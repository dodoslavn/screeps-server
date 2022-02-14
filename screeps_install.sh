#!/bin/bash

echo ==================================
echo Running installation script
echo ==================================

echo INFO: Prepare package manager
apt-get clean ;
apt-get update ;

DEBIAN_FRONTEND=noninteractive
TZ=Europe/Bratislava
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime 
echo $TZ > /etc/timezone


echo INFO: Installing updates and basic tools
apt-get install -y apt-utils ;
apt-get install -y dialog ;
apt-get install -y libterm-ui-perl ;
apt-get upgrade -y ;
apt-get install -y vim curl gnupg gnupg2 gnupg1 gcc g++ make less wget apt-transport-https procps;

echo INFO: Installting Python2 NodeJS NPM
apt-get install -y nodejs
apt-get install -y python2
apt-get install -y npm

apt-get install -y zlib1g-dev libicu-dev libbrotli-dev libc-ares-dev libnghttp2-dev

mkdir /screeps
cd /screeps

echo INFO: Running Screeps installation
npm install screeps
npx screeps init

echo "cd /screeps" >> /start.sh
echo "npx screeps start >/screeps.log 2>&1 &" >> /start.sh
