import fs from "fs";
import express from "express";
import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const router = express.Router();
const { OLLAMA_URL, EMBED_MODEL } = process.env;

// Cosine similarity function
function cosineSimilarity(a, b) {
  const dot = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dot / (magA * magB);
}

// Embed a query
async function embedQuery(text) {
  const res = await axios.post(
    `${OLLAMA_URL}/api/embeddings`,
    {
      model: EMBED_MODEL,
      prompt: String(text).replace(/\r?\n|\r/g, " "),
    },
    { headers: { "Content-Type": "application/json" } }
  );
  return res.data.embedding || res.data.data?.[0]?.embedding || [];
}

// POST /search
router.post("/", async (req, res) => {
  try {
    console.log("🔍 Search request received:", req.body);
    const { query } = req.body;
    if (!query) return res.status(400).json({ error: "Query is required" });

    if (!fs.existsSync("index.json"))
      return res.status(400).json({ error: "Index not found. Build it first." });

    const index = JSON.parse(fs.readFileSync("index.json", "utf-8"));
    const queryEmbedding = await embedQuery(query);

    if (!queryEmbedding.length)
      return res.status(500).json({ error: "Failed to generate embedding for query" });

    let bestMatch = null;
    let bestScore = -Infinity;

    for (let doc of index) {
      if (!doc.embedding || !doc.embedding.length) continue;
      const score = cosineSimilarity(queryEmbedding, doc.embedding);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = doc.name;
      }
    }

    res.json({ Best_Match: bestMatch, Score: bestScore });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

export default router;
