# BEGIN : ~/Toolbox/filesystem_tools.sh 

# -- dependencies
# 1. 7z : compressing and extracting tools 

# -- description
echo ""
echo "=== Filesystem Tools ==="
echo "createFileFromTemplate : create a template file from ~/Template folder "
echo "getHashInfo : sha256 and other useful hashs for a file"
echo "getSize : estimate or get metadata of filesize of folder or file"
echo "showMetadata : show metadata info for file or folder"
echo "createBackup : create a compressed backup file for file or folder naming with datetime stamp"
echo "restoreBackup <archive_file.7z> [output_directory] : ..."
echo "restoreBackup <archive_file.7z> : ... current directory"
echo "viewBackupContents : view the contents of a compressed archive"
echo ""

# -- implementation
function createFileFromTemplate { # create a template file from ~/Template folder 
    if [[ "$#" -ne 2 ]]; then
        ls ~/Templates -l
        return 
    fi
    if [[ ! -f ~/Templates/"$1" ]]; then
        echo "Error: Template '$1' not found in ~/Templates/"
        ls ~/Templates -l
        return 
    fi
    cp --interactive --verbose ~/Templates/"$1" ./"$2"
}
function getHashInfo { # sha256 and other useful hashs for a file
    # sha256 and other useful hashes for a file
    # Usage: getHashInfo <filename>
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: getHashInfo <filename>"
        return 1
    fi
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found or is not a regular file."
        return 1
    fi
    echo ""
    echo "--- Hash Information for: $file ---"
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
}
function getSize { # estimate or get metadata of filesize of folder or file 
    # estimate or get metadata of filesize of folder or file 
    # Usage: getFileSize <path>
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: getFileSize <path>"
        return 1
    fi
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo "Error: Path '$path' does not exist."
        return 1
    fi
    echo ""
    echo "--- Size Information for: $path ---"
    if [[ -d "$path" ]]; then
        # Directory: Use du for apparent size and disk usage
        echo "Type: Directory"
        echo -n "Apparent Size (human readable): "
        du -sh "$path" | cut -f1
        echo -n "Disk Usage (blocks): "
        du -s "$path" | cut -f1
        echo "File Count:"
        find "$path" -type f | wc -l
    else
        # File: Use stat for precise byte count and du for blocks
        echo "Type: File"
        echo -n "Exact Size (bytes): "
        stat -c %s "$path" 2>/dev/null || stat -f %z "$path" 2>/dev/null # Handles Linux/macOS
        echo -n "Human Readable: "
        du -h "$path" | cut -f1
        echo -n "Disk Blocks Used: "
        du -s "$path" | cut -f1
    fi
}
function showMetadata { # show metadata info for file or folder
    # show metadata info for file or folder
    # Usage: showMetadata <path>
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: showMetadata <path>"
        return 1
    fi
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo "Error: Path '$path' does not exist."
        return 1
    fi
    # Standard POSIX/Linux Metadata using stat
    echo ""
    echo "--- System Metadata : $path ---"
    # Using stat with format options (Linux specific mostly, %z is modify time)
    # For macOS compatibility, one might need 'stat -f' syntax, but sticking to GNU stat for Linux context
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
    echo -e "\n--- File Type Detection ---"
    file -b "$path"
}
function createBackup { # create a compressed backup file for file or folder naming with datetime stamp
    if [ -z "$1" ]; then
        echo "Error: No source path provided."
        echo "Usage: createBackup <path_to_file_or_folder>"
        return 1
    fi
    local source="$1"
    if [ ! -e "$source" ]; then
        echo "Error: Source '$source' does not exist."
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
        echo "Backup created successfully: $archive_name"
        return 0
    else
        echo "Error: Backup creation failed."
        return 1
    fi
}
function restoreBackup { # extract the contents of a backup file 
    if [ -z "$1" ]; then
        echo "Error: No archive file provided."
        echo "Usage: restoreBackup <archive_file.7z> [output_directory]"
        return 1
    fi
    local archive="$1"
    local output_dir="${2:-.}" # Default to current directory if not specified
    if [ ! -f "$archive" ]; then
        echo "Error: Archive '$archive' not found."
        return 1
    fi
    echo "Restoring '$archive' to '$output_dir'..."
    # -o: Set output directory
    # -y: Assume Yes on all queries (overwrite without prompt)
    if 7z x -y -o"$output_dir" "$archive"; then
        echo "Restore completed successfully."
        return 0
    else
        echo "Error: Restore failed."
        return 1
    fi
}
function viewBackupContents { # view the contents of a compressed archive
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

# END