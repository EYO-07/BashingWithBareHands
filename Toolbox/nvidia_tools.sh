# BEGIN : Toolbox/nvidia_tools.sh 
# ... helper functions to get information about nvidia 

# -- 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "NVIDIA GPU Tools"
    toolbox_item "tools / inv" "show this ... / command syntax" $width
    toolbox_item "nvidiaChecklistArch" "check for common configurations or missing packages on arch-linux" $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "NVIDIA GPU Tools"
    local width=9
    inventory_item 1 "lspci -k -d ::03xx" "show gpu devices information" $width
    inventory_endl 
    _codex_unset
}

# -- implementation
function nvidiaChecklistArch {
    local green='\033[32m' yellow='\033[33m' red='\033[31m' gray='\033[90m' reset='\033[0m'
    local bold='\033[1m'
    
    # --- GPU Detection ---
    printf "${bold}GPU Detection:${reset}\n"
    local gpus
    gpus=$(lspci 2>/dev/null | grep -iE 'vga|3d|display')
    if [[ -z "$gpus" ]]; then
        printf "  ${red}✗ No GPU detected${reset}\n"
    else
        while IFS= read -r line; do
            local clean_line
            clean_line=$(echo "$line" | sed 's/^[[:space:]]*//')
            if echo "$line" | grep -qi 'nvidia'; then
                printf "  ${green}✓ %s${reset}\n" "$clean_line"
            else
                printf "  ${yellow}⚠ %s${reset} ${gray}(non-NVIDIA)${reset}\n" "$clean_line"
            fi
        done <<< "$gpus"
    fi

    # --- Packages (Arch-focused) ---
    printf "\n${bold}Packages:${reset}\n"
    local has_driver=false
    local driver_pkgs=(
        "nvidia-open" "nvidia-open-dkms" "nvidia-open-lts"
        "nvidia" "nvidia-dkms" "nvidia-lts"
    )
    
    for pkg in "${driver_pkgs[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            printf "  ${green}✓ Driver installed: ${pkg}${reset}\n"
            has_driver=true
            break
        fi
    done
    
    if ! $has_driver; then
        printf "  ${red}✗ No primary NVIDIA driver found${reset} ${gray}→ sudo pacman -S nvidia-open (or nvidia-open-dkms)${reset}\n"
    fi

    # Check supporting packages
    for pkg in nvidia-utils nvidia-settings cuda; do
        if pacman -Q "$pkg" &>/dev/null; then
            printf "  ${green}✓ ${pkg}${reset}\n"
        else
            if [[ "$pkg" == "nvidia-utils" ]]; then
                printf "  ${red}✗ ${pkg} (missing — core)${reset} ${gray}→ sudo pacman -S nvidia-utils${reset}\n"
            else
                printf "  ${gray}○ ${pkg} (optional)${reset} ${gray}→ sudo pacman -S ${pkg}${reset}\n"
            fi
        fi
    done

    # --- Driver Version & Major Extraction ---
    local drv_ver=""
    local drv_major=0
    if command -v nvidia-smi &>/dev/null; then
        drv_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        if [[ -n "$drv_ver" ]]; then
            drv_major=$(echo "$drv_ver" | cut -d. -f1)
            printf "\n${bold}Driver Status:${reset}\n  ${green}✓ nvidia-smi reports driver ${drv_ver} (Major: ${drv_major})${reset}\n"
        else
            printf "\n${bold}Driver Status:${reset}\n  ${red}✗ nvidia-smi present but returned no driver version${reset}\n"
        fi
    else
        printf "\n${bold}Driver Status:${reset}\n  ${red}✗ nvidia-smi not found${reset} ${gray}→ ensure nvidia-utils is installed${reset}\n"
    fi

    # --- Kernel Modules ---
    printf "\n${bold}Kernel Modules:${reset}\n"
    local modules=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
    for mod in "${modules[@]}"; do
        if lsmod 2>/dev/null | grep -q "^${mod}"; then
            printf "  ${green}✓ module loaded: ${mod}${reset}\n"
        else
            printf "  ${yellow}⚠ module not loaded: ${mod}${reset}\n"
        fi
    done

    # --- Kernel Parameters & Runtime Status (KMS & FBDev) ---
    printf "\n${bold}Kernel Parameters & Runtime Status (KMS / FBDev):${reset}\n"
    local modeset_val=""
    local fbdev_val=""
    
    if [[ -f "/sys/module/nvidia_drm/parameters/modeset" ]]; then
        modeset_val=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null)
    fi
    if [[ -f "/sys/module/nvidia_drm/parameters/fbdev" ]]; then
        fbdev_val=$(cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null)
    fi
    
    local cmdline
    cmdline=$(cat /proc/cmdline 2>/dev/null)
    
    # Check Modeset
    if [[ "$modeset_val" =~ ^(Y|1)$ ]]; then
        printf "  ${green}✓ nvidia-drm.modeset is active (Runtime: ${modeset_val})${reset}\n"
    elif [[ "$cmdline" =~ nvidia-drm\.modeset=1 ]] || grep -rqE 'options\s+nvidia-drm\s+.*modeset=1' /etc/modprobe.d/ 2>/dev/null; then
        printf "  ${yellow}⚠ nvidia-drm.modeset=1 configured (Configured, but module not fully active yet)${reset}\n"
    else
        printf "  ${red}✗ nvidia_drm.modeset=1 missing${reset} ${gray}→ add to kernel cmdline or /etc/modprobe.d/nvidia.conf${reset}\n"
    fi

    # Check FBDev
    if [[ "$fbdev_val" =~ ^(Y|1)$ ]]; then
        printf "  ${green}✓ nvidia-drm.fbdev is active (Runtime: ${fbdev_val})${reset}\n"
    elif [[ "$cmdline" =~ nvidia-drm\.fbdev=1 ]] || grep -rqE 'options\s+nvidia-drm\s+.*fbdev=1' /etc/modprobe.d/ 2>/dev/null; then
        printf "  ${yellow}⚠ nvidia-drm.fbdev=1 configured (Configured, but module not fully active yet)${reset}\n"
    else
        printf "  ${gray}○ nvidia-drm.fbdev not explicitly set${reset} ${gray}(defaults depend on driver version)${reset}\n"
    fi

    # --- Configuration Files ---
    printf "\n${bold}Configuration Files:${reset}\n"
    local conf_file="/etc/X11/xorg.conf.d/20-nvidia.conf"
    if [[ -f "$conf_file" ]]; then
        printf "  ${green}✓ ${conf_file} exists${reset}\n"
    else
        printf "  ${gray}○ ${conf_file} not present${reset} ${gray}→ usually optional with modern compositors${reset}\n"
    fi

    # Check for OutputClass configuration (crucial for PRIME/Optimus and modern setup)
    local output_class_found=false
    if compgen -G "/etc/X11/xorg.conf.d/*.conf" > /dev/null; then
        for f in /etc/X11/xorg.conf.d/*.conf; do
            if grep -qi "OutputClass" "$f" 2>/dev/null && grep -qi "nvidia" "$f" 2>/dev/null; then
                printf "  ${green}✓ Local OutputClass config found: ${f}${reset}\n"
                output_class_found=true
                break
            fi
        done
    fi

    if ! $output_class_found; then
        if [[ -f "/usr/share/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf" ]] || compgen -G "/usr/share/X11/xorg.conf.d/*nvidia*.conf" > /dev/null; then
            printf "  ${green}✓ System-default OutputClass config provided by nvidia-utils${reset}\n"
        else
            printf "  ${gray}○ No explicit NVIDIA OutputClass config found${reset} ${gray}(optional for single-GPU, required for PRIME/Optimus)${reset}\n"
        fi
    fi

    
    # --- Power Management Services (Version-Aware) ---
    printf "\n${bold}Power Management Services:${reset}\n"
    if [[ "$drv_major" -gt 0 && "$drv_major" -lt 595 ]]; then
        # Legacy/Older series (430-590) where systemd hooks are strictly expected
        printf "  ${gray}ℹ Driver version < 595 detected: legacy sleep hooks recommended${reset}\n"
        for svc in nvidia-suspend nvidia-resume nvidia-hibernate; do
            if systemctl is-enabled "$svc.service" &>/dev/null; then
                printf "  ${green}✓ ${svc}.service is enabled${reset}\n"
            else
                printf "  ${yellow}⚠ ${svc}.service not enabled${reset} ${gray}→ sudo systemctl enable ${svc}.service${reset}\n"
            fi
        done
    else
        # Modern drivers (595+) use kernel suspend notifiers natively
        printf "  ${green}✓ Driver version 595+ (or unknown): using modern kernel suspend notifiers${reset}\n"
        printf "  ${gray}○ Explicit systemd sleep services are optional (though GDM/Wayland may still use resume hooks)${reset}\n"
    fi

    # --- Persistence Daemon ---
    printf "\n${bold}Persistence Daemon:${reset}\n"
    if systemctl is-active nvidia-persistenced &>/dev/null; then
        printf "  ${green}✓ nvidia-persistenced is active${reset}\n"
    else
        printf "  ${gray}○ nvidia-persistenced not running${reset} ${gray}→ optional for standard desktop/gaming${reset}\n"
    fi
    
    return 0
}



# END 