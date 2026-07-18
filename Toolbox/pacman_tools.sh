# BEGIN : ~/Toolbox/pacman_tools.sh
# ... collection of pacman toplevel terminal functions and aliases for linux
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. pacman 
# 2. pacman-contrib : showPackageRelations

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=9
    toolbox_title "Pacman Package Manager Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "listInstalledPackages [ <kw1> <kw2> ... ]" "search packages by matching keywords" $width
    toolbox_item 'listInstalledPackages "<kw1>|<kw2>|..."' "search for multiple packages" $width
    toolbox_item "checkInstalledPackages" "check for upgradable packages" $width
    toolbox_item "systemUpdate" "repository sync and update" $width
    toolbox_item "searchPackages <keyword1> [keyword2 ...]" "search packages on official repos" $width
    toolbox_item "installPackage <package1> [package2 ...]" "install packages from official repos" $width
    toolbox_item "packageInfo" "show detailed information about a package" $width
    toolbox_item "listOrphanPackages" "list orphan dependency packages" $width
    toolbox_item "removePackage" "remove/uninstall package keeping configs" $width
    toolbox_item "purgePackage" "remove and remove configs" $width
    toolbox_item "cleanPackageCache" "clean the pacman cache" $width
    toolbox_item "packageRelations" "show direct parent child dependency relations" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Package Managers { Arch-Linux }"
    local width=4
    inventory_item 1 "yay -Qu" "check update status for AUR and official packages" $width
    inventory_item 2 "yay -S <package>" "install/update a AUR package using yay" $width
    inventory_item 3 "fc-cache -fv" "update the font cache" $width
    inventory_item 4 "mkinitcpio -P" "regenerate initramfs, necessary on drivers and kernel updates" $width
    #inventory_item 0 "" "" $width
    inventory_endl 
    _codex_unset
}

