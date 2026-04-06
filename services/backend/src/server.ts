import express from "express";
import { authRouter } from "./modules/auth/auth.router.js";
import { routesRouter } from "./modules/routes/routes.router.js";
import { sessionsRouter } from "./modules/sessions/sessions.router.js";
import { emergencyRouter } from "./modules/emergency/emergency.router.js";
import { feedbackRouter } from "./modules/feedback/feedback.router.js";
import { errorHandler } from "./shared/middleware.js";

const app = express();
const PORT = process.env["PORT"] ?? 3000;

app.use(express.json({ limit: "1mb" }));

// Health check
app.get("/health", (_req, res) => res.json({ status: "ok", service: "lumera-backend" }));

// API v1
const v1 = express.Router();
v1.use("/auth", authRouter);
v1.use("/routes", routesRouter);
v1.use("/sessions", sessionsRouter);
v1.use("/emergency", emergencyRouter);
v1.use("/", feedbackRouter);

app.use("/v1", v1);
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`LumeraAI backend running on port ${PORT}`);
});
