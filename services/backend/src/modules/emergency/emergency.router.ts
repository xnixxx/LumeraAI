import { Router, Response } from "express";
import { z } from "zod";
import { db } from "../../shared/db";
import { authenticate, AuthRequest } from "../../shared/middleware";

export const emergencyRouter = Router();
emergencyRouter.use(authenticate);

const TriggerSchema = z.object({
  sessionId: z.string().uuid(),
  triggerSource: z.string(),
  lastKnownLatitude: z.number().optional(),
  lastKnownLongitude: z.number().optional(),
});

emergencyRouter.post("/trigger", async (req: AuthRequest, res: Response) => {
  const parse = TriggerSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const d = parse.data;
  const result = await db.query(
    `INSERT INTO emergency_events (id, session_id, user_id, triggered_at, trigger_source, last_known_lat, last_known_lon)
     VALUES (gen_random_uuid(), $1, $2, NOW(), $3, $4, $5)
     RETURNING id, triggered_at`,
    [d.sessionId, req.userId, d.triggerSource, d.lastKnownLatitude, d.lastKnownLongitude]
  );
  const row = result.rows[0];
  // In production: trigger push notifications to emergency contacts
  res.status(201).json({ emergencyId: row.id, triggeredAt: row.triggered_at, notificationsSent: true });
});

const CheckinSchema = z.object({
  emergencyId: z.string().uuid(),
  safeConfirmed: z.boolean(),
});

emergencyRouter.post("/checkin", async (req: AuthRequest, res: Response) => {
  const parse = CheckinSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const { emergencyId, safeConfirmed } = parse.data;
  await db.query(
    "UPDATE emergency_events SET checkin_at = NOW(), resolved_at = CASE WHEN $1 THEN NOW() END WHERE id = $2 AND user_id = $3",
    [safeConfirmed, emergencyId, req.userId]
  );
  res.status(204).send();
});
