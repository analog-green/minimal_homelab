#!/bin/bash
# ==============================================================================
# Copyright (c) 2026 https://github.com/analog-green/minimal_homelab
# Licensed under the MIT License.
# Initial Contributor:  MTG
# ==============================================================================
DIR_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${DIR_SRC}/minimal_homelab_functions.sh" ]; then
    source "${DIR_SRC}/minimal_homelab_functions.sh"
else
    echo "❌ 실행불가. 누락된 파일을 확인해주세요. (minimal_homelab_functions.sh)"
    exit 1
fi
####################################################################################
####################################################################################
print_information;

while true; do
	print_menu;
    echo -e "${ANSI_WIP}  🔔 uninsatll 할 그룹을 선택해주세요 ${ANSI_END}";
	read -p "  Delete: " MENU_INPUT;
	LOWER_MENU_INPUT=$(echo "$MENU_INPUT" | tr '[:upper:]' '[:lower:]');
	TOOL_LIST="";

	if [[ ${LOWER_MENU_INPUT} == "q" ]]; then
		echo -e "${ANSI_ETC} quit. this script. ${ANSI_END}"
		break
	elif [[ ${LOWER_MENU_INPUT} == "i" ]]; then
		print_information
		continue
	fi
	
	echo -e "----------";
    echo -e "${ANSI_WIP}  🔔 tool uninsatll ${ANSI_END}";
	echo -e "----------";
	make_log "ready to uninsatll" "${LOWER_MENU_INPUT}"
	if [[ ${LOWER_MENU_INPUT} -eq 1 ]]; then
        clear_docker "openproject"
        clear_docker "planka"
        clear_docker "planka-db"
	elif [[ ${LOWER_MENU_INPUT} -eq 2 ]]; then
		clear_docker "onedev"

		clear_docker "mariadb"
        clear_docker "oracle"
        clear_docker "postgres"

		clear_docker "mongodb"
        clear_docker "redis"
        clear_docker "memcached"
	elif [[ ${LOWER_MENU_INPUT} -eq 3 ]]; then
		clear_docker "onedev"
		clear_docker "jenkins"
	elif [[ ${LOWER_MENU_INPUT} -eq 4 ]]; then
		clear_docker "jenkins"
	elif [[ ${LOWER_MENU_INPUT} -eq 5 ]]; then
		clear_docker "onedev"
		clear_docker "jenkins"
	elif [[ ${LOWER_MENU_INPUT} -eq 6 ]]; then
		clear_docker "jenkins"
	elif [[ ${LOWER_MENU_INPUT} -eq 7 ]]; then
        clear_docker "portainer"
	elif [[ ${LOWER_MENU_INPUT} -eq 8 ]]; then
        clear_docker "portainer"
	elif [[ ${LOWER_MENU_INPUT} == "all" ]]; then
        clear_docker "openproject"
        clear_docker "planka"
        clear_docker "planka-db"

		clear_docker "mariadb"
        clear_docker "oracle"
        clear_docker "postgres"

		clear_docker "mongodb"
        clear_docker "redis"
        clear_docker "memcached"

		clear_docker "onedev"
		clear_docker "jenkins"

        clear_docker "portainer"
        #rm -rf "${DIR_HOMELAB}"
	fi

	echo "";
	print_docker_ps;
done

echo -e "${ANSI_ETC}  ✅ FIN ${ANSI_END}";
