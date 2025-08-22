import "dotenv/config";
import express from "express";
import cors from "cors";
import morgan from "morgan";
import { initSchema } from "./db.js";
import { createRouter } from "./routes.js";
import { startPolling, pollOnce } from "./poller.js";

const app = express();

const origin = process.env.FRONTEND_ORIGIN || "*";
app.use(cors({ origin }));
app.use(express.json());
app.use(morgan("dev"));

app.use("/api", createRouter());

const port = process.env.PORT || 4000;

initSchema()
  .then(() => app.listen(port, () => console.log(`API listening on ${port}`)))
  .then(async () => {
    await pollOnce().catch(err => console.error("Initial poll failed:", err.message));
    startPolling();
  })
  .catch(err => {
    console.error("Startup error:", err);
    process.exit(1);
  }); 