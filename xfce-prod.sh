#!/bin/bash

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


# Nouvelles fonctions de message
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

install_package() {
    local pkg=$1
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- pkg install "$pkg" -y
    else
        show_banner
        execute_command "pkg install $pkg -y" "Installation de $pkg"
    fi
}

download_file() {
    local url=$1
    local message=$2
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$message" -- wget "$url"
    else
        echo -e "${COLOR_BLUE}$message${COLOR_RESET}"
        eval "wget $url $redirect"
    fi
}

trap finish EXIT

show_banner
if $USE_GUM && ! command -v gum &> /dev/null; then
    echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
    pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
fi

username="$1"

pkgs=('virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme' 'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly')

for pkg in "${pkgs[@]}"; do
    install_package "$pkg"
done

eval "{
    mkdir -p $HOME/Desktop
    cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop
    chmod +x $HOME/Desktop/firefox.desktop
} $redirect"

show_banner
download_file "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" "Téléchargement du fond d'écran"

eval "mkdir -p $PREFIX/share/backgrounds/xfce/ $redirect"
eval "mv waves.png $PREFIX/share/backgrounds/xfce/ $redirect"

show_banner
download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "Installation WhiteSur-Dark"
eval "{
    unzip 2024.09.02.zip
    tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    rm -rf WhiteSur*
    rm 2024.09.02.zip
} $redirect"

show_banner
download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Installation Fluent Cursor"
eval "{
    unzip 2024-02-25.zip
    mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/
    mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/
    rm -rf $HOME/Fluent*
    rm 2024-02-25.zip
} $redirect"

show_banner
download_file "https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip" "Installation de la configuration"
eval "{
    unzip config.zip
    rm config.zip
} $redirect"
