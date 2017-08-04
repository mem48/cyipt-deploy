# cyipt-deploy

Scripts for installing CyIPT.

Uses bash, but ideally would be moved to Ansible/Chef/Docker/Puppet/whatever in future.


## Requirements

Written for Ubuntu Server 16.04 LTS.


## Timezone

```shell
# Check your machine is in the right timezone
# user@machine:~$
cat /etc/timezone

# If not set it using:
sudo dpkg-reconfigure tzdata
```


## Setup

Add this repository to a machine using the following, as your normal username (not root). In the listing the grouped items can usually be cut and pasted together into the command shell, others require responding to a prompt:

```shell
# Install git
# user@machine:~$
sudo apt-get -y install git

# Tell git who you are
# git config --global user.name "Your git username"
# git config --global user.email "Your git email"
# git config --global push.default simple
# git config --global credential.helper 'cache --timeout=86400'

# Clone the repo
git clone https://github.com/cyipt/cyipt-deploy.git

# Move it to the right place
sudo mv cyipt-deploy /opt
cd /opt/cyipt-deploy/
git config core.sharedRepository group

# Create a generic user - without prompting for e.g. office 'phone number
sudo adduser --gecos "" cyipt

# Create the rollout group
sudo addgroup rollout

# Add your username to the rollout group
sudo adduser `whoami` rollout

# The adduser command above can't add your existing shell process to the
# new rollout group; you may want to replace it by doing:
exec newgrp rollout

# Login
# user@other-machine:~$
ssh user@machine

# Set ownership and group
# user@machine:~$
sudo chown -R cyipt.rollout /opt/cyipt-deploy

# Set group permissions and add sticky group bit
sudo chmod -R g+w /opt/cyipt-deploy
sudo find /opt/cyipt-deploy -type d -exec chmod g+s {} \;
```


