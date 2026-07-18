# BEGIN : ~/Toolbox/filesystem_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. 7z : compressing and extracting tools 

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Files/Filesystem Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "createFile" "if not exists creates a regular file by filename" $width
    toolbox_item "renameFile" "rename file/folder with token confirmation prompt" $width
    toolbox_item "createFolder" "if not exists creates a folder" $width
    toolbox_item "deleteFile <path>" "safely deletes a file after confirming with a random token." $width
    toolbox_item "deleteFolder <path>" "recursively deletes a folder after confirming with a random token." $width
    toolbox_item "createFileFromTemplate" "create a template file from ~/Template folder " $width
    toolbox_item "getHashInfo" "sha256 and other useful hashs for a file" $width
    toolbox_item "getSize" "estimate or get metadata of filesize of folder or file" $width
    toolbox_item "showMetadata" "show metadata info for file or folder" $width
    toolbox_item "createBackup" "create a compressed backup file for file or folder naming with datetime stamp" $width
    toolbox_item "restoreBackup <file.7z> [out_dir]" "..." $width
    toolbox_item "restoreBackup <file.7z>" "... current directory" $width
    toolbox_item "viewBackupContents" "view the contents of a compressed archive" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "7z {File Compression}"
    local width=9
    inventory_item 1 "7z x" "extracts a compressed file preserving the folder structure" $width
    inventory_item 2 "7z e <archive> <path_in_archive> -o<out_dir>" "extracts a single file from compressed archive" $width
    inventory_item 3 "7z t" "test file integrity" $width
    inventory_endl 
    _codex_unset
}

