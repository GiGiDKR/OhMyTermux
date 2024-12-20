#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES GLOBALES
#------------------------------------------------------------------------------
USE_GUM=false
VERBOSE=false
INSTALL_THEME=false
INSTALL_ICONS=false
INSTALL_WALLPAPERS=false
INSTALL_CURSORS=false
SELECTED_THEME=""
SELECTED_ICON_THEME=""
SELECTED_WALLPAPER=""

# Variables pour l'utilisateur PRoot
PROOT_USERNAME=""
PROOT_PASSWORD=""

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
        --username=*)
            PROOT_USERNAME="${ARG#*=}"
            shift
            ;;
        --password=*)
            PROOT_PASSWORD="${ARG#*=}"
            shift
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
    local USERNAME=$(whoami)
    local HOSTNAME=$(hostname)
    local CWD=$(pwd)
    echo "[$(date +'%d/%m/%Y %H:%M:%S')] ERREUR: $ERROR_MSG | Utilisateur: $USERNAME | Machine: $HOSTNAME | Répertoire: $CWD" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
#------------------------------------------------------------------------------
execute_command() {
    local COMMAND="$1"
    local INFO_MSG="$2"
    local SUCCESS_MSG="✓ $INFO_MSG"
    local ERROR_MSG="✗ $INFO_MSG"
    local ERROR_DETAILS

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            gum style "$SUCCESS_MSG" --foreground 82
        else
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            gum style "$ERROR_MSG - $ERROR_DETAILS" --foreground 196
            log_error "$ERROR_DETAILS"
            return 1
        fi
    else
        tput sc
        info_msg "$INFO_MSG"
        
        if eval "$COMMAND $REDIRECT"; then
            tput rc
            tput el
            success_msg "$SUCCESS_MSG"
        else
            tput rc
            tput el
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            error_msg "$ERROR_MSG - $ERROR_DETAILS"
            log_error "$ERROR_DETAILS"
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
    #local PKGS_PROOT=('sudo' 'wget' 'nala' 'xfconf' 'gnome-themes-extra')
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
    local MESA_URL="https://github.com/GiGiDKR/OhMyTermux/raw/1.0.0/src/$MESA_PACKAGE"

    if ! proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dpkg -s mesa-vulkan-kgsl &> /dev/null; then
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $MESA_URL" "Téléchargement de Mesa-Vulkan"
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$MESA_PACKAGE" "Installation de Mesa-Vulkan"
    else
        info_msg "Mesa-Vulkan est déjà installé."
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION DES THÈMES ET ICÔNES
#------------------------------------------------------------------------------
configure_themes_and_icons() {
    # Charger la configuration depuis le fichier temporaire
    if [ -f "$HOME/.config/OhMyTermux/theme_config.tmp" ]; then
        source "$HOME/.config/OhMyTermux/theme_config.tmp"
    fi

    # Créer les répertoires nécessaires
    execute_command "
        mkdir -p \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes\"
        mkdir -p \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons\"
        mkdir -p \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/backgrounds/whitesur\"
        mkdir -p \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$USERNAME/.fonts/\"
        mkdir -p \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$USERNAME/.themes/\"
    " "Création des répertoires"

    # Copier les thèmes si installés
    if [ "$INSTALL_THEME" = true ] && [ -n "$SELECTED_THEME" ]; then
        case $SELECTED_THEME in
            "WhiteSur")
                execute_command "cp -r $PREFIX/share/themes/WhiteSur-Dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration du thème WhiteSur"
                ;;
            "Fluent")
                execute_command "cp -r $PREFIX/share/themes/Fluent-dark-compact $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration du thème Fluent"
                ;;
            "Lavanda")
                execute_command "cp -r $PREFIX/share/themes/Lavanda-dark-compact $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration du thème Lavanda"
                ;;
        esac
    fi

    # Copier les icônes si installées
    if [ "$INSTALL_ICONS" = true ] && [ -n "$SELECTED_ICON_THEME" ]; then
        case $SELECTED_ICON_THEME in
            "WhiteSur")
                execute_command "cp -r $PREFIX/share/icons/WhiteSur-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration des icônes WhiteSur"
                ;;
            "McMojave-circle")
                execute_command "cp -r $PREFIX/share/icons/McMojave-circle-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration des icônes McMojave"
                ;;
            "Tela")
                execute_command "cp -r $PREFIX/share/icons/Tela-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration des icônes Tela"
                ;;
            "Fluent")
                execute_command "cp -r $PREFIX/share/icons/Fluent-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration des icônes Fluent"
                ;;
            "Qogir")
                execute_command "cp -r $PREFIX/share/icons/Qogir-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration des icônes Qogir"
                ;;
        esac
    fi

    # Copier les fonds d'écran si installés
    if [ "$INSTALL_WALLPAPERS" = true ]; then
        execute_command "cp -r $PREFIX/share/backgrounds/whitesur/* $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/backgrounds/whitesur/" "Configuration des fonds d'écran"
    fi

    # Configuration des curseurs
    if [ "$INSTALL_CURSORS" = true ]; then
        cd "$PREFIX/share/icons"
        execute_command "find dist-dark | cpio -pdm \"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons\"" "Configuration des curseurs"
        
        # Configuration du fichier .Xresources
        cat << EOF > "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$USERNAME/.Xresources"
