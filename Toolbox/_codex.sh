# BEGIN : Toolbox/_codex.sh
# ... this file is the framework for bashing with bare hands.
# ... those functions are intended to be called inside functions.
# ... source the script inside the function scope to prevent namespace pollution.
# ... why is called _codex ?
# Spellcrafting Paradigm : Concept Mapping 
# 1. Spellcasting : Spell is a function and casting is the use of the appropriate syntax.
# 2. Oracles : Are the LLM's, a wizard should use it to craft new spells or consulting.
# 3. Grimoires : list of existing spells, generaly crafted as a `cheat sheet comment block` format with aid of oracules. Grimoires can be safely handled by oracles. 
# 4. Golems : the golem is the manually crafted part of code, managed primarly by humans, the golem should be as close as possible (have the form) of the project's logic. Golem could be the main file or any other file intended for this purpose.
# 5. Codex : the codex are the crafted spells (framework).
# 6. LLM Spellcrafting : humans design the spell (syntax) and ask for implementation for oracles.
# 7. Golem Sculpting : can be or not be made by LLM's, golem sculpting is the creation of dummy and placeholder classes and functions for your project, it will be the 'skeleton' of your project.
# 8. Golem Infusion : is the implementation of the dummies and placeholders of your project.
# 9. Golem Craft : is the programming itself, the main objective of a wizard is the golem creation, the golem is the program which is designed to do some hard work. 
# 10. Divination : Oracle consulting.
# 11. Library : Official Documentation, Search Engines.

# >> how to import
# ... as global variable
# _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ... inside a function 
# source "$_SCRIPT_DIR/_codex.sh"
# ... as the last command of this function 
# _codex_unset
#
# ... suggestion : tools to print the toolbox, inv to print inventories
function _codex_unset {
    unset -f color_echo warn_echo crit_echo info_echo
    unset -f toolbox_title toolbox_item toolbox_endl 
    unset -f inventory_title inventory_item inventory_endl 
    unset -f token_prompt yn_prompt
    unset -f get_tracking_file save_to_tracking_file parse_variable_from_tracking_file
}

