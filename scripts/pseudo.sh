#! /usr/bin/env bash

# Personal Arch Linux Installation Script - Pseudocode
# Stage 1: Pre-Installation (from live boot enviroment)
# Stage 2: Post-Installation (after first boot)

function pre_installation() {
	printf "Setting Keyboard Layout...\n"
	# localectl list-keymaps
	# loadkeys {selected-keymap}
	
	printf "Setting Console Font...\n"
	# ls /usr/share/kbd/consolefonts/
	# setfont {selected-font}
	
	printf "Verifing boot mode (64=64, 32=32, BIOS=No such file or directory)...\n"
	# cat /sys/firmware/efi/fw_platform_size 

	printf "Connectng to the internet...\n"
	connecting_to_the_internet() {
		
		printf "Ensuring network interface is listed and enabled...\n"
		# ip link
		
		printf "Selecting connection method...\n"
		# do things here

		connect_via_ethernet() {
			printf "Connecting to ethernet network...\n"
		}
		connect_via_ethernet
		
		connect_via_wifi() {
			printf "Ensuring wireless interface is not blocked...\n"
			# rfkill
			printf "Unblocking wireless interface if desired (soft-block only)...\n"
			# rfkill unblock {selected-interface}
			printf "Connecting to wireless network...\n"
			# iwctl
		}
		connect_via_wifi

		connect_via_broadband() {
			printf "Connecting to broadband network...\n"
			# mmcli
		}
		connect_via_broadband
	}
	connecting_to_the_internet
	
	printf "Verifying connection...\n"
	# ping 1.1.1.1
	
	printf "Updating system clock,,,\n"
	# timeanddatectl
	
	printf "Partitioning disks...\n"
	partitioning_disks() {

		printf "Starting UEFI partitioning...\n"
		uefi_gpt_partitioning() {
			printf "Creating boot partition...\n"
			# /dev/efi_system_partition (1GiB)
			printf "Creating swap partition...\n"
			# /dev/swap_partition (4GiB min)
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
		}
		uefi_gpt_partitioning

		printf "Starting BIOS partitioning...\n"
		bios_mbr_partitioning() {
			printf "Creating swap partition...\n"
			# /dev/swap_partition (4GiB min)
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
		}
		bios_mbr_partitioning
	}
	partitioning_disks
}

function main() {
	pre_installation
}

main