Xcursor.theme: dist-dark
EOF
    fi

    # Supprimer le fichier de configuration temporaire
    rm -f "$HOME/.config/OhMyTermux/theme_config.tmp"
}

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
check_dependencies
title_msg "❯ Installation de Debian Proot"

if [ $# -eq 0 ] && [ -z "$PROOT_USERNAME" ] && [ -z "$PROOT_PASSWORD" ]; then
    if [ "$USE_GUM" = true ]; then
        PROOT_USERNAME=$(gum input --prompt "Username: " --placeholder "Entrer un nom d'utilisateur")
        while true; do
            PROOT_PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Entrer un mot de passe")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirmer le mot de passe")
            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground 196 "Les mots de passe ne correspondent pas. Veuillez réessayer."
            fi
        done
    else
        echo -e "${COLOR_BLUE}Entrer un nom d'utilisateur: ${COLOR_RESET}"
        read -r PROOT_USERNAME
        tput cuu1
        tput el
        while true; do
            echo -e "${COLOR_BLUE}Entrer un mot de passe: ${COLOR_RESET}"
            read -rs PROOT_PASSWORD
            tput cuu1
            tput el
            echo -e "${COLOR_BLUE}Confirmer le mot de passe: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            tput cuu1
            tput el 
            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}Les mots de passe ne correspondent pas. Veuillez réessayer.${COLOR_RESET}"
                tput cuu1
                tput el
            fi
        done
    fi
elif [ $# -eq 1 ] && [ -z "$PROOT_PASSWORD" ]; then
    PROOT_USERNAME="$1"
    if [ "$USE_GUM" = true ]; then
        while true; do
            PROOT_PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Entrer un mot de passe")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirmer le mot de passe")
            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground 196 "Les mots de passe ne correspondent pas. Veuillez réessayer."
            fi
        done
    else
        while true; do
            echo -e "${COLOR_BLUE}Entrer un mot de passe: ${COLOR_RESET}"
            read -rs PROOT_PASSWORD
            tput cuu1
            tput el
            echo -e "${COLOR_BLUE}Confirmer le mot de passe: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            tput cuu1
            tput el
            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}Les mots de passe ne correspondent pas. Veuillez réessayer.${COLOR_RESET}"
                tput cuu1
                tput el
            fi
        done
    fi
elif [ $# -eq 2 ] && [ -z "$PROOT_USERNAME" ] && [ -z "$PROOT_PASSWORD" ]; then
    PROOT_USERNAME="$1"
    PROOT_PASSWORD="$2"
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

# Utiliser les variables PROOT_USERNAME et PROOT_PASSWORD pour create_user_proot
USERNAME="$PROOT_USERNAME"
PASSWORD="$PROOT_PASSWORD"
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
# CONFIGURATION GRAPHIQUE
#------------------------------------------------------------------------------
configure_themes_and_icons

#------------------------------------------------------------------------------
# INSTALLATION DE MESA-VULKAN
#------------------------------------------------------------------------------
install_mesa_vulkan

#------------------------------------------------------------------------------
# INSTALLATION DE DEBIAN
#------------------------------------------------------------------------------
install_debian() {
    title_msg "❯ Installation de Debian"
    
    # Si les identifiants ne sont pas fournis en argument, les demander
    if [ -z "$DEBIAN_USERNAME" ]; then
        if $USE_GUM; then
            DEBIAN_USERNAME=$(gum input --placeholder "Entrez le nom d'utilisateur pour Debian")
        else
            printf "${COLOR_BLUE}Entrez le nom d'utilisateur pour Debian : ${COLOR_RESET}"
            read -r DEBIAN_USERNAME
        fi
    fi
    
    if [ -z "$DEBIAN_PASSWORD" ]; then
        if $USE_GUM; then
            DEBIAN_PASSWORD=$(gum input --password --placeholder "Entrez le mot de passe pour Debian")
        else
            printf "${COLOR_BLUE}Entrez le mot de passe pour Debian : ${COLOR_RESET}"
            read -r -s DEBIAN_PASSWORD
            echo
        fi
    fi
    
    # Installation de Debian
    execute_command "proot-distro install debian" "Installation de Debian"
    
    # Configuration de l'utilisateur
    execute_command "proot-distro login debian -- useradd -m -s /bin/bash \"$DEBIAN_USERNAME\"" "Création de l'utilisateur"
    execute_command "proot-distro login debian -- bash -c \"echo '$DEBIAN_USERNAME:$DEBIAN_PASSWORD' | chpasswd\"" "Configuration du mot de passe"
    execute_command "proot-distro login debian -- usermod -aG sudo \"$DEBIAN_USERNAME\"" "Ajout aux sudoers"
    
    # Configuration de sudo sans mot de passe
    execute_command "proot-distro login debian -- bash -c 'echo \"$DEBIAN_USERNAME ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers'" "Configuration de sudo"
    
    success_msg "✓ Installation de Debian terminée"
}