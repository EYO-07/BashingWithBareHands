# BEGIN : Toolbox/wine_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 
# 1. wine 
# 2. winetricks

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Wine Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "readmeWineTools" "... please execute this command on terminal" $width
    if all_commands_valid "wine" "winetricks"; then 
        toolbox_item "createWineDirectory" "Creates a isolated Wine Prefix Directory (Git-like layout)" $width
        toolbox_item "wineDirectoryInfo" "Information on the current local Wine environment based on .wineprefix_id" $width
        toolbox_item "wineSessionInfo" "Current global terminal environment variables." $width
        toolbox_item "wineInstallWinetricksPackage" "Install winetricks packages locally on wine directory" $width
        toolbox_item "wineDirectoryRun" "Run commands using the local directory's prefix .wineprefix_id (works on subdirectories)" $width
        toolbox_item "wineDesktop" "Explore the wineprefix directory via an emulated desktop window" $width
        toolbox_item "exportWinePrefix" "Export this local prefix to your active terminal session" $width
        toolbox_item "makeWineKissable" "De-bloat Wine's forced Linux desktop & MIME integrations" $width
        toolbox_item "exportWineNvidiaSetup" "Bind NVIDIA GPU stubs (terminal session only)" $width
        toolbox_item "gotoWineDirectoryRoot" "go to current wine directory root" $width
        toolbox_item "gotoWineDirectoryC" "go to C:/" $width
        toolbox_item "gotoWineDirectoryAppData" "go to %AppData%" $width
    else 
        crit_echo "... these tools requires wine and winetricks"
    fi 
    toolbox_endl
    _codex_unset
}
tools 
function readmeWineTools {
    source "$_SCRIPT_DIR/_codex.sh"
    echo ""
    warn_echo "=== Wine Tools ==="
    info_echo "this is a collection of bash functions and aliases to handle wineprefixes on terminal."
    echo "the idea is to make a wineprefix directory behave as git-directory."
    echo "1. wine prefix is the path for a wine's window directory where wine install their programs."
    echo "... installing using a custom wine prefix is installing in a custom directory."
    echo "... you can manage different setups for wine just changing wine prefixes."
    echo "2. the tools on this script uses the file .wineprefix_id to identify the prefix."
    echo "... use 'ls -a' inside the created wine directory to locate the .wineprefix_id"
    echo ""
    echo "To create a wine directory, use the function createWineDirectory"
    echo "... this function will create the prefix folder and open winecfg gui for first setup."
    echo ""
    echo "After the creation, change the diretory to the created directory and check the prefix with wineDirectoryInfo"
    echo ""
    echo "To install things on your wine prefix, inside the wine directory, use exportWinePrefix"
    echo "... you can check if the exporting succeed with wineSessionInfo."
    echo "... then you can change to any folder and executes the installer."
    warn_echo "... exportWinePrefix only changes the current terminal session variables"
    warn_echo "... so closing or opening other terminal instance will reset to default wineprefix."
    echo ""
    echo "To use the programs installed on your wine directory, you can use the function wineDesktop"
    echo "... which will open an explorer.exe desktop emulator."
    echo "Alternatively, you can explore the wine_prefix contents directly on terminal"
    echo "... find the executable and run using 'wineDirectoryRun myapp.exe'."
    info_echo "wineDesktop is useful for programs that have ill behaviour on fullscreen."
    echo ""
    warn_echo "Optionally, if you are using multi-card setup, you can assert nvidia graphics by using "
    warn_echo "... exportWineNvidiaSetup before using the other functions."
    echo ""
    echo "If you program needs specific runtimes, you can install them using wineInstallWinetricksPackage."
    echo "... use it inside the root of wine directory (where .wineprefix_id is located)."
    echo ""
    info_echo "If you know how to, you can use those functions to create a script executable on .local/bin"
    info_echo "... but be sure to use 'cd ...' to the wine directory and to source the script correctly."
    _codex_unset
}

