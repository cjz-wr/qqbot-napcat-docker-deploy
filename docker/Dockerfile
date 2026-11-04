# Build with the backend checkout as context, not this deployment repository.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    TZ=Asia/Shanghai

WORKDIR /app
COPY requirements.txt ./
ARG PIP_USE_DEPRECATED
RUN python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip check \
    && groupadd --gid 10001 qqbot \
    && useradd --uid 10001 --gid qqbot --home-dir /app --no-create-home qqbot \
    && mkdir -p /app/data /app/logs /app/mface /app/plugins \
    && chown -R qqbot:qqbot /app

COPY --chown=qqbot:qqbot app/ ./app/
COPY --chown=qqbot:qqbot scripts/*.py ./scripts/
COPY --chown=qqbot:qqbot plugins/ ./plugins/
USER qqbot
EXPOSE 8881
VOLUME ["/app/data", "/app/logs", "/app/mface"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; r = urllib.request.urlopen('http://127.0.0.1:8881/healthz', timeout=3); assert r.status == 200"
CMD ["python", "-m", "app", "--host", "0.0.0.0", "--port", "8881"]
