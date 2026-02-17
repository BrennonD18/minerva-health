import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { authMiddleware, JwtPayload } from "../middleware/auth";

const router = Router();

// GET /me – Current user (requires Authorization: Bearer <token>)
router.get("/", authMiddleware, async (req, res): Promise<void> => {
  try {
    const { userId } = (req as Request & { user: JwtPayload }).user;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, appleId: true, email: true, name: true, createdAt: true, updatedAt: true },
    });
    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }
    res.json(user);
  } catch (e) {
    console.error("GET /me", e);
    res.status(500).json({ error: "Failed to fetch user" });
  }
});

export default router;
