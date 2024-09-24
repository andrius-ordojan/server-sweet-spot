set -e

# echo "enter server host:"
# read host
# host=20.79.165.75
#
# echo "Enter server port (default is 22 if left empty):"
# read port
# if [ -z "$port" ]; then
#   port=22
# fi
#
# echo "Enter name of root user (default is root if left empty):"
# read root
# if [ -z "$port" ]; then
#   root=root
# fi

# echo "Use password authentication yes or no? (leave empty for no):"
# read use_password
# if [ "$use_password" = "yes" ]; then
#   echo "installing sshpass for automatic authentication with a password"
#   sudo apt install -y sshpass
# else
#   use_password="no"
# fi

use_password="yes"
host=20.79.165.75
port=22
root="root2"
password=46AaCfGgKkMNnqsTtVvXxYy

run_command() {
  local cmd=$1

  if [ "$use_password" = "yes" ]; then
    sshpass -p $password ssh -p $port $root@$host $cmd
  else
    ssh -p $port $root@$host $cmd
  fi
}

get_required_input() {
  local prompt=$1
  local input

  while true; do
    echo "$prompt"
    read input

    if [ -n "$input" ]; then
      break
    else
      echo "Input is not set. Please enter a value."
    fi
  done

  echo "$input"
}

get_choose_input() {
  local prompt=$1
  local choices=$2
  local input

  while true; do
    echo "$prompt"
    read input

    if [ -n "$input" ]; then
      break
    else
      echo "Input is not set. Please enter a value."
    fi
  done

  echo "$input"
}

echo "install optional packages yes or no? (leave empty for no):"
read install_optional
if [ "$install_optional" != "yes" ]; then
  install_optional="no"
fi

echo "[ APT ]"
echo "=> installing essential packages"
run_command "sudo apt-get update"
run_command "sudo apt-get upgrade -y"
run_command "sudo apt-get install -y curl ufw fail2ban wget"

if [ "$install_optional" = "yes" ]; then
  echo "=> installing optional packages"
  run_command "sudo apt-get install -y git fish fzf zip bat ncdu net-tools btop ripgrep fd-find rust-eza sd"
fi
echo

echo "[ user ]"
echo "creating admin user"
echo

user=$(get_required_input "Enter the name:")

if [ "$install_optional" = "yes" ]; then
  echo "using fish shell"
  shell_path="/usr/bin/fish"
else
  echo "using bash"
  shell_path="/bin/bash"
fi

run_command "sudo useradd -m -s ${shell_path} -G sudo ${user}"

user_home="/home/${user}/"

echo "configuring vim"
run_command "sudo -u ${user} wget https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/vim/vimrc > ~/.vimrc"
# TODO: check if i need to chmod
# run_command "sudo chmod 644 ${user_home}/.vimrc"

run_command "sudo -u ${user} mkdir -p ~/.vim/colors"
# TODO: check if i need to chmod
run_command "sudo -u ${user} wget https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/vim/PaperColor.vim > ~/.vim/colors/"
# TODO: check if i need to chmod

if [ "$install_optional" = "yes" ]; then
  echo "configuring fish"
  run_command "sudo -u ${user} mkdir -p ~/.config/fish/conf.d"
  run_command "sudo -u ${user} cat << EOF > ~/.config/fish/conf.d/alias.fish
                alias ls='ls -F'
                alias lsa='ls -aF'
                alias ll='ls -lh'
                alias lt='ls --human-readable --size -1 -S --classify'
                alias ff=\"fzf --preview 'batcat --style=numbers --color=always {}'\"
                alias fd='fdfind'

                alias ..='cd ..'
                alias ...='cd ../..'
                alias ....='cd ../../..'

                alias v='v .'

                alias ports='sudo netstat -tulanp'
              EOF"

  run_command "sudo -u ${user} cat << EOF > ~/.config/fish/config.fish
                function v
                    if test -n \"\$argv\"
                        vim .
                    else
                        vim \$argv
                    end
                end
              EOF"
fi
