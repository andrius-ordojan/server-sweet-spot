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
    echo $prompt
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

# echo "[ APT ]"
# echo "=> installing essential packages"
# echo
# run_command "sudo apt-get update"
# run_command "sudo apt-get upgrade -y"
# run_command "sudo apt-get install -y curl ufw fail2ban wget"
#
# echo
# echo "=> install optional packages yes or no? (leave empty for no):"
# read install_optional
# echo
# if [ "$install_optional" != "yes" ]; then
#   install_optional="no"
# fi
#
# if [ "$install_optional" = "yes" ]; then
#   echo "=> installing optional packages"
#   echo
#
#   run_command "sudo apt-get install -y git fish fzf zip bat ncdu net-tools btop ripgrep fd-find sd"
#
#   run_command "wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz"
#   run_command "sudo chown root:root eza"
#   run_command "sudo mv eza /usr/local/bin/eza"
# fi
# echo

# echo "[ user ]"
# echo "=> creating admin user"
# echo
#
# while true; do
#   echo "enter name of user:"
#   read input
#
#   if [ -n "$input" ]; then
#     echo
#     user=$input
#     break
#   else
#     echo "Input is not set. Please enter a value."
#   fi
# done
#
install_optional="yes"
# if [ "$install_optional" = "yes" ]; then
#   echo "=> using fish shell"
#   shell_path="/usr/bin/fish"
# else
#   echo "=> using bash"
#   shell_path="/bin/bash"
# fi
#
# run_command "sudo useradd -m -s ${shell_path} -G sudo ${user}"
# user_home="/home/${user}"
#
# echo "=> configuring vim"
# echo
#
# run_command "sudo -u ${user} wget https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/vim/vimrc -O ${user_home}/.vimrc"
#
# run_command "sudo -u ${user} mkdir -p ${user_home}/.vim/colors"
# run_command "sudo -u ${user} wget https://raw.githubusercontent.com/andrius-ordojan/server-sweet-spot/refs/heads/main/vim/PaperColor.vim -O ${user_home}/.vim/colors/PaperColor.vim"

user=a5
user_home=/home/a5
if [ "$install_optional" = "yes" ]; then
  echo "=> configuring fish"
  echo

  # run_command "sudo -u ${user} mkdir -p ${user_home}/.config/fish/conf.d"

  run_command "sudo -u ${user} bash <<EOF
cat > ${user_home}/.config/fish/conf.d/alias.fish << 'INNEREOF'
alias ls='ls -F'
alias lsa='ls -aF'
alias ll='ls -lh'
alias lt='ls --human-readable --size -1 -S --classify'
alias fd='fdfind'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias v='v .'
alias ports='sudo netstat -tulanp'
INNEREOF
EOF"
  # run_command "sudo su - ${user} -c \" bash -c \'cat << EOF > ${user_home}/.config/fish/conf.d/alias.fish
  #               alias ls='ls -F'
  #               alias lsa='ls -aF'
  #               alias ll='ls -lh'
  #               alias lt='ls --human-readable --size -1 -S --classify'
  #               alias ff=\"fzf --preview 'batcat --style=numbers --color=always {}'\"
  #               alias fd='fdfind'
  #
  #               alias ..='cd ..'
  #               alias ...='cd ../..'
  #               alias ....='cd ../../..'
  #
  #               alias v='v .'
  #
  #               alias ports='sudo netstat -tulanp'
  #             EOF\'\""

  run_command "sudo -u ${user} cat << EOF > ${uesr_home}/.config/fish/config.fish
                function v
                    if test -n \"\$argv\"
                        vim .
                    else
                        vim \$argv
                    end
                end
              EOF"
fi
