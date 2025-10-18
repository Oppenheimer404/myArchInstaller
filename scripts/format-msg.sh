#! /usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

msg_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1" >&2
    sleep 0.5
    # sleep 1 && clear
}
msg_warn() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1" >&2
    sleep 0.7
}
msg_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
    sleep 1
}
msg_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1" >&2
}
msg_debug() {
    printf "${CYAN}[DEBUG]${NC} %s\n" "$1" >&2
}
msg_select() {
    printf "${CYAN}[SELECT]${NC} %s\n" "$1" >&2
}
msg_prompt() {
    local prompt="$1"
    shift
    local options=("$@")
    local i selection
    msg_select "$prompt:"
    for i in "${!options[@]}"; do
        printf "  %d) %s\n" "$((i + 1))" "${options[$i]}" >&2
    done
    while true; do
        msg_select "Enter selection: (1-${#options[@]})"
        read -r selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
            printf "${options[$((selection - 1))]}\n"
            exit 0
        else
            msg_error "Invalid selection ($selection) Please enter a number between 1 and ${#options[@]}"
        fi
    done
}
msg_check() {
    local prompt="$1"
    shift
    local user_selections=("$@")
    local response
    msg_info "${prompt}"
    while true; do
        msg_select "Confirm: (y)Yes (n)No"
        read -r response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        case "$response" in
            y|yes)
                msg_success "Confirmed selection(s): $*"
                return 0
                ;;
            n|no)
                msg_warn "Cancelling..."
                return 1
                ;;
            *)
                msg_error "Invalid response ($response) Please enter y/n or yes/no"
        esac
    done
}