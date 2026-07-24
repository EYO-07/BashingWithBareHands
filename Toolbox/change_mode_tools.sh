# BEGIN : Toolbox/change_mode_tools.sh 
# ... aliases and helper function for chmod cli 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 
# Requires: bash, chmod, ls, stat (optional fallback used)

# -- description 
# A toolbox for managing file permissions with colored output.

function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=3
    toolbox_title "Change File Mode Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "showAttributes" "display file attributes" $width
    toolbox_item "activate" "turn script or file executable (chmod +x)" $width
    toolbox_item "deactivate" "turn off the executable attribute (chmod -x)" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "change mode tools"
    local width=6
    inventory_item 1 "chown <USER>:<GROUP> <FILE>" "change file ownership" $width
    inventory_item 2 "chmod <MODE> <FILE>" "change file permissions" $width
    inventory_endl 
    _codex_unset
}

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
    if [ "$#" -gt 0 ]; then
        echo -e "\e[${color}m$@\e[0m"
    else
        while IFS= read -r line; do
            echo -e "\e[${color}m${line}\e[0m"
        done
    fi
}
function warn_echo {
    color_echo 33 "$@"
}
function crit_echo {
    color_echo 31 "$@"
}

# -- implementation
function showAttributes { 
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 1 ]; then
        ls -a
        warn_echo "USAGE: showAttributes <file>"
        _codex_unset
        return 0
    fi
    local file="$1"    
    if [ ! -e "$file" ]; then
        crit_echo "Warning: '$file' does not exist."
        _codex_unset
        return 1 
    fi
    local stat_cmd stat_format
    stat_cmd="stat"
    stat_format="--format"
    # Extract details using the correct flag
    local fname ftype fowner fmode foctal
    fname=$($stat_cmd $stat_format="%N" "$file" | tr -d "'")
    ftype=$($stat_cmd $stat_format="%F" "$file")
    fowner=$($stat_cmd $stat_format="%U:%G" "$file")
    fmode=$($stat_cmd $stat_format="%A" "$file")
    foctal=$($stat_cmd $stat_format="%a" "$file")
    # Display
    echo ""
    color_echo 36 "$fname"
    echo "   * Type: $ftype"
    echo "   * Owner: $fowner"
    # Translate mode to plain English
    local desc=""
    if [[ $fmode == *r* ]]; then desc+="read"; fi
    if [[ $fmode == *w* ]]; then 
        [ -n "$desc" ] && desc+=", "
        desc+="write"
    fi
    if [[ $fmode == *x* ]]; then 
        [ -n "$desc" ] && desc+=", "
        desc+="execute"
    fi
    [ -z "$desc" ] && desc="none"
    echo "   * Permissions: $desc (Mode: $foctal)"
    echo ""
    _codex_unset
}
function activate { 
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then
        ls -a
        warn_echo "Usage: activate <file1> [file2] ..."
        _codex_unset
        return 0
    fi
    for file in "$@"; do
        if [ ! -e "$file" ]; then
            crit_echo "Error: '$file' does not exist."
            continue
        fi  
        # Try normal chmod first
        if ! chmod +x "$file" 2>/dev/null; then
            warn_echo "Permission denied. Attempting with sudo..."
            # Directly attempt sudo chmod. 
            # sudo will handle the password prompt interactively if needed.
            if sudo chmod +x "$file"; then
                color_echo 32 "Activated (sudo): $file"
            else
                crit_echo "Error: Failed to change permissions (sudo failed or cancelled)."
                _codex_unset
                return 1
            fi
        else
            color_echo 32 "Activated: $file"
        fi
    done
    _codex_unset
}
function deactivate { 
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then
        ls -a
        warn_echo "Usage: deactivate <file1> [file2] ..."
        _codex_unset
        return 0
    fi
    for file in "$@"; do
        if [ ! -e "$file" ]; then
            crit_echo "Error: '$file' does not exist."
            continue
        fi
        # Try normal chmod first
        if ! chmod -x "$file" 2>/dev/null; then
            warn_echo "Permission denied. Attempting with sudo..."
            # Directly attempt sudo chmod
            if sudo chmod -x "$file"; then
                color_echo 35 "Deactivated (sudo): $file"
            else
                crit_echo "Error: Failed to change permissions (sudo failed or cancelled)."
                _codex_unset
                return 1
            fi
        else
            color_echo 35 "Deactivated: $file"
        fi
    done
    _codex_unset
}   

# END   