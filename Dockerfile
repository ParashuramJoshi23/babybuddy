# Multi-stage build for Baby Buddy
FROM node:18-slim AS frontend-builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node dependencies
RUN npm ci --include=dev

# Copy source files needed for build
COPY gulpfile*.js ./
COPY babybuddy/static_src ./babybuddy/static_src
COPY core/static_src ./core/static_src
COPY dashboard/static_src ./dashboard/static_src
COPY reports/static_src ./reports/static_src

# Build assets
RUN npx gulp build

# Python application stage
FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -u 1000 babybuddy && \
    mkdir -p /app/data && \
    chown -R babybuddy:babybuddy /app

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY --chown=babybuddy:babybuddy . .

# Copy built assets from frontend-builder
COPY --from=frontend-builder --chown=babybuddy:babybuddy /app/babybuddy/static ./babybuddy/static

# Switch to non-root user
USER babybuddy

# Expose port
EXPOSE 8000

# Default command (can be overridden by docker-compose)
CMD ["gunicorn", "babybuddy.wsgi:application", "--bind", "0.0.0.0:8000", "--timeout", "30", "--log-file", "-"]
