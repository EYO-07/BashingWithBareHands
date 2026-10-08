#!/usr/bin/env bash
# Utility script to traverse a toolbox folder, audit script integrity, 
# and interactively prompt for baseline generation/updates.
# run it as `bash bwbh_update_baseline.sh`

TOOLBOX_DIR="$HOME/Toolbox" # MODIFY IF NECESSARY TO ACTUAL PATH
if [[ ! -d "$TOOLBOX_DIR" ]]; then
    printf '\033[1;31m✗ Error: Toolbox directory not found: %s\033[0m\n' "$TOOLBOX_DIR" >&2
    exit 1
fi

# Ensure security core functions are available
if ! declare -F __SCRIPT_INTEGRITY_CHECK &>/dev/null; then
    if [[ -f "/var/lib/script_security/bwbh_security_core.sh" ]]; then
        source "/var/lib/script_security/bwbh_security_core.sh"
    else
        printf '\033[1;31m✗ Error: Security core is not loaded or missing from protected storage.\033[0m\n' >&2
        printf 'ℹ Run this tool with proper access or ensure bwbh_security_core.sh is installed.\033[0m\n' >&2
        exit 1
    fi
fi
printf '\033[1;34mAuditing toolbox scripts in: %s\033[0m\n\n' "$TOOLBOX_DIR"

# Traverse directory for all script files (adjust extension or pattern as needed)
find "$TOOLBOX_DIR" -type f -name "*.sh" | while read -r script; do
    printf 'Checking: %s ... ' "$script"
    # Run integrity check; suppress error output to keep the loop clean
    if __SCRIPT_INTEGRITY_CHECK "$script" >/dev/null 2>&1; then
        printf '\033[1;32m[OK]\033[0m\n'
    else
        printf '\033[1;33m[MISSING/MODIFIED]\033[0m\n'
        # Prompt user interactively
        read -r -p "    Update or generate baseline for this file? [y/N]: " choice < /dev/tty
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            __SCRIPT_BASELINE_UPDATE "$script"
        else
            printf '   ➔ Skipped baseline update for %s\n' "$script"
        fi
    fi
done

printf '\n\033[1;32m Toolbox audit and sync process complete.\033[0m\n'