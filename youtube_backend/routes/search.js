// routes/search.js
import express from "express";
import fs from "fs";
import path from "path";
import axios from "axios";
import dotenv from "dotenv";
import multer from "multer";

dotenv.config();
const router = express.Router();

const { OLLAMA_URL, EMBED_MODEL } = process.env;

// ----------------------
// Multer setup for multipart-form
// ----------------------
const upload = multer({ dest: "temp_search_uploads/" });

// ----------------------
// Utils
// ----------------------

// Cosine similarity
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

// Get embedding via Ollama API
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
// Route
// ----------------------
router.post(
  "/",
  upload.fields([
    { name: "query", maxCount: 1 },
    { name: "transcriptFiles", maxCount: 20 }, // adjust maxCount as needed
  ]),
  async (req, res) => {
    try {
      console.log("🔍 Search request received");

      // Get query from multipart/form-data
      const query = req.body.query?.[0] || req.body.query;
      if (!query) return res.status(400).json({ error: "Query string is required" });
      console.log("Query:", query);

      // Get transcript files uploaded
      let transcriptFiles = [];
      if (req.files && req.files.transcriptFiles) {
        transcriptFiles = req.files.transcriptFiles.map(f => f.path);
      }

      if (!transcriptFiles.length) {
        return res
          .status(400)
          .json({ error: "No transcript files uploaded" });
      }
      console.log("Uploaded transcript files:", transcriptFiles);

      // Load transcripts & ensure embeddings
      let transcripts = [];
      for (const file of transcriptFiles) {
        console.log(`Loading transcript file: ${file}`);
        if (!fs.existsSync(file)) continue;

        const data = JSON.parse(fs.readFileSync(file, "utf8"));

        // Compute embedding if missing
        let updated = false;
        for (const segment of data) {
          if (!segment.embedding || !segment.embedding.length) {
            console.log(`Generating embedding for segment: ${segment.text.slice(0, 30)}...`);
            segment.embedding = await getEmbedding(segment.text || "");
            updated = true;
          }
        }

        // Save updated transcript back to file
        if (updated) {
          fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf8");
          console.log(`Updated transcript saved with embeddings: ${file}`);
        }

        transcripts.push(...data);
      }

      if (!transcripts.length) {
        return res.status(400).json({ error: "No valid transcript segments found" });
      }

      console.log("Generating embedding for query...");
      const queryEmbedding = await getEmbedding(query);
      if (!queryEmbedding.length) {
        return res.status(500).json({ error: "Failed to generate query embedding" });
      }

      console.log("Comparing query embedding with transcript segments...");
      let bestMatch = null;
      let highestScore = -Infinity;

      for (const segment of transcripts) {
        console.log("Highest score so far:", highestScore," for segment:", segment.text.slice(0, 30), "...");
        if (!segment.text || !segment.embedding?.length) continue;

        const score = cosineSim(queryEmbedding, segment.embedding);
        if (score > highestScore) {
          highestScore = score;
          bestMatch = {
            videoFile: segment.url?.split("#")[0] || "unknown",
            start: segment.start,
            end: segment.end,
            start_hms: segment.start_hms,
            end_hms: segment.end_hms,
            text: segment.text,
            similarity: score.toFixed(4),
          };
        }
      }

      if (!bestMatch) {
        console.log("No matching segment found.");
        return res.json({ message: "No match found", query });
      }

      console.log("Best match found:", bestMatch.text.slice(0, 50), "...", "Score:", highestScore.toFixed(4));

      res.json({
        message: "Best match found",
        query,
        result: bestMatch,
      });
    } catch (err) {
      console.error("❌ Error during search:", err);
      res.status(500).json({ error: err.message });
    }
  }
);

export default router;
