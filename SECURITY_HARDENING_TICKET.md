# [SECURITY] Backend Services Hardening — OWASP Top 10 Compliance

> **Scope:** All Django backend microservices (`auth-service`, `product-service`, `baker-service`, `order-service`, `payment-service`, `admin-service`, `analytics-service`, `display-service`, `favorite-service`, `message-service`, `notification-service`, `review-service`, `search-service`, `subscription-service`, `user-service`).
>
> **Reference services (witness):** `auth-service`, `product-service`. All other services are structured identically — reuse the same patterns.
>
> **Goal:** Bring every service to at least **OWASP Top 10 (2021) compliance**, fix every known vulnerability, and enforce secure defaults everywhere.
>
> **Mode:** Autonomous — the agent must analyze, plan, patch, test, and document each fix. It must **not** break existing public API contracts unless the fix is impossible without a breaking change (in that case, the change must be documented in a migration note).

---

## 0. Operating rules for the agent

1. Work service by service. For each service:
   - Branch from `develop` with `security/hardening-<service>`.
   - Apply every fix listed below that applies to this service.
   - Run the existing test suite (`./run_integration_tests.sh` or `python manage.py test`) before committing.
   - Add / update unit tests for every new security control (see §12).
   - Commit in atomic commits grouped by OWASP category (one commit per section of this ticket).
   - Open a PR against `develop` with the completion checklist (see §13) filled in.
2. **Never** commit real secrets, `.env`, `.env.freebox`, `VERSION` tarballs, `__pycache__`, or coverage artifacts.
3. When a fix requires a shared utility, create it under `core/security/` in the service; if the same util is needed in 3+ services, factor it into a shared package and document it.
4. When a fix is impossible without infra / DevOps change (e.g. TLS termination), stop and produce a follow-up ticket instead of hacking a workaround.

---

## 1. OWASP A01 — Broken Access Control

### 1.1 Privilege escalation via `group_id` in registration (CRITICAL — auth-service)

**Location:** `accounts/serializers.py` `UserSerializer`, `accounts/views.py` `RegisterView`.

**Problem:** `group_id` is accepted from the client body during `POST /register/` and assigned to the user. A malicious client can register as `group_id=1` (admin) directly.

**Fix:**
- Remove `group_id` from `UserSerializer.Meta.fields` for the public registration path.
- Force the default group to `2` (User) server-side in `create_user()`.
- Create a separate admin-only endpoint (`POST /admin/users/` with `IsAdminUser`) that can set `group_id`, protected by `permission_classes = [IsAdminOrStaff]`.
- Add a regression test that proves `POST /register/` with `group_id=1` does **not** create an admin.

### 1.2 Unauthenticated password change (CRITICAL — auth-service)

**Location:** `accounts/views.py` `ForgotPasswordView.post()`.

**Problem:** Accepts `{email, new_password}` and changes the password directly. The `authentication_classes = [JWTAuthentication]` is set but `permission_classes = [AllowAny]` overrides the gate — any anonymous caller can reset any user's password.

**Fix:**
- Delete `ForgotPasswordView` entirely, or require a valid `reset_token` (already implemented by `ResetPasswordView` flow). Keep only the 3-step flow: request → verify → reset.
- Ensure the old endpoint is removed from `urls.py` and return `404` for old paths.
- Add integration test verifying anonymous callers get `401/403` on any password mutation route except the proper reset flow.

### 1.3 Reset token reuse (HIGH — auth-service)

**Location:** `accounts/views.py` `ResetPasswordView.post()`.

**Problem:** `ResetPasswordView` filters `PasswordResetCode.objects.get(id=reset_token, user=user, is_used=True)` — a used code remains a valid reset token forever. Any leaked `reset_token` UUID can reset the password repeatedly.

**Fix:**
- Add a `consumed_at` timestamp on `PasswordResetCode`.
- After a successful password reset, set `consumed_at=now()` and ensure the filter excludes consumed tokens.
- Reject tokens older than 10 minutes at the reset step too (not only at verify step).
- Invalidate all other outstanding tokens for the same user upon successful reset.

### 1.4 Horizontal privilege (IDOR) audit (HIGH — all services)

**Problem:** Several endpoints trust `product_id`, `baker_id`, `order_id`, `user_id` coming from the body without verifying the caller owns the resource. The current `ProductObjectPermission` only covers the DRF `get_object` path — custom actions (`create_variants`, `create_images`, `create_categories`, `create_allergens`, `create_quantity_rules`, `update_variants`, `update_categories`, `update_images`, `create_full_product`) must all go through `check_product_permission`.

