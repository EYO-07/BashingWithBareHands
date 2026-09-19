# BEGIN ~/Toolbox/move_copy_delete_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- global variables 
_STARTING_DIR=""

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=3
    toolbox_title "File Move/Copy/Delete Tools"
    toolbox_item "tools" "print this ..." $width
    if all_commands_valid "cp" "touch" "rm" "mkdir"; then 
        toolbox_item "fileMove" "select files to be moved" $width
        toolbox_item "fileCopy" "select files to be copied" $width
        toolbox_item "fileDelete" "select files to be deleted" $width
    else
        crit_echo "... missing basic filesystem commands: cp, rm, ..."
    fi 
    toolbox_endl
    _codex_unset
}
tools 

# -- helpers
__estimate_size() { # __estimate_size <array_reference>
    local -n _est_files="$1"
    local total_bytes=0   
    for path in "${_est_files[@]}"; do
        if [[ -e "$path" ]]; then
            # Usa du -sb para obter o tamanho exato em bytes (recursivo para diretórios)
            local path_size
            path_size=$(du -sb "$path" 2>/dev/null | awk '{print $1}')
            if [[ "$path_size" =~ ^[0-9]+$ ]]; then
                total_bytes=$((total_bytes + path_size))
            fi
        fi
    done
    echo "$total_bytes"
}
__has_enough_space() { # __has_enough_space <dest_path> <size>
    local dest_path="$1"
    local required_size="$2"
    # Encontra um diretório ancestral existente para consultar o espaço em disco
    local target_dir="$dest_path"
    while [[ ! -d "$target_dir" && "$target_dir" != "/" ]]; do
        target_dir="$(dirname "$target_dir")"
    done
    [[ -d "$target_dir" ]] || target_dir="/"
    # Obtém os bytes disponíveis no sistema de ficheiros (df -P -B1 para blocos de 1 byte)
    local avail_bytes
    avail_bytes=$(df -P -B1 "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    # Validação de segurança dos valores numéricos
    if [[ ! "$avail_bytes" =~ ^[0-9]+$ ]] || [[ ! "$required_size" =~ ^[0-9]+$ ]]; then
        return 1 # Falha na leitura do espaço
    fi
    # Compara o espaço disponível com o tamanho necessário (com margem de segurança opcional de 1%)
    if (( avail_bytes >= required_size )); then
        return 0
    fi
    return 1
}

# -- implementation 
function fileMove {
    source "$_SCRIPT_DIR/_codex.sh"
    [[ -z "$HOME" ]] && return 1
    # -- file selection 
    local chosen_files=()
    INTERACTIVE_FILESELECT_MULT chosen_files "Files to move:"
    if (( ${#chosen_files[@]} == 0 )); then
        crit_echo "... no files selected"
        _codex_unset
        return 0
    fi
    if ! yn_prompt "Confirmation" "proceed?"; then
        _codex_unset
        return 0
    fi
    # -- drop directory selection 
    local chosen_dir=""
    INTERACTIVE_FILESELECT_SINGLE chosen_dir "Please select drop directory:"
    if [[ ! -d "$chosen_dir" ]]; then
        crit_echo "... $chosen_dir not a valid directory"
        _codex_unset
        return 1
    fi
    local abs_dest
    abs_dest=$(get_abs_path "$chosen_dir")
    # -- validation || path check 
    local validated_files=()
    for file in "${chosen_files[@]}"; do
        local abs_src
        abs_src=$(get_abs_path "$file")
        if [[ ! -e "$abs_src" ]]; then
            crit_echo "ERROR: Source file does not exist: $file"
            _codex_unset
            return 1
        fi
        if [[ "$abs_dest" == "$abs_src" || "$abs_dest" == "$abs_src/"* ]]; then
            crit_echo "ERROR: Cannot move a directory into itself or its subdirectory: $file -> $chosen_dir"
            _codex_unset
            return 1
        fi
        validated_files+=("$abs_src")
    done
    # -- validation || space check 
    local est_size=$(__estimate_size validated_files)
    if ! __has_enough_space "$abs_dest" "$est_size"; then 
        crit_echo "... destination don't have enough available space."
        _codex_unset
        return 1
    fi 
    # -- confirmation
    warn_echo "Drop Directory: $abs_dest"
    warn_echo "... files to be moved"
    for file in "${validated_files[@]}"; do
        echo "  - $file"
    done
    if ! token_prompt "Confirmation" "moving those files?"; then
        _codex_unset
        return 0
    fi 
    good_echo "... moving files"
    if mv -- "${validated_files[@]}" "$abs_dest"; then
        good_echo "... files moved successfully"
    else
        crit_echo "... error moving some files"
    fi
    _codex_unset
}
function fileCopy {
    source "$_SCRIPT_DIR/_codex.sh"
    [[ -z "$HOME" ]] && return 1
    # -- file selection 
    local chosen_files=()
    INTERACTIVE_FILESELECT_MULT chosen_files "Files to copy:"
    if (( ${#chosen_files[@]} == 0 )); then
        crit_echo "... no files selected"
        _codex_unset
        return 0
    fi
    if ! yn_prompt "Confirmation" "proceed to copying?"; then
        _codex_unset[cite: 1]
        return 0
    fi
    # -- drop directory selection 
    local chosen_dir=""
    INTERACTIVE_FILESELECT_SINGLE chosen_dir "Please select drop directory:"
    if [[ ! -d "$chosen_dir" ]]; then
        crit_echo "... $chosen_dir not a valid directory"
        _codex_unset
        return 1
    fi
    local abs_dest
    abs_dest=$(get_abs_path "$chosen_dir")
    # -- validation || path check 
    local validated_files=()
    for file in "${chosen_files[@]}"; do
        local abs_src
        abs_src=$(get_abs_path "$file")
        if [[ ! -e "$abs_src" ]]; then
            crit_echo "ERROR: Source file does not exist: $file"
            _codex_unset
            return 1
        fi
        if [[ "$abs_dest" == "$abs_src" || "$abs_dest" == "$abs_src/"* ]]; then
            crit_echo "ERROR: Cannot copy a directory into itself or its subdirectory: $file -> $chosen_dir"
            _codex_unset
            return 1
        fi
        validated_files+=("$abs_src")
    done
    # -- validation || space check 
    local est_size=$(__estimate_size validated_files)
    if ! __has_enough_space "$abs_dest" "$est_size"; then 
        crit_echo "... destination don't have enough available space."
        _codex_unset
        return 1
    fi 
    # -- confirmation
    warn_echo "Drop Directory: $abs_dest"
    warn_echo "... files to be copied"
    for file in "${validated_files[@]}"; do
        echo "  - $file"
    done
    if ! token_prompt "Confirmation" "copying those files?"; then
        _codex_unset
        return 0
    fi 
    good_echo "... copying files"
    if cp -rP -- "${validated_files[@]}" "$abs_dest"; then
        good_echo "... files copied successfully"
    else
        crit_echo "... error copying some files"
    fi
    _codex_unset
}
function fileDelete {
    source "$_SCRIPT_DIR/_codex.sh"
    [[ -z "$HOME" ]] && return 1
    local chosen_files=()
    INTERACTIVE_FILESELECT_MULT chosen_files "Files to delete:"
    if (( ${#chosen_files[@]} == 0 )); then
        crit_echo "... no files selected"
        _codex_unset
        return 0
    fi
    # Safety validation: Resolve and check all paths before prompting
    local validated_files=()
    for file in "${chosen_files[@]}"; do
        local abs_path
        abs_path=$(get_abs_path "$file")
        # Block critical system directories, their subpaths, and trailing slashes using wildcards
        case "$abs_path" in
            / | \
            /etc | /etc/* | \
            /bin | /bin/* | \
            /sbin | /sbin/* | \
            /usr | /usr/* | \
            /var | /var/* | \
            /boot | /boot/* | \
            /sys | /sys/* | \
            /proc | /proc/* | \
            /dev | /dev/* | \
            /lib | /lib/* | \
            /lib64 | /lib64/* | \
            /root | /root/*)
                crit_echo "ERROR: Deletion of protected system path or its contents is blocked: $abs_path"
                _codex_unset
                return 1
                ;;
            "$HOME" | "$HOME"/)
                crit_echo "ERROR: Deletion of your home directory is blocked: $abs_path"
                _codex_unset
                return 1
                ;;
            *)
                validated_files+=("$abs_path")
                ;;
        esac
    done
    if ! yn_prompt "Confirmation" "proceed to deletion?"; then
        _codex_unset
        return 0
    fi
    warn_echo "... files to be deleted"
    for file in "${validated_files[@]}"; do
        echo "  - $file"
    done
    if ! token_prompt "Confirmation" "deleting those files?"; then
        _codex_unset
        return 0
    fi    
    good_echo "... deleting files"
    if rm -rf -- "${validated_files[@]}"; then
        good_echo "... files deleted successfully"
    else
        crit_echo "... error deleting some files"
    fi
    _codex_unset
}

# END