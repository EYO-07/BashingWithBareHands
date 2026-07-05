# BEGIN : processes_tools.sh
# ... tasks, processes, etc

# -- dependencies

# -- description

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
    echo -e "\e[${color}m$@\e[0m"
}

echo ""
color_echo 33 "=== Processes/Task Tools ==="
echo "processMatch <keyword>     : show processes matching the keyword"
echo "processTop [cpu|mem]       : show top 10 processes by CPU or memory"
echo "processInfo <pid>          : show detailed info for a specific PID"
echo "forceKillProcess <pid>     : force kill process by pid"
echo "--- built-in linux commands ---" 
echo "pgrep <name> : search process by name"
echo "pidof <name> : return the process id"
echo "kill <pid> : kill process by process id"
echo ""

# -- implementation
function processTop {
    local sort_by="${1:-cpu}"
    echo ""
    echo "--- Top 10 Processes by $sort_by ---"
    case "$sort_by" in
        cpu) ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -11 ;;
        mem) ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -11 ;;
        *) echo "USAGE: processTop [cpu|mem]" >&2; return 1 ;;
    esac
}
function processInfo {
    if [ "$#" -ne 1 ]; then
        echo "USAGE: processInfo <pid>" >&2
        return 1
    fi
    ps -fp "$1"
    echo ""
    echo "--- Memory Details ---"
    cat /proc/"$1"/status 2>/dev/null | grep -E "VmSize|VmRSS|VmSwap" || echo "Process not found"
}
function processMatch {
    # Check if exactly one keyword is provided
    if [ "$#" -ne 1 ]; then
        echo "USAGE: processMatch <keyword>" >&2
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
        echo "--- processes matching $1 ---"
        echo "$result"
        return 0
    fi
    # No matches found
    return 1
}   
function forceKillProcess {
    # Check argument count
    if [[ "$#" -ne 1 ]]; then
        echo "USAGE: forceKillProcess <pid>"
        return 1
    fi
    local pid="$1"
    # Validate PID is a number
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: PID must be a positive integer."
        return 1
    fi
    # Check if process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "ERROR: Process with PID $pid does not exist."
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
                return 0
            else
                echo "ERROR: Failed to kill process $pid. Permission denied or process already gone."
                return 1
            fi
            ;;
        *)
            echo "Operation cancelled."
            return 1
            ;;
    esac
}   








# END 






