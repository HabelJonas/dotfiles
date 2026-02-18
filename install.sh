#!/bin/bash

# ==========================================
# ARCH LINUX SETUP SCRIPT (TOOLS ONLY)
# ==========================================

# --- 1. System Update & Basis-Pakete ---
echo "Update System und installiere Basis-Pakete..."

# Core & GUI Basics (inkl. Kitty)
sudo pacman -Syu --noconfirm --needed hyprland kitty git base-devel linux-headers ly firefox ttf-liberation wl-clipboard pavucontrol sof-firmware btop openssh less

# Neovim & Dev Tools (inkl. Font für Icons)
sudo pacman -Syu --noconfirm --needed neovim lua luarocks dotnet-sdk dotnet-runtime aspnet-runtime unzip ripgrep fd ttf-jetbrains-mono-nerd

# Ricing Tools (Nur Installation)
sudo pacman -Syu --noconfirm --needed starship zsh fastfetch

# Shell auf Zsh ändern
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo "Ändere Standard-Shell zu Zsh..."
    chsh -s /usr/bin/zsh
fi

# --- 2. Yay Installation ---
if ! command -v yay &> /dev/null; then
    echo "Installiere yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay ist bereits installiert."
fi

# --- 3. Audio Installation (FINALER FIX) ---
echo ""
echo "--- AUDIO SETUP ---"

# SCHRITT A: Konflikte entfernen
CONFLICT_PKGS=("jack2" "jack" "pulseaudio" "pulseaudio-alsa" "pipewire-media-session" "cadence")

echo "Prüfe auf Konflikt-Pakete..."
for pkg in "${CONFLICT_PKGS[@]}"; do
    if pacman -Qs "^$pkg$" > /dev/null; then
        echo "Entferne $pkg..."
        sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null || echo "Konnte $pkg nicht entfernen."
    fi
done

# SCHRITT B: Neuinstallation
echo "Installiere PipeWire und WirePlumber..."
sudo pacman -S --noconfirm pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils

# SCHRITT C: Dienste aktivieren
echo "Aktiviere Audio-Dienste für den Benutzer..."
systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null
systemctl --user daemon-reload
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

echo "Audio-Status:"
sleep 2
systemctl --user status wireplumber --no-pager | grep "Active"

# --- 3.1 Focusrite Spezifisch ---
read -p "Benutzt du ein Focusrite Audio Interface? [y/N] " response_focusrite
response_focusrite=${response_focusrite,,}

if [[ "$response_focusrite" =~ ^(yes|y)$ ]]; then
    echo "Installiere Focusrite Tools..."
    yay -S --noconfirm alsa-scarlett-gui
    yay -S --noconfirm realtime-privileges
    
    sudo usermod -aG realtime $USER
    echo "Benutzer '$USER' wurde zur 'realtime' Gruppe hinzugefügt."

    # Hinweis: Diese Config ist Hardware-spezifisch und wird daher hier erstellt
    echo "Setze Focusrite als Standard-Audio..."
    mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"
    cat <<EOF > "$HOME/.config/wireplumber/wireplumber.conf.d/51-focusrite-default.conf"
monitor.alsa.rules = [
  {
    matches = [ { "node.name", "matches", "alsa_output.usb-Focusrite*" } ],
    actions = { update-props = { "priority.driver" = 1050, "priority.session" = 1050 } }
  },
  {
    matches = [ { "node.name", "matches", "alsa_input.usb-Focusrite*" } ],
    actions = { update-props = { "priority.driver" = 1050, "priority.session" = 1050 } }
  }
]
EOF
else
    echo "Überspringe Focusrite-Tools."
fi

# --- 4. Nvidia Abfrage ---
echo ""
read -p "Hast du eine NVIDIA GPU? [y/N] " response_nvidia
response_nvidia=${response_nvidia,,}

IS_NVIDIA=false
if [[ "$response_nvidia" =~ ^(yes|y)$ ]]; then
    IS_NVIDIA=true
    echo "Installiere Nvidia Pakete..."
    yay -S --needed --noconfirm nvidia-dkms nvidia-utils egl-wayland nvidia-settings

    echo "-----------------------------------"
    echo "WICHTIG: Manuelle Nvidia Schritte!"
    echo "1. Kernel Parameter: 'nvidia_drm.modeset=1'"
    echo "2. Initramfs (mkinitcpio): MODULES=(... nvidia ...)"
    echo "-----------------------------------"
else
    echo "Überspringe Nvidia Installation."
fi

# --- 5. Steam & Gaming Installation ---
echo ""
read -p "Möchtest du STEAM und Gaming-Tools installieren? [y/N] " response_steam
response_steam=${response_steam,,}

if [[ "$response_steam" =~ ^(yes|y)$ ]]; then
    echo "Bereite Gaming-Umgebung vor..."
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi

    sudo pacman -S --noconfirm --needed steam vulkan-icd-loader lib32-vulkan-icd-loader gamemode lib32-gamemode discord gamescope
    yay -S --noconfirm protonup-qt

    if [ "$IS_NVIDIA" = true ]; then
        sudo pacman -S --noconfirm --needed lib32-nvidia-utils
    fi
fi

# --- 6. Ly Service aktivieren ---
echo ""
echo "Konfiguriere Display Manager (Ly)..."
sudo systemctl disable getty@tty2.service 2>/dev/null

if systemctl list-unit-files | grep -q "ly.service"; then
    sudo systemctl enable ly@tty1.service
else
    sudo systemctl enable ly@tty2.service
fi

echo ""
echo "-----------------------------------"
echo "INSTALLATION ABGESCHLOSSEN!"
echo "Alle Tools (Kitty, Zsh, Starship, Fastfetch) sind installiert."
echo "Bitte kopiere deine Dotfiles jetzt manuell oder nach dem Neustart."
echo "Bitte starte das System neu!"
echo "-----------------------------------"
