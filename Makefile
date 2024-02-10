APPS = $(shell cat apps.txt)
APPS_YAY = $(shell cat apps_yay.txt)
FONTS = $(shell cat fonts.txt)
DRIVERS = $(shell cat drivers.txt)
MMEDIA = $(shell cat media.txt)

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

run: install-apps add-user-groups enable-daemons install-translator
	@echo "Done!"

.PHONY: run
.DEFAULT_GOAL := run