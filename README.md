# DIY Raspberry Pi NAS: Automated Backup & Remote Desktop

This repository contains all the necessary scripts, instructions, and resources to build a powerful, low-cost Network Attached Storage (NAS) device using a Raspberry Pi 4. This project automates backups from a Windows PC and a remote VPS, and provides a persistent, browser-accessible remote Linux desktop.

This guide is based on the process detailed in the **[accompanying video tutorial](https://www.youtube.com/watch?v=your_video_link_here)**.


> A photo of the final, assembled NAS rig.

## Table of Contents

- [Project Overview](#project-overview)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Step-by-Step Installation Guide](#step-by-step-installation-guide)
  - [Phase 1: Hardware Assembly](#phase-1-hardware-assembly)
  - [Phase 2: Initial Raspberry Pi Setup](#phase-2-initial-raspberry-pi-setup)
  - [Phase 3: OpenMediaVault (OMV) Installation](#phase-3-openmediavault-omv-installation)
  - [Phase 4: Storage Configuration](#phase-4-storage-configuration)
  - [Phase 5: Host PC Configuration](#phase-5-host-pc-configuration)
- [Scripts & Automation](#scripts--automation)
  - [Configuration Helper (`configure_all.bat`)](#configuration-helper-configure_allbat)
  - [Main PC Backup Script](#main-pc-backup-script)
  - [Remote Server Download Script](#remote-server-download-script)
  - [Backup Rotation Script](#backup-rotation-script)
  - [Rsync Exclude Files](#rsync-exclude-files)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Project Overview

This DIY NAS project is designed to provide a robust, personal data storage solution with three primary functions:

1.  **Automated PC Backup:** The NAS will automatically wake a sleeping Windows PC at a scheduled time, perform a full and incremental backup of its drives using `rsync`, and then shut it down.
2.  **Remote Server Backup:** It will connect to a remote VPS (e.g., an Oracle Cloud server running Minecraft), create a compressed archive of specified files, download it, and manage old backups to save space.
3.  **Remote Desktop:** Using Docker and Webtop, it hosts a full-featured Linux desktop environment that can be accessed from any web browser, perfect for running 24/7 scripts or managing the NAS graphically.

## Hardware Requirements

| Component | Model/Type | Quantity | Notes |
| :--- | :--- | :--- | :--- |
| **SBC** | Raspberry Pi 4 (4GB+) | 1 | The core of the NAS. |
| **Storage** | 3.5" SATA HDD | 2+ | This guide uses two 3TB Seagate Barracuda drives. |
| **Power Supply** | Official Raspberry Pi 4 PSU | 1 | Crucial for stability. Third-party cables can cause power issues. |
| **Adapters** | USB 3.0 to SATA Adapter | 2+ | Must have an external power input for 3.5" drives. |
| **USB Hub** | Powered USB 3.0 Hub | 1 | To connect drives to the Pi. Ensure it provides enough power. |
| **Enclosure** | 3D-Printed Case | 1 | Files for the specific model are in this repo. Many alternatives exist on sites like Thingiverse. |
| **SD Card** | microSD Card (16GB+) | 1 | For the Raspberry Pi's operating system. |
| **Cooling** | 30mm Fan | 1 | Optional but recommended to prevent thermal throttling. |

> [!IMPORTANT]
> **Power is Critical**:
> - **3.5" HDDs** require more power (6-12W) and both 5V and 12V lines. They **must** be powered externally via their SATA-to-USB adapters; a USB hub alone is not sufficient.
> - **2.5" HDDs** require less power (~5W) and can often be powered by a high-quality, sufficiently-powered USB hub.

## Software Requirements

- **[OpenMediaVault (OMV)](https://www.openmediavault.org/):** The NAS operating system.
- **[Raspberry Pi Imager](https://www.raspberrypi.com/software/):** To flash the OS onto the microSD card.
- **[PuTTY](https://www.putty.org/) or other SSH client:** To connect to the Raspberry Pi remotely.
- **[nmap](https://nmap.org/):** To discover the Raspberry Pi's IP address on your network.

## Step-by-Step Installation Guide

### Phase 1: Hardware Assembly

1.  **Print the Enclosure:** If you are 3D-printing your own case, print all the necessary parts.
2.  **Assemble the Rig:** Follow the assembly instructions for your chosen enclosure. Mount the Raspberry Pi, fan, and hard drives securely.
3.  **Connect Cables:** Connect the HDDs to their SATA-to-USB adapters. Plug the adapters' power cables into a power strip and their USB cables into the powered USB hub. Connect the USB hub to one of the Raspberry Pi's USB 3.0 ports (the blue ones).


### Phase 2: Initial Raspberry Pi Setup

1.  **Flash Raspberry Pi OS:**
    - Open the Raspberry Pi Imager.
    - Choose **Raspberry Pi 4** as the device.
    - For the Operating System, select `Raspberry Pi OS (Other)` -> `Raspberry Pi OS Lite (64-bit)`.
    - Select your microSD card as the storage device.
    - Click **Next**, then **Edit Settings**.
    - In the **General** tab, set a hostname, and create a username and password.
    - In the **Services** tab, enable **SSH** and select "Use password authentication".
    - Click **Save**, then **Write** to flash the OS.

![Imager](https://github.com/user-attachments/assets/659f313b-4941-4104-956f-21c9b8e19e43)


2.  **Boot and Connect:**
    - Insert the microSD card into the Raspberry Pi and power it on. **For the initial OMV installation, connect the Pi to your router via an Ethernet cable to avoid setup issues.**
    - On your PC, open a command prompt and use `nmap -sn YOUR_NETWORK_IP/24` (e.g., `192.168.1.0/24`) to find the IP address of the Raspberry Pi.
    - Open PuTTY, enter the Pi's IP address, and connect via SSH. Log in with the username and password you created.

### Phase 3: OpenMediaVault (OMV) Installation

1.  **Update System:** Once logged in via SSH, update your system:
    ```bash
    sudo apt update && sudo apt full-upgrade -y
    ```
2.  **Install OMV:** Run the official OMV installation script. This will take some time.
    ```bash
    wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
    ```
3.  **Access OMV Web UI:**
    - Once the script finishes, open a web browser and navigate to the Raspberry Pi's IP address.
    - Log in with the default credentials: username `admin` and password `openmediavault`.
    - Immediately navigate to **System -> General Settings -> Web Administrator Password** to change the default password.

![Screenshot_1170](https://github.com/user-attachments/assets/e2516f5b-d1d0-41a5-b070-dc090034d19d)


### Phase 4: Storage Configuration

1.  **Create LVM Pool:** To combine your two physical drives into one large volume:
    - In the OMV UI, go to **Storage -> Logical Volume Management**.
    - Go to the **Physical Volumes** tab and click **Create** to add both of your HDDs.
    - Go to the **Volume Groups** tab and click **Create**. Give the group a name (e.g., `NASDataPool`) and select both physical volumes.
2.  **Create File System:**
    - Go to **Storage -> File Systems** and click **Create**.
    - Select your newly created LVM volume group. Give it a label and choose the **EXT4** file system.
3.  **Create Shared Folders:**
    - Go to **Storage -> Shared Folders** and click **Create**.
    - Create a separate folder for each purpose (e.g., `MainBackup`, `ImportantBackup`, `MinecraftBackups`, `RemoteSystemData`). For each, select your LVM file system and specify a relative path.
4.  **Enable SMB/CIFS Shares:**
    - Go to **Services -> SMB/CIFS -> Settings** and enable the service.
    - Go to the **Shares** tab and click **Create**.
    - For each shared folder you created, create a corresponding SMB share. Make sure to set permissions as needed and enable the "Browseable" option if you want it to appear automatically in your network explorer.

![Screenshot_1169](https://github.com/user-attachments/assets/3051cb5f-dd36-46be-957b-8400ab498db7)



### Phase 5: Host PC Configuration

1.  **Enable Wake-on-LAN (WOL):**
    - Restart your Windows PC and enter the BIOS/UEFI settings.
    - Find the setting for "Wake on LAN" or "Power On By PCI-E/PCI" and enable it. This location varies by motherboard manufacturer.
    - Save changes and exit.

![BIOS](https://github.com/user-attachments/assets/1c93c04b-7886-451e-8774-d3a7ad86d45d)


2.  **Enable Administrative Shares:**
    - On your Windows PC, open the Registry Editor (`regedit`).
    - Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`.
    - Right-click in the right-hand pane, select `New` -> `DWORD (32-bit) Value`.
    - Name the new value `LocalAccountTokenFilterPolicy`.
    - Double-click it and set its value to `1`.
    - Restart your PC for the change to take effect.

![Registry](https://github.com/user-attachments/assets/ac62c199-7d39-47af-9054-f38b34d3d82c)


## Scripts & Automation

### Configuration Helper (`configure_all.bat`)

To simplify setup, this repository includes a `configure_all.bat` script for Windows users. This script provides a menu-driven interface that will:

1.  Prompt you for each required configuration value (e.g., IP addresses, MAC addresses, file paths).
2.  Provide descriptions and examples for each value.
3.  Automatically generate the three `.sh` scripts with your custom values inserted.

**How to use:**
1.  Download this repository as a ZIP file and extract it.
2.  Run `configure_all.bat`.
3.  Choose a script to generate from the menu.
4.  Follow the on-screen prompts.
5.  The configured script will be saved in the same directory, ready to be copied to your NAS.

### Main PC Backup Script

This script handles the complete backup process for a Windows PC. It wakes the PC, mounts its drives, runs `rsync`, and shuts it down.

<details>
  <summary>Click to show `backup_main_pc.sh`</summary>

```bash
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
)

IMPORTANT_FOLDERS_D=(
    "YOUR_IMPORTANT_FOLDER_D_1_PATH_HERE"
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
```

</details>

### Remote Server Download Script

This script connects to a remote server via SSH, creates a compressed backup, downloads it, and cleans up the remote file.

<details>
  <summary>Click to show `minecraft_download.sh`</summary>

```bash
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
```

</details>

### Backup Rotation Script

This script checks the total size of the Minecraft backup directory and deletes the oldest backups if it exceeds a defined limit.

<details>
  <summary>Click to show `minecraft_rotation.sh`</summary>

```bash
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
```

</details>

### Rsync Exclude Files

These files contain lists of patterns for `rsync` to ignore, preventing unnecessary system files, caches, and temporary files from being backed up. Place them in `/etc/rsync/` on your Raspberry Pi.

<details>
  <summary>Click to show `windows-c-drive-excludes.txt`</summary>

```
# System files & Recycle Bin
pagefile.sys
hiberfil.sys
swapfile.sys
$RECYCLE.BIN/
$Recycle.Bin/
System Volume Information/

# Windows Temp, Cache, Logs, Updates
Windows/Temp/
Windows/SoftwareDistribution/
Windows/Prefetch/
Windows/Installer/$PatchCache$/
Windows/Logs/CBS/
Windows/Minidump/
Windows/MEMORY.DMP
Windows/servicing/LCU/
Windows/LiveKernelReports/
Windows/Panther/
Windows/WinSxS/Backup/
Windows/System32/config/RegBack/
Windows/System32/sru/
Windows/System32/SleepStudy/
Windows/PLA/

# ProgramData Temp & Cache
ProgramData/Microsoft/Windows/WER/
ProgramData/Microsoft/Network/Downloader/
ProgramData/Microsoft/Diagnosis/
ProgramData/Package Cache/
ProgramData/USOShared/

# User specific cache and temp files
Users/*/AppData/Local/Temp/
Users/*/AppData/Local/Microsoft/Windows/INetCache/
Users/*/AppData/Local/Microsoft/Windows/Explorer/thumbcache_*.db
Users/*/AppData/Local/Microsoft/Windows/Explorer/iconcache_*.db
Users/*/AppData/Local/Microsoft/Windows/WebCache/
Users/*/AppData/Local/Microsoft/Windows/History/
Users/*/AppData/Local/Microsoft/Office/16.0/OfficeFileCache/
Users/*/AppData/Local/Google/Chrome/User Data/Default/Cache/
Users/*/AppData/Local/Google/Chrome/User Data/Default/Code Cache/
Users/*/AppData/Local/Google/Chrome/User Data/Default/Application Cache/
Users/*/AppData/Local/Google/Chrome/User Data/ShaderCache/
Users/*/AppData/Local/Google/Chrome/User Data/Default/Service Worker/CacheStorage/
Users/*/AppData/Local/Mozilla/Firefox/Profiles/*.default*/cache2/
Users/*/AppData/Local/Mozilla/Firefox/Profiles/*.default*/startupCache/
Users/*/AppData/Local/Mozilla/Firefox/Profiles/*.default*/shader-cache/
Users/*/AppData/Local/Microsoft/Edge/User Data/Default/Cache/
Users/*/AppData/Local/Microsoft/Edge/User Data/Default/Code Cache/
Users/*/AppData/Local/Microsoft/Edge/User Data/Default/Application Cache/
Users/*/AppData/Local/Microsoft/Edge/User Data/ShaderCache/
Users/*/AppData/Local/Microsoft/Edge/User Data/Default/Service Worker/CacheStorage/
Users/*/AppData/Local/NVIDIA/DXCache/
Users/*/AppData/Local/NVIDIA/GLCache/
Users/*/AppData/Local/AMD/DxCache/
Users/*/AppData/Local/AMD/GLCache/
Users/*/AppData/LocalLow/Microsoft/CryptnetUrlCache/
Users/*/NTUSER.DAT.LOG*
Users/*/ntuser.ini.LOG*

# Common development/build folders (optional, uncomment if C: drive contains dev projects)
# node_modules/
# vendor/
# target/
# build/
# dist/

# Other common exclusions
*.tmp
*.bak
*~
Thumbs.db
.DS_Store
desktop.ini
```

</details>

<details>
  <summary>Click to show `windows-d-drive-excludes.txt`</summary>

```
$RECYCLE.BIN/
$Recycle.Bin/
System Volume Information/
Thumbs.db
desktop.ini
*.tmp
*.bak
*~
```

</details>

## Troubleshooting

-   **HDD Chirping / Power Issues:** Your Raspberry Pi or USB hub is not providing enough power. Use the official Raspberry Pi power supply and a high-quality powered USB hub. Do not power 3.5" drives from the hub.
-   **Drives Not Detected (JMicron/UAS Issue):** Some USB-to-SATA adapters have compatibility issues with the UAS driver on Linux. To fix this, you need to blacklist the device from using UAS.
    1.  Find the Vendor and Product ID with `lsusb`.
    2.  Edit `/boot/firmware/cmdline.txt` and add `usb-storage.quirks=VENDOR_ID:PRODUCT_ID:u` to the end of the line.
    3.  Reboot the Raspberry Pi.
-   **Windows Share 'Permission Denied':** Windows, by default, restricts remote administrative access to its drives.
    1.  Open Registry Editor (`regedit`) on your Windows PC.
    2.  Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`.
    3.  Create a new `DWORD (32-bit) Value`, name it `LocalAccountTokenFilterPolicy`, and set its value to `1`.
    4.  Reboot your PC.
-   **OMV Plugin Failures:** If a newly installed plugin is not working, try disabling the NTP server.
    -   In the OMV UI, go to **System -> Date & Time** and uncheck "Use NTP server".


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
```
