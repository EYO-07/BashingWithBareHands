# Bashing With Bare Hands 

(this project is a working progress)

This repository is just a collection of aliases and helper functions to be used on linux desktop terminal. In contrast to the legacy pattern of linux and unix system, these aliases and functions should be easy to remember and be used with autocompletion, so the commands are verbose.

The main goal for this project is to make minimal setup linux environments easy to manage using only terminal interface. Many of the tools still require third-party cli tools, so read it and install the necessary packages for your system.

### Rules for a Toolscript
1. No more than 10 items (functions and aliases).
2. Should point out dependencies as comment block.
3. Verbose Human Readable Commands.
4. Should print an inventory of commands and short description on sourcing.
5. Functions should be designed to be safe and user friendly.

With these rules you should manage the linux system with minimal memorization of commands.

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

1. `mounting_tools.sh` : aliases and functions to mount, unmount, devices and partitions by label using udiskctl.
2. `filesystem_tools.sh` : aliases and functions for filesystem operations.
3. `sensor_tools.sh` : aliases and functions to find device sensor files (temperature, usage, etc).
4. `services_tools.sh` : daemons and services with systemctl.
5. `display_tools.sh` : setup of monitor video display on xorg.

Some scripts needs specific tools, check the dependencies on script annotation.

```bash 
# other importing/sourcing alias
alias tools_filesystem='. $TOOLBOX/filesystem_tools.sh'
alias tools_mounting='. $TOOLBOX/mounting_tools.sh'
alias tools_sensors='. $TOOLBOX/sensor_tools.sh'
alias tools_git='. $TOOLBOX/git_tools.sh'
alias tools_screenshot='. $TOOLBOX/screenshot_tools.sh'
alias tools_date='. $TOOLBOX/date_tools.sh'
alias tools_video_music_download='. $TOOLBOX/video_music_download_tools.sh'
alias tools_net='. $TOOLBOX/net_tools.sh'
alias tools_processes='. $TOOLBOX/processes_tools.sh'
alias tools_services='. $TOOLBOX/services_tools.sh'
alias tools_displays='. $TOOLBOX/display_tools.sh'
alias tools_pacman='. $TOOLBOX/pacman_tools.sh'
alias tools_chmod='. $TOOLBOX/change_mode_tools.sh'
alias tools_audio='. $TOOLBOX/audio_tools.sh'
alias tools_sockets='. $TOOLBOX/socket_tools.sh'
alias tools_errors='. $TOOLBOX/errors_tools.sh'
```

Add these to your preferred aliases script and use `tools_NAME.sh` to source in your terminal session.
