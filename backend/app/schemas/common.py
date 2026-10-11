from typing import Optional, Any
from pydantic import BaseModel

class ErrorDetail(BaseModel):
    error_code: str
    message: str
    details: Optional[Any] = None

class ErrorResponse(BaseModel):
    detail: ErrorDetail
