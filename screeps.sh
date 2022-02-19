#set -x

docker image pull $DOCKER_IMAGE 

if [ -z "$SCREEPS_NAME" ]
	then
	echo ERROR: Screeps container name not defined!
	exit 2
	fi

if ! [ -z "$CLEAN_RUN" ]
	then
	echo INFO: Removing old container $SCREEPS_NAME
	docker rm -f $SCREEPS_NAME 2>/dev/null
	fi

echo
echo INFO: Building new container
docker run -p 21025:21025/tcp --network=bridge --name $SCREEPS_NAME --hostname=$SCREEPS_NAME -d -t $DOCKER_IMAGE bash

echo
echo INFO: Copying installation script
docker cp $SCREEPS_INSTALL_SCRIPT $SCREEPS_NAME:/ 

echo
echo INFO: Running installation script
docker exec -it $SCREEPS_NAME chmod 700 /$SCREEPS_INSTALL_SCRIPT
docker exec -it $SCREEPS_NAME /$SCREEPS_INSTALL_SCRIPT
