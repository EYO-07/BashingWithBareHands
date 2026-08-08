# BEGIN Toolbox/usb_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- helpers
_get_base_dev() { # Helper to safely resolve root parent block device (e.g., sdb1 -> sdb, nvme0n1p1 -> nvme0n1)
    local target="$1"
    local dev_name="${target#/dev/}"
    local parent
    parent=$(lsblk -ndo PKNAME "/dev/$dev_name" 2>/dev/null)
    if [[ -n "$parent" ]]; then
        echo "$parent"
    else
        echo "$dev_name"
    fi
}
_is_usb_device() { # Helper to verify if block device is USB/Removable
    local base_dev="$1"
    local is_removable
    local tran
    is_removable=$(cat "/sys/block/$base_dev/removable" 2>/dev/null)
    tran=$(lsblk -ndo TRAN "/dev/$base_dev" 2>/dev/null)
    if [[ "$is_removable" == "1" || "$tran" == "usb" ]]; then
        return 0
    fi
    return 1
}
_get_device_serial() {
    local device="$1"
    local serial
    serial=$(udevadm info --query=property --name="$device" 2>/dev/null | grep -oP '^ID_SERIAL_SHORT=\K.*' | head -n 1)
    if [[ -z "$serial" ]]; then
        serial=$(udevadm info --query=property --name="$device" 2>/dev/null | grep -oP '^ID_SERIAL=\K.*' | head -n 1)
    fi
    [[ -z "$serial" ]] && serial="Unknown"
    echo "$serial"
}
_check_required_commands() {
    local missing=0
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            crit_echo "Required command not found: $cmd"
            missing=1
        fi
    done
    return "$missing"
}
_get_mountpoints() {
    local device="$1"
    lsblk -nrpo MOUNTPOINTS "$device" 2>/dev/null | awk 'NF { print }'
}
_has_active_mounts() {
    local device="$1"
    [[ -n "$(_get_mountpoints "$device")" ]]
}

function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Usb Tools"
    info_echo "... requires jq"
    info_echo "... may require dosfstools for formatting"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "showUsbDeviceInfo" "show information only for usb sticks" $width
    toolbox_item "formatUsbDevice" "format usb storage device" $width
    toolbox_item "setUsbDeviceLabel" "change the name label of usb storage device" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
