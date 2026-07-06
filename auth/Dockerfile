FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libldap2-dev libsasl2-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8081
CMD ["gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "--timeout", "30", "app.main:app"]
