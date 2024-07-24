#!/bin/bash
# Install dependencies
sudo apt update
sudo apt install -y net-tools docker.io nginx logrotate

# Copy main script to /usr/local/bin
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Setup systemd service
sudo cp devopsfetch.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

# Create logrotate configuration
sudo tee /etc/logrotate.d/devopsfetch > /dev/null <<EOL
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
    sharedscripts
    postrotate
        systemctl reload devopsfetch.service > /dev/null 2>/dev/null || true
    endscript
    su root root
}
EOL

# Ensure the log file exists and has the correct permissions
sudo touch /var/log/devopsfetch.log
sudo chown root:root /var/log/devopsfetch.log
sudo chmod 644 /var/log/devopsfetch.log

echo "Setup completed. DevOpsFetch service is now running and logs are managed."
echo "You can now use it by running 'sudo ./devopsfetch' followed by the appropriate flags."
echo "The monitoring service has also been set up and started."
