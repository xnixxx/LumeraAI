import { Router, Response } from "express";
import { z } from "zod";
import { db } from "../../shared/db";
import { authenticate, AuthRequest } from "../../shared/middleware";

export const routesRouter = Router();
routesRouter.use(authenticate);

routesRouter.get("/", async (_req: AuthRequest, res: Response) => {
  const result = await db.query(
    `SELECT id, name, description, environment, total_distance_m,
            complexity_rating, tags, validation_status
     FROM routes
     WHERE validation_status = 'validated'
     ORDER BY name`
  );
  res.json(result.rows);
});

routesRouter.get("/:id", async (req: AuthRequest, res: Response) => {
  const result = await db.query("SELECT * FROM routes WHERE id = $1", [req.params["id"]]);
  if (!result.rows[0]) { res.status(404).json({ code: "NOT_FOUND", message: "Route not found" }); return; }
  res.json(result.rows[0]);
});

const CreateRouteSchema = z.object({
  name: z.string().min(2),
  description: z.string(),
  environment: z.string(),
  segments: z.array(z.unknown()),
  tags: z.array(z.string()),
  knownHazardNotes: z.array(z.string()),
});

routesRouter.post("/", async (req: AuthRequest, res: Response) => {
  const parse = CreateRouteSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const { name, description, environment, segments, tags, knownHazardNotes } = parse.data;
  const totalDistanceM = 0; // computed from segments in production
  const result = await db.query(
    `INSERT INTO routes (id, name, description, environment, segments, tags, known_hazard_notes, total_distance_m, complexity_rating, validation_status, created_by)
     VALUES (gen_random_uuid(), $1, $2, $3, $4::jsonb, $5, $6, $7, 'pending', 'pending', $8)
     RETURNING id`,
    [name, description, environment, JSON.stringify(segments), tags, knownHazardNotes, totalDistanceM, req.userId]
  );
  res.status(201).json({ id: result.rows[0].id });
});

routesRouter.post("/:id/validate", async (req: AuthRequest, res: Response) => {
  const routeId = req.params["id"];
  // Validation logic placeholder — run geometry checks, corridor consistency etc.
  const issues: string[] = [];
  const status = issues.length === 0 ? "validated" : "rejected";
  await db.query("UPDATE routes SET validation_status = $1 WHERE id = $2", [status, routeId]);
  res.json({ routeId, validationStatus: status, issues });
});
