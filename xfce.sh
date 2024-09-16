#!/bin/bash

USE_GUM=false

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
    esac
done

bash_banner() {
    clear
    local BANNER="
╔════════════════════════════════════════╗
║                                        ║
║           OHMYTERMUXSCRIPT             ║
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
            "" "OHMYTERMUXSCRIPT" ""
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

install_package() {
    local pkg=$1
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- pkg install "$pkg" -y
    else
        show_banner
        echo -e "${COLOR_BLUE}Installation de $pkg...${COLOR_RESET}"
        pkg install "$pkg" -y > /dev/null 2>&1
    fi
}

download_file() {
    local url=$1
    local message=$2
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$message" -- wget "$url"
    else
        echo -e "${COLOR_BLUE}$message${COLOR_RESET}"
        wget "$url" > /dev/null 2>&1
    fi
}

trap finish EXIT

show_banner
if $USE_GUM && ! command -v gum &> /dev/null; then
    echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
    pkg update -y > /dev/null 2>&1
    pkg install -y gum > /dev/null 2>&1
fi

username="$1"

pkgs=('virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme' 'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly')

for pkg in "${pkgs[@]}"; do
    install_package "$pkg"
done

{
    mkdir -p $HOME/Desktop
    cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop
    chmod +x $HOME/Desktop/firefox.desktop
}

show_banner
download_file "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png" "Téléchargement du fond d'écran"

mkdir -p $PREFIX/share/backgrounds/xfce/
mv waves.png $PREFIX/share/backgrounds/xfce/ > /dev/null 2>&1

show_banner
download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip" "Installation WhiteSur-Dark"
{
    unzip 2024.09.02.zip
    tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    rm -rf WhiteSur*
    rm 2024.09.02.zip
} > /dev/null 2>&1

show_banner
download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Installation Fluent Cursor"
{
    unzip 2024-02-25.zip
    mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/
    mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/
    rm -rf $HOME/Fluent*
    rm 2024-02-25.zip
} > /dev/null 2>&1

show_banner
download_file "https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip" "Installation de la configuration"
{
    unzip config.zip
    rm config.zip
} > /dev/null 2>&1