import { Router, Response } from "express";
import { z } from "zod";
import { db } from "../../shared/db";
import { authenticate, AuthRequest } from "../../shared/middleware";

export const feedbackRouter = Router();
feedbackRouter.use(authenticate);

const FeedbackSchema = z.object({
  overallRating: z.number().int().min(1).max(5),
  guidanceAccuracy: z.number().int().min(1).max(5),
  hapticClarity: z.number().int().min(1).max(5),
  freeTextComment: z.string().optional(),
  falseAlertsReported: z.number().int().nonnegative(),
  missedAlertsReported: z.number().int().nonnegative(),
});

feedbackRouter.post("/sessions/:sessionId/feedback", async (req: AuthRequest, res: Response) => {
  const parse = FeedbackSchema.safeParse(req.body);
  if (!parse.success) { res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message }); return; }
  const d = parse.data;
  await db.query(
    `INSERT INTO session_feedback
       (id, session_id, user_id, submitted_at, overall_rating, guidance_accuracy, haptic_clarity,
        free_text_comment, false_alerts_reported, missed_alerts_reported)
     VALUES (gen_random_uuid(), $1, $2, NOW(), $3, $4, $5, $6, $7, $8)`,
    [req.params["sessionId"], req.userId, d.overallRating, d.guidanceAccuracy, d.hapticClarity,
     d.freeTextComment, d.falseAlertsReported, d.missedAlertsReported]
  );
  res.status(204).send();
});
