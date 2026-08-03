# BEGIN : ~/Toolbox/mounting_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. udisksctl

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Mounting Tools"
    info_echo "... requires: udisksctl; basic filesystem tools: fsck, lsblk, blkid"
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
    toolbox_item "checkFilesystemErrors" "check for filesystem errors on unmounted device by label" $width
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
function checkFilesystemErrors {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -eq 0 ]; then 
        warn_echo "Usage: checkFilesystemErrors <label>"
        storageDeviceLabels
        _codex_unset
        return 0
    fi 
    # Notation: A || B means that B is inside the structure of A, B is one topological level internal.
    # Notation: A | B means that A and B are on same topological level, same scope.
    # Notation: % means a conditional structure 
    # Observation: those functions are abstractions, not necessarily actual functions
    # ... 
    # Logic [ checkFilesystemErrors ]
    # Usage: checkFilesystemErrors <Label>
    # C := checkFilesystemErrors
    # L := extract the device name from label, if fail return 1
    # T := check for errors without changing, if find error return 0
    # F := filesystem repair, if fail return 0
    # I := check if filesystem partition is mounted, if so return 0
    # C || % !L || feedback | return 1
    # C || % !L | % I || feedback | return 1
    # C || % !L | % I | % T | feedback | return 0
    # C || % !L | % I | % T || % prompt for fix with default cancel | feedback | return 0
    # C || % !L | % I | % T || % prompt for fix with default cancel || feedback | return 1
    local LABEL="$*"
    local DEVICE
    local FSCK_EXIT
    local RESPONSE
    # --- L: Extract device name from label ---
    DEVICE=$(blkid -L "$LABEL" 2>/dev/null)
    if [[ -z "$DEVICE" ]]; then
        crit_echo "Error: Label '$LABEL' not found."
        _codex_unset
        return 1
    fi
    info_echo "Target device for label '$LABEL': $DEVICE"
    # --- I: Check if filesystem partition is mounted ---
    if findmnt -rno SOURCE,TARGET "$DEVICE" >/dev/null 2>&1; then
        crit_echo "Error: Partition $DEVICE is currently mounted."
        warn_echo "Please unmount it before checking integrity."
        _codex_unset
        return 1
    fi
    # --- T: Check for errors without changing (Dry Run) ---
    info_echo "Running read-only check on $DEVICE..."
    # Run fsck -n and capture the exit code
    #sudo fsck -n "$DEVICE" >/dev/null 2>&1
    sudo fsck -n -v -C "$DEVICE"
    FSCK_EXIT=$?
    # Interpret exit codes (bitmask)
    # 0: No errors
    # 1: Errors corrected (or would be corrected) -> Usually safe, just dirty
    # 2: System should reboot
    # 4: Errors left uncorrected -> CRITICAL
    # 8+: Operational errors
    if (( FSCK_EXIT == 0 )); then
        good_echo "Success: No critical errors found on $DEVICE."
        info_echo "... if minor journal inconsistencies were found, those can be fixed by mounting the system."
        _codex_unset
        return 0
    elif (( FSCK_EXIT & 4 )); then
        # Bitwise AND with 4. If true, uncorrected errors exist.
        warn_echo "Warning: Uncorrected errors detected on $DEVICE (Code: $FSCK_EXIT)."
    elif (( FSCK_EXIT & 1 )); then
        # Errors found but correctable (dirty bit). 
        # Optional: You might still want to offer a repair to clear the dirty bit cleanly.
        warn_echo "Notice: Filesystem is dirty but errors appear correctable (Code: $FSCK_EXIT)."
        warn_echo "A repair run will cleanly clear the journal/dirty bit."
    else
        # Other codes (2, 8, 16, etc.)
        warn_echo "Warning: Filesystem check returned status $FSCK_EXIT."
    fi
    # --- Prompt for fix with default cancel ---
    # Only prompt if we detected issues (FSCK_EXIT != 0)
    if token_prompt "Do you want to attempt to repair these errors?" "Do not interrupt or poweroff the system, or the operation could corrupt the partition" ; then
        info_echo "Attempting repair on $DEVICE..."
        #if sudo fsck -y "$DEVICE"; then
        if sudo fsck -y -v -C "$DEVICE"; then
            good_echo "Repair completed successfully."
            _codex_unset
            return 0
        else
            crit_echo "Error: Repair failed or encountered uncorrectable errors."
            _codex_unset
            return 1
        fi
    else
        warn_echo "Operation cancelled by user. Filesystem remains unchecked/unrepaired."
        _codex_unset
        return 0 # Return 0 as per your "default cancel" logic
    fi
}

# END