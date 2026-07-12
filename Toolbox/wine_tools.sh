# BEGIN : Toolbox/wine_tools.sh

# -- dependencies 
# 1. wine 
# 2. winetricks

# -- description 
# A toolbox for managing file permissions with colored output.

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
function warn_echo {
    color_echo 33 "$@"
}
function crit_echo {
    color_echo 31 "$@"
}
function info_echo {
    color_echo 36 "$@" 
}

echo ""
color_echo 33 "=== Wine Tools ==="
echo "makeWineKissable : remove all the bloat to follow the 'Keep It Simple, Stupid' arch-linux's standart."
echo ""

# -- helpers
# helpers begin with underscore _name()

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

function createWineLauncherScript {
    # USAGE: createWineLauncherScript <name> [ <wineprefixpath> [ <winetricks_packages> ... ] ]
    # createWineLauncherScript <name> : creates a default wine launcher script on current directory with dummies and commented-out lines to prevent accidental usage before setup. The <name> is the name of the script.
    # createWineLauncherScript <name> <path> : creates a wine launcher script on current directory with path pointing to wineprefix (where the data will be stored).
    # createWineLauncherScript <name> <path> [ <winetricks_packages> ... ] : creates a wine launcher script on current directory with path pointing to wineprefix and with a initial installing process using winetricks writed on this generated script. Use a .wine_setup file on wineprefix folder to indicate that the packages are already installed and to make the script skip the installation and go directly to execution.
    return 1
}

# END 