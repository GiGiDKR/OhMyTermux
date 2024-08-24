#!/bin/bash

# Fonction pour afficher la bannière sans gum
bash_banner() {
	clear
	COLOR="\e[38;5;212m"

	TOP_BORDER="╔════════════════════════════════════════╗"
	BOTTOM_BORDER="╚════════════════════════════════════════╝"
	EMPTY_LINE="║                                        ║"
	TEXT_LINE="║              OHMYTERMUX                ║"
	SUBTEXT_LINE="║                 XFCE                   ║"

	echo
	echo -e "${COLOR}${TOP_BORDER}"
	echo -e "${COLOR}${EMPTY_LINE}"
	echo -e "${COLOR}${TEXT_LINE}"
	echo -e "${COLOR}${SUBTEXT_LINE}"
	echo -e "${COLOR}${EMPTY_LINE}"
	echo -e "${COLOR}${BOTTOM_BORDER}\e[0m"
	echo
}

bash_banner

echo "Changer le répertoire de sources ? (o/n)"
read change_repo_choice
if [ "$change_repo_choice" = "o" ]; then
    termux-change-repo
fi

# Variable pour déterminer si gum doit être utilisé
USE_GUM=false

# Vérification des arguments
for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
    esac
done

# Fonction pour vérifier et installer gum
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
		   bash_banner
        echo "Installation de gum..."
        pkg update -y && pkg install gum -y
    fi
}

# Fonction pour afficher la bannière avec ou sans gum
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --border double \
            --align center \
            --width 40 \
            --margin "1 1 1 0" \
            "OHMYTERMUX" \
            "XFCE"
    else
       bash_banner
    fi
}

# Fonction de fin pour gérer les erreurs
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERREUR: Installation de XFCE dans Termux impossible."
        else
            echo "ERREUR: Installation de XFCE dans Termux impossible."
        fi
        echo "Veuillez vous référer au(x) message(s) d'erreur ci-dessus."
    fi
}

trap finish EXIT

check_and_install_gum
show_banner

# Configuration du répértoire $HOME/.termux
termux_dir="$HOME/.termux"
file_path="$termux_dir/colors.properties"
if [ ! -f "$file_path" ]; then
    mkdir -p "$termux_dir"
    cat <<EOL > "$file_path"
## Name: TokyoNight
# Special
foreground = #c0caf5
background = #1a1b26
cursor = #c0caf5
# Black/Grey
color0 = #15161e
color8 = #414868
# Red
color1 = #f7768e
color9 = #f7768e
# Green
color2 = #9ece6a
color10 = #9ece6a
# Yellow
color3 = #e0af68
color11 = #e0af68
# Blue
color4 = #7aa2f7
color12 = #7aa2f7
# Magenta
color5 = #bb9af7
color13 = #bb9af7
# Cyan
color6 = #7dcfff
color14 = #7dcfff
# White/Grey
color7 = #a9b1d6
color15 = #c0caf5
# Other
color16 = #ff9e64
color17 = #db4b4b
EOL
fi

if $USE_GUM; then
    gum spin --title "Téléchargement police par défaut..." -- curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf
else
    echo "Téléchargement police par défaut..."
    curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf
fi

file_path="$termux_dir/termux.properties"

if [ ! -f "$file_path" ]; then
    cat <<EOL > "$file_path"
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL
else
    sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$file_path"
    sed -i 's/^# use-black-ui = true/use-black-ui = true/' "$file_path"
    sed -i 's/^# bell-character = ignore/bell-character = ignore/' "$file_path"
    sed -i 's/^# fullscreen = true/fullscreen = true/' "$file_path"
fi

# Suppression du fichier motd après sauvegarde
MOTD_PATH="/data/data/com.termux/files/usr/etc/motd"
MOTD_BACKUP_PATH="/data/data/com.termux/files/usr/etc/motd.bak"
if [ -f "$MOTD_PATH" ]; then
    mv "$MOTD_PATH" "$MOTD_BACKUP_PATH"
else
    echo "Le fichier motd n'existe pas !"
fi

termux-reload-settings

# Accès au stockage externe
show_banner
if $USE_GUM; then
    gum confirm "Autoriser l'accès au stockage ?" && termux-setup-storage
else
    echo "Autoriser l'accès au stockage ? (o/n)"
    read choice
    [ "$choice" = "o" ] && termux-setup-storage
fi

# Menu de choix du shell
show_banner
if $USE_GUM; then
    shell_choice=$(gum choose --height=5 --header="Choisissez le shell à installer :" "bash" "zsh" "fish")
