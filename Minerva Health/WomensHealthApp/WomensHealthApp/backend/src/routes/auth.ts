import { Router, Request, Response } from "express";
import bcrypt from "bcrypt";
import { prisma } from "../lib/prisma";
import { signToken } from "../middleware/auth";

const router = Router();
const SALT_ROUNDS = 10;

function toUserJson(user: { id: string; appleId: string | null; googleId: string | null; email: string | null; name: string | null; createdAt: Date }) {
  return {
    id: user.id,
    appleId: user.appleId,
    googleId: user.googleId,
    email: user.email,
    name: user.name,
    createdAt: user.createdAt,
  };
}

// POST /auth/apple – Sign in with Apple
// Body: { appleId: string, email?: string, name?: string }
// Returns: { token, user: { id, appleId, email, name } }
router.post("/apple", async (req: Request, res: Response): Promise<void> => {
  try {
    const { appleId, email, name } = req.body as { appleId?: string; email?: string; name?: string };
    if (!appleId || typeof appleId !== "string") {
      res.status(400).json({ error: "appleId is required" });
      return;
    }

    let user = await prisma.user.findUnique({ where: { appleId } });
    if (!user) {
      user = await prisma.user.create({
        data: { appleId, email: email ?? null, name: name ?? null },
      });
    } else if (email !== undefined || name !== undefined) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          ...(email !== undefined && { email }),
          ...(name !== undefined && { name }),
        },
      });
    }

    const token = signToken({ userId: user.id, appleId: user.appleId ?? undefined });
    res.status(200).json({ token, user: toUserJson(user) });
  } catch (e) {
    console.error("POST /auth/apple", e);
    res.status(500).json({ error: "Authentication failed" });
  }
});

// POST /auth/register – Sign up with email and password
// Body: { email: string, password: string, name?: string }
router.post("/register", async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, name } = req.body as { email?: string; password?: string; name?: string };
    if (!email || typeof email !== "string" || !email.trim()) {
      res.status(400).json({ error: "Email is required" });
      return;
    }
    if (!password || typeof password !== "string" || password.length < 8) {
      res.status(400).json({ error: "Password must be at least 8 characters" });
      return;
    }
    const existing = await prisma.user.findUnique({ where: { email: email.trim().toLowerCase() } });
    if (existing) {
      res.status(409).json({ error: "An account with this email already exists" });
      return;
    }
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const user = await prisma.user.create({
      data: {
        email: email.trim().toLowerCase(),
        passwordHash,
        name: name?.trim() ?? null,
      },
    });
    const token = signToken({ userId: user.id, appleId: user.appleId ?? undefined });
    res.status(201).json({ token, user: toUserJson(user) });
  } catch (e) {
    console.error("POST /auth/register", e);
    res.status(500).json({ error: "Registration failed" });
  }
});

// POST /auth/login – Sign in with email and password
// Body: { email: string, password: string }
router.post("/login", async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };
    if (!email || typeof email !== "string" || !email.trim()) {
      res.status(400).json({ error: "Email is required" });
      return;
    }
    if (!password || typeof password !== "string") {
      res.status(400).json({ error: "Password is required" });
      return;
    }
    const user = await prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    if (!user || !user.passwordHash) {
      res.status(401).json({ error: "Invalid email or password" });
      return;
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      res.status(401).json({ error: "Invalid email or password" });
      return;
    }
    const token = signToken({ userId: user.id, appleId: user.appleId ?? undefined });
    res.status(200).json({ token, user: toUserJson(user) });
  } catch (e) {
    console.error("POST /auth/login", e);
    res.status(500).json({ error: "Login failed" });
  }
});

// POST /auth/google – Sign in with Google
// Body: { googleId: string (sub), email?: string, name?: string }
// Returns: { token, user }
router.post("/google", async (req: Request, res: Response): Promise<void> => {
  try {
    const { googleId, email, name } = req.body as { googleId?: string; email?: string; name?: string };
    if (!googleId || typeof googleId !== "string") {
      res.status(400).json({ error: "googleId is required" });
      return;
    }

    let user = await prisma.user.findUnique({ where: { googleId } });
    if (!user) {
      user = await prisma.user.create({
        data: { googleId, email: email ?? null, name: name ?? null },
      });
    } else if (email !== undefined || name !== undefined) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          ...(email !== undefined && { email }),
          ...(name !== undefined && { name }),
        },
      });
    }

    const token = signToken({ userId: user.id, appleId: user.appleId ?? undefined });
    res.status(200).json({ token, user: toUserJson(user) });
  } catch (e) {
    console.error("POST /auth/google", e);
    res.status(500).json({ error: "Authentication failed" });
  }
});

export default router;
