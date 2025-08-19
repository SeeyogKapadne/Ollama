import fs from 'fs';
import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

const OLLAMA_URL = process.env.OLLAMA_URL;
const EMBED_MODEL = process.env.EMBED_MODEL;

// Load index.json
const indexFile = 'index.json';
const index = JSON.parse(fs.readFileSync(indexFile));

// Function to get embedding for a query
async function embedDocument(text) {
  const res = await axios.post(`${OLLAMA_URL}/api/embeddings`, {
    model: EMBED_MODEL,
    prompt: text
  });
  return res.data.embedding;
}

// Cosine similarity between two vectors
function cosineSimilarity(a, b) {
  const dot = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dot / (magA * magB);
}

// Main search function
async function searchResume(query) {
  const queryEmbedding = await embedDocument(query);

  let bestMatch = null;
  let bestScore = -Infinity;

  for (let doc of index) {
    const score = cosineSimilarity(queryEmbedding, doc.embedding);
    if (score > bestScore) {
      bestScore = score;
      bestMatch = doc.name;
    }
  }

  console.log(`Best match for "${query}": ${bestMatch} (score: ${bestScore})`);
}

// Example usage:
const prompt = process.argv[2] || "JavaScript developer";
searchResume(prompt).catch(console.error);
