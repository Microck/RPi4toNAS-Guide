#!/bin/bash

MAIN_PC_MAC="YOUR_MAIN_PC_MAC_ADDRESS_HERE"
MAIN_PC_IP="YOUR_MAIN_PC_IP_ADDRESS_HERE"
CREDENTIALS_FILE="YOUR_SAMBA_CREDENTIALS_FILE_PATH_HERE"
PI_USERNAME="YOUR_PI_USERNAME_FOR_FILE_OWNERSHIP_HERE"

MNT_PC_DRIVE_C="YOUR_MOUNT_POINT_FOR_PC_C_DRIVE_ON_PI_HERE"
MNT_PC_DRIVE_D="YOUR_MOUNT_POINT_FOR_PC_D_DRIVE_ON_PI_HERE"

LVM_MOUNT_BASE="YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE"

C_DRIVE_BACKUP_SUBDIR_NAME="YOUR_C_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE"
D_DRIVE_BACKUP_SUBDIR_NAME="YOUR_D_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE"
IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME="YOUR_IMPORTANT_FILES_BACKUP_BASE_SUBDIRECTORY_NAME_HERE"

NAS_C_DRIVE_BACKUP_DIR="${LVM_MOUNT_BASE}/${C_DRIVE_BACKUP_SUBDIR_NAME}/"
NAS_D_DRIVE_BACKUP_DIR="${LVM_MOUNT_BASE}/${D_DRIVE_BACKUP_SUBDIR_NAME}/"
NAS_IMPORTANT_DIR="${LVM_MOUNT_BASE}/${IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME}/"

WINDOWS_C_DRIVE_SHARE_NAME="YOUR_WINDOWS_C_DRIVE_ADMIN_SHARE_NAME_HERE"
WINDOWS_D_DRIVE_SHARE_NAME="YOUR_WINDOWS_D_DRIVE_ADMIN_SHARE_NAME_HERE"

PC_SHARE_C="//${MAIN_PC_IP}/${WINDOWS_C_DRIVE_SHARE_NAME}"
PC_SHARE_D="//${MAIN_PC_IP}/${WINDOWS_D_DRIVE_SHARE_NAME}"

EXCLUDE_FILE_C="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_C_DRIVE_HERE"
EXCLUDE_FILE_D="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_D_DRIVE_HERE"
EXCLUDE_FILE_IMPORTANT="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_IMPORTANT_FILES_HERE"

IMPORTANT_FOLDERS_C=(
    "YOUR_IMPORTANT_FOLDER_C_1_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_2_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_3_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_4_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_5_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_6_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_7_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_8_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_9_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_10_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_11_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_C_12_PATH_HERE"
)

IMPORTANT_FOLDERS_D=(
    "YOUR_IMPORTANT_FOLDER_D_1_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_D_2_PATH_HERE"
    "YOUR_IMPORTANT_FOLDER_D_3_PATH_HERE"
)

LOG_TAG="YOUR_CUSTOM_SYSTEMD_LOG_TAG_HERE"
echo "Starting backup process at $(date)" | systemd-cat -p info -t ${LOG_TAG}

PI_UID=$(id -u "${PI_USERNAME}")
PI_GID=$(id -g "${PI_USERNAME}")
if [ -z "${PI_UID}" ] || [ -z "${PI_GID}" ]; then
    echo "Error: User '${PI_USERNAME}' not found on this system. Please set PI_USERNAME correctly." | systemd-cat -p err -t ${LOG_TAG}
    exit 1
fi

echo "Sending WOL packet to ${MAIN_PC_MAC}..." | systemd-cat -p info -t ${LOG_TAG}
if ! /usr/bin/wakeonlan "${MAIN_PC_MAC}"; then
    echo "wakeonlan failed, trying etherwake..." | systemd-cat -p warning -t ${LOG_TAG}
    if ! /usr/sbin/etherwake "${MAIN_PC_MAC}"; then
        echo "Error: Both wakeonlan and etherwake failed to send WOL packet." | systemd-cat -p err -t ${LOG_TAG}
    fi
fi

WAIT_TIME=YOUR_NUMBER_OF_SECONDS_TO_WAIT_FOR_PC_BOOT_HERE
echo "Waiting ${WAIT_TIME} seconds for PC (${MAIN_PC_IP}) to boot and shares to be available..." | systemd-cat -p info -t ${LOG_TAG}
sleep ${WAIT_TIME}

