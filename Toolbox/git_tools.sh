# BEGIN : ~/Toolbox/git_tools.sh

# -- dependencies
# 1. git ; cli tool 

# -- description
echo ""
echo "=== Git Tools ==="
echo "gitDownload <PROJECT_OWNER> <PROJECT_NAME> : download a repository clone"
echo "gitDownload <URL> : download a repository clone"
echo ""

# -- implementation 
function gitDownload {
    if [ "$#" -eq 0 ]; then 
        echo "Usage: gitDownload <PROJECT_OWNER> <PROJECT_NAME>"
        echo "Usage: gitDownload <URL>"
        return 1
    fi
    if [ "$#" -eq 1 ]; then 
        git clone "$1"
        return 0
    fi 
    if [ "$#" -eq 2 ]; then 
        git clone "https://github.com/$1/$2.git"
        return 0
    fi
    echo "Usage: gitDownload <PROJECT_OWNER> <PROJECT_NAME>"
    echo "Usage: gitDownload <URL>"
}

# END