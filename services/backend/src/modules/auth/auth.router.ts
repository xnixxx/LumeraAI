import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { db } from "../../shared/db";
import { generateTokens } from "../../shared/middleware";

export const authRouter = Router();

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

authRouter.post("/login", async (req: Request, res: Response) => {
  const parse = LoginSchema.safeParse(req.body);
  if (!parse.success) {
    res.status(400).json({ code: "VALIDATION_ERROR", message: parse.error.message });
    return;
  }
  const { email, password } = parse.data;
  const result = await db.query("SELECT id, password_hash, name FROM users WHERE email = $1", [email]);
  const user = result.rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash as string))) {
    res.status(401).json({ code: "INVALID_CREDENTIALS", message: "Email or password incorrect" });
    return;
  }
  const tokens = generateTokens(user.id as string);
  res.json({ ...tokens, expiresIn: 3600, user: { id: user.id, name: user.name, email } });
});

const RefreshSchema = z.object({ refreshToken: z.string() });

authRouter.post("/refresh", async (req: Request, res: Response) => {
  const parse = RefreshSchema.safeParse(req.body);
  if (!parse.success) {
    res.status(400).json({ code: "VALIDATION_ERROR", message: "Missing refreshToken" });
    return;
  }
  // In production: validate refresh token against DB and rotate
  const tokens = generateTokens("placeholder");
  res.json({ accessToken: tokens.accessToken, expiresIn: 3600 });
});
