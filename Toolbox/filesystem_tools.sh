# BEGIN : ~/Toolbox/filesystem_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. 7z : compressing and extracting tools 

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Files/Filesystem Tools"
    info_echo "... requires: sudo, touch, rm, makedir"
    info_echo "... backup functions requires: 7z"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "createFile" "if not exists creates a regular file by filename" $width
    toolbox_item "createLink" "creates a symlink" $width
    toolbox_item "renameFile" "rename file/folder with token confirmation prompt" $width
    toolbox_item "createFolder" "if not exists creates a folder" $width
    toolbox_item "deleteFile <path>" "safely deletes a file after confirming with a random token." $width
    toolbox_item "deleteFolder <path>" "recursively deletes a folder after confirming with a random token." $width
    toolbox_item "createFromTemplate" "create a template file or folder from ~/Template folder " $width
    toolbox_item "getHashInfo" "sha256 and other useful hashs for a file" $width
    toolbox_item "getSize" "estimate or get metadata of filesize of folder or file" $width
    toolbox_item "showMetadata" "show metadata info for file or folder" $width
    toolbox_item "showFileTree" "display files recursively" $width
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
    inventory_title "File/Filesystem Tools"
    local width=9
    inventory_item 1 "7z x" "extracts a compressed file preserving the folder structure" $width
    inventory_item 2 "7z e <archive> <path_in_archive> -o<out_dir>" "extracts a single file from compressed archive" $width
    inventory_item 3 "7z t" "test file integrity" $width
    inventory_item 4 "touch FILENAME" "creates a regular empty file" $width
    inventory_item 5 "mkdir -p PATH" "creates a directory" $width
    inventory_endl 
    _codex_unset
}