else
    echo "Choisissez le shell à installer :"
    echo "1) bash"
    echo "2) zsh"
    echo "3) fish"
    read -p "Entrez le numéro de votre choix : " choice
    case $choice in
        1) shell_choice="bash" ;;
        2) shell_choice="zsh" ;;
        3) shell_choice="fish" ;;
        *) shell_choice="bash" ;;
    esac
fi

case $shell_choice in
    "bash")
        echo "Bash sélectionné, poursuite du script..."
        ;;
    "zsh")
        if $USE_GUM; then
            gum spin --title "Installation de ZSH..." -- pkg install -y zsh
        else
            echo "Installation de ZSH..."
            pkg install -y zsh
        fi
        show_banner
        if $USE_GUM; then
            gum confirm "Voulez-vous installer Oh My Zsh ?" && {
                gum spin --title "Installation des prérequis..." -- pkg install -y wget curl git unzip
                gum spin --title "Installation de Oh My Zsh..." -- git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
            }
        else
            echo "Voulez-vous installer Oh My Zsh ? (o/n)"
            read choice
            if [ "$choice" = "o" ]; then
                echo "Installation des prérequis..."
                pkg install -y wget curl git unzip
                echo "Installation de Oh My Zsh..."
                git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
            fi
        fi

        show_banner
        if $USE_GUM; then
            gum confirm "Voulez-vous installer PowerLevel10k ?" && {
                gum spin --title "Installation de PowerLevel10k..." -- git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || true
                echo 'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME/.zshrc"

                show_banner
                if gum confirm "  Installer le prompt OhMyTermux ?"; then
                    gum spin --title "Téléchargement prompt PowerLevel10k..." -- curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                else
                    echo "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                fi
            }
        else
            echo "Voulez-vous installer PowerLevel10k ? (o/n)"
            read choice
            if [ "$choice" = "o" ]; then
                echo "Installation de PowerLevel10k..."
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || true
                echo 'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME/.zshrc"

                echo "Installer le prompt OhMyTermux ? (o/n)"
                read choice
                if [ "$choice" = "o" ]; then
                    echo "Téléchargement du prompt PowerLevel10k..."
                    curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                else
                    echo "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                fi
            fi
        fi

show_banner

# Fonction de sélection des plugins
select_plugins() {
    if $USE_GUM; then
        PLUGINS=$(gum choose --no-limit --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer")
    else
        echo "Sélectionner les plugins à installer (séparés par des espaces) :"
        echo "1) zsh-autosuggestions"
        echo "2) zsh-syntax-highlighting"
        echo "3) zsh-completions"
        echo "4) you-should-use"
        echo "5) zsh-abbr"
        echo "6) zsh-alias-finder"
        echo "7) Tout installer"
        read -p "Entrez les numéros des plugins : " plugin_choices
        # Convertir les choix en noms de plugins
        PLUGINS=""
        for choice in $plugin_choices; do
            case $choice in
                1) PLUGINS+="zsh-autosuggestions " ;;
                2) PLUGINS+="zsh-syntax-highlighting " ;;
                3) PLUGINS+="zsh-completions " ;;
                4) PLUGINS+="you-should-use " ;;
                5) PLUGINS+="zsh-abbr " ;;
                6) PLUGINS+="zsh-alias-finder " ;;
                7) PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder" ;;
            esac
        done
    fi
}

# Appel de la fonction pour sélectionner les plugins
select_plugins

# Vérification des plugins sélectionnés
if [[ "$PLUGINS" == *"Tout installer"* ]]; then
  PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder"
fi

# Installation des plugins
for PLUGIN in $PLUGINS; do
  if $USE_GUM; then
    gum spin --title "Installation de $PLUGIN..." -- sleep 2
  else
    echo "Installation de $PLUGIN..."
    sleep 2
  fi

  case $PLUGIN in
    "zsh-autosuggestions")
      git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" >/dev/null 2>&1 || true
      ;;
    "zsh-syntax-highlighting")
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" >/dev/null 2>&1 || true
      ;;
    "zsh-completions")
      git clone https://github.com/zsh-users/zsh-completions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" >/dev/null 2>&1 || true
      ;;
    "you-should-use")
      git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$HOME/.oh-my-zsh/custom/plugins/you-should-use" >/dev/null 2>&1 || true
      ;;
    "zsh-abbr")
      git clone https://github.com/olets/zsh-abbr "$HOME/.oh-my-zsh/custom/plugins/zsh-abbr" >/dev/null 2>&1 || true
      ;;
    "zsh-alias-finder")
      git clone https://github.com/akash329d/zsh-alias-finder "$HOME/.oh-my-zsh/custom/plugins/zsh-alias-finder" >/dev/null 2>&1 || true
      ;;
  esac
