import argparse
import psutil
import docker
import subprocess
import pwd
from tabulate import tabulate
from datetime import datetime, timedelta

def list_ports():
    connections = psutil.net_connections()
    data = [{"Port": conn.laddr.port, "Service": psutil.Process(conn.pid).name()} for conn in connections if conn.status == 'LISTEN']
    return data

def port_details(port):
    connections = psutil.net_connections()
    for conn in connections:
        if conn.laddr.port == port and conn.status == 'LISTEN':
            process = psutil.Process(conn.pid)
            data = {
                "Port": conn.laddr.port,
                "Service": process.name(),
                "PID": process.pid,
                "User": process.username(),
                "Executable": process.exe()
            }
            return data
    return None

def list_docker():
    client = docker.from_env()
    images = [{"Image": img.tags} for img in client.images.list()]
    containers = [{"Container": c.name, "Status": c.status} for c in client.containers.list(all=True)]
    return images, containers

def docker_details(container_name):
    client = docker.from_env()
    container = client.containers.get(container_name)
    data = {
        "Name": container.name,
        "Status": container.status,
        "Image": container.image.tags,
        "Command": container.attrs['Config']['Cmd'],
        "Ports": container.attrs['NetworkSettings']['Ports']
    }
    return data

def list_nginx():
    try:
        result = subprocess.run(['nginx', '-T'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        output = result.stdout
        # Parse the nginx configuration from output
        # Placeholder code: Need actual parser for proper implementation
        domains = []
        return domains
    except Exception as e:
        return str(e)

def nginx_details(domain):
    # Placeholder code: Implement the parser for Nginx configuration details
    details = {}
    return details

def list_users():
    users = [pwd.getpwnam(user).pw_name for user in pwd.getpwall()]
    data = []
    for user in users:
        last_login = subprocess.run(['lastlog', '-u', user], stdout=subprocess.PIPE, text=True)
        data.append({"User": user, "Last Login": last_login.stdout.splitlines()[-1]})
    return data

def user_details(username):
    try:
        user_info = pwd.getpwnam(username)
        data = {
            "Username": user_info.pw_name,
            "User ID": user_info.pw_uid,
            "Group ID": user_info.pw_gid,
            "Home Directory": user_info.pw_dir,
            "Shell": user_info.pw_shell,
            "Last Login": subprocess.run(['lastlog', '-u', username], stdout=subprocess.PIPE, text=True).stdout.splitlines()[-1]
        }
        return data
    except KeyError:
        return None

def activities_within_time_range(start_time, end_time):
    logs = []
    # Implement log parsing logic
    return logs

def main():
    parser = argparse.ArgumentParser(description='DevOps Fetch Tool')
    parser.add_argument('-p', '--port', nargs='?', const=True, help='Display active ports and services')
    parser.add_argument('-d', '--docker', nargs='?', const=True, help='Display Docker images and containers')
    parser.add_argument('-n', '--nginx', nargs='?', const=True, help='Display Nginx domains and ports')
    parser.add_argument('-u', '--users', nargs='?', const=True, help='Display user logins')
    parser.add_argument('-t', '--time', help='Display activities within a specified time range')
    args = parser.parse_args()

    if args.port:
        if args.port is True:
            print(tabulate(list_ports(), headers="keys"))
        else:
            print(port_details(int(args.port)))

    if args.docker:
        if args.docker is True:
            images, containers = list_docker()
            print("Docker Images:")
            print(tabulate(images, headers="keys"))
            print("\nDocker Containers:")
            print(tabulate(containers, headers="keys"))
        else:
            print(docker_details(args.docker))

    if args.nginx:
        if args.nginx is True:
            print(tabulate(list_nginx(), headers="keys"))
        else:
            print(nginx_details(args.nginx))

    if args.users:
        if args.users is True:
            print(tabulate(list_users(), headers="keys"))
        else:
            print(user_details(args.users))

    if args.time:
        start_time, end_time = args.time.split(',')
        start_time = datetime.strptime(start_time, '%Y-%m-%d %H:%M:%S')
        end_time = datetime.strptime(end_time, '%Y-%m-%d %H:%M:%S')
        print(tabulate(activities_within_time_range(start_time, end_time), headers="keys"))

if __name__ == '__main__':
    main()
