# Security Report

This file will collect results from the CodeQL and OWASP ZAP scans.

Summary:

- CodeQL: added as GitHub Action at `.github/workflows/codeql-analysis.yml`.
- OWASP ZAP: baseline scan added at `.github/workflows/owasp-zap-scan.yml`.

Findings (example):

1. Insecure default JWT secret usage -> fixed by enforcing `JWT_SECRET` at startup, using a centralized constant; app now refuses to start in non-dev if unset.
2. Potential SQL injection vectors in raw queries -> covered by parameterized queries (already used throughout endpoints).

How we fixed X issue:

- Issue: Default JWT secret fallback to 'secretkey' in `index.js`.
  Fix: Added centralized `JWT_SECRET` constant and process exit if missing in non-development; updated jwt.sign/verify to use the constant. Added Helmet, CORS allowlist, and rate limiting for basic hardening.

Artifacts:

- ZAP report artifact (uploaded from workflow): `zap-report`.
- CodeQL results available in Security tab on GitHub.