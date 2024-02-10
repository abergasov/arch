APPS = "pacman-contrib vlc base cmake opensnitch dnsmasq openssh jq openvpn wpa_supplicant wireless-regdb wireless_tools libreoffice-still sudo mc git nano curl wget flatpak flameshot base-devel mpv yay docker docker-compose tailscale avahi curl dnsutils firewalld net-tools netctl networkmanager networkmanager-openvpn network-manager-applet nm-connection-editor nss-mdns wget whois telegram-desktop steam"
APPS_YAY = "spotify obsidian slack"
FONTS = "cantarell-fonts inter-font noto-fonts ttf-bitstream-vera ttf-caladea ttf-carlito ttf-cascadia-code ttf-croscore ttf-dejavu ttf-droid ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-inconsolata ttf-liberation ttf-opensans ttf-roboto ttf-ubuntu-font-family"
DRIVERS = "dkms amd-ucode libva-utils linux-headers mesa"
MMEDIA = "alsa-card-profiles alsa-lib alsa-plugins alsa-firmware alsa-utils gst-libav gst-plugin-pipewire gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer gstreamer-vaapi libpulse pipewire wireplumber x264 x265 xvidcore"
PWD = $(shell pwd)
GIT_TEMPLATE_HOOK = $(HOME)/.git-templates/hooks/prepare-commit-msg

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
	@echo "Installing flatpak apps..."
	flatpak install -y us.zoom.Zoom

add-user-groups:
	sudo usermod -aG docker $(USER)

create-git-template:
	mkdir -p "~/.git-templates/hooks/"
	touch $(GIT_TEMPLATE_HOOK)
	@echo '#!/bin/bash' > $(GIT_TEMPLATE_HOOK)
	@echo 'BRANCH_NAME=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null)' >> $(GIT_TEMPLATE_HOOK)
	@echo '# Ensure BRANCH_NAME is not empty and is not in a detached HEAD state (i.e. rebase).' >> $(GIT_TEMPLATE_HOOK)
	@echo '# SKIP_PREPARE_COMMIT_MSG may be used as an escape hatch to disable this hook,' >> $(GIT_TEMPLATE_HOOK)
	@echo '# while still allowing other githooks to run.' >> $(GIT_TEMPLATE_HOOK)
	@echo 'if [ ! -z "$$BRANCH_NAME" ] && [ "$$BRANCH_NAME" != "HEAD" ]; then' >> $(GIT_TEMPLATE_HOOK)
	@echo '	PREFIX_PATTERN='[A-Z]{2,8}-[0-9]{1,6}'' >> $(GIT_TEMPLATE_HOOK)
	@echo '        [[ $$BRANCH_NAME =~ $$PREFIX_PATTERN ]]' >> $(GIT_TEMPLATE_HOOK)
	@echo '        PREFIX=$${BASH_REMATCH[0]}' >> $(GIT_TEMPLATE_HOOK)
	@echo '        PREFIX_IN_COMMIT=$$(grep -c "\[$$PREFIX\]" $$1)' >> $(GIT_TEMPLATE_HOOK)
	@echo '        # Ensure PREFIX exists in BRANCH_NAME and is not already present in the commit message' >> $(GIT_TEMPLATE_HOOK)
	@echo '        if [[ -n "$$PREFIX" ]] && ! [[ $$PREFIX_IN_COMMIT -ge 1 ]]; then' >> $(GIT_TEMPLATE_HOOK)
	@echo '            sed -i.bak -e "1s~^~$$PREFIX ~" $$1' >> $(GIT_TEMPLATE_HOOK)
	@echo '        fi' >> $(GIT_TEMPLATE_HOOK)
	@echo 'fi' >> $(GIT_TEMPLATE_HOOK)
	@chmod +x $(GIT_TEMPLATE_HOOK)

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

run: install-apps add-user-groups enable-daemons install-translator regenerate create-git-template
	@echo "Done!"

.PHONY: run
.DEFAULT_GOAL := run