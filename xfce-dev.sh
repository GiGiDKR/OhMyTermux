#!/bin/bash

USE_GUM=false
VERBOSE=false
BROWSER="firefox"

#------------------------------------------------------------------------------
# COULEURS
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Succès
COLOR_GOLD='\033[38;5;220m'   # Avertissement
COLOR_RED='\033[38;5;196m'    # Erreur
COLOR_RESET='\033[0m'         # Réinitialisation

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# AFFICHAGE DE L'AIDE
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "Aide OhMyTermux"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v Afficher les sorties détaillées"
    echo "  --help | -h    Afficher ce message d'aide"
    echo "  --browser=    Choisir le navigateur (firefox ou chromium)"
}

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
#------------------------------------------------------------------------------
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
        --help|-h)
            show_help
            exit 0
            ;;
        --browser=*)
            BROWSER="${arg#*=}"
            shift
            ;;
        *)
            break
            ;;
    esac
done

#------------------------------------------------------------------------------
# AFFICHAGE DE LA BANNIERE EN MODE TEXTE
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# AFFICHAGE DE LA BANNIERE EN MODE GRAPHIQUE
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# GESTION DES ERREURS
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# MESSAGES D'INFORMATION
#------------------------------------------------------------------------------
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE SUCCÈS
#------------------------------------------------------------------------------
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES D'ERREUR
#------------------------------------------------------------------------------
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE TITRE
#------------------------------------------------------------------------------
title_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 220 --bold
    else
        echo -e "\n${COLOR_GOLD}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# JOURNALISATION DES ERREURS
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >>  "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# EXECUTION D'UNE COMMANDE ET AFFICHAGE DYNAMIQUE DU RÉSULTAT
#------------------------------------------------------------------------------
execute_command() {
    local command="$1"
    local info_msg="$2"
    local success_msg="✓ $info_msg"
    local error_msg="✗ $info_msg"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$info_msg" -- bash -c "$command $redirect"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            log_error "$command"
            return 1
        fi
    else
        info_msg "$info_msg"
        if eval "$command $redirect"; then
            success_msg "$success_msg"
        else
            error_msg "$error_msg"
            log_error "$command"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION D'UN PAQUET
#------------------------------------------------------------------------------
#install_package() {
#    local pkg=$1
#    execute_command "pkg install $pkg -y" "Installation de $pkg"
#}

#------------------------------------------------------------------------------
# TÉLÉCHARGEMENT D'UN FICHIER
#------------------------------------------------------------------------------
download_file() {
    local url=$1
    local message=$2
    execute_command "wget $url" "$message"
}

trap finish EXIT

# Fonction pour configurer XFCE selon le type d'installation
configure_xfce() {
    local config_dir="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    local install_type="$1"

    # Créer le répertoire de configuration si nécessaire
    mkdir -p "$config_dir"

    case "$install_type" in
        "complète")
            # Configuration complète avec tous les éléments
            cat > "$config_dir/xsettings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur-dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="dist-dark"/>
    <property name="CursorThemeSize" type="int" value="32"/>
  </property>
</channel>
EOF

            cat > "$config_dir/xfwm4.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
  </property>
</channel>
EOF
            ;;
            
        "minimale"|"personnalisée")
            # Configuration de base
            local theme_value="Default"
            local icon_value="Adwaita"
            local cursor_value="default"
            local wallpaper="/data/data/com.termux/files/usr/share/backgrounds/xfce/xfce-stripes.png"

            # Ajuster selon les choix personnalisés
            [ "$install_theme" = true ] && theme_value="WhiteSur-Dark"
            [ "$install_icons" = true ] && icon_value="WhiteSur-dark"
            [ "$install_cursors" = true ] && cursor_value="dist-dark"
            [ "$install_wallpapers" = true ] && wallpaper="/data/data/com.termux/files/usr/share/backgrounds/whitesur/Monterey.jpg"

            # Générer xsettings.xml
            cat > "$config_dir/xsettings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="$theme_value"/>
    <property name="IconThemeName" type="string" value="$icon_value"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="$cursor_value"/>
    <property name="CursorThemeSize" type="int" value="32"/>
  </property>
