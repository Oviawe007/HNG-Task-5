#!/bin/bash

# install.sh

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


LOG_FILE="/var/log/devopsfetch.log"

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
fi

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

display_help() {
    log "Displaying help information"
    echo "Usage: devopsfetch [option] [argument]"
    echo
    echo "   -p, --port [port_number]      Display active ports"
    echo "   -d, --docker [container_name] Display Docker information"
    echo "   -n, --nginx [domain]          Display Nginx information"
    echo "   -u, --users [username]        Display user information"
    echo "   -t, --time [start] [end]      Display activities within time range"
    echo "   -h, --help                    Display help"
    echo
}

get_ports() {
    local port=$1
    log "Fetching ports with argument: $port"
    
    if [ -z "$port" ]; then
        # Display all ports and services
        log "Displaying all ports and services:"
        if command -v netstat > /dev/null; then
            sudo netstat -tuln | sudo tee -a "$LOG_FILE"
        else
            log "netstat command not found, trying ss instead"
            sudo ss -tuln | sudo tee -a "$LOG_FILE"
        fi
    else
        # Display ports filtered by specific port number
        log "Displaying ports filtered by specific port number: $port"
        if command -v netstat > /dev/null; then
            port_info=$(sudo netstat -tuln | grep ":$port")
            if [ -z "$port_info" ]; then
                log "Port $port is not available."
                echo "Port $port is not available." | sudo tee -a "$LOG_FILE"
            else
                echo "$port_info" | awk 'NR==1{print "Proto Recv-Q Send-Q Local Address Foreign Address State"} {print}' | column -t | sudo tee -a "$LOG_FILE"
            fi
        else
            log "netstat command not found, trying ss instead"
            port_info=$(sudo ss -tuln | grep ":$port")
            if [ -z "$port_info" ]; then
                log "Port $port is not available."
                echo "Port $port is not available." | sudo tee -a "$LOG_FILE"
            else
                echo "$port_info" | awk 'NR==1{print "Proto Recv-Q Send-Q Local Address Foreign Address State"} {print}' | column -t | sudo tee -a "$LOG_FILE"
            fi
        fi
    fi
}


get_docker() {
    log "Fetching Docker information for: $1"
    if [ -z "$1" ]; then
        docker ps -a | sudo tee -a "$LOG_FILE"
    else
        docker inspect "$1" | sudo tee -a "$LOG_FILE"
    fi
}

get_nginx_info() {
    domain=$1

    if [[ -z $domain ]]; then
        # Display all Nginx domains and their ports in a tabular format
        {
            echo -e "Domain\tPort"
            nginx -T 2>/dev/null | grep -E "server_name|listen" | \
            sed 'N;s/\n/ /' | \
            sed 's/server_name //g; s/listen //g; s/;//g' | \
            column -t
        } | sudo tee -a "$LOG_FILE"
    else
 # Provide detailed configuration information for a specific domain
        {
            echo "Detailed configuration for domain: $domain"
            sudo grep -A 20 "server_name $domain" /etc/nginx/sites-available/* /etc/nginx/nginx.conf
        } | sudo tee -a "$LOG_FILE"
    fi
}

get_users() {
    log "Fetching user information for: $1"
    if [ -z "$1" ]; then
        lastlog | sudo tee -a "$LOG_FILE"
    else
        lastlog | grep "$1" | sudo tee -a "$LOG_FILE"
    fi
}

get_time_range() {
    log "Fetching logs from $1 to $2"
    journalctl --since="$1" --until="$2" | sudo tee -a "$LOG_FILE"
}

while true; do
    case "$1" in
        -p|--port)
            get_ports "$2"
            ;;
        -d|--docker)
            get_docker "$2"
            ;;
        -n|--nginx)
            get_nginx_info $2
            ;;
        -u|--users)
            get_users "$2"
            ;;
        -t|--time)
            get_time_range "$2" "$3"
            ;;
        -h|--help)
	      display_help
            exit 0
            ;;
        *)
            log "Invalid option provided: $1"
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
      
    esac

    # Sleep for a specified interval before running again (e.g., 60 seconds)
    sleep 60
done

