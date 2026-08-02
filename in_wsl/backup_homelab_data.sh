#!/bin/bash
#	백업정책
#	1) 리눅스 데몬 서비스
#	2) sudo vi /etc/crontab을 통해 2시간마다.
#	sed -i 's/\r$//' backup_devops.sh
# ==============================================================================
PATH_BACK="/backup";
PATH_DEVOPS="/dev_minimal_homelab/data";
PATH_C="/mnt/c/backup_minimal_homelab";
PATH_D="/mnt/d/backup_minimal_homelab";

TODAY="$(LC_TIME=C date "+%A")"
TODAY_DETAIL="$(date "+%d_%H%M")"
FILE_NAME="${TODAY}-D${TODAY_DETAIL}.tar.gz"

EXECUTE_FLAG="$1"

if [ -n "${EXECUTE_FLAG}" ]; then
    if [ "${EXECUTE_FLAG}" = "by_crontab" ]; then
        FILE_NAME="${TODAY}.tar.gz"
    elif [ "${EXECUTE_FLAG}" = "by_service" ]; then
        FILE_NAME="${TODAY}-booted.tar.gz"
    fi
fi
####################################################################################
####################################################################################
echo "백업 경로 확인";
mkdir -p "$PATH_BACK" "$PATH_C" "$PATH_D"

cd "${PATH_BACK}"
sudo tar -cf "${FILE_NAME}" -I "gzip -9" ${PATH_DEVOPS}
if [ $? -eq 0 ]; then
    echo "copy to other Dirve(s)";
else
    echo "Failed to compress";
    exit 1
fi
#set -x
cp -p "${PATH_BACK}/${FILE_NAME}" "$PATH_C/" && echo " ... copy to C drive ";
cp -p "${PATH_BACK}/${FILE_NAME}" "$PATH_D/" && echo " ... copy to D drive ";
#set +x
echo "---------------------------------------------------";
echo $(date "+%d_%H%M")
if [ -n "${EXECUTE_FLAG}" ] && [ "${EXECUTE_FLAG}" = "by_crontab" ]; then
    echo "Automatic backup: ${FILE_NAME}";
else
    echo "Manual backup: ${FILE_NAME}";
fi
