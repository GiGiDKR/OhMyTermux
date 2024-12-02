#!/bin/bash

set -euo pipefail

USE_GUM=false
VERBOSE=false

#------------------------------------------------------------------------------
# COULEURS D'AFFICHAGE
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Succès
COLOR_GOLD='\033[38;5;220m'   # Avertissement
COLOR_RED='\033[38;5;196m'    # Erreur
COLOR_RESET='\033[0m'         # Réinitialisation

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    REDIRECT=">/dev/null 2>&1"
else
    REDIRECT=""
fi

#------------------------------------------------------------------------------
# AFFICHAGE DE L'AIDE
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "Aide OhMyTermux"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v Afficher les sorties détaillées"
    echo "  --help | -h    Afficher ce message d'aide"
}

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
#------------------------------------------------------------------------------
for ARG in "$@"; do
    case $ARG in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            REDIRECT=""
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

#------------------------------------------------------------------------------
# MESSAGES D'INFORMATION
#------------------------------------------------------------------------------
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE SUCCÈS
#------------------------------------------------------------------------------
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES D'ERREUR
#------------------------------------------------------------------------------
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE TITRE
#------------------------------------------------------------------------------
title_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 220 --bold
    else
        echo -e "\n${COLOR_GOLD}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE SOUS-TITRE
#------------------------------------------------------------------------------
subtitle_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33 --bold
    else
        echo -e "\n${COLOR_BLUE}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# JOURNALISATION DES ERREURS
