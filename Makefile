APPS = "pacman-contrib vlc base cmake opensnitch dnsmasq openssh jq openvpn wpa_supplicant wireless-regdb wireless_tools libreoffice-still sudo mc git nano curl wget flatpak flameshot base-devel mpv yay docker docker-compose tailscale avahi curl dnsutils firewalld net-tools netctl networkmanager networkmanager-openvpn network-manager-applet nm-connection-editor nss-mdns wget whois"
APPS_YAY = "spotify obsidian"
FONTS = "cantarell-fonts inter-font noto-fonts ttf-bitstream-vera ttf-caladea ttf-carlito ttf-cascadia-code ttf-croscore ttf-dejavu ttf-droid ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-inconsolata ttf-liberation ttf-opensans ttf-roboto ttf-ubuntu-font-family"
DRIVERS = "dkms amd-ucode libva-utils linux-headers mesa"
MMEDIA = "alsa-card-profiles alsa-lib alsa-plugins alsa-firmware alsa-utils gst-libav gst-plugin-pipewire gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer gstreamer-vaapi libpulse pipewire wireplumber x264 x265 xvidcore"
PWD = $(shell pwd)

regenerate:
	/bin/bash -c "sed -i 's/^APPS = .*/APPS = \"$(shell cat apps.txt)\"/' $(PWD)/Makefile"
	/bin/bash -c "sed -i 's/^APPS_YAY = .*/APPS_YAY = \"$(shell cat apps_yay.txt)\"/' $(PWD)/Makefile"
	/bin/bash -c "sed -i 's/^FONTS = .*/FONTS = \"$(shell cat fonts.txt)\"/' $(PWD)/Makefile"
	/bin/bash -c "sed -i 's/^DRIVERS = .*/DRIVERS = \"$(shell cat drivers.txt)\"/' $(PWD)/Makefile"
	/bin/bash -c "sed -i 's/^MMEDIA = .*/MMEDIA = \"$(shell cat media.txt)\"/' $(PWD)/Makefile"

patch-pacman:
	/bin/bash -c "sudo sed -i 's/#Color/Color/g' /etc/pacman.conf"
	# set parallel downloads to 5
	/bin/bash -c "sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf"

install-apps: patch-pacman
	sudo pacman -Syu --noconfirm
	@echo "Installing apps..."
	sudo pacman -S --noconfirm --needed $(APPS)
	@echo "Installing apps from AUR..."
	yay -S --noconfirm --needed $(APPS_YAY)
	@echo "Installing drivers..."
	sudo pacman -S --noconfirm --needed $(DRIVERS)
	@echo "Installing fonts..."
	sudo pacman -S --noconfirm --needed $(FONTS)
	@echo "Installing media..."
	sudo pacman -S --noconfirm --needed $(MMEDIA)

add-user-groups:
	sudo usermod -aG docker $(USER)

enable-daemons:
	sudo systemctl enable docker.service
	sudo systemctl enable containerd.service
	sudo systemctl enable bluetooth.service
	sudo systemctl disable dhcpcd.service
	sudo systemctl enable NetworkManager.service
	sudo systemctl enable opensnitchd
	sudo systemctl enable sshd

install-translator:
	@echo "Installing translator..."
	wget git.io/trans
	chmod +x ./trans
	chown root:root ./trans
	sudo mv ./trans /usr/bin/trans

install-hyprland:
	@echo "Installing hyprland..."
	git clone https://github.com/abergasov/HyprV4.git
	cd HyprV4 && ./set-hypr

run: install-apps add-user-groups enable-daemons install-translator regenerate
	@echo "Done!"

.PHONY: run
.DEFAULT_GOAL := run