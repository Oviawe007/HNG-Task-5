#!/bin/bash

# Function to get port info
get_port_info() {
    port=$1
    process=$(lsof -i :$port -sTCP:LISTEN -t)
    if [ ! -z "$process" ]; then
        echo "Port $port is used by $(ps -p $process -o comm=) (PID: $process)"
    else
        echo "No process found listening on port $port"
    fi
}

# Function to get Docker info
get_docker_info() {
    echo "Docker Containers:"
    docker ps -a --format "table {{.Image}}\t{{.Names}}\t{{.Status}}"
}

# Function to get container info
get_container_info() {
    container=$1
    docker inspect $container | jq '.[0] | {Name: .Name, Image: .Config.Image, Status: .State.Status, Created: .Created, Ports: .NetworkSettings.Pports}' | jq -r 'to_entries | map("\(.key)\t\(.value)") | .[]'
}

# Function to get active ports
get_active_ports() {
    echo -e "Port\tProcess"
    ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -n | uniq | while read port; do
        process=$(lsof -i :$port -sTCP:LISTEN -t)
        if [ ! -z "$process" ]; then
            echo -e "$port\t$(ps -p $process -o comm=)"
        fi
    done | column -t
}

# Function to get Nginx info
get_nginx_info() {
    echo -e "Domain\tPort"
    nginx -T 2>/dev/null | grep -E "server_name|listen" | sed 'N;s/\n/ /' | sed 's/server_name //g; s/listen //g; s/;//g' | column -t
}

# Function to get Nginx domain info
get_nginx_domain_info() {
    domain=$1
    nginx -T 2>/dev/null | awk -v domain="$domain" '/server {/,/}/ {if ($0 ~ domain) {p=1}; if (p) print; if ($0 ~ /}/) p=0}'
}

# Function to get user logins
get_user_logins() {
    echo -e "User\tLogin Time"
    last -n 20 | awk '!/wtmp/ {print $1, $4, $5, $6, $7}' | column -t
}

# Function to get user info
get_user_info() {
    user=$1
    id $user
    last -n 1 $user
}

# Function to get activities in time range
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
        echo "  -d, --docker [NAME]   Get all Docker containers or info about a specific container"
        echo "  -h, --help            Get this help message"
        echo "  -n, --nginx [DOMAIN]  Get all Nginx domains or info about a specific domain"
        echo "  -p, --port [PORT]     Get all active ports or info about a specific port"
        echo "  -t, --time START END  Get activities within a time range"
        echo "  -u, --users [USER]    Get all user logins or info about a specific user"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
