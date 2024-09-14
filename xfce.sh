#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

# Option pour utiliser gum (interface utilisateur améliorée)
USE_GUM=false

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true; shift ;;
        *) shift ;;
    esac
done

# Fonction pour afficher la bannière
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
        echo -e "\e[38;5;33m
╔════════════════════════════════════════╗
║                                        ║
║              OHMYTERMUX                ║
║                                        ║
╚════════════════════════════════════════╝
\e[0m"
    fi
}

# Fonction pour afficher un message d'erreur
error_msg() {
    if $USE_GUM; then
        gum style --foreground 196 "$1"
    else
        echo -e "\e[38;5;196m$1\e[0m"
    fi
}

# Fonction pour afficher un message d'information
info_msg() {
    if $USE_GUM; then
        gum style --foreground 33 "$1"
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Fonction pour installer un paquet
install_package() {
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $1" -- pkg install "$1" -y
    else
        show_banner
        info_msg "Installation de $1..."
        pkg install "$1" -y > /dev/null 2>&1
    fi
}

# Fonction pour télécharger un fichier
download_file() {
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de $1" -- wget "$2"
    else
        info_msg "Téléchargement de $1..."
        wget "$2" > /dev/null 2>&1
    fi
}

# Gestion des erreurs
trap 'error_msg "ERREUR: Installation de OhMyTermux impossible. Veuillez vous référer au(x) message(s) d'"'"'erreur ci-dessus."' ERR

# Affichage de la bannière
show_banner

# Installation de gum si nécessaire
if $USE_GUM && ! command -v gum &> /dev/null; then
    info_msg "Installation de gum..."
    pkg update -y && pkg install -y gum > /dev/null 2>&1
fi

# Liste des paquets à installer
pkgs=(
    'virglrenderer-android'
    'xfce4'
    'xfce4-goodies'
    'papirus-icon-theme'
    'pavucontrol-qt'
    'jq'
    'wmctrl'
    'firefox'
    'netcat-openbsd'
    'termux-x11-nightly'
)

# Installation des paquets
for pkg in "${pkgs[@]}"; do
    install_package "$pkg"
done

# Création du dossier Desktop et copie du raccourci Firefox
mkdir -p "$HOME/Desktop"
cp "$PREFIX/share/applications/firefox.desktop" "$HOME/Desktop"
chmod +x "$HOME/Desktop/firefox.desktop"

show_banner

# Téléchargement et installation du fond d'écran
download_file "fond d'écran" "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/waves.png"
mkdir -p "$PREFIX/share/backgrounds/xfce/"
mv waves.png "$PREFIX/share/backgrounds/xfce/"

show_banner

# Téléchargement et installation du thème WhiteSur-Dark
download_file "WhiteSur-Dark" "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.09.02.zip"
unzip 2024.09.02.zip
tar -xf WhiteSur-gtk-theme-2024.09.02/release/WhiteSur-Dark.tar.xz
mv WhiteSur-Dark/ "$PREFIX/share/themes/"
rm -rf WhiteSur* 2024.09.02.zip

show_banner

# Téléchargement et installation du curseur Fluent
download_file "Fluent Cursor" "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip"
unzip 2024-02-25.zip
mv Fluent-icon-theme-2024-02-25/cursors/dist "$PREFIX/share/icons/"
mv Fluent-icon-theme-2024-02-25/cursors/dist-dark "$PREFIX/share/icons/"
rm -rf "$HOME/Fluent"* 2024-02-25.zip

show_banner

# Téléchargement et installation de la configuration
download_file "configuration" "https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip"
unzip config.zip
rm config.zip
