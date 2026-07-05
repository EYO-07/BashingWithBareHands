# BEGIN : ~/Toolbox/mounting_tools.sh

# -- dependencies
# 1. udisksctl

# -- description

# RED = 31 - 41
# GREEN = 32 - 42
# YELLOW = 33 - 43
# BLUE = 34 - 44
# MAGENTA = 35 - 45
# CYAN = 36 - 46
# WHITE = 37 - 47
function color_echo {
    local color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

echo ""
color_echo 33 "=== Mounting Tools ==="
echo "showMountPoints : show mounted units"
echo "showStorageDevicesInfo : ..."
echo "mountIsoFile : mount iso file"
echo "safelyRemoveUsb : safely unmount and power-off usb device"
echo "storageDeviceLabels : show the storage device labels"
echo "mountStorageDevice <Label> : mount storage device by label"
echo "unmountStorageDevice : unmount storage device by label"
echo "gotoMountedStorage : goto default mounted storage by label"
echo "showLabelsMounted : show ONLY mounted storage device labels "
echo ""

# -- implementation
alias showMountPoints='sudo lsblk -l'
alias showStorageDevicesInfo='(sudo blkid && sudo fdisk -l) | tee ~/storage_devices.txt'
alias mountIsoFile='udisksctl loop-setup -f'
function safelyRemoveUsb { # safely unmount and power-off usb storage by label
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: safelyRemoveUsb <LABEL>"
        storageDeviceLabels
        return 1
    fi
    local LABEL="$1"
    # Resolve label to partition path (e.g., /dev/sdb1)
    local PARTITION="/dev/disk/by-label/${LABEL}"
    if [[ ! -e "$PARTITION" ]]; then
        echo "Error: Device with label '$LABEL' not found."
        return 1
    fi
    # Resolve the real partition path (in case symlink changes)
    local REAL_PARTITION
    REAL_PARTITION=$(readlink -f "$PARTITION")
    # Derive the parent drive path (e.g., /dev/sdb from /dev/sdb1)
    # This removes the trailing number from the device name
    local PARENT_DRIVE
    PARENT_DRIVE=$(echo "$REAL_PARTITION" | sed 's/[0-9]*$//')
    echo "Safely removing '$LABEL' ($REAL_PARTITION)..."
    # Step 1: Unmount the partition
    # udisksctl unmount handles cache flushing automatically
    if ! udisksctl unmount -b "$REAL_PARTITION"; then
        echo "Error: Failed to unmount '$LABEL'. It may be in use."
        return 1
    fi
    # Step 2: Power off the parent drive
    # This cuts power to the USB port, making it safe to pull
    if udisksctl power-off -b "$PARENT_DRIVE"; then
        echo "Success: '$LABEL' is now safe to remove."
    else
        echo "Warning: Unmounted successfully, but failed to power off drive."
        echo "You may manually unplug if no LED activity is visible."
    fi
}   
function unmountStorageDevice { # unmount storage device by label
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: unmountStorageDevice <LABEL>"
        storageDeviceLabels
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"
    # Check if the label symlink exists
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: Device with label '$LABEL' not found."
        return 1
    fi
    # Resolve the real device path (e.g., /dev/sdb1) because udisksctl needs it
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    if [[ -z "$REAL_DEVICE" ]]; then
        echo "Error: Could not resolve real device path for '$LABEL'."
        return 1
    fi
    echo "Unmounting $REAL_DEVICE (Label: $LABEL)..."
    # Use udisksctl to unmount
    if UMON_OUTPUT=$(udisksctl unmount -b "$REAL_DEVICE" 2>&1); then
        echo "$UMON_OUTPUT"
        # Optional: Power off if it's a removable USB drive
        # udisksctl power-off -b "$REAL_DEVICE"
    else
        echo "Error unmounting: $UMON_OUTPUT"
        return 1
    fi
}
function storageDeviceLabels { # show storage device labels 
    local LABEL_DIR="/dev/disk/by-label"
    if [[ ! -d "$LABEL_DIR" ]]; then
        echo "Error: Directory $LABEL_DIR does not exist."
        return 1
    fi
    local labels
    labels=$(ls -1 "$LABEL_DIR" 2>/dev/null)
    if [[ -z "$labels" ]]; then
        echo "No storage devices with labels found."
        return 0
    fi
    echo "Available storage labels:"
    echo "$labels"
}
function mountStorageDevice { # mount storage device by label 
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: mount_storage_device <LABEL>"
        storageDeviceLabels
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"
    if [[ -z "$LABEL" ]]; then
        echo "USAGE: mount_storage_device <LABEL>"
        return 1
    fi 
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: '$LABEL' not found in $DEVICE"
        return 1
    fi
    
    # Resolve real path to ensure compatibility
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    
    if MOUNT_OUTPUT=$(udisksctl mount -b "$REAL_DEVICE" 2>&1); then
        echo "$MOUNT_OUTPUT"
    else
        echo "Error: $MOUNT_OUTPUT"
        return 1
    fi
    
    #if MOUNT_OUTPUT=$(udisksctl mount -b "$DEVICE" 2>&1); then
        #echo "$MOUNT_OUTPUT"
    #else
        #echo "$MOUNT_OUTPUT"
        #return 1
    #fi
}
function gotoMountedStorage { # goto default mounted storage by label
    if [[ "$#" -ne 1 ]]; then
        showLabelsMounted
        echo "USAGE: gotoMountedStorage <LABEL>"
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"    
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: Device '$LABEL' not found."
        return 1
    fi
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    # Find mount point using findmnt (cleaner than parsing lsblk)
    local MOUNT_POINT
    MOUNT_POINT=$(findmnt -n -o TARGET "$REAL_DEVICE" 2>/dev/null)
    if [[ -z "$MOUNT_POINT" ]]; then
        echo "Error: Device '$LABEL' is not mounted."
        return 1
    fi
    cd "$MOUNT_POINT" && echo "Changed directory to: $MOUNT_POINT" || echo "Failed to change directory."
}
function showLabelsMounted { # show ONLY mounted storage device labels 
    # Use findmnt to list all mounted filesystems, outputting only the LABEL column
    # -n: No headings
    # -r: Raw output (easier to parse)
    # -o LABEL: Output only the LABEL column
    local labels
    labels=$(findmnt -n -r -o LABEL 2>/dev/null | sort -u)
    if [[ -z "$labels" ]]; then
        echo "No mounted storage devices with labels found."
        return 0
    fi
    echo ""
    echo "--- Available mounted storage labels ---"
    echo "$labels"
}

# END