function formatUsbDevice {
    source "$_SCRIPT_DIR/_codex.sh"
    local target_path="$1"
    local format_type="${2:-vfat}"
    local base_dev=""
    local part_path=""
    local is_full_disk=0
    local model=""
    local serial=""
    local size=""
    # 1. Strict Path Validation
    if [[ -z "$target_path" ]] || [[ ! "$target_path" =~ ^/dev/ ]]; then
        warn_echo "Usage: formatUsbDevice <device_or_partition_path> [format_type]"
        echo "  Examples:"
        echo "    formatUsbDevice /dev/sdb vfat   (Wipes entire disk, creates new partition table)"
        echo "    formatUsbDevice /dev/sdb1 ext4  (Formats only partition 1, preserves other partitions)"
        _codex_unset
        return 0
    fi
    if [[ ! -b "$target_path" ]]; then
        crit_echo "Error: Block device '$target_path' does not exist."
        _codex_unset
        return 1
    fi
    # 2. Resolve Base USB Device & Determine Action Scope
    base_dev="$(_get_base_dev "$target_path")"
    if ! _is_usb_device "$base_dev"; then
        crit_echo "CRITICAL ERROR: $target_path belongs to '$base_dev' which is NOT a removable USB device. Aborting."
        _codex_unset
        return 1
    fi
    # If target matches root base device (/dev/sdb), perform full wipe & partition.
    if [[ "$target_path" == "/dev/$base_dev" ]]; then
        is_full_disk=1
    fi
    # 3. Preflight filesystem and required utilities.
    # IMPORTANT: Do this BEFORE any destructive operation.
    if ! _check_required_commands jq; then
        _codex_unset
        return 1
    fi
    case "$format_type" in
        vfat|fat32)
            if ! _check_required_commands mkfs.vfat; then
                _codex_unset
                return 1
            fi
            ;;
        ntfs)
            if ! _check_required_commands mkfs.ntfs; then
                _codex_unset
                return 1
            fi
            ;;
        exfat)
            if ! _check_required_commands mkfs.exfat; then
                _codex_unset
                return 1
            fi
            ;;
        ext4)
            if ! _check_required_commands mkfs.ext4; then
                _codex_unset
                return 1
            fi
            ;;
        *)
            crit_echo "Error: Unsupported filesystem type '$format_type'."
            _codex_unset
            return 1
            ;;
    esac
    if [[ $is_full_disk -eq 1 ]]; then
        if ! _check_required_commands wipefs parted; then
            _codex_unset
            return 1
        fi
    fi
    # 4. Determine partition path.
    if [[ $is_full_disk -eq 1 ]]; then
        if [[ "$base_dev" =~ [0-9]$ ]]; then
            part_path="/dev/${base_dev}p1"
        else
            part_path="/dev/${base_dev}1"
        fi
    else
        part_path="$target_path"
    fi
    # 5. Gather identifying information BEFORE changing device state.
    model=$(udevadm info --query=property --name="/dev/$base_dev" 2>/dev/null |
        grep -oP '^ID_MODEL=\K.*' | head -n 1)
    [[ -z "$model" ]] && model="Unknown"
    serial="$(_get_device_serial "/dev/$base_dev")"
    size=$(lsblk -ndo SIZE "/dev/$base_dev" 2>/dev/null)
    echo ""
    warn_echo "You are about to format the following target:"
    echo "  Target Path : $target_path"
    echo "  Parent Model: $model"
    echo "  Serial      : $serial"
    echo "  Total Size  : $size"
    echo "  Format Type : $format_type"
    if [[ $is_full_disk -eq 1 ]]; then
        warn_echo "  Mode        : FULL DISK WIPE (Re-creates Partition Table)"
    else
        info_echo "  Mode        : SINGLE PARTITION ONLY (Preserves other partitions)"
    fi
    # 6. Confirm BEFORE unmounting or modifying device state.
    if ! token_prompt "Formatting Confirmation" "confirm formatting operation."; then
        _codex_unset
        return 0
    fi
    # 7. Unmount Target / Sub-partitions
    info_echo "Unmounting target drive/partition..."
    local unmount_failed=0
    if [[ $is_full_disk -eq 1 ]]; then
        # Use lsblk JSON + jq so mountpoints containing spaces are handled safely.
        while IFS= read -r part_path_to_unmount; do
            [[ -z "$part_path_to_unmount" ]] && continue
            if ! sudo umount "$part_path_to_unmount"; then
                crit_echo "Error: Failed to unmount $part_path_to_unmount."
                unmount_failed=1
            fi
        done < <(
            lsblk -J -o PATH,TYPE,MOUNTPOINT "/dev/$base_dev" 2>/dev/null |
                jq -r '
                    .blockdevices[]?.children[]?
                    | select(.type == "part")
                    | select((.mountpoint // "") != "")
                    | .path
                '
        )
    else
        local target_mountpoint
        target_mountpoint=$(lsblk -ndo MOUNTPOINT "$target_path" 2>/dev/null)
        if [[ -n "$target_mountpoint" ]]; then
            if ! sudo umount "$target_path"; then
                crit_echo "Error: Failed to unmount $target_path."
                unmount_failed=1
            fi
        fi
    fi
    if [[ $unmount_failed -eq 1 ]]; then
        _codex_unset
        return 1
    fi
    # 8. Partition Management (Full Disk Mode Only)
    if [[ $is_full_disk -eq 1 ]]; then
        info_echo "Wiping existing filesystem signatures..."
        if ! sudo wipefs --all "/dev/$base_dev"; then
            crit_echo "Error: Failed to wipe signatures."
            _codex_unset
            return 1
        fi
        info_echo "Creating new MSDOS partition table..."
        if ! sudo parted -s "/dev/$base_dev" mklabel msdos; then
            crit_echo "Error: Failed to create partition table."
            _codex_unset
            return 1
        fi
        local parted_fs_type="fat32"
        [[ "$format_type" == "ext4" ]] && parted_fs_type="ext4"
        if ! sudo parted -s "/dev/$base_dev" mkpart primary "$parted_fs_type" 1MiB 100%; then
            crit_echo "Error: Failed to create primary partition."
            _codex_unset
            return 1
        fi
        sudo partprobe "/dev/$base_dev" 2>/dev/null
        udevadm settle 2>/dev/null || sleep 2
        if [[ ! -b "$part_path" ]]; then
            crit_echo "Error: Target partition node '$part_path' is invalid or missing."
            _codex_unset
            return 1
        fi
    else
        # Partition-only mode:
        # Do NOT call wipefs here. mkfs is sufficient to replace the filesystem.
        if [[ ! -b "$part_path" ]]; then
            crit_echo "Error: Target partition node '$part_path' is invalid or missing."
            _codex_unset
            return 1
        fi
    fi
    # 9. Signature Inspection & Apply Filesystem
    if [[ $is_full_disk -eq 0 ]]; then
        info_echo "Checking for existing filesystem signatures on $part_path..."
        echo "ExFAT and other format tools may refuse to overwrite existing signatures without wiping it."
        if token_prompt "Signature Overwrite Confirmation" "confirm overwriting partition signature."; then
            info_echo "Wiping existing signature..."
            sudo wipefs --all "$part_path" >/dev/null 2>&1
        else 
            info_echo "keeping existing signature..."
        fi
    fi
    info_echo "Formatting $part_path as $format_type..."
    local mkfs_args=()
    case "$format_type" in
        vfat|fat32)
            mkfs_args=("mkfs.vfat" "-F" "32")
            ;;
        ntfs)
            mkfs_args=("mkfs.ntfs" "-f")
            ;;
        exfat)
            mkfs_args=("mkfs.exfat")
            ;;
        ext4)
            mkfs_args=("mkfs.ext4" "-F")
            ;;
        *)
            crit_echo "Error: Unsupported filesystem type '$format_type'."
            _codex_unset
            return 1
            ;;
    esac
    if ! sudo "${mkfs_args[@]}" "$part_path"; then
        crit_echo "Error: Formatting failed."
        _codex_unset
        return 1
    fi
    # --
    good_echo "Success! Target $part_path formatted as $format_type."
    _codex_unset
    return 0
}
function setUsbDeviceLabel {
    source "$_SCRIPT_DIR/_codex.sh"
    local part_path="$1"
    local new_label="$2"
    local base_dev=""
    local fs_type=""
    # 1. Strict Validation
    if [[ -z "$part_path" ]] || [[ ! "$part_path" =~ ^/dev/ ]] || [[ -z "$new_label" ]]; then
        warn_echo "Usage: setUsbDeviceLabel <partition_path> <new_label>"
        warn_echo "Example: setUsbDeviceLabel /dev/sdb1 \"MY_USB\""
        showUsbDeviceInfo
        _codex_unset
        return 1
    fi
    if [[ ! -b "$part_path" ]]; then
        crit_echo "Error: Device '$part_path' does not exist or is not a block device."
        _codex_unset
        return 1
    fi
    base_dev="$(_get_base_dev "$part_path")"
    # 2. USB Safety Validation
    if ! _is_usb_device "$base_dev"; then
        crit_echo "CRITICAL ERROR: $part_path belongs to '$base_dev' which is NOT a removable USB device."
        _codex_unset
        return 1
    fi
    if ! showUsbDeviceInfo "/dev/$base_dev"; then
        _codex_unset
        return 1
    fi
    source "$_SCRIPT_DIR/_codex.sh" # must be sourced again because showUsbDeviceInfo unsource _codex.sh
    # 3. Filesystem Detection & Label Utility Validation
    fs_type=$(lsblk -ndo FSTYPE "$part_path" 2>/dev/null)
    if [[ -z "$fs_type" ]]; then
        crit_echo "Error: Could not detect filesystem on $part_path ."
        _codex_unset
        return 1
    fi
    case "$fs_type" in
        vfat|fat|fat32)
            if ! _check_required_commands fatlabel; then
                _codex_unset
                return 1
            fi
            ;;
        ntfs)
            if ! _check_required_commands ntfslabel; then
                _codex_unset
                return 1
            fi
            ;;
        exfat)
            if ! command -v tune.exfat >/dev/null 2>&1 &&
               ! command -v exfatlabel >/dev/null 2>&1; then
                crit_echo "Required command not found: tune.exfat or exfatlabel"
                warn_echo "please install exfatprogs or exfat-utils"
                _codex_unset
                return 1
            fi
            ;;
        ext2|ext3|ext4)
            if ! _check_required_commands e2label; then
                _codex_unset
                return 1
            fi
            ;;
        *)
            crit_echo "Error: Unsupported filesystem '$fs_type' for labeling."
            _codex_unset
            return 1
            ;;
    esac
    # 4. Confirmation Prompt
    if ! token_prompt "Confirmation" "confirm the re-labelling of usb device"; then
        _codex_unset
        return 0
    fi
    # 5. Unmount if necessary
    local target_mountpoint
    target_mountpoint=$(lsblk -ndo MOUNTPOINT "$part_path" 2>/dev/null)
    if [[ -n "$target_mountpoint" ]]; then
        info_echo "Unmounting $part_path..."
        if ! sudo umount "$part_path"; then
            crit_echo "Error: Failed to unmount $part_path."
            _codex_unset
            return 1
        fi
    fi
    # 6. Filesystem Labeling
    info_echo "Setting label '$new_label' on $part_path ($fs_type)..."
    local cmd_success=0
    case "$fs_type" in
        vfat|fat|fat32)
            # FAT labels strictly enforce max 11 uppercase characters
            local fat_label="${new_label:0:11}"
            fat_label="${fat_label^^}"
            if [[ "${#new_label}" -gt 11 ]]; then
                warn_echo "FAT labels max length is 11 chars. Truncating '$new_label' to '$fat_label'."
            fi
            sudo fatlabel "$part_path" "$fat_label" && cmd_success=1
            ;;
        ntfs)
            sudo ntfslabel "$part_path" "$new_label" && cmd_success=1
            ;;
        exfat)
            if command -v tune.exfat &> /dev/null; then
                sudo tune.exfat -L "$new_label" "$part_path" && cmd_success=1
            else
                sudo exfatlabel "$part_path" "$new_label" && cmd_success=1
            fi
            ;;
        ext2|ext3|ext4)
            sudo e2label "$part_path" "$new_label" && cmd_success=1
            ;;
        *)
            # Kept as a defensive check even though validation already handles this.
            crit_echo "Error: Unsupported filesystem '$fs_type' for labeling."
            _codex_unset
            return 1
            ;;
    esac
    if [[ $cmd_success -eq 1 ]]; then
        good_echo "Label successfully changed."
    else
        crit_echo "Failed to change label. Ensure formatting utilities are installed."
        _codex_unset
        return 1
    fi
    _codex_unset
    return 0
}
function showUsbDeviceInfo {
    source "$_SCRIPT_DIR/_codex.sh"
    local target="$1"
    local found=0
    _print_info() {
        local dev="$1"
        local base_dev="$(_get_base_dev "$dev")"
        local full_base="/dev/$base_dev"
        # Gather static info
        local model size serial
        model=$(udevadm info --query=property --name="$full_base" 2>/dev/null | grep -oP '^ID_MODEL=\K.*' | head -n 1 || echo "Unknown")
        [[ -z "$model" ]] && model="Unknown"
        serial="$(_get_device_serial "$full_base")"
        size=$(lsblk -ndo SIZE "$full_base" 2>/dev/null)
        printf "\n%-12s : %s\n" "Device" "$full_base"
        printf "%-12s : %s\n" "Model" "$model"
        printf "%-12s : %s\n" "Serial" "$serial"
        printf "%-12s : %s\n" "Total Size" "$size"
        echo "Partitions:"
        # Use lsblk --json with explicit columns and parse with jq
        # This handles empty fields (null) automatically without IFS issues
        local json_output
        json_output=$(lsblk -Jno NAME,LABEL,FSTYPE,MOUNTPOINT,SIZE "$full_base" 2>/dev/null)
        # Parse JSON: Iterate over children of the specific device
        # We use 'select(.name == "...")' to ensure we only get children of the target device
        # and not siblings if the JSON contains multiple top-level devices
        local parts
        parts=$(echo "$json_output" | jq -r --arg dev "$base_dev" '
            .blockdevices[] 
            | select(.name == $dev) 
            | .children[]? 
            | [
                ("/dev/" + .name), 
                (.size // "Unknown"), 
                (.fstype // "None"), 
                (.label // "None"), 
                (if .mountpoint == null or .mountpoint == "" then "Not mounted" else .mountpoint end)
              ] 
            | @tsv
        ')
        if [[ -n "$parts" ]]; then
            local part_path part_size part_fs part_label part_mnt
            while IFS=$'\t' read -r part_path part_size part_fs part_label part_mnt; do
                printf "  └─ %-10s | Size: %-7s | FS: %-6s | Label: %-12s | Mount: %s\n" \
                    "$part_path" "$part_size" "$part_fs" "$part_label" "$part_mnt"
            done <<< "$parts"
        else
            # Fallback for superfloppy (no partitions)
            local label fs mountpoint
            label=$(lsblk -ndo LABEL "$full_base" 2>/dev/null)
            fs=$(lsblk -ndo FSTYPE "$full_base" 2>/dev/null)
            mountpoint=$(lsblk -ndo MOUNTPOINT "$full_base" 2>/dev/null)
            [[ -z "$label" ]] && label="None"
            [[ -z "$fs" ]] && fs="None"
            [[ -z "$mountpoint" ]] && mountpoint="Not mounted"
            printf "  └─ (No Partitions) | FS: %-6s | Label: %-12s | Mount: %s\n" \
                "$fs" "$label" "$mountpoint"
        fi
        echo "------------------------------------------------------------------------"
    }
    if [[ -n "$target" ]]; then
        if [[ "$target" =~ ^/dev/ ]]; then
            local base_dev
            base_dev="$(_get_base_dev "$target")"
            if [[ -b "/dev/$base_dev" ]]; then
                if _is_usb_device "$base_dev"; then
                    _print_info "/dev/$base_dev"
                    found=1
                else
                    crit_echo "Error: /dev/$base_dev is not a removable USB device." >&2
                    _codex_unset
                    return 1
                fi
            else
                crit_echo "Error: Device /dev/$base_dev not found." >&2
                _codex_unset
                return 1
            fi
        else
            crit_echo "Error: Target must be an absolute device path (e.g., /dev/sdb)." >&2
            _codex_unset
            return 1
        fi
    else
        echo "Scanning for USB storage devices..."
        while IFS= read -r dev; do
            if [[ -n "$dev" ]] && _is_usb_device "$dev"; then
                _print_info "/dev/$dev"
                found=1
            fi
        done < <(
            lsblk -ndo NAME,TYPE 2>/dev/null | awk '$2 == "disk" { print $1 }'
        )
        if [[ $found -eq 0 ]]; then
            warn_echo "No USB storage devices found."
        fi
    fi
    _codex_unset
    return 0
}   

# END