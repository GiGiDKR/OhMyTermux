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
            echo -e "\e[38;5;196mERREUR: Installation de OhMyTermux impossible.\e[0m"
        fi
        echo -e "\e[38;5;33mVeuillez vous référer au(x) message(s) d'erreur ci-dessus.\e[0m"
    fi
}

trap finish EXIT

show_banner
if $USE_GUM && ! command -v gum &> /dev/null; then
    echo -e "\e[38;5;33mInstallation de gum...\e[0m"
    pkg update -y > /dev/null 2>&1
    pkg install -y gum > /dev/null 2>&1
fi

username="$1"

pkgs=('git' 'virglrenderer-android' 'papirus-icon-theme' 'xfce4' 'xfce4-goodies' 'eza' 'pavucontrol-qt' 'bat' 'jq' 'nala' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly' 'eza')

for pkg in "${pkgs[@]}"; do
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $pkg" -- pkg install "$pkg" -y
    else
        show_banner
        echo -e "\e[38;5;33mInstallation de $pkg...\e[0m"
        pkg install "$pkg" -y > /dev/null 2>&1
    fi
done

{
    mkdir -p $HOME/Desktop
    cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop
    chmod +x $HOME/Desktop/firefox.desktop
}

echo '

alias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"
alias ..="cd .."
alias q="exit"
alias c="clear"
alias md="mkdir"
alias s="source"
alias debian="proot-distro login debian --user $username --shared-tmp"
alias hud="GALLIUM_HUD=fps "
alias cat="bat"
alias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"
alias n="nano"
alias cm="chmod +x"
alias clone="git clone"
alias push="git pull && git add . && git commit -m '\''mobile push'\'' && git push"
alias bashconfig="nano $PREFIX/etc/bash.bashrc"

' >> $PREFIX/etc/bash.bashrc

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement du fond d'écran" -- wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/mac_waves.png
else
    echo -e "\e[38;5;33mTéléchargement du fond d'écran...\e[0m"
    wget https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/mac_waves.png > /dev/null 2>&1
fi
mv mac_waves.png $PREFIX/share/backgrounds/xfce/ > /dev/null 2>&1

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation du thème WhiteSur-Dark" -- wget https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-05-01.zip
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

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation du thème Fluent Cursor" -- wget https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip
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

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des fichiers de configuration" -- wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip
else
    echo -e "\e[38;5;33mInstallation des fichiers de configuration...\e[0m"
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/files/config.zip > /dev/null 2>&1
fi
{
    unzip config.zip
    rm config.zip
} > /dev/null 2>&1