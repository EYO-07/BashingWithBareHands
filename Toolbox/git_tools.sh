# BEGIN : ~/Toolbox/git_tools.sh
# {TextMarker|magenta:pwd}
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. git ; cli tool 
# 2. gh ; github cli tool 

# -- description

function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Git Tools"
    toolbox_item "tools" "show this ..." $width
    toolbox_item "inv" "show helpful built-in commands" $width
    toolbox_item "downloadProject" "... run without args to see usage" $width
    toolbox_item "projectInfo" "run it inside git directory to show information about the directory and update status" $width
    toolbox_item "gitCommit <title> [description]" "local clone commit registry" $width
    toolbox_item "projectUpdate" "discard local changes and sync with remote repository" $width
    toolbox_item "gitPullRequest" "pull request, require gh cli tool" $width
    toolbox_item "listBranches" "list available branches from the git directory" $width
    toolbox_item "setBranch <keyword>" "set branch for current git directory" $width
    toolbox_item "gitDirectPush" "direct push using gh credentials" $width
    toolbox_item "gitStash" "manage git stashes" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=3
    inventory_title "todo"
    inventory_item 1 "..." "..." $width
    inventory_endl
    _codex_unset
}

# -- implementation 
function downloadProject {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then 
        echo "Usage: downloadProject <PROJECT_OWNER> <PROJECT_NAME>"
        echo "Usage: downloadProject <URL>"
        warn_echo "... it will download the project directory on current directory $(pwd)"
        _codex_unset
        return 1
    fi
    if [ "$#" -eq 1 ]; then 
        git clone "$1"
        _codex_unset
        return 0
    fi 
    if [ "$#" -eq 2 ]; then 
        git clone "https://github.com/$1/$2.git"
        _codex_unset
        return 0
    fi
    echo "Usage: downloadProject <PROJECT_OWNER> <PROJECT_NAME>"
    echo "Usage: downloadProject <URL>"
    _codex_unset
}
function projectInfo {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check if inside a git repository
    if [ ! -d .git ]; then
        ls -a
        info_echo "Current Directory: $(pwd)"
        crit_echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    # Get current branch name
    local branch=$(git rev-parse --abbrev-ref HEAD)
    # Check if branch is detached or has no upstream
    if [ "$branch" = "HEAD" ] || ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        echo "Repository: $(git config --get remote.origin.url)"
        echo "Current Branch: $branch (No upstream tracking branch set)"
        _codex_unset
        return 0
    fi
    echo "Repository: $(git config --get remote.origin.url)"
    echo "Current Branch: $branch"
    # Fetch latest info from remote (does not change local files)
    if ! git fetch --quiet; then 
        crit_echo "fail to connect to repository"
        _codex_unset
        return 1
    fi
    # Get commit hashes
    local local_hash=$(git rev-parse @)
    local remote_hash=$(git rev-parse @{u})
    local base_hash=$(git merge-base @ @{u})
    # Compare hashes to determine status
    if [ "$local_hash" = "$remote_hash" ]; then
        color_echo 32 "Status: Up-to-date with remote"
    elif [ "$local_hash" = "$base_hash" ]; then
        local commits_behind=$(git rev-list --count @..@{u})
        warn_echo "Status: Behind remote by $commits_behind commit(s) (Run 'git pull')"
    elif [ "$remote_hash" = "$base_hash" ]; then
        local commits_ahead=$(git rev-list --count @{u}..@)
        crit_echo "Status: Ahead of remote by $commits_ahead commit(s) (Run 'git push')"
    else
        crit_echo "Status: Diverged (Local and remote have different commits)"
        echo "       Run 'git pull --rebase' or 'git pull' to resolve."
    fi
    # Show short status of working directory (uncommitted changes)
    local short_status=$(git status --short)
    if [ -n "$short_status" ]; then
        warn_echo "Working Directory: Has uncommitted changes"
        # Optionally uncomment the next line to see the changes
        echo "$short_status"
    else
        color_echo 32 "Working Directory: Clean"
    fi
    _codex_unset
}   
function gitCommit {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check for arguments
    if [ "$#" -lt 1 ]; then 
        echo "Usage: gitCommit <title> [description]"
        _codex_unset
        return 1
    fi
    local title="$1"
    shift
    local description="$*"
    # Display what will be committed
    echo ""
    echo "=== Commit Preview ==="
    echo "Title: $title"
    if [ -n "$description" ]; then
        echo "Description: $description"
    fi
    echo "======================"
    echo ""
    # Confirmation Prompt (Defaults to NO)
    read -r -p "Do you want to proceed with this commit? [y/N] " response
    # Check response (case-insensitive)
    case "$response" in
        [yY][eE][sS]|[yY])
            if [ -n "$description" ]; then
                git commit -m "$title" -m "$description"
            else
                git commit -m "$title"
            fi
            ;;
        *)
            echo "Commit aborted."
            _codex_unset
            return 1
            ;;
    esac
    _codex_unset
}   
function projectUpdate {
    source "$_SCRIPT_DIR/_codex.sh"
    # Ensure we are inside a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        ls -a
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    # Check if an upstream branch is set
    local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [ -z "$upstream" ]; then
        echo "Error: No upstream branch configured."
        echo "Run 'git push -u origin <branch>' to set one."
        _codex_unset
        return 1
    fi
    info_echo "=== Download Sync (Overwrite Mode) ==="
    echo "Target: $upstream"
    echo ""
    echo "WARNING: This operation will:"
    echo "  1. Discard ALL local commits not on remote."
    echo "  2. Overwrite ALL modified tracked files."
    echo "  3. Delete ALL untracked files and directories."
    echo "Your local clone will become an EXACT copy of the remote."
    # Safety Confirmation Dialog
    if ! token_prompt "Confirmation Update" "are you sure you want to proceed?"; then 
        _codex_unset
        return 0
    fi 
    # --
    echo "Fetching latest changes..."
    git fetch --quiet origin
    echo "Resetting local branch to match remote..."
    git reset --hard @{u}
    echo "Cleaning untracked files..."
    git clean -fd
    color_echo 32 "Sync complete. Local clone matches remote exactly."
    _codex_unset
}   
function gitPullRequest {
    source "$_SCRIPT_DIR/_codex.sh"
    # 1. Check for GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not installed."
        echo "Install it: brew install gh (macOS) or sudo apt install gh (Linux)"
        echo "Then run: gh auth login"
        _codex_unset
        return 1
    fi
    # 2. Ensure we are inside a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        ls -a
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    # 3. Get current branch
    local current_branch=$(git branch --show-current)
    if [ -z "$current_branch" ]; then
        echo "Error: Cannot determine current branch (detached HEAD?)."
        _codex_unset
        return 1
    fi
    # 4. Prompt for Base Branch (default: main)
    read -r -p "Target base branch (default: main): " base_branch
    base_branch=${base_branch:-main}
    # 5. Preview Action
    echo ""
    echo "=== Pull Request Preview ==="
    echo "Source: $current_branch"
    echo "Target: $base_branch"
    echo "Action: Push branch to remote AND create PR"
    echo "============================"
    echo ""
    # 6. Confirmation
    read -r -p "Proceed? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            echo "Aborted."
            _codex_unset
            return 1
            ;;
    esac
    # 7. Push Branch (PRs require the branch to exist on remote)
    echo "Pushing branch '$current_branch' to origin..."
    git push -u origin "$current_branch"
    if [ $? -ne 0 ]; then
        echo "Error: Push failed. Cannot create PR."
        _codex_unset
        return 1
    fi
    # 8. Create PR using GitHub CLI
    # --fill automatically uses commit messages for title/body if not provided
    echo "Creating Pull Request..."
    gh pr create --base "$base_branch" --head "$current_branch" --fill
    if [ $? -eq 0 ]; then
        echo "✓ Pull Request created successfully!"
    else
        echo "Error: Failed to create PR. You may already have one open for this branch."
        _codex_unset
        return 1
    fi
    _codex_unset
}   
function listBranches {
    source "$_SCRIPT_DIR/_codex.sh"
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        ls -a
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    echo "=== Remote Branches ==="
    if [ "$#" -eq 0 ]; then
        # List all remote branches, stripping 'origin/' prefix for cleanliness
        git branch -r | grep -v '\HEAD' | sed 's/origin\///'
    else
        # Filter by argument (case-insensitive grep)
        local pattern="$1"
        echo "Filter: '$pattern'"
        git branch -r | grep -v '\HEAD' | grep -i "$pattern" | sed 's/origin\///'  
        if [ ${PIPESTATUS[1]} -ne 0 ]; then
            echo "No branches found matching '$pattern'."
            _codex_unset
            return 1
        fi
    fi
    _codex_unset
}
function setBranch {
    source "$_SCRIPT_DIR/_codex.sh"
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    # Check for dirty working directory
    if [ -n "$(git status --porcelain)" ]; then
        echo "Warning: You have uncommitted changes."
        read -r -p "continue? [y/N] " response
        if [[ "$response" =~ ^[yY]$ ]]; then
            echo "..."
        else
            echo "Abort: Please commit or stash changes manually."
            _codex_unset
            return 1
        fi
    fi
    if [ "$#" -eq 0 ]; then
        echo "=== Available Branches ==="
        git branch -a
        _codex_unset
        return 0
    fi
    local target="$1"
    local remote_exists=$(git branch -r --list "origin/$target")
    echo "=== Switching to '$target' ==="
    if [ -n "$remote_exists" ]; then
        # Branch exists on remote: checkout and track
        git checkout -B "$target" "origin/$target"
    else
        # Branch does not exist: create new from main/master
        echo "Remote branch not found. Creating new branch '$target' from 'main'..."
        git checkout -b "$target" main 2>/dev/null || git checkout -b "$target" master
    fi
    _codex_unset
}   
function gitDirectPush {
    source "$_SCRIPT_DIR/_codex.sh"
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    local current_branch=$(git branch --show-current)
    # Safety: Prevent direct push to main/master without explicit confirmation
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        echo "WARNING: You are attempting to push directly to '$current_branch'."
        read -r -p "Type 'force' to confirm direct push to protected branch: " confirm
        if [ "$confirm" != "force" ]; then
            echo "Aborted. Use a feature branch and gitPullRequest instead."
            _codex_unset
            return 1
        fi
    fi
    echo "=== Direct Push ==="
    echo "Branch: $current_branch"
    read -r -p "Proceed with git push? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            git push -u origin "$current_branch"
            if [ $? -eq 0 ]; then
                echo "Pushed successfully."
            else
                echo "Error: Push failed."
                _codex_unset
                return 1
            fi
            ;;
        *)
            echo "Aborted."
            _codex_unset
            return 1
            ;;
    esac
    _codex_unset
}   
function gitStash {
    source "$_SCRIPT_DIR/_codex.sh"
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        ls -a
        echo "Error: Not a git repository."
        _codex_unset
        return 1
    fi
    # Mode 1: No arguments -> Interactively ask to Save or Pop/List
    if [ "$#" -eq 0 ]; then
        echo "=== Git Stash Manager ==="
        echo "1) Save changes to stash"
        echo "2) Pop latest stash (Apply & Delete)"
        echo "3) List current stashes"
        echo "4) Cancel"
        echo ""
        read -r -p "Select an option [1-4]: " stash_opt
        case "$stash_opt" in
            1)
                read -r -p "Enter optional stash message: " stash_msg
                if [ -n "$stash_msg" ]; then
                    git stash push -m "$stash_msg"
                else
                    git stash push
                fi
                _codex_unset
                return 0
                ;;
            2)
                echo "Applying and removing the most recent stash..."
                git stash pop
                _codex_unset
                return $?
                ;;
            3)
                echo "=== Current Stash List ==="
                git stash list
                _codex_unset
                return 0
                ;;
            *)
                echo "Operation cancelled."
                _codex_unset
                return 0
                ;;
        esac
    fi
    # Mode 2: Commands passed as arguments (e.g., 'gitStash pop' or 'gitStash list')
    local sub_command="$1"
    case "$sub_command" in
        "list")
            git stash list
            ;;
        "pop")
            git stash pop
            ;;
        "push"|"save")
            shift
            local message="$*"
            if [ -n "$message" ]; then
                git stash push -m "$message"
            else
                git stash push
            fi
            ;;
        *)
            echo "Usage options:"
            echo "  gitStash               : Open the interactive menu"
            echo "  gitStash list          : Show all stashed changes"
            echo "  gitStash pop           : Apply and delete top stash entry"
            echo "  gitStash save [msg]    : Stash local changes with an optional message"
            _codex_unset
            return 1
            ;;
    esac
    _codex_unset
}

function gitIgnore { # creates or update gitignore
    source "$_SCRIPT_DIR/_codex.sh"
    # dont use templates 
    # USAGE: gitIgnore <file_or_expr1> [ <file_or_expr2> ... ]
    _codex_unset
    return 1
}


# END