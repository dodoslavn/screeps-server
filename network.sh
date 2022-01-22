#!/bin/bash

if [ -z "$NET_NAME" ]
	then
	echo ERROR - Docker network name was not specified! 
	exit 1
	fi

docker network create $NET_NAME

