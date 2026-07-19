# BEGIN : Toolbox/errors_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# {TextMarker|red:|cyan:}

# -- dependencies
# Requires: dmesg (util-linux), journalctl (systemd)

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=11
    toolbox_title "Error/Issues Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "getSystemErrorMessages [ <keyword> [<fileoutput>] ]" "Scan kernel log for critical system failures" $width
    toolbox_item "getDeviceErrorMessages [ <keyword> [<fileoutput>] ]" "Retrieve hardware/device errors" $width
    toolbox_item "getDriverErrorMessages [ <keyword> [<fileoutput>] ]" "Retrieve kernel module/driver failures" $width
    toolbox_item "getUserErrorMessages [ <keyword> [<fileoutput>] ]" "Retrieve user-space application errors" $width
    toolbox_item "getX11ErrorMessages [ <keyword> [<fileoutput>]" "x11/xorg specific errors" $width
    toolbox_item "getGraphicCardErrorMessages [ <keyword> [<fileoutput>]" "..." $width
    toolbox_item "systemInformation" "... info attached to fileoutputs" $width
    toolbox_item "queryMessagesByUnit <unit>" "query journalctl by unit name" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Errors"
    local width=8
    inventory_item '' "loginctl list-sessions" "list active sessions" $width
    inventory_item '' "loginctl kill-session <SESSION_ID>" "terminate session by id" $width
    inventory_item '' "<command> | less" "allow reading long command outputs" $width
    inventory_item '' "dmesg --since=YYYY-MM-DD | less" "show kernel logs" $width
    inventory_item '' "journalctl --since=YYYY-MM-DD | less" "show system logs" $width
    inventory_item '' "<command> | grep -i <keyword>" "filter lines of the output of a command by keyword case-insensitive" $width
    inventory_item '' '<command> | grep -iE "kw1|kw2|..."' "union of filtered keyword line searchs case-insensitive" $width
    inventory_item '' '<command> | grep -iv <keyword>' "exclude matching lines" $width
    inventory_item '' '<command> | grep -ivE "kw1|kw2|..."' "exclude matching lines combined" $width
    inventory_item '' "<command> --help" "majority of cli tools have this syntax for help page" $width
    #inventory_item 0 "" "" $width
    inventory_endl 
    _codex_unset
}

# -- Helper: Safe Output Handler
# Handles writing to stdout or file, ensures directory exists, avoids accidental overwrites if desired.
# Args: $1 = content (via stdin), $2 = optional file path
function _write_output {
    source "$_SCRIPT_DIR/_codex.sh"
    local outfile="$1"
    if [[ -n "$outfile" ]]; then
        # Ensure parent directory exists
        local dir
        dir=$(dirname "$outfile")
        if [[ ! -d "$dir" ]]; then
            crit_echo "Error: Output directory '$dir' does not exist."
            _codex_unset
            return 1
        fi
        # Write to file
        systemInformation > "$outfile"
        echo "" >> "$outfile"
        echo "=== Error Messages ===" >> "$outfile"
        cat >> "$outfile"
        info_echo "Output written to: $outfile"
    else
        # Write to stdout
        cat
    fi
    _codex_unset
    return 0
}

