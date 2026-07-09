# BEGIN : Toolbox/errors_tools.sh

# -- dependencies
# Requires: dmesg (util-linux), journalctl (systemd)

# -- description
# A Linux-specific library for retrieving system, device, driver, and application error messages.
# Supports lookup by keyword search with optional file output.
# Usage: <function> [ <keyword> [<fileoutput>] ]

# -- color utilities
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
function warn_echo { color_echo 33 "$@"; }
function crit_echo { color_echo 31 "$@"; }
function info_echo { color_echo 36 "$@"; }

# -- Header Display
echo ""
color_echo 33 "=== Change Mode Tools ==="
echo "getSystemErrorMessages [ <keyword> [<fileoutput>] ] : Scan kernel log for critical system failures"
echo "getDeviceErrorMessages [ <keyword> [<fileoutput>] ] : Retrieve hardware/device errors"
echo "getDriverErrorMessages [ <keyword> [<fileoutput>] ] : Retrieve kernel module/driver failures"
echo "getApplicationErrorMessages [ <keyword> [<fileoutput>] ] : Retrieve user-space application errors"
echo ""

# -- Helper: Safe Output Handler
# Handles writing to stdout or file, ensures directory exists, avoids accidental overwrites if desired.
# Args: $1 = content (via stdin), $2 = optional file path
function _write_output {
    local outfile="$1"
    if [[ -n "$outfile" ]]; then
        # Ensure parent directory exists
        local dir
        dir=$(dirname "$outfile")
        if [[ ! -d "$dir" ]]; then
            crit_echo "Error: Output directory '$dir' does not exist."
            return 1
        fi
        # Write to file
        cat > "$outfile"
        info_echo "Output written to: $outfile"
    else
        # Write to stdout
        cat
    fi
    return 0
}

# -- implementation
# variables
_device_filter="device|hardware|I/O"
_device_error_filter="error|reset|failed|warning"
_driver_filter="driver|module|firmware"
_driver_error_filter="error|fail|refused|missing|warning"
# functions
function getSystemErrorMessages {
    # USAGE: getSystemErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    local pattern="panic|oom|out.of.memory|segfault|general.protection.fault|machine.check.exception|filesystem.corruption|critical|bug|kernel.bug"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
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
    return 0
}
function getDeviceErrorMessages {
    # USAGE: getDeviceErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        return 1
    fi
    local cmd="sudo dmesg -T"
    if [[ -n "$keyword" ]]; then
        { $cmd | grep -iE "$_device_filter" | grep -iE "$_device_error_filter" | grep -i "$keyword" || true; } | _write_output "$outfile"
    else
        # Default filter for device errors
        { $cmd | grep -iE "$_device_filter" | grep -iE "$_device_error_filter" | tail -n 20 || true; } | _write_output "$outfile"
    fi
    return 0
}
function getDriverErrorMessages {
    # USAGE: getDriverErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v dmesg &> /dev/null; then
        crit_echo "Error: 'dmesg' command not found."
        return 1
    fi
    local cmd="sudo dmesg -T"
    info_echo "--- Scanning for driver errors ---"
    if [[ -n "$keyword" ]]; then
        { $cmd | grep -iE "$_driver_filter" | grep -iE "$_driver_error_filter" | grep -i "$keyword" || true; } | _write_output "$outfile"
    else
        { $cmd | grep -iE "$_driver_filter" | grep -iE "$_driver_error_filter" | tail -n 20 || true; } | _write_output "$outfile"
    fi
    return 0
}
function getApplicationErrorMessages {
    # USAGE: getApplicationErrorMessages [ <keyword> [<fileoutput>] ]
    local keyword="$1"
    local outfile="$2"
    if ! command -v journalctl &> /dev/null; then
        crit_echo "Error: 'journalctl' (systemd) not found."
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
    return 0
}

# END   