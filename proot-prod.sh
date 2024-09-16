#!/bin/bash

set -euo pipefail

USE_GUM=false
VERBOSE=false

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

# Configuration de la redirection
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
else
    redirect=""
fi

# Fonction pour vérifier les dépendances nécessaires
check_dependencies() {
    if [ "$USE_GUM" = true ]; then
        if ! command -v gum &> /dev/null; then
            echo -e "${COLOR_BLUE}Gum n'est pas installé. Installation de gum...${COLOR_RESET}"
            pkg update -y && pkg install gum -y
        fi
    fi

    if ! command -v proot-distro &> /dev/null; then
        echo -e "${COLOR_RED}Erreur : proot-distro n'est pas installé. Veuillez l'installer avant de continuer.${COLOR_RESET}"
        exit 1
    fi
}

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

# Fonction pour gérer les finitions en cas d'erreur
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if [ "$USE_GUM" = true ]; then
            gum style --foreground 196 "ERREUR : Installation de OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERREUR : Installation de OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Veuillez vous référer aux messages d'erreur ci-dessus.${COLOR_RESET}"
    fi
}

trap terminer EXIT

# Fonction pour installer les paquets nécessaires dans proot
install_packages_proot() {
    local pkgs_proot=('sudo' 'wget' 'nala' 'jq')
    for pkg in "${pkgs_proot[@]}"; do
        if [ "$USE_GUM" = true ]; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y
        else
            echo -e "${COLOR_BLUE}Installation de $pkg...${COLOR_RESET}"
            eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install $pkg -y $redirect"
        fi
    done
}

# Fonction pour créer un utilisateur dans proot
create_user_proot() {
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Création de l'utilisateur" -- bash -c "
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
            proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
        "
    else
        echo -e "${COLOR_BLUE}Création de l'utilisateur...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage $redirect"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel $redirect"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash $username $redirect"
    fi
}

# Fonction pour configurer les droits de l'utilisateur
configure_user_rights() {
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Ajout des droits utilisateur" -- bash -c '
            chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
            echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
            chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        '
    else
        echo -e "${COLOR_BLUE}Ajout des droits utilisateur...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chmod u+rw \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers\" $redirect"
        eval "echo \"$username ALL=(ALL) NOPASSWD:ALL\" | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 tee -a \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers\" $redirect"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chmod u-w \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers\" $redirect"
    fi
}

# Fonction pour installer Mesa-Vulkan
install_mesa_vulkan() {
    local mesa_package="mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb"
    local mesa_url="https://github.com/GiGiDKR/OhMyTermux/raw/main/$mesa_package"
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget "$mesa_url"
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./"$mesa_package"
    else
        echo -e "${COLOR_BLUE}Téléchargement de Mesa-Vulkan...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $mesa_url $redirect"
        echo -e "${COLOR_BLUE}Installation de Mesa-Vulkan...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$mesa_package $redirect"
    fi
}

# Fonction principale
main() {
    check_dependencies
    show_banner
    # Récupération du nom d'utilisateur
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
        eval "proot-distro install debian $redirect"
    fi
    show_banner
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Recherche de mise à jour" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Mise à jour des paquets" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y
    else
        echo -e "${COLOR_BLUE}Recherche de mise à jour...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update $redirect"
        echo -e "${COLOR_BLUE}Mise à jour des paquets...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y $redirect"
    fi
    install_packages_proot
    create_user_proot
    configure_user_rights
    show_banner
    if [ "$USE_GUM" = true ]; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Configuration de la distribution" -- bash -c '
            echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
        '
    else
        echo -e "${COLOR_BLUE}Configuration de la distribution...${COLOR_RESET}"
        eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"echo 'export DISPLAY=:1.0' >> /home/$username/.bashrc\" $redirect"
    fi
    # Ajout des alias dans .bashrc
    eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"cat << 'EOF' >> /home/$username/.bashrc
alias zink='MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform '
alias hud='GALLIUM_HUD=fps '
alias ..='cd ..'
alias q='exit'
alias c='clear'
alias cat='bat '
alias apt='sudo nala '
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
alias push='git pull && git add . && git commit -m \\\"mobile push\\\" && git push'
alias bashconfig='nano \\\$HOME/.bashrc'
EOF\" $redirect"
    # Configuration du fuseau horaire
    timezone=$(getprop persist.sys.timezone)
    eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"
        rm /etc/localtime
        cp /usr/share/zoneinfo/$timezone /etc/localtime
    \" $redirect"
    # Configuration des icônes et thèmes
    eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 mkdir -p /usr/share/icons $redirect"
    cd "$PREFIX/share/icons"
    eval "find dist-dark | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 cpio -pdm /usr/share/icons $redirect"
    eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"cat << EOF > /home/$username/.Xresources
Xcursor.theme: dist-dark
EOF\" $redirect"
    # Création des répertoires nécessaires
    eval "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"mkdir -p /home/$username/.fonts/ /home/$username/.themes/\" $redirect"
    install_mesa_vulkan
}

main "$@"
