#!/bin/bash

apt-get -y update
apt-get -y install debian-archive-keyring
apt-get -y install curl gnupg apt-transport-https
curl -L https://packagecloud.io/varnishcache/varnish60lts/gpgkey | apt-key add -
echo "deb https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" | \
tee /etc/apt/sources.list.d/varnishcache_varnish60lts.list
echo "deb-src https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" | \
tee -a /etc/apt/sources.list.d/varnishcache_varnish60lts.list
echo tatatataata
ls -al /etc/apt/sources.list.d/
echo tatatatataata
apt-get -y update
apt-get -y install varnish varnish-dev

tee /etc/varnish/default.vcl <<EOF
vcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
EOF

touch /etc/varnish/secret
