#!/bin/bash

# Fonction pour afficher la bannière sans gum
bash_banner() {
    clear
    COLOR="\e[38;5;33m"

    TOP_BORDER="╔════════════════════════════════════════╗"
    BOTTOM_BORDER="╚════════════════════════════════════════╝"
    EMPTY_LINE="║                                        ║"
    TEXT_LINE="║              OHMYTERMUX                ║"

    echo
    echo -e "${COLOR}${TOP_BORDER}"
    echo -e "${COLOR}${EMPTY_LINE}"
    echo -e "${COLOR}${TEXT_LINE}"
    echo -e "${COLOR}${EMPTY_LINE}"
    echo -e "${COLOR}${BOTTOM_BORDER}\e[0m"
    echo
}

# Fonction pour afficher la bannière avec ou sans gum
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 33 \
            --border-foreground 33 \
            --border double \
            --align center \
            --width 40 \
            --margin "1 1 1 0" \
            "" "OHMYTERMUX" ""
    else
       bash_banner
    fi
}

# Installation de gum
show_banner
if ! command -v gum &> /dev/null; then
    echo -e "\e[38;5;33mInstallation de gum...\e[0m"
    pkg update -y > /dev/null 2>&1
    pkg install -y gum > /dev/null 2>&1
fi

# Fonction de fin pour gérer les erreurs
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERREUR: Installation de XFCE dans Termux impossible."
        else
            echo -e "\e[38;5;196mERREUR: Installation de XFCE dans Termux impossible.\e[0m"
        fi
        echo -e "\e[38;5;33mVeuillez vous référer au(x) message(s) d'erreur ci-dessus.\e[0m"
    fi
}

trap finish EXIT

username="$1"

pkgs_proot=('sudo' 'wget' 'nala' 'jq')

# Installation de Debian
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation de Debian proot" -- pd install debian > /dev/null 2>&1
else
    echo -e "\e[38;5;33mInstallation de Debian proot...\e[0m"
    pd install debian > /dev/null 2>&1
fi

# Mise à jour des paquets
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Mise à jour des paquets" -- pd login debian --shared-tmp -- env DISPLAY=:1.0 apt update > /dev/null 2>&1
else
    echo -e "\e[38;5;33mMise à jour des paquets...\e[0m"
    pd login debian --shared-tmp -- env DISPLAY=:1.0 apt update > /dev/null 2>&1
fi
pd login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y > /dev/null 2>&1

# Installation des paquets
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation des paquets" -- pd login debian --shared-tmp -- env DISPLAY=:1.0 apt install "${pkgs_proot[@]}" -y > /dev/null 2>&1
else
    echo -e "\e[38;5;33mInstallation des paquets...\e[0m"
    pd login debian --shared-tmp -- env DISPLAY=:1.0 apt install "${pkgs_proot[@]}" -y > /dev/null 2>&1
fi

# Création de l'utilisateur
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Création de l'utilisateur" -- {
        pd login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        pd login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        pd login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
    } > /dev/null 2>&1
else
    echo -e "\e[38;5;33mCréation de l'utilisateur...\e[0m"
    {
        pd login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        pd login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        pd login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
    } > /dev/null 2>&1
fi

# Ajout de l'utilisateur à sudoers
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Ajout des droits utilisateur" -- {
        chmod u+rw $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers
        echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers > /dev/null
        chmod u-w $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers
    } > /dev/null 2>&1
else
    echo -e "\e[38;5;33mAjout des droits utilisateur...\e[0m"
    {
        chmod u+rw $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers
        echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers > /dev/null
        chmod u-w $PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers
    } > /dev/null 2>&1
fi

# Configuration de l'affichage proot
show_banner
echo -e "\e[38;5;33mConfiguration de l'affichage proot...\e[0m"
echo "export DISPLAY=:1.0" >> $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc

# Configuration des alias proot
show_banner
echo -e "\e[38;5;33mConfiguration des alias proot...\e[0m"
echo "
alias zink='MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform '
alias hud='GALLIUM_HUD=fps '
alias l='eza -1 --icons'
alias ls='eza --icons'
alias ll='eza -lF -a --icons --total-size --no-permissions --no-time --no-user'
alias la='eza --icons -lgha --group-directories-first'
alias lt='eza --icons --tree'
alias lta='eza --icons --tree -lgha'
alias dir='eza -lF --icons'
alias ..='cd ..'
alias q='exit'
alias c='clear'
alias cat='bat '
alias apt='sudo nala '
alias install='sudo nala install -y '
alias update='sudo nala update'
alias upgrade='sudo nala upgrade -y'
alias remove='sudo nala remove -y '
alias list='nala list --upgradeable'
alias show='nala show '
alias search='nala search '
alias start='echo please run from termux, not Debian proot.'
alias cm='chmod +x'
alias clone='git clone'
alias push=\"git pull && git add . && git commit -m 'mobile push' && git push\"
alias bashconfig='nano $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc'
" >> $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc

# Configuration du fuseau horaire proot
show_banner
echo -e "\e[38;5;33mConfiguration du fuseau horaire...\e[0m"
timezone=$(getprop persist.sys.timezone)
{
    pd login debian --shared-tmp -- env DISPLAY=:1.0 rm /etc/localtime
    pd login debian --shared-tmp -- env DISPLAY=:1.0 cp /usr/share/zoneinfo/$timezone /etc/localtime
} > /dev/null 2>&1

# Application du thème de xfce à proot
show_banner
echo -e "\e[38;5;33mApplication du thème XFCE...\e[0m"
cd $PREFIX/share/icons
find dist-dark | cpio -pdm $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons > /dev/null 2>&1

cat <<'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources
Xcursor.theme: dist-dark
EOF

mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.fonts/ > /dev/null 2>&1
mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.themes/ > /dev/null 2>&1

# Configuration de l'accélération matérielle
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Téléchargement de Mesa-Vulkan" -- pd login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
else
    echo -e "\e[38;5;33mTéléchargement de Mesa-Vulkan...\e[0m"
    pd login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
fi
pd login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1