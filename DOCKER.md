# Docker Setup for Baby Buddy

This guide explains how to run Baby Buddy using Docker and Docker Compose.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- Make (usually pre-installed on macOS/Linux)

## Quick Start

### 1. Start Docker Desktop

Make sure Docker Desktop is running before proceeding.

### 2. Build and Start Services

```bash
# View all available commands
make help

# Build Docker images (first time only)
make build

# Start all services (database + web)
make start
```

The application will be available at: **http://localhost:8000**

Default credentials:

- Username: `admin`
- Password: `admin`

## Makefile Commands

### Service Management

| Command        | Description                   |
| -------------- | ----------------------------- |
| `make start`   | Start all services (db + web) |
| `make stop`    | Stop all services             |
| `make restart` | Restart all services          |
| `make down`    | Stop and remove containers    |
| `make build`   | Build/rebuild Docker images   |
| `make rebuild` | Rebuild and restart services  |

### Database Management

| Command                           | Description                        |
| --------------------------------- | ---------------------------------- |
| `make dbstart`                    | Start only the database            |
| `make dbstop`                     | Stop only the database             |
| `make dbshell`                    | Open PostgreSQL shell              |
| `make dbreset`                    | Reset database (deletes all data!) |
| `make backup-db`                  | Backup database to file            |
| `make restore-db FILE=backup.sql` | Restore from backup                |

### Monitoring

| Command            | Description                  |
| ------------------ | ---------------------------- |
| `make logs`        | Show logs from all services  |
| `make logs-follow` | Follow logs (Ctrl+C to exit) |
| `make logs-web`    | Show web service logs        |
| `make logs-db`     | Show database logs           |
| `make ps`          | Show running containers      |
| `make status`      | Show service status          |
| `make health`      | Check service health         |

### Shell Access

| Command           | Description                      |
| ----------------- | -------------------------------- |
| `make shell`      | Open shell in web container      |
| `make shell-root` | Open root shell in web container |
| `make dbshell`    | Open PostgreSQL shell            |

### Django Management

| Command                | Description             |
| ---------------------- | ----------------------- |
| `make migrate`         | Run database migrations |
| `make makemigrations`  | Create new migrations   |
| `make createsuperuser` | Create admin user       |
| `make collectstatic`   | Collect static files    |
| `make test`            | Run tests in container  |

### Cleanup

| Command          | Description                  |
| ---------------- | ---------------------------- |
| `make clean`     | Remove stopped containers    |
| `make clean-all` | Remove everything (WARNING!) |

### Local Development (without Docker)

| Command           | Description                 |
| ----------------- | --------------------------- |
| `make dev-setup`  | Setup local dev environment |
| `make dev-start`  | Start local dev server      |
| `make test-local` | Run tests locally           |

## Architecture

The Docker setup includes:

### Services

1. **PostgreSQL Database** (`db`)

   - Image: `postgres:15-alpine`
   - Port: `5432`
   - Volume: `babybuddy-postgres-data`
   - Health checks enabled

2. **Web Application** (`web`)
   - Built from Dockerfile
   - Port: `8000`
   - Depends on database
   - Auto-runs migrations on startup
   - Health checks enabled

### Volumes

- `babybuddy-postgres-data`: Persists database data
- `babybuddy-media-data`: Persists uploaded media files
- `./data`: Local data directory mounted in container

## Multi-Stage Dockerfile

The Dockerfile uses a multi-stage build:

1. **Frontend Builder Stage**

   - Node.js 18
   - Builds CSS/JS assets using Gulp
   - Minimizes final image size

2. **Application Stage**
   - Python 3.12
   - Installs Python dependencies
   - Copies built assets from stage 1
   - Runs as non-root user for security

## Configuration

### Environment Variables

Create a `.env` file (see `.env.example`):

```bash
cp .env.example .env
```

Key variables:

- `SECRET_KEY`: Django secret key (generate a secure one!)
- `DEBUG`: Set to `False` in production
- `ALLOWED_HOSTS`: Comma-separated list of allowed hosts
- `DATABASE_URL`: PostgreSQL connection string
- `TIME_ZONE`: Your timezone (e.g., `America/New_York`)

### Ports

The application exposes:

- **8000**: Web application (HTTP)
- **5432**: PostgreSQL database

To change ports, edit `docker-compose.yml`:

```yaml
ports:
  - "8080:8000" # Access on port 8080 instead
```

## Common Workflows

### First Time Setup

```bash
# 1. Build images
make build

# 2. Start services
make start

# 3. Create admin user (optional, default admin/admin exists)
make createsuperuser
```

### Daily Development

```bash
# Start services
make start

# View logs
make logs-follow

# Stop when done
make stop
```

### Database Backup

```bash
# Backup
make backup-db
# Creates: backups/backup_YYYYMMDD_HHMMSS.sql

# Restore
make restore-db FILE=backups/backup_20250101_120000.sql
```

### Troubleshooting

```bash
# Check service status
make status

# Check health
make health

# View logs
make logs

# Restart services
make restart

# Rebuild from scratch
make clean
make build
make start
```

### Running Migrations

```bash
# Auto-run on startup, or manually:
make migrate

# Create new migrations (after model changes):
make makemigrations
```

### Running Tests

```bash
# In Docker:
make test

# Locally (faster):
make test-local
```

## Production Considerations

For production deployments:

1. **Generate a secure SECRET_KEY**:

   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(50))"
   ```

2. **Set environment variables**:

   - `DEBUG=False`
   - `SECRET_KEY=<your-secure-key>`
   - `ALLOWED_HOSTS=yourdomain.com`

3. **Use a reverse proxy** (nginx/traefik) for:

   - HTTPS/SSL termination
   - Static file serving
   - Load balancing

4. **Enable backups**:

   ```bash
   # Set up automated backups
   make backup-db
   ```

5. **Monitor logs**:

   ```bash
   make logs-follow
   ```

6. **Update regularly**:
   ```bash
   git pull
   make rebuild
   ```

## Cleaning Up

### Remove containers and images

```bash
# Remove stopped containers
make clean

# Remove everything (including volumes!)
make clean-all
```

### Remove specific volumes

```bash
docker volume rm babybuddy-postgres-data
docker volume rm babybuddy-media-data
```

## Support

- Documentation: https://docs.baby-buddy.net
- GitHub: https://github.com/babybuddy/babybuddy
- Issues: https://github.com/babybuddy/babybuddy/issues
