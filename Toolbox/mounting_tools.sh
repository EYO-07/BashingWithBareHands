# BEGIN : ~/Toolbox/mounting_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. udisksctl

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Mounting Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "showMountPoints" "show mounted units devices" $width
    toolbox_item "showStorageDevicesInfo" "..." $width
    toolbox_item "mountIsoFile" "mount iso file as storage device" $width
    toolbox_item "safelyRemoveUsb" "safely unmount and power-off usb device" $width
    toolbox_item "storageDeviceLabels" "show the storage device labels" $width
    toolbox_item "mountStorageDevice <Label>" "mount storage device by label" $width
    toolbox_item "unmountStorageDevice" "unmount storage device by label" $width
    toolbox_item "gotoMountedStorage" "go to default mounted storage by label" $width
    toolbox_item "showLabelsMounted" "show ONLY mounted storage device labels" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "todo"
    local width=9
    inventory_item 1 "..." "..." $width
    inventory_endl 
    _codex_unset
}

# -- implementation
alias showMountPoints='sudo lsblk -l'
alias showStorageDevicesInfo='(sudo blkid && sudo fdisk -l) | tee ~/storage_devices.txt'
alias mountIsoFile='udisksctl loop-setup -f'
function safelyRemoveUsb { # safely unmount and power-off usb storage by label
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: safelyRemoveUsb <LABEL>"
        storageDeviceLabels
        _codex_unset
        return 1
    fi
    local LABEL="$1"
    # Resolve label to partition path (e.g., /dev/sdb1)
    local PARTITION="/dev/disk/by-label/${LABEL}"
    if [[ ! -e "$PARTITION" ]]; then
        echo "Error: Device with label '$LABEL' not found."
        _codex_unset
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
        _codex_unset
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
    _codex_unset
}   
function unmountStorageDevice { # unmount storage device by label
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: unmountStorageDevice <LABEL>"
        storageDeviceLabels
        _codex_unset
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"
    # Check if the label symlink exists
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: Device with label '$LABEL' not found."
        _codex_unset
        return 1
    fi
    # Resolve the real device path (e.g., /dev/sdb1) because udisksctl needs it
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    if [[ -z "$REAL_DEVICE" ]]; then
        echo "Error: Could not resolve real device path for '$LABEL'."
        _codex_unset
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
        _codex_unset
        return 1
    fi
    _codex_unset
}
function storageDeviceLabels { # show storage device labels 
    source "$_SCRIPT_DIR/_codex.sh"
    local LABEL_DIR="/dev/disk/by-label"
    if [[ ! -d "$LABEL_DIR" ]]; then
        echo "Error: Directory $LABEL_DIR does not exist."
        _codex_unset
        return 1
    fi
    local labels
    labels=$(ls -1 "$LABEL_DIR" 2>/dev/null)
    if [[ -z "$labels" ]]; then
        echo "No storage devices with labels found."
        _codex_unset
        return 0
    fi
    echo "Available storage labels:"
    echo "$labels"
    _codex_unset
}
function mountStorageDevice { # mount storage device by label 
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: mount_storage_device <LABEL>"
        storageDeviceLabels
        _codex_unset
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"
    if [[ -z "$LABEL" ]]; then
        echo "USAGE: mount_storage_device <LABEL>"
        _codex_unset
        return 1
    fi 
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: '$LABEL' not found in $DEVICE"
        _codex_unset
        return 1
    fi
    # Resolve real path to ensure compatibility
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    if MOUNT_OUTPUT=$(udisksctl mount -b "$REAL_DEVICE" 2>&1); then
        echo "$MOUNT_OUTPUT"
    else
        echo "Error: $MOUNT_OUTPUT"
        _codex_unset
        return 1
    fi
    _codex_unset
}
function gotoMountedStorage { # goto default mounted storage by label
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -ne 1 ]]; then
        showLabelsMounted
        echo "USAGE: gotoMountedStorage <LABEL>"
        _codex_unset
        return 1
    fi
    local LABEL="$1"
    local DEVICE="/dev/disk/by-label/${LABEL}"    
    if [[ ! -e "$DEVICE" ]]; then
        echo "Error: Device '$LABEL' not found."
        _codex_unset
        return 1
    fi
    local REAL_DEVICE
    REAL_DEVICE=$(readlink -f "$DEVICE")
    # Find mount point using findmnt (cleaner than parsing lsblk)
    local MOUNT_POINT
    MOUNT_POINT=$(findmnt -n -o TARGET "$REAL_DEVICE" 2>/dev/null)
    if [[ -z "$MOUNT_POINT" ]]; then
        echo "Error: Device '$LABEL' is not mounted."
        _codex_unset
        return 1
    fi
    cd "$MOUNT_POINT" && echo "Changed directory to: $MOUNT_POINT" || echo "Failed to change directory."
    _codex_unset
}
function showLabelsMounted { # show ONLY mounted storage device labels 
    source "$_SCRIPT_DIR/_codex.sh"
    # Use findmnt to list all mounted filesystems, outputting only the LABEL column
    # -n: No headings
    # -r: Raw output (easier to parse)
    # -o LABEL: Output only the LABEL column
    local labels
    labels=$(findmnt -n -r -o LABEL 2>/dev/null | sort -u)
    if [[ -z "$labels" ]]; then
        echo "No mounted storage devices with labels found."
        _codex_unset
        return 0
    fi
    echo ""
    echo "--- Available mounted storage labels ---"
    echo "$labels"
    _codex_unset
}

# END