**Fix (witness: `product-service/products/views.py`):**
- Audit every `@action` and every method on `ProductViewSet`. Ensure `check_product_permission(request, product)` is invoked **before** any mutation and **before** any DB read that exposes ownership-sensitive data.
- Replicate the same audit for every service (e.g. `order-service/orders/views.py`, `favorite-service`, `message-service`, etc.).
- In `create_full_product`, when `group_id == 1` (admin) and the caller provides `user_id`, verify the target user exists and is a baker. Reject if not.
- Replace the `raw SQL → ORM fallback` ownership check with a single, well-tested helper `services/security/ownership.py::assert_user_owns(<resource>, user)`.

### 1.5 Default `IsAuthenticated` (MEDIUM)

- `product-service` sets `DEFAULT_PERMISSION_CLASSES = (IsAuthenticated,)` — good. `auth-service` does **not** — it defaults to `AllowAny`. Apply `IsAuthenticated` as the default in every service and explicitly opt-out on the small set of truly public endpoints (register, login, password reset, image stream, public product list).
- Forbid `permission_classes = []` anywhere; always state the intent explicitly.

### 1.6 Hard-coded group IDs (LOW)

- Replace magic numbers (`1`, `3`, `4`) with an `AuthGroup` enum shared from a common module (e.g. `core/security/groups.py::Group.ADMIN/USER/BAKER/...`).

---

## 2. OWASP A02 — Cryptographic Failures

### 2.1 Insecure `SECRET_KEY` fallback (CRITICAL — all services)

**Problem:** Both services fall back to a hardcoded `'django-insecure-(xes=q7t4od9t...'` if the env var is missing. This string is in the repo history.

**Fix:**
- Refuse to boot if `SECRET_KEY` is not set **and** `DEBUG=False`:

  ```python
  SECRET_KEY = os.environ["SECRET_KEY"]  # raises KeyError
  if not DEBUG and (SECRET_KEY.startswith("django-insecure-") or len(SECRET_KEY) < 50):
      raise ImproperlyConfigured("SECRET_KEY is not production-grade")
  ```
- Rotate the current production `SECRET_KEY` and `JWT_SECRET_KEY` (coordinate with DevOps — document the rotation procedure).
- Remove the string literal from every settings file.
- Add a pre-commit hook (`detect-secrets` or `gitleaks`) in each service.

### 2.2 JWT signing key == Django SECRET_KEY (MEDIUM)

**Problem:** `SIMPLE_JWT.SIGNING_KEY = SECRET_KEY`. A leak of the Django session key also compromises every issued JWT.

**Fix:**
- Introduce a dedicated `JWT_SIGNING_KEY` env var, distinct from `SECRET_KEY`.
- Prepare the ground for `ALGORITHM='RS256'` (asymmetric): add optional `JWT_PUBLIC_KEY` / `JWT_PRIVATE_KEY` settings, keep `HS256` as default for backward compatibility, but document the migration.

### 2.3 Access token lifetime too long (MEDIUM)

- `ACCESS_TOKEN_LIFETIME=12h` is excessive. Target: `15min` access / `7d` refresh with rotation + blacklist.
- Enable `rest_framework_simplejwt.token_blacklist` in `INSTALLED_APPS` (currently missing from both services despite `BLACKLIST_AFTER_ROTATION=True` — the rotation blacklist does nothing without the app).
- Add `POST /logout/` endpoint that blacklists the current refresh token.

### 2.4 Non-cryptographic RNG for reset codes (HIGH — auth-service)

**Location:** `accounts/views.py:111` — `code = ''.join(random.choices(string.digits, k=6))`.

**Fix:**
- Replace `random` with `secrets.choice`/`secrets.randbelow` for password reset codes, API keys, nonces, CSRF-like tokens, etc.
- Increase the reset code to 8 digits OR issue a signed URL token (itsdangerous / djangorestframework-simplejwt sliding token with short TTL).
- Rate-limit the verify step to prevent brute force of the 6-digit space (see §9).
- Lock an account after N (e.g. 5) failed verify attempts on the same code.

### 2.5 Password policy consistency (LOW)

- `AUTH_PASSWORD_VALIDATORS` doesn't set `OPTIONS={'min_length': 12}` on `MinimumLengthValidator`. The serializer enforces 8; Django validators enforce 8 by default. Unify to 12, and keep upper/lower/digit/special complexity checks at the serializer level.
- Wrap password validation in `django.contrib.auth.password_validation.validate_password(value, user)` so the policy is enforced both on register and on reset.

