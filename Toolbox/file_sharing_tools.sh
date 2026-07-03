# BEGIN : setup_ethernet_file_sharing.sh

# { rsync, avahi }
# Daemon Aproach for Ethernet File Sharing
# No external internet connection 

# 1. both arch-linux connected through ethernet cable

# 2. run this on both machines 
#sudo pacman -Syu --needed rsync avahi
#sudo systemctl enable --now avahi-daemon.socket

# 3. disable wifi or other internet source connection, keep only the ethernet connection 
#nmcli device wifi disconnect 

# 4. disable firewall on both sides
#sudo ufw disable 

# 5. create a configuration file rsyncd.conf on server machine 
# ... USER, SOURCE and DESTINATION are placeholders
# [shared]
# path = SOURCE 
# read only = true
# list = true
# uid = USER
# gid = USER   

# 6. (server machine) 
# sudo rsync --daemon --config=rsyncd.conf --no-detach 

# 6. (client machine) 
# -- sync a SOURCE data folder to DESTINATION data folder 
# -- exact copy
# rsync -av username@hostname.local::shared/ DESTINATION
# -- usable copy
# rsync -rv --no-perms --no-owner --no-group --no-times username@hostname.local::shared/ DESTINATION 

# 7. restore 
# nmcli device wifi connect 
# sudo ufw enable 

# END