# -- color echos
function color_echo {
    if [ $# -eq 0 ]; then 
        echo "USAGE: color_echo <echo text>"
        echo "USAGE: color_echo <forecolor_num> <echo text>"
        echo "USAGE: color_echo <forecolor_num> <background_num> <echo text>"
        echo "foreground background color"
        echo "31 41 red"
        echo "32 42 green"
        echo "33 43 yellow"
        echo "34 44 blue"
        echo "35 45 magenta"
        echo "36 46 cyan"
        echo "37 47 white"
        return
    fi
    # Check NO_COLOR standard
    if [ "${NO_COLOR:-}" = "1" ]; then
        # Colors disabled globally
        if [ $# -eq 1 ]; then echo "$1"
        elif [ $# -eq 2 ]; then echo "$2"
        else shift 2; echo "$@"
        fi
        return
    fi
    local fg_color=$1
    local bg_color=$2 
    if [ $# -eq 1 ]; then 
        echo -e "\e[33m$1\e[0m"
    elif [ $# -eq 2 ]; then 
        echo -e "\e[${fg_color}m$2\e[0m"
    elif [ $# -ge 3 ]; then 
        shift 2
        echo -e "\e[${fg_color};${bg_color}m$@\e[0m"
    fi   
}
function warn_echo { color_echo 33 "$@"; }
function crit_echo { color_echo 31 "$@"; }
function info_echo { color_echo 36 "$@"; }
# -- inventories
# ... are small curated list of syntax : description 
function inventory_title {
    echo       ""
    echo       "Inventory : $@" 
    color_echo "-------------------------------------------------------------------"
}
function inventory_item {
    local title description separator indicator
    if [ $# -eq 3 ]; then 
        indicator="$(warn_echo $1'.')"
        shift
    else 
        indicator="$(warn_echo '->')"        
    fi  
    title="$1"
    separator="$(warn_echo ':')"
    shift
    description="$@"
    echo       "$indicator $title $separator $description"
}
function inventory_endl { echo ""; }  
function toolbox_title {
    echo       ""
    warn_echo "=== $@ ==="
}
function toolbox_item {
    local title description separator
    title="$1"
    separator="$(warn_echo ':')"
    shift
    description="$@"
    echo       "$title $separator $description"
}
function toolbox_endl { echo ""; }  
# -- prompt dialogs 
function token_prompt {
    # example : ...
    #if token_prompt "Delete Database" "This will destroy all data"; then
    #    echo "Confirmed. Deleting..."
    #else
    #    crit_echo "Operation aborted by user."
    #fi
    local title="$1"
    shift
    local description="$@"
    # CRITICAL: Check if running in an interactive terminal
    # If not (e.g., cron, pipe), fail safely to prevent hanging
    if [ ! -t 0 ]; then
        crit_echo "Error: Cannot confirm token in non-interactive mode."
        crit_echo "       Please run this script directly in a terminal."
        return 1
    fi
    local confirm_token user_input
    # Generate 6-character alphanumeric token
    confirm_token=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)
    echo ""
    # Check if title is empty or unset
    if [ -z "$title" ]; then
        title='Token Confirmation Dialog'
    fi
    warn_echo "$title : $description"
    echo "- please type the following token to confirm:"
    warn_echo ">>> $confirm_token <<<"
    # Read input silently? No, usually we want them to see what they type for tokens
    # unless it's a password. For confirmation tokens, visible input is standard.
    read -p "> " user_input
    if [ "$user_input" = "$confirm_token" ]; then
        color_echo 32 "Operation confirmed: token matched."
        echo ""
        return 0
    else
        crit_echo "Cancelled: token mismatch."
        echo ""
        return 1
    fi
}
function yn_prompt {
    local title="$1"
    shift
    local description="$@"
    if [ ! -t 0 ]; then
        crit_echo "Error: Cannot prompt in non-interactive mode."
        return 1
    fi
    warn_echo "${title:-Confirmation}: $description"
    read -p "[y/N] > " user_input
    case "$user_input" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}
# -- git-like directories
function get_tracking_file {
    # Only locate and return the path to the tracking file.
    # Usage: get_tracking_file <filename>
    # example : 
    # tracking_file=$(get_tracking_file ".myconfig") || exit 1
    # source "$tracking_file"
    # Output: echoes the full path to the file on success; returns 1 on failure.
    if [ $# -eq 0 ]; then 
        echo "USAGE: get_tracking_file <filename>" >&2
        return 1
    fi
    local current_dir="$PWD"
    local id_filename="$1"
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/$id_filename" ]; then
            echo "$current_dir/$id_filename"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    crit_echo "Error: '$id_filename' not found in this directory or any parent directories." >&2
    return 1
}
function save_to_tracking_file {
    # Save specific variables to the tracking file so they persist across sessions.
    # Usage: save_to_tracking_file <filename> <var1> [var2] [var3] ...
    # Example: save_to_tracking_file ".myconfig" DB_HOST API_KEY DEBUG_MODE
    if [ $# -lt 2 ]; then 
        crit_echo "USAGE: save_to_tracking_file <filename> <var1> [var2] ..."
        return 1
    fi
    local id_filename="$1"
    shift # Remove filename from arguments, leaving only variable names
    local vars_to_save=("$@")
    # 1. Locate existing file OR determine path for new file
    local target_file
    target_file=$(get_tracking_file "$id_filename")
    if [ -z "$target_file" ]; then
        # File doesn't exist yet; create it in the current directory
        target_file="$PWD/$id_filename"
        # Add at file creation
        touch "$target_file" || {
            crit_echo "Error: Cannot create tracking file '$target_file'."
            return 1
        }
        chmod 600 "$target_file"
        # Warn users
        warn_echo "Security: '$target_file' will be executed when sourced."
        warn_echo "         Permissions set to 600 (owner-only)."
        info_echo "Created new tracking file: $target_file"
    fi
    # 2. Append variables to the file
    # We use a temporary buffer to ensure we don't partially write on error
    local content_to_append=""
    for var_name in "${vars_to_save[@]}"; do
        # Check if variable is set
        if [ -z "${!var_name+x}" ]; then
            crit_echo "Warning: Variable '$var_name' is unset. Skipping."
            continue
        fi
        # Validate variable names
        if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            crit_echo "Error: Invalid variable name '$var_name'."
            continue
        fi
        # Safely extract the value using declare -p and parse it.
        # declare -p VAR outputs: declare -- VAR="value" (or declare -x if already exported)
        # We use eval to safely capture the value even if it contains spaces/quotes.
        local var_def
        var_def=$(declare -p "$var_name" 2>/dev/null) || {
            crit_echo "Error: Could not inspect variable '$var_name'."
            return 1
        }
        # Extract the value part. This regex handles the 'declare -- VAR="..."' format.
        # It strips the 'declare ... VAR=' prefix and keeps the quoted value.
        local value_expr
        value_expr="${var_def#*=}"
        # Construct the export line: export VAR_NAME=<value>
        # Since 'value_expr' is already quoted by declare -p, we can append it directly.
        content_to_append+="export ${var_name}=${value_expr}"$'\n'
    done
    # Write to file only if we have content
    if [ -n "$content_to_append" ]; then
        # 1. Create a secure temporary file in the SAME directory (ensures same filesystem for mv)
        local temp_file
        temp_file=$(mktemp "${target_file}.XXXXXX") || {
            crit_echo "Error: Cannot create temporary file."
            return 1
        }
        # 2. Set permissions on temp file immediately
        chmod 600 "$temp_file"
        # 3. Write content to temp file
        {
            echo "# Updated by save_to_tracking_file on $(date)"
            echo "$content_to_append"
        } > "$temp_file" || {
            rm -f "$temp_file"
            crit_echo "Error: Failed to write to temporary file."
            return 1
        }
        # 4. Atomically move temp file to target (prevents partial writes)
        mv "$temp_file" "$target_file" || {
            rm -f "$temp_file"
            crit_echo "Error: Failed to update tracking file."
            return 1
        }
        info_echo "Successfully saved variables to $target_file"
        return 0
    else
        crit_echo "No valid variables were saved."
        return 1
    fi   
}
function parse_variable_from_tracking_file {
    return 1 # todo
}

# END 