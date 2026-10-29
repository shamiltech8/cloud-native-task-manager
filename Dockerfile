FROM python:3.12-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
COPY wheels/ /wheels/

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
    --timeout 300 \
    --retries 10 \
    --no-index \
    --find-links=/wheels \
    psycopg2-binary==2.9.12 \
    && pip install --no-cache-dir \
    --timeout 300 \
    --retries 10 \
    -r requirements.txt

COPY . .

# Create a dedicated non-root user
RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid 10001 \
       --no-create-home --shell /usr/sbin/nologin appuser \
    && chown -R 10001:10001 /app

# Run the application without root privileges
USER 10001:10001

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "run:app"]
