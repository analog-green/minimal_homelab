#!/bin/bash
# ==============================================================================
# Copyright (c) 2026 https://github.com/analog-green/minimal_homelab
# Licensed under the MIT License.
# Initial Contributor:  MTG
# ==============================================================================
DIR_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${DIR_SRC}/ansi.sh" ]; then
    source "${DIR_SRC}/ansi.sh"
else
    echo "❌ 실행불가. 누락된 파일을 확인해주세요. (ansi.sh)"
    exit 1
fi

DIR_BACK="/backup";
NW="minimal_homelab";NW_DEV="minimal_homelab-dev";
DIR_HOMELAB="/dev_minimal_homelab";		DIR_HOMELAB_DATA="/dev_minimal_homelab/data";		DIR_HOMELAB_YML="/dev_minimal_homelab/yml";
DIR_WROK="/dev_workspace";
DIR_CURRENT=$(pwd);

ADMIN_ID="admin";
ADMIN_PW="this_is_tmp_pw_123456";

BASH_TRUE=0
BASH_FALSE=1
IS_DOCKER_CLEAN=BASH_TRUE;

MIN_LENGTH=5;
DEFAULT_VAL="minimalHomelab";
WSP_IP=$(hostname -I | awk '{print $1}')
####################################################################################
####################################################################################
# is_xxx
is_installed_package(){
	# 함수 반환값이 아닌 echo에는 >&2로 구분 잊지말것.
	local pack_name=$1;

	if dpkg-query -W -f='${Status}' "$pack_name" 2>/dev/null | grep -q "ok installed" || command -v "$pack_name" &>/dev/null; then
		echo -e "${ANSI_ETC}✅ installed: $pack_name (already) ${ANSI_END}" >&2
		echo ${BASH_TRUE}
    else
		echo -e "${ANSI_ETC}⚠️ none: $pack_name${ANSI_END}" >&2
		echo ${BASH_FALSE}
    fi
}
is_running_container(){
	# 함수 반환값이 아닌 echo에는 >&2로 구분 잊지말것.
	local name=$1
    local status;
    status=$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)

    if [[ "$status" == "true" ]]; then
        echo -e "${ANSI_ETC}✅ container: ${name} (already) ${ANSI_END}" >&2
		echo ${BASH_TRUE}
    else
		echo -e "${ANSI_ETC}⚠️ container: ${name} ${ANSI_END}" >&2
		echo ${BASH_FALSE}
    fi
}
is_alive_webpage(){
	local base_url=$1;
	local init_url=$2;

	for i in {1..15}; do
		curl -k -s "${base_url}" > /dev/null
		if [ $? -eq 0 ]; then
			echo "web page ready	${init_url}"
			return ${BASH_TRUE}
		fi
		sleep 1
	done

	return ${BASH_FALSE}
}
# ==============================================================================
# init_xxx
init_directory(){
	if [ -d "${DIR_HOMELAB}" ] && [ -d "${DIR_HOMELAB_YML}" ] && [ -n "$(ls -A "${DIR_HOMELAB_DATA}" 2>/dev/null)" ]; then
		return ${BASH_TRUE};
    fi

	#set -x;
	sudo mkdir -p "${DIR_BACK}";
	sudo cp backup_homelab_data.sh "${DIR_BACK}/"
	sudo chmod 711 "backup_homelab_data.sh"
	sudo chmod 711 "${DIR_BACK}/backup_homelab_data.sh"

	sudo mkdir -p "${DIR_HOMELAB}";sudo mkdir -p "${DIR_HOMELAB_DATA}";sudo mkdir -p "${DIR_HOMELAB_YML}";
	sudo mkdir -p "${DIR_WROK}";
	
	sudo chown -R $USER:$USER "${DIR_HOMELAB}";sudo chown -R $USER:$USER "${DIR_WROK}";
	sudo chown -R 999:999 "${DIR_HOMELAB_DATA}";sudo chmod -R 755 "${DIR_HOMELAB_DATA}"
	#set +x
}
# ==============================================================================
# make_xxx
make_data_directory(){
	local package_name=$1;
	local arg_arr=$2;
	local arg_arr=("$@");#WARN. ARRAY !!!

	for dir_name in "${arg_arr[@]}"; do
		sudo mkdir -p "${DIR_HOMELAB_DATA}/${package_name}";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/${package_name}";
    done
	sudo mkdir -p "${DIR_HOMELAB_YML}/${package_name}";
}
make_devops_directory(){
	local package_name=$1
    local yml_file_name=$2

	sudo mkdir -p "${DIR_HOMELAB_DATA}";sudo mkdir -p "${DIR_HOMELAB_DATA}/${package_name}";
	sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/${package_name}";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/${package_name}";

	sudo mkdir -p "${DIR_HOMELAB_YML}";sudo mkdir -p "${DIR_HOMELAB_YML}/${package_name}";
	sudo chown -R 999:999 "${DIR_HOMELAB_YML}/${package_name}";sudo chmod -R 755 "${DIR_HOMELAB_YML}/${package_name}";
	sudo chown -R $USER:$USER "${DIR_HOMELAB_YML}/${package_name}"

	local yml_file="${DIR_HOMELAB_YML}/${package_name}/docker-compose.yml";
	sudo cp "yml_files/${yml_file_name}.yml" "${yml_file}";#unoffical yml

	# return ${yml_file}
	echo "${yml_file}";
}
make_network(){
	if ! docker network inspect "${NW}" >/dev/null 2>&1; then
		echo "⚠️ NW none: ${NW}"
		sudo docker network create "${NW}"
	fi
	
	if ! docker network inspect "${NW_DEV}" >/dev/null 2>&1; then
		echo "⚠️ NW none: ${NW_DEV}"
		sudo docker network create "${NW_DEV}"
	fi
}
make_log(){
	local arg1=$1;
	local arg2=$2;
	local log_msg=$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "${arg1}" "${arg2}")

	echo "${log_msg}" >> "log.log"
}
make_docker_log(){
	local docker_name=$1;
	docker logs --tail 20 "${docker_name}" >> ./docker.log 2>&1
	echo "=================================" >> ./docker.log 2>&1
}
# ==============================================================================
install_docker(){
	local is_installed=$(is_installed_package "docker-ce")
    if [[ "${is_installed}" -eq ${BASH_TRUE} ]]; then
        return;
    fi

	sudo apt-get update;
	sudo apt-get install -y psmisc apt-transport-https ca-certificates curl gnupg lsb-release;

	OS_ID=$(. /etc/os-release; echo "$ID");
	curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg;
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${OS_ID} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	sudo apt-get update;
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io;
	docker --version;
	docker network inspect ${NW} >/dev/null 2>&1 || docker network create ${NW}

	if ! getent group docker > /dev/null; then
		sudo groupadd docker;
	fi;
	echo -e "${ANSI_WIP}  🔔 터미널 쉘 재접속 ${ANSI_END}"
	sleep 1;
	sudo usermod -aG docker $USER;newgrp docker;
	exec su "$USER"
}
install_docker_gui(){
	echo -e "${ANSI_BASIC}Operate/Monitoring: ${ANSI_END}"


	local is_running=$(is_running_container "portainer")
	# echo "is_running=${is_running}";
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		sudo chmod 666 /var/run/docker.sock;
		local yml_file=$(make_devops_directory "portainer" "etc_portainer")

		sed -i "s|__PORT1__|2700|g" "${yml_file}";
		sed -i "s|__PORT2__|2743|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/portainer|g" "${yml_file}";
		sed -i "s|__NW_CODING__|${NW_DEV}|g" "${yml_file}";
		sed -i "s|__NW__|${NW}|g" "${yml_file}";

        docker compose -f "${yml_file}" up -d;
		is_alive_webpage "http://localhost:2700" "http://localhost:2700/#!/init/admin"
		local setup_token=$(sudo docker logs portainer 2>&1 | grep "setup_token=" | sed -n 's/.*setup_token=\([^ ]*\).*/\1/p')
		echo -e "${ANSI_BASIC} setup_token: ${setup_token} ${ANSI_END}"
		echo -e "${ANSI_ETC} 수동으로 확인시   sudo docker logs portainer 2>&1 | grep -i "token" ${ANSI_END}"

		make_log "portainer setup_token" "${setup_token}"
	fi
}
install_coding_lang(){
	if ! command --version dotnet &>/dev/null; then
		echo -e "${ANSI_ETC}✅ installed: dotnet-sdk (already) ${ANSI_END}" >&2
	else
		echo -e "${ANSI_ETC}⚠️ none: dotnet-sdk ${ANSI_END}" >&2

		wget https://dot.net/v1/dotnet-install.sh -O lang/install-dotnet.sh;chmod +x lang/install-dotnet.sh;
		bash lang/install-dotnet.sh --version latest --channel 10.0

		echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
		echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc
		source ~/.bashrc
		dotnet --version;
    fi

	if ! command -v java &>/dev/null || ! java -version 2>&1 | grep -q '21'; then
		echo -e "${ANSI_ETC}✅ installed: openjdk-21-jdk-headless (already) ${ANSI_END}" >&2
	else
		echo -e "${ANSI_ETC}⚠️ none: openjdk-21-jdk-headless ${ANSI_END}" >&2

		# PPA 기반
		sudo apt update && sudo apt install -y software-properties-common
		sudo add-apt-repository -y ppa:openjdk-r/ppa
		sudo apt update
		sudo apt install -y openjdk-21-jdk-headless
    fi
}
install_coding_rdbms(){
	echo -e "${ANSI_BASIC}Coding: RDBMS - mariadb, oracle-free, postgres ${ANSI_END}"

	local is_running=$(is_running_container "mariadb")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "mariadb" "coding_mariadb")
		sudo mkdir -p "${DIR_HOMELAB_DATA}/mariadb_conf";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/mariadb_conf";

		sed -i "s|__PORT_MARIA_1__|13306|g" "${yml_file}";
		sed -i "s|__PORT_MARIA_2__|23306|g" "${yml_file}";
		sed -i "s|__PORT_MARIA_4__|43306|g" "${yml_file}";
		sed -i "s|__ADMIN_PW__|${ADMIN_PW}|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}|g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		echo -e "${ANSI_BOX_BASIC}init account info: ServerHost=localhost / Username=root / Password=${ADMIN_PW} ${ANSI_END}";
		make_log "mariadb" "ServerHost=localhost / Username=root / Password=${ADMIN_PW}"
		make_docker_log "mariadb"
	else
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/mariadb";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/mariadb";
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/mariadb_conf";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/mariadb_conf";
	fi
	
	local is_running=$(is_running_container "oracle")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "oracle" "coding_oracle")
		sudo chown -R 54321:54321 "${DIR_HOMELAB_DATA}/oracle";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/oracle";

		sed -i "s|__PORT_OC_11__|11521|g" "${yml_file}";
		sed -i "s|__PORT_OC_12__|21521|g" "${yml_file}";
		sed -i "s|__PORT_OC_14__|41521|g" "${yml_file}";
		sed -i "s|__PORT_OC_21__|15500|g" "${yml_file}";
		sed -i "s|__PORT_OC_22__|25500|g" "${yml_file}";
		sed -i "s|__PORT_OC_24__|45500|g" "${yml_file}";#registered port=1024~49151. SAFE!!
		sed -i "s|__ADMIN_PW__|${ADMIN_PW}|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/oracle|g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		echo -e "${ANSI_BOX_BASIC}init account info: Host=localhost / Database=FREE / Username=system / Password=${ADMIN_PW} ${ANSI_END}";
		make_log "oracle" "Host=localhost / Database=FREE / Username=system / Password=${ADMIN_PW}"
		make_docker_log "oracle"

		# echo -e "${ANSI_ETC} ready to oracle DB (about 3min+) ${ANSI_END}"
		# until docker exec -i oracle sqlplus -s / as sysdba <<< "SET HEAD OFF FEEDBACK OFF; SELECT open_mode FROM v\$pdbs WHERE name = 'FREEPDB1'; EXIT;" | grep -q "READ WRITE"
		# do
		# 	echo -e "${ANSI_ETC} ... ... ... ${ANSI_END}"
		# 	sleep 10
		# done
		# docker exec -i oracle sqlplus -s / as sysdba <<-EOF
		# 	ALTER USER SYSTEM IDENTIFIED BY "${ADMIN_PW}";
		# 	ALTER USER SYSTEM ACCOUNT UNLOCK;
		# 	EXIT;
		# EOF
	else
		sudo chown -R 54321:54321 "${DIR_HOMELAB_DATA}/oracle";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/oradata";
	fi

	local is_running=$(is_running_container "postgres")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "postgres" "coding_postgres")

		sed -i "s|__PORT_PG_1__|15432|g" "${yml_file}";
		sed -i "s|__PORT_PG_2__|25432|g" "${yml_file}";
		sed -i "s|__PORT_PG_4__|45432|g" "${yml_file}";
		sed -i "s|__ADMIN_PW__|${ADMIN_PW}|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/postgres|g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		echo -e "${ANSI_BOX_BASIC}init account info: Host=localhost / DB=postgres / user=postgres / pw=${ADMIN_PW} ${ANSI_END}";
		make_log "postgres" "Host=localhost / DB=postgres / user=postgres / pw=${ADMIN_PW}"
		make_docker_log "postgres"
	else
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/postgres";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/postgres";
	fi
}
install_coding_nosql(){
	echo -e "${ANSI_BASIC}Coding: NoSQL - mongodb, redis, memcached ${ANSI_END}"

	local is_running=$(is_running_container "mongodb")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "mongodb" "coding_mongodb")
		sudo mkdir -p "${DIR_HOMELAB_DATA}/mongodb";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/mongodb";

		sed -i "s|__PORT_1__|17017|g" "${yml_file}";
		sed -i "s|__PORT_2__|27017|g" "${yml_file}";
		sed -i "s|__PORT_4__|47017|g" "${yml_file}";#registered port=1024~49151. SAFE!!
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/mongodb|g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		make_log "mongodb" "install OK"
	fi
	
	local is_running=$(is_running_container "redis")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "redis" "coding_redis")
		sudo mkdir -p "${DIR_HOMELAB_DATA}/redis";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/redis";

		sed -i "s/__PORT_1__/16379/g" "${yml_file}";
		sed -i "s/__PORT_2__/26379/g" "${yml_file}";
		sed -i "s/__PORT_4__/46379/g" "${yml_file}";#registered port=1024~49151. SAFE!!
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/redis|g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		make_log "redis" "install OK"
	fi

	local is_running=$(is_running_container "memcached")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "memcached" "coding_memcached")

		sed -i "s/__PORT_1__/11211/g" "${yml_file}";
		sed -i "s/__PORT_2__/21211/g" "${yml_file}";
		sed -i "s/__PORT_4__/41211/g" "${yml_file}";
		sed -i "s|__NW__|${NW_DEV}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		make_log "memcached" "install OK"
	fi
}
install_version_control(){
	echo -e "${ANSI_BASIC}Coding/Build/Deploy: onedev ${ANSI_END}"

	sudo apt install -y git > /dev/null 2>&1
	sudo apt install -y subversion > /dev/null 2>&1

	git --version;svn --version | head -n 1;
	local is_running=$(is_running_container "onedev")

    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "onedev" "coding_version_control")

		sed -i "s|__NAME__|onedev|g" "${yml_file}";
		sed -i "s|__PORT1__|2200|g" "${yml_file}";
		sed -i "s|__PORT2__|2201|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/onedev|g" "${yml_file}";
		sed -i "s|__NW__|${NW}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		is_alive_webpage "http://localhost:2200" "http://localhost:2200"
		echo -e "${ANSI_BOX_BASIC}account first setting PLZ ${ANSI_END}";
		make_log "onedev" "http://localhost:2200"
		make_docker_log "onedev"
    fi
	#	END. openproject
}
install_automation(){
	echo -e "${ANSI_BASIC}Build/Test/Release: jenkins ${ANSI_END}"
	
	local is_running=$(is_running_container "jenkins")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "jenkins" "etc_jenkins")
		sudo chown -R 1000:1000 "${DIR_HOMELAB_DATA}/jenkins";
		sudo chmod 666 /var/run/docker.sock;

		sed -i "s|__PORT__|2380|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/jenkins|g" "${yml_file}";
		sed -i "s|__NW_CODING__|${NW_DEV}|g" "${yml_file}";
		sed -i "s|__NW__|${NW}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		is_alive_webpage "http://${WSP_IP}:2380" "http://${WSP_IP}:2380"
		init_pass=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null)
		echo -e "${ANSI_BOX_BASIC}init account info: init_pass=${init_pass} ${ANSI_END}";
		make_log "jenkins" "http://${WSP_IP}:2380/login   init_pass=${init_pass}"
		make_docker_log "jenkins"
    fi
}
install_plan(){
	echo -e "${ANSI_BASIC}Plan: openproject, planka ${ANSI_END}"
	local is_running=$(is_running_container "openproject")

    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "openproject" "plan_openproject")

		sudo mkdir -p "${DIR_HOMELAB_DATA}/openproject/assets";
		sudo mkdir -p "${DIR_HOMELAB_DATA}/openproject/pgdata";
		sudo chown -R 1000:1000 "${DIR_HOMELAB_DATA}/openproject/assets";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/openproject/assets"
		sudo chown -R 102:102 "${DIR_HOMELAB_DATA}/openproject/pgdata";sudo chmod -R 700 "${DIR_HOMELAB_DATA}/openproject/pgdata"
		sudo chmod 666 /var/run/docker.sock;

		local random_key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32);# leng=32
		sed -i "s|__KEY__|${random_key}|g" "${yml_file}";
		sed -i "s|__NAME__|openproject|g" "${yml_file}";
		sed -i "s|__PORT__|2100|g" "${yml_file}";
		sed -i "s|__WSL_IP__|${WSP_IP}|g" "${yml_file}";
		sed -i "s|__LANG__|ko|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/openproject|g" "${yml_file}";
		sed -i "s|__NW__|${NW}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		is_alive_webpage "http://${WSP_IP}:2100" "http://${WSP_IP}:2100"
		echo -e "${ANSI_BOX_BASIC}init account info: admin / ${ADMIN_PW} ${ANSI_END}";
		make_log "openproject" "admin/${ADMIN_PW}	http://${WSP_IP}:2100"
		make_docker_log "openproject"
	else
		sudo chown -R 1000:1000 "${DIR_HOMELAB_DATA}/openproject/assets";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/openproject/assets"
		sudo chown -R 102:102 "${DIR_HOMELAB_DATA}/openproject/pgdata";sudo chmod -R 700 "${DIR_HOMELAB_DATA}/openproject/pgdata"
		#docker stop openproject
		#sudo rm -f "${DIR_HOMELAB_DATA}/openproject/pgdata/postmaster.pid"
		#docker start openproject
	fi
	#	END. openproject


	is_running=$(is_running_container "planka")
    if [[ "${is_running}" -eq "${BASH_FALSE}" ]]; then
		local yml_file=$(make_devops_directory "planka" "plan_planka")

		sudo mkdir -p "${DIR_HOMELAB_DATA}/planka/data"
		sudo mkdir -p "${DIR_HOMELAB_DATA}/planka/db-data"
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/planka/data";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/planka/data"
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/planka/db-data";sudo chmod -R 700 "${DIR_HOMELAB_DATA}/planka/db-data"

		sed -i "s|__NAME1__|planka|g" "${yml_file}";
		sed -i "s|__NAME2__|planka-db|g" "${yml_file}";
		sed -i "s|__PORT__|2101|g" "${yml_file}";
		sed -i "s|__ADMIN_PW__|${ADMIN_PW}|g" "${yml_file}";
		sed -i "s|__VOL_PATH__|${DIR_HOMELAB_DATA}/planka|g" "${yml_file}";
		sed -i "s|__NW__|${NW}|g" "${yml_file}";

		docker compose -f "${yml_file}" up -d;
		is_alive_webpage "http://localhost:2101" "http://localhost:2101"
		echo -e "${ANSI_BOX_BASIC}init account info: admin / ${ADMIN_PW} ${ANSI_END}";
		make_log "planka" "${ADMIN_ID}/${ADMIN_PW}	http://localhost:2101"
		make_docker_log "planka"
	else
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/planka/data";sudo chmod -R 755 "${DIR_HOMELAB_DATA}/planka/data"
		sudo chown -R 999:999 "${DIR_HOMELAB_DATA}/planka/db-data";sudo chmod -R 700 "${DIR_HOMELAB_DATA}/planka/db-data"
    fi
}
# ==============================================================================
# print_xxx
print_information(){
	clear;
	echo -e "${ANSI_HELP} ▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣ "
	echo -e "▣▣                                                                                             ▣▣"
	echo -e "▣                                         ▄▄   ▄▄▄   ▄▄▄                      ▄▄       ▄▄       ▣"
	echo -e "▣            ▀▀        ▀▀                 ██   ███   ███                      ██       ██       ▣"
	echo -e "▣   ███▄███▄ ██  ████▄ ██  ███▄███▄  ▀▀█▄ ██   █████████ ▄███▄ ███▄███▄ ▄█▀█▄ ██  ▀▀█▄ ████▄    ▣"
	echo -e "▣   ██ ██ ██ ██  ██ ██ ██  ██ ██ ██ ▄█▀██ ██   ███▀▀▀███ ██ ██ ██ ██ ██ ██▄█▀ ██ ▄█▀██ ██ ██    ▣"
	echo -e "▣   ██ ██ ██ ██▄ ██ ██ ██▄ ██ ██ ██ ▀█▄██ ██   ███   ███ ▀███▀ ██ ██ ██ ▀█▄▄▄ ██ ▀█▄██ ████▀    ▣"
	echo -e "▣                                      _                                                        ▣"
	echo -e "▣                                __   (_ _  _  /  \|_     _ |_      __                          ▣"
	echo -e "▣                                     | (_)|   \__/|_)|_|| )|_|_|                               ▣"
	echo -e "▣▣                                                                                             ▣▣"
	echo -e " ▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣▣ ${ANSI_RESET}"
	echo -e "${ANSI_HELP}
	 Copyright (c) 2026 https://github.com/analog-green/minimal_homelab
	 Licensed under the MIT License.
	 
	 Initial Contributor: MTG
	 Edit: 2026-08-02 (UTC+9)
	 ASCII art: http://patorjk.com/software/taag (Coder Mini, Straight)
	 
	 1) Env: wsl, ubuntu
	 2) Home Lab 사이즈인 devOps세팅에서 프로그래밍&설계에 집중 할 시간을 확보용도.
	    DevOps에 유용한 자동화 스크립트 공개 템플릿으로 제공.
	 3) Port number rule
		 21xx: Plan tool+@       22xx: Coding tool+@     23xx: Build tool+@
		1xxxx: dev-test         2xxxx: qa-test          4xxxx: live(public)
	 4) Encoding: UTF-8
	 5) 도커와 portainer기반으로 패키지가 다뤄집니다.
	${ANSI_END}"
}
print_menu(){
	echo -e "";
	echo -e "${ANSI_WIP}  🔔 Tool list ${ANSI_END}";
	echo -e "  1  Plan       : openproject-17, PLANKA(Community)
  2  Coding     : git, git server, subversion, openjdk-21, dotnet-sdk-10, RDBMS, NoSQL
  3  Build      : git server, jenkins(jdk21)
  4  Test       : jenkins(jdk21)
  5  Deploy     : git server
  6  Release    : jenkins(jdk21)
  7  Operate    : Portainer(CE)
  8  Monitoring : Portainer(CE)
  (all: 1~8)
  (i: infomation. about this script)
  (q: quit this script)
----------
${ANSI_ETC}  IS_DOCKER_CLEAN: ${IS_DOCKER_CLEAN} ${ANSI_END}
${ANSI_ETC}  DIR_HOMELAB_DATA: ${DIR_HOMELAB_DATA} ${ANSI_END}"
}
print_docker_ps(){
	echo -e "${ANSI_WIP}  🔔 현재 구동중인 도커 컨테이너 목록 ${ANSI_END}";
	echo -e "${ANSI_BOX_BASIC} Name \t\t\t Port(s)\t\t NW Bridge \t\t Create ${ANSI_END}";
	docker ps --format "{{.Names}}\t{{.Ports}}\t{{.CreatedAt}}" | while read -r line; do                       
        name=$(echo "$line" | awk -F'\t' '{print $1}')                                                              
	ports_raw=$(echo "$line" | awk -F'\t' '{print $2}')
	created=$(echo "$line" | awk -F'\t' '{print $3}')
    bridge=$(docker inspect -f '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' "$name")    
	                                                                                                                    
	if [ -z "$ports_raw" ]; then                                                                                
			echo -e "${name}\tnone\t${cid}\t${bridge}\t${created}"                                              
	else                                                                                                        
		first_port=$(echo "$ports_raw" | cut -d',' -f1 | xargs)          
		echo -e "${name}\t${first_port}\t${cid}\t${bridge}\t${created}"                                     
		echo "$ports_raw" | cut -d',' -f2- | tr ',' '\n' | while read -r extra_port; do                     

		if [ ! -z "$extra_port" ]; then
				echo -e " \t$(echo "$extra_port" | xargs)\t \t \t "                                         
			fi                                                                                                  
			done                                                                                                
		fi                                                                                                          
		done | column -t -s $'\t'
}
# ==============================================================================
# clear_xxx
clear_docker(){
	local pack_name=$1;

    docker stop "$pack_name";docker rm "$pack_name";
	local is_installed=$(is_installed_package "$pack_name")
}
# ==============================================================================
# set_xxx
set_basic_info(){
	echo -e "${ANSI_WIP}  🔔 yml에 사용할 관리자 계정 정보를 입력하세요. ${ANSI_END}";
	echo -e "${ANSI_WIP}     info 1. 해당 정보는 외부 전송되지 않습니다. ${ANSI_END}";
	echo -e "${ANSI_WIP}     info 2. ${MIN_LENGTH}자 이상의 입력이 없을경우 기본값: ${DEFAULT_VAL} ${ANSI_END}";
	read -p "  admin id: " ADMIN_ID;
	read -p "  admin pw: " ADMIN_PW;

	if [ ${#ADMIN_ID} -lt $MIN_LENGTH ]; then
		ADMIN_ID="$DEFAULT_VAL"
	fi
	if [ ${#ADMIN_PW} -lt $MIN_LENGTH ]; then
		ADMIN_PW="$DEFAULT_VAL"
	fi

	make_log "ADMIN_ID/ADMIN_PW" "${ADMIN_ID}/${ADMIN_PW}"
}
# ==============================================================================
# (etc.)
copy_docker_data(){
	local dir_name=$1
	local docker_name=$2
	local docker_path=$3
	local docker_img=$4

	#set -x;
	if [ -d "${DIR_HOMELAB_DATA}/${dir_name}" ] && [ -n "$(ls -A "${DIR_HOMELAB_DATA}/${dir_name}" 2>/dev/null)" ]; then
		echo -e "${ANSI_ETC}  existe: ${DIR_HOMELAB_DATA}/${dir_name} ${ANSI_END}"
		return ${BASH_FALSE};
    fi
	if ! docker inspect "$docker_name" >/dev/null 2>&1; then
		echo -e "${ANSI_ETC}  docker not yet: ${docker_name} ${ANSI_END}"
		
		docker create --name "${docker_name}" "$docker_img";
		docker cp "${docker_name}:${docker_path}" "${DIR_HOMELAB_DATA}/"
		docker rm "${docker_name}"
		return;
	fi
	sudo mkdir -p "${DIR_HOMELAB_DATA}/${dir_name}";
	docker cp "${docker_name}:${docker_path}" "${DIR_HOMELAB_DATA}/"
	#set +x
}
download_yml(){
	local repo_url=$1;
	local tool_name=$2;

	sudo mkdir -p "${DIR_HOMELAB}/yml_${tool_name}";
	sudo mkdir -p "${DIR_HOMELAB_DATA}/${tool_name}";
	
	sudo chown -R $USER:$USER "${DIR_HOMELAB}";sudo chown -R $USER:$USER "${DIR_WROK}";
	sudo chown -R 999:999 "${DIR_HOMELAB_DATA}";sudo chmod -R 755 "${DIR_HOMELAB_DATA}"

	curl -L ${repo_url} -o "${DIR_HOMELAB}/yml_${tool_name}/docker-compose.yml"
}
pull_and_update_docker(){
	# WARN. Not yet. DON'T USE
	# 경고. 준비중이라 아직 쓰지마세요.
	local package_name=$1;

	docker compose -f "${DIR_HOMELAB_YML}/${package_name}/docker-compose.yml" pull
	docker compose -f "${DIR_HOMELAB_YML}/${package_name}/docker-compose.yml" up -d
	docker logs ${package_name} --tail 10;
}