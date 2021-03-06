#!/bin/bash
set -e

if [ ! "$HOME" == "$PWD" ]; then
  echo "This script is intended to be run from the user's home path: $HOME"
  exit 1
fi


# DEFAULTS
BRANCH="master"
ANSIBLE_ARGS="--module-path=~/.ansible/plugins/modules"

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -b|--branch)
    BRANCH="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# BOOTSTRAP

# Add apt repositories
if ! grep -q "ansible/ansible" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo apt-add-repository ppa:ansible/ansible
fi
if ! grep -q "git-core/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo apt-add-repository ppa:git-core/ppa
fi

# Upgrade packages
sudo apt-get update
sudo UCF_FORCE_CONFOLD=1 DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq -y upgrade

# Install Ansible & Git
sudo UCF_FORCE_CONFOLD=1 DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq -y install libssl1.1
sudo UCF_FORCE_CONFOLD=1 DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq -y install ansible
sudo apt-get --assume-yes install git

# Clone ansible luarocks module if not already present
if [ ! -d ".ansible/plugins/modules/ansible-module-luarocks" ]; then
  mkdir -p .ansible/plugins/modules
  git clone https://github.com/rahulg/ansible-module-luarocks.git .ansible/plugins/modules/ansible-module-luarocks
fi

# Clone toolbox repo if not already present
if [ ! -d "toolbox" ]; then
  #git clone git@github.com:bondesen/toolbox.git toolbox
  git clone https://github.com/bondesen/toolbox.git toolbox
fi

# Checkout specified branch and change to ssh
cd toolbox
git checkout ${BRANCH}
git remote set-url origin git@github.com:bondesen/toolbox.git

# Run Ansible playbook
ansible-playbook setup_bondesen_environment.yml -i hosts -vv ${ANSIBLE_ARGS}
