import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { signToken } from "../middleware/auth";

const router = Router();

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
    res.status(200).json({
      token,
      user: {
        id: user.id,
        appleId: user.appleId,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt,
      },
    });
  } catch (e) {
    console.error("POST /auth/apple", e);
    res.status(500).json({ error: "Authentication failed" });
  }
});

export default router;
