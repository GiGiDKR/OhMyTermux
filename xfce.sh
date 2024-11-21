#!/bin/bash

USE_GUM=false
VERBOSE=false

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

# Configuration de la redirection
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

# Fonction pour afficher l'aide
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

# Gestion des arguments
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

# Fonction pour afficher la bannerière
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

# Fonction de gestion des erreurs
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERREUR: Installation de OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERREUR: Installation de OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Veuillez vous référer au(x) message(s) d'erreur ci-dessus.${COLOR_RESET}"
    fi
}

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    if $USE_GUM; then
        gum style --foreground 33 "$1"
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    if $USE_GUM; then
        gum style --foreground 76 "$1"
    else
        echo -e "\e[38;5;76m$1${COLOR_RESET}"
    fi
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    if $USE_GUM; then
        gum style --foreground 196 "$1"
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

# Fonction pour journaliser les erreurs
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/ohmytermux.log"
}

# Fonction pour exécuter une commande et afficher le résultat
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

# TODO Implémenter la fonction install_package
# Fonction pour installer un package
#install_package() {
#    local pkg=$1
#    execute_command "pkg install $pkg -y" "Installation de $pkg"
#}

# Fonction pour télécharger un fichier

download_file() {
    local url=$1
    local message=$2
    execute_command "wget $url" "$message"
}

trap finish EXIT

# Fonction principale
main() {
    # Installation de gum si nécessaire
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo -e "${COLOR_BLUE}Installation de gum${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi

    info_msg "❯ Installation de XFCE"

    execute_command "pkg update -y && pkg upgrade -y" "Mise à jour des paquets"

    # Installation des packages
    pkgs=('virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme' 'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly')


    for pkg in "${pkgs[@]}"; do
        execute_command "pkg install $pkg -y" "Installation de $pkg"
    done

    # Configuration du bureau
    execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop && chmod +x $HOME/Desktop/firefox.desktop" "Configuration du bureau"

    # Téléchargement du fond d'écran
    download_file "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/src/waves.png" "Téléchargement du fond d'écran"
    execute_command "mkdir -p $PREFIX/share/backgrounds/xfce/ && mv waves.png $PREFIX/share/backgrounds/xfce/" "Configuration du fond d'écran"

    # Téléchargement du thème
    download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "Téléchargement de WhiteSur-Dark"
    execute_command "unzip 2024.09.02.zip && tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz && mv WhiteSur-Dark/ $PREFIX/share/themes/ && rm -rf WhiteSur* && rm 2024.09.02.zip" "Installation du thème"

    # 
    download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement de Fluent Cursor"
    execute_command "unzip 2024-02-25.zip && mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && rm -rf $HOME/Fluent* && rm 2024-02-25.zip" "Installation des curseurs"

    # Téléchargement de la pré-configuration
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/1.1.0/src/config.zip" "Téléchargement de la configuration XFCE"
        execute_command "unzip -o config.zip && rm config.zip" "Installation de la configuration XFCE"
    }

main "$@"