# -- implementation
function createFile {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a
        warn_echo "USAGE: createFile <filename>"
        return 1
    fi
    local filename="$1"
    local absolute_path
    if [[ -e "$filename" ]]; then
        absolute_path="$(cd "$(dirname "$filename")" && pwd)/$(basename "$filename")"
    else
        local dir_part="$(dirname "$filename")"
        local file_part="$(basename "$filename")"
        if [[ ! -d "$dir_part" ]]; then
            mkdir -p "$dir_part" || {
                warn_echo "Error: Could not create directory '$dir_part'"
                return 1
            }
        fi        
        absolute_path="$(cd "$dir_part" && pwd)/$file_part"
    fi
    if [[ -f "$absolute_path" ]]; then
        warn_echo "File Already Exists"
    else 
        if touch "$absolute_path"; then
            echo "Created file: $absolute_path"
        else
            warn_echo "Error: Failed to create file '$absolute_path'"
        fi
    fi
    _codex_unset
}
function renameFile {
    source "$_SCRIPT_DIR/_codex.sh"
    # Validate arguments (expects 2: old_name new_name)
    if [ $# -ne 2 ]; then 
        ls -a
        warn_echo "USAGE: renameFile <current_filename> <new_filename>"
        return 1
    fi
    local old_filename="$1"
    local new_filename="$2"
    local old_absolute_path
    local new_absolute_path
    local dir_part
    local file_part
    # --- Resolve Old Absolute Path ---
    if [[ ! -e "$old_filename" ]]; then
        crit_echo "Error: Source file does not exist: $old_filename"
        _codex_unset
        return 1
    fi
    old_absolute_path="$(cd "$(dirname "$old_filename")" && pwd)/$(basename "$old_filename")"
    # --- Resolve New Absolute Path ---
    # Check if target exists or if only the parent path exists
    if [[ -e "$new_filename" ]]; then
        new_absolute_path="$(cd "$(dirname "$new_filename")" && pwd)/$(basename "$new_filename")"
    else
        dir_part="$(dirname "$new_filename")"
        file_part="$(basename "$new_filename")"
        # Ensure parent directory for new name exists
        if [[ ! -d "$dir_part" ]]; then
            if ! mkdir -p "$dir_part"; then
                crit_echo "Error: Could not create directory '$dir_part' for new filename"
                _codex_unset
                return 1
            fi
        fi
        new_absolute_path="$(cd "$dir_part" && pwd)/$file_part"
    fi
    # --- Check for Collision ---
    if [[ -e "$new_absolute_path" ]]; then
        # If old and new resolve to the same file, do nothing
        if [[ "$old_absolute_path" == "$new_absolute_path" ]]; then
            echo "Source and destination are identical. No action taken."
        else 
            warn_echo "Target already exists: $new_absolute_path"
            crit_echo "Operation Cancelled"
        fi
        _codex_unset
        return 0
    fi
    # --- Perform Rename ---
    if token_prompt "Confirm Renaming" "$old_filename to $new_absolute_path"; then 
        if mv -- "$old_absolute_path" "$new_absolute_path"; then
            echo "Renamed: $old_absolute_path -> $new_absolute_path"
            _codex_unset
            return 0
        else
            warn_echo "Error: Failed to rename file"
            _codex_unset
            return 1
        fi
    fi
}
function createFolder {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a
        warn_echo "USAGE: createFolder <foldername>"
        return 1
    fi
    local foldername="$1"
    local absolute_path
    local dir_part
    local folder_part
    # --- Resolve Absolute Path ---
    if [[ -d "$foldername" ]]; then
        # Folder exists, resolve directly
        absolute_path="$(cd "$(dirname "$foldername")" && pwd)/$(basename "$foldername")"
    else
        # Folder does not exist, resolve parent dir
        dir_part="$(dirname "$foldername")"
        folder_part="$(basename "$foldername")"
        # Ensure parent directory exists
        if [[ ! -d "$dir_part" ]]; then
            crit_echo "this function was not intended to create nested subfolders structure"
            warn_echo "create the parent folder first"
            _codex_unset
            return 1
        fi
        absolute_path="$(cd "$dir_part" && pwd)/$folder_part"
    fi
    # --- Check Existence & Create ---
    if [[ -d "$absolute_path" ]]; then
        warn_echo "Folder already exists: $absolute_path"
    else
        # Check if a FILE with the same name exists (safety check)
        if [[ -e "$absolute_path" ]]; then
            crit_echo "Error: A file with this name already exists: $absolute_path"
            _codex_unset
            return 1
        fi
        if mkdir -- "$absolute_path"; then
            echo "Created folder: $absolute_path"
        else
            crit_echo "Error: Failed to create folder '$absolute_path'"
            _codex_unset
            return 1
        fi
    fi
    _codex_unset
    return 0
}   
function getSize { # estimate or get metadata of filesize of folder or file 
    source "$_SCRIPT_DIR/_codex.sh"
    # estimate or get metadata of filesize of folder or file 
    # Usage: getFileSize <path>
    if [[ "$#" -ne 1 ]]; then
        ls -a
        warn_echo "Usage: getSize <path>"
        _codex_unset
        return 1
    fi
    local path="$1"
    if [[ ! -e "$path" ]]; then
        crit_echo "Error: Path '$path' does not exist."
        _codex_unset
        return 1
    fi
    info_echo "--- Size Information for: $path ---"
    if [[ -d "$path" ]]; then
        # Directory: Use du for apparent size and disk usage
        color_echo 32 "Type: Directory"
        echo -n "Apparent Size: "
        du -sh "$path" | cut -f1
        echo -n "Disk Usage (blocks): "
        du -s "$path" | cut -f1
        echo "File Count:"
        find "$path" -type f | wc -l
    else
        # File: Use stat for precise byte count and du for blocks
        color_echo 35 "Type: File"
        echo -n "Exact Size (bytes): "
        stat -c %s "$path" 2>/dev/null || stat -f %z "$path" 2>/dev/null # Handles Linux/macOS
        echo -n "Human Readable: "
        du -h "$path" | cut -f1
        echo -n "Disk Blocks Used: "
        du -s "$path" | cut -f1
    fi
    _codex_unset
}
function createFileFromTemplate { # create a template file from ~/Template folder 
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -ne 2 ]]; then
        info_echo "Available Templates (~/Templates): "
        ls ~/Templates
        warn_echo "USAGE: createFileFromTemplate <template_filename> <filename>"
        _codex_unset
        return 0
    fi
    if [[ ! -f ~/Templates/"$1" ]]; then
        echo "Error: Template '$1' not found in ~/Templates/"
        ls ~/Templates -l
        _codex_unset
        return 1
    fi
    local new_absolute_path
    new_absolute_path="$(get_abs_path $2)"
    if [ -e "$new_absolute_path" ]; then 
        crit_echo "File Already Exists"
        _codex_unset
        return 1
    fi
    cp --verbose ~/Templates/"$1" "$new_absolute_path"
    color_echo 32 "File Created Successfully from Template"
    _codex_unset
    return 0
}
function getHashInfo { # sha256 and other useful hashs for a file
    source "$_SCRIPT_DIR/_codex.sh"
    # sha256 and other useful hashes for a file
    # Usage: getHashInfo <filename>
    if [[ "$#" -ne 1 ]]; then
        ls -a
        warn_echo "Usage: getHashInfo <filename>"
        _codex_unset
        return 0
    fi
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found or is not a regular file."
        _codex_unset
        return 1
    fi
    echo ""
    warn_echo "--- Hash Information for: $file ---"
    # SHA256 (Standard)
    echo -n "SHA256: "
    sha256sum "$file" | awk '{print $1}'
    # SHA1 (Legacy compatibility)
    if command -v sha1sum &> /dev/null; then
        echo -n "SHA1:   "
        sha1sum "$file" | awk '{print $1}'
    fi
    # MD5 (Legacy/Checksums)
    if command -v md5sum &> /dev/null; then
        echo -n "MD5:    "
        md5sum "$file" | awk '{print $1}'
    fi
    # BLAKE2b (If available, faster and more secure)
    if command -v b2sum &> /dev/null; then
        echo -n "BLAKE2b:"
        b2sum "$file" | awk '{print $1}'
    fi
    echo ""
    _codex_unset
}
function showMetadata { # show metadata info for file or folder
    source "$_SCRIPT_DIR/_codex.sh"
    # show metadata info for file or folder
    # Usage: showMetadata <path>
    if [[ "$#" -ne 1 ]]; then
        ls -a
        warn_echo "Usage: showMetadata <path>"
        _codex_unset
        return 0
    fi
    local path="$1"
    if [[ ! -e "$path" ]]; then
        crit_echo "Error: Path '$path' does not exist."
        _codex_unset
        return 1
    fi
    # Standard POSIX/Linux Metadata using stat
    echo ""
    info_echo "--- System Metadata : $path ---"
    # Using stat with format options (Linux specific mostly, %z is modify time)
    stat -c "File: %n" "$path"
    stat -c "Size: %s bytes" "$path"
    stat -c "Blocks: %b" "$path"
    stat -c "IO Block: %o" "$path"
    stat -c "Type: %F" "$path"
    stat -c "Device: %d" "$path"
    stat -c "Inode: %i" "$path"
    stat -c "Links: %h" "$path"
    stat -c "Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)" "$path"
    stat -c "Access Time: %x" "$path"
    stat -c "Modify Time: %y" "$path"
    stat -c "Change Time: %z" "$path"
    # File type detection
    info_echo "--- File Type Detection ---"
    file -b "$path"
    echo ""
    _codex_unset
}
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

