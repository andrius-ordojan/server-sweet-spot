#!/bin/bash
# Function to check and modify sources.list files
check_and_modify_sources() {
  local file="$1"
  if [ -f "$file" ]; then
    if grep -q "^deb cdrom:" "$file" || grep -q "^deb \[arch=" "$file"; then
      print_color "yellow" "CD-ROM or DVD entries found in $file. Commenting them out..."
      sed -i '/^deb cdrom:/s/^/# /' "$file"
      sed -i '/^deb \[arch=/s/^/# /' "$file"
      print_color "green" "CD-ROM and DVD entries in $file have been commented out."
    else
      print_color "green" "No CD-ROM or DVD entries found in $file."
    fi
  fi
}
display_ascii_art() {
  local art="$1"
  echo "$art"
}
# Function to center text
center_text() {
  local text="$1"
  local width
  width=$(tput cols) || return
  local padding=$(((width - ${#text}) / 2))
  printf "%${padding}s%s\n" '' "$text"
}
# Function to print colored output
print_color() {
  case $1 in
  "green") echo -e "\e[32m$2\e[0m" ;;
  "red") echo -e "\e[31m$2\e[0m" ;;
  "yellow") echo -e "\e[33m$2\e[0m" ;;
  esac
  sleep 0.1
}
# Function to prompt user for yes/no input
prompt_yes_no() {
  while true; do
    read -r -p "$1 (y/n): " yn
    case $yn in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
}
# Function to show progress
show_progress() {
  local pid=$1
  local delay=0.1
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local start_time=$(date +%s)

  printf "  "
  while ps -p "$pid" >/dev/null 2>&1; do
    local temp=${spinstr#?}
    printf "\r[%c] " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60))
  done
  printf "\r[✓] Done!     \n"
}
#force scroll for after neoss install no idea why it hangs.
force_scroll() {
  local lines=${1:-10}
  for i in $(seq 1 $lines); do
    echo
    sleep 0.1
  done
}
# Complex ASCII art
complex_ascii_art=$(
  cat <<EOF
   ███████╗ ██████╗ ██╗   ██╗██████╗  █████╗ ███╗   ██╗    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗     ██████╗  █████╗  ██████╗██╗  ██╗
   ██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔══██╗████╗  ██║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
   ███████╗██║   ██║██║   ██║██████╔╝███████║██╔██╗ ██║    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝    ██████╔╝███████║██║     █████╔╝ 
   ╚════██║██║   ██║╚██╗ ██╔╝██╔══██╗██╔══██║██║╚██╗██║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗    ██╔═══╝ ██╔══██║██║     ██╔═██╗ 
   ███████║╚██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║ ╚████║    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║    ██║     ██║  ██║╚██████╗██║  ██╗
   ╚══════╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
)

# Simple ASCII art
simple_ascii_art=$(
  cat <<'EOF'
   ____                         ____                       ___           __  
  / __/__ _  _________ ____    / __/__ _____  _____ ____  / _ \___ _____/ /__
 _\ \/ _ \ |/ / __/ _ `/ _ \  _\ \/ -_) __/ |/ / -_) __/ / ___/ _ `/ __/  '_/
/___/\___/___/_/  \_,_/_//_/ /___/\__/_/  |___/\__/_/   /_/   \_,_/\__/_/\_\ 
                                                                             
EOF
)

#-------------
# Main Script
#-------------
# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
  print_color "red" "This script must be run as root"
  exit 1
fi
if [ "$1" = "simple" ] || [ "$USE_SIMPLE_ART" = "true" ]; then
  selected_art="$simple_ascii_art"
else
  # Check terminal width
  if [ "$(tput cols)" -ge 100 ]; then
    selected_art="$complex_ascii_art"
  else
    selected_art="$simple_ascii_art"
  fi
fi
clear
echo
display_ascii_art "$selected_art"
echo
center_text "Created by Enki"
center_text "Thanks for using this server setup script"
center_text "This script will walk you through some basic server setup and configuration."
echo
print_color "green" "Starting server setup..."
sleep 5

