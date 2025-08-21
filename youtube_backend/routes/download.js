// import express from 'express';
// import path from 'path';
// import fs from 'fs';
// import ytDlpExec from 'yt-dlp-exec';

// const router = express.Router();

// // Ensure videos folder exists
// const videosDir = path.resolve('./videos');
// if (!fs.existsSync(videosDir)) fs.mkdirSync(videosDir, { recursive: true });

// // Helper: next available filename
// function getNextVideoFilename() {
//   let i = 1;
//   let filename;
//   do {
//     filename = path.join(videosDir, `video${i}.mp4`);
//     i++;
//   } while (fs.existsSync(filename));
//   return filename;
// }

// // Normalize Shorts URL
// function normalizeYouTubeUrl(url) {
//   if (url.includes('youtube.com/shorts/')) {
//     const match = url.match(/\/shorts\/([a-zA-Z0-9_-]+)/);
//     if (match && match[1]) return `https://www.youtube.com/watch?v=${match[1]}`;
//   }
//   return url;
// }

// // POST /download
// router.post('/', async (req, res) => {
//   try {
//     let { url } = req.body;
//     if (!url || typeof url !== 'string') {
//       return res.status(400).json({ error: 'YouTube URL is required' });
//     }

//     url = normalizeYouTubeUrl(url);

//     const outPath = getNextVideoFilename();

//     console.log(`[⏳ Download starting] ${url}`);

//     await ytDlpExec(url, {
//       output: outPath,
//       format: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4',
//       quiet: true,
//       noWarnings: true,
//       mergeOutputFormat: 'mp4',
//     });

//     console.log(`[✅ Download completed] ${outPath}`);

//     res.json({
//       message: 'Video downloaded successfully',
//       videoFile: outPath,
//     });

//   } catch (err) {
//     console.error(`[❌ Download error] ${err.message}`);
//     res.status(500).json({
//       error: 'Video download failed. Make sure the URL is valid and accessible.',
//       details: err.message,
//     });
//   }
// });

// export default router;
import express from 'express';
import path from 'path';
import fs from 'fs';
import { spawn } from 'child_process';

const router = express.Router();
const videosDir = path.resolve('./videos');
if (!fs.existsSync(videosDir)) fs.mkdirSync(videosDir, { recursive: true });

function getNextVideoFilename() {
  let i = 1;
  let filename;
  do {
    filename = path.join(videosDir, `video${i}.mp4`);
    i++;
  } while (fs.existsSync(filename));
  return filename;
}

// POST /download
router.post('/', async (req, res) => {
  try {
    const { url } = req.body;
    if (!url || typeof url !== 'string') {
      return res.status(400).json({ error: 'YouTube URL is required' });
    }

    const outPath = getNextVideoFilename();

    const pythonProcess = spawn('python', [
      path.resolve('./download_youtube.py'),
      url,
      outPath
    ]);

    let pythonOutput = '';
    pythonProcess.stdout.on('data', (data) => {
      pythonOutput += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      console.error('[Python STDERR]', data.toString());
    });

    pythonProcess.on('close', (code) => {
      if (code === 0) {
        res.status(200).json({
          status: 'success',
          message: 'Video downloaded successfully',
          videoFile: outPath
        });
      } else {
        res.status(500).json({
          status: 'error',
          message: 'Video download failed',
          details: pythonOutput
        });
      }
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

export default router;
