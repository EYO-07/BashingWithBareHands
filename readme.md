# Bashing With Bare Hands 

This repository is just a collection of aliases and helper functions to be used on linux desktop terminal. In contrast to the legacy pattern of linux and unix system, these aliases and functions should be easy to remember and be used with autocompletion, so the commands are verbose.

## Usage

```bash
# -- BashingWithBareHands
# ... add this to your aliases script (.bash_aliases or .bashrc)
TOOLBOX='PATH_TO/Toolbox' # modify me, actual path of Toolbox folder 
alias tools_filesystem='. $TOOLBOX/filesystem_tools.sh'
function toolsImport {
    if [[ "$#" -ne 1 ]]; then
        ls $TOOLBOX -l
        return 1
    fi
    if [[ ! -f $TOOLBOX/"$1" ]]; then
        echo "Error: Tool '$1' not found in $TOOLBOX"
        ls $TOOLBOX -l
        return 1
    fi
    . $TOOLBOX/"$1"
}
```

Just add the script above to your preferred aliases file. Executing `toolsImport` without args will show all the contents of `Toolbox` folder, executing `toolsImport FILENAME` will source/import the aliases and functions to your current terminal session and print the list of commands and their respective descriptions. You can also add aliases to source/import the tool script directly, as an example the `tools_filesystem` which source/import the `filesystem_tools.sh`.

## Toolbox Contents

1. `mounting_tools.sh` : aliases and functions to mount, unmount, devices and partitions by label.
2. `filesystem_tools.sh` : aliases and functions for filesystem operations.
3. `sensor_tools.sh` : aliases and functions to find device sensor files (temperature, usage, etc).

Some scripts needs specific tools, check the dependencies on script annotation.

### Rules for a Toolscript
1. No more than 10 items (functions and aliases).
2. Should point out dependencies.
3. Verbose Human Readable Commands.
4. Should print an inventory of commands and short description on sourcing `. <script>` or `source <script>`.