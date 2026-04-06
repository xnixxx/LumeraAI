import { Router, Response } from "express";
import { z } from "zod";
import { db } from "../../shared/db.js";
import { authenticate, AuthRequest } from "../../shared/middleware.js";

export const sessionsRouter = Router();
sessionsRouter.use(authenticate);

const StartSchema = z.object({
  routeId: z.string().uuid(),
  runMode: z.string(),
});

sessionsRouter.post("/start", async (req: AuthRequest, res: Response) => {
  const parse = StartSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const { routeId, runMode } = parse.data;
  const result = await db.query(
    `INSERT INTO sessions (id, user_id, route_id, run_mode, started_at, state)
     VALUES (gen_random_uuid(), $1, $2, $3, NOW(), 'ACTIVE_RUN')
     RETURNING id, started_at`,
    [req.userId, routeId, runMode]
  );
  const row = result.rows[0];
  res.status(201).json({ sessionId: row.id, startedAt: row.started_at });
});

sessionsRouter.post("/:id/events", async (req: AuthRequest, res: Response) => {
  const events = req.body.events as unknown[];
  if (!Array.isArray(events)) { res.status(400).json({ code: "VALIDATION_ERROR", message: "events must be an array" }); return; }
  // Batch insert guidance/hazard events
  for (const event of events) {
    const e = event as Record<string, unknown>;
    if (e["semanticType"]) {
      await db.query(
        `INSERT INTO guidance_events (id, session_id, timestamp, semantic_type, priority, trigger_reason)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5)`,
        [req.params["id"], e["timestamp"], e["semanticType"], e["priority"], e["triggerReason"] ?? ""]
      );
    } else if (e["hazardType"]) {
      await db.query(
        `INSERT INTO hazard_events (id, session_id, timestamp, hazard_type, severity, distance_m, bearing)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)`,
        [req.params["id"], e["timestamp"], e["hazardType"], e["severity"], e["distanceM"], e["bearing"]]
      );
    }
  }
  res.status(204).send();
});

const EndSchema = z.object({
  endedAt: z.string(),
  totalDistanceM: z.number().nonnegative(),
  lapCount: z.number().int().nonnegative(),
  averagePaceMpS: z.number().nonnegative(),
  averageHeartRateBpm: z.number().optional(),
  maxHeartRateBpm: z.number().optional(),
});

sessionsRouter.post("/:id/end", async (req: AuthRequest, res: Response) => {
  const parse = EndSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const d = parse.data;
  await db.query(
    `UPDATE sessions SET ended_at = $1, total_distance_m = $2, lap_count = $3,
                         average_pace_mps = $4, average_heart_rate_bpm = $5, max_heart_rate_bpm = $6, state = 'SESSION_COMPLETE'
     WHERE id = $7 AND user_id = $8`,
    [d.endedAt, d.totalDistanceM, d.lapCount, d.averagePaceMpS, d.averageHeartRateBpm, d.maxHeartRateBpm, req.params["id"], req.userId]
  );
  res.json({ sessionId: req.params["id"], summaryAvailable: true });
});

sessionsRouter.get("/:id", async (req: AuthRequest, res: Response) => {
  const result = await db.query("SELECT * FROM sessions WHERE id = $1 AND user_id = $2", [req.params["id"], req.userId]);
  if (!result.rows[0]) { res.status(404).json({ code: "NOT_FOUND", message: "Session not found" }); return; }
  res.json(result.rows[0]);
});
