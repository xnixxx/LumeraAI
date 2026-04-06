import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env["JWT_SECRET"] ?? "change-in-production";

export interface AuthRequest extends Request {
  userId?: string;
}

export function authenticate(req: AuthRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    res.status(401).json({ code: "UNAUTHORIZED", message: "Missing token" });
    return;
  }
  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: string };
    req.userId = payload.userId;
    next();
  } catch {
    res.status(401).json({ code: "UNAUTHORIZED", message: "Invalid token" });
  }
}

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  console.error(err);
  res.status(500).json({ code: "INTERNAL_ERROR", message: "An unexpected error occurred" });
}

export function generateTokens(userId: string): { accessToken: string; refreshToken: string } {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, { expiresIn: "1h" });
  const refreshToken = jwt.sign({ userId, type: "refresh" }, JWT_SECRET, { expiresIn: "30d" });
  return { accessToken, refreshToken };
}
