# BEGIN : Toolbox/grub_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Grub Tools"
    crit_echo "... never try to edit /boot/grub/grub.cfg directly"
    crit_echo "... edit /etc/default/grub and regenerate the config"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "gotoGrubD" "change to /etc/grub.d directory" $width
    toolbox_item "viewDefaultGrub" "view the /etc/default/grub file" $width
    toolbox_item "getGrubMenuentries [file]" "get entries from grub.cfg to be added on 40_custom" $width
    toolbox_item "regenerateGrub" "Arch/Debian/Fedora grub regeneration" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
function viewDefaultGrub {
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done < <(grep -iE "GRUB_" /etc/default/grub)
    local comm_color='\033[90m'
    local active_color='\033[32m'
    local reset='\033[0m'
    for line in "${lines[@]}"; do
        # strip leading whitespace to detect comments
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        if [[ "$trimmed" == \#* ]]; then
            printf "${comm_color}%s${reset}\n" "$line"
        else
            printf "${active_color}%s${reset}\n" "$line"
        fi
    done
}   
function gotoGrubD {
    cd "/etc/grub.d"
}
function getGrubMenuentries {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_file="${1:-/boot/grub/grub.cfg}"
    if [[ ! -f "$config_file" ]]; then
        crit_echo "Error: Configuration file '$config_file' not found." >&2
        warn_echo "Usage: getGrubMenuentries [path]"
        _codex_unset
        return 1
    fi
    echo ""
    auto_escalate awk '
        /^menuentry[[:space:]]|^submenu[[:space:]]/ {
            inside = 1
            depth = 0
        }

        inside {
            print

            line = $0
            opens = gsub(/\{/, "{", line)
            closes = gsub(/\}/, "}", line)

            depth += opens - closes

            if (depth <= 0) {
                inside = 0
                print ""
            }
        }
    ' "$config_file"
    _codex_unset
}
function regenerateGrub {
    source "$_SCRIPT_DIR/_codex.sh"
    # --- 1. Detect boot mode ---
    local boot_mode
    if [ -d /sys/firmware/efi ]; then
        boot_mode="efi"
    else
        boot_mode="bios"
    fi
    # --- 2. Detect distro family via /etc/os-release ---
    local distro_family
    local id id_like
    #id=$(grep -m1 '^ID=' /etc/os-release 2>/dev/null | cut -d'"' -f2)
    #id_like=$(grep -m1 '^ID_LIKE=' /etc/os-release 2>/dev/null | cut -d'"' -f2)    
    id=$(grep -m1 '^ID=' /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    id_like=$(grep -m1 '^ID_LIKE=' /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    case "$id $id_like" in
        *fedora*|*rhel*|*centos*)  distro_family="fedora" ;;
        *debian*|*ubuntu*)         distro_family="debian" ;;
        *arch*)                     distro_family="arch"   ;;
        *)
            # Fallback: detect by which binary exists
            if command -v grub2-mkconfig &>/dev/null; then
                distro_family="fedora"
            elif command -v grub-mkconfig &>/dev/null; then
                distro_family="arch"
            else
                crit_echo "Error: Could not detect distro family or find grub-mkconfig."
                _codex_unset
                return 1
            fi
            ;;
    esac
    # --- 3. Determine command and output path ---
    local cmd output_path
    case "$distro_family" in
        arch)
            cmd="grub-mkconfig"
            if [ "$boot_mode" = "efi" ]; then
                # ESP is typically mounted at /boot/efi; grub.cfg lives on the ESP
                if [ -d /boot/efi ]; then
                    output_path="/boot/efi/EFI/arch/grub.cfg"
                else
                    output_path="/boot/grub/grub.cfg"
                fi
            else
                output_path="/boot/grub/grub.cfg"
            fi
            ;;
        debian)
            cmd="grub-mkconfig"
            if [ "$boot_mode" = "efi" ]; then
                if [ -d /boot/efi ]; then
                    output_path="/boot/efi/EFI/debian/grub.cfg"
                else
                    output_path="/boot/grub/grub.cfg"
                fi
            else
                output_path="/boot/grub/grub.cfg"
            fi
            ;;
        fedora)
            cmd="grub2-mkconfig"
            if [ "$boot_mode" = "efi" ]; then
                output_path="/boot/efi/EFI/fedora/grub.cfg"
            else
                output_path="/boot/grub2/grub.cfg"
            fi
            ;;
    esac
    # --- 4. Verify the output directory exists ---
    if [ ! -d "$(dirname "$output_path")" ]; then
        crit_echo "Error: Output directory '$(dirname "$output_path")' does not exist."
        crit_echo "Is the ESP mounted? (check /etc/fstab)"
        _codex_unset
        return 1
    fi
    # --- 5. Report and execute ---
    echo ""
    warn_echo "Distro family : $distro_family"
    echo "Boot mode     : $boot_mode"
    echo "Command       : $cmd -o $output_path"
    if ! token_prompt "Confirmation" "are you sure to regenerate grub.cfg"; then 
        _codex_unset 
        return 0
    fi 
    sudo "$cmd" -o "$output_path"
    local rc=$?
    if [ $rc -eq 0 ]; then
        good_echo "GRUB configuration regenerated successfully."
    else
        crit_echo "Error: $cmd exited with code $rc."
    fi
    _codex_unset
    return $rc
}   

# END