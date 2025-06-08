#!/bin/bash

LVM_MOUNT_BASE="YOUR_NAS_LVM_BASE_MOUNT_PATH_HERE"
MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION="YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_FOR_ROTATION_HERE"
MC_BACKUP_DIR="${LVM_MOUNT_BASE}/${MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION}/"

MAX_BACKUP_SIZE_GIB=YOUR_MAX_TOTAL_BACKUP_SIZE_IN_GIB_HERE
MAX_SIZE_BYTES=$((${MAX_BACKUP_SIZE_GIB} * 1024 * 1024 * 1024))
LOG_TAG="YOUR_MINECRAFT_ROTATION_LOG_TAG_HERE"

echo "Starting Minecraft backup rotation check at $(date)" | systemd-cat -p info -t ${LOG_TAG}

if [ ! -d "${MC_BACKUP_DIR}" ]; then
  echo "Error: Backup directory ${MC_BACKUP_DIR} not found." | systemd-cat -p err -t ${LOG_TAG}
  exit 1
fi

while true; do
  CURRENT_SIZE=$(du -sb "${MC_BACKUP_DIR}" | cut -f1)

  if [ -z "${CURRENT_SIZE}" ]; then
      echo "Warning: Could not determine current size of ${MC_BACKUP_DIR}." | systemd-cat -p warning -t ${LOG_TAG}
      CURRENT_SIZE=0
  fi

  echo "Current size of ${MC_BACKUP_DIR} is ${CURRENT_SIZE} bytes. Max allowed is ${MAX_SIZE_BYTES} bytes." | systemd-cat -p info -t ${LOG_TAG}

  if [ "${CURRENT_SIZE}" -le "${MAX_SIZE_BYTES}" ]; then
    echo "Current size is within limit. No rotation needed." | systemd-cat -p info -t ${LOG_TAG}
    break
  fi

  echo "Current size exceeds limit. Attempting to delete oldest backup." | systemd-cat -p info -t ${LOG_TAG}
  OLDEST=$(ls -tr "${MC_BACKUP_DIR}" | grep '^world_.*\.tar\.gz$' | head -n 1)

  if [ -z "${OLDEST}" ]; then
    echo "Warning: No backups found matching 'world_*.tar.gz' to delete in ${MC_BACKUP_DIR}, but size limit exceeded. Check directory or naming convention from download script." | systemd-cat -p warning -t ${LOG_TAG}
    break
  fi

  echo "Deleting oldest backup: ${MC_BACKUP_DIR}${OLDEST}" | systemd-cat -p info -t ${LOG_TAG}
  if rm -f "${MC_BACKUP_DIR}${OLDEST}"; then
      echo "Successfully deleted ${MC_BACKUP_DIR}${OLDEST}." | systemd-cat -p info -t ${LOG_TAG}
  else
      echo "Error: Failed to delete ${MC_BACKUP_DIR}${OLDEST}. Exit code: $?." | systemd-cat -p err -t ${LOG_TAG}
      sleep 5
  fi
  sleep 1
done

echo "Minecraft backup rotation check complete at $(date)." | systemd-cat -p info -t ${LOG_TAG}
exit 0