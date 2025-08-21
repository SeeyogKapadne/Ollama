import argparse, json, sys, os
from faster_whisper import WhisperModel

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("audio", help="audio file path (wav/mp3/m4a/etc.)")
    ap.add_argument("--model", default="small", help="tiny/base/small/medium/large-v3 or GGML name")
    ap.add_argument("--device", default="auto", help="cuda|cpu|auto")
    ap.add_argument("--compute_type", default=None,
                    help="float16|int8_float16|int8|int8x8|float32 (defaults based on device)")
    ap.add_argument("--language", default=None, help="hint language code, e.g. en, hi")
    args = ap.parse_args()
    
    if not os.path.exists(args.audio):
        print(json.dumps({"error": f"Audio not found: {args.audio}"}))
        sys.exit(2)

    # --- FIXED ---
    if args.device == "auto":
        import torch
        device = "cuda" if torch.cuda.is_available() else "cpu"
    else:
        device = args.device

    compute_type = args.compute_type if args.compute_type is not None else "default"
    
    model = WhisperModel(args.model, device=device, compute_type=compute_type)
    
    segments, info = model.transcribe(
        args.audio,
        language=args.language,
        vad_filter=True,
        beam_size=5,
        best_of=5
    )

    out = []
    for s in segments:
        start = float(s.start) if s.start is not None else 0.0
        end   = float(s.end)   if s.end is not None else start
        out.append({
            "text": s.text.strip(),
            "start": start,
            "duration": max(0.0, end - start)
        })

    sys.stdout.buffer.write(json.dumps(out, ensure_ascii=False).encode('utf-8'))
    sys.stdout.buffer.write(b"\n")
    sys.exit(0)

if __name__ == "__main__":
    main()