if ! ping -c 5 -W 3 "${MAIN_PC_IP}" &> /dev/null; then
  echo "Error: Main PC (${MAIN_PC_IP}) is not reachable after waiting. Aborting." | systemd-cat -p err -t ${LOG_TAG}
  exit 1
fi
echo "Main PC (${MAIN_PC_IP}) is online." | systemd-cat -p info -t ${LOG_TAG}

sudo mkdir -p "${MNT_PC_DRIVE_C}" "${MNT_PC_DRIVE_D}"

mount_share() {
    local share_path=$1
    local mount_point=$2
    echo "Attempting to mount ${share_path} to ${mount_point}..." | systemd-cat -p info -t ${LOG_TAG}
    sudo mount -t cifs "${share_path}" "${mount_point}" \
        -o credentials=${CREDENTIALS_FILE},vers=3.0,iocharset=utf8,uid=${PI_UID},gid=${PI_GID},nounix,noserverino,file_mode=0664,dir_mode=0775
    local mount_exit_code=$?
    if [ ${mount_exit_code} -ne 0 ]; then
        echo "Error: Failed to mount ${share_path} (Exit Code: ${mount_exit_code}). Check credentials and share permissions." | systemd-cat -p err -t ${LOG_TAG}
        sudo umount -l "${MNT_PC_DRIVE_C}" &> /dev/null
        sudo umount -l "${MNT_PC_DRIVE_D}" &> /dev/null
        return 1
    fi
    echo "${share_path} mounted successfully to ${mount_point}." | systemd-cat -p info -t ${LOG_TAG}
    return 0
}

unmount_share() {
    local mount_point=$1
    if mountpoint -q "${mount_point}"; then
        echo "Unmounting ${mount_point}..." | systemd-cat -p info -t ${LOG_TAG}
        sudo umount -l "${mount_point}"
        sleep 2
        if mountpoint -q "${mount_point}"; then
            echo "Warning: Failed to unmount ${mount_point}. It might still be busy." | systemd-cat -p warning -t ${LOG_TAG}
        else
            echo "${mount_point} unmounted." | systemd-cat -p info -t ${LOG_TAG}
        fi
    else
        echo "${mount_point} was not mounted or already unmounted." | systemd-cat -p info -t ${LOG_TAG}
    fi
}

mount_share "${PC_SHARE_C}" "${MNT_PC_DRIVE_C}" || exit 1
mount_share "${PC_SHARE_D}" "${MNT_PC_DRIVE_D}" || { unmount_share "${MNT_PC_DRIVE_C}"; exit 1; }

BACKUP_SUCCESSFUL=true

run_rsync() {
    local source_path="$1"
    local destination_path="$2"
    local task_name="$3"
    local exclude_file_path="$4"

    echo "Running rsync for ${task_name}: ${source_path} -> ${destination_path}" | systemd-cat -p info -t ${LOG_TAG}
    sudo mkdir -p "${destination_path}"

    local rsync_opts=(-avz --info=progress2 --stats --delete --no-i-r)

    if [ -n "${exclude_file_path}" ] && [ -f "${exclude_file_path}" ]; then
        rsync_opts+=(--exclude-from="${exclude_file_path}")
        echo "Using exclude file: ${exclude_file_path}" | systemd-cat -p info -t ${LOG_TAG}
    else
        echo "Warning: Exclude file '${exclude_file_path}' not specified or not found for ${task_name}. Using basic fallback excludes." | systemd-cat -p warning -t ${LOG_TAG}
        rsync_opts+=(
            --exclude='$RECYCLE.BIN/'
            --exclude='$Recycle.Bin/'
            --exclude='System Volume Information/'
            --exclude='pagefile.sys'
            --exclude='hiberfil.sys'
            --exclude='swapfile.sys'
            --exclude='Thumbs.db'
            --exclude='desktop.ini'
            --exclude='*.tmp'
        )
    fi

    rsync "${rsync_opts[@]}" "${source_path}" "${destination_path}"
    local rsync_exit_code=$?

    if [ ${rsync_exit_code} -ne 0 ]; then
        if [ ${rsync_exit_code} -eq 24 ]; then
            echo "Warning: rsync for ${task_name} completed with code 24 (some source files vanished). This might be okay for volatile data." | systemd-cat -p warning -t ${LOG_TAG}
        else
            echo "Error: rsync failed for ${task_name} (Exit Code: ${rsync_exit_code})." | systemd-cat -p err -t ${LOG_TAG}
            BACKUP_SUCCESSFUL=false
        fi
    else
        echo "rsync successful for ${task_name}." | systemd-cat -p info -t ${LOG_TAG}
    fi
}

