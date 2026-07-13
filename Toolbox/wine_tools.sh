# BEGIN : Toolbox/wine_tools.sh

# -- dependencies 
# 1. wine 
# 2. winetricks

# -- description 

# RED = 31 - 41
# GREEN = 32 - 42
# YELLOW = 33 - 43
# BLUE = 34 - 44
# MAGENTA = 35 - 45
# CYAN = 36 - 46
# WHITE = 37 - 47
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

echo ""
color_echo 33 "=== Wine Tools ==="
echo "createWineDirectory          : Creates a isolated Wine directory (Git-like layout)"
info_echo "                               -> Use 'cd' into it; functions look for local '.wineprefix_id'."
echo "wineDirectoryInfo            : Information on the current local Wine environment"
echo "wineSessionInfo              : Current global terminal environment variables"
echo "wineInstallWinetricksPackage : Install winetricks packages locally"
echo "wineDirectoryRun             : Run commands using the local directory's prefix (works on subdirectories)"
info_echo "                               -> Example: wineRun winecfg  OR  wineRun application.exe"
echo "wineDesktop                  : Explore the wineprefix via an emulated desktop window"
echo "exportWinePrefix             : Export this local prefix to your active terminal session"
echo "makeWineKissable             : De-bloat Wine's forced Linux desktop & MIME integrations"
echo "exportWineNvidiaSetup        : Bind NVIDIA GPU stubs"
echo ""

# -- implementation
function makeWineKissable {
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
}
function createWineDirectory {
    # createWineDirectory <path>
    # 1. Creates a folder based on <path> with a wine prefix folder inside it
    # 2. Creates a tracking file .wineprefix_id to store the absolute wine prefix path
    local target_dir="$1"
    if [ -z "$target_dir" ]; then
        crit_echo "Error: Target directory path is required."
        info_echo "Usage: createWineDirectory <path/to/project>"
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
        return 1
    fi
    # Write the tracking file (stores the absolute path of the prefix)
    echo "$prefix_path" > "$id_file"
    info_echo ">>> Success! Wine environment linked to: $target_dir"
    info_echo "    Run 'cd $target_dir && wineDirectoryInfo' to view status."
}
function wineInstallWinetricksPackage {
    # Install winetricks package only if .wineprefix_id exists in the CURRENT directory.
    # No Git dependency, no parent directory search.
    if [ "$#" -eq 0 ]; then
        crit_echo "Error: Package name required."
        info_echo "Usage: wineInstallWinetricksPackage <package1> [package2...]"
        return 1
    fi
    local packages=("$@")
    local id_file="./.wineprefix_id"
    # Simple check: Does the file exist right here?
    if [ ! -f "$id_file" ]; then
        crit_echo "Error: Not a Wine-managed directory."
        crit_echo "    File '.wineprefix_id' not found in current directory."
        info_echo "    Run 'createWineDirectory .' to initialize this folder."
        return 1
    fi
    local prefix_path
    prefix_path=$(cat "$id_file")
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Target prefix not found at '$prefix_path'."
        crit_echo "    The path stored in '.wineprefix_id' does not exist."
        return 1
    fi
    if ! command -v winetricks &> /dev/null; then
        crit_echo "Error: 'winetricks' command not found."
        return 1
    fi
    info_echo ">>> Installing packages in: $prefix_path"
    info_echo "    Packages: ${packages[*]}"
    # Execute winetricks with the specific prefix
    WINEPREFIX="$prefix_path" winetricks "${packages[@]}"
    if [ $? -eq 0 ]; then
        info_echo ">>> Installation complete."
    else
        crit_echo ">>> Installation failed or was interrupted."
        return 1
    fi
}

# -- implementation | info
function _showWineEnvVariables {
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
}
function _confirmWinetricks {
    # Helper to prompt user before running winetricks list-installed
    local prefix_path="$1"
    echo ""
    # -p allows a prompt string, -n1 reads exactly 1 character
    read -p "    List installed Winetricks packages? (y/N): " -n 1 -r
    echo "" # Move to a new line
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        info_echo "      (Skipped Winetricks package listing)"
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
}
function wineDirectoryInfo {
    # Shows info only if .wineprefix_id exists in CURRENT directory.
    local id_file="./.wineprefix_id"
    if [ ! -f "$id_file" ]; then
        crit_echo "Error: Not a Wine-managed directory."
        crit_echo "    File '.wineprefix_id' not found in current directory."
        return 1
    fi
    local prefix_path
    prefix_path=$(cat "$id_file")
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Prefix directory missing at '$prefix_path'!"
        return 1
    fi
    info_echo "=== Wine Environment Info ==="
    echo "    Prefix Path: $prefix_path"
    local wine_ver
    wine_ver=$(WINEPREFIX="$prefix_path" wine --version 2>/dev/null | head -n1)
    echo "    Wine Version: $wine_ver"
    # Show active graphics & Wine variables
    _showWineEnvVariables
    # Prompt for Winetricks
    _confirmWinetricks "$prefix_path"
}
function wineSessionInfo {
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
    return 0
}

