# BEGIN : Toolbox/firewall_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. ufw firewall 

# Inventory [ Firewall basics ] { Linux Bash }
# 1. apt install ufw ; install uncomplicated firewall
# 2. ufw enable ; enable firewall
# 3. ufw disable ; disable firewall
# 4. ufw status ; show firewall status
# 5. ufw status verbose ; detailed status
# 6. ufw allow PORT ; allow port (example: 22)
# 7. ufw deny PORT ; deny port
# 8. ufw allow SERVICE ; allow service (example: ssh)
# 9. ufw delete allow PORT ; remove rule
# 10. ufw reset ; reset all rules
# 11. ufw default deny incoming ; block incoming by default
# 12. ufw default allow outgoing ; allow outgoing by default
# 13. ufw allow from IP ; allow specific IP
# 14. ufw allow from IP to any port PORT ; allow IP to port
# 15. iptables -L ; list iptables rules
# 16. iptables -F ; flush iptables rules
# 17. nft list ruleset ; list nftables rules
# 18. ss -tuln ; list listening ports
# 19. netstat -tuln ; list open ports (legacy)
# 20. systemctl enable ufw ; enable firewall at boot
# sudo ufw allow in on proton0 from any to any

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Firewall Tools"
    toolbox_item "tools / inv" "print this ... / show command syntax" $width
    if is_command_valid "ufw"; then 
        toolbox_item "firewallReset" "reset ufw firewall settings to default" $width
        toolbox_item "firewallStatusVerbose" "show detailed ufw firewall status" $width
        toolbox_item "firewallAllowPort" "allow a specific port" $width
        toolbox_item "firewallBindInterface" "manage rules bound to a network interface" $width
        toolbox_item "firewallLogs" "view recent blocked connection logs" $width
        toolbox_item "firewallNumberedList" "list rules with index numbers" $width
        toolbox_item "firewallDeleteRule" "delete a firewall rule by its index number" $width
    else 
        crit_echo "... these tools require ufw"
    fi 
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    inventory_title "Firewall Tools { ufw }"
    info_echo "... may require admin. privileges"
    inventory_item 1 "ufw enable" "enable firewall globally (system-wise)" $width
    inventory_item 2 "ufw disable" "disable firewall globally (system-wise)" $width
    inventory_item 3 "ufw status verbose" "show the current status of ufw firewall" $width
    #inventory_item 4 "" "" $width
    inventory_endl
    _codex_unset
}

# -- implementation 
function firewallStatusVerbose {
    source "$_SCRIPT_DIR/_codex.sh"
    auto_escalate ufw status verbose
    _codex_unset
}
function firewallReset {
    source "$_SCRIPT_DIR/_codex.sh"
    token_prompt "Confirmation" "this will reset the firewall to default settings" || { _codex_unset; return 1; }
    sudo ufw reset && sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw enable 
    _codex_unset
}
function firewallAllowPort {
    source "$_SCRIPT_DIR/_codex.sh"   
    local port="$1"
    if [[ -z "$port" ]]; then 
        warn_echo "Usage: firewallAllowPort <port> [ <protocol> ]"
        echo "protocol : tcp (default) / udp / any"
        _codex_unset 
        return 1
    fi 
    if ! validate_positive_integer "$port" "Port"; then 
        crit_echo "invalid port number, it must be a positive integer"
        _codex_unset
        return 1
    fi
    local proto="${2:-tcp}"
    if yn_prompt "Confirm Rule" "Allow incoming traffic on port $port/$proto?"; then
        auto_escalate ufw allow "$port/$proto"
    else
        info_echo "Operation cancelled."
    fi
    _codex_unset
}
function firewallNumberedList {
    source "$_SCRIPT_DIR/_codex.sh"
    local filter="${1:-}"
    if [[ -n "$filter" ]]; then
        toolbox_title "Active UFW Rules (Numbered) [Filter: '$filter']"
        # Keep header lines and lines matching the filter query case-insensitively
        sudo ufw status numbered | grep -E -i "Status:|To|Action|From|\[[0-9]+\]|$filter"
    else
        toolbox_title "Active UFW Rules (Numbered)"
        sudo ufw status numbered
    fi   
    _codex_unset
}
function firewallLogs {
    source "$_SCRIPT_DIR/_codex.sh"
    local lines="${1:-20}"
    toolbox_title "Recent UFW Firewall Logs (Last $lines entries)"
    if command -v journalctl &>/dev/null; then
        auto_escalate journalctl -k -t ufw -n "$lines" --no-pager
    elif [[ -f /var/log/ufw.log ]]; then
        auto_escalate tail -n "$lines" /var/log/ufw.log
    else
        crit_echo "Error: Could not locate UFW logs via journalctl or /var/log/ufw.log."
        _codex_unset
        return 1
    fi
    _codex_unset
}
function firewallBindInterface {
    source "$_SCRIPT_DIR/_codex.sh"
    local interface="$1"
    local action="${2:-allow}"
    local port="${3:-}"
    local proto="${4:-any}"

    if [[ -z "$interface" ]]; then
        warn_echo "Usage: firewallBindInterface <interface> [action] [port] [protocol]"
        echo "  action   : allow (default) / deny"
        echo "  port     : optional port number (leave blank for all ports)"
        echo "  protocol : tcp / udp / any (default: any)"
        _codex_unset
        return 1
    fi
    if [[ -n "$port" ]]; then
        if ! validate_positive_integer "$port" "Port"; then
            crit_echo "invalid port number, it must be a positive integer"
            _codex_unset
            return 1
        fi
        local target="to any port $port"
        if [[ "$proto" != "any" ]]; then
            target="to any port $port proto $proto"
        fi
        if yn_prompt "Confirm Rule" "$action incoming traffic on interface '$interface' $target?"; then
            auto_escalate ufw "$action" in on "$interface" "$target"
        fi
    else
        if yn_prompt "Confirm Rule" "$action all incoming traffic on interface '$interface'?"; then
            auto_escalate ufw "$action" in on "$interface" from any to any
        fi
    fi   
    _codex_unset
}
function firewallDeleteRule {
    source "$_SCRIPT_DIR/_codex.sh"
    local rule_num="$1"   
    if [[ -z "$rule_num" ]]; then
        warn_echo "Usage: firewallDeleteRule <rule_number>"
        info_echo "Hint: Run 'firewallListNumbered' first to see valid rule indices."
        _codex_unset
        return 1
    fi
    if ! validate_positive_integer "$rule_num" "Rule Number"; then
        crit_echo "invalid rule number, it must be a positive integer"
        _codex_unset
        return 1
    fi
    if yn_prompt "Confirm Deletion" "Are you sure you want to delete rule #$rule_num?"; then
        auto_escalate ufw delete "$rule_num"
    else
        info_echo "Operation cancelled."
    fi
    _codex_unset
}

# END 

































