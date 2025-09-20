#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /home/ec2-user/cicd-dashboard
cd /home/ec2-user/cicd-dashboard

# Create production docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: "3.9"
services:
  api:
    image: cicd-dashboard-api:latest
    environment:
      DATABASE_URL: postgres://${database_username}:${database_password}@${database_endpoint}:5432/${database_name}
      PORT: 4000
      GITHUB_TOKEN: ${github_token}
      GITHUB_REPOS: ${github_repos}
      POLL_INTERVAL_SECONDS: ${poll_interval}
      SLACK_WEBHOOK_URL: ${slack_webhook_url}
      ALERT_EMAIL_TO: ${alert_email_to}
      SMTP_HOST: ${smtp_host}
      SMTP_PORT: ${smtp_port}
      SMTP_SECURE: ${smtp_secure}
      SMTP_USER: ${smtp_user}
      SMTP_PASS: ${smtp_pass}
      FRONTEND_ORIGIN: http://${alb_dns_name}
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: ${database_username}
      POSTGRES_PASSWORD: ${database_password}
      POSTGRES_DB: ${database_name}
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped

  web:
    image: cicd-dashboard-web:latest
    environment:
      VITE_API_URL: http://${alb_dns_name}
    depends_on:
      - api
    restart: unless-stopped

volumes:
  db-data:
EOF

# Create build script
cat > build.sh << 'EOF'
#!/bin/bash

# Build API image
cd /home/ec2-user/cicd-dashboard/backend
docker build -t cicd-dashboard-api:latest .

# Build Web image
cd /home/ec2-user/cicd-dashboard/frontend
docker build -t cicd-dashboard-web:latest .
EOF

chmod +x build.sh

# Create deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash

cd /home/ec2-user/cicd-dashboard

# Pull latest code (you would replace this with your actual deployment method)
# git pull origin main

# Build and deploy
docker-compose down
docker-compose build
docker-compose up -d

# Wait for services to be ready
sleep 30

# Health check
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "Application deployed successfully!"
else
    echo "Application deployment failed!"
    exit 1
fi
EOF

chmod +x deploy.sh

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/cicd-dashboard

# Create systemd service for auto-start
cat > /etc/systemd/system/cicd-dashboard.service << 'EOF'
[Unit]
Description=CI/CD Dashboard
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/cicd-dashboard
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cicd-dashboard.service

# Create log rotation
cat > /etc/logrotate.d/cicd-dashboard << 'EOF'
/home/ec2-user/cicd-dashboard/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
}
EOF

# Install monitoring tools
yum install -y htop iotop

echo "Setup completed successfully!"
