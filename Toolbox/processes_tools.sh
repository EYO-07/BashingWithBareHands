# BEGIN : processes_tools.sh
# ... tasks, processes, etc
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# linux built-in tools like pid, pidof, ps, pgrep

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Processes/Tasks Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "processMatch <keyword>" "show processes matching the keyword" $width
    toolbox_item "processTop [cpu|mem]" "show top 10 processes by CPU or memory" $width
    toolbox_item "processInfo <pid>" "show detailed info for a specific PID" $width
    toolbox_item "forceKillProcess <pid>" "force kill process by pid" $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Processes/Tasks Tools"
    local width=3
    inventory_item 1 "pgrep <name>" "search process by name" $width
    inventory_item 2 "pidof <name>" "return the process id" $width
    inventory_item 3 "kill <pid>" "kill process by process id" $width
    inventory_endl 
    _codex_unset
    return 0
}

# -- implementation
function processTop {
    source "$_SCRIPT_DIR/_codex.sh"
    local sort_by="${1:-cpu}"
    info_echo "--- Top 10 Processes by $sort_by ---"
    case "$sort_by" in
        cpu) ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -11 ;;
        mem) ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -11 ;;
        *) echo "USAGE: processTop [cpu|mem]" >&2; _codex_unset; return 1 ;;
    esac
    _codex_unset
}
function processInfo {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 1 ]; then
        echo "USAGE: processInfo <pid>" >&2
        _codex_unset
        return 1
    fi
    ps -fp "$1"
    echo ""
    echo "--- Memory Details ---"
    cat /proc/"$1"/status 2>/dev/null | grep -E "VmSize|VmRSS|VmSwap" || echo "Process not found"
    _codex_unset
}
function processMatch {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check if exactly one keyword is provided
    if [ "$#" -ne 1 ]; then
        warn_echo "USAGE: processMatch <keyword>" >&2
        _codex_unset
        return 1
    fi
    local keyword="$1"
    # Capture output: 
    # -w: Wide output (prevents truncation of command line)
    # -o pid,args: Show PID and full command line arguments
    # tolower($0) ~ tolower(kw): Performs case-insensitive matching
    local result
    result=$(ps -eo pid,args -w -w | awk -v kw="$keyword" 'tolower($0) ~ tolower(kw) && !/awk/')
    # If result is not empty, print it and return 0
    if [ -n "$result" ]; then
        echo ""
        info_echo "--- processes matching $1 ---"
        echo "$result"
        echo ""
        _codex_unset
        return 0
    fi
    # No matches found
    _codex_unset
    return 1
}   
function forceKillProcess {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check argument count
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: forceKillProcess <pid>"
        _codex_unset
        return 1
    fi
    local pid="$1"
    # Validate PID is a number
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: PID must be a positive integer."
        _codex_unset
        return 1
    fi
    # Check if process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "ERROR: Process with PID $pid does not exist."
        _codex_unset
        return 1
    fi
    # Get process name for display
    local process_name
    process_name=$(ps -p "$pid" -o comm= 2>/dev/null)
    # Confirmation dialog
    echo "WARNING: You are about to forcefully terminate the following process:"
    echo "  PID:  $pid"
    echo "  Name: ${process_name:-<unknown>}"
    echo ""
    read -p "Are you sure you want to send SIGKILL to this process? [y/N]: " confirm
    case "$confirm" in
        [Yy]|[Yy][Ee][Ss])
            echo "Sending SIGKILL to PID $pid..."
            if kill -KILL "$pid" 2>/dev/null; then
                echo "SUCCESS: Process $pid terminated."
                _codex_unset
                return 0
            else
                echo "ERROR: Failed to kill process $pid. Permission denied or process already gone."
                _codex_unset
                return 1
            fi
            ;;
        *)
            echo "Operation cancelled."
            _codex_unset
            return 1
            ;;
    esac
    _codex_unset
}   

# END 






