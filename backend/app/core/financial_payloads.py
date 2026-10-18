"""Bound structured request bodies without buffering documents or other APIs."""
from starlette.responses import JSONResponse


class FinancialPayloadLimitMiddleware:
    def __init__(self, app, prefix):
        self.app, self.prefix = app, prefix

    async def __call__(self, scope, receive, send):
        path = scope.get("path", "")
        if scope["type"] != "http" or not path.startswith(self.prefix + "/") or path == self.prefix + "/documents":
            return await self.app(scope, receive, send)
        if scope["method"] not in ("POST", "PUT", "PATCH"):
            return await self.app(scope, receive, send)
        messages, size = [], 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            size += len(message.get("body", b""))
            if size > 2 * 1024 * 1024:
                response = JSONResponse(status_code=413, content={"detail": {
                    "error_code": "FINANCIAL_PAYLOAD_TOO_LARGE", "message": "Dados estruturados acima de 2 MiB.",
                }}, headers={"Cache-Control": "no-store"})
                return await response(scope, receive, send)
            messages.append(message)
            if not message.get("more_body", False):
                break
        position = 0

        async def replay():
            nonlocal position
            if position < len(messages):
                message = messages[position]
                position += 1
                return message
            return await receive()

        await self.app(scope, replay, send)
