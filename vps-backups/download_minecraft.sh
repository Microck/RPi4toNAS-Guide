#!/bin/bash

ORACLE_USER="YOUR_ORACLE_SERVER_USERNAME_HERE"
ORACLE_IP="YOUR_ORACLE_SERVER_IP_ADDRESS_HERE"
ORACLE_MC_WORLD_DIR="YOUR_MINECRAFT_WORLD_DIRECTORY_ON_ORACLE_SERVER_HERE"

LVM_MOUNT_BASE="YOUR_NAS_LVM_BASE_MOUNT_PATH_HERE"
MINECRAFT_BACKUPS_SUBDIR_NAME="YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_ON_NAS_HERE"
NAS_BACKUP_DIR="${LVM_MOUNT_BASE}/${MINECRAFT_BACKUPS_SUBDIR_NAME}/"

ORACLE_TEMP_ARCHIVE_PATH="YOUR_TEMPORARY_ARCHIVE_DIRECTORY_ON_ORACLE_SERVER_HERE"
SSH_KEY_PATH="YOUR_SSH_PRIVATE_KEY_FILE_PATH_FOR_ORACLE_ACCESS_HERE"
SSH_OPTIONS="-i ${SSH_KEY_PATH}"

LOG_TAG="YOUR_MINECRAFT_DOWNLOAD_LOG_TAG_HERE"
echo "Starting Minecraft backup download process at $(date)" | systemd-cat -p info -t "${LOG_TAG}"

mkdir -p "${NAS_BACKUP_DIR}"
if [ ! -d "${NAS_BACKUP_DIR}" ]; then
  echo "Error: NAS backup directory ${NAS_BACKUP_DIR} does not exist or could not be created." | systemd-cat -p err -t "${LOG_TAG}"
  exit 1
fi
echo "NAS backup directory confirmed: ${NAS_BACKUP_DIR}" | systemd-cat -p info -t "${LOG_TAG}"

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
ARCHIVE_FILENAME="world_${TIMESTAMP}.tar.gz"
REMOTE_ARCHIVE_FULL_PATH="${ORACLE_TEMP_ARCHIVE_PATH}${ARCHIVE_FILENAME}"

ORACLE_MC_PARENT_DIR=$(dirname "${ORACLE_MC_WORLD_DIR}")
ORACLE_MC_WORLD_NAME=$(basename "${ORACLE_MC_WORLD_DIR}")

echo "Connecting to ${ORACLE_IP} as ${ORACLE_USER} to compress '${ORACLE_MC_WORLD_DIR}' into '${REMOTE_ARCHIVE_FULL_PATH}'..." | systemd-cat -p info -t "${LOG_TAG}"

TAR_COMMAND="tar -czf \"${REMOTE_ARCHIVE_FULL_PATH}\" -C \"${ORACLE_MC_PARENT_DIR}\" \"${ORACLE_MC_WORLD_NAME}\" 2>&1; echo \"TAR_EXIT_CODE:\$?\""
TAR_OUTPUT_AND_ERROR=$(ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "${TAR_COMMAND}")
SSH_CMD_EXIT_CODE=$?

echo "Output from remote tar command (includes stderr and TAR_EXIT_CODE line):" | systemd-cat -p info -t "${LOG_TAG}"
echo "${TAR_OUTPUT_AND_ERROR}" | systemd-cat -p info -t "${LOG_TAG}"

ACTUAL_TAR_EXIT_CODE_LINE=$(echo "${TAR_OUTPUT_AND_ERROR}" | grep 'TAR_EXIT_CODE:')
if [ -n "${ACTUAL_TAR_EXIT_CODE_LINE}" ]; then
    ACTUAL_TAR_EXIT_CODE=$(echo "${ACTUAL_TAR_EXIT_CODE_LINE}" | cut -d':' -f2)
else
    ACTUAL_TAR_EXIT_CODE="UNKNOWN"
fi

if [ "${SSH_CMD_EXIT_CODE}" -ne 0 ] || [ "${ACTUAL_TAR_EXIT_CODE}" = "UNKNOWN" ] || [ "${ACTUAL_TAR_EXIT_CODE}" -ne 0 ]; then
  echo "Error: Failed to create archive on Oracle server." | systemd-cat -p err -t "${LOG_TAG}"
  echo "SSH command exit code: ${SSH_CMD_EXIT_CODE}." | systemd-cat -p err -t "${LOG_TAG}"
  echo "Actual tar exit code on remote server: ${ACTUAL_TAR_EXIT_CODE}." | systemd-cat -p err -t "${LOG_TAG}"
  echo "Checking if archive '${REMOTE_ARCHIVE_FULL_PATH}' somehow exists on Oracle server despite error..." | systemd-cat -p info -t "${LOG_TAG}"
  ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${REMOTE_ARCHIVE_FULL_PATH}\"" 2>&1 | systemd-cat -p info -t "${LOG_TAG}"
  exit 1
