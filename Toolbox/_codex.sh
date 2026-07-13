# BEGIN : Toolbox/_codex.sh
# ... this file is the framework for bashing with bare hands.

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

# Tips:
# 1. Source the script inside the function scope to prevent namespace pollution

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
    title="$1"
    separator="$(warn_echo ':')"
    indicator="$(warn_echo '->')"
    shift
    description="$@"
    echo       "$indicator $title $separator $description"
}
function inventory_endl { echo ""; }  
# -- 
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
# --
function inventory_example {
    inventory_title 'journalctl { errors }'
    inventory_item 'journalctl -u' 'investigate journal entries by unit name'
    inventory_item 'journalctl -b' 'investigate journal entries from specific boot time'
    inventory_endl
}
function toolbox_example {
    toolbox_title "Filesystem Tools"
    toolbox_item "create_file" "create a file"
    toolbox_item "create_folder" "creates a folder"
    toolbox_item "deleteFile <path>" "safely deletes a file after confirming with a random token."
    toolbox_item "deleteFolder <path>" "recursively deletes a folder after confirming with a random token."
    toolbox_item "createFileFromTemplate" "create a template file from ~/Template folder"
    toolbox_item "getHashInfo" "sha256 and other useful hashs for a file"
    toolbox_item "getSize" "estimate or get metadata of filesize of folder or file"
    toolbox_item "showMetadata" "show metadata info for file or folder"
    toolbox_item "createBackup" "create a compressed backup file for file or folder naming with datetime stamp"
    toolbox_item "restoreBackup <archive_file.7z> [output_directory]" '...'
    toolbox_item "restoreBackup <archive_file.7z>" '... current directory'
    toolbox_item "viewBackupContents" "view the contents of a compressed archive"
    toolbox_endl
}

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

# -- git-like directories
# ... todo

















# END 