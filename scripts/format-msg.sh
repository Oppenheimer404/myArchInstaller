#! /usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

msg_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
    sleep 0.1
}
msg_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
    sleep 0.5
}
msg_warn() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
    sleep 1
}
msg_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
    sleep 1
}
msg_debug() {
    printf "${CYAN}[DEBUG]${NC} %s\n" "$1"
}