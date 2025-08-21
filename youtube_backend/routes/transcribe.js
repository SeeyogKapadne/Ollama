import express from 'express';
import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';
import { createObjectCsvWriter } from 'csv-writer';
import multer from 'multer';
import pLimit from 'p-limit';

const router = express.Router();
const upload = multer();

// ----------------------
// Utilities
// ----------------------
function hhmmss(sec) {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = Math.floor(sec % 60);
  return [h, m, s].map(v => String(v).padStart(2, '0')).join(':');
}

function deepLink(videoFile, start) {
  return `${videoFile}#t=${Math.floor(start)}`;
}

function exportJSON(segments, outPath) {
  fs.writeFileSync(outPath, JSON.stringify(segments, null, 2), 'utf8');
  console.log(`[✅ JSON Exported] ${outPath}`);
}

async function exportCSV(segments, outPath) {
  const csvWriter = createObjectCsvWriter({
    path: outPath,
    header: [
      { id: 'start', title: 'start_sec' },
      { id: 'end', title: 'end_sec' },
      { id: 'start_hms', title: 'start_hhmmss' },
      { id: 'end_hms', title: 'end_hhmmss' },
      { id: 'text', title: 'text' },
      { id: 'url', title: 'url' }
    ]
  });
  await csvWriter.writeRecords(segments);
  console.log(`[✅ CSV Exported] ${outPath}`);
}

function exportSRT(segments, outPath) {
  const toSrtTime = t =>
    `${hhmmss(t)},${String(Math.floor((t - Math.floor(t)) * 1000)).padStart(3, '0')}`;
  const body = segments
    .map((s, i) => `${i + 1}\n${toSrtTime(s.start)} --> ${toSrtTime(s.end)}\n${s.text}\n`)
    .join('\n');
  fs.writeFileSync(outPath, body, 'utf8');
  console.log(`[✅ SRT Exported] ${outPath}`);
}

function runASR(videoPath, opts = {}) {
  if (!fs.existsSync(videoPath)) throw new Error(`File not found: ${videoPath}`);
  const py = opts.python || 'python';
  const script = opts.script || path.resolve('./asr_whisper.py');
  const args = [
    script,
    videoPath,
    '--model', opts.model || 'small',
    '--device', opts.device || 'auto'
  ];
  if (opts.compute_type) args.push('--compute_type', opts.compute_type);
  if (opts.language) args.push('--language', opts.language);

  console.log(`[⏳ ASR Started] ${videoPath} using model=${opts.model || 'small'}`);
  const res = spawnSync(py, args, { encoding: 'utf8' });
  if (res.status !== 0) throw new Error(`ASR failed (${res.status}): ${res.stderr || res.stdout}`);
  console.log(`[✅ ASR Completed] ${videoPath}`);
  const parsed = JSON.parse(res.stdout);
  if (!Array.isArray(parsed)) throw new Error('ASR JSON not an array');
  return parsed;
}

// ----------------------
// Route: /transcribe
// ----------------------
router.post('/', upload.array('videoFiles'), async (req, res) => {
  let videoFiles = [];

  // Detect files: web multipart or JSON body
  if (req.files && req.files.length > 0) {
    videoFiles = req.files.map(f => ({ buffer: f.buffer, originalname: f.originalname }));
    console.log(`[ℹ️ Web Upload] ${videoFiles.length} files detected`);
  } else if (req.body.videoFiles) {
    videoFiles = req.body.videoFiles;
    console.log(`[ℹ️ JSON Input] ${videoFiles.length} files detected`);
  } else {
    return res.status(400).json({ error: 'No video files provided' });
  }

  // Ensure output folders exist
  const outDirs = {
    json: path.join('output', 'json'),
    csv: path.join('output', 'csv'),
    srt: path.join('output', 'srt')
  };
  Object.values(outDirs).forEach(dir => {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  });

  // ----------------------
  // Limit concurrency
  // ----------------------
  const concurrencyLimit = 2; // adjust based on CPU/GPU
  const limit = pLimit(concurrencyLimit);
  // Promise.all helps us run tasks concurrently
  const results = await Promise.all(
    videoFiles.map(videoFile => limit(async () => {
      let filePath = typeof videoFile === 'string' ? videoFile : null;
      const fileName = typeof videoFile === 'string' ? path.basename(videoFile) : videoFile.originalname;

      console.log(`[📥 Processing] ${fileName}`);

      // Save buffer to temp if needed
      if (!filePath && videoFile.buffer) {
        const tempDir = './temp_uploads';
        if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });
        filePath = path.join(tempDir, fileName);
        fs.writeFileSync(filePath, videoFile.buffer);
        console.log(`[💾 Saved Temp] ${filePath}`);
      }

      if (!fs.existsSync(filePath)) {
        console.log(`[❌ Missing File] ${fileName}`);
        return { videoFile: fileName, error: 'File does not exist' };
      }

      const startTime = Date.now();

      let asrSegs;
      try {
        asrSegs = runASR(filePath, { model: 'medium', device: 'auto' });
      } catch (e) {
        console.log(`[❌ ASR Error] ${fileName}: ${e.message}`);
        return { videoFile: fileName, error: e.message };
      }

      console.log(`[ℹ️ Segments Count] ${asrSegs.length} segments for ${fileName}`);

      const segments = asrSegs
        .map(s => {
          const start = s.start || 0;
          const end = start + (s.duration || 0);
          return {
            text: (s.text || '').trim(),
            start,
            end,
            start_hms: hhmmss(start),
            end_hms: hhmmss(end),
            url: deepLink(fileName, start),
            source: 'asr'
          };
        })
        .filter(s => s.text);

      const videoBaseName = path.parse(fileName).name;
      const formats = req.body.formats || ['json', 'csv', 'srt'];

      try {
        if (formats.includes('json')) exportJSON(segments, path.join(outDirs.json, `${videoBaseName}_transcript.json`));
        if (formats.includes('csv')) await exportCSV(segments, path.join(outDirs.csv, `${videoBaseName}_transcript.csv`));
        if (formats.includes('srt')) exportSRT(segments, path.join(outDirs.srt, `${videoBaseName}_transcript.srt`));
      } catch (e) {
        console.log(`[❌ Export Error] ${fileName}: ${e.message}`);
        return { videoFile: fileName, error: e.message };
      }

      const endTime = Date.now();
      const durationSeconds = ((endTime - startTime) / 1000).toFixed(2);
      console.log(`[⏱ Finished] ${fileName} in ${durationSeconds} sec`);

      return {
        videoFile: fileName,
        message: 'Transcript created successfully',
        outputFiles: {
          json: path.join(outDirs.json, `${videoBaseName}_transcript.json`),
          csv: path.join(outDirs.csv, `${videoBaseName}_transcript.csv`),
          srt: path.join(outDirs.srt, `${videoBaseName}_transcript.srt`)
        },
        sample: segments.slice(0, 5),
        processingTimeSec: durationSeconds
      };
    }))
  );

  res.json({ results });
});

export default router;
