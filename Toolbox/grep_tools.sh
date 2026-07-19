# BEGIN : Toolbox/grep_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. grep cli tool

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Standart Output Filtering Tools { Grep }"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "<command> | smartGrep" "apply filters on output of command using pre-defined filters" $width
    toolbox_item 'setMatches "keyword1|keyword2|..."' "set positive filter matches" $width
    toolbox_item 'addMatch <keyword>' "increment one string/keyword to the filter" $width
    toolbox_item 'setFilters "keyword1|keyword2|..."' "set excluding matches" $width
    toolbox_item 'addFilter <keyword>' "increment one string/keyword to the excluding filter" $width
    toolbox_item 'saveSmartGrep <filename>' "save the filters to file" $width
    toolbox_item 'loadSmartGrep <filename>' "load the filters from file" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    #inventory_title "7z {File Compression}"
    #local width=9
    #inventory_item 1 "7z x" "extracts a compressed file preserving the folder structure" $width
    #inventory_item 2 "7z e <archive> <path_in_archive> -o<out_dir>" "extracts a single file from compressed archive" $width
    #inventory_item 3 "7z t" "test file integrity" $width
    #inventory_endl 
    _codex_unset
}

# -- implementations 
function setMatches {
    source "$_SCRIPT_DIR/_codex.sh"
    local input="$1"
    if [[ -z "$input" ]]; then # Allow clearing the variable with no argument
        _matches=""
        echo "Matches pattern cleared."
        _codex_unset
        return 0
    fi
    _matches="$input"
    good_echo "Matches pattern set to: $_matches"
    _codex_unset
    return 0
}
function setFilters {
    source "$_SCRIPT_DIR/_codex.sh"
    local input="$1"
    if [[ -z "$input" ]]; then # Allow clearing the variable with no argument
        _filters=""
        echo "Filters pattern cleared."
        _codex_unset
        return 0
    fi
    _filters="$input"
    crit_echo "Filters pattern set to: $_filters"
    _codex_unset
    return 0
}
function smartGrep {
    source "$_SCRIPT_DIR/_codex.sh"
    local output=""
    local has_data=false
    # Check if stdin is a pipe (not a terminal)
    # -t 0 returns true if fd 0 (stdin) is a terminal, false if piped
    if [[ ! -t 0 ]]; then
        # Read from pipe
        output=$(cat)
        has_data=true
        echo "Reading from pipe..."
    elif [[ -n "$1" ]]; then
        # Execute command from argument
        echo "Executing command: $1"
        output=$("$1" 2>&1) || { echo "Command failed: $1"; return 1; }
        has_data=true
    else
        echo "No command provided and no pipe detected."
        echo "Usage: command | smartGrep  OR  smartGrep 'command'"
        echo "matches: $_matches"
        echo "filters: $_filters"
        _codex_unset
        return 1
    fi
    # Apply INCLUSION filter (matches to KEEP)
    if [[ -n "$_matches" ]]; then
        echo "matches: $_matches"
        output=$(echo "$output" | grep -iE "$_matches")
    fi
    # Apply EXCLUSION filter (filters to REMOVE)
    if [[ -n "$_filters" ]]; then
        echo "filters: $_filters"
        echo "$output" | grep -ivE "$_filters"
    else
        echo "filters: $_filters"
        echo "$output"
    fi
}
function addMatch {
    source "$_SCRIPT_DIR/_codex.sh"
    local input="$1"
    # Validate input is not empty
    if [[ -z "$input" ]]; then
        warn_echo "No pattern provided to addMatches."
        _codex_unset
        return 1
    fi
    # Append to global variable with OR separator if it already has content
    if [[ -n "$_matches" ]]; then
        _matches="${_matches}|${input}"
    else
        _matches="$input"
    fi
    good_echo "Matches updated: $_matches"
    _codex_unset
    return 0
}
function addFilter {
    source "$_SCRIPT_DIR/_codex.sh"
    local input="$1"
    # Validate input is not empty
    if [[ -z "$input" ]]; then
        warn_echo "No pattern provided to addFilters."
        _codex_unset
        return 1
    fi
    # Append to global variable with OR separator if it already has content
    if [[ -n "$_filters" ]]; then
        _filters="${_filters}|${input}"
    else
        _filters="$input"
    fi
    crit_echo "Filters updated: $_filters"
    _codex_unset
    return 0
}   
function saveSmartGrep {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a
        warn_echo "USAGE: saveSmartGrep <filename>"
        _codex_unset
        return 0
    fi 
    local filename="$1"
    # Validate that we have patterns to save
    if [[ -z "$_matches" && -z "$_filters" ]]; then
        warn_echo "No patterns to save."
        _codex_unset
        return 1
    fi
    # Use printf %q to safely escape special characters for shell re-evaluation
    # This ensures regex characters like |, *, $ don't break the config file
    {
        echo "# SmartGrep Configuration"
        echo "# Generated on $(date)"
        echo "_matches=$(printf '%q' "$_matches")"
        echo "_filters=$(printf '%q' "$_filters")"
    } > "$filename"

    info_echo "Configuration saved to: $filename"
    _codex_unset
    return 0
}
function loadSmartGrep {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        ls -a 
        warn_echo "USAGE: loadSmartGrep <filename>"
        _codex_unset
        return 0
    fi 
    local filename="$1"
    if [[ ! -f "$filename" ]]; then
        crit_echo "Config file not found: $filename"
        return 1
    fi
    # Source the file to restore variables
    # shellcheck disable=SC1090
    source "$filename"
    info_echo "Configuration loaded from: $filename"
    info_echo "  Matches: $_matches"
    info_echo "  Filters: $_filters"
    _codex_unset
    return 0
}   

# END