### 2.6 Password hashing (INFO)

- Django defaults to `PBKDF2`. Verify `PASSWORD_HASHERS` is not overridden anywhere. Consider adding `argon2` (via `argon2-cffi`) as first hasher for future-proofing.

### 2.7 Sensitive data at rest (MEDIUM)

- Ensure database column encryption / TLS between app and Postgres. Add `OPTIONS={'sslmode': 'require'}` to `DATABASES['default']` when `not DEBUG`.

---

## 3. OWASP A03 — Injection

### 3.1 Raw SQL audit (HIGH — product-service, order-service, baker-service)

**Problem:** `product-service/products/views.py` contains many `cursor.execute("...")` calls. Parameters are mostly passed via `%s` placeholders (good), but at least one f-string interpolates a column name:

```python
cursor.execute(f"UPDATE product SET {_baker_col} = %s WHERE id = %s", [baker_id, product.id])
```

`_baker_col` is validated against `('baker_id', 'bakerid')` — acceptable but fragile.

**Fix:**
- Replace raw SQL by ORM whenever feasible (drop `managed=False` or introduce proxy/unmanaged models with explicit FKs).
- For the legitimate remaining raw queries, centralize them in a `products/sql.py` module, use a whitelist constant for identifiers, and add unit tests that assert no untrusted data ever reaches an f-string.
- Add `ruff`/`bandit` to CI. Configure `bandit` to fail on `B608` (hardcoded SQL expressions).

### 3.2 Schema manipulation inside request handler (CRITICAL)

**Location:** `product-service/products/views.py` `create()` — executes `CREATE TABLE IF NOT EXISTS product_user ...` inside an HTTP request.

**Fix:**
- Remove all DDL from runtime code. Table creation must happen via a dedicated management command or a SQL migration shipped in `scripts/`.
- Make the service fail fast at startup if `product_user` is missing (a healthcheck query).

### 3.3 User-controlled filename → path traversal (HIGH — product-service storage)

**Location:** `products/storage.py::build_image_key` + `products/views.py::create_images`.

