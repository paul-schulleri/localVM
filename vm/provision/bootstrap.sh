#!/usr/bin/env bash

echo "#### Start Provisioning ###"

VM_IP=$(ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//')

export DEBIAN_FRONTEND=noninteractive

sudo add-apt-repository ppa:ondrej/php5-5.6
echo 'deb http://www.rabbitmq.com/debian/ testing main' >> /etc/apt/sources.list
wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc && sudo apt-key add rabbitmq-signing-key-public.asc
# postgres
echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get clean
sudo apt-get -qq update

sudo mkdir -p /var/app

# install services
sudo apt-get install -y --force-yes vim curl build-essential python-software-properties git openssl curl nginx libpcre3-dev gcc make imagemagick memcached unzip 2> /dev/null

# Redis
sudo apt-get install -y --force-yes redis-server 2> /dev/null
sudo apt-get install -y --force-yes git 2> /dev/null

# python
sudo apt-get install -y --force-yes python-software-properties 2> /dev/null

# PHP
sudo apt-get install -y --force-yes php5 php5-xcache php5-xdebug php5-fpm php5-dev php5-curl php5-mcrypt php5-gd php5-imagick php5-memcached php5-redis php5-mysql 2> /dev/null
php5enmod curl

# Postgres
sudo apt-get install -y --force-yes postgresql-9.4 php5-pgsql pv 2> /dev/null
sudo -u postgres psql -c "CREATE USER dbmaster WITH PASSWORD 'dbmaster';"
echo "listen_addresses = '*'" >> /etc/postgresql/9.4/main/postgresql.conf
sudo service postgresql restart

# memcached
sudo bash -c "echo 'extension=memcached.so' | tee /etc/php5/mods-available/memcached.ini 2> /dev/null"
php5enmod memcached

# xdebug
echo "xdebug.remote_enable=On" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_host=$VM_IP" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_port=9000" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_handler=dbgp" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_connect_back=On" >> /etc/php5/mods-available/xdebug.ini
php5dismod opcache

# update pool conf to display errors
touch /var/log/fpm-php.www.log
chmod 777 /var/log/fpm-php.www.log
echo "php_flag[display_errors] = on" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_value[error_log] = /var/log/fpm-php.www.log" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_flag[log_errors] = on" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_value[memory_limit] = 32M" >> /etc/php5/fpm/pool.d/www.conf

# Composer for PHP
sudo curl -sS https://getcomposer.org/installer | sudo php
sudo mv composer.phar /usr/local/bin/composer

# rabbitmq
sudo apt-get install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

echo "clean up apt"
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# add restart helper
touch /usr/local/bin/rs
chmod +x /usr/local/bin/rs
# echo "#!/bin/bash" >> /usr/local/bin/rs
echo "service nginx restart" >> /usr/local/bin/rs
echo "service php5-fpm restart" >> /usr/local/bin/rs
echo "service memcached restart" >> /usr/local/bin/rs

echo "Checking php modules"

function checkModule {
	value=$(sudo php -m | grep -i -m 1 $1)
	if [ "$value" == "$1" ]; then
		echo "$value: ok"
	else
		echo "$value: failed"
	fi
}

#checkModule phalcon
checkModule memcached
checkModule xdebug
checkModule xcache

echo "restart services"
# bring it all to an end
service nginx restart
service php5-fpm restart

sudo echo "Setup finished."



echo "######################################################"
echo "                VM IP: ${VM_IP}"
echo "######################################################"