</channel>
EOF

            # Générer xfwm4.xml
            cat > "$config_dir/xfwm4.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$theme_value"/>
  </property>
</channel>
EOF

            # Générer xfce4-desktop.xml
            cat > "$config_dir/xfce4-desktop.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="$wallpaper"/>
        </property>
      </property>
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="$wallpaper"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
            ;;
    esac

    # Appliquer les permissions
    chmod 644 "$config_dir"/*.xml
}

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
main() {
    # Installation de gum si nécessaire
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo -e "${COLOR_BLUE}Installation de gum${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi

    title_msg "❯ Installation de XFCE"

    execute_command "pkg update -y && pkg upgrade -y" "Mise à jour des paquets"

    # Installation des packages
    pkgs=(
        'virglrenderer-android'
        'xfce4'
        'xfce4-goodies'
        'pavucontrol-qt'
        'jq'
        'wmctrl'
        'netcat-openbsd'
        'termux-x11-nightly'
    )

    # Ajouter le navigateur choisi
    if [ "$BROWSER" = "firefox" ]; then
        pkgs+=('firefox')
    elif [ "$BROWSER" = "chromium" ]; then
        pkgs+=('chromium')
    elif [ "$BROWSER" = "aucun" ]; then
        info_msg "  Aucun navigateur web installé."
    else
        info_msg "  Navigateur inconnu. Installation de Firefox."
        pkgs+=('firefox')
    fi

    for pkg in "${pkgs[@]}"; do
        execute_command "pkg install $pkg -y" "Installation de $pkg"
    done

    # Configuration du bureau
    if [ "$BROWSER" = "firefox" ]; then
        execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop && chmod +x $HOME/Desktop/firefox.desktop" "Configuration du bureau"
    elif [ "$BROWSER" = "chromium" ]; then
        execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/chromium.desktop $HOME/Desktop && chmod +x $HOME/Desktop/chromium.desktop" "Configuration du bureau"
    fi

    # Téléchargement et installation des fonds d'écran WhiteSur
    download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Téléchargement des fonds d'écran WhiteSur"
    execute_command "unzip main.zip && \
                    mkdir -p $PREFIX/share/backgrounds/whitesur && \
                    cp -r WhiteSur-wallpapers-main/4k/* $PREFIX/share/backgrounds/whitesur/ && \
                    rm -rf WhiteSur-wallpapers-main main.zip" "Installation des fonds d'écran"

    # Téléchargement du thème
    download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Téléchargement du thème WhiteSur"
    execute_command "unzip 2024-11-18.zip && \
                    tar -xf WhiteSur-gtk-theme-2024-11-18/release/WhiteSur-Dark.tar.xz && \
                    mv WhiteSur-Dark/ $PREFIX/share/themes/ && \
                    rm -rf WhiteSur* && \
                    rm 2024-11-18.zip*" "Installation du thème"

    # Téléchargement et installation du thème d'icônes WhiteSur
    download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes WhiteSur"
    execute_command "unzip master.zip && \
                    cd WhiteSur-icon-theme-master && \
                    mkdir -p $PREFIX/share/icons && \
                    ./install.sh --dest $PREFIX/share/icons --name WhiteSur && \
                    cd .. && \
                    rm -rf WhiteSur-icon-theme-master master.zip" "Installation des icônes"

    # Téléchargement des curseurs
    download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement des curseurs Fluent"
    execute_command "unzip 2024-02-25.zip && \
                    mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && \
                    mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && \
                    rm -rf $HOME/Fluent* && \
                    rm 2024-02-25.zip*" "Installation des curseurs"

    # Téléchargement de la pré-configuration
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/config.zip" "Téléchargement de la configuration XFCE"
    execute_command "unzip -o config.zip && \
                    rm config.zip" "Installation de la configuration"

    # Configuration de XFCE selon le type d'installation
    case "$INSTALL_TYPE" in
        "complète")
            configure_xfce "complète"
            ;;
        "minimale")
            configure_xfce "minimale"
            ;;
        "personnalisée")
            configure_xfce "personnalisée"
            ;;
    esac
}

main "$@"