#!/bin/bash

set -euo pipefail

USE_GUM=false
VERBOSE=false

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

bashrc="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"

# Configuration de la redirection
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
else
    redirect=""
fi

# Fonction pour vérifier les dépendances nécessaires
check_dependencies() {
    if [ "$USE_GUM" = true ]; then
        if $USE_GUM && ! command -v gum &> /dev/null; then
            echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
            pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
        fi
    fi

    if ! command -v proot-distro &> /dev/null; then
        error_msg "Erreur : proot-distro n'est pas installé. Veuillez l'installer avant de continuer."
        exit 1
    fi
}

check_bashrc() {
    if [ ! -f "$bashrc" ]; then
        error_msg "Le fichier .bashrc n'existe pas pour l'utilisateur $username."
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 touch $bashrc" "Création du fichier .bashrc"
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

trap finish EXIT

# Fonction pour installer les paquets nécessaires dans proot
install_packages_proot() {
    local pkgs_proot=('sudo' 'wget' 'nala' 'jq')
    for pkg in "${pkgs_proot[@]}"; do
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install $pkg -y" "Installation de $pkg"
    done
}

# Fonction pour créer un utilisateur dans proot avec mot de passe
create_user_proot() {
    execute_command "
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
        echo '$username:$password' | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chpasswd
    " "Création de l'utilisateur"
}

# Fonction pour configurer les droits de l'utilisateur
configure_user_rights() {
    execute_command '
        chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        echo "$username ALL=(ALL) ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    ' "Ajout des droits utilisateur"
}

# Fonction pour installer Mesa-Vulkan
install_mesa_vulkan() {
    local mesa_package="mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb"
    local mesa_url="https://github.com/GiGiDKR/OhMyTermux/raw/main/$mesa_package"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $mesa_url" "Téléchargement de Mesa-Vulkan"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$mesa_package" "Installation de Mesa-Vulkan"
}

# Fonction principale
main() {
    check_dependencies
    show_banner
    if [ $# -eq 0 ]; then
        if [ "$USE_GUM" = true ]; then
            username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
            password=$(gum input --password --placeholder "Entrez votre mot de passe")
        else
            echo -e "${COLOR_BLUE}Entrez votre nom d'utilisateur :${COLOR_RESET}"
            read -r username
            echo -e "${COLOR_BLUE}Entrez votre mot de passe :${COLOR_RESET}"
            read -rs password
        fi
    else
        username="$1"
        password="$2"
    fi
    show_banner
    execute_command "proot-distro install debian" "Installation de Debian proot"
    show_banner
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update" "Recherche de mise à jour"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y" "Mise à jour des paquets"
    install_packages_proot
    create_user_proot
    configure_user_rights
    show_banner
    execute_command "echo 'export DISPLAY=:1.0' >> '$bashrc'" "Configuration de la distribution"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"cat << 'EOF' >> $bashrc
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
EOF\"" "Ajout d'alias dans .bashrc"
    # Configuration du fuseau horaire
    timezone=$(getprop persist.sys.timezone)
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"
        rm /etc/localtime
        cp /usr/share/zoneinfo/$timezone /etc/localtime
    \"" "Configuration du fuseau horaire"
    # Configuration des icônes et thèmes
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 mkdir -p /usr/share/icons" "Configuration des thèmes"
    cd "$PREFIX/share/icons"
    execute_command "find dist-dark | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 cpio -pdm /usr/share/icons" "Configuration des icônes"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"cat << EOF > /home/$username/.Xresources
Xcursor.theme: dist-dark
EOF\"" "Configuration des curseurs"
    # Création des répertoires nécessaires
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"mkdir -p /home/$username/.fonts/ /home/$username/.themes/\"" "Création des répertoires nécessaires"
    install_mesa_vulkan
}

info_msg() {
    if $USE_GUM; then
        gum style --foreground 33 "$1"
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

success_msg() {
    if $USE_GUM; then
        gum style --foreground 76 "$1"
    else
        echo -e "\e[38;5;76m$1${COLOR_RESET}"
    fi
}

error_msg() {
    if $USE_GUM; then
        gum style --foreground 196 "$1"
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

execute_command() {
    local command="$1"
    local message="$2"

    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$message" -- eval "$command $redirect"
    else
        info_msg "$message"
        eval "$command $redirect"
    fi
}

main "$@"