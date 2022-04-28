#!/usr/bin/env bash

get_distribution() {
	distribution="Unknown"
	while read -r line
	do
		element=$(echo "$line" | cut -f1 -d=)
		if [ "$element" = "ID" ]
		then
			distribution=$(echo "$line" | cut -f2 -d=)
		fi
	done < "/etc/os-release"
	echo "${distribution//\"}"
}

USER=$(whoami)
DISTRO=$(get_distribution)
echo "user: ${USER}, distro: ${DISTRO}"

# Install necessary software including curl, python-pip, tox, docker
install_software() {
	if [ $# -eq 0 ]; then
		echo "Should pass me the software name to install"
	fi
	install_list=$1
	echo "Install software: $install_list"
	case $DISTRO in
		ubuntu)
			command -v curl >/dev/null 2>&1 || { echo_r >&2 "No curl found, try installing";sudo apt-get install -y curl; }
			command -v pip >/dev/null 2>&1 || { echo_r >&2 "No pip found, try installing";sudo apt-get install -y python-pip; }
			command -v docker >/dev/null 2>&1 || { echo_r >&2 "No docker-engine found, try installing"; curl -sSL https://get.docker.com/ | sh; sudo service docker restart; }
			command -v docker-compose >/dev/null 2>&1 || { echo_r >&2 "No docker-compose found, try installing"; sudo pip install 'docker-compose>=1.17.0'; }
			sudo apt-get install -y tox nfs-common;
			;;
		debian)
			sudo apt-get install apt-transport-https ca-certificates -y
			sudo sh -c "echo deb https://apt.dockerproject.org/repo debian-jessie main > /etc/apt/sources.list.d/docker.list"
			sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
			sudo apt-get update
			sudo apt-cache policy docker-engine
			sudo apt-get install docker-engine curl python-pip  -y
			sudo service docker start
			;;
		centos)
			sudo yum install -y epel-release yum-utils
			sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
			sudo yum makecache fast
			sudo yum update && sudo yum install -y docker-ce python-pip
			sudo systemctl enable docker
			sudo systemctl start docker
			;;
		*)
			echo "Linux distribution not identified !!! skipping docker & pip installation"
			;;
	esac
	echo_b "Add existing user ${USER} to docker group"
	sudo usermod -aG docker "${USER}"
}

echo "Make sure have installed: python-pip, tox, curl and docker-engine"
install_list=()
for software in pip tox curl docker docker-compose; do
	command -v ${software} >/dev/null 2>&1 || { install_list+=($software); break; }
done
[ -z "$install_list" ] || install_software "$install_list"