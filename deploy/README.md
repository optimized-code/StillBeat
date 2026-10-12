# Web deployment

Build:

```bash
tool/dev.sh build-web
```

Serve `build/web/` over **HTTPS** (browsers only allow camera access in a
secure context; `http://localhost` is the only exception). No server-side
code is needed and nothing is uploaded by the app.

## Required/recommended headers

`headers.conf` (nginx) and `_headers` (Netlify/Cloudflare Pages) in this
folder set:

| Header | Value | Why |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | HTTPS only |
| `Content-Security-Policy` | see files | Same-origin scripts/fonts; `wasm-unsafe-eval` for CanvasKit; `blob:` for export downloads; `connect-src 'self'` |
| `Permissions-Policy` | `camera=(self), microphone=(), geolocation=()` | Camera only for this origin |
| `Referrer-Policy` | `no-referrer` | |
| `X-Content-Type-Options` | `nosniff` | |
| `Cross-Origin-Opener-Policy` | `same-origin` | |

MIME types: `.wasm` must be served as `application/wasm`; `.mjs`/`.js` as
`text/javascript`.

Caching: `index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`
and `version.json` should be `no-cache`; everything else can be cached long
(file names change per build or are covered by the service worker).

Verify after deploy: open DevTools → Network during a measurement; all
requests must be to your origin.
