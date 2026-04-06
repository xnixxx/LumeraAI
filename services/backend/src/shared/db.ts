import { Pool } from "pg";

export const db = new Pool({
  host: process.env["DB_HOST"] ?? "localhost",
  port: Number(process.env["DB_PORT"] ?? 5432),
  database: process.env["DB_NAME"] ?? "lumera",
  user: process.env["DB_USER"] ?? "lumera",
  password: process.env["DB_PASSWORD"] ?? "",
  max: 20,
  idleTimeoutMillis: 30_000,
});
