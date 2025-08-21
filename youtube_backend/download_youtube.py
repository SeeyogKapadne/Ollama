import sys
import yt_dlp

url = sys.argv[1]
out_path = sys.argv[2]

ydl_opts = {
    'outtmpl': out_path,
    'format': 'bestvideo+bestaudio/best',
    'merge_output_format': 'mp4',
    'quiet': True,
    'no_warnings': True
}

try:
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])
    sys.exit(0)
except Exception as e:
    print(str(e))
    sys.exit(1)