done

# Télécharger les fichiers de configuration depuis GitHub
        show_banner
        if $USE_GUM; then
            gum spin --title "Téléchargement des fichiers de conf..." -- curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh
            gum spin --title "Téléchargement du fichier zshrc..." -- curl -fLo "$HOME/.zshrc" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/zshrc
        else
            echo "Téléchargement des fichiers de conf..."
            curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh
            echo "Téléchargement du fichier zshrc..."
            curl -fLo "$HOME/.zshrc" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/zshrc
        fi

        echo "alias help='glow \$HOME/.config/OhMyTermux/Help.md'" >> "$HOME/.zshrc"
        chsh -s zsh
        ;;
    "fish")
        if $USE_GUM; then
            gum spin --title "Installation de Fish..." -- pkg install -y fish
        else
            echo "Installation de Fish..."
            pkg install -y fish
        fi
        # TODO : ajouter la configuration de Fish, de ses plugins et des alias (abbr)
        chsh -s fish
        ;;
esac

# Installation de thèmes
show_banner
if $USE_GUM; then
    if gum confirm "Installer des thèmes pour Termux ?"; then
        # Définir et créer les répertoires
        CONFIG=$HOME/.config
        COLORS_DIR_TERMUXSTYLE=$HOME/.termux/colors/termuxstyle
        COLORS_DIR_TERMUX=$HOME/.termux/colors/termux
        COLORS_DIR_XFCE4TERMINAL=$HOME/.termux/colors/xfce4terminal

        mkdir -p $CONFIG $COLORS_DIR_TERMUXSTYLE $COLORS_DIR_TERMUX $COLORS_DIR_XFCE4TERMINAL

        gum spin --title "Installation des thèmes" -- bash -c '
            curl -L -o $HOME/.termux/colors.zip https://github.com/GiGiDKR/OhMyTermux/raw/main/files/colors.zip &&
            unzip -o "$HOME/.termux/colors.zip" -d "$HOME/.termux/"
        '
    fi
else
    echo "Installer des thèmes pour Termux ? (o/n)"
    read choice
    if [ "$choice" = "o" ]; then
        # Définir et créer les répertoires
        CONFIG=$HOME/.config
        COLORS_DIR_TERMUXSTYLE=$HOME/.termux/colors/termuxstyle
        COLORS_DIR_TERMUX=$HOME/.termux/colors/termux
        COLORS_DIR_XFCE4TERMINAL=$HOME/.termux/colors/xfce4terminal

        mkdir -p $CONFIG $COLORS_DIR_TERMUXSTYLE $COLORS_DIR_TERMUX $COLORS_DIR_XFCE4TERMINAL

        echo "Installation des thèmes..."
        curl -L -o $HOME/.termux/colors.zip https://github.com/GiGiDKR/OhMyTermux/raw/main/files/colors.zip
        unzip -o "$HOME/.termux/colors.zip" -d "$HOME/.termux/"
    fi
fi

rm "$HOME/.termux/colors.zip"

# Fonction pour installer les polices
install_font() {
    local font_url="$1"
    curl -L -o "$HOME/.termux/font.ttf" "$font_url" >/dev/null 2>&1
}

show_banner

# Menu de séléction de police
if $USE_GUM; then
    FONT=$(gum choose --height=14 --header="Sélectionner la police à installer :" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
else
    echo "Sélectionner la police à installer :"
    echo "1) Police par défaut"
    echo "2) CaskaydiaCove Nerd Font"
    echo "3) FiraMono Nerd Font"
    echo "4) JetBrainsMono Nerd Font"
    echo "5) Mononoki Nerd Font"
    echo "6) VictorMono Nerd Font"
    echo "7) RobotoMono Nerd Font"
    echo "8) DejaVuSansMono Nerd Font"
    echo "9) UbuntuMono Nerd Font"
    echo "10) AnonymousPro Nerd Font"
    echo "11) Terminus Nerd Font"
    read -p "Entrez le numéro de votre choix : " font_choice
    case $font_choice in
        1) FONT="Police par défaut" ;;
        2) FONT="CaskaydiaCove Nerd Font" ;;
        3) FONT="FiraMono Nerd Font" ;;
        4) FONT="JetBrainsMono Nerd Font" ;;
        5) FONT="Mononoki Nerd Font" ;;
        6) FONT="VictorMono Nerd Font" ;;
        7) FONT="RobotoMono Nerd Font" ;;
        8) FONT="DejaVuSansMono Nerd Font" ;;
        9) FONT="UbuntuMono Nerd Font" ;;
        10) FONT="AnonymousPro Nerd Font" ;;
        11) FONT="Terminus Nerd Font" ;;
        *) echo "Choix invalide"; exit 1 ;;
    esac
