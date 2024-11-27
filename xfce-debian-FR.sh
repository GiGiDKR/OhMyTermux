#!/bin/bash

USE_GUM=false
VERBOSE=false

#------------------------------------------------------------------------------
# COULEURS
#------------------------------------------------------------------------------
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_GREEN="\e[38;5;82m"
COLOR_GOLD="\e[38;5;220m"
COLOR_RESET="\e[0m"

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# AFFICHAGE DE L'AIDE
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "Aide Installation XFCE sur Debian"
    echo 
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --gum | -g     Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v Afficher les sorties détaillées"
    echo "  --help | -h    Afficher ce message d'aide"
}

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
#------------------------------------------------------------------------------
for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            redirect=""
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
# AFFICHAGE DE LA BANNIERE EN MODE TEXTE
#------------------------------------------------------------------------------
bash_banner() {
    clear
    local BANNER="
╔════════════════════════════════════════╗
║                                        ║
║             XFCE SUR DEBIAN            ║
║                                        ║
╚════════════════════════════════════════╝"

    echo -e "${COLOR_BLUE}${BANNER}${COLOR_RESET}\n"
}

#------------------------------------------------------------------------------
# AFFICHAGE DE LA BANNIERE EN MODE GRAPHIQUE
#------------------------------------------------------------------------------
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
            "" "XFCE SUR DEBIAN" ""
    else
        bash_banner
    fi
}

#------------------------------------------------------------------------------
# GESTION DES ERREURS
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERREUR: Installation de XFCE impossible."
        else
            echo -e "${COLOR_RED}ERREUR: Installation de XFCE impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Veuillez vous référer au(x) message(s) d'erreur ci-dessus.${COLOR_RESET}"
    fi
}

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
        echo -e "\n${COLOR_GOLD}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# JOURNALISATION DES ERREURS
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/.config/xfce-debian/install.log"
}

#------------------------------------------------------------------------------
# EXECUTION D'UNE COMMANDE ET AFFICHAGE DYNAMIQUE DU RÉSULTAT
#------------------------------------------------------------------------------
execute_command() {
    local command="$1"
    local info_msg="$2"
    local success_msg="✓ $info_msg"
    local error_msg="✗ $info_msg"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command $redirect"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            log_error "$command"
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command $redirect"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            log_error "$command"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# TÉLÉCHARGEMENT D'UN FICHIER
#------------------------------------------------------------------------------
download_file() {
    local url=$1
    local message=$2
    execute_command "wget $url" "$message"
}

trap finish EXIT

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
main() {
    # Vérification des privilèges sudo
    if [ "$(id -u)" -ne 0 ]; then
        error_msg "Ce script doit être exécuté avec les privilèges sudo"
        exit 1
    fi

    # Installation de gum si nécessaire
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo -e "${COLOR_BLUE}Installation de gum${COLOR_RESET}"
        apt update -y > /dev/null 2>&1 && apt install gum -y > /dev/null 2>&1
    fi

    title_msg "❯ Installation de XFCE"

    # Mise à jour du système
    execute_command "apt update -y && apt upgrade -y" "Mise à jour du système"

    # Installation des paquets XFCE
    pkgs=(
        'xfce4'
        'xfce4-goodies'
        'pavucontrol'
        'jq'
        'wmctrl'
        'firefox-esr'
        'netcat-openbsd'
        'lightdm'
    )
    
    for pkg in "${pkgs[@]}"; do
        execute_command "apt install -y $pkg" "Installation de $pkg"
    done

    # Configuration du bureau
    execute_command "mkdir -p /usr/share/desktop-base" "Création du répertoire desktop-base"

    # Téléchargement et installation des fonds d'écran WhiteSur
    download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Téléchargement des fonds d'écran WhiteSur"
    execute_command "unzip main.zip && \
                    mkdir -p /usr/share/backgrounds/WhiteSur && \
                    cp -r WhiteSur-wallpapers-main/4k/* /usr/share/backgrounds/WhiteSur/ && \
                    rm -rf WhiteSur-wallpapers-main main.zip" "Installation des fonds d'écran"

    # Téléchargement du thème
    download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Téléchargement du thème WhiteSur"
    execute_command "unzip 2024-11.18.zip && \
                    cd WhiteSur-gtk-theme-2024-11-18 && \
                    ./install.sh -d /usr/share/themes && \
                    cd .. && \
                    rm -rf WhiteSur-gtk-theme-2024-11-18 2024-11-18.zip" "Installation du thème"

    # Téléchargement et installation du thème d'icônes WhiteSur
    download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes WhiteSur"
    execute_command "unzip master.zip && \
                    cd WhiteSur-icon-theme-master && \
                    ./install.sh --dest /usr/share/icons && \
                    cd .. && \
                    rm -rf WhiteSur-icon-theme-master master.zip" "Installation des icônes"

    # Téléchargement des curseurs
    download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement de Fluent Cursor"
    execute_command "unzip 2024-02-25.zip && \
                    cd Fluent-icon-theme-2024-02-25/cursors && \
                    mkdir -p /usr/share/icons/Fluent-cursors && \
                    cp -r dist/* /usr/share/icons/Fluent-cursors/ && \
                    mkdir -p /usr/share/icons/Fluent-cursors-dark && \
                    cp -r dist-dark/* /usr/share/icons/Fluent-cursors-dark/ && \
                    cd ../.. && \
                    rm -rf Fluent-icon-theme-2024-02-25 2024-02-25.zip" "Installation des curseurs"

    # Configuration de LightDM
    execute_command "systemctl enable lightdm" "Activation de LightDM"

    success_msg "✓ Installation de XFCE terminée"
    info_msg "Redémarrez votre système pour utiliser XFCE"
}

main "$@" 