echo "--- Starting Main Drive Backups ---" | systemd-cat -p info -t ${LOG_TAG}
run_rsync "${MNT_PC_DRIVE_C}/" "${NAS_C_DRIVE_BACKUP_DIR}" "Main Backup C -> LVM Pool" "${EXCLUDE_FILE_C}"
run_rsync "${MNT_PC_DRIVE_D}/" "${NAS_D_DRIVE_BACKUP_DIR}" "Main Backup D -> LVM Pool" "${EXCLUDE_FILE_D}"
echo "--- Finished Main Drive Backups ---" | systemd-cat -p info -t ${LOG_TAG}

backup_important_folder() {
    local source_drive_mount=$1
    local relative_folder_path=$2
    local nas_important_base_dir=$3
    local task_prefix=$4
    local exclude_file_for_important=$5

    if [ -z "${relative_folder_path}" ]; then return; fi

    local full_source_path="${source_drive_mount}/${relative_folder_path}"
    local full_destination_path="${nas_important_base_dir}/${relative_folder_path}"

    echo "Backing up ${task_prefix}/${relative_folder_path}: ${full_source_path}/ -> ${full_destination_path}/" | systemd-cat -p info -t ${LOG_TAG}

    sudo mkdir -p "${full_destination_path}"

    local rsync_opts_important=(-avz --info=progress2 --stats --delete --no-i-r)
    if [ -n "${exclude_file_for_important}" ] && [ -f "${exclude_file_for_important}" ]; then
        rsync_opts_important+=(--exclude-from="${exclude_file_for_important}")
        echo "Using exclude file for important backup: ${exclude_file_for_important}" | systemd-cat -p info -t ${LOG_TAG}
    else
        rsync_opts_important+=(
            --exclude='$RECYCLE.BIN/'
            --exclude='$Recycle.Bin/'
            --exclude='System Volume Information/'
            --exclude='Thumbs.db'
            --exclude='desktop.ini'
            --exclude='*.tmp'
            --exclude='*.bak'
            --exclude='*~'
        )
    fi
    
    rsync "${rsync_opts_important[@]}" "${full_source_path}/" "${full_destination_path}/"
    local rsync_exit_code=$?
    if [ ${rsync_exit_code} -ne 0 ]; then
        if [ ${rsync_exit_code} -eq 24 ]; then
             echo "Warning: rsync for ${task_prefix}/${relative_folder_path} completed with code 24 (vanished files)." | systemd-cat -p warning -t ${LOG_TAG}
        else
            echo "Error: rsync failed for ${task_prefix}/${relative_folder_path} (Exit Code: ${rsync_exit_code})." | systemd-cat -p err -t ${LOG_TAG}
            BACKUP_SUCCESSFUL=false
        fi
    else
        echo "rsync successful for ${task_prefix}/${relative_folder_path}." | systemd-cat -p info -t ${LOG_TAG}
    fi
}

echo "--- Starting Important File Backups ---" | systemd-cat -p info -t ${LOG_TAG}
IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME="YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_C_DRIVE_FILES_HERE"
IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME="YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_D_DRIVE_FILES_HERE"

for folder_path in "${IMPORTANT_FOLDERS_C[@]}"; do
    backup_important_folder "${MNT_PC_DRIVE_C}" "${folder_path}" "${NAS_IMPORTANT_DIR}/${IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME}" "Important: C" "${EXCLUDE_FILE_IMPORTANT}"
done
for folder_path in "${IMPORTANT_FOLDERS_D[@]}"; do
    backup_important_folder "${MNT_PC_DRIVE_D}" "${folder_path}" "${NAS_IMPORTANT_DIR}/${IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME}" "Important: D" "${EXCLUDE_FILE_IMPORTANT}"
done
echo "--- Finished Important File Backups ---" | systemd-cat -p info -t ${LOG_TAG}

unmount_share "${MNT_PC_DRIVE_C}"
unmount_share "${MNT_PC_DRIVE_D}"

