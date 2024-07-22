#!/bin/bash

# Install Python dependencies
pip3 install -r requirements.txt

# Copy the systemd service file
cp devopsfetch.service /etc/systemd/system/

# Reload systemd to recognize the new service
systemctl daemon-reload

# Enable and start the service
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat <<EOF >/etc/logrotate.d/devopsfetch
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
EOF

echo "Installation completed successfully."
