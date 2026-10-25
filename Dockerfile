# syntax=docker/dockerfile:1
FROM python:3.12-slim-bookworm

COPY --from=ghcr.io/astral-sh/uv:0.13.4 /uv /uvx /bin/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    PATH="/app/.venv/bin:$PATH" \
    HOST=0.0.0.0 \
    PORT=8791 \
    HF_HOME=/home/app/.cache/huggingface \
    EXPLORER_NAMES_FILE=/app/explorer/cache/names.json

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

COPY explorer/ ./explorer/
COPY sweep/ ./sweep/

RUN useradd --create-home --uid 1000 app \
    && mkdir -p runs stats /home/app/.cache/huggingface \
    && chown -R app:app /app /home/app

USER app
EXPOSE 8791

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8791/api/status', timeout=4)" || exit 1

CMD ["python", "explorer/server.py"]
