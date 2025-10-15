#! /usr/bin/env bash

source "$(dirname "$0")/format-msg.sh"

function pre_installation() {
	
	## ARCH INSTALL GUIDE 1.5  
	# Set the console keyboard layout and font
	setup_keyboard_terminal
	
	## ARCH INSTALL GUIDE 1.6
	# Verify the boot mode

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
			# /dev/swap_partition (4GiB min, Match to RAM Ideal)
		
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
	
		}
		uefi_gpt_partitioning

		printf "Starting BIOS partitioning...\n"
		bios_mbr_partitioning() {

			printf "Creating swap partition...\n"
			# /dev/swap_partition (4GiB min, Match to RAM Ideal)
		
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
		
		}
		bios_mbr_partitioning
	
	}
	partitioning_disks

	printf "Formatting disks...\n"
	formatting_disks() {
		
		printf "Starting UEFI formatting...\n"
		uefi_partition_formatting() {
			
			printf "Formatting boot partition..."
			# mkfs.fat -F 32 /dev/efi_system_partition
			
			printf "Formatting swap partition..."
			# mkswap /dev/swap_partition
			
			printf "Formatting root partition..."
			# FILESYSTEM STUFF

		}
		uefi_partition_formatting
		
		printf "Starting BIOS formatting...\n"
		bios_partition_formatting() {
			
			printf "Formatting swap partition...\n"
			# mkswap /dev/swap_partition
			
			printf "Formatting root partition..\n"
			# FILESYSTEM STUFF

		}
		bios_partition_formatting

	}
	formatting_disks

	printf "Mounting UEFI partitions...\n"
	mount_uefi_partitions() {
	
		printf "Mounting root partition...\n"
		# mount /dev/root_partition /mnt
		
		printf "Mounting boot partition...\n"
		# mount --mkdir /dev/boot_partition /mnt/boot
	
		printf "Enabling swap...\n"
		# swapon /dev/swap_partition
	
	}
	mount_uefi_partitions	

	printf "Mounting BIOS partitions...\n"
	mount_bios_partitions() {
	
		printf "Mounting root partition...\n"
		# mount /dev/root_partition /mnt
		
		printf "Enabling swap...\n"
		# swapon /dev/swap_partition
	
	}
	mount_bios_partitions	

}

function setup_keyboard_terminal() {

	
	# Check available keymaps
	msg_info "Checking avaliable keymaps..."
	available_keymaps=()
	
	for keymap in us uk de fr dvorak colemak; do
    if localectl list-keymaps | grep -q "^${keymap}$"; then
		msg_info "[$keymap] Keymap Installed"
		available_keymaps+=("$keymap")
    else
		msg_warn "$keymap Not Installed"
    fi
	done
	
	msg_success "Found ${#available_keymaps[@]} keymaps"
	printf "Available keymaps: ${available_keymaps[@]}"

	# loadkeys {selected-keymap}
	
	printf "Setting Console Font...\n"
	# ls /usr/share/kbd/consolefonts/
	# setfont {selected-font}
	
}

function main() {

	pre_installation

}

main
