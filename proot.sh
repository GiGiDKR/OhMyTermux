#!/bin/bash

set -euo pipefail

USE_GUM=false
VERBOSE=false

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v Afficher les sorties détaillées"
    echo "  --help | -h    Afficher ce message d'aide"
}

# Traitement des options
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
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

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "\e[38;5;82m$1\e[0m"
    fi
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "\e[38;5;196m$1\e[0m"
    fi
}

# Fonction pour exécuter une commande et afficher le résultat
execute_command() {
    local command="$1"
    local info_msg="$2"
    local success_msg="✓ $info_msg"
    local error_msg="✗ $info_msg"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command $redirect"; then
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command $redirect"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            return 1
        fi
    fi
}

# Fonction pour vérifier les dépendances nécessaires
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

# Fonction pour vérifier l'existence de .bashrc
check_bashrc() {
    if [ ! -f "$bashrc" ]; then
        error_msg "Le fichier .bashrc n'existe pas pour l'utilisateur $username."
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 touch $bashrc" "Création du fichier .bashrc"
    fi
}

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
    local mesa_url="https://github.com/GiGiDKR/OhMyTermux/raw/1.0.9/$mesa_package"
    
    if ! proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dpkg -s mesa-vulkan-kgsl &> /dev/null; then
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $mesa_url" "Téléchargement de Mesa-Vulkan"
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$mesa_package" "Installation de Mesa-Vulkan"
    else
        info_msg "Mesa-Vulkan est déjà installé."
    fi
}

add_aliases() {
    local shell_rc="$1"
    local shell_name="$2"

    local aliases_content="
alias zink='MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform'
alias hud='GALLIUM_HUD=fps'
alias ..='cd ..'
alias q='exit'
alias c='clear'
alias cat='bat'
alias apt='sudo nala'
alias install='sudo nala install -y'
alias update='sudo nala update'
alias upgrade='sudo nala upgrade -y'
alias remove='sudo nala remove -y'
alias list='nala list --upgradeable'
alias show='nala show'
alias search='nala search'
alias start='echo \"Veuillez exécuter depuis Termux et non Debian proot.\"'
alias cm='chmod +x'
alias clone='git clone'
alias push='git pull && git add . && git commit -m \"mobile push\" && git push'
alias bashrc='nano \$HOME/.bashrc'
alias zshrc='nano \$HOME/.zshrc'
alias ${shell_name}rc='nano \$HOME/.${shell_name}rc'
"
    execute_command "echo \"$aliases_content\" >> '$shell_rc'" "Ajout d'alias dans .${shell_name}rc"
}

# Fonction principale
main() {
    check_dependencies
    show_banner

    # Gestion des arguments utilisateur et mot de passe
    if [ $# -eq 0 ]; then
        if [ "$USE_GUM" = true ]; then
            username=$(gum input --prompt "Nom d'utilisateur : " --placeholder "Entrez votre nom d'utilisateur")
            password=$(gum input --password --prompt "Mot de passe : " --placeholder "Entrez votre mot de passe")
        else
            echo -e "${COLOR_BLUE}Entrez votre nom d'utilisateur : ${COLOR_RESET}"
            read -r username
            echo -e "${COLOR_BLUE}Entrez votre mot de passe : ${COLOR_RESET}"
            read -rs password
        fi
    elif [ $# -eq 1 ]; then
        username="$1"
        if [ "$USE_GUM" = true ]; then
            password=$(gum input --password --prompt "Mot de passe : " --placeholder "Entrez votre mot de passe")
        else
            echo -e "${COLOR_BLUE}Entrez votre mot de passe : ${COLOR_RESET}"
            read -rs password
        fi
    elif [ $# -eq 2 ]; then
        username="$1"
        password="$2"
    else
        show_help
        exit 1
    fi
    
    show_banner
    execute_command "proot-distro install debian" "Installation de Debian proot"
    
    # Vérification de l'installation de Debian
    if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
        error_msg "L'installation de Debian a échoué."
        exit 1
    fi
    
    bashrc="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
    zshrc="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.zshrc"

    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update" "Recherche de mise à jour"
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y" "Mise à jour des paquets"
    install_packages_proot
    
    create_user_proot
    configure_user_rights
    
    check_bashrc
    execute_command "echo 'export DISPLAY=:1.0' >> '$bashrc'" "Configuration de la distribution"

    add_aliases "$bashrc" "bash"
        if [ -f "$zshrc" ]; then
            add_aliases "$zshrc" "zsh"
        fi

    # Configuration du fuseau horaire
    timezone=$(getprop persist.sys.timezone)
    execute_command "
        proot-distro login debian -- rm /etc/localtime
        proot-distro login debian -- cp /usr/share/zoneinfo/$timezone /etc/localtime
    " "Configuration du fuseau horaire"

    # Configuration des icônes et thèmes
    cd "$PREFIX/share/icons"
    execute_command "find dist-dark | cpio -pdm $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons" "Configuration des icônes"
    
    # Configuration de .Xresources
    execute_command "cat <<'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources
    Xcursor.theme: dist-dark
    EOF" "Configuration des curseurs"

    # Création des répertoires nécessaires
    execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"mkdir -p /home/$username/.fonts/ /home/$username/.themes/\"" "Configuration des thèmes et polices"
    
    install_mesa_vulkan
}

main "$@"