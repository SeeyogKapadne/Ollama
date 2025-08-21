import express from 'express';
import cors from 'cors';
import downloadRouter from './routes/download.js';
import transcribeRouter from './routes/transcribe.js';
import searchRouter from './routes/search.js';
import videosRouter from './routes/get_videos.js'; // <-- new import
import buildIndexRouter from './routes/build_index.js';

const app = express();

// Enable CORS for all routes
app.use(cors());
app.use(express.json());

// Routes
app.use('/download', downloadRouter);
app.use('/transcribe', transcribeRouter);
app.use('/search', searchRouter);
app.use('/videos', videosRouter); // <-- add this
app.use('/build-index', buildIndexRouter);

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
