import json
import uuid
import hashlib
import datetime
from typing import Any, Tuple, Callable, Optional, Dict
from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.idempotency import IdempotencyRecord
from app.models.base import utc_now

def canonical_json_str(data: Any) -> str:
    """Produces normalized, deterministic JSON string for consistent hashing."""
    if data is None:
        return ""
    if isinstance(data, (dict, list)):
        return json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    if isinstance(data, bytes):
        return data.decode("utf-8")
    return str(data)

def compute_payload_hash(data: Any) -> str:
    """Calculates SHA-256 digest of canonical representation."""
    canonical = canonical_json_str(data)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()

class IdempotencyResult:
    def __init__(self, response_body: str, status_code: int, is_replay: bool):
        self.response_body = response_body
        self.status_code = status_code
        self.is_replay = is_replay

    def to_json_dict(self) -> Any:
        try:
            return json.loads(self.response_body)
        except Exception:
            return self.response_body

def process_transactional_idempotency(
    db: Session,
    idempotency_key: Optional[str],
    operation_type: str,
    payload: Any,
    business_callback: Callable[[Session], Tuple[int, Any]]
) -> IdempotencyResult:
    """
    Executes business logic transactionally with idempotency guarantees:
    - Same key + same payload: returns stored response without re-executing logic or movements.
    - Same key + different payload or operation: rejects with HTTP 409 IDEMPOTENCY_PAYLOAD_MISMATCH.
    - Concurrent in-flight key: rejects with HTTP 409 REQUEST_IN_PROGRESS.
    - Expired in-flight key: safely re-locks and executes without UNIQUE constraint violations.
    - New key: executes business logic, records stock movements and idempotency response atomically.
    """
    clean_key = idempotency_key.strip() if idempotency_key else None
    if not clean_key:
        # If no idempotency key was supplied, execute business callback and commit
        status_code, result = business_callback(db)
        body = json.dumps(result, ensure_ascii=False) if not isinstance(result, str) else result
        db.commit()
        return IdempotencyResult(response_body=body, status_code=status_code, is_replay=False)

    payload_hash = compute_payload_hash(payload)

    # Check for existing record
    existing = db.execute(
        select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == clean_key)
    ).scalar_one_or_none()

    if existing is not None:
        # Check payload and operation match
        if existing.operation_type != operation_type or existing.request_payload_hash != payload_hash:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error_code": "IDEMPOTENCY_PAYLOAD_MISMATCH",
                    "message": "A chave de idempotencia informada ja foi utilizada para uma requisicao diferente."
                }
            )

        # Check in-flight lock
        now = utc_now()
        locked_until = existing.locked_until
        if locked_until is not None:
            if locked_until.tzinfo is None and now.tzinfo is not None:
                locked_until = locked_until.replace(tzinfo=datetime.timezone.utc)
            if existing.response_status_code == 0 and locked_until > now:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error_code": "REQUEST_IN_PROGRESS",
                        "message": "Operacao com esta chave de idempotencia ja esta em processamento."
                    }
                )

        if existing.response_status_code > 0:
            # Replay stored response without mutating stock or commercial data
            return IdempotencyResult(
                response_body=existing.response_body,
                status_code=existing.response_status_code,
                is_replay=True
            )

        # In-flight lock has expired without completion: reuse and re-lock existing record
        record = existing
        record.locked_until = now + datetime.timedelta(seconds=30)
        db.flush()
    else:
        # Key is new: create initial in-flight record
        record = IdempotencyRecord(
            id=str(uuid.uuid4()),
            idempotency_key=clean_key,
            operation_type=operation_type,
            request_payload_hash=payload_hash,
            response_status_code=0,
            response_body="",
            locked_until=utc_now() + datetime.timedelta(seconds=30),
            created_at=utc_now(),
        )
        db.add(record)
        db.flush()

    try:
        status_code, result = business_callback(db)
        body = json.dumps(result, ensure_ascii=False) if not isinstance(result, str) else result

        record.response_status_code = status_code
        record.response_body = body
        record.locked_until = None
        db.commit()

        return IdempotencyResult(response_body=body, status_code=status_code, is_replay=False)
    except Exception:
        db.rollback()
        raise