# -- implementations 
function checkInstalledPackages {
    source "$_SCRIPT_DIR/_codex.sh"
    sudo pacman -Sy "$@"
    pacman -Qu "$@" | warn_echo
    _codex_unset
}
function systemUpdate {
    source "$_SCRIPT_DIR/_codex.sh"
    sudo pacman -Syu "$@"
    _codex_unset
}
function searchPackages {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then 
        echo "USAGE: searchPackages <keyword1> [keyword2 ...]"
        _codex_unset
        return 0
    fi
    # 1. Capture the search results
    local search_results
    search_results=$(pacman -Ss "$@")
    # 2. Count the actual number of package matches 
    # (pacman -Ss outputs 2 lines per package, so we count lines starting with a repo name)
    local match_count
    match_count=$(echo "$search_results" | grep -E '^[a-zA-Z0-9_-]+/' | wc -l)
    # Case 0: No packages found
    if [ "$match_count" -eq 0 ]; then
        color_echo 31 "No packages found matching: $@"
        _codex_unset
        return 1
    fi
    # Case 1: Exact single match found -> show detailed info
    if [ "$match_count" -eq 1 ]; then
        local pkg_name
        pkg_name=$(echo "$search_results" | grep -E '^[a-zA-Z0-9_-]+/' | awk '{print $1}' | cut -d'/' -f2)
        color_echo 32 "Exact match found: $pkg_name. Fetching detailed info..."
        echo ""
        pacman -Si "$pkg_name"
        _codex_unset
        return 0
    fi
    # Case 2: Too many matches -> Prompt for filtering
    if [ "$match_count" -gt 30 ]; then
        color_echo 33 "WARNING: Found $match_count matching packages."
        read -p "Do you want to filter these results? [Y/n]: " -n 1 -r
        echo "" # Move to a new line
        # Default to Yes if they hit Enter or press Y
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            read -p "Enter additional filter keyword: " filter_keyword
            if [ -n "$filter_keyword" ]; then
                # Re-run search with the original keywords and the new filter
                color_echo 36 "Filtering results for '$filter_keyword'..."
                pacman -Ss "$@" | grep -i -B 1 "$filter_keyword"
            else
                color_echo 31 "No filter entered. Displaying all results anyway..."
                echo "$search_results"
            fi
            _codex_unset
            return 0
        fi
    fi
    # Case 3: Under the threshold or user chose not to filter -> Print everything
    color_echo 32 "--- search results ---"
    echo "$search_results"
    _codex_unset
}
function installPackage {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then 
        echo "USAGE: installPackage <package1> [package2 ...]"
        _codex_unset
        return 0
    fi
    # Prompt for system upgrade
    warn_echo "NOTE: A full system upgrade (pacman -Syu) is recommended before installing new packages."
    read -p "Do you want to upgrade your system now? [y/N]: " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        color_echo 32 "... repository sync and update"
        if ! sudo pacman -Syu; then 
            crit_echo "ERROR: failed to sync or update official repositories"
            _codex_unset
            return 1
        fi
    else
        color_echo 36 "... skipping system upgrade (proceeding with installation only)"
        # Just refresh database to ensure package lists are current for installation
        sudo pacman -Sy
    fi
    # Attempt installation
    if sudo pacman -S --needed "$@"; then 
        _codex_unset
        return 0
    else 
        searchPackages "$@"
        warn_echo "WARNING: packages not found, check for spelling errors"
        _codex_unset
        return 1
    fi
}
alias packageInfo='pacman -Si'
function listOrphanPackages {
    source "$_SCRIPT_DIR/_codex.sh"
    pacman -Qdt | warn_echo
    _codex_unset
}
alias removePackage='sudo pacman -R'
alias purgePackage='sudo pacman -Rn'
function cleanPackageCache {
    source "$_SCRIPT_DIR/_codex.sh"
    local cache_dir="/var/cache/pacman/pkg"
    local current_size
    local choice
    # 1. Check if cache directory exists
    if [ ! -d "$cache_dir" ]; then
        crit_echo "ERROR: Cache directory $cache_dir not found."
        _codex_unset
        return 1
    fi
    # 2. Calculate current cache size
    current_size=$(du -sh "$cache_dir" | cut -f1)
    color_echo 36 "Current total pacman cache size: $current_size"
    # 3. Explain behavior based on available tools
    if command -v paccache &> /dev/null; then
        warn_echo "Mode: paccache (Safe - keeps last 3 versions of all packages)"
        warn_echo "      This will free space while allowing downgrades."
    else
        warn_echo "Mode: pacman -Sc (Standard - keeps ONLY currently installed packages)"
        warn_echo "      Note: Install 'pacman-contrib' for safer, smarter cleaning."
    fi
    echo ""
    # 4. Prompt for confirmation
    read -p "Do you want to proceed with cleaning the cache? [y/N]: " -n 1 -r choice
    echo ""
    if [[ $choice =~ ^[Yy]$ ]]; then
        color_echo 36 "Cleaning cache..."
        # Execute cleanup
        if command -v paccache &> /dev/null; then
            sudo paccache -r
        else
            sudo pacman -Sc
        fi       
        # 5. Show result
        if [ -d "$cache_dir" ]; then
            local new_size
            new_size=$(du -sh "$cache_dir" | cut -f1)
            color_echo 32 "Cleanup complete. New cache size: $new_size"
        else
            color_echo 32 "Cleanup complete. Cache directory is empty."
        fi
        _codex_unset
        return 0
    else
        crit_echo "Operation cancelled."
        _codex_unset
        return 0
    fi
}
function packageRelations {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check argument count
    if [ "$#" -ne 1 ]; then 
        echo "USAGE: showPackageRelations <package_name>"
        _codex_unset
        return 0
    fi
    local pkg_name="$1"
    # Dependency check for pactree
    if ! command -v pactree &> /dev/null; then
        crit_echo "ERROR: 'pactree' not found. Please install 'pacman-contrib'."
        _codex_unset
        return 1
    fi
    # Check if the package is installed locally
    if ! pacman -Qi "$pkg_name" &> /dev/null; then
        crit_echo "ERROR: Package '$pkg_name' is not installed locally."
        _codex_unset
        return 1
    fi
    warn_echo "=== Relations for Package: $pkg_name ==="
    # 1. Fetch Direct Dependencies
    info_echo "--- Direct Dependencies (What '$pkg_name' depends on) ---"
    # Use local and check if pactree actually returned anything *besides* the target package
    local deps
    deps=$(pactree -d 1 -u "$pkg_name" 2>/dev/null | tail -n +2) 
    if [ -z "$deps" ]; then
        echo "None"
    else
        echo "$deps" | sed 's/^/  -> /'
    fi
    # 2. Fetch Direct Reverse Dependencies
    crit_echo "--- Required By (What depends on '$pkg_name') ---"
    local req_by
    req_by=$(pactree -r -d 1 -u "$pkg_name" 2>/dev/null | tail -n +2)
    if [ -z "$req_by" ] || [ "$req_by" = "$pkg_name" ]; then
        echo "None"
    else
        echo "$req_by" | sed 's/^/  <- /'
    fi
    _codex_unset
    return 0
}   
function listInstalledPackages {
    source "$_SCRIPT_DIR/_codex.sh"
    local keywords=("$@")
    # Base command: Generate "Name : Description" for all installed packages
    # We use a function or a subshell to start the pipeline
    local result
    result=$(pacman -Qi | awk '
        /^Name/ { name=$3 } 
        /^Description/ { print name " : " substr($0, index($0,$3)) }
    ')
    # If no keywords, just print the result
    if [ ${#keywords[@]} -eq 0 ]; then
        warn_echo "$result"
        _codex_unset
        return 0
    fi
    # Apply each keyword as a separate grep filter (AND logic)
    # We echo the stored result and pipe it through grep for each keyword
    local cmd="echo \"\$result\""
    for kw in "${keywords[@]}"; do
        # Append grep to the command string safely without eval
        # We use a while loop to pipe the output of the previous grep into the next
        result=$(echo "$result" | grep -iE "$kw")
        # Optimization: If result is empty, no need to check further
        if [ -z "$result" ]; then
            _codex_unset
            return 0
        fi
    done
    warn_echo "$result"
    _codex_unset
}

# END