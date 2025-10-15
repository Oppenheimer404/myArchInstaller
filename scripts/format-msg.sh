#! /usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

msg_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1" >&2
    sleep 0.1
}
msg_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1" >&2
    sleep 0.5
}
msg_warn() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1" >&2
    sleep 1
}
msg_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
    sleep 1
}
msg_debug() {
    printf "${CYAN}[DEBUG]${NC} %s\n" "$1" >&2
}
msg_prompt() {
    prompt="$1"
    shift
    options=("$@")

    printf "${CYAN}[SELECT]${NC} %s\n" "$prompt" >&2

    for i in "${!options[@]}"; do
        printf "  %d) %s\n" "$((i + 1))" "${options[$i]}" >&2
    done

    while true; do
        printf "${BLUE}Enter selection (1-${#options[@]}):${NC} " >&2
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
            printf "${options[$((selection - 1))]}\n"
            exit 0
        else
            printf "${RED}[ERROR]${NC} Invalid selection ($selection) Please enter a number between 1 and ${#options[@]}\n" >&2
        fi
    done
}