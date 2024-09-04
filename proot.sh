#!/bin/bash

USE_GUM=false

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
    if [ "$USE_GUM" = true ]; then
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

check_and_install_gum() {
    if [ "$USE_GUM" = true ] && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "\e[38;5;33mInstallation de gum...\e[0m"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if [ "$USE_GUM" = true ]; then
            gum style --foreground 196 "ERREUR: Installation de OhMyTermux impossible."
        else
            echo -e "\e[38;5;196mERREUR: Installation de OhMyTermux impossible.\e[0m"
        fi
        echo -e "\e[38;5;33mVeuillez vous référer au(x) message(s) d'erreur ci-dessus.\e[0m"
    fi
}

trap finish EXIT

if [ $# -eq 0 ]; then
    echo -e "\e[38;5;33mVeuillez saisir un nom d'utilisateur :\e[0m"
    read -r username
else
    username="$1"
fi

pkgs_proot=('sudo' 'wget' 'nala' 'jq')

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Debian proot" -- proot-distro install debian
else
    echo -e "\e[38;5;33mInstallation de Debian proot...\e[0m"
    proot-distro install debian > /dev/null 2>&1
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Recherche de mise à jour" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Mise à jour des paquets" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y
else
    echo -e "\e[38;5;33mRecherche de mise à jour...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update > /dev/null 2>&1
    echo -e "\e[38;5;33mMise à jour des paquets...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y > /dev/null 2>&1
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des paquets" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "${pkgs_proot[@]}" -y
else
    echo -e "\e[38;5;33mInstallation des paquets...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install "${pkgs_proot[@]}" -y > /dev/null 2>&1
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Création de l'utilisateur" -- bash -c '
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
    '
else
    echo -e "\e[38;5;33mCréation de l'utilisateur...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Ajout des droits utilisateur" -- bash -c '
        chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    '
else
    echo -e "\e[38;5;33mAjout des droits utilisateur...\e[0m"
    chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    echo "$username ALL=(ALL) NOPASSWD:ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
fi

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Configuration de la distribution" -- bash -c '
        echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
    '
else
    echo -e "\e[38;5;33mConfiguration de la distribution...\e[0m"
    echo "export DISPLAY=:1.0" >> "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
fi

is_package_installed() {
    dpkg -l | grep -qw "$1"
}

bashrc_path="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"

if is_package_installed "eza"; then
    cat << EOF >> "$bashrc_path"
alias l='eza --icons'
alias ls='eza -1 --icons'
alias ll='eza -lF -a --icons --total-size --no-permissions --no-time --no-user'
alias la='eza --icons -lgha --group-directories-first'
alias lt='eza --icons --tree'
alias lta='eza --icons --tree -lgha'
alias dir='eza -lF --icons'
EOF
fi

if is_package_installed "bat"; then
    echo "alias cat='bat'" >> "$bashrc_path"
fi

if is_package_installed "nala"; then
    cat << EOF >> "$bashrc_path"
alias install='nala install -y'
alias uninstall='nala remove -y'
alias update='nala update'
alias upgrade='nala upgrade -y'
alias search='nala search'
alias list='nala list --upgradeable'
alias show='nala show'
EOF
fi

cat << EOF >> "$bashrc_path"
alias zink='MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform '
alias hud='GALLIUM_HUD=fps '
alias ..='cd ..'
alias q='exit'
alias c='clear'
alias cat='bat '
alias start='echo please run from termux, not Debian proot.'
alias cm='chmod +x'
alias clone='git clone'
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
alias bashconfig='nano $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc'
EOF

timezone=$(getprop persist.sys.timezone)
{
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 rm /etc/localtime
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 cp /usr/share/zoneinfo/$timezone /etc/localtime
} > /dev/null 2>&1

cd "$PREFIX/share/icons"
find dist-dark | cpio -pdm "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons" > /dev/null 2>&1

cat << EOF > "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources"
Xcursor.theme: dist-dark
EOF

mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.fonts/"
mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.themes/"

show_banner
if [ "$USE_GUM" = true ]; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Mesa-Vulkan" -- proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb
else
    echo -e "\e[38;5;33mTéléchargement de Mesa-Vulkan...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget https://github.com/GiGiDKR/OhMyTermux/raw/main/mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
    echo -e "\e[38;5;33mInstallation de Mesa-Vulkan...\e[0m"
    proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb > /dev/null 2>&1
fi

echo '
get_proot_username() {
  basename "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"*
}
export username=$(get_proot_username)
' >> $PREFIX/etc/bash.bashrc

echo '
get_proot_username() {
  basename "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"*
}
export username=$(get_proot_username)
' >> $HOME/.zshrc

# TODO : Ajouter pour fish

source $PREFIX/etc/bash.bashrc
if [ -n "$ZSH_VERSION" ]; then
    source $PREFIX/etc/zshrc

# TODO : Ajouter pour Fish
# elif [ -n "$FISH_VERSION" ]; then

fi