**Problem:** `filename = raw_imageurl.split('/')[-1] if raw_imageurl else uploaded_file.name` — `split('/')` does not defend against `\`, null bytes, unicode normalization, or `..` sequences that come from the client `imageurl` field.

**Fix:**
- Replace custom splitting with `pathlib.PurePosixPath(name).name` + re-run through `werkzeug.utils.secure_filename` or equivalent.
- Reject filenames containing `..`, `/`, `\`, null bytes, or starting with a dot.
- Force extension against an allow-list: `{"jpg", "jpeg", "png", "webp", "heic"}`.
- Generate a server-side UUID-based filename and keep the original only in DB for display.
- Verify `os.path.realpath(target_path).startswith(os.path.realpath(PRODUCT_IMAGES_ROOT))` before every write and read.
- Enforce the same check on `source_path` in `save_image_local` (relative paths are currently resolved against `PRODUCT_IMAGES_ROOT` but escape via symlink is possible).

### 3.4 File upload content validation (HIGH)

- Enforce `MAX_UPLOAD_SIZE_MB=10`. Reject larger with `413`.
- Detect MIME from file magic (`python-magic`), not from client-supplied `content_type`. Reject if mismatch with extension.
- Re-encode images through Pillow (`Image.open().verify()` + `Image.open().save()`) to strip EXIF and prevent polyglot files.
- Scan with `clamav` in production (optional follow-up).

### 3.5 NoSQL / header / log injection (LOW)

- Audit every `logger.info/warning/error` call that includes request data — sanitize newlines (`%r` format) to avoid log forging.
- Add `django-ratelimit` protection on endpoints receiving JSON to mitigate JSON-bomb payloads.

---

## 4. OWASP A04 — Insecure Design

### 4.1 Rate limiting (HIGH — all services, especially auth-service)

**Problem:** No throttling on `/login/`, `/register/`, `/password-reset/request/`, `/password-reset/verify/`, `/password-reset/reset/`, `/token/refresh/`. Open to credential stuffing and 6-digit code brute force.

**Fix:**
- Add `django-ratelimit` (or DRF `AnonRateThrottle` + `UserRateThrottle` + custom `ScopedRateThrottle`).
- Default rates:
  - Anonymous POST: `5/min` per IP + `30/hour` per IP.
  - `/login/`: `5/min` per IP + `10/min` per email.
  - `/password-reset/request/`: `3/hour` per email.
  - `/password-reset/verify/`: `10/hour` per email; auto-block after 10 failures on the same code.
- Configure DRF:

  ```python
  REST_FRAMEWORK = {
      ...,
      'DEFAULT_THROTTLE_CLASSES': [
          'rest_framework.throttling.AnonRateThrottle',
          'rest_framework.throttling.UserRateThrottle',
      ],
      'DEFAULT_THROTTLE_RATES': {
          'anon': '60/min',
          'user': '240/min',
          'login': '10/min',
          'password_reset': '5/hour',
      },
  }
  ```
- Add a Redis backend (`DJANGO_REDIS_URL`) as cache so throttling is shared across processes/pods.

### 4.2 User enumeration (MEDIUM — auth-service)

**Location:** `RequestPasswordResetView` returns `404 "Aucun utilisateur trouvé avec cet email."`, `ForgotPasswordView` too, `VerifyResetCodeView` returns distinguishable error messages.

**Fix:**
- Return the same generic `200 OK` message whether the email exists or not on password reset request.
- Return the same error on invalid code vs non-existent user on verify.
- Constant-time comparison for codes (`hmac.compare_digest`).
- Keep the existing timing-attack mitigation in `EmailBackend` (good) and replicate it anywhere a user is looked up from user input.

### 4.3 Account lockout / breach detection (MEDIUM)

- Track failed login attempts per email (Redis counter with TTL).
- Lock the account for 15 minutes after 10 failures; log a security event.
- Add a `last_failed_login` and `failed_login_count` columns on `AccountsUser`.

### 4.4 Email verification on registration (MEDIUM)

- `RegisterView` creates an active account immediately. Add `is_active=False` + email verification flow (reuse the notification-service).
- Document the migration for existing users.

### 4.5 Multi-factor authentication (LOW — follow-up)

- Out of scope for this ticket, but create a follow-up ticket: add TOTP-based 2FA (`django-otp`) for admins and optionally bakers.

---

## 5. OWASP A05 — Security Misconfiguration

### 5.1 Settings hardening (CRITICAL — all services)

Unify every `core/settings.py` so the following holds:

```python
DEBUG = os.environ.get("DEBUG", "False") == "True"

if not DEBUG:
    ALLOWED_HOSTS = [h for h in os.environ["ALLOWED_HOSTS"].split(",") if h]
    assert ALLOWED_HOSTS and "*" not in ALLOWED_HOSTS, "Invalid ALLOWED_HOSTS in prod"

    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    CSRF_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    CSRF_COOKIE_SAMESITE = "Lax"
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"
    X_FRAME_OPTIONS = "DENY"
    SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
```

- Remove `ALLOWED_HOSTS = ['*']` from `auth-service`.
- Never allow `DEBUG=True` by default — default must be `"False"`.
- Replace `CORS_ALLOW_ALL_ORIGINS = True` with an explicit `CORS_ALLOWED_ORIGINS` list read from env, even on Freebox. Add `CORS_ALLOWED_ORIGIN_REGEXES` for preview domains.
- Never ship secrets in `docker-compose.yml` defaults.

### 5.2 `django-csp` / Content-Security-Policy (MEDIUM)

- Install `django-csp`. Add a strict default-src self policy, no unsafe-inline, no unsafe-eval. Allow the S3/CloudFront domain serving images.

### 5.3 Dockerfile hardening (HIGH)

**Location:** `auth-service/Dockerfile`, same pattern in every service.

**Problems:**
- Runs as `root`.
- Uses `python manage.py runserver 0.0.0.0:8000` (dev server, single-threaded, no TLS).
- APT packages not pinned.
- Build context leaks `.env`, `venv/`, `__pycache__/`, tarballs — add a `.dockerignore`.

**Fix:**
- Add a non-root user (`RUN useradd -m -u 10001 app && USER app`).
- Switch to `gunicorn --workers 3 --bind 0.0.0.0:8000 core.wsgi` (install `gunicorn` in requirements).
- Pin base image by digest (`python:3.11-slim@sha256:...`).
- Add `HEALTHCHECK CMD curl -f http://localhost:8000/health/ || exit 1` and a `/health/` endpoint.
- Multi-stage build to keep image small and without `gcc`/`libpq-dev` in runtime stage.
- Add `.dockerignore` with `.env*`, `.git`, `venv/`, `__pycache__/`, `*.tar.gz`, `*.pyc`, `logs/`, `test_results*`, `integration_test_output*`, `coverage/`.

