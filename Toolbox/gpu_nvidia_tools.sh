# BEGIN : Toolbox/gpu_nvidia_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 

# -- description 
function checkNvidiaTools {
    local missing_critical=()
    local missing_important=()
    local missing_optional=()
    for cmd in nvidia-smi nvidia-bug-report.sh nvidia-debugdump nvidia-persistenced nvidia-modprobe; do
        if ! is_command_valid "$cmd"; then
            missing_critical+=("$cmd")
        fi
    done
    for cmd in nvidia-settings nvidia-xconfig; do
        if ! is_command_valid "$cmd"; then
            missing_important+=("$cmd")
        fi
    done
    for cmd in nvidia-powerd nvidia-cuda-mps-control; do
        if ! is_command_valid "$cmd"; then
            missing_optional+=("$cmd")
        fi
    done
    # kernel module check (the real "is the driver working" test)
    if ! lsmod | grep -q "^nvidia "; then
        crit_echo "kernel module 'nvidia' is NOT loaded"
        crit_echo "  → check: lsmod | grep nvidia"
        crit_echo "  → check: dmesg | grep -i nvidia"
        crit_echo "  → likely cause: nvidia package not installed or DKMS build failed"
    fi
    if (( ${#missing_critical[@]} > 0 )); then
        crit_echo "missing critical tools: ${missing_critical[*]}"
    fi
    if (( ${#missing_important[@]} > 0 )); then
        warn_echo "missing important tools: ${missing_important[*]}"
    fi
    if (( ${#missing_optional[@]} > 0 )); then
        info_echo "missing optional tools: ${missing_optional[*]}"
    fi
}
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "NVIDIA GPU Tools"
    toolbox_item "tools" "show this ..." $width
    checkNvidiaTools
    toolbox_item "listNvidiaEnvironmentVariables" "show environment variables related to nvidia settings" $width
    toolbox_item "saveNvidiaEnvironmentVariables" "save nvidia env variables to config file" $width
    toolbox_item "loadNvidiaEnvironmentVariables" "load nvidia env variables from config file" $width
    toolbox_endl
    _codex_unset
}
tools 

# -- implementation 
_NV_MANAGED_VARS=(
    "__GLX_VENDOR_LIBRARY_NAME"
    "__NV_PRIME_RENDER_OFFLOAD"
    "CUDA_VISIBLE_DEVICES"
    "GBM_BACKEND"
    "__VK_LAYER_NV_optimus"
    "__EGL_VENDOR_LIBRARY_FILENAMES"
    "LIBVA_DRIVER_NAME"
    "VDPAU_DRIVER"
    "__GL_SYNC_TO_VBLANK"
    "__GL_MAX_FRAMES_ALLOWED"
    "__GL_THREADED_OPTIMIZATIONS"
    "__GL_SHADER_DISK_CACHE"
    "__GL_SHADER_DISK_CACHE_PATH"
    "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP"
    "__GL_SHOW_FPS"
    "__GL_FSAA_MODE"
    "__GL_ALLOW_FXAA_USAGE"
    "__GL_YIELD"
    "__GL_VRR_ALLOWED"
    "__GL_GSYNC_ALLOWED"
    "__GL_ALLOW_UNOFFICIAL_GSYNC"
    "__GL_EXPERIMENTAL_REENTRANCY"
    "__NV_DISABLE_EXPLICIT_SYNC"
    "__GL_MaxFramesAllowed"
    "__GL_SYNC_DISPLAY_DEVICE"
    "VK_ICD_FILENAMES"
    "CUDA_DEVICE_ORDER"
    "__GL_LOG_MAX_ANISO"
)
function listNvidiaEnvironmentVariables {
    source "$_SCRIPT_DIR/_codex.sh"
    echo ""
    # Print table header
    printf "\033[1;33m%-35s %-20s %-35s\033[0m\n" "VARIABLE" "CURRENT_VALUE" "POSSIBLE_VALUES"
    printf "%-35s %-20s %-35s\n" "------------------------------" "--------------------" "-----------------------------------"
    local reference_vars=(
        "__GLX_VENDOR_LIBRARY_NAME|nvidia (Forces proprietary NVIDIA driver for GLX context)"
        "__NV_PRIME_RENDER_OFFLOAD|1 (Enables PRIME offloading on Optimus hybrid laptops)"
        "GBM_BACKEND|nvidia-drm (Sets GBM graphics backend for Wayland/EGL streams)"
        "__VK_LAYER_NV_optimus|non_layer (Vulkan layer configuration for NVIDIA Optimus)"
        "__EGL_VENDOR_LIBRARY_FILENAMES|/usr/share/glvnd/egl_vendor.d/10_nvidia.json (Forces specific EGL library JSON path)"
        "LIBVA_DRIVER_NAME|nvidia (Sets VA-API hardware video acceleration backend)"
        "VDPAU_DRIVER|nvidia (Sets VDPAU video decoding and presentation backend)"
        "__GL_SYNC_TO_VBLANK|0 or 1 (VSync control: 0=Disabled/Off, 1=Enabled/On)"
        "__GL_SYNC_DISPLAY_DEVICE|CRT-0, DFP-0, etc. (Target display device for VSync synchronization)"
        "__GL_MAX_FRAMES_ALLOWED|1, 2, 4, ... (Pre-rendered frames limit; set to 1 to lower input lag)"
        "__GL_THREADED_OPTIMIZATIONS|0 or 1 (Enables driver worker threads to ease CPU bottlenecks)"
        "__GL_SHADER_DISK_CACHE|0 or 1 (Enables persistent disk caching for compiled shaders)"
        "__GL_SHADER_DISK_CACHE_PATH|/path/to/dir (Custom directory path to store shader disk cache)"
        "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP|0 or 1 (Bypasses the default 128MB shader cache size limit)"
        "__GL_SHOW_FPS|0 or 1 (Toggles built-in driver on-screen FPS performance counter)"
        "__GL_FSAA_MODE|0, 1, 2, ... (Full-scene anti-aliasing override configuration modes)"
        "__GL_ALLOW_FXAA_USAGE|0 or 1 (Allows or forbids Fast Approximate Anti-Aliasing globally)"
        "__GL_LOG_MAX_ANISO|0 to 16 (Sets maximum anisotropic filtering level for OpenGL applications)"
        "__GL_YIELD|NOTHING, USLEEP, SLEEP (Controls driver yield behavior during thread wait states)"
        "__GL_VRR_ALLOWED|0 or 1 (Enables Variable Refresh Rate / Adaptive Sync globally)"
        "__GL_GSYNC_ALLOWED|0 or 1 (Toggles G-Sync compatibility features)"
        "__GL_ALLOW_UNOFFICIAL_GSYNC|0 or 1 (Enables G-Sync on non-certified Adaptive-Sync monitors)"
        "__GL_EXPERIMENTAL_REENTRANCY|0 or 1 (Enables experimental thread reentrancy optimizations)"
        "__NV_DISABLE_EXPLICIT_SYNC|0 or 1 (Toggles explicit sync protocols on Wayland)"
        "__GL_MaxFramesAllowed|1, 2, 4, ... (Alternative casing alias for max pre-rendered frames)"
        "VK_ICD_FILENAMES|/path/to/nvidia_icd.json (Forces a specific Vulkan ICD JSON configuration file)"
        "CUDA_VISIBLE_DEVICES|0, 1, 2, ... (Restricts available GPU devices for CUDA apps)"
        "CUDA_DEVICE_ORDER|PCI_BUS_ID or FASTEST_FIRST (Controls order of CUDA device enumeration)"
    )
    for item in "${reference_vars[@]}"; do
        local var_name="${item%%|*}"
        local possible_vals="${item#*|}"
        local current_val="${!var_name:-}"
        if [[ -z "$current_val" ]]; then 
            printf "\033[90m%-35s %-20s %-35s\033[0m\n" "$var_name" "$current_val" "$possible_vals"
        else 
            printf "%-35s %-20s %-35s\n" "$var_name" "$current_val" "$possible_vals"
        fi 
    done
    echo ""
    _codex_unset
}
function saveNvidiaEnvironmentVariables {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_file="${1:-$HOME/.config/nvidia/env_vars.sh}"
    info_echo "Saving active NVIDIA environment variables to: $config_file"   
    # Utiliza a função nativa save_variables do _codex.sh para persistir com permissões seguras (600)
    
    __save_variables_to_export() {
        local file="$1"
        shift
        if [[ -z "$file" || $# -eq 0 ]]; then
            return 1
        fi
        local dir
        dir="$(dirname "$file")"
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || return 1
        fi
        local temp_file
        temp_file="$(mktemp "${file}.XXXXXX")" || return 1
        chmod 600 "$temp_file" || {
            rm -f "$temp_file"
            return 1
        }
        local var_name
        local var_def
        local value_expr
        for var_name in "$@"; do
            if var_def=$(declare -p "$var_name" 2>/dev/null); then
                value_expr="${var_def#*=}"
                printf 'export %s=%s\n' "$var_name" "$value_expr" >> "$temp_file" || {
                    rm -f "$temp_file"
                    return 1
                }
            fi
        done
        mv -f "$temp_file" "$file" || {
            rm -f "$temp_file"
            return 1
        }
        return 0
    }
    if __save_variables_to_export "$config_file" "${_NV_MANAGED_VARS[@]}"; then
        good_echo "Successfully saved NVIDIA environment variables."
        _codex_unset
        return 0
    else
        crit_echo "Failed to save NVIDIA environment variables."
        _codex_unset
        return 1
    fi
}
function loadNvidiaEnvironmentVariables {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_file="${1:-$HOME/.config/nvidia/env_vars.sh}"
    if [[ ! -f "$config_file" ]]; then
        crit_echo "Configuration file not found: $config_file"
        _codex_unset
        return 1
    fi
    info_echo "Loading NVIDIA environment variables from: $config_file"
    # 1. Carrega o ficheiro para o escopo
    # shellcheck source=/dev/null
    if source "$config_file"; then
        # 2. Força o export explícito de cada variável gerida para a sessão
        for var_name in "${_NV_MANAGED_VARS[@]}"; do
            if [[ -n "${!var_name+x}" ]]; then
                echo "$var_name updated"
            fi
        done
        good_echo "Successfully loaded and exported NVIDIA environment variables."
        _codex_unset
        return 0
    else
        crit_echo "Error occurred while sourcing configuration file."
        _codex_unset
        return 1
    fi
}

# END 