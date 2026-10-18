import asyncio


class DatabaseGate:
    """Single-worker request barrier: maintenance excludes all database requests."""

    def __init__(self):
        self.condition = asyncio.Condition()
        self.readers = 0
        self.writer = False
        self.waiting_writers = 0

    async def acquire(self, exclusive):
        async with self.condition:
            if exclusive:
                self.waiting_writers += 1
                try:
                    await self.condition.wait_for(lambda: not self.writer and not self.readers)
                    self.writer = True
                finally:
                    self.waiting_writers -= 1
                    self.condition.notify_all()
            else:
                await self.condition.wait_for(lambda: not self.writer and not self.waiting_writers)
                self.readers += 1

    async def release(self, exclusive):
        async with self.condition:
            if exclusive:
                self.writer = False
            else:
                self.readers -= 1
            self.condition.notify_all()


class DatabaseMaintenanceMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope['type'] != 'http':
            return await self.app(scope, receive, send)
        gate = scope['app'].state.database_gate
        exclusive = scope['method'] == 'POST' and scope['path'] in {
            '/api/v1/backup/new-database', '/api/v1/backup/restore'}
        await gate.acquire(exclusive)
        try:
            await self.app(scope, receive, send)
        finally:
            await gate.release(exclusive)
