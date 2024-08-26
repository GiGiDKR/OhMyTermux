#!/bin/bash

# Fonction pour afficher la bannière sans gum
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

# Fonction pour afficher la bannière avec ou sans gum
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

# Installation de gum
show_banner
if ! command -v gum &> /dev/null; then
    echo -e "\e[38;5;33mInstallation de gum...\e[0m"
    pkg update -y > /dev/null 2>&1
    pkg install -y gum > /dev/null 2>&1
fi

username="$1"

# Liste des paquets nécessaires
pkgs=('git' 'virglrenderer-android' 'papirus-icon-theme' 'xfce4' 'xfce4-goodies' 'eza' 'pavucontrol-qt' 'bat' 'jq' 'nala' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly' 'eza')

# Installation des paquets nécessaires
for pkg in "${pkgs[@]}"; do
    show_banner
    if command -v gum &> /dev/null; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation de $pkg..." -- pkg install "$pkg" -y > /dev/null 2>&1
    else
        echo -e "\e[38;5;33mInstallation de $pkg...\e[0m"
        pkg install "$pkg" -y > /dev/null 2>&1
    fi
done

# Placer l'icône de Firefox sur le bureau
{
    cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop
    chmod +x $HOME/Desktop/firefox.desktop
} > /dev/null 2>&1

# Définir les alias
echo -e "\e[38;5;33m
# Aliases
alias l='eza --icons'
alias ls='eza -1 --icons'
alias ll='eza -lF -a --icons --total-size --no-permissions --no-time --no-user'
alias la='eza --icons -lgha --group-directories-first'
alias lt='eza --icons --tree'
alias lta='eza --icons --tree -lgha'
alias dir='eza -lF --icons'
alias ..='cd ..'
alias q='exit'
alias c='clear'
alias md='mkdir'
alias debian='proot-distro login debian --user $username --shared-tmp'
#alias zrun='proot-distro login debian --user $username --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform '
#alias zrunhud='proot-distro login debian --user $username --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform GALLIUM_HUD=fps '
alias hud='GALLIUM_HUD=fps '
alias cat='bat '
alias apt='nala '
alias install='nala install -y '
alias uninstall='nala remove -y '
alias update='nala update'
alias upgrade='nala upgrade -y'
alias search='nala search '
alias list='nala list --upgradeable'
alias show='nala show'
alias n='nano'
alias prop='nano $HOME/.termux/termux.properties'
alias tmx='cd $HOME/.termux'
alias cm='chmod +x'
alias clone='git clone'
alias push=\"git pull && git add . && git commit -m 'mobile push' && git push\"
alias bashconfig='nano $PREFIX/etc/bash.bashrc'
\e[0m" >> $PREFIX/etc/bash.bashrc

# Téléchargement fond d'écran 
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Téléchargement du fond d'écran" -- wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/mac_waves.png > /dev/null 2>&1
else
    echo -e "\e[38;5;33mTéléchargement du fond d'écran...\e[0m"
    wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/mac_waves.png > /dev/null 2>&1
fi
mv mac_waves.png $PREFIX/share/backgrounds/xfce/ > /dev/null 2>&1

# Installation du thème WhiteSur-Dark
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation du thème WhiteSur-Dark" -- wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-05-01.zip > /dev/null 2>&1
else
    echo -e "\e[38;5;33mInstallation du thème WhiteSur-Dark...\e[0m"
    wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-05-01.zip > /dev/null 2>&1
fi
{
    unzip 2024-05-01.zip
    tar -xf WhiteSur-gtk-theme-2024-05-01/release/WhiteSur-Dark.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    rm -rf WhiteSur*
    rm 2024-05-01.zip
} > /dev/null 2>&1

# Installation du thème d'icônes Fluent Cursor
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation du thème Fluent Cursor" -- wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1
else
    echo -e "\e[38;5;33mInstallation du thème Fluent Cursor...\e[0m"
    wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip > /dev/null 2>&1
fi
{
    unzip 2024-02-25.zip
    mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/
    mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/
    rm -rf $HOME/Fluent*
    rm 2024-02-25.zip
} > /dev/null 2>&1

# Installation des fichiers de configuration
show_banner
if command -v gum &> /dev/null; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title "Installation des fichiers de configuration" -- wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip > /dev/null 2>&1
else
    echo -e "\e[38;5;33mInstallation des fichiers de configuration...\e[0m"
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip > /dev/null 2>&1
fi
{
    unzip config.zip
    rm config.zip
} > /dev/null 2>&1