### 5.4 Admin panel (MEDIUM)

- `django.contrib.admin` is installed everywhere. In production, either:
  - Expose it only on an internal network, or
  - Protect it with IP allow-list + mandatory 2FA (`django-admin-honeypot`, `django-otp-admin`).
- Disable `admin` entirely on services that don't need it (payment, notification, message, search).

### 5.5 Committed artifacts (HIGH)

Listed in `git status`:
- `Station-Avoine-1200x675-1.jpg` (product-service)
- `VERSION`, `test_results.*`, `test_output.txt`, `integration_test_output*.txt`, `coverage/`, `__pycache__/`, `*.tar.gz`

**Fix:** update every service `.gitignore`, remove these from the tree with `git rm --cached`, and add a CI job `git ls-files | grep -E '(__pycache__|\.pyc|\.tar\.gz|test_results)'` that fails the build if any of these re-appear.

### 5.6 `MIGRATION_MODULES = { 'accounts': None, ... }` (MEDIUM)

- Migrations are disabled everywhere (every model is `managed=False`). This couples the services to an external schema and prevents Django from tracking changes, security patches to auth tables, etc.
- At minimum: document this explicitly in each `README.md` and provide a runnable `scripts/schema.sql` that is the single source of truth, kept under version control, reviewed on PR.

---

## 6. OWASP A06 — Vulnerable & Outdated Components

### 6.1 Dependencies audit (HIGH)

- `auth-service/requirements.txt`:
  - `Django==5.1.6` — check current CVEs for 5.1.x; upgrade to latest `5.1.x` or `5.2 LTS`.
  - `djangorestframework==3.15.0` — OK.
  - `djangorestframework-simplejwt==5.3.1` — OK.
  - `python-jose[cryptography]==3.3.0` — known CVEs (CVE-2024-33664 algorithm confusion, CVE-2024-33663). **Remove** `python-jose` — `djangorestframework-simplejwt` already relies on `PyJWT`. Delete the dependency if unused.
  - `passlib==1.7.4` — project is de facto unmaintained; audit usage, replace with `argon2-cffi` / Django built-in hashing.
  - `bcrypt==4.1.2` — check latest.
  - `requests==2.31.0` — upgrade to `>=2.32.3` (CVE-2024-35195).
- `product-service/requirements.txt`:
  - `djangorestframework==3.14.0` — **upgrade to 3.15.2+** (several security advisories on 3.14).
  - `psycopg2-binary==2.9.9` — OK, but align to `psycopg[binary]>=3.2` to match auth-service.
  - `Pillow==10.2.0` — multiple CVEs (CVE-2024-28219, heap overflow). **Upgrade to `>=10.3.0`** (or `>=11.x`).

**Fix:**
- Run `pip-audit` (or `safety check`) in CI for every service. Fail the build on HIGH/CRITICAL.
- Add `Dependabot` / `Renovate` config at the repo root.
- Pin indirect deps via `pip-compile` (introduce `requirements.in` + generated `requirements.txt`).

### 6.2 Base image CVEs

- Run `trivy image` / `grype` on each service image in CI; fail on HIGH+.

---

## 7. OWASP A07 — Identification & Authentication Failures

### 7.1 JWT configuration (HIGH)

- Enable `rest_framework_simplejwt.token_blacklist` in every service's `INSTALLED_APPS` and run the migrations (even if `MIGRATION_MODULES` override needs to be relaxed for that app only).
- Set `UPDATE_LAST_LOGIN=True`.
- Tighten `SIMPLE_JWT`:

  ```python
  SIMPLE_JWT = {
      "ALGORITHM": "HS256",  # or RS256 when rolled out
      "SIGNING_KEY": os.environ["JWT_SIGNING_KEY"],
      "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
      "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
      "ROTATE_REFRESH_TOKENS": True,
      "BLACKLIST_AFTER_ROTATION": True,
      "AUTH_HEADER_TYPES": ("Bearer",),
      "LEEWAY": 0,
      "USER_ID_FIELD": "id",
      "USER_ID_CLAIM": "user_id",
      "TOKEN_TYPE_CLAIM": "token_type",
      "AUDIENCE": "patisry-api",
      "ISSUER": "auth-service",
  }
  ```
- Every downstream service must **verify** `iss`, `aud`, and signature. Shared JWT public key or shared signing key must be injected via env — currently each service uses its own `JWT_SECRET_KEY` or worse falls back to Django `SECRET_KEY`. Unify.