fi

echo "Installation de la police sélectionnée..."
case $FONT in
    "CaskaydiaCove Nerd Font")
        install_font "https://github.com/mayTermux/myTermux/raw/main/.fonts/CaskaydiaCoveNerdFont-Regular.ttf"
        ;;
    "FiraMono Nerd Font")
        install_font "https://github.com/mayTermux/myTermux/raw/main/.fonts/FiraMono-Regular.ttf"
        ;;
    "JetBrainsMono Nerd Font")
        install_font "https://github.com/mayTermux/myTermux/raw/main/.fonts/JetBrainsMono-Regular.ttf"
        ;;
    "Mononoki Nerd Font")
        install_font "https://github.com/mayTermux/myTermux/raw/main/.fonts/Mononoki-Regular.ttf"
        ;;
    "VictorMono Nerd Font")
        install_font "https://github.com/mayTermux/myTermux/raw/main/.fonts/VictorMono-Regular.ttf"
        ;;
    "RobotoMono Nerd Font")
        install_font "https://github.com/adi1090x/termux-style/raw/master/fonts/RobotoMonoNerdFont.ttf"
        ;;
    "DejaVuSansMono Nerd Font")
        install_font "https://github.com/adi1090x/termux-style/raw/master/fonts/DejaVuSansMonoNerdFont.ttf"
        ;;
    "UbuntuMono Nerd Font")
        install_font "https://github.com/adi1090x/termux-style/raw/master/fonts/UbuntuMonoNerdFont.ttf"
        ;;
    "AnonymousPro Nerd Font")
        install_font "https://github.com/adi1090x/termux-style/raw/master/fonts/AnonymousProNerdFont.ttf"
        ;;
    "Terminus Nerd Font")
        install_font "https://github.com/adi1090x/termux-style/raw/master/fonts/TerminusNerdFont.ttf"
        ;;
    "Police par défaut")
        echo "Police déjà installée."
        ;;
    *)
        echo "Police non reconnue : $FONT"
        ;;
esac

# Menu de séléction des packages
show_banner
if $USE_GUM; then
    PACKAGES=$(gum choose --no-limit --height=13 --header="Sélectionner avec espace les packages à installer :" "nala" "eza" "bat" "lf" "fzf" "glow" "python" "lsd" "micro" "tsu" "Tout installer")
else
    echo "Sélectionner les packages à installer (séparés par des espaces) :"
    echo "1) nala"
    echo "2) eza"
    echo "3) bat"
    echo "4) lf"
    echo "5) fzf"
    echo "6) glow"
    echo "7) python"
    echo "8) lsd"
    echo "9) micro"
    echo "10) tsu"
    echo "11) Tout installer"
    read -p "Entrez les numéros des packages : " package_choices
    PACKAGES=""
    for choice in $package_choices; do
        case $choice in
            1) PACKAGES+="nala " ;;
            2) PACKAGES+="eza " ;;
            3) PACKAGES+="bat " ;;
            4) PACKAGES+="lf " ;;
            5) PACKAGES+="fzf " ;;
            6) PACKAGES+="glow " ;;
            7) PACKAGES+="python " ;;
            8) PACKAGES+="lsd " ;;
            9) PACKAGES+="micro " ;;
            10) PACKAGES+="tsu " ;;
            11) PACKAGES="nala eza bat lf fzf glow python lsd micro tsu" ;;
        esac
    done
fi

installed_packages=""

show_banner 

if [ -n "$PACKAGES" ]; then
    for PACKAGE in $PACKAGES; do
        if $USE_GUM; then
            gum spin --title "Installation de $PACKAGE..." -- pkg install -y $PACKAGE
        else
            echo "Installation de $PACKAGE..."
            pkg install -y $PACKAGE
        fi
        installed_packages+="Installé : $PACKAGE\n"
        show_banner 
        echo -e "$installed_packages"
    done
else
    echo "Aucun package sélectionné. Poursuite du script ..."
fi

