#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Configuration
USE_GUM=false
VERBOSE=false
LOG_FILE="$HOME/ohmytermux_proot_install.log"

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
Usage: $0 [options] [username]

Options:
    --gum, -g      Utiliser gum pour l'interface
    --verbose, -v  Afficher les détails des opérations
    --help, -h     Afficher ce message d'aide

Si aucun nom d'utilisateur n'est fourni, il sera demandé interactivement.
EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gum|-g) USE_GUM=true ;;
            --verbose|-v) VERBOSE=true ;;
            --help|-h) show_help ;;
            *) 
                if [[ -z ${username+x} ]]; then
                    username="$1"
                else
                    error "Option non reconnue : $1"
                fi
                ;;
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

install_packages() {
    local -a pkgs=('sudo' 'wget' 'nala' 'jq')

    for pkg in "${pkgs[@]}"; do
        run_command "Installation de $pkg" proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y
    done
}

setup_user() {
    run_command "Création de l'utilisateur" bash -c "
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
    "

    run_command "Ajout des droits utilisateur" bash -c '
        chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    '
}

configure_environment() {
    run_command "Configuration de la distribution" bash -c '
        echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
    '

    cat << 'EOF' >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
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
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
alias bashconfig='nano $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc'
EOF

    timezone=$(getprop persist.sys.timezone)
    run_command "Configuration du fuseau horaire" bash -c '
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 rm /etc/localtime
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 cp /usr/share/zoneinfo/$timezone /etc/localtime
    '

    run_command "Configuration des icônes" bash -c '
        cd "$PREFIX/share/icons"
        find dist-dark | cpio -pdm "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons"
    '

    cat << EOF > "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources"
Xcursor.theme: dist-dark
EOF

    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.fonts/"
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.themes/"
}

install_mesa_vulkan() {
    run_command "Téléchargement de Mesa-Vulkan" proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
    run_command "Installation de Mesa-Vulkan" proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
}

main() {
    parse_arguments "$@"
    
    if [[ -z ${username+x} ]]; then
        if $USE_GUM; then
            username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
        else
            show_banner
            echo -e "${BLUE}Entrez votre nom d'utilisateur :${NC}"
            read -r username
        fi
    fi

    show_banner
    log "Début de l'installation de OhMyTermux Proot"
    
    run_command "Installation de Debian proot" proot-distro install debian
    run_command "Mise à jour des paquets" proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update
    run_command "Mise à jour du système" proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y
    
    install_packages
    setup_user
    configure_environment
    install_mesa_vulkan
    
    #show_banner
    #success "Installation de OhMyTermux Proot terminée avec succès"
}

trap 'error "Une erreur est survenue. Consultez le fichier de log : $LOG_FILE"' ERR

main "$@"