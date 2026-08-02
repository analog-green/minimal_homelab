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
init_directory;
set_basic_info;


while true; do
	print_menu;
	read -p "  Tool type: " MENU_INPUT;
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
	install_docker;
	make_network;
	echo -e "----------";
	if [[ ${LOWER_MENU_INPUT} -eq 1 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Plan       : openproject-17, PLANKA(Community)"
		install_plan;
	elif [[ ${LOWER_MENU_INPUT} -eq 2 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Coding     : git, git server, subversion, openjdk-21, dotnet-sdk-10, RDBMS, NoSQL"
		install_coding_lang;install_coding_rdbms;install_coding_nosql;

		install_version_control;
	elif [[ ${LOWER_MENU_INPUT} -eq 3 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Build      : git server, jenkins(jdk21)"
		install_version_control;
		install_automation;
	elif [[ ${LOWER_MENU_INPUT} -eq 4 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Test       : jenkins(jdk21)"
		install_automation;
	elif [[ ${LOWER_MENU_INPUT} -eq 5 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Deploy     : git server"
		install_version_control;
		install_automation;
	elif [[ ${LOWER_MENU_INPUT} -eq 6 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Release    : jenkins(jdk21)"
		install_automation;
	elif [[ ${LOWER_MENU_INPUT} -eq 7 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Operate    : Portainer(CE)"
		install_docker_gui;
	elif [[ ${LOWER_MENU_INPUT} -eq 8 ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}	Monitoring : Portainer(CE)"
		install_docker_gui;
	elif [[ ${LOWER_MENU_INPUT} == "all" ]]; then
		make_log "ready to install type" "${LOWER_MENU_INPUT}"
		install_plan;

		install_coding_lang;install_coding_rdbms;install_coding_nosql;

		install_version_control;install_automation;
		install_docker_gui;
	fi

	echo "";
	print_docker_ps;
done

echo -e "${ANSI_ETC}  ✅ FIN ${ANSI_END}";
