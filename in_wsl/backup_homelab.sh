#!/bin/bash
# ==============================================================================
PATH_BACK="/backup";
PATH_DEVOPS="/dev_minimal_homelab";
PATH_C="/mnt/c/backup_minimal_homelab";
PATH_D="/mnt/d/backup_minimal_homelab";

WEEK="$(LC_TIME=C date "+%A")"
DATE_HM="$(date "+%H%M")"
FILE_NAME=""
FILE_LOG="$(date "+%Y")_backup.log"

EXECUTE_FLAG="$1"
####################################################################################
####################################################################################
echo $(date "+%m%d_H%H%M");
echo $(date "+%m%d_H%H%M") >> "${PATH_BACK}/${FILE_LOG}"
echo "Take a break time - pause oracle mongodb";
sudo mkdir -p "$PATH_BACK" "$PATH_C" "$PATH_D"
cd "${PATH_BACK}"
docker ps -q --filter "status=running" | xargs -r docker pause


if [ -z "${EXECUTE_FLAG}" ]; then
    FILE_NAME="${WEEK}-H${DATE_HM}.tar.gz";
    sudo tar -cf "${FILE_NAME}" -I "gzip -7" ${PATH_DEVOPS}
else
    if [ "${EXECUTE_FLAG}" = "by_service" ]; then
        FILE_NAME="${WEEK}-booted.tar.gz"
    # elif [ "${EXECUTE_FLAG}" = "by_crontab" ]; then
    #     FILE_NAME="${TODAY}.tar.gz"
    fi
    sudo tar -cf "${FILE_NAME}" -I "gzip -5" ${PATH_DEVOPS}
fi


if [ $? -eq 0 ]; then
    echo "Copy to other Dirve(s)";
else
    echo "Failed to compress";
    exit 1
fi
#set -x
sudo chmod 644 "${PATH_BACK}/${FILE_NAME}"
sudo cp "${PATH_BACK}/${FILE_NAME}" "$PATH_C/" && echo " ... copy to C:\backup_minimal_homelab ";
sudo cp "${PATH_BACK}/${FILE_NAME}" "$PATH_D/" && echo " ... copy to D:\backup_minimal_homelab ";
#set +x
echo "---------------------------------------------------";
sudo ls -al "${PATH_BACK}/${FILE_NAME}" 2>&1 | tee -a "${PATH_BACK}/${FILE_LOG}"
sudo ls -alh "${PATH_BACK}/${FILE_NAME}" 2>&1 | tee -a "${PATH_BACK}/${FILE_LOG}"
echo $(date "+%m%d_H%H%M");
echo $(date "+%m%d_H%H%M") >> "${PATH_BACK}/${FILE_LOG}"
docker ps -q --filter "status=paused" | xargs -r docker unpause

if [ -z "${EXECUTE_FLAG}" ]; then
    echo "Manual backup: ${FILE_NAME}"
else
    echo "Automatic backup: ${FILE_NAME}"
fi
echo "---------------------------------------------------" >> "${PATH_BACK}/${FILE_LOG}"