#--------------------
# Update and upgrade
#--------------------
print_color "yellow" "Checking and updating package sources..."
# Check main sources.list and all files in sources.list.d
check_and_modify_sources "/etc/apt/sources.list"
for file in /etc/apt/sources.list.d/*.list; do
  check_and_modify_sources "$file"
done

# Ensure that at least one valid source is present
if ! grep -qE '^deb ' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
  print_color "yellow" "No active package sources found. Adding a default source..."
  echo "deb http://deb.debian.org/debian $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list
fi

print_color "yellow" "Updating system..."
apt update >/tmp/apt_update.log 2>&1 &
update_pid=$!
show_progress $update_pid

wait $update_pid
update_status=$?

if [ $update_status -eq 0 ]; then
  print_color "green" "Update completed successfully."
else
  print_color "red" "Failed to update package lists. Here's the detailed error:"
  cat /tmp/apt_update.log
  exit 1
fi

print_color "yellow" "Upgrading system..."
DEBIAN_FRONTEND=noninteractive apt upgrade -y >/tmp/apt_upgrade.log 2>&1 &
upgrade_pid=$!
show_progress $upgrade_pid

wait $upgrade_pid
upgrade_status=$?

if [ $upgrade_status -eq 0 ]; then
  print_color "green" "Upgrade completed successfully."
else
  print_color "red" "Failed to upgrade packages. Here's the detailed error:"
  cat /tmp/apt_upgrade.log
  exit 1
fi

#---------------------
# Installs Basic Tools
#---------------------
essential_packages=("sudo" "net-tools" "wget" "curl" "git")
missing_packages=()
for package in "${essential_packages[@]}"; do
  if ! command -v "$package" &>/dev/null; then
    missing_packages+=("$package")
  fi
done
if [ ${#missing_packages[@]} -ne 0 ]; then
  print_color "yellow" "Installing missing basic packages: ${missing_packages[*]}"
  (apt install -y "${missing_packages[@]}" >/dev/null 2>&1) &
  show_progress $!
  print_color "green" "Basic packages installed."
else
  print_color "green" "All essential packages are already installed."
fi
# Ensure sudo is configured correctly
if ! grep -q "^%sudo" /etc/sudoers; then
  print_color "yellow" "Configuring sudo..."
  echo "%sudo ALL=(ALL:ALL) ALL" >>/etc/sudoers
  print_color "green" "Sudo configured."
fi

#----------------------
# Set up non-root user
#----------------------
if prompt_yes_no "Do you want to set up a new non-root user?"; then
  read -r -p "Enter new username: " new_user
  sudo adduser "$new_user"
  sudo usermod -aG sudo "$new_user"
  print_color "green" "User $new_user has been created and added to sudo group"
fi

#---------------
# SSH hardening
#---------------
ssh_hardened=false
new_ssh_port=""
if prompt_yes_no "Do you want to harden SSH?"; then
  print_color "yellow" "Configuring SSH..."

  # Backup original sshd_config
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  # Change SSH port
  while true; do
    read -r -p "Enter new SSH port (default: 2222): " ssh_port
    ssh_port=${ssh_port:-2222}
    if [[ "$ssh_port" =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1024 ] && [ "$ssh_port" -le 65535 ]; then
      break
    else
      print_color "red" "Invalid port number. Please enter a number between 1024 and 65535."
    fi
  done

  # Apply SSH hardening configurations
  sudo sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
  sudo sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

  # Allow only the new user (assuming $new_user is set earlier in the script)
  echo "AllowUsers $new_user" | sudo tee -a /etc/ssh/sshd_config >/dev/null

  print_color "yellow" "New SSH configuration:"
  print_color "yellow" "Port: $ssh_port"
  print_color "yellow" "Root login disabled"
  print_color "yellow" "Password authentication disabled"
  print_color "yellow" "Only user $new_user is allowed to login"

  # Test the new configuration
  if sudo sshd -t -f /etc/ssh/sshd_config; then
    print_color "green" "SSH configuration test passed."

    # Restart SSH service
    if sudo systemctl is-active --quiet ssh; then
      sudo systemctl restart ssh
      print_color "green" "SSH service restarted."
    else
      print_color "yellow" "SSH service not found. You may need to restart it manually."
    fi

    print_color "green" "SSH has been hardened. Check the end of the script for instructions on setting up an SSH key and logging in."
    ssh_hardened=true
    new_ssh_port=$ssh_port
  else
    print_color "red" "SSH configuration test failed. Reverting changes..."
    sudo mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    print_color "yellow" "Please check your SSH configuration manually"
  fi
else
  print_color "yellow" "Skipping SSH hardening."
fi
sleep 5

#-------------
# UFW setup
#-------------
if prompt_yes_no "Do you want to install and configure UFW?"; then
  print_color "yellow" "Installing and configuring UFW..."
  (apt install ufw -y >/dev/null 2>&1) &
  show_progress $!
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  ufw allow "$ssh_port"/tcp >/dev/null 2>&1
  ufw allow 80/tcp >/dev/null 2>&1
  ufw allow 443/tcp >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
  print_color "green" "UFW has been installed and configured"
fi

#---------------
# Fail2Ban setup
#---------------
if prompt_yes_no "Do you want to install and configure Fail2Ban?"; then
  print_color "yellow" "Installing and configuring Fail2Ban..."
  (apt install fail2ban -y >/dev/null 2>&1) &
  show_progress $!

  # Create a custom jail configuration
  cat <<EOF >/etc/fail2ban/jail.local
[DEFAULT]
bantime  = 10m
findtime  = 10m
maxretry = 5

# Avoid banning local network
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port    = $ssh_port
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl start fail2ban >/dev/null 2>&1
  print_color "green" "Fail2Ban has been installed and configured"
  print_color "yellow" "Default Fail2Ban settings:"
  print_color "yellow" "- Ban time: 10 minutes"
  print_color "yellow" "- Find time: 10 minutes"
  print_color "yellow" "- Max retries: 5"
  print_color "yellow" "- Ignored IP: localhost"
  print_color "yellow" "You can adjust these settings in /etc/fail2ban/jail.local"
fi

#---------------
# Install Nginx
#---------------
if prompt_yes_no "Do you want to install Nginx?"; then
  print_color "yellow" "Installing Nginx..."
  (apt install nginx -y >/dev/null 2>&1) &
  show_progress $!
  systemctl enable nginx >/dev/null 2>&1
  systemctl start nginx >/dev/null 2>&1
  print_color "green" "Nginx has been installed and started"
fi

#---------------
# Install Docker
#---------------
if prompt_yes_no "Do you want to install Docker?"; then
  print_color "yellow" "Installing Docker using the official method..."

  # Uninstall old versions
  print_color "yellow" "Removing old Docker versions if present..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    (sudo apt remove $pkg -y -qq >/dev/null 2>&1) &
    show_progress $!
  done

  # Update the apt package index
  print_color "yellow" "Updating apt package index..."
  (sudo apt update -qq >/dev/null 2>&1) &
  show_progress $!

  # Install packages to allow apt to use a repository over HTTPS
  print_color "yellow" "Installing required packages..."
  (sudo apt install ca-certificates curl -y -qq >/dev/null 2>&1) &
  show_progress $!

  # Add Docker's official GPG key
  print_color "yellow" "Adding Docker's official GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Set up the repository
  print_color "yellow" "Setting up the Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # Update the apt package index again
  print_color "yellow" "Updating apt package index..."
  (sudo apt update -qq >/dev/null 2>&1) &
  show_progress $!

  # Install Docker Engine, containerd, and Docker Compose
  print_color "yellow" "Installing Docker Engine, containerd, and Docker Compose..."
  (sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y -qq >/dev/null 2>&1) &
  show_progress $!

  # Verify Docker installation
  if docker --version >/dev/null 2>&1; then
    print_color "green" "Docker has been successfully installed."

    # Add user to the docker group
    print_color "yellow" "Adding $new_user to the docker group..."
    sudo usermod -aG docker "$new_user"

    # Verify group membership
    if id -nG "$new_user" | grep -qw "docker"; then
      print_color "green" "$new_user has been successfully added to the docker group."
    else
      print_color "red" "Failed to add $new_user to the docker group. Please add manually with: sudo usermod -aG docker $new_user"
    fi

    print_color "yellow" "Please log out and log back in for the group changes to take effect."
    print_color "yellow" "After logging back in, you can verify Docker works without sudo by running: docker run hello-world"
  else
    print_color "red" "Docker installation seems to have failed. Please check the logs and try again."
  fi
else
  print_color "yellow" "Skipping Docker installation"
fi

#-------------------------
# Install additional tools
#-------------------------
tools=("btop" "goaccess" "ncdu" "mc")
for tool in "${tools[@]}"; do
  if prompt_yes_no "Do you want to install $tool?"; then
    print_color "yellow" "Installing $tool..."
    (apt install "$tool" -y >/dev/null 2>&1) &
    show_progress $!
    print_color "green" "$tool has been installed"
  fi
done

#--------------------------------
# Install Node.js, npm, and Neoss
#--------------------------------
if prompt_yes_no "Do you want to install Neoss? This requires Node.js and npm to be installed as well."; then
  print_color "yellow" "Installing Node.js and npm..."

  # Download and run the NodeSource setup script
  print_color "yellow" "Adding NodeSource repository..."
  if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null 2>&1; then
    print_color "green" "NodeSource repository added successfully."
  else
    print_color "red" "Failed to add NodeSource repository. Aborting Node.js installation."
    return 1
  fi

  # Install Node.js (which includes npm)
  print_color "yellow" "Installing Node.js and npm..."
  if apt install -y nodejs >/dev/null 2>&1; then
    print_color "green" "Node.js and npm installed successfully."
  else
    print_color "red" "Failed to install Node.js and npm. Please check your internet connection and try again."
    return 1
  fi

  # Verify installation
  if node --version >/dev/null 2>&1 && npm --version >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_color "green" "Node.js ${NODE_VERSION} and npm ${NPM_VERSION} have been successfully installed"

    # Install Neoss
    print_color "yellow" "Installing Neoss..."
    npm install -g neoss >/tmp/neoss_install.log 2>&1 &
    install_pid=$!
    show_progress $install_pid

    wait $install_pid
    install_status=$?

    if [ $install_status -eq 0 ]; then
      NEOSS_VERSION=$(neoss --version 2>/dev/null || echo "version unknown")
      print_color "green" "Neoss installation successful."
      print_color "green" "Version: ${NEOSS_VERSION}"
    else
      print_color "red" "Neoss installation failed. Error log:"
      cat /tmp/neoss_install.log
      print_color "red" "You can try to install it manually later with 'npm install -g neoss'."
    fi
  else
    print_color "red" "Node.js and npm installation verification failed. Please check the installation manually."
    return 1
  fi

  sleep 0.5
  force_scroll 5
else
  print_color "yellow" "Skipping Node.js, npm, and Neoss installation"
fi

#------------------------
# Configure log rotation
#------------------------
if prompt_yes_no "Do you want to configure log rotation?"; then
  print_color "yellow" "Configuring log rotation..."

  # Default settings
  rotate_frequency="weekly"
  rotate_count=4
  rotate_size="100M"

  if prompt_yes_no "Do you want to customize global log rotation settings?"; then
    read -r -p "Enter rotation frequency (daily/weekly/monthly) [default: weekly]: " custom_frequency
    rotate_frequency=${custom_frequency:-$rotate_frequency}

    read -r -p "Enter number of log files to keep [default: 4]: " custom_count
    rotate_count=${custom_count:-$rotate_count}

    read -r -p "Enter max size of log file before rotation (e.g., 100M, 500M, 1G) [default: 100M]: " custom_size
    rotate_size=${custom_size:-$rotate_size}
  else
    print_color "yellow" "Using default settings for global log rotation."
  fi

  # Update global configuration
  cat <<EOF >/etc/logrotate.conf
# Global log rotation settings
${rotate_frequency}
rotate ${rotate_count}
create
compress
dateext

# Rotate log files larger than ${rotate_size} even before the scheduled rotation time
size ${rotate_size}

include /etc/logrotate.d

# System-specific logs may be configured here
EOF

  print_color "green" "Global log rotation has been configured with the following settings:"
  print_color "yellow" "- Rotation frequency: ${rotate_frequency}"
  print_color "yellow" "- Number of log files to keep: ${rotate_count}"
  print_color "yellow" "- Max size before rotation: ${rotate_size}"
  print_color "yellow" "You can further adjust these settings in /etc/logrotate.conf"

  # Nginx-specific configuration
  if command -v nginx &>/dev/null || [ -d "/etc/nginx" ]; then
    print_color "yellow" "Nginx installation detected."
    if prompt_yes_no "Do you want to configure Nginx-specific log rotation?"; then
      mkdir -p /etc/logrotate.d
      cat <<EOF >/etc/logrotate.d/nginx
/var/log/nginx/*.log {
    ${rotate_frequency}
    missingok
    rotate ${rotate_count}
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    maxsize ${rotate_size}
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \$(cat /var/run/nginx.pid)
        fi
    endscript
}
EOF
      print_color "green" "Nginx-specific log rotation has been configured."
      print_color "yellow" "Nginx log rotation configuration created at /etc/logrotate.d/nginx"
    else
      print_color "yellow" "Skipping Nginx-specific log rotation configuration."
    fi
  else
    print_color "yellow" "Nginx installation not detected. Skipping Nginx-specific log rotation configuration."
  fi

  # Docker-specific configuration
  if command -v docker &>/dev/null; then
    if prompt_yes_no "Docker is installed. Do you want to configure Docker-specific log rotation?"; then
      mkdir -p /etc/docker
      cat <<EOF >/etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "${rotate_size}",
    "max-file": "${rotate_count}"
  }
}
EOF
      print_color "green" "Docker-specific log rotation has been configured."
      print_color "yellow" "Note: You'll need to restart Docker for these changes to take effect."
      if prompt_yes_no "Do you want to restart Docker now?"; then
        systemctl restart docker
        print_color "green" "Docker has been restarted."
      else
        print_color "yellow" "Please remember to restart Docker later for the log rotation changes to take effect."
      fi
    else
      print_color "yellow" "Skipping Docker-specific log rotation configuration."
    fi
  fi

else
  print_color "yellow" "Skipping log rotation configuration."
fi

#---------------
# End of Script
#---------------
if [ "$ssh_hardened" = true ]; then
  print_color "yellow" "===== IMPORTANT: SSH KEY SETUP ====="
  print_color "yellow" "SSH has been hardened. If you haven't set up an SSH key, do so before logging out!"
  print_color "yellow" "Please test your SSH connection in a new terminal before closing this session."
  print_color "yellow" "Follow these steps on your local machine:"
  print_color "yellow" "1. Generate an SSH key:"
  print_color "yellow" "   ssh-keygen -t ed25519 -C 'your_email@example.com'"
  print_color "yellow" "2. Copy the key to your server:"
  print_color "yellow" "   ssh-copy-id -i ~/.ssh/id_ed25519.pub -p $ssh_port $new_user@your_server_ip"
  print_color "yellow" "3. Test your new key:"
  print_color "yellow" "   ssh -p $ssh_port $new_user@your_server_ip"
  print_color "yellow" "4. If successful, run this script again to disable password authentication."
  print_color "yellow" "If you can't connect, check your SSH configuration at /etc/ssh/sshd_config"
  print_color "yellow" "====================================="
fi

print_color "green" "Server setup complete!"
