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
#   sudo apt install -y sshpass >/dev/null
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

run_command 'ls -al ~/'
# echo "enter name of the admin account to create:"
# read user
