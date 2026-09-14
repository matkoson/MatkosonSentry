# MatkosonSentry

Shared Sentry bootstrap for Matkoson macOS fleet apps (self-hosted DSN via `.env`).

```swift
import MatkosonSentry

_ = MatkosonSentry.bootstrap(.init(app: "menubar"))
```

DSN env keys (first match wins): `SENTRY_DSN_<APP>`, `SENTRY_DSN`, `MATKOSON_SENTRY_DSN`.
