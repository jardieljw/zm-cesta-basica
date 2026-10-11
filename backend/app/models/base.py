import datetime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import DateTime

class Base(DeclarativeBase):
    pass

def utc_now() -> datetime.datetime:
    return datetime.datetime.now(datetime.timezone.utc)