# Installation de OhMyTermuxXFCE
show_banner
if $USE_GUM; then
    if gum confirm "    Installer OhMyTermux XFCE ?"; then
        # Demande du nom d'utilisateur avec gum
        username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
    else
        show_banner
        if gum confirm "      Exécuter OhMyTermux ?"; then
            termux-reload-settings
            clear
            exec $shell_choice
        else
            termux-reload-settings
            echo "OhMyTermux sera actif au prochain démarrage de Termux."
        fi
        exit 0
    fi
else
    echo "    Installer OhMyTermux XFCE ? (o/n)"
    read choice
    if [ "$choice" = "o" ]; then
        # Demande du nom d'utilisateur avec read
        read -p "Entrez votre nom d'utilisateur : " username
    else
        show_banner
        echo "      Exécuter OhMyTermux ? (o/n)"
        read choice
        if [ "$choice" = "o" ]; then
            termux-reload-settings
            clear
            exec $shell_choice
        else
            termux-reload-settings
            echo "OhMyTermux sera actif au prochain démarrage de Termux."
        fi
        exit 0
    fi
fi

show_banner
pkgs=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')

show_banner
if $USE_GUM; then
    gum spin --title "Installation des pré-requis" -- pkg install ncurses-ui-libs && pkg uninstall dbus -y
else
    echo "Installation des pré-requis..."
    pkg install ncurses-ui-libs && pkg uninstall dbus -y
fi

show_banner
if $USE_GUM; then
    gum spin --title "Mise à jour des paquets" -- pkg update -y
else
    echo "Mise à jour des paquets..."
    pkg update -y
fi

show_banner
if $USE_GUM; then
    gum spin --title "Installation des paquets nécessaires" -- pkg install "${pkgs[@]}" -y
else
    echo "Installation des paquets nécessaires..."
    pkg install "${pkgs[@]}" -y
fi

# Téléchargement et éxecution des scripts
show_banner
if $USE_GUM; then
    gum spin --title "Téléchargement des scripts" -- bash -c "
        wget https://github.com/GiGiDKR/OhMyTermux/raw/main/xfce.sh &&
        wget https://github.com/GiGiDKR/OhMyTermux/raw/main/proot.sh &&
        wget https://github.com/GiGiDKR/OhMyTermux/raw/main/utils.sh
    "
else
    echo "Téléchargement des scripts..."
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/xfce.sh
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/proot.sh
    wget https://github.com/GiGiDKR/OhMyTermux/raw/main/utils.sh
fi
chmod +x *.sh

show_banner
if $USE_GUM; then
    ./xfce.sh "$username" --gum
    ./proot.sh "$username" --gum
else
    ./xfce.sh "$username"
    ./proot.sh "$username"
fi
./utils.sh

# Installation de Termux-X11
show_banner
if $USE_GUM; then
    if gum confirm "    Installer Termux-X11 ?"; then
        show_banner
        gum spin --title "Téléchargement de Termux-X11 APK" -- wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
        mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
        termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk
        rm $HOME/storage/downloads/app-arm64-v8a-debug.apk
    fi
else
    echo "    Installer Termux-X11 ? (o/n)"
    read choice
    if [ "$choice" = "o" ]; then
        show_banner
        echo "Téléchargement de Termux-X11 APK..."
        wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
        mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
        termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk
        rm $HOME/storage/downloads/app-arm64-v8a-debug.apk
    fi
fi

# Finalisation de la configuration
source $PREFIX/etc/bash.bashrc
termux-reload-settings

rm xfce.sh
rm proot.sh
rm utils.sh
rm install.sh

# Installer OhMyTermuxScript
install_oh_my_termux_script() {
  pkg update -y && pkg install git -y
  git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript"
  chmod +x "$HOME/OhMyTermuxScript"/*.sh
}

if $USE_GUM; then
  if gum confirm ". Installer OhMyTermuxScript ?"; then
    gum spin --title "Installation de OhMyTermuxScript..." -- install_oh_my_termux_script >/dev/null 2>&1
  fi
else
  echo ". Installer OhMyTermuxScript ? (o/n)"
  read choice
  if [ "$choice" = "o" ]; then
    echo "Installation de OhMyTermuxScript..."
    install_oh_my_termux_script >/dev/null 2>&1
  fi
fi

# Message final
show_banner
if $USE_GUM; then
    if gum confirm "      Exécuter OhMyTermux ?"; then
        clear
        exec $shell_choice
    else
        echo "OhMyTermux sera actif au prochain démarrage de Termux."
    fi
else
    echo "      Exécuter OhMyTermux ? (o/n)"
    read choice
    if [ "$choice" = "o" ]; then
        clear
        exec $shell_choice
    else
        echo "OhMyTermux sera actif au prochain démarrage de Termux."
    fi
fi