# -- helpers
function _resolve_wine_context { # _resolve_wine_context [starting_path]
    local current_dir="${1:-$PWD}"
    if [[ "$current_dir" != /* ]]; then
        current_dir="$(pwd)/$current_dir"
    fi
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.wineprefix_id" ]; then
            local prefix_path
            prefix_path=$(cat "$current_dir/.wineprefix_id")
            if [ -d "$prefix_path" ]; then
                echo "$current_dir|$prefix_path"
                return 0
            fi
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}
function _showWineEnvVariables {
    source "$_SCRIPT_DIR/_codex.sh"
    # Helper to print specific Wine & Graphics environment variables if set
    local vars=(
        # Wine Renderers / Backends
        "WINE_D3D_CONFIG" "WINE_D3D_CUSTOM_MATRIX" "WINEGYLE" 
        # DXVK / VKD3D / Vulkan
        "DXVK_HUD" "DXVK_LOG_LEVEL" "DXVK_CONFIG_FILE" "DXVK_FILTER_DEVICE_NAME"
        "VKD3D_DEBUG" "VKD3D_SHADER_DEBUG" "VK_INSTANCE_LAYERS"
        # Gamescope / Proton-related Graphics
        "gamescope" "MESA_GL_VERSION_OVERRIDE" "__GLX_VENDOR_LIBRARY_NAME" 
        "__NV_PRIME_RENDER_OFFLOAD" "__VK_LAYER_NV_optimus"
        # General Wine Behavior
        "WINEDEBUG" "WINEARCH" "WINELLDB" "WINEDLLOVERRIDES"
    )
    info_echo "    Relevant Environment Variables:"
    local found_any=false
    for var in "${vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo "      - $var=${!var}"
            found_any=true
        fi
    done
    if [ "$found_any" = false ]; then
        warn_echo "      (None of the tracked graphics/Wine variables are currently set)"
    fi
    _codex_unset
}
function _confirmWinetricks {
    source "$_SCRIPT_DIR/_codex.sh"
    # Helper to prompt user before running winetricks list-installed
    local prefix_path="$1"
    echo ""
    # -p allows a prompt string, -n1 reads exactly 1 character
    read -p "    List installed Winetricks packages? (y/N): " -n 1 -r
    echo "" # Move to a new line
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        info_echo "      (Skipped Winetricks package listing)"
        _codex_unset
        return 0
    fi
    info_echo "      Fetching installed packages..."
    if command -v winetricks &> /dev/null; then
        local installed_pkgs
        installed_pkgs=$(WINEPREFIX="$prefix_path" winetricks list-installed 2>/dev/null)
        if [ -n "$installed_pkgs" ]; then
            echo "$installed_pkgs" | while read -r line; do
                [[ -z "$line" ]] && continue
                echo "      - $line"
            done
        else
            warn_echo "      (No winetricks packages installed)"
        fi
    else
        warn_echo "      (Winetricks command not found in PATH)"
    fi
    _codex_unset
}

# -- implementation
function makeWineKissable {
    source "$_SCRIPT_DIR/_codex.sh"
    info_echo ">>> Starting Wine Desktop Cleanup..."
    # 2. Cleanup: Remove existing MIME types
    warn_echo ">> Removing MIME type packages..."
    rm -fv ~/.local/share/mime/packages/x-wine*
    warn_echo ">> Removing application MIME types..."
    rm -fv ~/.local/share/mime/application/x-wine-extension*
    # 3. Cleanup: Remove Desktop Entries (Context Menus & Start Menu)
    warn_echo ">> Removing Wine extension desktop entries..."
    rm -fv ~/.local/share/applications/wine-extension*
    warn_echo ">> Removing Wine program menu entries..."
    rm -rfv ~/.local/share/applications/wine
    # 4. Cleanup: Remove Icons
    warn_echo ">> Removing Wine-specific icons..."
    rm -fv ~/.local/share/icons/hicolor/*/*/application-x-wine-extension*
    rm -fv ~/.local/share/icons/????_*.{xpm,png} 2>/dev/null
    rm -fv ~/.local/share/icons/*-x-wine-*.{xpm,png} 2>/dev/null
    # 5. Cleanup: Remove Menu Categories
    warn_echo ">> Cleaning up merged menu entries..."
    rm -fv ~/.config/menus/applications-merged/wine*
    rm -fv ~/.local/share/desktop-directories/wine*
    # Remove Wine Start Menu shortcuts
    warn_echo ">> Removing Wine Start Menu entries..."
    rm -rfv ~/.local/share/applications/wine/Programs
    rm -fv ~/.local/share/applications/wine*.desktop   
    # Force clear the MIME cache
    rm -fv ~/.local/share/applications/mimeinfo.cache   
    # List wine files on /usr/bin for manual deletion
    echo ""
    warn_echo ">> Listing sh*ts dropped directly on /usr/bin/ ..."
    warn_echo "    please remove unwanted symlinks (like notepad) using 'sudo rm /usr/bin/<name>'"
    ls -la /usr/bin | grep wine
    echo ""
    # 6. Update Databases
    warn_echo ">> Updating MIME and Desktop databases..."
    if command -v update-mime-database &> /dev/null; then
        update-mime-database ~/.local/share/mime/
    fi
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications/
    fi
    info_echo ">>> Cleanup Complete! Wine is now 'kissable'."
    info_echo "    Note: If you install new Windows software, associations might try to return."
    info_echo "    To permanently prevent this, run: winecfg -> Desktop Integration -> Uncheck 'Manage File Associations'"
    info_echo "    Also, run: winecfg -> Libraries -> Type: winemenubuilder.exe -> Add Edit Disable and Apply"
    _codex_unset
}
function createWineDirectory {
    source "$_SCRIPT_DIR/_codex.sh"
    # createWineDirectory <path>
    # 1. Creates a folder based on <path> with a wine prefix folder inside it
    # 2. Creates a tracking file .wineprefix_id to store the absolute wine prefix path
    local target_dir="$1"
    if [ -z "$target_dir" ]; then
        crit_echo "Error: Target directory path is required."
        info_echo "Usage: createWineDirectory <path/to/project>"
        _codex_unset
        return 1
    fi
    # Resolve absolute path
    if [[ "$target_dir" != /* ]]; then
        target_dir="$(pwd)/$target_dir"
    fi
    local prefix_path="$target_dir/wine_prefix"
    local id_file="$target_dir/.wineprefix_id"
    local error_file="$target_dir/errors.txt"
    if [ -d "$target_dir" ]; then
        warn_echo "Directory '$target_dir' already exists."
        if [ -f "$id_file" ]; then
            crit_echo "Error: This directory is already initialized as a Wine environment."
            _codex_unset
            return 1
        fi
    else
        info_echo ">>> Creating project directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    info_echo ">>> Initializing Wine Prefix inside: $prefix_path"
    # Create the actual prefix
    #WINEPREFIX="$prefix_path" wineboot --init &> "$error_file"
    WINEDLLOVERRIDES="winemenubuilder.exe=d" \
        WINEPREFIX="$prefix_path" \
        winecfg &> "$error_file"
    if [ $? -ne 0 ]; then
        crit_echo "Error: Failed to initialize Wine prefix."
        _codex_unset
        return 1
    fi
    # Write the tracking file (stores the absolute path of the prefix)
    echo "$prefix_path" > "$id_file"
    info_echo ">>> Success! Wine environment linked to: $target_dir"
    info_echo "    Run 'cd $target_dir && wineDirectoryInfo' to view status."
    _codex_unset
}
function wineInstallWinetricksPackage {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then
        crit_echo "Error: Package name required."
        info_echo "Usage: wineInstallWinetricksPackage <package1> [package2...]"
        _codex_unset
        return 1
    fi
    local packages=("$@")
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    if ! command -v winetricks &> /dev/null; then
        crit_echo "Error: 'winetricks' command not found."
        _codex_unset
        return 1
    fi
    info_echo ">>> Installing packages in: $prefix_path"
    info_echo "    Packages: ${packages[*]}"   
    WINEPREFIX="$prefix_path" winetricks "${packages[@]}"
    if [ $? -eq 0 ]; then
        info_echo ">>> Installation complete."
    else
        crit_echo ">>> Installation failed or was interrupted."
        _codex_unset
        return 1
    fi
    _codex_unset
}

# -- implementation | info
function wineDirectoryInfo {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # -- 
    info_echo "=== Wine Environment Info ==="
    echo "    Prefix Path: $prefix_path"
    local wine_ver
    wine_ver=$(WINEPREFIX="$prefix_path" wine --version 2>/dev/null | head -n1)
    echo "    Wine Version: $wine_ver"
    # Show active graphics & Wine variables
    _showWineEnvVariables
    # Prompt for Winetricks
    _confirmWinetricks "$prefix_path"
    _codex_unset
}
function wineSessionInfo {
    source "$_SCRIPT_DIR/_codex.sh"
    # Checks active Wine session variables and environment status.
    local prefix_path
    local is_default=false
    if [ -n "$WINEPREFIX" ]; then
        prefix_path="$WINEPREFIX"
    else
        prefix_path="$HOME/.wine"
        is_default=true
    fi
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Active Wine prefix directory missing at '$prefix_path'!"
        if [ "$is_default" = true ]; then
            warn_echo "    (WINEPREFIX variable is not set; using default location)"
        else
            echo "    (WINEPREFIX is set to: $WINEPREFIX)"
        fi
        _codex_unset
        return 1
    fi
    info_echo "=== Active Wine Session Info ==="
    if [ "$is_default" = true ]; then
        echo "    Source: Default (WINEPREFIX variable not set)"
    else
        echo "    Source: Environment Variable (WINEPREFIX)"
        echo "    Variable Value: $WINEPREFIX"
    fi    
    echo "    Resolved Prefix Path: $prefix_path"
    local wine_ver
    wine_ver=$(WINEPREFIX="$prefix_path" wine --version 2>/dev/null | head -n1)
    if [ -n "$wine_ver" ]; then
        echo "    Wine Version: $wine_ver"
    else
        warn_echo "    Wine Version: (Unable to detect - Wine binary missing or not executable)"
    fi
    # Show active graphics & Wine variables
    _showWineEnvVariables   
    # Prompt for Winetricks
    _confirmWinetricks "$prefix_path"
    _codex_unset
    return 0
}

# -- implementation | run
function wineDirectoryRun {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # Log errors to the project root directory instead of the active subdirectory
    local log_file="$project_root/errors.txt"
    echo "" >> "$log_file"
    echo "======================================================================" >> "$log_file"
    echo "Session '$1 $2' $(date '+%Y-%m-%d %H:%M:%S') " >> "$log_file"
    echo "" >> "$log_file"
    # Smart wrapper: Handles direct command passing (winecfg) or wrapper fallbacks
    info_echo "=== Wine Environment Info ==="
    echo "    Prefix Path: $prefix_path"
    local wine_ver
    wine_ver=$(WINEPREFIX="$prefix_path" wine --version 2>/dev/null | head -n1)
    echo "    Wine Version: $wine_ver"
    _showWineEnvVariables
    if [[ "$1" == wine* || "$1" == winetricks ]]; then
        WINEPREFIX="$prefix_path" "$@" &>> "$log_file" &
    else
        WINEPREFIX="$prefix_path" wine "$@" &>> "$log_file" &
    fi
    disown
    _codex_unset
}
function exportWinePrefix {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    echo "Wine Prefix : $prefix_path"
    export WINEPREFIX="$prefix_path"
    warn_echo "... now using 'wine <program>' outside the directory will use/install on this wineprefix"
    warn_echo "... check with 'wineSessionInfo' to see details about the current wineprefix loaded"
    _codex_unset
}
function wineDesktop {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ -z "$1" ] || [ -z "$2" ]; then
        crit_echo "Error: Missing arguments."
        echo "Usage: wineDesktop <resolution> <name>"
        echo "Example: wineDesktop 1280x720 mysession"
        echo "... 1600x900 1366x768 1280x720 800x600"
        _codex_unset
        return 1
    fi
    local resolution="$1"
    local name="$2"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    local log_file="$project_root/errors.txt"
    echo "" >> "$log_file"
    echo "======================================================================" >> "$log_file"
    echo "Session [ $name $resolution ] $(date '+%Y-%m-%d %H:%M:%S') " >> "$log_file"
    echo "" >> "$log_file"   
    _showWineEnvVariables
    WINEPREFIX="$prefix_path" wine explorer "/desktop=${name},${resolution}" explorer &>> "$log_file" &
    disown
    _codex_unset
}
function gotoWineDirectoryRoot {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    cd "$project_root"
    _codex_unset
    return 0
}
function gotoWineDirectoryC {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    cd "$project_root/wine_prefix/drive_c"
    _codex_unset
}
function gotoWineDirectoryAppData {
    source "$_SCRIPT_DIR/_codex.sh"
    # --
    local context
    context=$(_resolve_wine_context) || {
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        _codex_unset
        return 1
    }
    local project_root="${context%%|*}"
    local prefix_path="${context##*|}"
    # --
    cd "$project_root/wine_prefix/drive_c/users/$USER/AppData"
    _codex_unset
}

# -- implementation | environment settings
function exportWineNvidiaSetup {
    source "$_SCRIPT_DIR/_codex.sh"
    info_echo "... Enabling NVIDIA PRIME Render Offload"
    # 1. Direct OpenGL applications to render on the NVIDIA GPU.
    export __NV_PRIME_RENDER_OFFLOAD=1
    # 2. Force GLX to use the NVIDIA vendor library.
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    # 3. Prefer the NVIDIA GPU for Vulkan applications.
    export __VK_LAYER_NV_optimus=NVIDIA_only
    # 4. Force Vulkan to use the NVIDIA ICD (optional).
    # Uncomment if multiple Vulkan ICDs cause problems.
    # export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
    # 5. Prefer NVIDIA EGL implementation (usually not needed).
    # Uncomment only if you have EGL issues.
    # export __EGL_VENDOR_LIBRARY_FILENAMES="/usr/share/glvnd/egl_vendor.d/10_nvidia.json"
    # 6. Enable NVIDIA shader disk cache.
    #export __GL_SHADER_DISK_CACHE=1
    #export __GL_SHADER_DISK_CACHE_PATH="${HOME}/.nv_shader_cache"
    # 7. DXVK HUD (optional, useful for verifying GPU usage).
    # export DXVK_HUD="devinfo,fps"
    # 8. VKD3D debug output (optional).
    # export VKD3D_DEBUG=none
    warn_echo "Exported NVIDIA PRIME environment variables."
    _codex_unset
    return 0
}

# END 