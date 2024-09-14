#!/bin/bash

# Option pour utiliser gum (interface utilisateur améliorée)
USE_GUM=false

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true; shift ;;
        *) shift ;;
    esac
done

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

# Fonction pour afficher la bannière en mode bash
bash_banner() {
    clear
    echo -e "\e[38;5;33m
╔════════════════════════════════════════╗
║                                        ║
║              OHMYTERMUX                ║
║                                        ║
╚════════════════════════════════════════╝
\e[0m"
}

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
        bash_banner
    fi
}

# Fonction pour vérifier et installer gum si nécessaire
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        info_msg "Installation de gum..."
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

# Gestion d'erreur
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        error_msg "ERREUR: Installation de OhMyTermux impossible."
        info_msg "Veuillez vous référer au(x) message(s) d'erreur ci-dessus."
    fi
}

trap finish EXIT

# Demande du nom d'utilisateur et du mot de passe
if [ $# -eq 0 ]; then
    if $USE_GUM; then
        username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
        password=$(gum input --password --placeholder "Entrez votre mot de passe")
    else
        info_msg "Entrez votre nom d'utilisateur :"
        read -r username
        info_msg "Entrez votre mot de passe :"
        read -rs password
    fi
else
    username="$1"
    if $USE_GUM; then
        password=$(gum input --password --placeholder "Entrez votre mot de passe")
    else
        info_msg "Entrez votre mot de passe :"
        read -rs password
    fi
fi

# Liste des paquets à installer dans proot
pkgs_proot=('sudo' 'wget' 'nala' 'jq')

show_banner

# Installation de Debian proot
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Debian proot" -- proot-distro install debian
else
    info_msg "Installation de Debian proot..."
    proot-distro install debian > /dev/null 2>&1
fi

show_banner

# Mise à jour et configuration initiale de Debian
update_and_configure() {
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$1" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 $2
    else
        info_msg "$1"
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 $2 > /dev/null 2>&1
    fi
}

update_and_configure "Recherche de mise à jour" "apt update"
update_and_configure "Mise à jour des paquets" "apt upgrade -y"
update_and_configure "Désinstallation de xterm et sensible-utils" "apt remove xterm sensible-utils -y"

show_banner

# Installation des paquets dans proot
for pkg in "${pkgs_proot[@]}"; do
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y
    else
        info_msg "Installation de $pkg..."
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "$pkg" -y > /dev/null 2>&1
    fi
done

show_banner

# Création de l'utilisateur
create_user() {
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c "
        groupadd storage
        groupadd wheel
        useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
        echo '$username:$password' | chpasswd
    "
}

if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Création de l'utilisateur" -- create_user
else
    info_msg "Création de l'utilisateur..."
    create_user
fi

show_banner

# Ajout des droits utilisateur
add_user_rights() {
    chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    echo "$username ALL=(ALL) ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers" > /dev/null
    chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
}

if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Ajout des droits utilisateur" -- add_user_rights
else
    info_msg "Ajout des droits utilisateur..."
    add_user_rights
fi

show_banner

# Configuration de la distribution
configure_distro() {
    echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
}

if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Configuration de la distribution" -- configure_distro
else
    info_msg "Configuration de la distribution..."
    configure_distro
fi

# Ajout des alias et configurations supplémentaires
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

# Configuration du fuseau horaire
timezone=$(getprop persist.sys.timezone)
proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c "
    rm /etc/localtime
    cp /usr/share/zoneinfo/$timezone /etc/localtime
" > /dev/null 2>&1

# Configuration des icônes et du curseur
cd "$PREFIX/share/icons"
find dist-dark | cpio -pdm "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons" > /dev/null 2>&1

cat << EOF > "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources"
Xcursor.theme: dist-dark
EOF

mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.fonts/"
mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.themes/"

show_banner

# Installation de Mesa-Vulkan
install_mesa_vulkan() {
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
}

if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Mesa-Vulkan" -- install_mesa_vulkan
else
    info_msg "Installation de Mesa-Vulkan..."
    install_mesa_vulkan > /dev/null 2>&1
fi

info_msg "Installation terminée !"
