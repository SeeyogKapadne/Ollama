import express from "express";
import dotenv from "dotenv";
import cors from "cors"; // <-- import cors
import searchRoute from "./routes/searchroute.js";
import fs from "fs";
import path from "path";
import axios from "axios";

dotenv.config();

const app = express();
app.use(express.json());

// Enable CORS for all origins (for development)
app.use(cors());

// Or allow only your frontend origin
// app.use(cors({ origin: "http://localhost:52577" }));

const { OLLAMA_URL, EMBED_MODEL } = process.env;

// Embed document function
async function embedDocument(text) {
  try {
    const singleLineText = String(text)
      .split(/\r?\n|\r/)
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .join(" ");

    const payload = { model: EMBED_MODEL, prompt: singleLineText };

    const res = await axios.post(
      `${OLLAMA_URL}/api/embeddings`,
      payload,
      { headers: { "Content-Type": "application/json" } }
    );

    return res.data.embedding || res.data.data?.[0]?.embedding || [];
  } catch (err) {
    console.error("❌ Error generating embedding:", err.message);
    return [];
  }
}

// Build index function
async function buildIndex() {
  const documentsDir = path.join(process.cwd(), "documents");
  const files = fs.readdirSync(documentsDir).filter(f => f.endsWith(".txt"));
  const index = [];

  for (let f of files) {
    const content = fs.readFileSync(path.join(documentsDir, f), "utf-8");
    const embedding = await embedDocument(content);
    if (embedding.length > 0) {
      index.push({ name: f, embedding });
    } else {
      console.warn(`⚠️ Skipping ${f}, embedding empty`);
    }
  }

  fs.writeFileSync(path.join(process.cwd(), "index.json"), JSON.stringify(index, null, 2));
  return index;
}

// Index route
app.post("/index", async (req, res) => {
  try {
    const index = await buildIndex();
    res.json({ message: "Index built successfully", index });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Search route
app.use("/search", searchRoute);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running at http://localhost:${PORT}`));
