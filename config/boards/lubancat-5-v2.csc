# Rockchip RK3588 octa core 4-16GB RAM SoC eMMC NVMe 2x USB2 2x USB3 2x 1GbE 2x HDMI HDMIrx DP Mini-PCIe
BOARD_NAME="Lubancat-5 V2"
BOARD_VENDOR="embedfire"
BOARDFAMILY="rockchip-rk3588"
BOARD_MAINTAINER="amttnd"
INTRODUCED="2023"
BOOTCONFIG="lubancat-5-v2-rk3588_defconfig"
BOOT_SOC="rk3588"
KERNEL_TARGET="vendor,current,edge"
KERNEL_TEST_TARGET="vendor,current"
FULL_DESKTOP="yes"
BOOT_LOGO="desktop"
IMAGE_PARTITION_TABLE="gpt"
BOOT_FDT_FILE="rockchip/rk3588-lubancat-5-v2.dtb"
BOOT_SCENARIO="spl-blobs"

function post_family_config_branch_vendor__lubancat5_v2_kernel() {
	display_alert "$BOARD" "Custom kernel branch overrides for $BOARD - $BRANCH" "info"

	declare -g KERNELBRANCH="branch:rk-6.1-rkr7.2"
}

function post_family_config__lubancat5_v2_use_mainline_uboot() {
	display_alert "$BOARD" "Mainline U-Boot overrides for $BOARD - $BRANCH" "info"

	if [[ "${BRANCH}" != "vendor" ]]; then
		# To reuse ATF code in rockchip64_common, let's change the BOOT_SCENARIO and call prepare_boot_configuration() again
		declare -g BOOT_SCENARIO="tpl-blob-atf-mainline"
		declare -g UBOOT_TARGET_MAP="BL31=bl31.elf ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin"
		prepare_boot_configuration
	else
		declare -g UBOOT_TARGET_MAP="BL31=${RKBIN_DIR}/${BL31_BLOB} ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin"
	fi

	declare -g BOOTCONFIG="lubancat-5-v2-rk3588_defconfig"
	declare -g BOOTDELAY=1
	declare -g BOOTSOURCE="https://github.com/u-boot/u-boot.git"
	declare -g BOOTBRANCH="tag:v2026.07"
	declare -g BOOTPATCHDIR="v2026.07"
	declare -g BOOTDIR="u-boot-${BOARD}"

	# Disable stuff from rockchip64_common; we're using binman here which does all the work already
	unset uboot_custom_postprocess write_uboot_platform

	# Just use the binman-provided u-boot-rockchip.bin, which is ready-to-go
	function write_uboot_platform() {
		dd "if=$1/u-boot-rockchip.bin" "of=$2" bs=32k seek=1 conv=notrunc status=none
	}
}

function post_family_tweaks__lubancat5_v2_naming_audios() {
	display_alert "$BOARD" "Renaming $BOARD audios" "info"

	# PulseAudio releases (bookworm, jammy, noble): udev SOUND_DESCRIPTION maps to PA_PROP_DEVICE_DESCRIPTION.
	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi0-sound", ENV{SOUND_DESCRIPTION}="HDMI0 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi1-sound", ENV{SOUND_DESCRIPTION}="HDMI1 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmiin-sound", ENV{SOUND_DESCRIPTION}="HDMI-In Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-analog-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules

	# PipeWire releases (trixie, forky, sid, resolute+): WirePlumber 0.5 ignores udev, set device.description directly.
	mkdir -p $SDCARD/etc/wireplumber/wireplumber.conf.d/
	cat > $SDCARD/etc/wireplumber/wireplumber.conf.d/51-lubancat-5-v2-audio-names.conf <<-'WPCONF'
		monitor.alsa.rules = [
		  {
		    matches = [ { device.name = "alsa_card.platform-analog-sound" } ]
		    actions = { update-props = { device.description = "ES8388 Audio" } }
		  }
		  {
		    matches = [ { device.name = "alsa_card.platform-hdmi0-sound" } ]
		    actions = { update-props = { device.description = "HDMI0 Audio" } }
		  }
		  {
		    matches = [ { device.name = "alsa_card.platform-hdmi1-sound" } ]
		    actions = { update-props = { device.description = "HDMI1 Audio" } }
		  }
		  {
		    matches = [ { device.name = "alsa_card.platform-dp0-sound" } ]
		    actions = { update-props = { device.description = "DP0 Audio" } }
		  }
		  {
		    matches = [ { device.name = "alsa_card.platform-hdmiin-sound" } ]
		    actions = { update-props = { device.description = "HDMI-In Audio" } }
		  }
		]
	WPCONF

	return 0
}
