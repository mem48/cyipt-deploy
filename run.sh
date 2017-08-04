#!/bin/bash
# Installs the CyIPT system

### Stage 1 - general setup

echo "#	CyIPT: install system"

# Ensure this script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "#     This script must be run as root." 1>&2
    exit 1
fi

# Bomb out if something goes wrong
set -e

# Lock directory
lockdir=/var/lock/cyipt_outer
mkdir -p $lockdir

# Set a lock file; see: http://stackoverflow.com/questions/7057234/bash-flock-exit-if-cant-acquire-lock/7057385
(
	flock -n 900 || { echo '#	An installation is already running' ; exit 1; }


### CREDENTIALS ###

# Get the script directory see: http://stackoverflow.com/a/246128/180733
# The multi-line method of geting the script directory is needed to enable the script to be called from elsewhere.
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SCRIPTDIRECTORY=$DIR
ScriptHome=$(readlink -f "${SCRIPTDIRECTORY}/")

# Define the location of the credentials file relative to script directory
configFile=$ScriptHome/.config.sh

# Generate your own credentials file by copying from .config.sh.template
if [ ! -x $configFile ]; then
    echo "#	The config file, ${configFile}, does not exist or is not excutable - copy your own based on the ${configFile}.template file." 1>&2
    exit 1
fi

# Load the credentials
. $configFile

# Announce starting
echo "# CyIPT system installation $(date)"


## Main body

# Ensure a fully-patched system
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y autoremove

# Install basic utility software
apt-get -y install wget dnsutils man-db git nano bzip2 screen dos2unix mlocate
updatedb

# Install Apache (2.4)
apt-get -y install apache2

# Enable core Apache modules
a2enmod rewrite
a2enmod headers
a2enmod ssl
service apache2 restart

# Install PHP (7.1, using the Ondřej Surý -maintained packages)
apt-get install -y python-software-properties
add-apt-repository -y ppa:ondrej/php
apt-get update -y
apt-get -y install php7.1 php7.1-cli php7.1-mbstring
apt-get -y install libapache2-mod-php7.1

# Install PostgreSQL
apt-get -y install postgresql postgresql-contrib
apt-get -y install php7.1-pgsql

# Create site files directory
mkdir -p /var/www/cyipt/
chown -R cyipt.rollout /var/www/cyipt/
chmod g+ws /var/www/cyipt/

# Add VirtualHost
cp -pr $ScriptHome/apache.conf /etc/apache2/sites-available/cyipt.conf
a2ensite cyipt
service apache2 restart

# Clone or update repo
if [ ! -d /var/www/cyipt/.git/ ]; then
	sudo -u cyipt  git clone https://github.com/cyipt/cyipt.github.io.git /var/www/cyipt/
else
	sudo -u cyipt  git -C /var/www/cyipt/ pull
fi
chmod -R g+w /var/www/cyipt/

# Add cronjob to update from Git regularly
cp $ScriptHome/cyipt.cron /etc/cron.d/cyipt
chown root.root /etc/cron.d/cyipt
chmod 644 /etc/cron.d/cyipt


# Report completion
echo "#	Installing CyIPT system completed"

# Remove the lock file - ${0##*/} extracts the script's basename
) 900>$lockdir/${0##*/}

# End of file
