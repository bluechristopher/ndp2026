#!/bin/bash
set -e

echo "================================================="
echo " Flask Deployment Script"
echo "================================================="

APP_DIR="$(pwd)"
APP_NAME="$(basename "$APP_DIR")"
USER_NAME="$(whoami)"
SERVICE_NAME="${APP_NAME}.service"
NGINX_SITE_NAME="$APP_NAME"
SOCKET_NAME="${APP_NAME}.sock"

# Detect Flask entry point
if [ -f app.py ]; then
    APP_MODULE="app:app"
    ENTRY_FILE="app.py"
elif [ -f main.py ]; then
    APP_MODULE="main:app"
    ENTRY_FILE="main.py"
else
    echo
    echo "ERROR: Could not find app.py or main.py."
    echo "Please run this script from the root folder of your Flask project."
    exit 1
fi

echo
echo "Project folder      : $APP_DIR"
echo "Project name        : $APP_NAME"
echo "Linux user          : $USER_NAME"
echo "Entry file          : $ENTRY_FILE"
echo "Gunicorn module     : $APP_MODULE"
echo "Service name        : $SERVICE_NAME"
echo "Socket              : $SOCKET_NAME"
echo

read -p "Continue with deployment? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo "================================================="
echo " Starting Flask Deployment"
echo "================================================="

# 1. System Update & Dependencies
echo "--> Updating system packages and installing dependencies..."
sudo apt update
sudo apt upgrade -y
sudo apt install python3-pip python3-venv git nginx -y

# 2. Virtual Environment
echo "--> Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip

if [ -f requirements.txt ]; then
    echo "--> Installing from requirements.txt..."
    pip install -r requirements.txt
else
    pip install Flask gunicorn
fi

deactivate

# 3. Permissions
echo "--> Configuring permissions..."
sudo chmod 755 "/home/$USER_NAME"
chmod 750 "$APP_DIR"

# 4. Systemd Service
echo "--> Creating systemd service file..."

sudo tee "/etc/systemd/system/$SERVICE_NAME" > /dev/null << EOF
[Unit]
Description=Gunicorn instance to serve $APP_NAME
After=network.target

[Service]
User=$USER_NAME
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind unix:$SOCKET_NAME -m 007 $APP_MODULE

[Install]
WantedBy=multi-user.target
EOF

# 5. Start Service
echo "--> Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl restart "$SERVICE_NAME"
sudo systemctl enable "$SERVICE_NAME"

# 6. Nginx Config
echo "--> Creating Nginx reverse proxy config..."

sudo tee "/etc/nginx/sites-available/$NGINX_SITE_NAME" > /dev/null << EOF
server {
    listen 80 default_server;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:$APP_DIR/$SOCKET_NAME;
    }
}
EOF

# 7. Enable Nginx Site
echo "--> Activating Nginx config..."

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf "/etc/nginx/sites-available/$NGINX_SITE_NAME" "/etc/nginx/sites-enabled/$NGINX_SITE_NAME"

sudo nginx -t
sudo systemctl restart nginx

echo "================================================="
echo " Deployment Successful!"
echo " App folder: $APP_DIR"
echo " Service: $SERVICE_NAME"
echo " Access your app at: http://YOUR_EC2_PUBLIC_IP"
echo "================================================="