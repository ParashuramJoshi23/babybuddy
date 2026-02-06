# Docker Setup for Baby Buddy

This guide explains how to run Baby Buddy using Docker and Docker Compose.

## Prerequisites

- Docker Desktop (or Docker Engine with Docker Compose v2)

## Quick Start

### 1. Start Docker Desktop

Make sure Docker Desktop is running before proceeding.

### 2. Build and Start Services

```bash
# Build images and start all services (database + web)
docker compose up -d --build
```

The application will be available at: **http://localhost:8000**

Default credentials:

- Username: `admin`
- Password: `admin`

## Docker Compose Commands

### Service Management

| Command                        | Description                   |
| ------------------------------ | ----------------------------- |
| `docker compose up -d`         | Start all services (db + web) |
| `docker compose stop`          | Stop all services             |
| `docker compose restart`       | Restart all services          |
| `docker compose down`          | Stop and remove containers    |
| `docker compose build`         | Build/rebuild Docker images   |
| `docker compose up -d --build` | Rebuild and restart services  |

### Database Management

| Command                                                                       | Description                                             |
| ----------------------------------------------------------------------------- | ------------------------------------------------------- | -------------- |
| `docker compose up -d db`                                                     | Start only the database                                 |
| `docker compose stop db`                                                      | Stop only the database                                  |
| `docker compose exec db psql -U $DB_USER -d $DB_NAME`                         | Open PostgreSQL shell                                   |
| `docker compose down -v`                                                      | Reset database (deletes all data!)                      |
| `docker compose exec -T db pg_dump -U $DB_USER $DB_NAME > backups/backup.sql` | Backup database                                         |
| `cat backups/backup.sql                                                       | docker compose exec -T db psql -U $DB_USER -d $DB_NAME` | Restore backup |

### Monitoring

| Command                   | Description                  |
| ------------------------- | ---------------------------- |
| `docker compose logs`     | Show logs from all services  |
| `docker compose logs -f`  | Follow logs (Ctrl+C to exit) |
| `docker compose logs web` | Show web service logs        |
| `docker compose logs db`  | Show database logs           |
| `docker compose ps`       | Show running containers      |

### Shell Access

| Command                                               | Description                      |
| ----------------------------------------------------- | -------------------------------- |
| `docker compose exec web sh`                          | Open shell in web container      |
| `docker compose exec --user root web sh`              | Open root shell in web container |
| `docker compose exec db psql -U $DB_USER -d $DB_NAME` | Open PostgreSQL shell            |

### Django Management

| Command                                                            | Description             |
| ------------------------------------------------------------------ | ----------------------- |
| `docker compose exec web python manage.py migrate`                 | Run database migrations |
| `docker compose exec web python manage.py makemigrations`          | Create new migrations   |
| `docker compose exec web python manage.py createsuperuser`         | Create admin user       |
| `docker compose exec web python manage.py collectstatic --noinput` | Collect static files    |
| `docker compose exec web python manage.py test`                    | Run tests in container  |

### Cleanup

| Command                  | Description                  |
| ------------------------ | ---------------------------- |
| `docker compose rm -f`   | Remove stopped containers    |
| `docker compose down -v` | Remove everything (WARNING!) |

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
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`: PostgreSQL connection settings
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
docker compose build

# 2. Start services
docker compose up -d

# 3. Create admin user (optional, default admin/admin exists)
docker compose exec web python manage.py createsuperuser
```

### Daily Development

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop when done
docker compose stop
```

### Database Backup

```bash
# Backup
mkdir -p backups
docker compose exec -T db pg_dump -U $DB_USER $DB_NAME > backups/backup_YYYYMMDD_HHMMSS.sql

# Restore
cat backups/backup_20250101_120000.sql | docker compose exec -T db psql -U $DB_USER -d $DB_NAME
```

### Troubleshooting

```bash
# Check service status
docker compose ps

# Check health
docker compose ps

# View logs
docker compose logs

# Restart services
docker compose restart

# Rebuild from scratch
docker compose down -v
docker compose up -d --build
```

### Running Migrations

```bash
# Auto-run on startup, or manually:
docker compose exec web python manage.py migrate

# Create new migrations (after model changes):
docker compose exec web python manage.py makemigrations
```

### Running Tests

```bash
# In Docker:
docker compose exec web python manage.py test
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
   docker compose exec -T db pg_dump -U $DB_USER $DB_NAME > backups/backup_YYYYMMDD_HHMMSS.sql
   ```

5. **Monitor logs**:

   ```bash
   docker compose logs -f
   ```

6. **Update regularly**:
   ```bash
   git pull
   docker compose up -d --build
   ```

## Cleaning Up

### Remove containers and images

```bash
# Remove stopped containers
docker compose rm -f

# Remove everything (including volumes!)
docker compose down -v
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
