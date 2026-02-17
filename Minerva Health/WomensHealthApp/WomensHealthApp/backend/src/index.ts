import "dotenv/config";
import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth";
import meRoutes from "./routes/me";

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors({ origin: true }));
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "minerva-backend" });
});

app.use("/auth", authRoutes);
app.use("/me", meRoutes);

app.listen(PORT, () => {
  console.log(`Minerva backend running on port ${PORT}`);
});
