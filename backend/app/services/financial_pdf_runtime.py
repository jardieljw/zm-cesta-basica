"""Bounded separate process; extraction must happen outside SQLite write locks."""
import json
import os
from pathlib import Path
import subprocess
import sys
from threading import BoundedSemaphore

from app.services.financial_pdf_readers import empty_report, error

PDF_TIMEOUT_SECONDS = 20
WORKERS = BoundedSemaphore(1)


def extract_pdf(content, password=None):
    report = empty_report()
    if getattr(sys, "frozen", False):
        error(report, "PDF_RUNTIME_UNAVAILABLE")
        report["complete"] = False
        return report
    if not WORKERS.acquire(blocking=False):
        error(report, "PDF_PROCESSING_BUSY")
        report["complete"] = False
        return report
    try:
        env = os.environ.copy()
        if password:
            env["PDF_WORKER_PASSWORD"] = password
        result = subprocess.run([sys.executable, "-m", "app.services.financial_pdf_worker"], input=content,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=PDF_TIMEOUT_SECONDS,
            cwd=str(Path(__file__).resolve().parents[2]),
            env=env,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        if result.returncode != 0 or len(result.stdout) > 8 * 1024 * 1024:
            raise ValueError("worker")
        value = json.loads(result.stdout)
        if "worker_error" in value or not isinstance(value.get("items"), list):
            raise ValueError("worker")
        return value
    except subprocess.TimeoutExpired:
        error(report, "PDF_PROCESSING_TIMEOUT")
    except Exception:
        error(report, "PDF_PROCESSING_FAILED")
    finally:
        WORKERS.release()
    report["complete"] = False
    return report
