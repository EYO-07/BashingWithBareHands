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
    toolbox_item "tools / inv" "print this ... / show command syntax" $width
    toolbox_item "processMatch <keyword>" "show processes matching the keyword" $width
    toolbox_item "processTop [cpu|mem]" "show top 10 processes by CPU or memory" $width
    toolbox_item "processInfo <pid>" "show detailed info for a specific PID" $width
    toolbox_item "forceKillProcess <pid>" "force kill process by pid" $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    # Inventory : nice { Linux }
    # Scale: -20 (highest) → 0 (default) → +19 (lowest)
    # Positive = "nicer" to others (less CPU), Negative = more aggressive (needs sudo)
    # --- nice (at launch) ---
    # 1. nice -n 10 APPNAME          ; run with priority 10 (lower than default)
    # 2. nice -n 19 APPNAME          ; run at lowest possible priority
    # 3. sudo nice -n -5 APPNAME     ; run at higher priority (root only)
    # 4. nice APPNAME                ; default: adds +10 to niceness
    # --- renice (running process) ---
    # 5. renice -n 10 -p PID         ; change priority of one process by PID
    # 6. sudo renice -n -5 -p PID    ; raise priority of one process (root only)
    # 7. sudo renice -n 10 -u USER   ; change priority of ALL processes for a user
    # 8. sudo renice -n 10 -g PGID   ; change priority of ALL processes in a group
    # 9. renice -n 10 -p PID1 PID2   ; change priority of multiple PIDs at once
    # --- find PIDs ---
    # 10. pgrep -f APPNAME           ; get PID(s) by name
    # 11. ps -eo pid,ni,cmd          ; list all processes with their nice value
    # 12. top → press 'R'            ; interactive: raise niceness of a process
    # --- in a script (self-renice) ---
    # 13. renice -n 15 -p $$         ; lower this script's own priority
    
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Processes/Tasks Tools"
    local width=5
    info_echo "--- general ---"
    inventory_item 1 "pgrep <name>" "search process by name" $width
    inventory_item 2 "pidof <name>" "return the process id" $width
    inventory_item 3 "kill <pid>" "kill process by process id" $width
    info_echo "--- process priority ---"
    echo "... priority values range from -20 (highest) to 19 (lowest) with 0 as default"
    inventory_item 1 "nice -n <int> <program>" "run <program> with <int> priority" $width
    inventory_item 2 "renice -n <int> -p <PID>" "set program priority by pid" $width
    inventory_item 3 "ps -o pid,ni,comm -p <PID>" "NI is the priority of process" $width
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
    # Safety check: Prevent killing PID 1 or self ($$)
    if [[ "$pid" -eq 1 || "$pid" -eq $$ ]]; then
        echo "ERROR: Cannot terminate critical system PID $pid."
        _codex_unset
        return 1
    fi
    # Get process name for display
    local process_name
    process_name=$(ps -p "$pid" -o comm= 2>/dev/null)
    # Get full command line for display
    local process_cmd
    process_cmd=$(ps -p "$pid" -o args= 2>/dev/null)
    # Confirmation dialog
    warn_echo "WARNING: You are about to forcefully terminate the following process:"
    echo "  PID:  $pid"
    echo "  Name: ${process_name:-<unknown>}"
    echo "  Cmd:  ${process_cmd:-<unknown>}"
    echo ""
    if ! yn_prompt "Force Kill" "Are you sure you want to send SIGKILL to this process?"; then
        echo "Operation cancelled."
        _codex_unset
        return 1
    fi
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
}

# END 






