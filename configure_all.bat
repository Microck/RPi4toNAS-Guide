@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Script Configuration Generator (Windows Batch Version)
::
:: This script provides a menu-driven interface to generate fully configured
:: shell scripts for a Linux environment. It interactively prompts the user
:: for necessary values, providing context and examples for each.
::
:: v9.0 - Final fix: Restored specific examples in prompts for all standard
::        variables. Created a special-case prompt ONLY for the one
::        variable with problematic special characters.
:: ============================================================================

:: --- Define Descriptions and Examples for all Placeholders ---
call :setup_placeholders

:: ============================================================================
:: Main Menu Loop
:: ============================================================================
:main_menu
cls
echo(
echo(
call :center_text "------------------------------------------------------------------"
call :center_text " "
call :center_text "Script Configuration Generator"
call :center_text " "
call :center_text "------------------------------------------------------------------"
call :center_text " "
call :center_text "Activation Methods:"
call :center_text " "
call :center_text "[1] Windows PC Backup Script     - WOL, Mount, rsync, Shutdown"
call :center_text "[2] Minecraft Server Download    - SSH, Compress, SCP, Cleanup"
call :center_text "[3] Minecraft Backup Rotation    - Check Size, Delete Oldest"
call :center_text " "
call :center_text "------------------------------------------------------------------"
call :center_text " "
call :center_text "[9] Help"
call :center_text "[0] Exit"
call :center_text " "
call :center_text "------------------------------------------------------------------"
echo(

choice /c 12390 /n /m "Choose a menu option using your keyboard [1,2,3,9,0] : "

if %errorlevel% == 5 goto :exit_script
if %errorlevel% == 4 (call :show_help & goto :main_menu)
if %errorlevel% == 3 (call :process_template_3 & goto :main_menu)
if %errorlevel% == 2 (call :process_template_2 & goto :main_menu)
if %errorlevel% == 1 (call :process_template_1 & goto :main_menu)

goto :main_menu


:: ============================================================================
:: Main Processing Subroutines for Each Template
:: ============================================================================

:process_template_1
cls
echo --- Generating: Windows PC Backup Script ---
echo(
set "output_filename=windows_backup.sh"
set /p "output_filename=Enter the desired output filename [%output_filename%]: "

:: Step 1: Gather all user input and store in variables
call :prompt_template_1

:: Step 2: Write the stored variables to the output file
(
    call :write_template_1
) > "%output_filename%"

echo(
echo Success! Configuration saved to %output_filename%
echo It is recommended to review the file before use.
pause
goto :eof

:process_template_2
cls
echo --- Generating: Minecraft Server Download Script ---
echo(
set "output_filename=minecraft_download.sh"
set /p "output_filename=Enter the desired output filename [%output_filename%]: "

:: Step 1: Gather input
call :prompt_template_2
:: Step 2: Write output
(
    call :write_template_2
) > "%output_filename%"

echo(
echo Success! Configuration saved to %output_filename%
echo It is recommended to review the file before use.
pause
goto :eof

:process_template_3
cls
echo --- Generating: Minecraft Backup Rotation Script ---
echo(
set "output_filename=minecraft_rotation.sh"
set /p "output_filename=Enter the desired output filename [%output_filename%]: "

:: Step 1: Gather input
call :prompt_template_3
:: Step 2: Write output
(
    call :write_template_3
) > "%output_filename%"

echo(
echo Success! Configuration saved to %output_filename%
echo It is recommended to review the file before use.
pause
goto :eof


:: ============================================================================
:: Helper Subroutines
:: ============================================================================

:prompt
set "placeholder=%~1"
set "var_name=%~2"
set "user_val="

echo(
echo --- Configuring: %var_name% ---
echo   !DESC_%placeholder%!
set /p "user_val=Enter value [Example: !EX_%placeholder%!]: "
if not defined user_val set "user_val=!EX_%placeholder%!"
goto :eof

:prompt_special_case
set "placeholder=%~1"
set "var_name=%~2"
set "user_val="

echo(
echo --- Configuring: %var_name% ---
echo   !DESC_%placeholder%!
set /p "user_val=Enter value [or press Enter to use the full example above]: "
if not defined user_val set "user_val=!EX_%placeholder%!"
goto :eof

:prompt_array
set "array_name=%~1"
set "array_items="
echo(
echo --- Configuring Array: %array_name% ---
echo   Enter one folder path per line. Paths are relative to the drive.
echo   Press ENTER on an empty line when you are finished.
echo(
echo   Example:
echo   Users/YourUser/Documents
echo   Users/YourUser/Downloads
echo(
:array_loop
set "item="
set /p "item=Enter path: "
if not defined item goto :array_done
set array_items=!array_items!    "^^!item^^!"^

"
goto :array_loop
:array_done
goto :eof

:center_text
set "text_to_center=%~1"
set "pad="
for /l %%i in (1, 1, 8) do set "pad=!pad! "
echo(%pad%%text_to_center%
goto :eof

:show_help
cls
echo ------------------------------------------------------------------
echo(
echo                               Help
echo(
echo ------------------------------------------------------------------
echo(
echo  This script generates configuration files (.sh) for a Linux-based
echo  backup system.
echo(
echo  1. Choose a script template from the main menu.
echo  2. You will be prompted for each configuration value.
echo  3. An explanation and an example value will be shown for each prompt.
echo  4. You can press ENTER to accept the default example value.
echo  5. For lists of folders (arrays), enter one item per line and press
echo     ENTER on a blank line to finish.
echo  6. The final, configured .sh file will be saved in the current
echo     directory, ready to be copied to your Linux server.
echo(
echo ------------------------------------------------------------------
echo(
pause
goto :eof

:exit_script
cls
echo Exiting.
exit /b


:: ############################################################################
:: #
:: #                  TEMPLATE AND PLACEHOLDER DEFINITIONS
:: #
:: ############################################################################

:setup_placeholders
    set "DESC_YOUR_MAIN_PC_MAC_ADDRESS_HERE=The MAC address of the Windows PC to wake up via Wake-on-LAN."
    set "EX_YOUR_MAIN_PC_MAC_ADDRESS_HERE=00:00:5E:00:53:22"
    set "DESC_YOUR_MAIN_PC_IP_ADDRESS_HERE=The static IP address of the Windows PC."
    set "EX_YOUR_MAIN_PC_IP_ADDRESS_HERE=192.168.1.16"
    set "DESC_YOUR_SAMBA_CREDENTIALS_FILE_PATH_HERE=Full path to the file on your Linux machine that stores the Windows username and password."
    set "EX_YOUR_SAMBA_CREDENTIALS_FILE_PATH_HERE=/etc/samba/credentials.mainpc"
    set "DESC_YOUR_PI_USERNAME_FOR_FILE_OWNERSHIP_HERE=The username on the Linux machine that will own the mounted Windows shares."
    set "EX_YOUR_PI_USERNAME_FOR_FILE_OWNERSHIP_HERE=microck"
    set "DESC_YOUR_MOUNT_POINT_FOR_PC_C_DRIVE_ON_PI_HERE=A directory on the Linux machine where the Windows C: drive will be temporarily mounted."
    set "EX_YOUR_MOUNT_POINT_FOR_PC_C_DRIVE_ON_PI_HERE=/mnt/pc_c"
    set "DESC_YOUR_MOUNT_POINT_FOR_PC_D_DRIVE_ON_PI_HERE=A directory on the Linux machine where the Windows D: drive will be temporarily mounted."
    set "EX_YOUR_MOUNT_POINT_FOR_PC_D_DRIVE_ON_PI_HERE=/mnt/pc_d"
    set "DESC_YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE=The base path where your NAS storage is mounted."
    set "EX_YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE=/srv/dev-disk-by-uuid-33149383-18c3-4183-a35b-037e5853c221"
    set "DESC_YOUR_C_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE=The name of the subdirectory on your NAS for the C: drive backup."
    set "EX_YOUR_C_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE=MainBackup_C"
    set "DESC_YOUR_D_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE=The name of the subdirectory on your NAS for the D: drive backup."
    set "EX_YOUR_D_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE=MainBackup_D"
    set "DESC_YOUR_IMPORTANT_FILES_BACKUP_BASE_SUBDIRECTORY_NAME_HERE=The name of the base subdirectory on your NAS for important files."
    set "EX_YOUR_IMPORTANT_FILES_BACKUP_BASE_SUBDIRECTORY_NAME_HERE=ImportantBackup"
    set "DESC_YOUR_WINDOWS_C_DRIVE_ADMIN_SHARE_NAME_HERE=The administrative share name for the C: drive on Windows (usually 'c$')."
    set "EX_YOUR_WINDOWS_C_DRIVE_ADMIN_SHARE_NAME_HERE=c$"
    set "DESC_YOUR_WINDOWS_D_DRIVE_ADMIN_SHARE_NAME_HERE=The administrative share name for the D: drive on Windows (usually 'd$')."
    set "EX_YOUR_WINDOWS_D_DRIVE_ADMIN_SHARE_NAME_HERE=d$"
    set "DESC_YOUR_CUSTOM_SYSTEMD_LOG_TAG_HERE=A short tag for identifying these backup logs in systemd/journalctl."
    set "EX_YOUR_CUSTOM_SYSTEMD_LOG_TAG_HERE=win_backup_script"
    set "DESC_YOUR_NUMBER_OF_SECONDS_TO_WAIT_FOR_PC_BOOT_HERE=How many seconds to wait for the PC to boot after sending the Wake-on-LAN packet."
    set "EX_YOUR_NUMBER_OF_SECONDS_TO_WAIT_FOR_PC_BOOT_HERE=150"
    set "DESC_YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_C_DRIVE_FILES_HERE=A subdirectory inside the 'Important' backup folder to store files from C:."
    set "EX_YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_C_DRIVE_FILES_HERE=From_C_Drive"
    set "DESC_YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_D_DRIVE_FILES_HERE=A subdirectory inside the 'Important' backup folder to store files from D:."
    set "EX_YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_D_DRIVE_FILES_HERE=From_D_Drive"
    set "DESC_YOUR_TIMEOUT_IN_SECONDS_FOR_WINDOWS_SHUTDOWN_COMMAND_HERE=The countdown timer (in seconds) for the remote shutdown command sent to the Windows PC."
    set "EX_YOUR_TIMEOUT_IN_SECONDS_FOR_WINDOWS_SHUTDOWN_COMMAND_HERE=60"
    set "DESC_YOUR_CUSTOM_SHUTDOWN_MESSAGE_FOR_WINDOWS_PC_HERE_CAN_USE_VAR:^${WINDOWS_SHUTDOWN_TIMEOUT^}=The message displayed on the Windows PC during the shutdown countdown. Example: Automated backup finished. PC will shut down in ${WINDOWS_SHUTDOWN_TIMEOUT} seconds."
    set "EX_YOUR_CUSTOM_SHUTDOWN_MESSAGE_FOR_WINDOWS_PC_HERE_CAN_USE_VAR:^${WINDOWS_SHUTDOWN_TIMEOUT^}=Automated backup finished. PC will shut down in ${WINDOWS_SHUTDOWN_TIMEOUT} seconds. To cancel, type 'shutdown /a' in CMD."
    set "DESC_YOUR_ORACLE_SERVER_USERNAME_HERE=The SSH username for your Oracle Cloud server."
    set "EX_YOUR_ORACLE_SERVER_USERNAME_HERE=opc"
    set "DESC_YOUR_ORACLE_SERVER_IP_ADDRESS_HERE=The public IP address of your Oracle Cloud server."
    set "EX_YOUR_ORACLE_SERVER_IP_ADDRESS_HERE=129.146.155.10"
    set "DESC_YOUR_MINECRAFT_WORLD_DIRECTORY_ON_ORACLE_SERVER_HERE=Full path to the Minecraft world directory on the Oracle server."
    set "EX_YOUR_MINECRAFT_WORLD_DIRECTORY_ON_ORACLE_SERVER_HERE=/home/opc/minecraft"
    set "DESC_YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_ON_NAS_HERE=The name of the subdirectory on your NAS for Minecraft backups."
    set "EX_YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_ON_NAS_HERE=MinecraftBackups"
    set "DESC_YOUR_TEMPORARY_ARCHIVE_DIRECTORY_ON_ORACLE_SERVER_HERE=A temporary directory on the Oracle server to store the archive before download."
    set "EX_YOUR_TEMPORARY_ARCHIVE_DIRECTORY_ON_ORACLE_SERVER_HERE=/tmp/"
    set "DESC_YOUR_SSH_PRIVATE_KEY_FILE_PATH_FOR_ORACLE_ACCESS_HERE=Full path to the SSH private key used to access the Oracle server."
    set "EX_YOUR_SSH_PRIVATE_KEY_FILE_PATH_FOR_ORACLE_ACCESS_HERE=/root/.ssh/oracle_cloud_backup_key"
    set "DESC_YOUR_MINECRAFT_DOWNLOAD_LOG_TAG_HERE=A short tag for identifying Minecraft download logs in systemd/journalctl."
    set "EX_YOUR_MINECRAFT_DOWNLOAD_LOG_TAG_HERE=minecraft_download"
    set "DESC_YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_FOR_ROTATION_HERE=The name of the subdirectory on your NAS where Minecraft backups are stored (must match the download script)."
    set "EX_YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_FOR_ROTATION_HERE=MinecraftBackups"
    set "DESC_YOUR_MAX_TOTAL_BACKUP_SIZE_IN_GIB_HERE=The maximum total size (in GiB) the Minecraft backup folder should reach before old backups are deleted."
    set "EX_YOUR_MAX_TOTAL_BACKUP_SIZE_IN_GIB_HERE=295"
    set "DESC_YOUR_MINECRAFT_ROTATION_LOG_TAG_HERE=A short tag for identifying Minecraft rotation logs in systemd/journalctl."
    set "EX_YOUR_MINECRAFT_ROTATION_LOG_TAG_HERE=minecraft_rotation_script"
goto :eof

:: ############################################################################
:: #
:: #                  PROMPT AND WRITE SUBROUTINES
:: #
:: ############################################################################

:: --- Template 1: Windows PC Backup Script ---
:prompt_template_1
set "array_items="
call :prompt "YOUR_MAIN_PC_MAC_ADDRESS_HERE" "MAIN_PC_MAC"
set MAIN_PC_MAC=!user_val!
call :prompt "YOUR_MAIN_PC_IP_ADDRESS_HERE" "MAIN_PC_IP"
set MAIN_PC_IP=!user_val!
call :prompt "YOUR_SAMBA_CREDENTIALS_FILE_PATH_HERE" "CREDENTIALS_FILE"
set CREDENTIALS_FILE=!user_val!
call :prompt "YOUR_PI_USERNAME_FOR_FILE_OWNERSHIP_HERE" "PI_USERNAME"
set PI_USERNAME=!user_val!
call :prompt "YOUR_MOUNT_POINT_FOR_PC_C_DRIVE_ON_PI_HERE" "MNT_PC_DRIVE_C"
set MNT_PC_DRIVE_C=!user_val!
call :prompt "YOUR_MOUNT_POINT_FOR_PC_D_DRIVE_ON_PI_HERE" "MNT_PC_DRIVE_D"
set MNT_PC_DRIVE_D=!user_val!
call :prompt "YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE" "LVM_MOUNT_BASE"
set LVM_MOUNT_BASE=!user_val!
call :prompt "YOUR_C_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE" "C_DRIVE_BACKUP_SUBDIR_NAME"
set C_DRIVE_BACKUP_SUBDIR_NAME=!user_val!
call :prompt "YOUR_D_DRIVE_BACKUP_SUBDIRECTORY_NAME_HERE" "D_DRIVE_BACKUP_SUBDIR_NAME"
set D_DRIVE_BACKUP_SUBDIR_NAME=!user_val!
call :prompt "YOUR_IMPORTANT_FILES_BACKUP_BASE_SUBDIRECTORY_NAME_HERE" "IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME"
set IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME=!user_val!
call :prompt "YOUR_WINDOWS_C_DRIVE_ADMIN_SHARE_NAME_HERE" "WINDOWS_C_DRIVE_SHARE_NAME"
set WINDOWS_C_DRIVE_SHARE_NAME=!user_val!
call :prompt "YOUR_WINDOWS_D_DRIVE_ADMIN_SHARE_NAME_HERE" "WINDOWS_D_DRIVE_SHARE_NAME"
set WINDOWS_D_DRIVE_SHARE_NAME=!user_val!
call :prompt_array "IMPORTANT_FOLDERS_C"
set IMPORTANT_FOLDERS_C=!array_items!
call :prompt_array "IMPORTANT_FOLDERS_D"
set IMPORTANT_FOLDERS_D=!array_items!
call :prompt "YOUR_CUSTOM_SYSTEMD_LOG_TAG_HERE" "LOG_TAG"
set LOG_TAG=!user_val!
call :prompt "YOUR_NUMBER_OF_SECONDS_TO_WAIT_FOR_PC_BOOT_HERE" "WAIT_TIME"
set WAIT_TIME=!user_val!
call :prompt "YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_C_DRIVE_FILES_HERE" "IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME"
set IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME=!user_val!
call :prompt "YOUR_TARGET_SUBDIR_NAME_IN_IMPORTANT_BACKUP_FOR_D_DRIVE_FILES_HERE" "IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME"
set IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME=!user_val!
call :prompt "YOUR_TIMEOUT_IN_SECONDS_FOR_WINDOWS_SHUTDOWN_COMMAND_HERE" "WINDOWS_SHUTDOWN_TIMEOUT"
set WINDOWS_SHUTDOWN_TIMEOUT=!user_val!
call :prompt_special_case "YOUR_CUSTOM_SHUTDOWN_MESSAGE_FOR_WINDOWS_PC_HERE_CAN_USE_VAR:^${WINDOWS_SHUTDOWN_TIMEOUT^}" "WINDOWS_SHUTDOWN_MESSAGE"
set WINDOWS_SHUTDOWN_MESSAGE=!user_val!
goto :eof

:write_template_1
echo #!/bin/bash
echo(
echo MAIN_PC_MAC="%MAIN_PC_MAC%"
echo MAIN_PC_IP="%MAIN_PC_IP%"
echo CREDENTIALS_FILE="%CREDENTIALS_FILE%"
echo PI_USERNAME="%PI_USERNAME%"
echo(
echo MNT_PC_DRIVE_C="%MNT_PC_DRIVE_C%"
echo MNT_PC_DRIVE_D="%MNT_PC_DRIVE_D%"
echo(
echo LVM_MOUNT_BASE="%LVM_MOUNT_BASE%"
echo(
echo C_DRIVE_BACKUP_SUBDIR_NAME="%C_DRIVE_BACKUP_SUBDIR_NAME%"
echo D_DRIVE_BACKUP_SUBDIR_NAME="%D_DRIVE_BACKUP_SUBDIR_NAME%"
echo IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME="%IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME%"
echo(
echo NAS_C_DRIVE_BACKUP_DIR="${LVM_MOUNT_BASE}/${C_DRIVE_BACKUP_SUBDIR_NAME}/"
echo NAS_D_DRIVE_BACKUP_DIR="${LVM_MOUNT_BASE}/${D_DRIVE_BACKUP_SUBDIR_NAME}/"
echo NAS_IMPORTANT_DIR="${LVM_MOUNT_BASE}/${IMPORTANT_FILES_BACKUP_BASE_SUBDIR_NAME}/"
echo(
echo WINDOWS_C_DRIVE_SHARE_NAME="%WINDOWS_C_DRIVE_SHARE_NAME%"
echo WINDOWS_D_DRIVE_SHARE_NAME="%WINDOWS_D_DRIVE_SHARE_NAME%"
echo(
echo PC_SHARE_C="//${MAIN_PC_IP}/${WINDOWS_C_DRIVE_SHARE_NAME}"
echo PC_SHARE_D="//${MAIN_PC_IP}/${WINDOWS_D_DRIVE_SHARE_NAME}"
echo(
echo EXCLUDE_FILE_C="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_C_DRIVE_HERE"
echo EXCLUDE_FILE_D="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_D_DRIVE_HERE"
echo EXCLUDE_FILE_IMPORTANT="YOUR_PATH_TO_RSYNC_EXCLUDE_FILE_FOR_IMPORTANT_FILES_HERE"
echo(
echo IMPORTANT_FOLDERS_C=(
echo %IMPORTANT_FOLDERS_C%
echo )
echo(
echo IMPORTANT_FOLDERS_D=(
echo %IMPORTANT_FOLDERS_D%
echo )
echo(
echo LOG_TAG="%LOG_TAG%"
echo echo "Starting backup process at $(date)" ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo PI_UID=$(id -u "${PI_USERNAME}")
echo PI_GID=$(id -g "${PI_USERNAME}")
echo if [ -z "${PI_UID}" ] ^|^| [ -z "${PI_GID}" ]; then
echo     echo "Error: User '${PI_USERNAME}' not found on this system. Please set PI_USERNAME correctly." ^| systemd-cat -p err -t ${LOG_TAG}
echo     exit 1
echo fi
echo(
echo echo "Sending WOL packet to ${MAIN_PC_MAC}..." ^| systemd-cat -p info -t ${LOG_TAG}
echo if ! /usr/bin/wakeonlan "${MAIN_PC_MAC}"; then
echo     echo "wakeonlan failed, trying etherwake..." ^| systemd-cat -p warning -t ${LOG_TAG}
echo     if ! /usr/sbin/etherwake "${MAIN_PC_MAC}"; then
echo         echo "Error: Both wakeonlan and etherwake failed to send WOL packet." ^| systemd-cat -p err -t ${LOG_TAG}
echo     fi
echo fi
echo(
echo WAIT_TIME=%WAIT_TIME%
echo echo "Waiting ${WAIT_TIME} seconds for PC (${MAIN_PC_IP}) to boot and shares to be available..." ^| systemd-cat -p info -t ${LOG_TAG}
echo sleep ${WAIT_TIME}
echo(
echo if ! ping -c 5 -W 3 "${MAIN_PC_IP}" ^&^> /dev/null; then
echo   echo "Error: Main PC (${MAIN_PC_IP}) is not reachable after waiting. Aborting." ^| systemd-cat -p err -t ${LOG_TAG}
echo   exit 1
echo fi
echo echo "Main PC (${MAIN_PC_IP}) is online." ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo sudo mkdir -p "${MNT_PC_DRIVE_C}" "${MNT_PC_DRIVE_D}"
echo(
echo mount_share() {
echo     local share_path=$1
echo     local mount_point=$2
echo     echo "Attempting to mount ${share_path} to ${mount_point}..." ^| systemd-cat -p info -t ${LOG_TAG}
echo     sudo mount -t cifs "${share_path}" "${mount_point}" \
echo         -o credentials=${CREDENTIALS_FILE},vers=3.0,iocharset=utf8,uid=${PI_UID},gid=${PI_GID},nounix,noserverino,file_mode=0664,dir_mode=0775
echo     local mount_exit_code=$?
echo     if [ ${mount_exit_code} -ne 0 ]; then
echo         echo "Error: Failed to mount ${share_path} (Exit Code: ${mount_exit_code}). Check credentials and share permissions." ^| systemd-cat -p err -t ${LOG_TAG}
echo         sudo umount -l "${MNT_PC_DRIVE_C}" ^&^> /dev/null
echo         sudo umount -l "${MNT_PC_DRIVE_D}" ^&^> /dev/null
echo         return 1
echo     fi
echo     echo "${share_path} mounted successfully to ${mount_point}." ^| systemd-cat -p info -t ${LOG_TAG}
echo     return 0
echo }
echo(
echo unmount_share() {
echo     local mount_point=$1
echo     if mountpoint -q "${mount_point}"; then
echo         echo "Unmounting ${mount_point}..." ^| systemd-cat -p info -t ${LOG_TAG}
echo         sudo umount -l "${mount_point}"
echo         sleep 2
echo         if mountpoint -q "${mount_point}"; then
echo             echo "Warning: Failed to unmount ${mount_point}. It might still be busy." ^| systemd-cat -p warning -t ${LOG_TAG}
echo         else
echo             echo "${mount_point} unmounted." ^| systemd-cat -p info -t ${LOG_TAG}
echo         fi
echo     else
echo         echo "${mount_point} was not mounted or already unmounted." ^| systemd-cat -p info -t ${LOG_TAG}
echo     fi
echo }
echo(
echo mount_share "${PC_SHARE_C}" "${MNT_PC_DRIVE_C}" ^|^| exit 1
echo mount_share "${PC_SHARE_D}" "${MNT_PC_DRIVE_D}" ^|^| { unmount_share "${MNT_PC_DRIVE_C}"; exit 1; }
echo(
echo BACKUP_SUCCESSFUL=true
echo(
echo run_rsync() {
echo     local source_path="$1"
echo     local destination_path="$2"
echo     local task_name="$3"
echo     local exclude_file_path="$4"
echo(
echo     echo "Running rsync for ${task_name}: ${source_path} -> ${destination_path}" ^| systemd-cat -p info -t ${LOG_TAG}
echo     sudo mkdir -p "${destination_path}"
echo(
echo     local rsync_opts=(-avz --info=progress2 --stats --delete --no-i-r)
echo(
echo     if [ -n "${exclude_file_path}" ] ^&^& [ -f "${exclude_file_path}" ]; then
echo         rsync_opts+=(--exclude-from="${exclude_file_path}")
echo         echo "Using exclude file: ${exclude_file_path}" ^| systemd-cat -p info -t ${LOG_TAG}
echo     else
echo         echo "Warning: Exclude file '${exclude_file_path}' not specified or not found for ${task_name}. Using basic fallback excludes." ^| systemd-cat -p warning -t ${LOG_TAG}
echo         rsync_opts+=(
echo             --exclude='$RECYCLE.BIN/'
echo             --exclude='$Recycle.Bin/'
echo             --exclude='System Volume Information/'
echo             --exclude='pagefile.sys'
echo             --exclude='hiberfil.sys'
echo             --exclude='swapfile.sys'
echo             --exclude='Thumbs.db'
echo             --exclude='desktop.ini'
echo             --exclude='*.tmp'
echo         )
echo     fi
echo(
echo     rsync "${rsync_opts[@]}" "${source_path}" "${destination_path}"
echo     local rsync_exit_code=$?
echo(
echo     if [ ${rsync_exit_code} -ne 0 ]; then
echo         if [ ${rsync_exit_code} -eq 24 ]; then
echo             echo "Warning: rsync for ${task_name} completed with code 24 (some source files vanished). This might be okay for volatile data." ^| systemd-cat -p warning -t ${LOG_TAG}
echo         else
echo             echo "Error: rsync failed for ${task_name} (Exit Code: ${rsync_exit_code})." ^| systemd-cat -p err -t ${LOG_TAG}
echo             BACKUP_SUCCESSFUL=false
echo         fi
echo     else
echo         echo "rsync successful for ${task_name}." ^| systemd-cat -p info -t ${LOG_TAG}
echo     fi
echo }
echo(
echo echo "--- Starting Main Drive Backups ---" ^| systemd-cat -p info -t ${LOG_TAG}
echo run_rsync "${MNT_PC_DRIVE_C}/" "${NAS_C_DRIVE_BACKUP_DIR}" "Main Backup C -> LVM Pool" "${EXCLUDE_FILE_C}"
echo run_rsync "${MNT_PC_DRIVE_D}/" "${NAS_D_DRIVE_BACKUP_DIR}" "Main Backup D -> LVM Pool" "${EXCLUDE_FILE_D}"
echo echo "--- Finished Main Drive Backups ---" ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo backup_important_folder() {
echo     local source_drive_mount=$1
echo     local relative_folder_path=$2
echo     local nas_important_base_dir=$3
echo     local task_prefix=$4
echo     local exclude_file_for_important=$5
echo(
echo     if [ -z "${relative_folder_path}" ]; then return; fi
echo(
echo     local full_source_path="${source_drive_mount}/${relative_folder_path}"
echo     local full_destination_path="${nas_important_base_dir}/${relative_folder_path}"
echo(
echo     echo "Backing up ${task_prefix}/${relative_folder_path}: ${full_source_path}/ -> ${full_destination_path}/" ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo     sudo mkdir -p "${full_destination_path}"
echo(
echo     local rsync_opts_important=(-avz --info=progress2 --stats --delete --no-i-r)
echo     if [ -n "${exclude_file_for_important}" ] ^&^& [ -f "${exclude_file_for_important}" ]; then
echo         rsync_opts_important+=(--exclude-from="${exclude_file_for_important}")
echo         echo "Using exclude file for important backup: ${exclude_file_for_important}" ^| systemd-cat -p info -t ${LOG_TAG}
echo     else
echo         rsync_opts_important+=(
echo             --exclude='$RECYCLE.BIN/'
echo             --exclude='$Recycle.Bin/'
echo             --exclude='System Volume Information/'
echo             --exclude='Thumbs.db'
echo             --exclude='desktop.ini'
echo             --exclude='*.tmp'
echo             --exclude='*.bak'
echo             --exclude='*~'
echo         )
echo     fi
echo     
echo     rsync "${rsync_opts_important[@]}" "${full_source_path}/" "${full_destination_path}/"
echo     local rsync_exit_code=$?
echo     if [ ${rsync_exit_code} -ne 0 ]; then
echo         if [ ${rsync_exit_code} -eq 24 ]; then
echo              echo "Warning: rsync for ${task_prefix}/${relative_folder_path} completed with code 24 (vanished files)." ^| systemd-cat -p warning -t ${LOG_TAG}
echo         else
echo             echo "Error: rsync failed for ${task_prefix}/${relative_folder_path} (Exit Code: ${rsync_exit_code})." ^| systemd-cat -p err -t ${LOG_TAG}
echo             BACKUP_SUCCESSFUL=false
echo         fi
echo     else
echo         echo "rsync successful for ${task_prefix}/${relative_folder_path}." ^| systemd-cat -p info -t ${LOG_TAG}
echo     fi
echo }
echo(
echo echo "--- Starting Important File Backups ---" ^| systemd-cat -p info -t ${LOG_TAG}
echo IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME="%IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME%"
echo IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME="%IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME%"
echo(
echo for folder_path in "${IMPORTANT_FOLDERS_C[@]}"; do
echo     backup_important_folder "${MNT_PC_DRIVE_C}" "${folder_path}" "${NAS_IMPORTANT_DIR}/${IMPORTANT_BACKUP_C_TARGET_SUBDIR_NAME}" "Important: C" "${EXCLUDE_FILE_IMPORTANT}"
echo done
echo for folder_path in "${IMPORTANT_FOLDERS_D[@]}"; do
echo     backup_important_folder "${MNT_PC_DRIVE_D}" "${folder_path}" "${NAS_IMPORTANT_DIR}/${IMPORTANT_BACKUP_D_TARGET_SUBDIR_NAME}" "Important: D" "${EXCLUDE_FILE_IMPORTANT}"
echo done
echo echo "--- Finished Important File Backups ---" ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo unmount_share "${MNT_PC_DRIVE_C}"
echo unmount_share "${MNT_PC_DRIVE_D}"
echo(
echo WINDOWS_SHUTDOWN_TIMEOUT=%WINDOWS_SHUTDOWN_TIMEOUT%
echo WINDOWS_SHUTDOWN_MESSAGE="%WINDOWS_SHUTDOWN_MESSAGE%"
echo(
echo echo "Backup phase complete. Proceeding to Windows PC shutdown." ^| systemd-cat -p info -t ${LOG_TAG}
echo if [ "$BACKUP_SUCCESSFUL" = true ]; then
echo   echo "All backup tasks reported success." ^| systemd-cat -p info -t ${LOG_TAG}
echo else
echo   echo "Warning: One or more backup tasks reported errors. Check logs. PC will still be shut down as requested." ^| systemd-cat -p warning -t ${LOG_TAG}
echo fi
echo(
echo echo "Sending shutdown command to ${MAIN_PC_IP} with a ${WINDOWS_SHUTDOWN_TIMEOUT}s timer and cancellation instructions..." ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo RPC_USER=""
echo RPC_PASS=""
echo if [ -f "${CREDENTIALS_FILE}" ]; then
echo     RPC_USER_LINE=$(grep -i '^username=' "${CREDENTIALS_FILE}")
echo     RPC_PASS_LINE=$(grep -i '^password=' "${CREDENTIALS_FILE}")
echo     if [[ -n "$RPC_USER_LINE" ]]; then RPC_USER=$(echo "$RPC_USER_LINE" ^| cut -d'=' -f2-); fi
echo     if [[ -n "$RPC_PASS_LINE" ]]; then RPC_PASS=$(echo "$RPC_PASS_LINE" ^| cut -d'=' -f2-); fi
echo fi
echo(
echo SHUTDOWN_CMD_ATTEMPTED=false
echo if [ -n "${RPC_USER}" ] ^&^& [ -n "${RPC_PASS}" ]; then
echo     echo "Using credentials from file for net rpc shutdown." ^| systemd-cat -p info -t ${LOG_TAG}
echo     net rpc shutdown -I "${MAIN_PC_IP}" -U "${RPC_USER}%%${RPC_PASS}" -f -t "${WINDOWS_SHUTDOWN_TIMEOUT}" -C "${WINDOWS_SHUTDOWN_MESSAGE}"
echo     SHUTDOWN_EXIT_CODE=$?
echo     SHUTDOWN_CMD_ATTEMPTED=true
echo else
echo     echo "Warning: Could not parse full username/password from ${CREDENTIALS_FILE} (User: '${RPC_USER:-not set}', Pass: [hidden]). Attempting shutdown without explicit credentials." ^| systemd-cat -p warning -t ${LOG_TAG}
echo     echo "If shutdown fails, ensure 'net rpc' can authenticate (e.g., via smb.conf, Kerberos, or by manually setting -U user%%pass in script)." ^| systemd-cat -p warning -t ${LOG_TAG}
echo     net rpc shutdown -I "${MAIN_PC_IP}" -f -t "${WINDOWS_SHUTDOWN_TIMEOUT}" -C "${WINDOWS_SHUTDOWN_MESSAGE}"
echo     SHUTDOWN_EXIT_CODE=$?
echo     SHUTDOWN_CMD_ATTEMPTED=true
echo fi
echo(
echo if [ "$SHUTDOWN_CMD_ATTEMPTED" = true ]; then
echo     if [ ${SHUTDOWN_EXIT_CODE} -eq 0 ]; then
echo         echo "Remote shutdown command sent successfully to ${MAIN_PC_IP}." ^| systemd-cat -p info -t ${LOG_TAG}
echo     else
echo         echo "Error: Failed sending remote shutdown command to ${MAIN_PC_IP} (Exit Code: ${SHUTDOWN_EXIT_CODE}). PC may not shut down." ^| systemd-cat -p warning -t ${LOG_TAG}
echo     fi
echo else
echo      echo "Critical Error: Could not attempt to send shutdown command due to missing credentials logic (this should not happen)." ^| systemd-cat -p err -t ${LOG_TAG}
echo fi
echo(
echo echo "Backup script finished at $(date)." ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo if [ "$BACKUP_SUCCESSFUL" = true ]; then
echo   exit 0
echo else
echo   echo "Exiting with status 1 due to backup task failures." ^| systemd-cat -p info -t ${LOG_TAG}
echo   exit 1
echo fi
goto :eof

:: --- Template 2: Minecraft Server Download Script ---
:prompt_template_2
set "array_items="
call :prompt "YOUR_ORACLE_SERVER_USERNAME_HERE" "ORACLE_USER"
set ORACLE_USER=!user_val!
call :prompt "YOUR_ORACLE_SERVER_IP_ADDRESS_HERE" "ORACLE_IP"
set ORACLE_IP=!user_val!
call :prompt "YOUR_MINECRAFT_WORLD_DIRECTORY_ON_ORACLE_SERVER_HERE" "ORACLE_MC_WORLD_DIR"
set ORACLE_MC_WORLD_DIR=!user_val!
call :prompt "YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE" "LVM_MOUNT_BASE"
set LVM_MOUNT_BASE=!user_val!
call :prompt "YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_ON_NAS_HERE" "MINECRAFT_BACKUPS_SUBDIR_NAME"
set MINECRAFT_BACKUPS_SUBDIR_NAME=!user_val!
call :prompt "YOUR_TEMPORARY_ARCHIVE_DIRECTORY_ON_ORACLE_SERVER_HERE" "ORACLE_TEMP_ARCHIVE_PATH"
set ORACLE_TEMP_ARCHIVE_PATH=!user_val!
call :prompt "YOUR_SSH_PRIVATE_KEY_FILE_PATH_FOR_ORACLE_ACCESS_HERE" "SSH_KEY_PATH"
set SSH_KEY_PATH=!user_val!
call :prompt "YOUR_MINECRAFT_DOWNLOAD_LOG_TAG_HERE" "LOG_TAG"
set LOG_TAG=!user_val!
goto :eof

:write_template_2
echo #!/bin/bash
echo(
echo ORACLE_USER="%ORACLE_USER%"
echo ORACLE_IP="%ORACLE_IP%"
echo ORACLE_MC_WORLD_DIR="%ORACLE_MC_WORLD_DIR%"
echo(
echo LVM_MOUNT_BASE="%LVM_MOUNT_BASE%"
echo MINECRAFT_BACKUPS_SUBDIR_NAME="%MINECRAFT_BACKUPS_SUBDIR_NAME%"
echo NAS_BACKUP_DIR="${LVM_MOUNT_BASE}/${MINECRAFT_BACKUPS_SUBDIR_NAME}/"
echo(
echo ORACLE_TEMP_ARCHIVE_PATH="%ORACLE_TEMP_ARCHIVE_PATH%"
echo SSH_KEY_PATH="%SSH_KEY_PATH%"
echo SSH_OPTIONS="-i ${SSH_KEY_PATH}"
echo(
echo LOG_TAG="%LOG_TAG%"
echo echo "Starting Minecraft backup download process at $(date)" ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo mkdir -p "${NAS_BACKUP_DIR}"
echo if [ ! -d "${NAS_BACKUP_DIR}" ]; then
echo   echo "Error: NAS backup directory ${NAS_BACKUP_DIR} does not exist or could not be created." ^| systemd-cat -p err -t "${LOG_TAG}"
echo   exit 1
echo fi
echo echo "NAS backup directory confirmed: ${NAS_BACKUP_DIR}" ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo TIMESTAMP=$(date +'%%Y-%%m-%%d_%%H-%%M-%%S')
echo ARCHIVE_FILENAME="world_${TIMESTAMP}.tar.gz"
echo REMOTE_ARCHIVE_FULL_PATH="${ORACLE_TEMP_ARCHIVE_PATH}${ARCHIVE_FILENAME}"
echo(
echo ORACLE_MC_PARENT_DIR=$(dirname "${ORACLE_MC_WORLD_DIR}")
echo ORACLE_MC_WORLD_NAME=$(basename "${ORACLE_MC_WORLD_DIR}")
echo(
echo echo "Connecting to ${ORACLE_IP} as ${ORACLE_USER} to compress '${ORACLE_MC_WORLD_DIR}' into '${REMOTE_ARCHIVE_FULL_PATH}'..." ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo TAR_COMMAND="tar -czf \"${REMOTE_ARCHIVE_FULL_PATH}\" -C \"${ORACLE_MC_PARENT_DIR}\" \"${ORACLE_MC_WORLD_NAME}\" 2^>^&1; echo \"TAR_EXIT_CODE:\$?\""
echo TAR_OUTPUT_AND_ERROR=$(ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "${TAR_COMMAND}")
echo SSH_CMD_EXIT_CODE=$?
echo(
echo echo "Output from remote tar command (includes stderr and TAR_EXIT_CODE line):" ^| systemd-cat -p info -t "${LOG_TAG}"
echo echo "${TAR_OUTPUT_AND_ERROR}" ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo ACTUAL_TAR_EXIT_CODE_LINE=$(echo "${TAR_OUTPUT_AND_ERROR}" ^| grep 'TAR_EXIT_CODE:')
echo if [ -n "${ACTUAL_TAR_EXIT_CODE_LINE}" ]; then
echo     ACTUAL_TAR_EXIT_CODE=$(echo "${ACTUAL_TAR_EXIT_CODE_LINE}" ^| cut -d':' -f2)
echo else
echo     ACTUAL_TAR_EXIT_CODE="UNKNOWN"
echo fi
echo(
echo if [ "${SSH_CMD_EXIT_CODE}" -ne 0 ] ^|^| [ "${ACTUAL_TAR_EXIT_CODE}" = "UNKNOWN" ] ^|^| [ "${ACTUAL_TAR_EXIT_CODE}" -ne 0 ]; then
echo   echo "Error: Failed to create archive on Oracle server." ^| systemd-cat -p err -t "${LOG_TAG}"
echo   echo "SSH command exit code: ${SSH_CMD_EXIT_CODE}." ^| systemd-cat -p err -t "${LOG_TAG}"
echo   echo "Actual tar exit code on remote server: ${ACTUAL_TAR_EXIT_CODE}." ^| systemd-cat -p err -t "${LOG_TAG}"
echo   echo "Checking if archive '${REMOTE_ARCHIVE_FULL_PATH}' somehow exists on Oracle server despite error..." ^| systemd-cat -p info -t "${LOG_TAG}"
echo   ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${REMOTE_ARCHIVE_FULL_PATH}\"" 2^>^&1 ^| systemd-cat -p info -t "${LOG_TAG}"
echo   exit 1
echo fi
echo(
echo echo "Archive created successfully on Oracle server: ${REMOTE_ARCHIVE_FULL_PATH}" ^| systemd-cat -p info -t "${LOG_TAG}"
echo echo "(Note: 'tar: file changed as we read it' is a non-fatal warning if server was running and tar exit code was 1 but archive was created)" ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo echo "Verifying remote archive existence and readability: ${REMOTE_ARCHIVE_FULL_PATH}" ^| systemd-cat -p info -t "${LOG_TAG}"
echo REMOTE_FILE_STATUS_CMD="if [ -r \"${REMOTE_ARCHIVE_FULL_PATH}\" ]; then echo 'EXISTS_READABLE'; elif [ -e \"${REMOTE_ARCHIVE_FULL_PATH}\" ]; then echo 'EXISTS_UNREADABLE'; else echo 'NOT_FOUND'; fi"
echo REMOTE_FILE_STATUS=$(ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "${REMOTE_FILE_STATUS_CMD}")
echo SSH_VERIFY_EXIT_CODE=$?
echo(
echo if [ ${SSH_VERIFY_EXIT_CODE} -ne 0 ]; then
echo     echo "Error: SSH connection failed while verifying remote file (Exit Code: ${SSH_VERIFY_EXIT_CODE})." ^| systemd-cat -p err -t "${LOG_TAG}"
echo     exit 1
echo fi
echo(
echo if [ "${REMOTE_FILE_STATUS}" != "EXISTS_READABLE" ]; then
echo     echo "Error: Remote archive '${REMOTE_ARCHIVE_FULL_PATH}' problem on Oracle server before SCP. Status: ${REMOTE_FILE_STATUS}" ^| systemd-cat -p err -t "${LOG_TAG}"
echo     echo "Listing contents of ${ORACLE_TEMP_ARCHIVE_PATH} on Oracle server for debugging:" ^| systemd-cat -p info -t "${LOG_TAG}"
echo     ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${ORACLE_TEMP_ARCHIVE_PATH}\"" 2^>^&1 ^| systemd-cat -p info -t "${LOG_TAG}"
echo     exit 1
echo fi
echo echo "Remote archive '${REMOTE_ARCHIVE_FULL_PATH}' verified as existing and readable." ^| systemd-cat -p info -t "${LOG_TAG}"
echo(
echo echo "Downloading archive '${ARCHIVE_FILENAME}' to '${NAS_BACKUP_DIR}'..." ^| systemd-cat -p info -t "${LOG_TAG}"
echo scp -v ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP}:"${REMOTE_ARCHIVE_FULL_PATH}" "${NAS_BACKUP_DIR}/"
echo SCP_EXIT_CODE=$?
echo(
echo if [ ${SCP_EXIT_CODE} -eq 0 ]; then
echo   echo "Download successful." ^| systemd-cat -p info -t "${LOG_TAG}"
echo   echo "Deleting temporary archive on Oracle server: ${REMOTE_ARCHIVE_FULL_PATH}" ^| systemd-cat -p info -t "${LOG_TAG}"
echo   ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "rm -f \"${REMOTE_ARCHIVE_FULL_PATH}\""
echo   RM_EXIT_CODE=$?
echo   if [ ${RM_EXIT_CODE} -ne 0 ]; then
echo      echo "Warning: Failed to delete remote archive '${REMOTE_ARCHIVE_FULL_PATH}' (SSH/rm Exit Code: ${RM_EXIT_CODE})." ^| systemd-cat -p warning -t "${LOG_TAG}"
echo   else
echo      echo "Remote archive deleted successfully." ^| systemd-cat -p info -t "${LOG_TAG}"
echo   fi
echo   echo "Minecraft backup download process completed successfully at $(date)." ^| systemd-cat -p info -t "${LOG_TAG}"
echo   exit 0
echo else
echo   echo "Error: Failed to download archive from Oracle server (SCP Exit Code: ${SCP_EXIT_CODE})." ^| systemd-cat -p err -t "${LOG_TAG}"
echo   echo "Archive '${REMOTE_ARCHIVE_FULL_PATH}' will NOT be deleted on Oracle server due to download failure." ^| systemd-cat -p warning -t "${LOG_TAG}"
echo   echo "Checking if archive still exists on Oracle server after failed SCP..." ^| systemd-cat -p info -t "${LOG_TAG}"
echo   ssh ${SSH_OPTIONS} ${ORACLE_USER}@${ORACLE_IP} "ls -l \"${REMOTE_ARCHIVE_FULL_PATH}\"" 2^>^&1 ^| systemd-cat -p info -t "${LOG_TAG}"
echo   exit 1
echo fi
goto :eof

:: --- Template 3: Minecraft Backup Rotation Script ---
:prompt_template_3
set "array_items="
call :prompt "YOUR_NAS_BACKUP_LVM_BASE_MOUNT_PATH_HERE" "LVM_MOUNT_BASE"
set LVM_MOUNT_BASE=!user_val!
call :prompt "YOUR_MINECRAFT_BACKUPS_SUBDIRECTORY_NAME_FOR_ROTATION_HERE" "MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION"
set MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION=!user_val!
call :prompt "YOUR_MAX_TOTAL_BACKUP_SIZE_IN_GIB_HERE" "MAX_BACKUP_SIZE_GIB"
set MAX_BACKUP_SIZE_GIB=!user_val!
call :prompt "YOUR_MINECRAFT_ROTATION_LOG_TAG_HERE" "LOG_TAG"
set LOG_TAG=!user_val!
goto :eof

:write_template_3
echo #!/bin/bash
echo(
echo LVM_MOUNT_BASE="%LVM_MOUNT_BASE%"
echo MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION="%MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION%"
echo MC_BACKUP_DIR="${LVM_MOUNT_BASE}/${MINECRAFT_BACKUPS_SUBDIR_NAME_FOR_ROTATION}/"
echo(
echo MAX_BACKUP_SIZE_GIB=%MAX_BACKUP_SIZE_GIB%
echo MAX_SIZE_BYTES=$((${MAX_BACKUP_SIZE_GIB} * 1024 * 1024 * 1024))
echo LOG_TAG="%LOG_TAG%"
echo(
echo echo "Starting Minecraft backup rotation check at $(date)" ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo if [ ! -d "${MC_BACKUP_DIR}" ]; then
echo   echo "Error: Backup directory ${MC_BACKUP_DIR} not found." ^| systemd-cat -p err -t ${LOG_TAG}
echo   exit 1
echo fi
echo(
echo while true; do
echo   CURRENT_SIZE=$(du -sb "${MC_BACKUP_DIR}" ^| cut -f1)
echo(
echo   if [ -z "${CURRENT_SIZE}" ]; then
echo       echo "Warning: Could not determine current size of ${MC_BACKUP_DIR}." ^| systemd-cat -p warning -t ${LOG_TAG}
echo       CURRENT_SIZE=0
echo   fi
echo(
echo   echo "Current size of ${MC_BACKUP_DIR} is ${CURRENT_SIZE} bytes. Max allowed is ${MAX_SIZE_BYTES} bytes." ^| systemd-cat -p info -t ${LOG_TAG}
echo(
echo   if [ "${CURRENT_SIZE}" -le "${MAX_SIZE_BYTES}" ]; then
echo     echo "Current size is within limit. No rotation needed." ^| systemd-cat -p info -t ${LOG_TAG}
echo     break
echo   fi
echo(
echo   echo "Current size exceeds limit. Attempting to delete oldest backup." ^| systemd-cat -p info -t ${LOG_TAG}
echo   OLDEST=$(ls -tr "${MC_BACKUP_DIR}" ^| grep '^world_.*\.tar\.gz$' ^| head -n 1)
echo(
echo   if [ -z "${OLDEST}" ]; then
echo     echo "Warning: No backups found matching 'world_*.tar.gz' to delete in ${MC_BACKUP_DIR}, but size limit exceeded. Check directory or naming convention from download script." ^| systemd-cat -p warning -t ${LOG_TAG}
echo     break
echo   fi
echo(
echo   echo "Deleting oldest backup: ${MC_BACKUP_DIR}${OLDEST}" ^| systemd-cat -p info -t ${LOG_TAG}
echo   if rm -f "${MC_BACKUP_DIR}${OLDEST}"; then
echo       echo "Successfully deleted ${MC_BACKUP_DIR}${OLDEST}." ^| systemd-cat -p info -t ${LOG_TAG}
echo   else
echo       echo "Error: Failed to delete ${MC_BACKUP_DIR}${OLDEST}. Exit code: $?." ^| systemd-cat -p err -t ${LOG_TAG}
echo       sleep 5
echo   fi
echo   sleep 1
echo done
echo(
echo echo "Minecraft backup rotation check complete at $(date)." ^| systemd-cat -p info -t ${LOG_TAG}
echo exit 0
goto :eof