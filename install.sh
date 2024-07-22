#!/bin/bash

# Create virtual environment
python3 -m venv ~/devopsfetch_env

# Activate virtual environment and install dependencies
source ~/devopsfetch_env/bin/activate
pip install -r requirements.txt

# Deactivate virtual environment
deactivate

# Copy the systemd service file
sudo cp devopsfetch.service /etc/systemd/system/devopsfetch.service

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

# Set up log rotation
sudo bash -c 'cat <<EOF >/etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
    postrotate
        systemctl reload devopsfetch.service > /dev/null 2>/dev/null || true
    endscript
}
EOF'

echo "Installation completed successfully."
