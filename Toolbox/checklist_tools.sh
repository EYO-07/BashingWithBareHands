# BEGIN : Toolbox/checklist_tools.sh 
# ... helper functions to get information about nvidia 

if [[ "$(type -t __SCRIPT_INTEGRITY_CHECK 2>/dev/null)" == "function" ]]; then
    __SCRIPT_INTEGRITY_CHECK || return 1
else 
    source "$_SCRIPT_DIR/_codex.sh"
    __SCRIPT_INTEGRITY_CHECK || return 1
    _codex_unset
fi 

# -- 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Checklists"
    toolbox_item "tools" "show this ..." $width
    toolbox_item "checkListNvidiaArch" "check for common configurations or missing packages for nvidia gpu on arch-linux" $width
    toolbox_item "checkListModprobe" "check for modules" $width
    toolbox_item "checkListNetwork" "check for network components" $width
    toolbox_endl
    _codex_unset
}
tools 

# -- implementation
function checkListNvidiaArch {
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
function checkListModprobe {
    local green='\033[32m' yellow='\033[33m' red='\033[31m' gray='\033[90m' reset='\033[0m'
    local bold='\033[1m'
    # --- Loaded Modules Check ---
    printf "${bold}Loaded Kernel Modules:${reset}\n"
    # Define modules along with a short description separated by a pipe (|)
    local common_modules=(
        "nvidia:NVIDIA proprietary GPU core driver"
        "nvidia_drm:NVIDIA DRM (Direct Rendering Manager) driver for Wayland/KMS"
        "amdgpu:AMD Radeon graphics and display driver"
        "i915:Intel graphics and display driver"
        "kvm:Kernel-based Virtual Machine hypervisor"
        "snd_hda_intel:Intel/AMD/NVIDIA High Definition Audio controller driver"
    )
    local found_loaded=0
    for entry in "${common_modules[@]}"; do
        local mod="${entry%%:*}"
        local desc="${entry#*:}"
        
        if lsmod 2>/dev/null | grep -q "^${mod}\b"; then
            printf "  ${green}✓ Loaded: ${bold}%s${reset} ${gray}(%s)${reset}\n" "$mod" "$desc"
            found_loaded=$((found_loaded + 1))
        else
            printf "  ${gray}○ Not loaded: %s (${desc})${reset}\n" "$mod"
        fi
    done
    # --- Blacklisted Modules Check ---
    printf "\n${bold}Blacklisted Modules:${reset}\n"
    local blacklists_found=false
    # 1. Check kernel command line for modprobe.blacklist
    local cmdline
    cmdline=$(cat /proc/cmdline 2>/dev/null)
    if [[ "$cmdline" =~ modprobe\.blacklist=([^[:space:]]+) ]]; then
        printf "  ${yellow}⚠ Kernel cmdline blacklist detected:${reset} ${bold}%s${reset}\n" "${BASH_REMATCH[1]}"
        blacklists_found=true
    fi
    # 2. Check /etc/modprobe.d/ for blacklist entries
    if compgen -G "/etc/modprobe.d/*.conf" > /dev/null; then
        for f in /etc/modprobe.d/*.conf; do
            if grep -qiE '^\s*blacklist\s+' "$f" 2>/dev/null; then
                printf "  ${yellow}⚠ Blacklist rule found in ${f}:${reset}\n"
                while IFS= read -r line; do
                    if [[ "$line" =~ ^[[:space:]]*blacklist[[:space:]]+([^#[:space:]]+) ]]; then
                        printf "    ${gray}- Module blacklisted: ${bold}%s${reset}\n" "${BASH_REMATCH[1]}"
                        blacklists_found=true
                    fi
                done < <(grep -iE '^\s*blacklist\s+' "$f")
            fi
        done
    fi
    if ! $blacklists_found; then
        printf "  ${green}✓ No active module blacklists detected${reset}\n"
    fi
    # --- Modprobe Options & Configuration Files ---
    printf "\n${bold}Modprobe Configuration Files (/etc/modprobe.d/):${reset}\n"
    local conf_count=0
    if compgen -G "/etc/modprobe.d/*.conf" > /dev/null; then
        for f in /etc/modprobe.d/*.conf; do
            printf "  ${green}✓ Found config: ${f}${reset}\n"
            conf_count=$((conf_count + 1))
            # Extract and display options defined inside configuration files
            while IFS= read -r opt_line; do
                if [[ "$opt_line" =~ ^[[:space:]]*options[[:space:]]+(.+) ]]; then
                    printf "    ${gray}↳ option: %s${reset}\n" "${BASH_REMATCH[1]}"
                fi
            done < <(grep -iE '^\s*options\s+' "$f" 2>/dev/null)
        done
    fi
    if [[ "$conf_count" -eq 0 ]]; then
        printf "  ${gray}○ No custom .conf files found in /etc/modprobe.d/${reset}\n"
    fi
    return 0
}
function checkListNetwork {
    local green='\033[32m' yellow='\033[33m' red='\033[31m' gray='\033[90m' reset='\033[0m'
    local bold='\033[1m'
    # --- Network Interfaces ---
    printf "${bold}Network Interfaces:${reset}\n"
    if command -v ip &>/dev/null; then
        local interfaces
        interfaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}')
        if [[ -z "$interfaces" ]]; then
            printf "  ${red}✗ No network interfaces found${reset}\n"
        else
            while IFS= read -r iface; do
                # Skip loopback
                [[ "$iface" == "lo" ]] && continue
                
                local operstate
                operstate=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
                
                if [[ "$operstate" == "up" ]]; then
                    printf "  ${green}✓ Interface %s: UP${reset}\n" "$iface"
                elif [[ "$operstate" == "down" ]]; then
                    printf "  ${gray}○ Interface %s: DOWN${reset}\n" "$iface"
                else
                    printf "  ${yellow}⚠ Interface %s: %s${reset}\n" "$iface" "${operstate:-unknown}"
                fi
            done <<< "$interfaces"
        fi
    else
        printf "  ${red}✗ 'ip' command not found${reset}\n"
    fi
    # --- Default Gateway & Routing ---
    printf "\n${bold}Default Gateway & Routing:${reset}\n"
    local gateway=""
    if command -v ip &>/dev/null; then
        gateway=$(ip route show default 2>/dev/null | awk '/default/ {print $3}')
    fi
    if [[ -n "$gateway" ]]; then
        printf "  ${green}✓ Default gateway found: ${bold}%s${reset}\n" "$gateway"
    else
        printf "  ${red}✗ No default gateway configured${reset} ${gray}→ check local network/DHCP${reset}\n"
    fi
    # --- DNS Resolution & Resolvers ---
    printf "\n${bold}DNS Resolution & Resolvers:${reset}\n"
    local resolv_file="/etc/resolv.conf"
    if [[ -f "$resolv_file" ]]; then
        if grep -qE '^nameserver' "$resolv_file" 2>/dev/null; then
            printf "  ${green}✓ ${resolv_file} contains nameserver entries${reset}\n"
            while IFS= read -r ns_line; do
                if [[ "$ns_line" =~ ^nameserver[[:space:]]+(.+) ]]; then
                    printf "    ${gray}↳ nameserver: %s${reset}\n" "${BASH_REMATCH[1]}"
                fi
            done < <(grep -iE '^nameserver' "$resolv_file")
        else
            printf "  ${red}✗ ${resolv_file} has no nameserver entries${reset}\n"
        fi
    else
        printf "  ${yellow}⚠ ${resolv_file} not found${reset}\n"
    fi
    # Quick test lookup
    if command -v getent &>/dev/null; then
        if getent hosts archlinux.org &>/dev/null; then
            printf "  ${green}✓ DNS test lookup successful (archlinux.org)${reset}\n"
        else
            printf "  ${yellow}⚠ DNS test lookup failed (archlinux.org)${reset} ${gray}→ check internet/DNS settings${reset}\n"
        fi
    fi
    # --- Network Management Services ---
    printf "\n${bold}Network Management Services:${reset}\n"
    local net_services=("NetworkManager" "systemd-networkd" "iwd" "dhcpcd")
    local active_manager=false
    for svc in "${net_services[@]}"; do
        if systemctl is-active "$svc" &>/dev/null; then
            printf "  ${green}✓ Service active: ${bold}%s${reset}\n" "$svc"
            active_manager=true
        elif systemctl is-enabled "$svc" &>/dev/null; then
            printf "  ${gray}○ Service enabled but inactive: %s${reset}\n" "$svc"
        fi
    done
    if ! $active_manager; then
        printf "  ${yellow}⚠ No common network management daemon found active${reset}\n"
    fi
    # --- Xorg Network Listeners ---
    printf "\n${bold}Xorg Network Listeners:${reset}\n"
    local xorg_found=false
    if command -v ss &>/dev/null; then
        local xorg_listeners
        xorg_listeners=$(ss -tlnp 2>/dev/null | awk -F'[:/]' '/LISTEN/ && $NF ~ /X/ {print}')
        # More reliable: grep for X in the process column
        xorg_listeners=$(ss -tlnp 2>/dev/null | grep -E ':(60[0-9]{2})')
        if [[ -n "$xorg_listeners" ]]; then
            xorg_found=true
            while IFS= read -r line; do
                local addr
                addr=$(echo "$line" | awk '{print $5}')
                if [[ "$addr" == "127.0.0.1"* || "$addr" == "::1"* || "$addr" == "[::1]"* ]]; then
                    printf "  ${yellow}⚠ Xorg listening on localhost only: %s${reset}\n" "$addr"
                else
                    printf "  ${red}✗ Xorg listening on all interfaces: %s${reset} ${gray}→ add -nolisten tcp${reset}\n" "$addr"
                fi
            done <<< "$xorg_listeners"
        else
            printf "  ${green}✓ No Xorg TCP listeners detected${reset}\n"
        fi
    elif command -v netstat &>/dev/null; then
        local xorg_listeners
        xorg_listeners=$(sudo netstat -tlnp 2>/dev/null | grep -E ':(60[0-9]{2})')
        if [[ -n "$xorg_listeners" ]]; then
            xorg_found=true
            while IFS= read -r line; do
                local addr
                addr=$(echo "$line" | awk '{print $4}')
                if [[ "$addr" == "127.0.0.1"* || "$addr" == "::1"* ]]; then
                    printf "  ${yellow}⚠ Xorg listening on localhost only: %s${reset}\n" "$addr"
                else
                    printf "  ${red}✗ Xorg listening on all interfaces: %s${reset} ${gray}→ add -nolisten tcp${reset}\n" "$addr"
                fi
            done <<< "$xorg_listeners"
        else
            printf "  ${green}✓ No Xorg TCP listeners detected${reset}\n"
        fi
    else
        printf "  ${gray}○ 'ss' or 'netstat' not available — skipping Xorg check${reset}\n"
    fi   
    return 0
}

# END 