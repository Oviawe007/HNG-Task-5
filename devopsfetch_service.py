#!/home/ubuntu/devopsfetch_env/bin/python

import time
import logging
from devopsfetch import list_ports, list_docker, list_nginx, list_users

logging.basicConfig(filename='/var/log/devopsfetch.log', level=logging.INFO, format='%(asctime)s %(message)s')

def continuous_monitor():
    while True:
        logging.info("Active Ports: %s", list_ports())
        images, containers = list_docker()
        logging.info("Docker Images: %s", images)
        logging.info("Docker Containers: %s", containers)
        logging.info("Nginx Domains: %s", list_nginx())
        logging.info("Users: %s", list_users())
        time.sleep(3600)  # Log every hour

if __name__ == '__main__':
    continuous_monitor()
