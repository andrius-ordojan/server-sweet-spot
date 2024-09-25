#!/bin/bash

display_ascii_art() {
  local art="$1"
  echo "$art"
}

center_text() {
  local text="$1"
  local width
  width=$(tput cols) || return
  local padding=$(((width - ${#text}) / 2))
  printf "%${padding}s%s\n" '' "$text"
}

print_color() {
  case $1 in
  "green") echo -e "\e[32m$2\e[0m" ;;
  "red") echo -e "\e[31m$2\e[0m" ;;
  "yellow") echo -e "\e[33m$2\e[0m" ;;
  esac
  sleep 0.1
}

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

show_progress() {
  local pid=$1
  local delay=0.2
  local spinstr='-\\|/'
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

#-------------
# Main Script
#-------------
# TODO: make a cli for most of these
username="root2"
server_ip="20.79.165.75"
# TODO: change to /tmp
path_on_server="/home/root2"
password="46AaCfGgKkMNnqsTtVvXxYy"
host_pub_key=$(cat ~/.ssh/id_ed25519.pub)

if [[ ! "$ON_SERVER" ]]; then
  sshpass -p "$password" scp "$0" "$username@$server_ip:$path_on_server"
  sshpass -p "$password" ssh -t "$username@$server_ip" "sudo ON_SERVER=1 HOST_PUB_KEY='$host_pub_key' bash $path_on_server/$(basename $0)"
  exit 0
fi

ascii_art=$(
  cat <<'EOF'
 __                            __                   _     __             _   
/ _\ ___ _ ____   _____ _ __  / _\_      _____  ___| |_  / _\_ __   ___ | |_ 
\ \ / _ \ '__\ \ / / _ \ '__| \ \\ \ /\ / / _ \/ _ \ __| \ \| '_ \ / _ \| __|
_\ \  __/ |   \ V /  __/ |    _\ \\ V  V /  __/  __/ |_  _\ \ |_) | (_) | |_ 
\__/\___|_|    \_/ \___|_|    \__/ \_/\_/ \___|\___|\__| \__/ .__/ \___/ \__|
                                                            |_|              
EOF
)

clear
echo
# TODO: center this at some point
display_ascii_art "$ascii_art"
echo
center_text "Inspired by Enki, created by Andrius"
center_text "https://github.com/andrius-ordojan/server-sweet-spot"
center_text "This script will walk you through some basic server setup and configuration."
echo
print_color "green" "Starting server setup on $(hostname) $(hostname -I)..."
# TODO: change 5 later
sleep 1

if [[ $EUID -ne 0 ]]; then
  print_color "red" "This script must be run as root"
  exit 1
fi

#--------------------
# Update and upgrade
#--------------------
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
# Installs Packages
#---------------------
essential_packages=("ufw" "fail2ban" "net-tools" "wget" "curl")

print_color "yellow" "Installing essential packages: ${essential_packages[*]}"
(apt install -y "${essential_packages[@]}" >/dev/null 2>&1) &
show_progress $!
print_color "green" "Essential packages installed."

if prompt_yes_no "Do you want to install optional packages? [git, fish, fzf, zip, bat, ncdu, btop, ripgrep, fd-find, sd, eza, tldr]"; then
  install_optional=1
  optional_packages=("git" "fish" "fzf" "zip" "bat" "ncdu" "btop" "ripgrep" "fd-find" "sd" "tld")

  (apt install -y "${optional_packages[@]}" >/dev/null 2>&1) &
  show_progress $!

  if [ ! -L "/usr/local/bin/bat" ]; then
    ln -s /usr/bin/batcat /usr/local/bin/bat
  fi
  if [ ! -L "/usr/local/bin/fd" ]; then
    ln -s /usr/bin/fdfind /usr/local/bin/fd
  fi
  print_color "green" "Optional packages installed."

  if [ ! -f "/usr/local/bin/eza" ]; then
    wget -cq https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
    chown root:root eza
    mv eza /usr/local/bin/eza
  fi
fi

#----------------------
# Set up non-root user
#----------------------
read -r -p "Enter username of the new non-root user: " new_user

if command -v fish 2 >&1 >/dev/null; then
  if prompt_yes_no "Fish shell is installed. Do you want to set it as default for the user ${new_user}"; then
    using_fish=1
    shell_path="/usr/bin/fish"
    print_color "green" "Setting fish as default shell"
  fi
else
  shell_path="/bin/bash"
fi

sudo useradd -m -s ${shell_path} -G sudo ${new_user}
print_color "green" "User $new_user has been created and added to sudo group"

if [ $using_fish ]; then
  sudo -u ${new_user} mkdir -p /home/${new_user}/.config/fish/conf.d

  sudo -u ${new_user} bash -c "cat >/home/${new_user}/.config/fish/conf.d/alias.fish <<EOL
alias ls='eza -lh --group-directories-first --icons'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff=\"fzf --preview 'batcat --style=numbers --color=always {}'\"
alias fd='fdfind'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ports='sudo netstat -tulanp'
EOL"

  sudo -u ${new_user} bash -c "cat >/home/${new_user}/.config/fish/config.fish <<EOL
function v
    if test -n "$argv"
        vim .
    else
        vim $argv
    end
end
EOL"

  print_color "green" "Configured fish"
fi

if prompt_yes_no "Add public key to authorized_keys for ${new_user}?"; then
  read -r -p "Provide public key to add (by default it will try to use ~/.ssh/id_ed25519.pub):" input

  if [ -z "$input" ]; then
    key=$host_pub_key
  else
    key=$input
  fi

  sudo -u ${new_user} mkdir -p /home/${new_user}/.ssh
  sudo -u ${new_user} bash -c "echo $HOST_PUB_KEY > /home/${new_user}/.ssh/authorized_keys"
  sudo -u ${new_user} bash -c "chmod 600 /home/${new_user}/.ssh/authorized_keys"
fi

sudo -u ${new_user} wget -q https://raw.githubusercontent.com/amix/vimrc/refs/heads/master/vimrcs/basic.vim -O /home/${new_user}/.vimrc
print_color "green" "Configured vim"

#---------------
# Configure unattended upgrades
#---------------
print_color "yellow" "Configuring unattended-upgrades..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<-EOF
APT::Periodic::Update-Package-Lists "1"
APT::Periodic::Unattended-Upgrade "1"
APT::Periodic::AutocleanInterval "7"
EOF

sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-local >/dev/null <<-EOF
"Unattended-Upgrade::Origins-Pattern {"
  "origin=Debian,codename=\${distro_codename},label=Debian";
  "origin=Debian,codename=\${distro_codename},label=Debian-Security";
  "origin=Debian,codename=\${distro_codename}-security,label=Debian-Security";
  "origin=Debian,codename=\${distro_codename},label=Debian-Updates";
};

Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

print_color "green" "Done"

#---------------
# Configure SSH
#---------------
print_color "yellow" "Configuring SSH..."

mkdir -p /etc/ssh/sshd_config.d/_archive
mv /etc/ssh/sshd_config.d/* /etc/ssh/sshd_config.d/_archive >/dev/null 2>&1
print_color "green" "Archived existing ssh configuration located in /etc/ssh/ssh_config.d/ to /etc/ssh/ssh_config.d/_archive"

custom_conf="/etc/ssh/sshd_config.d/50-custom.conf"
sudo tee -a ${custom_conf} >/dev/null <<-EOF
Port 2954
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

Protocol 2
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

echo "AllowUsers $new_user" | sudo tee -a ${custom_conf} >/dev/null
sudo chmod 600 ${custom_conf}

print_color "yellow" "New SSH configuration:"
print_color "yellow" "Port: 2954"
print_color "yellow" "Root login disabled"
print_color "yellow" "Password authentication disabled"
print_color "yellow" "Only user $new_user is allowed to login"

sudo systemctl restart ssh
