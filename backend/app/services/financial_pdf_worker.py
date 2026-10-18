"""Disposable text-only worker. Original bytes enter stdin; no file paths or DB."""
import json
import logging
import sys


def main():
    logging.disable(logging.CRITICAL)
    try:
        from app.services.financial_pdf_readers import parse_local
        import os
        content = sys.stdin.buffer.read(10 * 1024 * 1024 + 1)
        if len(content) > 10 * 1024 * 1024 or not content.startswith(b"%PDF-"):
            raise ValueError("invalid")
        password = os.environ.get("PDF_WORKER_PASSWORD")
        report = parse_local(content, password=password)
        sys.stdout.buffer.write(json.dumps(report, ensure_ascii=False, allow_nan=False).encode("utf-8"))
    except Exception:
        sys.stdout.buffer.write(b'{"worker_error":"PDF_PROCESSING_FAILED"}')


if __name__ == "__main__":
    main()
