#!/bin/bash

# devopsfetch.sh

# Function to display active ports
show_active_ports() {
    echo "Active Ports:"
    ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -n | uniq | while read port; do
        process=$(lsof -i :$port -sTCP:LISTEN -t)
        if [ ! -z "$process" ]; then
            echo "Port $port: $(ps -p $process -o comm=)"
        fi
    done
}

# Function to display port info
show_port_info() {
    port=$1
    process=$(lsof -i :$port -sTCP:LISTEN -t)
    if [ ! -z "$process" ]; then
        echo "Port $port is used by $(ps -p $process -o comm=) (PID: $process)"
    else
        echo "No process found listening on port $port"
    fi
}

# Function to display Docker info
show_docker_info() {
    echo "Docker Containers:"
    docker ps -a --format "table {{.Image}}\t{{.Names}}\t{{.Status}}"
}

# Function to display container info
show_container_info() {
    container=$1
    docker inspect $container | jq '.[0] | {Name: .Name, Image: .Config.Image, Status: .State.Status, Created: .Created, Ports: .NetworkSettings.Ports}'
}

# Function to display Nginx info
show_nginx_info() {
    echo "Nginx Domains and Ports:"
    nginx -T 2>/dev/null | grep -E "server_name|listen" | sed 'N;s/\n/ /' | sed 's/server_name //g; s/listen //g; s/;//g'
}

# Function to display Nginx domain info
show_nginx_domain_info() {
    domain=$1
    nginx -T 2>/dev/null | awk -v domain="$domain" '/server {/,/}/ {if ($0 ~ domain) {p=1}; if (p) print; if ($0 ~ /}/) p=0}'
}

# Function to display user logins
show_user_logins() {
    echo "User Logins:"
    last -n 20 | awk '!/wtmp/ {print $1, $4, $5, $6, $7}'
}

# Function to display user info
show_user_info() {
    user=$1
    id $user
    last -n 1 $user
}

# Function to display activities in time range
show_activities_in_time_range() {
    start_time=$1
    end_time=$2
    echo "Activities between $start_time and $end_time:"
    journalctl --since "$start_time" --until "$end_time"
}

# Main execution
case "$1" in
    -p|--port)
        if [ -z "$2" ]; then
            show_active_ports
        else
            show_port_info $2
        fi
        ;;
    -d|--docker)
        if [ "$2" = "all" ]; then
            show_docker_info
        else
            show_container_info $2
        fi
        ;;
    -n|--nginx)
        if [ "$2" = "all" ]; then
            show_nginx_info
        else
            show_nginx_domain_info $2
        fi
        ;;
    -u|--users)
        if [ "$2" = "all" ]; then
            show_user_logins
        else
            show_user_info $2
        fi
        ;;
    -t|--time)
        show_activities_in_time_range "$2" "$3"
        ;;
    -h|--help)
        echo "Usage: devopsfetch [OPTION]"
        echo "  -p, --port [PORT]     Show all active ports or info about a specific port"
        echo "  -d, --docker [NAME]   Show all Docker containers or info about a specific container"
        echo "  -n, --nginx [DOMAIN]  Show all Nginx domains or info about a specific domain"
        echo "  -u, --users [USER]    Show all user logins or info about a specific user"
        echo "  -t, --time START END  Show activities within a time range"
        echo "  -h, --help            Show this help message"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
