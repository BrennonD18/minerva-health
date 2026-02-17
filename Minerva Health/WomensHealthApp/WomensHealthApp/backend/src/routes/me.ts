import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { authMiddleware, JwtPayload } from "../middleware/auth";

const router = Router();

router.use(authMiddleware);

// GET /me – Current user (requires Authorization: Bearer <token>)
router.get("/", async (req: Request & { user: JwtPayload }, res: Response): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
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
