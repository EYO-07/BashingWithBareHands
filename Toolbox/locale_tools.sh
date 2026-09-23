# BEGIN Toolbox/locale_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Keyboard/Language/Time Settings Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_endl
    _codex_unset
}

# -- implementation 

# END 