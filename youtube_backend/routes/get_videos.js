import express from "express";
import path from "path";
import fs from "fs";

const router = express.Router();

// Folder where your videos are stored
const videosDir = path.join(process.cwd(), "videos");

// GET /videos/:filename
router.get("/:filename", (req, res) => {
  const { filename } = req.params;

  // Security: reject any path traversal
  if (filename.includes("..")) {
    return res.status(400).send("Invalid filename");
  }

  // Only use the base filename
  const safeName = path.basename(filename);
  const videoPath = path.join(videosDir, safeName);

  // Check if file exists
  fs.access(videoPath, fs.constants.R_OK, (err) => {
    if (err) {
      console.error("Video not found:", err);
      return res.status(404).send("Video not found");
    }

    // Send the video
    res.sendFile(videoPath, { headers: { "Content-Type": "video/mp4" } }, (err) => {
      if (err) {
        console.error("Error sending video:", err);
        res.status(500).send("Error sending video");
      }
    });
  });
});

export default router;