#------------------------------------------------------------------------------
log_error() {
    local ERROR_MSG="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $ERROR_MSG" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
#------------------------------------------------------------------------------
execute_command() {
    local COMMAND="$1"
    local INFO_MSG="$2"
    local SUCCESS_MSG="✓ $INFO_MSG"
    local ERROR_MSG="✗ $INFO_MSG"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            gum style "$SUCCESS_MSG" --foreground 82
        else
            gum style "$ERROR_MSG" --foreground 196
            log_error "$COMMAND"
            return 1
        fi
    else
        info_msg "$INFO_MSG"
        if eval "$COMMAND $REDIRECT"; then
            success_msg "$SUCCESS_MSG"
        else
            error_msg "$ERROR_MSG"
            log_error "$COMMAND"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# VÉRIFICATION DES DÉPENDANCES
#------------------------------------------------------------------------------
check_dependencies() {
    if [ "$USE_GUM" = true ]; then
        if $USE_GUM && ! command -v gum &> /dev/null; then
            echo -e "${COLOR_BLUE}Installation de gum${COLOR_RESET}"
            pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
        fi
    fi

    if ! command -v proot-distro &> /dev/null; then
        error_msg "Veuillez installer proot-distro avant de continuer."
        exit 1
    fi
}

#------------------------------------------------------------------------------
# AFFICHAGE DE LA BANNIERE EN MODE TEXTE
#------------------------------------------------------------------------------
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


#------------------------------------------------------------------------------
# AFFICHAGE DE LA BANNIERE
#------------------------------------------------------------------------------
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 33 \
            --border-foreground 33 \
            --border double \
            --align center \
            --width 42 \
            --margin "1 1 1 0" \
            "" "OHMYTERMUX" ""
    else
        bash_banner
    fi
}

#------------------------------------------------------------------------------
# GESTION DES ERREURS
#------------------------------------------------------------------------------
finish() {
    local RET=$?
    if [ ${RET} -ne 0 ] && [ ${RET} -ne 130 ]; then
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

#------------------------------------------------------------------------------
# INSTALLATION DES PAQUETS PROOT
#------------------------------------------------------------------------------
install_packages_proot() {
    local PKGS_PROOT=('sudo' 'wget' 'nala' 'xfconf')
    for PKG in "${PKGS_PROOT[@]}"; do
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install $PKG -y" "Installation de $PKG"
    done
}

#------------------------------------------------------------------------------
# CRÉATION D'UN UTILISATEUR DANS PROOT AVEC MOT DE PASSE
#------------------------------------------------------------------------------
create_user_proot() {
    execute_command "
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$USERNAME'
        echo '$USERNAME:$PASSWORD' | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chpasswd
    " "Création de l'utilisateur"
}

#------------------------------------------------------------------------------
# CONFIGURATION DES DROITS DE L'UTILISATEUR
#------------------------------------------------------------------------------
configure_user_rights() {
    execute_command "
        # Ajout de l'utilisateur au groupe sudo
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 usermod -aG sudo '$USERNAME'
        
        # Création du fichier sudoers.d pour l'utilisateur
        echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' > '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers.d/$USERNAME'
        chmod 0440 '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers.d/$USERNAME'
        
        # Configuration du fichier sudoers principal
        echo '%sudo ALL=(ALL:ALL) ALL' >> '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'
        
        # Vérification des permissions
        chmod 440 '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'
        chown root:root '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'
    " "Configuration des droits sudo"
}

#------------------------------------------------------------------------------
# INSTALLATION DE MESA-VULKAN
#------------------------------------------------------------------------------
install_mesa_vulkan() {
    local MESA_PACKAGE="mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb"
    local MESA_URL="https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/$MESA_PACKAGE"
    
    if ! proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dpkg -s mesa-vulkan-kgsl &> /dev/null; then
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $MESA_URL" "Téléchargement de Mesa-Vulkan"
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$MESA_PACKAGE" "Installation de Mesa-Vulkan"
    else
        info_msg "Mesa-Vulkan est déjà installé."
    fi
}

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
check_dependencies
title_msg "❯ Installation de Debian Proot"

if [ $# -eq 0 ]; then
    if [ "$USE_GUM" = true ]; then
        USERNAME=$(gum input --prompt "Username: " --placeholder "Enter your username")
        while true; do
            PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Enter your password")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Enter your password again")
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground "#FF0000" "Passwords do not match. Please try again."
            fi
        done
    else
        echo -e "${COLOR_BLUE}Enter your username: ${COLOR_RESET}"
        read -r USERNAME
        while true; do
            echo -e "${COLOR_BLUE}Enter your password: ${COLOR_RESET}"
            read -rs PASSWORD
            echo -e "${COLOR_BLUE}Confirm your password: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}Passwords do not match. Please try again.${COLOR_RESET}"
            fi
        done
    fi
elif [ $# -eq 1 ]; then
    USERNAME="$1"
    if [ "$USE_GUM" = true ]; then
        while true; do
            PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Enter your password")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Enter your password again")
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground "#FF0000" "Passwords do not match. Please try again."
            fi
        done
    else
        while true; do
            echo -e "${COLOR_BLUE}Enter your password: ${COLOR_RESET}"
            read -rs PASSWORD
            echo -e "${COLOR_BLUE}Confirm your password: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}Passwords do not match. Please try again.${COLOR_RESET}"
            fi
        done
    fi
elif [ $# -eq 2 ]; then
    USERNAME="$1"
    PASSWORD="$2"
else
    show_help
    exit 1
fi

execute_command "proot-distro install debian" "Installation de la distribution"

#------------------------------------------------------------------------------
# VÉRIFICATION DE L'INSTALLATION DE DEBIAN
#------------------------------------------------------------------------------
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
    error_msg "L'installation de Debian a échoué."
    exit 1
fi

execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update" "Recherche de mise à jour"
execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y" "Mise à jour des paquets"

install_packages_proot

subtitle_msg "❯ Configuration de la distribution"

create_user_proot
configure_user_rights

#------------------------------------------------------------------------------
# CONFIGURATION DU FUSEAU HORAIRE
#------------------------------------------------------------------------------
TIMEZONE=$(getprop persist.sys.timezone)
execute_command "
    proot-distro login debian -- rm /etc/localtime
    proot-distro login debian -- cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
" "Configuration du fuseau horaire"

#------------------------------------------------------------------------------
# CONFIGURATION DES ICONES ET THÈMES
#------------------------------------------------------------------------------
mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons
execute_command "cp -r $PREFIX/share/icons/WhiteSur $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/WhiteSur" "Configuration des icônes"

#------------------------------------------------------------------------------
# CONFIGURATION DES CURSEURS
#------------------------------------------------------------------------------
execute_command "cat <<'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$USERNAME/.Xresources
Xcursor.theme: WhiteSur
EOF" "Configuration des curseurs"

#------------------------------------------------------------------------------
# CONFIGURATION DE LA POLICE
#------------------------------------------------------------------------------
#execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"mkdir -p /home/$USERNAME/.fonts/ /home/$USERNAME/.themes/\"" "Configuration des thèmes et polices"

if [ -f "$HOME/.termux/font.ttf" ]; then
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c 'mkdir -p /usr/share/fonts/ && \
    cp /data/data/com.termux/files/home/.termux/font.ttf /usr/share/fonts/MesloLGL.ttf && \
    fc-cache -f -v /usr/share/fonts/'" "Configuration de la police"
    # Modification de la police pour xfce4-terminal
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c 'sed -i \"s/FontName=.*/FontName=MesloLGL 11/\" /home/$USERNAME/.config/xfce4/terminal/terminalrc'" "Modification de la police du terminal XFCE"
    # Ajustement des permissions
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chown -R $USERNAME:users /home/$USERNAME/.config" "Configuration des permissions"
fi

install_mesa_vulkan