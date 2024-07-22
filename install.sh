#!/bin/bash

# install.sh

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update package lists
apt update

# Install necessary dependencies
apt install -y jq lsof net-tools nginx docker.io

# Create directory for DevOpsFetch
mkdir -p /opt/devopsfetch

# Copy the main script
cat << 'EOF' > /opt/devopsfetch/devopsfetch.sh
#!/bin/bash

# devopsfetch.sh

# Function to display active ports
get_active_ports() {
    echo "Active Ports:"
    ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -n | uniq | while read port; do
        process=$(lsof -i :$port -sTCP:LISTEN -t)
        if [ ! -z "$process" ]; then
            echo "Port $port: $(ps -p $process -o comm=)"
        fi
    done
}

# Function to display port info
get_port_info() {
    port=$1
    process=$(lsof -i :$port -sTCP:LISTEN -t)
    if [ ! -z "$process" ]; then
        echo "Port $port is used by $(ps -p $process -o comm=) (PID: $process)"
    else
        echo "No process found listening on port $port"
    fi
}

# Function to display Docker info
get_docker_info() {
    echo "Docker Containers:"
    docker ps -a --format "table {{.Image}}\t{{.Names}}\t{{.Status}}"
}

# Function to display container info
get_container_info() {
    container=$1
    docker inspect $container | jq '.[0] | {Name: .Name, Image: .Config.Image, Status: .State.Status, Created: .Created, Ports: .NetworkSettings.Ports}'
}

# Function to display Nginx info
get_nginx_info() {
    echo "Nginx Domains and Ports:"
    nginx -T 2>/dev/null | grep -E "server_name|listen" | sed 'N;s/\n/ /' | sed 's/server_name //g; s/listen //g; s/;//g'
}

# Function to display Nginx domain info
get_nginx_domain_info() {
    domain=$1
    nginx -T 2>/dev/null | awk -v domain="$domain" '/server {/,/}/ {if ($0 ~ domain) {p=1}; if (p) print; if ($0 ~ /}/) p=0}'
}

# Function to display user logins
get_user_logins() {
    echo "User Logins:"
    last -n 20 | awk '!/wtmp/ {print $1, $4, $5, $6, $7}'
}

# Function to display user info
get_user_info() {
    user=$1
    id $user
    last -n 1 $user
}

# Function to display activities in time range
get_activities_in_time_range() {
    start_time=$1
    end_time=$2
    echo "Activities between $start_time and $end_time:"
    journalctl --since "$start_time" --until "$end_time"
}

# Main execution
case "$1" in
    -p|--port)
        if [ -z "$2" ]; then
            get_active_ports
        else
            get_port_info $2
        fi
        ;;
    -d|--docker)
        if [ "$2" = "all" ]; then
            get_docker_info
        else
            get_container_info $2
        fi
        ;;
    -n|--nginx)
        if [ "$2" = "all" ]; then
            get_nginx_info
        else
            get_nginx_domain_info $2
        fi
        ;;
    -u|--users)
        if [ "$2" = "all" ]; then
            get_user_logins
        else
            get_user_info $2
        fi
        ;;
    -t|--time)
        get_activities_in_time_range "$2" "$3"
        ;;
    -h|--help)
        echo "Usage: devopsfetch [OPTION]"
        echo "  -d, --docker [NAME]   get all Docker containers or info about a specific container"
        echo "  -h, --help            get this help message"
        echo "  -n, --nginx [DOMAIN]  get all Nginx domains or info about a specific domain"
        echo "  -p, --port [PORT]     get all active ports or info about a specific port"
        echo "  -t, --time START END  get activities within a time range"
        echo "  -u, --users [USER]    get all user logins or info about a specific user"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
EOF

# Make the script executable
chmod +x /opt/devopsfetch/devopsfetch.sh


# Create a symbolic link to the devopsfetch.sh script
if [ -L /usr/local/bin/devopsfetch ]; then
    echo "Symbolic link /usr/local/bin/devopsfetch already exists. Removing it."
    sudo rm /usr/local/bin/devopsfetch
fi

# Create a symlink to make the script accessible system-wide
ln -s /opt/devopsfetch/devopsfetch.sh /usr/local/bin/devopsfetch


# Create systemd service file
cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/opt/devopsfetch/devopsfetch.sh -t "$(date -d '1 hour ago' +'%Y-%m-%d %H:%M:%S')" "$(date +'%Y-%m-%d %H:%M:%S')"
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat <<EOT | sudo tee /etc/logrotate.d/devopsfetch
/var/log/syslog {
    rotate 7
    daily
    compress
    missingok
    notifempty
    delaycompress
    postrotate
    systemctl restart rsyslog
    endscript
}
EOT

echo "Setup completed. DevOpsFetch service is now running and logs are managed."
echo "You can now use it by running 'devopsfetch' followed by the appropriate flags."
echo "The monitoring service has also been set up and started."
