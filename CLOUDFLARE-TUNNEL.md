# Cloudflare Tunnel Setup for Baby Buddy

This guide explains how to set up Cloudflare Tunnel to securely expose your Baby Buddy instance to the internet without opening ports on your firewall.

## Prerequisites

- A Cloudflare account with a domain managed by Cloudflare
- `cloudflared` CLI installed (used to create/authenticate the tunnel)
- Docker Desktop (or Docker Engine with Docker Compose v2)

## Setup Steps

### 1. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will open a browser window to authenticate. After authentication, a credentials file will be saved to `~/.cloudflared/cert.pem`.

### 2. Create a Tunnel

```bash
cloudflared tunnel create babybuddy
```

This will:

- Create a tunnel named "babybuddy"
- Generate a tunnel UUID
- Create a credentials file at `~/.cloudflared/<TUNNEL_ID>.json`

**Important:** Note the tunnel UUID shown in the output - you'll need it for configuration.

### 3. Configure the Tunnel

Edit `cloudflare-tunnel.yml` in the Baby Buddy root directory:

```yaml
tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: /config/creds/YOUR_TUNNEL_ID_HERE.json

ingress:
  # Route requests to Baby Buddy application
  - hostname: babybuddy.yourdomain.com
    service: http://localhost:8000

  # Catch-all rule (required)
  - service: http_status:404
```

Replace:

- `YOUR_TUNNEL_ID_HERE` with your actual tunnel UUID
- `babybuddy.yourdomain.com` with your desired subdomain

### 4. Create DNS Record

Create a CNAME record pointing your subdomain to the tunnel:

```bash
cloudflared tunnel route dns babybuddy babybuddy.yourdomain.com
```

Replace `babybuddy.yourdomain.com` with your desired subdomain.

### 5. Run Baby Buddy with Docker Compose

```bash
docker compose up -d
```

Visit your domain (e.g., https://babybuddy.yourdomain.com) to verify it's working.

## Security Considerations

1. **Credentials**: The tunnel credentials file (`*.json`) contains sensitive data and is automatically excluded from git by `.gitignore`.

2. **HTTPS**: Cloudflare Tunnel automatically provides HTTPS encryption between visitors and Cloudflare.

3. **Access Control**: Consider using Cloudflare Access to add authentication before your Baby Buddy instance.

4. **Django Settings**: Update your Baby Buddy settings for production:
   - Set `ALLOWED_HOSTS` to include your domain
   - Set `CSRF_TRUSTED_ORIGINS` to include `https://babybuddy.yourdomain.com`
   - Disable `DEBUG` mode
   - Use a strong `SECRET_KEY`

Example environment variables:

```bash
export ALLOWED_HOSTS=babybuddy.yourdomain.com
export CSRF_TRUSTED_ORIGINS=https://babybuddy.yourdomain.com
export DEBUG=False
export SECRET_KEY=your-secret-key-here
```

## Troubleshooting

### Check Tunnel Status

```bash
cloudflared tunnel info babybuddy
```

### View Tunnel Logs

```bash
docker compose logs -f cloudflared
```

### List All Tunnels

```bash
cloudflared tunnel list
```

### Delete a Tunnel

```bash
# First clean up DNS records
cloudflared tunnel route dns --delete babybuddy babybuddy.yourdomain.com

# Then delete the tunnel
cloudflared tunnel delete babybuddy
```

## Advanced Configuration

### Multiple Services

You can route multiple subdomains through the same tunnel:

```yaml
tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID_HERE.json

ingress:
  - hostname: babybuddy.yourdomain.com
    service: http://localhost:8000

  - hostname: api.babybuddy.yourdomain.com
    service: http://localhost:8000/api

  - service: http_status:404
```

### Access Control with Cloudflare Access

To add authentication before Baby Buddy:

1. Go to Cloudflare Dashboard → Access → Applications
2. Create a new application
3. Select your domain (babybuddy.yourdomain.com)
4. Configure authentication providers (Google, GitHub, email OTP, etc.)
5. Set access policies

### Custom Origin Certificates

For additional security, you can use Cloudflare Origin Certificates:

1. Generate an origin certificate in Cloudflare Dashboard → SSL/TLS → Origin Server
2. Configure Baby Buddy to use HTTPS with the origin certificate
3. Update the tunnel config to use `https://localhost:8443` instead of `http://localhost:8000`

## Resources

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflared GitHub](https://github.com/cloudflare/cloudflared)
- [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/)
