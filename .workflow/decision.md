# Decisions

## Deployment packaging

2026-11-04: Publish an independent deployment repository and register it as a
submodule. Image publishing accepts a configurable build input and optional
`SOURCE_REPO_TOKEN` for authentication. A deployment-owned Dockerfile uses a
multi-platform Python base, rather than inheriting an architecture-specific
digest from a local build. Runtime Compose has no local `build` or tar dependency.

Installers download to staging, preserve `.env`, and back up Compose during an
explicit update. The Compose project name remains `qqbot-napcat` by default, so
install-directory changes do not silently choose new named volumes.

Registry metadata confirmed that the existing public `1.1.10` image is AMD64
only. Compose therefore explicitly defaults the backend to `linux/amd64`;
native ARM64 can be selected after publishing a multi-platform version.
