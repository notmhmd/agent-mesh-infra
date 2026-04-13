# Upstream hub image (mem0/mem0-api-server) is linux/arm64-only; build OSS REST API for amd64.
# See: https://github.com/mem0ai/mem0/tree/main/server
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG MEM0_REF=main
RUN git clone --depth 1 --branch "${MEM0_REF}" https://github.com/mem0ai/mem0.git /tmp/mem0 \
    && cp -a /tmp/mem0/server/. /app/ \
    && rm -rf /tmp/mem0
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir "psycopg[binary,pool]" "langchain-neo4j" "rank-bm25"
RUN mkdir -p /app/history
EXPOSE 8000
ENV PYTHONUNBUFFERED=1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