# -- implementation
# variables
_general_error_filter="panic|oom|out.of.memory|segfault|general.protection.fault|machine.check.exception|filesystem.corruption|critical|bug|kernel.bug"
_device_filter="device|hardware|I/O"
_device_error_filter="error|reset|failed|warning"
_driver_filter="driver|module|firmware"
_driver_error_filter="error|fail|refused|missing|warning"
_gpu_drivers="nvidia|nouveau|amdgpu|radeon|i915|xe|drm|vgaarb|gpu"
_gpu_errors="error|fail|corrupt|reset|timeout|hang|fallback|vram|flip_done|crtc|invalid"
# functions
function getSystemErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getSystemErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    local pattern="$_general_error_filter"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        _codex_unset
        return 1
    fi
    local cmd="sudo dmesg -T"
    # Build grep pipeline 
    # Use '|| true' to prevent script exit if grep finds nothing (set -e safety)
    if [[ -n "$keyword" ]]; then
        info_echo "--- Searching system logs for '$keyword' within critical events ---"
        # First filter for critical patterns, then for keyword
        { $cmd | grep -iE "$pattern" | grep -i "$keyword" || true; } | _write_output "$outfile"
    else
        info_echo "--- Scanning for general critical system errors ---"
        { $cmd | grep -iE "$pattern" || true; } | _write_output "$outfile"
    fi
    _codex_unset
    return 0
}
function getDeviceErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getDeviceErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        _codex_unset
        return 1
    fi
    local cmd="sudo dmesg -T"
    if [[ -n "$keyword" ]]; then
        { $cmd | grep -iE "$_device_filter" | grep -iE "$_device_error_filter" | grep -i "$keyword" || true; } | _write_output "$outfile"
    else
        # Default filter for device errors
        { $cmd | grep -iE "$_device_filter" | grep -iE "$_device_error_filter" | tail -n 20 || true; } | _write_output "$outfile"
    fi
    _codex_unset
    return 0
}
function getDriverErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getDriverErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        _codex_unset
        return 1
    fi
    local cmd="sudo dmesg -T"
    info_echo "--- Scanning for driver errors ---"
    if [[ -n "$keyword" ]]; then
        { $cmd | grep -iE "$_driver_filter" | grep -iE "$_driver_error_filter" | grep -i "$keyword" || true; } | _write_output "$outfile"
    else
        { $cmd | grep -iE "$_driver_filter" | grep -iE "$_driver_error_filter" | tail -n 20 || true; } | _write_output "$outfile"
    fi
    _codex_unset
    return 0
}
function getUserErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getApplicationErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v journalctl &> /dev/null; then
        crit_echo "Error: 'journalctl' (systemd) not found."
        _codex_unset
        return 1
    fi
    info_echo "--- Scanning for application errors ---"
    if [[ -n "$keyword" ]]; then
        # Try strict error first, fallback to general if empty
        # We capture to a variable to check if empty before deciding to fallback or write
        local results
        results=$(sudo journalctl -p err --grep="$keyword" --no-pager -n 50 2>/dev/null)
        if [[ -z "$results" ]]; then
            warn_echo "No strict error matches. Broadening search..."
            results=$(sudo journalctl --grep="$keyword" --no-pager -n 50 2>/dev/null)
        fi
        echo "$results" | _write_output "$outfile"
    else
        # Default: Recent application errors
        sudo journalctl -p err --no-pager -n 25 2>/dev/null | _write_output "$outfile"
    fi
    _codex_unset
    return 0
}
function systemInformation {    
    source "$_SCRIPT_DIR/_codex.sh"
    # show a short system hardware and operational system info
    # to constraint the solution based on current system 
    echo "=== System Information ==="
    # 1. Show the Linux OS
    # Uses /etc/os-release for broad compatibility across distros
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: $PRETTY_NAME"
    else
        echo "OS: $(uname -o) $(uname -r)"
    fi
    # 2. Show kernel version
    echo "Kernel: $(uname -r)"
    # 3. Show CPU
    # Extracts the first model name found in /proc/cpuinfo
    cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f2 | xargs)
    cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
    echo "CPU: $cpu_model ($cpu_cores cores)"
    # 4. Show GPU
    # Tries lspci first (works without sudo), falls back to lshw if needed
    gpu_info=$(lspci | grep -i vga | cut -d ':' -f3 | xargs)
    if [ -z "$gpu_info" ]; then
        gpu_info="No VGA controller found (Headless or Integrated?)"
    fi
    echo "GPU: $gpu_info"
    # 5. Show Motherboard
    # Tries reading from /sys first (no sudo), then dmidecode (needs sudo)
    mobo_model=""
    if [ -f /sys/class/dmi/id/board_name ]; then
        mobo_vendor=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
        mobo_model=$(cat /sys/class/dmi/id/board_name 2>/dev/null)
    fi
    if [ -z "$mobo_model" ] || [ "$mobo_model" == "Not Available" ]; then
        if command -v dmidecode &> /dev/null; then
            mobo_vendor=$(sudo dmidecode -s baseboard-manufacturer 2>/dev/null)
            mobo_model=$(sudo dmidecode -s baseboard-product-name 2>/dev/null)
        fi
    fi
    echo "Motherboard: $mobo_vendor $mobo_model"
    # 6. Additional Useful Info
    # RAM
    ram_total=$(free -h | awk '/^Mem:/ {print $2}')
    echo "RAM: $ram_total"
    # Architecture
    arch=$(uname -m)
    echo "Architecture: $arch"
    # Disk Space (Root partition)
    disk_avail=$(df -h / | awk 'NR==2 {print $4}')
    echo "Available Disk (Root): $disk_avail"
    # Virtualization Check (Simple heuristic)
    if grep -q hypervisor /proc/cpuinfo 2>/dev/null; then
        echo "Environment: Virtual Machine"
    else
        echo "Environment: Physical/Bare Metal"
    fi
    _codex_unset
}   
function getX11ErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getX11ErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    info_echo "--- Scanning via X11 Core Logs & Tools ---"
    # 1. Verify if the X Server is currently responsive
    if command -v xset &> /dev/null; then
        if ! xset q &>/dev/null; then
            crit_echo "Warning: Cannot connect to X server (DISPLAY=$DISPLAY)."
        fi
    fi
    # 2. Define traditional Xorg log paths
    local xorg_logs=(
        "$HOME/.local/share/xorg/Xorg.0.log"
        "/var/log/Xorg.0.log"
        "/var/log/Xorg.1.log"
    )
    # Collect errors using Xorg-specific markers:
    # (EE) = Error, (WW) = Warning, (NI) = Not Implemented
    local buffer
    buffer=$(
        for log in "${xorg_logs[@]}"; do
            if [[ -f "$log" ]]; then
                echo "=== Xorg Log File: $log ==="
                # Extract lines containing the X11 error/warning signatures
                grep -E "\[\s*[0-9.]+\s*\] \((EE|WW|NI)\)" "$log"
            fi
        done
    )
    # 3. Filter and Output
    if [[ -z "$buffer" ]]; then
        warn_echo "No X11 errors or warnings found in standard log paths."
        _codex_unset
        return 0
    fi
    if [[ -n "$keyword" ]]; then
        echo "$buffer" | grep -i "$keyword" | _write_output "$outfile"
    else
        echo "$buffer" | _write_output "$outfile"
    fi   
    _codex_unset
    return 0
}
function getGraphicCardErrorMessages {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: getGraphicCardErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        _codex_unset
        return 1
    fi
    info_echo "--- Scanning Kernel Logs (dmesg) for Graphics/GPU errors ---"
    # Define graphics drivers and error patterns to cross-reference    
    local buffer
    buffer=$(
        # Filter lines that mention a graphics driver AND an error keyword
        sudo dmesg -T | grep -iE "$_gpu_drivers" | grep -iE "$_gpu_errors" || true
    )
    # Filter and Output
    if [[ -z "$buffer" ]]; then
        warn_echo "No specific Graphics Card/GPU errors detected in dmesg."
        _codex_unset
        return 0
    fi
    if [[ -n "$keyword" ]]; then
        echo "$buffer" | grep -i "$keyword" | _write_output "$outfile"
    else
        echo "$buffer" | _write_output "$outfile"
    fi
    _codex_unset
    return 0
}
function queryMessagesByUnit {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then
        echo "Usage: queryMessagesByUnit <unit_name>"
        _codex_unset
        return 1
    fi
    journalctl -u "$1"
    _codex_unset
}

# END   