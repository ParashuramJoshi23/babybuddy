# Cloudflare Tunnel Setup for Baby Buddy

This guide explains how to set up Cloudflare Tunnel to securely expose your Baby Buddy instance to the internet without opening ports on your firewall.

## Prerequisites

- A Cloudflare account with a domain managed by Cloudflare
- `cloudflared` CLI installed on your system
- Baby Buddy running locally (typically on port 8000)

## Installation

### macOS (Homebrew)

```bash
brew install cloudflare/cloudflare/cloudflared
```

### Linux

```bash
# Download and install the latest version
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### Windows

Download from: https://github.com/cloudflare/cloudflared/releases/latest

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
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID_HERE.json

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

### 5. Test the Tunnel

Start the tunnel in test mode:

```bash
cloudflared tunnel --config cloudflare-tunnel.yml run
```

If successful, you should see logs indicating the tunnel is connected.

### 6. Run Baby Buddy

In a separate terminal, start Baby Buddy:

```bash
# Using gulp (development)
gulp

# Or using Docker
docker-compose up
```

Visit your domain (e.g., https://babybuddy.yourdomain.com) to verify it's working.

## Running as a Service

### Using systemd (Linux)

Create a service file at `/etc/systemd/system/cloudflared-babybuddy.service`:

```ini
[Unit]
Description=Cloudflare Tunnel for Baby Buddy
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/babybuddy
ExecStart=/usr/local/bin/cloudflared tunnel --config /path/to/babybuddy/cloudflare-tunnel.yml run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-babybuddy
sudo systemctl start cloudflared-babybuddy
sudo systemctl status cloudflared-babybuddy
```

### Using Docker Compose

Add to `docker-compose.yml`:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel --config /etc/cloudflared/config.yml run
    volumes:
      - ./cloudflare-tunnel.yml:/etc/cloudflared/config.yml:ro
      - ~/.cloudflared:/etc/cloudflared:ro
    restart: unless-stopped
    depends_on:
      - app
```

### Using macOS LaunchAgent

Create `~/Library/LaunchAgents/com.cloudflare.tunnel.babybuddy.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudflare.tunnel.babybuddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/cloudflared</string>
        <string>tunnel</string>
        <string>--config</string>
        <string>/path/to/babybuddy/cloudflare-tunnel.yml</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/cloudflared-babybuddy.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/cloudflared-babybuddy.error.log</string>
</dict>
</plist>
```

Load the service:

```bash
launchctl load ~/Library/LaunchAgents/com.cloudflare.tunnel.babybuddy.plist
```

## Security Considerations

1. **Credentials**: The tunnel credentials file (`*.json`) contains sensitive data and is automatically excluded from git by `.gitignore`.

2. **HTTPS**: Cloudflare Tunnel automatically provides HTTPS encryption between visitors and Cloudflare

3. **Access Control**: Consider using Cloudflare Access to add authentication before your Baby Buddy instance

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
# If running as systemd service
sudo journalctl -u cloudflared-babybuddy -f

# If running manually
cloudflared tunnel --config cloudflare-tunnel.yml --loglevel debug run
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
