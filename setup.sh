#!/bin/bash

# Exit immediately if any command fails
set -e

echo "================================================="
echo " Starting Automated Flask Deployment from Repo"
echo "================================================="

# 1. System Update & Dependencies Installation
echo "--> Updating system packages and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip python3-venv git nginx -y

# 2. Virtual Environment & Package Installation
echo "--> Setting up Python virtual environment and installing Flask..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask gunicorn
deactivate

# 3. Permissions Configuration
echo "--> Configuring user groups and directory permissions..."
sudo usermod -aG ubuntu www-data
sudo chmod 755 /home/ubuntu
# Adjust permissions of the current repository directory we are standing in
chmod 750 $(pwd)

# 4. Create the ndp-app systemd Service File
echo "--> Creating systemd service file..."
sudo cat << 'EOF' | sudo tee /etc/systemd/system/ndp-app.service > /dev/null
[Unit]
Description=Gunicorn instance to serve Flask Application (ndp-app)
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/ndp2026
Environment="PATH=/home/ubuntu/ndp2026/venv/bin"
ExecStart=/home/ubuntu/ndp2026/venv/bin/gunicorn --workers 3 --bind unix:flaskapp.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOF

# 5. Start and Enable the ndp-app service
echo "--> Starting ndp-app backend service..."
sudo systemctl daemon-reload
sudo systemctl start ndp-app
sudo systemctl enable ndp-app

# 6. Create Nginx Configuration File
echo "--> Creating Nginx reverse proxy configuration..."
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-available/flaskapp > /dev/null
server {
    listen 80 default_server;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/ndp2026/flaskapp.sock;
    }
}
EOF

# 7. Activate Nginx Configuration
echo "--> Activating Nginx configuration and restarting web server..."
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

if [ ! -f "/etc/nginx/sites-enabled/flaskapp" ]; then
    sudo ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/
fi

sudo nginx -t
sudo systemctl restart nginx

echo "================================================="
echo " Deployment Successful!"
echo " Access your app at: http://YOUR_EC2_PUBLIC_IP"
echo "================================================="