# -- implementation | run
function wineDirectoryRun {
    local current_dir="$PWD"
    local id_file=""
    local project_root=""
    # Traverse upwards to find the .wineprefix_id file
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.wineprefix_id" ]; then
            id_file="$current_dir/.wineprefix_id"
            project_root="$current_dir"
            break
        fi
        current_dir=$(dirname "$current_dir")
    done
    # Fail out if we couldn't find the anchor file anywhere up the tree
    if [ -z "$id_file" ]; then
        crit_echo "Error: '.wineprefix_id' not found in this directory or any parent directories."
        return 1
    fi
    local prefix_path
    prefix_path=$(cat "$id_file")
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Prefix not found at '$prefix_path'."
        return 1
    fi
    # Log errors to the project root directory instead of the active subdirectory
    local log_file="$project_root/errors.txt"
    echo "" >> "$log_file"
    echo "======================================================================" >> "$log_file"
    echo "Session $(date '+%Y-%m-%d %H:%M:%S') " >> "$log_file"
    echo "" >> "$log_file"
    # Smart wrapper: Handles direct command passing (winecfg) or wrapper fallbacks
    _showWineEnvVariables
    if [[ "$1" == wine* || "$1" == winetricks ]]; then
        WINEPREFIX="$prefix_path" "$@" &>> "$log_file"
    else
        WINEPREFIX="$prefix_path" wine "$@" &>> "$log_file"
    fi
}
function exportWinePrefix {
    # Run a wine command in the current directory's prefix.
    if [ ! -f "./.wineprefix_id" ]; then
        crit_echo "Error: '.wineprefix_id' not found in current directory."
        return 1
    fi
    local prefix_path
    prefix_path=$(cat "./.wineprefix_id")
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Prefix not found at '$prefix_path'."
        return 1
    fi
    echo "Wine Prefix : $prefix_path"
    export WINEPREFIX="$prefix_path"
}
function wineDesktop {
    # Open just the Wine desktop environment (Explorer) in a virtual window.
    # USAGE: wineDesktop <resolution> <name>
    # Example: wineDesktop 1280x720 mysession
    # 1. Validate arguments
    if [ -z "$1" ] || [ -z "$2" ]; then
        crit_echo "Error: Missing arguments."
        echo "Usage: wineDesktop <resolution> <name>"
        echo "Example: wineDesktop 1280x720 mysession"
        echo "... 1600x900 1366x768 1280x720 800x600"
        return 1
    fi
    local resolution="$1"
    local name="$2"
    # 2. Validate Prefix ID file
    if [ ! -f "./.wineprefix_id" ]; then
        crit_echo "Error: '.wineprefix_id' not found in current directory."
        return 1
    fi
    local prefix_path
    prefix_path=$(cat "./.wineprefix_id")
    # 3. Validate Prefix Directory
    if [ ! -d "$prefix_path" ]; then
        crit_echo "Error: Prefix not found at '$prefix_path'."
        return 1
    fi
    # 4. Launch Wine Explorer
    # Syntax: wine explorer /desktop=<name>,<resolution> explorer
    # We use 'explorer' as the command to launch the shell (taskbar/start menu)
    echo "" >> ./errors.txt
    echo "======================================================================" >> ./errors.txt
    echo "Session [ $name $resolution ] $(date '+%Y-%m-%d %H:%M:%S') " >> ./errors.txt
    echo "" >> ./errors.txt
    _showWineEnvVariables
    WINEPREFIX="$prefix_path" wine explorer "/desktop=${name},${resolution}" explorer &>> ./errors.txt &
    # Optional: Disown the process so it survives if the script exits immediately
    disown
}

# -- implementation | environment settings
function exportWineNvidiaSetup {
    # 1. Direct 3D apps to offload rendering to the NVIDIA GPU
    echo "... Direct 3D apps to offload rendering to the NVIDIA GPU"
    export __NV_PRIME_RENDER_OFFLOAD=1
    # 2. Force GLX to use the NVIDIA driver instead of Mesa/AMD
    echo "... Force GLX to use the NVIDIA driver instead of Mesa/AMD"
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    warn_echo "Exported NVIDIA Prime Environment Variable Settings"
    return 0
}

# END 