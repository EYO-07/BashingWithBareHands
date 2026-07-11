# BEGIN : ~/Toolbox/pacman_tools.sh
# ... collection of pacman toplevel terminal functions and aliases for linux

# -- dependencies
# 1. pacman 
# 2. pacman-contrib : showPackageRelations

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
    # If arguments are provided, use them. Otherwise, read from standard input (stdin).
    if [ "$#" -gt 0 ]; then
        echo -e "\e[${color}m$@\e[0m"
    else
        while IFS= read -r line; do
            echo -e "\e[${color}m${line}\e[0m"
        done
    fi
}
function warn_echo {
    # Seamlessly forwards arguments or stdin to color_echo
    color_echo 33 "$@"
}
function crit_echo {
    # Seamlessly forwards arguments or stdin to color_echo
    color_echo 31 "$@"
}
function info_echo { color_echo 36 "$@"; }

echo ""
color_echo 33 "=== Pacman Package Manager Tools ==="
color_echo 36 "... designed for pacman package manager"
echo "listInstalledPackages : ... you can filter by keywords"
echo " 1. listInstalledPackages [ <kw1> <kw2> ... ] : filter search"
echo ' 2. listInstalledPackages "<kw1>|<kw2>|..." : combined search'
echo "checkInstalledPackages : check for upgradable packages"
echo "systemUpdate : repository sync and update"
echo "searchPackages <keyword1> [keyword2 ...] : search packages on official repos"
echo "installPackage <package1> [package2 ...] : install packages from official repos"
echo "packageInfo : show detailed information about a package"
echo "listOrphanPackages : list orphan dependency packages"
echo "removePackage : remove/uninstall package keeping configs"
echo "purgePackage : remove and remove configs"
echo "cleanPackageCache : clean the pacman cache"
echo "packageRelations : show direct parent child dependency relations"
echo ""
color_echo 31 "-- Post Installation Commands --"
echo "regenerate_initramfs : ..."
echo ""

alias checkInstalledPackages='sudo pacman -Sy && (pacman -Qu | warn_echo)'
alias systemUpdate='sudo pacman -Syu'
function searchPackages {
    if [ "$#" -eq 0 ]; then 
        echo "USAGE: searchPackages <keyword1> [keyword2 ...]"
        return 1
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
        return 1
    fi
    # Case 1: Exact single match found -> show detailed info
    if [ "$match_count" -eq 1 ]; then
        local pkg_name
        pkg_name=$(echo "$search_results" | grep -E '^[a-zA-Z0-9_-]+/' | awk '{print $1}' | cut -d'/' -f2)
        color_echo 32 "Exact match found: $pkg_name. Fetching detailed info..."
        echo ""
        pacman -Si "$pkg_name"
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
            return 0
        fi
    fi
    # Case 3: Under the threshold or user chose not to filter -> Print everything
    color_echo 32 "--- search results ---"
    echo "$search_results"
}
function installPackage {
    if [ "$#" -eq 0 ]; then 
        echo "USAGE: installPackage <package1> [package2 ...]"
        return 1
    fi
    # Prompt for system upgrade
    color_echo 33 "NOTE: A full system upgrade (pacman -Syu) is recommended before installing new packages."
    read -p "Do you want to upgrade your system now? [y/N]: " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        color_echo 32 "... repository sync and update"
        if ! sudo pacman -Syu; then 
            color_echo 31 "ERROR: failed to sync or update official repositories"
            return 1
        fi
    else
        color_echo 36 "... skipping system upgrade (proceeding with installation only)"
        # Just refresh database to ensure package lists are current for installation
        sudo pacman -Sy
    fi
    # Attempt installation
    if sudo pacman -S --needed "$@"; then 
        return 0
    else 
        searchPackages "$@"
        color_echo 33 "WARNING: packages not found, check for spelling errors"
        return 1
    fi
}
alias packageInfo='pacman -Si'
alias listOrphanPackages='pacman -Qdt | warn_echo'
alias removePackage='sudo pacman -R'
alias purgePackage='sudo pacman -Rn'
function cleanPackageCache {
    local cache_dir="/var/cache/pacman/pkg"
    local current_size
    local choice
    # 1. Check if cache directory exists
    if [ ! -d "$cache_dir" ]; then
        crit_echo "ERROR: Cache directory $cache_dir not found."
        return 1
    fi
    # 2. Calculate current cache size
    current_size=$(du -sh "$cache_dir" | cut -f1)
    color_echo 36 "Current total pacman cache size: $current_size"
    # 3. Explain behavior based on available tools
    if command -v paccache &> /dev/null; then
        color_echo 33 "Mode: paccache (Safe - keeps last 3 versions of all packages)"
        color_echo 33 "      This will free space while allowing downgrades."
    else
        color_echo 33 "Mode: pacman -Sc (Standard - keeps ONLY currently installed packages)"
        color_echo 33 "      Note: Install 'pacman-contrib' for safer, smarter cleaning."
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
        return 0
    else
        color_echo 31 "Operation cancelled."
        return 0
    fi
}
alias regenerate_initramfs='sudo mkinitcpio -P'
function packageRelations {
    # Check argument count
    if [ "$#" -ne 1 ]; then 
        echo "USAGE: showPackageRelations <package_name>"
        return 1
    fi
    local pkg_name="$1"
    # Dependency check for pactree
    if ! command -v pactree &> /dev/null; then
        crit_echo "ERROR: 'pactree' not found. Please install 'pacman-contrib'."
        return 1
    fi
    # Check if the package is installed locally
    if ! pacman -Qi "$pkg_name" &> /dev/null; then
        crit_echo "ERROR: Package '$pkg_name' is not installed locally."
        return 1
    fi
    color_echo 33 "=== Relations for Package: $pkg_name ==="
    # 1. Fetch Direct Dependencies
    color_echo 36 "--- Direct Dependencies (What '$pkg_name' depends on) ---"
    # Use local and check if pactree actually returned anything *besides* the target package
    local deps
    deps=$(pactree -d 1 -u "$pkg_name" 2>/dev/null | tail -n +2) 
    if [ -z "$deps" ]; then
        echo "None"
    else
        echo "$deps" | sed 's/^/  -> /'
    fi
    # 2. Fetch Direct Reverse Dependencies
    color_echo 31 "--- Required By (What depends on '$pkg_name') ---"
    local req_by
    req_by=$(pactree -r -d 1 -u "$pkg_name" 2>/dev/null | tail -n +2)
    if [ -z "$req_by" ] || [ "$req_by" = "$pkg_name" ]; then
        echo "None"
    else
        echo "$req_by" | sed 's/^/  <- /'
    fi
    return 0
}   
function listInstalledPackages {
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
            return 0
        fi
    done
    warn_echo "$result"
}

# END