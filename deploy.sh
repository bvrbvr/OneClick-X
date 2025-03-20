#!/bin/bash

CLIENT_EMAIL="shadowuser@shadowserver.com"
EMAIL_REGEX="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

if [ -x "$(command -v docker)" ]; then
    docker -v
else
    echo
    echo "Please install docker."
    exit 0
fi

echo

if [ "$1" ]; then
    if [[ $1 =~ $EMAIL_REGEX ]]; then
        docker kill OneClick-X 2>/dev/null
        docker rm OneClick-X 2>/dev/null
        docker image rm OneClick-X 2>/dev/null
        docker volume rm xray_vol 2>/dev/null
        CLIENT_EMAIL=$1
    else
        if [ "$1" == "remove" ]; then
            docker kill OneClick-X 2>/dev/null
            docker rm OneClick-X 2>/dev/null
            docker image rm OneClick-X 2>/dev/null
            docker volume rm xray_vol 2>/dev/null
            echo "OneClick-X removed."
            exit 0
        else
            if [ "$1" == "reload" ]; then
                docker kill OneClick-X 2>/dev/null
                docker rm OneClick-X 2>/dev/null
                docker image rm OneClick-X 2>/dev/null
                docker volume rm xray_vol 2>/dev/null
            else
                if [ "$1" == "restart" ]; then
                    docker kill OneClick-X 2>/dev/null
                    docker rm OneClick-X 2>/dev/null
                else
                    if [ "$1" == "uuid" ]; then
                        docker exec -it OneClick-X /opt/xray/xray uuid 2>/dev/null || echo "Please deploy Xray server first."
                        exit 0
                    else
                        echo "Wrong email or param was provided, performing regular deploy command instead."
                        echo "Available params: [reload, remove]"
                        echo
                    fi
                fi
            fi
        fi
    fi
fi

docker image ls | grep "OneClick-X" || docker build \
    -t OneClick-X . \
    --build-arg RELOAD_BUST=$(date +%s) \
    --build-arg CLIENT_EMAIL=$CLIENT_EMAIL
docker run \
    -v xray_vol:/opt/xray \
    -p 0.0.0.0:443:443/tcp \
    -p 0.0.0.0:23:23/tcp \
    -p 0.0.0.0:23:23/udp \
    -d --name OneClick-X \
    --restart always \
    OneClick-X 2>/dev/null || echo "Xray container already exists"

echo
echo "########################### Xray config ###########################"
echo
docker exec -it OneClick-X cat /opt/xray/xray-creds.txt
echo
echo "###################################################################"
echo
echo "####################### Xray connection url #######################"
echo
docker exec -it OneClick-X cat /opt/xray/vless-connection-string.txt | sed -r "s/127.0.0.1/"$(hostname -I | cut -d " " -f 1)"/"
echo
echo "###################################################################"
echo
