# ---------------------------------------------------------------------------
# Generic backend-service image (same recipe for all three services).
# The service listens on 0.0.0.0:$SERVICE_PORT so it is reachable from
# other containers on the Docker Compose network (i.e. from Nginx).
# No absolute host paths are referenced anywhere.
# ---------------------------------------------------------------------------
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    SERVICE_PORT=8000

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Structured service log lives under /app/data/service_logs (bind-mounted to
# ./data/service_logs on the host by docker-compose.yml)
RUN mkdir -p /app/data/service_logs

EXPOSE 8000

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${SERVICE_PORT} --log-level warning"]