### 7.2 Session management (MEDIUM)

- Since authentication is JWT-only, disable session auth in DRF and remove `django.contrib.sessions` from middleware for API-only services (keep it for the admin if it is used).

### 7.3 CSRF on state-changing endpoints (INFO)

- JWT endpoints with `Authorization: Bearer ...` are CSRF-safe because they don't rely on cookies. Keep `CsrfViewMiddleware` for the admin panel only.

### 7.4 Password logging (HIGH — auth-service)

**Location:** `RequestPasswordResetView.post()` logs `f"User ID: {user.id}, Email: {email}, Code: {code}, Reset Type: ..."`. The **plain-text 6-digit code** is written to `django.log`.

**Fix:**
- Strip sensitive fields (codes, tokens, passwords) from every `logger.*` call. Add a redaction filter (`logging.Filter`) that masks patterns like `password=...`, `code=\d{6}`, `Bearer ...`, `reset_token=...`.
- Never include `str(e)` or `traceback.format_exc()` in the HTTP response body (`RequestPasswordResetView` returns `details` when `DEBUG=True`; remove this block — DEBUG must never be true in prod, and even in dev it should not leak DB error strings to clients in production-like tests).

---

## 8. OWASP A08 — Software & Data Integrity Failures

### 8.1 Supply-chain (MEDIUM)

- Verify every `pip install` in Dockerfiles uses `--require-hashes` against a `requirements.txt` generated via `pip-compile --generate-hashes`.
- Sign Docker images (cosign) — produce a follow-up ticket if infra is not ready.

### 8.2 Deserialization

- No direct `pickle.loads` of user input detected. Confirm with `bandit -r .` per service.

### 8.3 Serializer field whitelisting (HIGH)

- Several DRF serializers in witness services include `__all__` or expose internal flags (`is_staff`, `is_superuser`, `group_id`). Explicit `fields = [...]` is already used in `UserSerializer` but `is_staff`/`is_superuser` must never be writable via the public API. Add a test that POSTs `is_staff=true` and proves it is ignored.

---

## 9. OWASP A09 — Security Logging & Monitoring Failures

### 9.1 Structured logging (MEDIUM)

- Replace string-format logs with structured logging (JSON via `python-json-logger`) in each service.
- Log a dedicated `security` channel for: login success/failure, token refresh, token blacklist, 401/403 events, rate-limit hits, password reset lifecycle, admin actions.
- Include `request_id`, `user_id`, `ip`, `ua` in every security log line.

### 9.2 Log retention & integrity

- Do not write to `logs/django.log` inside the container filesystem. Log to stdout (Twelve-Factor) and let Docker / Promtail / Loki ship them.
- Remove the `file` handler in `LOGGING` and delete any `logs/` directory.

### 9.3 Metrics & alerts

- Expose a `/metrics` endpoint (Prometheus via `django-prometheus`). Add alert rules for: `5xx` spikes, auth-failure spikes, rate-limit hits > N/min.

### 9.4 `exc_info` leakage (LOW)

- Several views emit `logger.error(f"... {error_msg}")` with the raw exception text returned to the client. Split: log full traceback, return a generic 500 with a correlation ID.

---

## 10. OWASP A10 — Server-Side Request Forgery (SSRF)

- Audit every outbound call. Known potential outbound calls:
  - `notification-service` → email/SMS gateway.
  - `payment-service` → payment provider.
  - S3 (`product-service.storage.py`).
- For any URL taken from user input (image URLs, webhook registrations, avatars), use an allow-list of domains, block RFC 1918 / link-local / 169.254 / 127.0.0.1 resolution, and use a dedicated HTTP client with a DNS pin.
- No current direct SSRF was identified in `auth-service` or `product-service`; confirm in the remaining services and add a `core/security/http.py::safe_get()` helper.

---

## 11. Cross-cutting extras (beyond OWASP Top 10)

### 11.1 CORS (HIGH)

- `auth-service` has `CORS_ALLOW_ALL_ORIGINS = True` unconditionally. `product-service` has it when `FREEBOX_ENV=True`. Replace with explicit lists loaded from env, identical across services.
- Document the canonical allowed origins list in `Documentations/`.

### 11.2 `ALLOWED_HOSTS` / Host header attack (MEDIUM)

- Remove `'*'` everywhere. Build from env.

### 11.3 Request size limits (MEDIUM)