# << refactored | refactoring {_codex.sh} >>

function viewBackupContents { # view the contents of a compressed archive
    source "$_SCRIPT_DIR/_codex.sh"
    if [ -z "$1" ]; then
        echo "Error: No archive file provided."
        echo "Usage: peekBackup <archive_file>"
        return 1
    fi

    local archive="$1"
    if [ ! -f "$archive" ]; then
        echo "Error: Archive '$archive' not found."
        return 1
    fi

    echo "--- Contents of $archive ---"
    case "$archive" in
        *.7z)        7z l "$archive" ;;
        *.zip)       unzip -l "$archive" ;;
        *.tar.gz|*.tgz) tar -tf "$archive" ;;
        *)           echo "Error: Unsupported archive format." ;;
    esac
}
function deleteFolder { 
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: deleteFolder <path>
    # Recursively deletes a folder after confirming with a random token.
    local target_path="${1:-}"
    # 1. Validate Input
    if [ -z "$target_path" ]; then
        ls -a
        warn_echo "Usage: deleteFolder <path>"
        return 0
    fi
    # 2. Check Existence
    if [ ! -d "$target_path" ]; then
        crit_echo "Error: Directory '$target_path' does not exist or is not a directory."
        return 1
    fi
    # 3. Gather Information (Size & Contents)
    # Get human-readable size
    local dir_size
    dir_size=$(du -sh "$target_path" 2>/dev/null | cut -f1)
    # Count items
    local item_count
    item_count=$(find "$target_path" -mindepth 1 | wc -l | tr -d ' ')
    color_echo 33 "--- Deletion Preview ---"
    color_echo 36 "Target: $target_path"
    color_echo 36 "Total Size: $dir_size"
    color_echo 36 "Items to delete: $item_count"
    color_echo 31 "WARNING: This action is irreversible!"
    # 4. Generate Random Token (6 characters, alphanumeric)
    # Uses /dev/urandom for cryptographic security
    local confirm_token
    confirm_token=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)
    # 5. Prompt User
    color_echo 35 "To confirm deletion, type the following token exactly:"
    color_echo 32 ">>> $confirm_token <<<"
    read -p "Enter token: " user_input
    # 6. Verify and Execute
    if [ "$user_input" == "$confirm_token" ]; then
        color_echo 35 "Token matched. Deleting..."
        rm -rf "$target_path"
        if [ $? -eq 0 ]; then
            color_echo 32 "=== Deletion Successful ==="
            return 0
        else
            crit_echo "=== Deletion Failed (Permission error?) ==="
            return 1
        fi
    else
        crit_echo "=== Deletion Cancelled: Token mismatch ==="
        return 1
    fi
}
function deleteFile { 
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: deleteFile <path>
    # Deletes a single file after confirming with a random token.
    local target_path="${1:-}"
    # 1. Validate Input
    if [ -z "$target_path" ]; then
        crit_echo "Error: No path provided."
        echo "Usage: deleteFile <path>"
        return 1
    fi
    # 2. Check Existence (Ensure it is a file, not a directory)
    if [ ! -f "$target_path" ]; then
        if [ -d "$target_path" ]; then
            crit_echo "Error: '$target_path' is a directory. Use deleteFolder instead."
        else
            crit_echo "Error: File '$target_path' does not exist."
        fi
        return 1
    fi
    # 3. Gather Information (Size)
    local file_size
    file_size=$(du -h "$target_path" 2>/dev/null | cut -f1)
    color_echo 33 "--- Deletion Preview ---"
    color_echo 36 "Target: $target_path"
    color_echo 36 "Size: $file_size"
    color_echo 31 "WARNING: This action is irreversible!"
    # 4. Generate Random Token (6 characters, alphanumeric)
    local confirm_token
    confirm_token=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)
    # 5. Prompt User
    color_echo 35 "To confirm deletion, type the following token exactly:"
    color_echo 32 ">>> $confirm_token <<<"
    read -p "Enter token: " user_input
    # 6. Verify and Execute
    if [ "$user_input" == "$confirm_token" ]; then
        color_echo 35 "Token matched. Deleting..."
        rm -f "$target_path"
        if [ $? -eq 0 ]; then
            color_echo 32 "=== Deletion Successful ==="
            return 0
        else
            crit_echo "=== Deletion Failed (Permission error?) ==="
            return 1
        fi
    else
        crit_echo "=== Deletion Cancelled: Token mismatch ==="
        return 1
    fi
}   

# ""

# END