fi

echo "Archive created successfully on Oracle server: ${REMOTE_ARCHIVE_FULL_PATH}" | systemd-cat -p info -t "${LOG_TAG}"
echo "(Note: 'tar: file changed as we read it' is a non-fatal warning if server was running and tar exit code was 1 but archive was created)" | systemd-cat -p info -t "${LOG_TAG}"

echo "Verifying remote archive existence and readability: ${REMOTE_ARCHIVE_FULL_PATH}" | systemd-cat -p info -t "${LOG_TAG}"
REMOTE_FILE_STATUS_CMD="if [ -r \"${REMOTE_ARCHIVE_FULL_PATH}\" ]; then echo 'EXISTS_READABLE'; elif [ -e \"${REMOTE_ARCHIVE_FULL_PATH}\" ]; then echo 'EXISTS_UNREADABLE'; else echo 'NOT_FOUND'; fi"
REMOTE_FILE_STATUS=$(ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "${REMOTE_FILE_STATUS_CMD}")
SSH_VERIFY_EXIT_CODE=$?

if [ ${SSH_VERIFY_EXIT_CODE} -ne 0 ]; then
    echo "Error: SSH connection failed while verifying remote file (Exit Code: ${SSH_VERIFY_EXIT_CODE})." | systemd-cat -p err -t "${LOG_TAG}"
    exit 1
fi

if [ "${REMOTE_FILE_STATUS}" != "EXISTS_READABLE" ]; then
    echo "Error: Remote archive '${REMOTE_ARCHIVE_FULL_PATH}' problem on Oracle server before SCP. Status: ${REMOTE_FILE_STATUS}" | systemd-cat -p err -t "${LOG_TAG}"
    echo "Listing contents of ${ORACLE_TEMP_ARCHIVE_PATH} on Oracle server for debugging:" | systemd-cat -p info -t "${LOG_TAG}"
    ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${ORACLE_TEMP_ARCHIVE_PATH}\"" 2>&1 | systemd-cat -p info -t "${LOG_TAG}"
    exit 1
fi
echo "Remote archive '${REMOTE_ARCHIVE_FULL_PATH}' verified as existing and readable." | systemd-cat -p info -t "${LOG_TAG}"

echo "Downloading archive '${ARCHIVE_FILENAME}' to '${NAS_BACKUP_DIR}'..." | systemd-cat -p info -t "${LOG_TAG}"
scp -v ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP}:"${REMOTE_ARCHIVE_FULL_PATH}" "${NAS_BACKUP_DIR}/"
SCP_EXIT_CODE=$?

if [ ${SCP_EXIT_CODE} -eq 0 ]; then
  echo "Download successful." | systemd-cat -p info -t "${LOG_TAG}"
  echo "Deleting temporary archive on Oracle server: ${REMOTE_ARCHIVE_FULL_PATH}" | systemd-cat -p info -t "${LOG_TAG}"
  ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "rm -f \"${REMOTE_ARCHIVE_FULL_PATH}\""
  RM_EXIT_CODE=$?
  if [ ${RM_EXIT_CODE} -ne 0 ]; then
     echo "Warning: Failed to delete remote archive '${REMOTE_ARCHIVE_FULL_PATH}' (SSH/rm Exit Code: ${RM_EXIT_CODE})." | systemd-cat -p warning -t "${LOG_TAG}"
  else
     echo "Remote archive deleted successfully." | systemd-cat -p info -t "${LOG_TAG}"
  fi
  echo "Minecraft backup download process completed successfully at $(date)." | systemd-cat -p info -t "${LOG_TAG}"
  exit 0
else
  echo "Error: Failed to download archive from Oracle server (SCP Exit Code: ${SCP_EXIT_CODE})." | systemd-cat -p err -t "${LOG_TAG}"
  echo "Archive '${REMOTE_ARCHIVE_FULL_PATH}' will NOT be deleted on Oracle server due to download failure." | systemd-cat -p warning -t "${LOG_TAG}"
  echo "Checking if archive still exists on Oracle server after failed SCP..." | systemd-cat -p info -t "${LOG_TAG}"
  ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${REMOTE_ARCHIVE_FULL_PATH}\"" 2>&1 | systemd-cat -p info -t "${LOG_TAG}"
  exit 1
fi