- `DATA_UPLOAD_MAX_MEMORY_SIZE` and `FILE_UPLOAD_MAX_MEMORY_SIZE` must be explicit (`5 * 1024 * 1024` for JSON, `10 * 1024 * 1024` for files).
- `DATA_UPLOAD_MAX_NUMBER_FIELDS = 1000`.

### 11.4 Error responses (MEDIUM)

- Install a global exception handler in `core/exceptions.py` for every service (auth-service already has `core.exceptions.custom_exception_handler` — replicate). It must:
  - Never return `str(e)` or tracebacks.
  - Always return `{"error": "...", "code": "...", "request_id": "..."}`.
  - Map known exceptions to specific HTTP statuses.

### 11.5 Secure defaults in `core/exceptions.py`

- Add a `core/security/` package with:
  - `ownership.py`: reusable resource-ownership checks.
  - `http.py`: hardened HTTP client.
  - `tokens.py`: secrets-based code generator.
  - `files.py`: filename sanitizer, extension allow-list, MIME sniffer.
  - `logging.py`: secret redaction filter.
  - `throttles.py`: custom DRF throttle classes.

### 11.6 Environment-variable validation (MEDIUM)

- Add `django-environ` or a custom `core/env.py` that validates required variables at startup: `SECRET_KEY`, `JWT_SIGNING_KEY`, `POSTGRES_*`, `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS`. Fail loud on `ImproperlyConfigured`.

### 11.7 `.env.freebox` committed (CRITICAL if contains secrets)

- `auth-service/.env.freebox` and `user-service/.env.freebox` appear in `git status` as modified. Verify they contain only placeholder values. If they hold real secrets, rotate immediately and move them out of git.

### 11.8 `managed = False` + DDL in views

- Already covered in §3.2 — repeat here as a reminder that schema changes must go through `scripts/schema.sql`, not runtime code.

### 11.9 Admin user creation (LOW)

- Ensure no `create_superuser("admin", "admin")` is called in any `entrypoint.sh`. Scan all `entrypoint.sh` / `setup_freebox_env.sh` for hardcoded credentials.

---

## 12. Testing requirements

For each fix, add a test in `<service>/<app>/tests/` or `<service>/tests/security/`:

1. **Privilege escalation on registration**: POST `/register/` with `group_id=1` → assert created user has group `2`.
2. **Unauthenticated password change**: assert deprecated endpoint returns 404/410.
3. **Reset token reuse**: after one successful reset, the same token must return 400.
4. **IDOR**: baker A tries to PATCH baker B's product → 403.
5. **Rate limit**: 11th call to `/login/` within a minute → 429.
6. **Brute force**: 11 wrong verify codes → 429 + account cooldown.
7. **User enumeration**: same response body on existing vs non-existing email for password-reset request.
8. **Password policy**: weak passwords rejected on both register and reset.
9. **JWT blacklist**: blacklisted refresh token cannot be used.
10. **File upload**: oversized → 413, wrong MIME → 400, path traversal filename → 400.
11. **Path traversal storage**: crafted `imageurl=../../etc/passwd` → 400.
12. **DEBUG leak**: 500 responses never include tracebacks.
13. **CORS**: Origin not in allow-list → no `Access-Control-Allow-Origin` header.
14. **Security headers**: `SecurityMiddleware` headers present on every response in prod settings.
15. **Bandit / pip-audit** pass in CI.

Target: ≥ 90% coverage of the new `core/security/` package; ≥ 80% overall.

---

## 13. Per-service completion checklist (copy into every PR)

