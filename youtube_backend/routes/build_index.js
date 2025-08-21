// routes/buildIndex.js
import express from "express";
import fs from "fs";
import path from "path";
import axios from "axios";
import dotenv from "dotenv";

dotenv.config();
const router = express.Router();

const { OLLAMA_URL, EMBED_MODEL } = process.env;

// ----------------------
// Utils
// ----------------------

// Cosine similarity (for later search)
function cosineSim(a, b) {
  let dot = 0,
    normA = 0,
    normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Call Ollama API to get embedding for text
async function getEmbedding(text) {
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

// ----------------------
// Route: POST /build-index
// ----------------------
router.post("/", async (req, res) => {
  try {
    console.log("📚 Build index request received:", req.body);
    const { transcriptFiles } = req.body;

    if (!Array.isArray(transcriptFiles) || transcriptFiles.length === 0) {
      return res
        .status(400)
        .json({ error: "transcriptFiles must be a non-empty array of paths" });
    }

    const index = [];

    for (const file of transcriptFiles) {
      if (!fs.existsSync(file)) {
        console.warn(`File not found: ${file}`);
        continue;
      }

      const data = JSON.parse(fs.readFileSync(file, "utf8"));

      for (const segment of data) {
        if (!segment.text) continue;

        // Get embedding from Ollama
        console.log(`Embedding: "${segment.text}"`);
        const embedding = await getEmbedding(segment.text);

        // Build index entry
        index.push({
          text: segment.text,
          embedding,
          start: segment.start,
          end: segment.end,
          start_hms: segment.start_hms,
          end_hms: segment.end_hms,
          url: segment.url || "unknown",
        });
      }
    }

    // Save the index to file
    fs.writeFileSync("index.json", JSON.stringify(index, null, 2), "utf8");

    res.json({
      message: "Index created successfully",
      totalSegments: index.length,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

export default router;
