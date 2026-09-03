# Bashing With Bare Hands 

This repository is just a collection of aliases and helper functions to be used on linux desktop terminal. In contrast to the legacy pattern of linux and unix system, these aliases and functions should be easy to remember and be used with autocompletion, so the commands are verbose.

The majority of commands display the following behaviour:
1. The script when sourced display a small inventory of their functions/aliases.
2. Their functions prompts the user with confirmation token or simple confirmation for critical or irreversible modifications.
3. Their functions display usage help and useful information when used with wrong number or no arguments.
4. Colors for contrast.

The main goal for this project is to make minimal setup linux environments easy to manage using only terminal interface. Many of the tools still require third-party cli tools, so read it and install the necessary packages for your system.

## Usage

Please read the dependencies to see if you can use it, as it relies primarily on other cli programs, this is just a user interface wrapper of existing commands. The dependencies are listed on script itself.

```bash
# -- BashingWithBareHands
# ... add this to your aliases script (.bash_aliases or .bashrc)
TOOLBOX="PATH_TO/Toolbox" # modify me, actual path of Toolbox folder 
alias toolsImport="source $TOOLBOX/tools.sh"
```

Just add the script above to your preferred aliases file `.bash_aliases`, source the `.bash_aliases` again or re-open the terminal and execute `toolsImport` to import the `tools.sh` script. You can create aliases pointing directly to a specific file or use `toolsImport` and `toolsInteractiveMenu` to select the toolbox interactively.