```
## Security hardening — <service>

### A01 Access control
- [ ] No privilege escalation via registration
- [ ] All mutations go through ownership check
- [ ] Default permission class is IsAuthenticated
- [ ] Deprecated password-change endpoints removed / 410

### A02 Cryptography
- [ ] No hardcoded SECRET_KEY fallback
- [ ] Dedicated JWT_SIGNING_KEY
- [ ] Short access token, blacklist app enabled
- [ ] `secrets` used for reset codes / nonces
- [ ] DB TLS enabled

### A03 Injection
- [ ] Raw SQL audited, no f-string on identifiers without allow-list
- [ ] No DDL at runtime
- [ ] Filename sanitization + MIME sniffing
- [ ] Bandit clean

### A04 Insecure design
- [ ] Throttling on auth endpoints (login, register, reset flow, refresh)
- [ ] No user enumeration
- [ ] Account lockout after N failures

### A05 Misconfiguration
- [ ] Security headers set when DEBUG=False
- [ ] ALLOWED_HOSTS / CORS explicit
- [ ] Dockerfile: non-root, gunicorn, .dockerignore, pinned image
- [ ] Secrets / tarballs / __pycache__ not in git

### A06 Vulnerable components
- [ ] pip-audit clean
- [ ] python-jose removed (auth-service)
- [ ] Pillow >= 10.3
- [ ] DRF >= 3.15.2

### A07 Auth failures
- [ ] token_blacklist enabled and migrated
- [ ] JWT iss / aud enforced
- [ ] No secrets in logs

### A08 Integrity
- [ ] Serializer field allow-lists explicit, no is_staff writable
- [ ] --require-hashes in Docker build

### A09 Logging
- [ ] Stdout only, JSON logs
- [ ] security channel with request_id/user_id/ip
- [ ] No `str(e)` in responses
- [ ] /metrics endpoint

### A10 SSRF
- [ ] Outbound HTTP uses safe client with allow-list

### Tests
- [ ] Security test file added
- [ ] Coverage ≥ 80%
- [ ] CI green (bandit, pip-audit, trivy)
```

---

## 14. Definition of done

- All 15 services have merged their `security/hardening-<service>` branches into `develop`.
- CI pipelines include `bandit`, `pip-audit`, `trivy`, and the new security test suite; all green.
- No high/critical CVE in any image or dependency file.
- SECRET_KEY and JWT_SIGNING_KEY rotated in every environment.
- Documentation updated:
  - `Documentations/SECURITY.md` — final hardened configuration + threat model summary.
  - `Documentations/SECURITY_CHANGELOG.md` — one entry per fix, per service.
- A manual penetration test (or OWASP ZAP baseline scan) runs against `staging` and returns no HIGH finding.

---

## Appendix A — Witness-service anchor references

Use these exact lines as the canonical "before" state when writing migration notes:

```33:36:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/core/settings.py
SECRET_KEY = os.getenv(
    'JWT_SECRET_KEY',
    os.getenv('SECRET_KEY', 'django-insecure-(xes=q7t4od9t%59zit6)#84rcqsig&e1^6@etqe2e9f*w%cw%')
)
```

```39:41:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/core/settings.py
DEBUG = os.getenv('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = ['*']
```

```166:167:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/core/settings.py
CORS_ALLOW_ALL_ORIGINS = True  # À modifier en production pour spécifier les origines autorisées
CORS_ALLOW_CREDENTIALS = True
```

```73:97:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/accounts/views.py
class ForgotPasswordView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = [JWTAuthentication]  # Si vous souhaitez protéger cette vue

    def post(self, request):
        user_model = get_user_model()
        email = request.data.get('email')
        new_password = request.data.get('new_password')
        ...
        user = user_model.objects.get(email=email)
        user.set_password(new_password)
        user.save()
```

```111:114:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/accounts/views.py
code = ''.join(random.choices(string.digits, k=6))
try:
    reset_code = PasswordResetCode.objects.create(user=user, code=code, reset_type=reset_type)
```

```12:19:/Users/anzembani/Documents/Personel/Dev/Backend/auth-service/accounts/serializers.py
class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    group_id = serializers.IntegerField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'password', 'first_name', 'last_name',
                 'phone_number', 'date_of_birth', 'city', 'country',
                 'postal_code', 'region', 'street', 'street_number',
                 'address_complement', 'group_id']
```

```261:268:/Users/anzembani/Documents/Personel/Dev/Backend/product-service/products/views.py
cursor.execute("""
    CREATE TABLE IF NOT EXISTS product_user (
        product_id INTEGER PRIMARY KEY REFERENCES product(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
        UNIQUE(product_id, user_id)
    )
""")
```

```292:302:/Users/anzembani/Documents/Personel/Dev/Backend/product-service/products/views.py
cursor.execute(
    "INSERT INTO product_user (product_id, user_id) VALUES (%s, %s)",
    [product.id, user_id]
)
if _baker_col:
    cursor.execute(
        f"UPDATE product SET {_baker_col} = %s WHERE id = %s",
        [baker_id, product.id]
    )
```

```14:18:/Users/anzembani/Documents/Personel/Dev/Backend/product-service/products/storage.py
def build_image_key(baker_id: int, product_id: int, filename: str) -> str:
    """
    Build a storage key of the form: bakerId/productId/filename.ext
    """
    return f"{baker_id}/{product_id}/{filename}"
```

These anchors must disappear or be transformed by the end of the ticket.
