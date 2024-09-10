#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Configuration
USE_GUM=false
VERBOSE=false
LOG_FILE="$HOME/ohmytermux.log"

# Couleurs (compatibles avec Termux)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Fonctions utilitaires
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERREUR]${NC} $*" >&2 | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $*" | tee -a "$LOG_FILE"
}

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

show_help() {
    cat << EOF
Usage: $0 [options]

Options:
    --gum, -g      Utiliser gum pour l'interface
    --verbose, -v  Afficher les détails des opérations
    --help, -h     Afficher ce message d'aide
EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gum|-g) USE_GUM=true ;;
            --verbose|-v) VERBOSE=true ;;
            --help|-h) show_help ;;
            *) error "Option non reconnue : $1" ;;
        esac
        shift
    done
}

run_command() {
    local title="$1"
    shift
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$title" -- "$@"
    else
        show_banner
        log "$title..."
        if $VERBOSE; then
            "$@" | tee -a "$LOG_FILE"
        else
            "$@" >> "$LOG_FILE" 2>&1
        fi
    fi
}

download_file() {
    local url="$1"
    local filename="$2"
    run_command "Téléchargement de $filename" wget "$url" -O "$filename"
}

download_and_extract() {
    local url="$1"
    local filename="$2"
    local extract_dir="$3"
    local dest_dir="$4"
    
    download_file "$url" "$filename"
    run_command "Extraction de $filename" unzip -q "$filename"
    run_command "Déplacement des fichiers" mv "$extract_dir"/* "$dest_dir/"
    run_command "Nettoyage" rm -rf "$extract_dir" "$filename"
}

install_packages() {
    local -a pkgs=(
        'virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme'
        'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly'
    )

    run_command "Mise à jour des paquets" pkg update -y
    for pkg in "${pkgs[@]}"; do
        run_command "Installation de $pkg" pkg install "$pkg" -y
    done
}

setup_themes() {
    mkdir -p "$PREFIX/share/themes" "$PREFIX/share/icons" "$PREFIX/share/backgrounds/xfce"
    download_and_extract "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "WhiteSur-gtk-theme.zip" "WhiteSur-gtk-theme-2024.09.02" "$PREFIX/share/themes"
    download_and_extract "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Fluent-icon-theme.zip" "Fluent-icon-theme-2024-02-25/cursors" "$PREFIX/share/icons"
    download_file "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" "$PREFIX/share/backgrounds/xfce/waves.png"
}

main() {
    parse_arguments "$@"
    
    show_banner
    log "Début de l'installation de OhMyTermux"
    
    install_packages
    setup_themes
    
    #show_banner
    #success "Installation de OhMyTermux terminée avec succès"
}

trap 'error "Une erreur est survenue. Consultez le fichier de log : $LOG_FILE"' ERR

main "$@"