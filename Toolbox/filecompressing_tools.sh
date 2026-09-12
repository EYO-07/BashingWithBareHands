# BEGIN : Toolbox/filecompressing_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- load/save config
__BWBH_SAVE_CONFIG_filecompressing() {
    return 0
}

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=8
    toolbox_title "File Compressing Tools"
    toolbox_item "tools / inv" "print this ... / command syntax" $width
    if is_command_valid 7z ; then
        toolbox_item "createBackup" "create a compressed backup file for file or folder naming with datetime stamp" $width
        toolbox_item "restoreBackup <file.7z> [out_dir]" "..." $width
        toolbox_item "restoreBackup <file.7z>" "... current directory" $width
        toolbox_item "viewBackupContents" "view the contents of a compressed archive" $width
    else 
        crit_echo "... backup functions requires: 7z"
    fi
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "File/Filesystem Tools"
    local width=9
    inventory_item 1 "7z x" "extracts a compressed file preserving the folder structure" $width
    inventory_item 2 "7z e <archive> <path_in_archive> -o<out_dir>" "extracts a single file from compressed archive" $width
    inventory_item 3 "7z t" "test file integrity" $width
    inventory_endl 
    _codex_unset
}

# -- implementation
function createBackup { # create a compressed backup file for file or folder naming with datetime stamp
    source "$_SCRIPT_DIR/_codex.sh"
    if [ -z "$1" ]; then
        ls -a
        warn_echo "Usage: createBackup <path_to_file_or_folder>"
        _codex_unset
        return 0
    fi
    local source="$1"
    if [ ! -e "$source" ]; then
        echo "Error: Source '$source' does not exist."
        _codex_unset
        return 1
    fi
    # Generate timestamp: YYYYMMDD_HHMMSS
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local basename=$(basename "$source")
    local archive_name="${basename}_${timestamp}.7z"
    echo "Creating backup of '$source'..."
    # -mx=9: Ultra compression
    # -mmt=on: Multi-threading
    # -ssw: Compress shared files (useful for live backups)
    if 7z a -mx=9 -mmt=on -ssw "$archive_name" "$source"; then
        color_echo 32 "Backup created successfully: $archive_name"
        _codex_unset
        return 0
    else
        crit_echo "Error: Backup creation failed."
        _codex_unset
        return 1
    fi
}
function restoreBackup { # extract the contents of a backup file 
    source "$_SCRIPT_DIR/_codex.sh"
    if [ -z "$1" ]; then
        ls -a
        warn_echo "Usage: restoreBackup <archive_file.7z> [output_directory]"
        _codex_unset
        return 0
    fi
    local archive="$1"
    local output_dir="${2:-.}" # Default to current directory if not specified
    if [ ! -f "$archive" ]; then
        crit_echo "Error: Archive '$archive' not found."
        _codex_unset
        return 1
    fi
    local abs_output_dir="$(get_abs_path $output_dir)"
    if ! token_prompt "Restoring ($archive) to ($abs_output_dir)" "This action is irreversible"; then 
        _codex_unset
        return 0
    fi
    # -o: Set output directory
    # -y: Assume Yes on all queries (overwrite without prompt)
    if 7z x -y -o"$output_dir" "$archive"; then
        color_echo 32 "Restore completed successfully."
        _codex_unset
        return 0
    else
        crit_echo "Error: Restore failed."
        _codex_unset
        return 1
    fi
}
function viewBackupContents { # view the contents of a compressed archive
    source "$_SCRIPT_DIR/_codex.sh"
    if [ -z "$1" ]; then
        ls -la | grep -iE "zip|7z|tar" 
        warn_echo "Usage: viewBackupContents <archive_file>"
        _codex_unset
        return 1
    fi
    local archive="$1"
    if [ ! -f "$archive" ]; then
        echo "Error: Archive '$archive' not found."
        _codex_unset
        return 1
    fi
    info_echo "--- Contents of $archive ---"
    case "$archive" in
        *.7z)        7z l "$archive" ;;
        *.zip)       unzip -l "$archive" ;;
        *.tar.gz|*.tgz) tar -tf "$archive" ;;
        *)           echo "Error: Unsupported archive format." ;;
    esac
    _codex_unset
}


# END 