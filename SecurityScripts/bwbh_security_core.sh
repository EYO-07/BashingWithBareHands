#!/usr/bin/env bash
# ==============================================================================
# BashingWithBareHands - Root-Protected Security Core
# Purpose: Ensures script integrity via cryptographic hashes (SHA-256) and 
#          prevents unauthorized file tampering using immutable file attributes.
# Suggested Path: /var/lib/script_security/bwbh_security_core.sh
# ==============================================================================

# 1. Integrity Check Function
# Validates whether a given script matches its trusted cryptographic baseline.
__SCRIPT_INTEGRITY_CHECK() {
    # Capture the first argument passed to the function (the script path)
    local script_path="${1:-}"
    
    # Safety check: Ensure a path was provided and that the file actually exists
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        printf '\033[1;31m✗ Error: Invalid or missing script path for integrity check.\033[0m\n' >&2
        return 1
    fi
    
    # Convert relative paths (like './script.sh') into absolute paths for consistency
    script_path="$(realpath "$script_path")"
    
    # Define where cryptographic baseline hash files are safely stored
    local hash_dir="/var/lib/script_integrity"
    
    # Map the target script's path to a unique hash filename by replacing slashes ('/') with underscores ('_')
    # Example: /home/user/Toolbox/tools.sh becomes /var/lib/script_integrity/_home_user_Toolbox_tools.sh
    local hash_file="$hash_dir/${script_path//\//_}"
    
    # Check if a saved baseline hash file exists for this script
    if [[ ! -f "$hash_file" ]]; then
        printf '\033[1;33m⚠ Warning: No integrity baseline found for: %s\033[0m\n' "$script_path" >&2
        return 1
    fi
    
    local saved_hash current_hash
    
    # Read the trusted hash from the stored baseline file (takes only the first column)
    saved_hash="$(awk '{print $1}' "$hash_file" 2>/dev/null)"
    
    # Calculate the cryptographic SHA-256 hash of the script *right now*
    current_hash="$(sha256sum "$script_path" | awk '{print $1}')"
    
    # Compare the current hash against the trusted baseline hash
    if [[ "$current_hash" != "$saved_hash" ]]; then
        # If they don't match, print a prominent security warning alert
        printf '\n\033[1;31m✗ SECURITY ALERT: Modification detected in protected file!\033[0m\n' >&2
        printf '  \033[2mFile:   %s\033[0m\n' "$script_path" >&2
        printf '  \033[2mSaved:  %s\033[0m\n' "$saved_hash" >&2
        printf '  \033[2mCurrent:%s\033[0m\n' "$current_hash" >&2
        printf '\033[1;33mℹ To update the baseline hash, run: sudo __SCRIPT_BASELINE_UPDATE "%s"\033[0m\n' "$script_path" >&2
        return 1 # Return a failure code to block downstream actions
    fi
    
    # If hashes match perfectly, return success
    return 0
}

# 2. Baseline Update Function
# Calculates and securely stores/updates a fresh cryptographic baseline for a script.
__SCRIPT_BASELINE_UPDATE() {
    local script_path="${1:-}"
    
    # Ensure the target script exists
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        printf '\033[1;31m✗ Error: Invalid or missing script path for baseline update.\033[0m\n' >&2
        return 1
    fi
    
    script_path="$(realpath "$script_path")"
    local hash_dir="/var/lib/script_integrity"
    
    # If the secure storage directory doesn't exist yet, create it with root privileges
    if [[ ! -d "$hash_dir" ]]; then
        sudo mkdir -p "$hash_dir"
        sudo chmod 755 "$hash_dir"
        sudo chattr +a "$hash_dir" 2>/dev/null
    fi
    
    local hash_file="$hash_dir/${script_path//\//_}"
    local current_hash
    
    # Compute the current SHA-256 checksum of the target file
    current_hash="$(sha256sum "$script_path" | awk '{print $1}')"
    
    # If an existing hash file is locked as immutable ('+i'), temporarily unlock it so we can update it
    if lsattr -d "$hash_file" 2>/dev/null | awk '{print $1}' | grep -q 'i'; then
        sudo chattr -i "$hash_file" 2>/dev/null
    fi
    
    # Write the new hash and script path securely into the hash file via sudo
    echo "$current_hash  $script_path" | sudo tee "$hash_file" >/dev/null || return 1
    
    # Lock down permissions: make the hash file strictly read-only (0444)
    sudo chmod 0444 "$hash_file"
    
    # Apply the immutable file attribute ('+i') to prevent any deletion or modification, even by root
    sudo chattr +i "$hash_file" 2>/dev/null
    
    printf '\033[1;32m✓ Baseline successfully updated for: %s\033[0m\n' "$script_path"
    return 0
}

# 3. Safe Sourcing Function 
# A wrapper that audits a script's integrity *before* allowing the shell to source it.
__SCRIPT_SAFE_SOURCE() {
    # Run the integrity check first; if it fails, abort immediately (return 1)
    __SCRIPT_INTEGRITY_CHECK "$1" || return 1
    
    # If safe, source the script into the current shell session
    source "$1"
}

# Hardening / Session Protection:
# Mark these core functions as read-only. This prevents malicious or accidental 
# script execution from redefining, overriding, or hijacking these core security functions mid-session.
readonly -f __SCRIPT_INTEGRITY_CHECK
readonly -f __SCRIPT_BASELINE_UPDATE
readonly -f __SCRIPT_SAFE_SOURCE