WINDOWS_SHUTDOWN_TIMEOUT=YOUR_TIMEOUT_IN_SECONDS_FOR_WINDOWS_SHUTDOWN_COMMAND_HERE
WINDOWS_SHUTDOWN_MESSAGE="YOUR_CUSTOM_SHUTDOWN_MESSAGE_FOR_WINDOWS_PC_HERE_CAN_USE_VAR:\${WINDOWS_SHUTDOWN_TIMEOUT}"

echo "Backup phase complete. Proceeding to Windows PC shutdown." | systemd-cat -p info -t ${LOG_TAG}
if [ "$BACKUP_SUCCESSFUL" = true ]; then
  echo "All backup tasks reported success." | systemd-cat -p info -t ${LOG_TAG}
else
  echo "Warning: One or more backup tasks reported errors. Check logs. PC will still be shut down as requested." | systemd-cat -p warning -t ${LOG_TAG}
fi

echo "Sending shutdown command to ${MAIN_PC_IP} with a ${WINDOWS_SHUTDOWN_TIMEOUT}s timer and cancellation instructions..." | systemd-cat -p info -t ${LOG_TAG}

RPC_USER=""
RPC_PASS=""
if [ -f "${CREDENTIALS_FILE}" ]; then
    RPC_USER_LINE=$(grep -i '^username=' "${CREDENTIALS_FILE}")
    RPC_PASS_LINE=$(grep -i '^password=' "${CREDENTIALS_FILE}")
    if [[ -n "$RPC_USER_LINE" ]]; then RPC_USER=$(echo "$RPC_USER_LINE" | cut -d'=' -f2-); fi
    if [[ -n "$RPC_PASS_LINE" ]]; then RPC_PASS=$(echo "$RPC_PASS_LINE" | cut -d'=' -f2-); fi
fi

SHUTDOWN_CMD_ATTEMPTED=false
if [ -n "${RPC_USER}" ] && [ -n "${RPC_PASS}" ]; then
    echo "Using credentials from file for net rpc shutdown." | systemd-cat -p info -t ${LOG_TAG}
    net rpc shutdown -I "${MAIN_PC_IP}" -U "${RPC_USER}%${RPC_PASS}" -f -t "${WINDOWS_SHUTDOWN_TIMEOUT}" -C "${WINDOWS_SHUTDOWN_MESSAGE}"
    SHUTDOWN_EXIT_CODE=$?
    SHUTDOWN_CMD_ATTEMPTED=true
else
    echo "Warning: Could not parse full username/password from ${CREDENTIALS_FILE} (User: '${RPC_USER:-not set}', Pass: [hidden]). Attempting shutdown without explicit credentials." | systemd-cat -p warning -t ${LOG_TAG}
    echo "If shutdown fails, ensure 'net rpc' can authenticate (e.g., via smb.conf, Kerberos, or by manually setting -U user%pass in script)." | systemd-cat -p warning -t ${LOG_TAG}
    net rpc shutdown -I "${MAIN_PC_IP}" -f -t "${WINDOWS_SHUTDOWN_TIMEOUT}" -C "${WINDOWS_SHUTDOWN_MESSAGE}"
    SHUTDOWN_EXIT_CODE=$?
    SHUTDOWN_CMD_ATTEMPTED=true
fi

if [ "$SHUTDOWN_CMD_ATTEMPTED" = true ]; then
    if [ ${SHUTDOWN_EXIT_CODE} -eq 0 ]; then
        echo "Remote shutdown command sent successfully to ${MAIN_PC_IP}." | systemd-cat -p info -t ${LOG_TAG}
    else
        echo "Error: Failed sending remote shutdown command to ${MAIN_PC_IP} (Exit Code: ${SHUTDOWN_EXIT_CODE}). PC may not shut down." | systemd-cat -p warning -t ${LOG_TAG}
    fi
else
     echo "Critical Error: Could not attempt to send shutdown command due to missing credentials logic (this should not happen)." | systemd-cat -p err -t ${LOG_TAG}
fi

echo "Backup script finished at $(date)." | systemd-cat -p info -t ${LOG_TAG}

if [ "$BACKUP_SUCCESSFUL" = true ]; then
  exit 0
else
  echo "Exiting with status 1 due to backup task failures." | systemd-cat -p info -t ${LOG_TAG}
  exit 1
fi