# server-sweet-spot

## Purpose

This script is designed to automate the initial setup and configuration of a server. It has been tested on Debian but should work on Ubuntu as well.

### How It Works

The script copies itself to the server using `scp`, then gets executed using `ssh`. This allows you to point the script at servers and configure them remotely.

### What It Does

The script is opinionated, but the configuration serves as a good starting point for further development, whether that includes installing Docker or a runtime of your choice.

The configuration steps are:
- `apt update`
- `apt upgrade`
- Install essential packages. Optional ones will be installed if accepted.
- Create a non-root user with sudo privileges.
- Configure unattended upgrades.
- Configure Fail2Ban.
- Configure SSH, disabling password authentication and only allowing the new user to log in using a public key.
- Configure the firewall (UFW) by denying all ingress except for the SSH port.

## Installation

To install the script and make it available for use:

1. Download the script from GitHub using `wget` or `curl` and place it in `~/.local/bin/` folder:

**using wget**
``` bash
wget https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/serversweetspot.sh -O ~/.local/bin/serversweetspot
```

**using curl**
``` bash
curl -L https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/serversweetspot.sh -o ~/.local/bin/serversweetspot
```
2. Make the script executable:
``` bash
chmod +x ~/.local/bin/serversweetspot
```
3. Double check that the `~/.local/bin/` folder is in the `PATH`.

4. Install `sshpass`. It is a required dependency, and the script will not run without it. It is used to automate password authentication over SSH when the script copies itself to the server.

On Debian-based systems, run:
``` bash
sudo apt install sshpass
```

On Mac, use Homebrew:
``` bash
brew install sshpass

```
## Usage

To use the script, execute it with the required parameters. The script can be run with the following syntax:

```bash
serversweetspot -s server_ip -p password [options]
```

### Required arguments:
- `-s server_ip`: IP address of the server to configure.
- `-p password`: Password for the SSH connection.

### Optional arguments:
- `-r root_user`: Specify the root user (default: `root`).
- `-k pub_key`: Provide the public key (default: contents of `~/.ssh/id_ed25519.pub`).
- `-S new_ssh_port`: Specify the SSH port (default: `2954`).

### Example:
```bash
serversweetspot -s 192.168.1.1 -p "your_password" 
```
