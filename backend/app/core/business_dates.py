"""Civil business days; stored instants remain UTC (current business zone UTC-03)."""
import datetime

BUSINESS_TZ = datetime.timezone(datetime.timedelta(hours=-3))


def as_utc(value: datetime.datetime) -> datetime.datetime:
    return (value.replace(tzinfo=datetime.timezone.utc) if value.tzinfo is None
            else value.astimezone(datetime.timezone.utc))


def business_today(now: datetime.datetime) -> datetime.date:
    return as_utc(now).astimezone(BUSINESS_TZ).date()


def business_day_start(day: datetime.date) -> datetime.datetime:
    # Canonical representation of a chosen day, not an operator-supplied time.
    return datetime.datetime.combine(day, datetime.time.min, BUSINESS_TZ).astimezone(datetime.timezone.utc)
