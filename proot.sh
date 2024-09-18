#!/bin/bash

USE_GUM=false

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
    esac
done

bash_banner() {
    clear
    local BANNER="
╔════════════════════════════════════════╗
║                                        ║
║               OHMYTERMUX               ║
║                                        ║
╚════════════════════════════════════════╝"

    echo -e "${COLOR_BLUE}${BANNER}${COLOR_RESET}\n"
}

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

check_and_install_gum() {
    if [ "$USE_GUM" = true ] && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if [ "$USE_GUM" = true ]; then
            gum style --foreground 196 "ERREUR: Installation de OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERREUR: Installation de OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Veuillez vous référer au(x) message(s) d'erreur ci-dessus.${COLOR_RESET}"
    fi
}

trap finish EXIT

install_proot_packages() {
    local pkgs_proot=('sudo' 'wget' 'nala' 'jq')
    for pkg in "${pkgs_proot[@]}"; do
        if [ "$USE_GUM" = true ]; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y
        else
            echo -e "${COLOR_BLUE}Installation de $pkg...${COLOR_RESET}"
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y > /dev/null 2>&1
        fi
    done
}

create_proot_user() {
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Création de l'utilisateur" -- bash -c "
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
        "
    else
        echo -e "${COLOR_BLUE}Création de l'utilisateur...${COLOR_RESET}"
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
    fi
}

configure_proot_user() {
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Ajout des droits utilisateur" -- bash -c '
            chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
            echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
            chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        '
    else
        echo -e "${COLOR_BLUE}Ajout des droits utilisateur...${COLOR_RESET}"
        chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    fi
}

install_mesa_vulkan() {
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
    else
        echo -e "${COLOR_BLUE}Téléchargement de Mesa-Vulkan...${COLOR_RESET}"
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
        echo -e "${COLOR_BLUE}Installation de Mesa-Vulkan...${COLOR_RESET}"
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
    fi
}

if [ $# -eq 0 ]; then
    if [ "$USE_GUM" = true ]; then
        username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
    else
        echo -e "${COLOR_BLUE}Entrez votre nom d'utilisateur :${COLOR_RESET}"
        read -r username
    fi
else
    username="$1"
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Debian proot" -- proot-distro install debian
else
    echo -e "${COLOR_BLUE}Installation de Debian proot...${COLOR_RESET}"
    proot-distro install debian > /dev/null 2>&1
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Recherche de mise à jour" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Mise à jour des paquets" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y
else
    echo -e "${COLOR_BLUE}Recherche de mise à jour...${COLOR_RESET}"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update > /dev/null 2>&1
    echo -e "${COLOR_BLUE}Mise à jour des paquets...${COLOR_RESET}"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y > /dev/null 2>&1
fi

install_proot_packages
create_proot_user
configure_proot_user

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Configuration de la distribution" -- bash -c '
        echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
    '
else
    echo -e "${COLOR_BLUE}Configuration de la distribution...${COLOR_RESET}"
    echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
fi

cat << 'EOF' >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
alias zink='MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform '
alias hud='GALLIUM_HUD=fps '
alias ..='cd ..'
alias l='ls'
alias ll='ls -la'
alias n='nano'
alias s='source'
alias q='exit'
alias c='clear'
alias cat='bat '
alias install='sudo nala install -y'
alias update='sudo nala update'
alias upgrade='sudo nala upgrade -y'
alias remove='sudo nala remove -y'
alias list='nala list --upgradeable'
alias show='nala show'
alias search='nala search'
alias start='echo please run from termux, not Debian proot.'
alias cm='chmod +x'
alias clone='git clone'
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
alias bashconfig='nano $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc'
EOF

timezone=$(getprop persist.sys.timezone)
{
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 rm /etc/localtime
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 cp /usr/share/zoneinfo/$timezone /etc/localtime
} > /dev/null 2>&1

cd "$PREFIX/share/icons"
find dist-dark | cpio -pdm "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons" > /dev/null 2>&1

cat << EOF > "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources"
Xcursor.theme: dist-dark
EOF

mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.fonts/"
mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.themes/"

install_mesa_vulkan 