# -- implementation
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
function showFileTree {
    source "$_SCRIPT_DIR/_codex.sh"
    # Usage: showFileTree <folder_path> [ <keyword1> <keyword2> ... ]
    if [ $# -eq 0 ]; then 
        ls -a
        warn_echo "Usage: showFileTree <folder_path>"
        _codex_unset
        return 0
    fi
    if [ -t 0 ] || [ -c /dev/tty ]; then
        echo "" 2> /dev/null
    else
        crit_echo "Error: non-interactive mode"
        return 1
    fi
    local dir="${1:-.}"
    shift
    local keywords=("$@")
    # Global line counter for pagination
    local PRINT_COUNT=0
    local PAGE_LIMIT=150
    # Internal recursive function
    _print_tree() {
        local current_dir="$1"
        local indent="$2"
        local items=()
        local i=0
        # Read directory contents into an array
        while IFS= read -r -d '' item; do
            items+=("$item")
        done < <(find "$current_dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
        local count=${#items[@]}
        local last_index=$((count - 1))
        for ((i=0; i<count; i++)); do
            local item="${items[$i]}"
            local name=$(basename "$item")
            local connector="├── "
            local next_indent="│   "
            if [ $i -eq $last_index ]; then
                connector="└── "
                next_indent="    "
            fi
            # --
            local should_print=0
            if [ -d "$item" ]; then
                # Always print directories to keep tree structure
                should_print=1
            elif [ ${#keywords[@]} -eq 0 ]; then
                # No keywords: print all files
                should_print=1
            else
                # Keywords exist: print file ONLY if it matches
                for kw in "${keywords[@]}"; do
                    if [[ "$name" == *"$kw"* ]]; then
                        should_print=1
                        break
                    fi
                done
            fi
            # --
            if [ $should_print -eq 1 ]; then
                echo -e "${indent}${connector}${name}"
                ((PRINT_COUNT++))
                # Pagination Check: Prompt every PAGE_LIMIT lines
                if (( PRINT_COUNT % PAGE_LIMIT == 0 )); then
                    echo -n $'\n'"--- Press any key to continue (Ctrl+C to exit) ---"$'\n'
                    # Read from /dev/tty to ensure we get keyboard input
                    # -n 1: read 1 char, -s: silent, -r: raw                    
                    if ! read -n 1 -s -r < /dev/tty; then
                        # Handle Ctrl+C or EOF gracefully
                        echo ""
                        _codex_unset
                        return 1
                    fi
                    echo "" # Newline after keypress
                fi
            fi
            # Recurse if directory
            if [ -d "$item" ]; then
                _print_tree "$item" "${indent}${next_indent}"
            fi
        done
    }
    # Validate input directory
    if [ ! -d "$dir" ]; then
        crit_echo "Error: '$dir' is not a valid directory." >&2
        _codex_unset
        return 1
    fi
    # Print root
    echo "$(basename "$dir")"
    ((PRINT_COUNT++))
    _print_tree "$dir" ""
    _codex_unset
}   

# REFACTORED >>>
function renameFile {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 2 ]; then
        ls -a
        warn_echo "Usage: renameFile <current_filename> <new_filename>"
        return 1
    fi
    local old_filename="$1"
    local new_filename="$2"
    # Check that the source exists, including symlinks.
    if [[ ! -e "$old_filename" && ! -L "$old_filename" ]]; then
        crit_echo "Error: Source file does not exist: $old_filename"
        _codex_unset
        return 1
    fi
    # --- Check for Collision ---
    if [[ -e "$new_filename" || -L "$new_filename" ]]; then
        # If old and new are literally the same path, do nothing.
        if [[ "$old_filename" == "$new_filename" ]]; then
            echo "Source and destination are identical. No action taken."
        else
            warn_echo "Target already exists: $new_filename"
            crit_echo "Operation Cancelled"
        fi
        _codex_unset
        return 0
    fi
    # --- Perform Rename ---
    if token_prompt "Confirm Renaming" "$old_filename to $new_filename"; then
        if auto_escalate mv -- "$old_filename" "$new_filename"; then
            echo "Renamed: $old_filename -> $new_filename"
            _codex_unset
            return 0
        else
            warn_echo "Error: Failed to rename file"
            _codex_unset
            return 1
        fi
    fi
    _codex_unset
    return 0
}
function createFile {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a
        warn_echo "Usage: createFile <filename>"
        _codex_unset
        return 1
    fi
    local filename="$1"
    # Quote "$filename" to handle spaces
    local absolute_path="$(get_abs_path "$filename")"
    if [[ -f "$absolute_path" ]]; then
        warn_echo "File Already Exists: $absolute_path"  
        _codex_unset
        return 0
    fi 
    if ! create_intermediate_dirs "$absolute_path"; then
        crit_echo "Error: Could not create directories for '$absolute_path'"
        _codex_unset
        return 1
    fi
    if auto_escalate touch "$absolute_path"; then
        good_echo "Created file: $absolute_path"
        _codex_unset 
        return 0
    else
        crit_echo "Error: Failed to create file '$absolute_path'"
        _codex_unset
        return 1
    fi
}   
function createFolder {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a
        warn_echo "Usage: createFolder <foldername>"
        return 1
    fi
    local foldername="$1"
    local absolute_path="$(get_abs_path "$foldername")"
    # --- Check Existence & Create ---
    # Check if a FILE with the same name exists (safety check)
    if [[ -e "$absolute_path" && ! -d "$absolute_path" ]]; then
        crit_echo "Error: A file with this name already exists: $absolute_path"
        _codex_unset
        return 1
    fi
    if [[ -d "$absolute_path" ]]; then
        warn_echo "Folder already exists: $absolute_path"
        _codex_unset 
        return 0
    fi
    # The '--' protects against folder names starting with '-'
    if auto_escalate mkdir -- "$absolute_path"; then
        echo "Created folder: $absolute_path"
        _codex_unset
        return 0
    else
        crit_echo "Error: Failed to create folder '$absolute_path'"
        _codex_unset
        return 1
    fi
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
        _codex_unset
        return 0
    fi
    # 2. Check Existence
    if [ ! -d "$target_path" ]; then
        crit_echo "Error: Directory '$target_path' does not exist or is not a directory."
        _codex_unset
        return 1
    fi
    # 3. Gather Information (Size & Contents)
    # Get human-readable size
    local dir_size
    dir_size=$(du -sh "$target_path" 2>/dev/null | cut -f1)
    # Count items
    local item_count
    item_count=$(find "$target_path" -mindepth 1 | wc -l | tr -d ' ')
    info_echo "--- Deletion Preview ---"
    echo "Target: $target_path"
    echo "Total Size: $dir_size"
    echo "Items to delete: $item_count"
    if ! token_prompt "Confirm deletion" "this action is irreversible" ; then 
        _codex_unset
        return 1
    fi
    if auto_escalate rm -rf "$target_path"; then 
        good_echo "Deletion Successful"
        _codex_unset
        return 0
    else
        crit_echo "Deletion Failed"
        _codex_unset
        return 1
    fi
}
function deleteFile { 
    source "$_SCRIPT_DIR/_codex.sh"
    local target_path="${1:-}"
    if [ -z "$target_path" ]; then
        ls -a
        echo "Usage: deleteFile <path>"
        _codex_unset
        return 0
    fi
    # --
    if [ ! -f "$target_path" ]; then
        if [ -d "$target_path" ]; then
            crit_echo "Error: '$target_path' is a directory. Use deleteFolder instead."
        else
            crit_echo "Error: File '$target_path' does not exist."
        fi
        _codex_unset
        return 1
    fi
    # -- 
    local file_size
    file_size=$(du -h "$target_path" 2>/dev/null | cut -f1)
    info_echo "--- Deletion Preview ---"
    echo "Target: $target_path"
    echo "Size: $file_size"
    if ! token_prompt "Confirm deletion" "this is irreversible"; then
        _codex_unset
        return 1
    fi
    if auto_escalate rm -f "$target_path"; then
        good_echo "Deletion Successful"
        _codex_unset
        return 0
    else
        crit_echo "Deletion Failed"
        _codex_unset
        return 1
    fi
}   
function createFromTemplate { 
    source "$_SCRIPT_DIR/_codex.sh"    
    # Validate arguments
    if [[ "$#" -ne 2 ]]; then
        info_echo "Available Templates (~/Templates): "
        ls ~/Templates
        warn_echo "Usage: createFromTemplate <template_name> <destination_path>"
        _codex_unset
        return 0
    fi
    local template_name="$1"
    local dest_path="$2"
    local template_source=~/Templates/"$template_name"
    local new_absolute_path
    new_absolute_path="$(get_abs_path "$dest_path")"
    # Check if source exists (file OR directory)
    if [[ ! -e "$template_source" ]]; then
        echo "Error: Template '$template_name' not found in ~/Templates/"
        ls ~/Templates -l
        _codex_unset
        return 1
    fi
    # Check if destination already exists
    if [ -e "$new_absolute_path" ]; then 
        crit_echo "Destination Already Exists: $new_absolute_path"
        _codex_unset
        return 1
    fi
    # Create parent directories for the destination if they don't exist
    # This is crucial for recursive structures where parents might not exist
    create_intermediate_dirs "$new_absolute_path"
    # Perform Recursive Copy if source is a directory, otherwise single file copy
    if [[ -d "$template_source" ]]; then
        info_echo "Detected directory template. Copying recursively..."
        # cp -r copies the directory and all its contents
        if ! auto_escalate cp -r --verbose "$template_source" "$new_absolute_path"; then 
            warn_echo "Failed to create the template directory structure"
            _codex_unset 
            return 1
        fi
    else
        info_echo "Detected file template. Copying single file..."
        if ! auto_escalate cp --verbose "$template_source" "$new_absolute_path"; then 
            warn_echo "Failed to create the template file"
            _codex_unset 
            return 1
        fi
    fi
    good_echo "Template Created Successfully at: $new_absolute_path"
    _codex_unset
    return 0
} 
function createLink {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 2 ]; then 
        ls -a
        warn_echo "Usage: createLink <original_path> <link_name>"
        _codex_unset
        return 1
    fi 
    local original_path link_name
    original_path="$1"
    link_name="$2"
    info_echo "Creating a Symlink"
    echo "Original : $original_path"
    echo "Symlink : $link_name"
    echo "Output Directory : $PWD"
    if ! token_prompt "Confirmation" "are you sure to create this symlink $link_name?" ; then 
        _codex_unset
        return 0
    fi 
    if ! auto_escalate ln -s "$original_path" "$link_name"; then
        _codex_unset
        crit_echo "failed to create the symlink"
        return 1
    fi
    _codex_unset
}

# END