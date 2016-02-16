#!/usr/bin/env bash

echo "Preparing virtual hosts..."

VHOSTS="/vagrant/provision/nginx/*"

for VHOST_CONFIG_FILE in $VHOSTS
do
    echo "Processing ${VHOST_CONFIG_FILE}..."

    EXT=".conf"
    VHOST_PATH=${VHOST_CONFIG_FILE%${EXT}}
    VHOST_NAME=${VHOST_PATH##*/}

    echo '----------------------------------------------------------------------'
    echo "Configuring ${VHOST_NAME}..."
    echo "${VHOST_CONFIG}"
    echo '----------------------------------------------------------------------'

    sudo cp ${VHOST_CONFIG_FILE} /etc/nginx/sites-available/${VHOST_NAME}.conf
    sudo ln -sf /etc/nginx/sites-available/${VHOST_NAME}.conf /etc/nginx/sites-enabled/${VHOST_NAME}.conf
    sudo ln -sf /devel/php/${VHOST_NAME} /var/app/${VHOST_NAME}

    echo "Update /etc/hosts"
    sudo bash -c "echo '127.0.0.1 ${VHOST_NAME}' >> /etc/hosts"

done

sudo service nginx restart

sudo chown www-data:www-data /var/app -R
