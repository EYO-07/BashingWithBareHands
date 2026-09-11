# BEGIN Toolbox/scan_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. clamav 

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Virus/Malware Scanning Tools"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    if is_command_valid freshclam ; then 
        toolbox_item "virusDefinitionUpdate" "update virus/malware signatures" $width
    else 
        crit_echo "... missing: freshclam"
    fi
    if is_command_valid clamscan ; then 
        toolbox_item "virusLogView" "latest founds" $width
        toolbox_item "virusLogCleanup" "cleanup logs" $width
        toolbox_item "virusScanDirectoryList <list>" "perform scan on provided list" $width
        toolbox_item "virusQuarantine <path>" "quarantine file" $width
    else 
        crit_echo "... missing: clamav"
    fi
    toolbox_endl
    _codex_unset
}
tools

# -- implementation 
function virusDefinitionUpdate {
    source "$_SCRIPT_DIR/_codex.sh"
    # Ensure daemon is running
    if ! systemctl is-active --quiet clamav-daemon; then
        info_echo "Starting clamav-daemon..."
        sudo systemctl start clamav-daemon
    fi
    sudo freshclam || {
        crit_echo "ERROR: freshclam failed (exit $?)" >&2
        _codex_unset
        return 1
    }
    good_echo "Virus definitions updated."
    _codex_unset
}
function virusLogView {
    source "$_SCRIPT_DIR/_codex.sh"
    local log="${1:-$(ls -t /var/log/clamav/scan-*.log 2>/dev/null | head -1)}"
    if [ -z "$log" ] || [ ! -f "$log" ]; then
        crit_echo "No scan logs found in /var/log/clamav/"
        _codex_unset
        return 1
    fi
    info_echo "Log: $log"
    echo "-------------------------------------------"
    # Show infected lines + summary
    auto_escalate grep -E "FOUND|SCAN SUMMARY" -A6 "$log"
    _codex_unset
}
function virusLogCleanup {
    source "$_SCRIPT_DIR/_codex.sh"
    local days="${1:-7}"
    # Validate input
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        crit_echo "ERROR: days must be a positive integer (got: $days)"
        _codex_unset
        return 1
    fi
    local logdir="/var/log/clamav"
    local found=$(find "$logdir" -name "scan-*.log" -type f -mtime +"$days" 2>/dev/null)
    if [ -z "$found" ]; then
        good_echo "No scan logs older than ${days} day(s) found."
        _codex_unset
        return 0
    fi
    local count
    count=$(echo "$found" | wc -l)
    info_echo "Removing $count log file(s) older than ${days} day(s):"
    echo "$found" | while IFS= read -r f; do
        info_echo "  $f"
    done
    echo "$found" | xargs -d '\n' rm -f
    good_echo "Cleanup complete."
    _codex_unset
}   
function virusQuarantine {
    source "$_SCRIPT_DIR/_codex.sh"
    local target="${1:-}"
    local quarantine_dir="${2:-/var/quarantine/clamav}"
    if [ -z "$target" ]; then
        crit_echo "Usage: virusQuarantine <path> [quarantine_dir]"
        _codex_unset
        return 1
    fi
    # Validate target exists
    if [ ! -e "$target" ]; then
        crit_echo "ERROR: $target does not exist"
        _codex_unset
        return 1
    fi
    # Create quarantine directory if needed
    if [ ! -d "$quarantine_dir" ]; then
        info_echo "Creating quarantine directory: $quarantine_dir"
        sudo mkdir -p "$quarantine_dir"
        sudo chmod 700 "$quarantine_dir"
    fi
    # Confirm before proceeding
    warn_echo "Files detected as infected will be MOVED to: $quarantine_dir"
    warn_echo "Target: $target"
    if ! token_prompt "Confirmation" "Proceed?"; then
        _codex_unset
        return 0
    fi
    # Ensure daemon is running
    if ! systemctl is-active --quiet clamav-daemon; then
        info_echo "Starting clamav-daemon..."
        sudo systemctl start clamav-daemon
    fi
    local log="/var/log/clamav/quarantine-$(date +%Y%m%d-%H%M%S).log"
    echo "Scanning and quarantining: $target"
    sudo clamdscan -i --multiscan --fdpass \
        --move="$quarantine_dir" \
        -l "$log" \
        "$target"
    local rc=$?
    echo ""
    if [ $rc -eq 1 ]; then
        # Show what was moved
        local moved
        moved=$(grep "FOUND" "$log" 2>/dev/null)
        if [ -n "$moved" ]; then
            crit_echo "Quarantined file(s):"
            echo "$moved" | while IFS= read -r line; do
                info_echo "  $line"
            done
        fi
        info_echo "Log: $log"
        _codex_unset
        return 1
    elif [ $rc -gt 1 ]; then
        crit_echo "ERROR: clamdscan failed (exit $rc). See: $log"
        _codex_unset
        return 1
    else
        good_echo "No infections found. Nothing quarantined."
        _codex_unset
    fi
}
function virusScanDirectoryList { 
    source "$_SCRIPT_DIR/_codex.sh"
    local file="$1"
    if [ ! -f "$file" ]; then
        crit_echo "ERROR: $file not found" >&2
        warn_echo "Usage: virusScanDirectoryList <filename>"
        echo "... this file should contain a list of directory paths"
        echo "... use # for comment-lines"
        echo "File Example"
        echo "  # light scan"
        echo "  /var/tmp"
        echo "  /var/www"
        echo "  /var/spool"
        echo "  /var/mail"
        echo "  /home/user/Downloads"
        echo "  /root"
        echo "  /srv"
        echo "  /tmp"
        _codex_unset
        return 1
    fi
    if ! systemctl is-active --quiet clamav-daemon; then
        info_echo "Starting clamav-daemon..."
        sudo systemctl start clamav-daemon
    fi
    local log="/var/log/clamav/scan-$(date +%Y%m%d-%H%M%S).log"
    local infected=0
    local -a targets=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line%%[[:space:]]#*}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        targets+=("$line")
    done < "$file"
    for dir in "${targets[@]}"; do
        [ -d "$dir" ] || { warn_echo "WARN: $dir is not a directory, skipping." >&2; continue; }
        echo "Scanning: $dir"
        # inventory:
        #  - nice -n 19       → lowest CPU priority
        #  - ionice -c3       → idle I/O priority (only uses disk when idle)
        #  - --max-filesize=50M   → skip huge files (saves RAM)
        #  - --max-scansize=100M  → cap total decompressed scan size
        #  - --quiet          → suppress non-infected output
        #  - removed --multiscan → single thread, far less CPU        
        sudo nice -n 19 ionice -c3 clamdscan \
            -i --fdpass --quiet \
            -l "$log" "$dir"
        local rc=$?
        if [ $rc -eq 1 ]; then
            infected=$((infected + 1))
        elif [ $rc -gt 1 ]; then
            warn_echo "WARN: clamdscan error on $dir (exit $rc)" >&2
        fi
    done
    if [ $infected -gt 0 ]; then
        crit_echo "!! $infected directory(ies) contained infected files. See: $log"
        _codex_unset
        return 1
    fi
    good_echo "Scan complete. No infections found."
    _codex_unset
}   

# END