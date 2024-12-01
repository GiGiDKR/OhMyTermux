#!/bin/bash

USE_GUM=false
VERBOSE=false
BROWSER="chromium"

#------------------------------------------------------------------------------
# COULEURS D'AFFICHAGE
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
    REDIRECT=">/dev/null 2>&1"
else
    REDIRECT=""
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
    echo "  --gum | -g        Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v    Afficher les sorties détaillées"
    echo "  --browser | -b    Choisir le navigateur (Chromium ou Firefox)"
    echo "  --version | -ver  Choisir le type d'installation (complète, minimale, personnalisée)"
    echo "  --help | -h       Afficher ce message d'aide"
}

#------------------------------------------------------------------------------
# VARIABLES GLOBALES POUR L'INSTALLATION PERSONNALISÉE
#------------------------------------------------------------------------------
INSTALL_THEME=false
INSTALL_ICONS=false
INSTALL_WALLPAPERS=false
INSTALL_CURSORS=false
INSTALL_TYPE=""

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
#------------------------------------------------------------------------------
for ARG in "$@"; do
    case $ARG in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            REDIRECT=""
            shift
            ;;
        --browser|-b)
            BROWSER="${2}"
            shift 2
            ;;
        --version=*)
            INSTALL_TYPE="${ARG#*=}"
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

#------------------------------------------------------------------------------
# CONFIRMATION GUM
#------------------------------------------------------------------------------
gum_confirm() {
    local PROMPT="$1"
    if $FULL_INSTALL; then
        return 0 
    else
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$PROMPT"
    fi
}

#------------------------------------------------------------------------------
# SÉLECTION GUM UNIQUE
#------------------------------------------------------------------------------
gum_choose() {
    local PROMPT="$1"
    shift
    local SELECTED=""
    local OPTIONS=()
    local HEIGHT=10

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                SELECTED="${1#*=}"
                ;;
            --height=*)
                HEIGHT="${1#*=}"
                ;;
            *)
                OPTIONS+=("$1")
                ;;
        esac
        shift
    done

    if $FULL_INSTALL; then
        if [ -n "$SELECTED" ]; then
            echo "$SELECTED"
        else
            # Retourner la première option par défaut
            echo "${OPTIONS[0]}"
        fi
    else
        gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
}

#------------------------------------------------------------------------------
# SÉLECTION GUM MULTIPLE
#------------------------------------------------------------------------------
gum_choose_multi() {
    local PROMPT="$1"
    shift
    local SELECTED=""
    local OPTIONS=()
    local HEIGHT=10

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                SELECTED="${1#*=}"
                ;;
            --height=*)
                HEIGHT="${1#*=}"
                ;;
            *)
                OPTIONS+=("$1")
                ;;
        esac
        shift
    done

    if $FULL_INSTALL; then
        if [ -n "$SELECTED" ]; then
            echo "$SELECTED"
        else
            echo "${OPTIONS[@]}"
        fi
    else
        gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
}

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
            --width 42 \
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
    local RET=$?
    if [ ${RET} -ne 0 ] && [ ${RET} -ne 130 ]; then
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
        echo -e "\n${COLOR_GOLD}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# MESSAGES DE SOUS-TITRE
#------------------------------------------------------------------------------
subtitle_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33 --bold
    else
        echo -e "\n${COLOR_BLUE}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# JOURNALISATION DES ERREURS
#------------------------------------------------------------------------------
log_error() {
    local ERROR_MSG="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $ERROR_MSG" >>  "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
#------------------------------------------------------------------------------
execute_command() {
    local COMMAND="$1"
    local INFO_MSG="$2"
    local SUCCESS_MSG="✓ $INFO_MSG"
    local ERROR_MSG="✗ $INFO_MSG"

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            success_msg "$SUCCESS_MSG"
        else
            error_msg "$ERROR_MSG"
            log_error "$COMMAND"
            return 1
        fi
    else
        info_msg "$INFO_MSG"
        if eval "$COMMAND $REDIRECT"; then
            success_msg "$SUCCESS_MSG"
        else
            error_msg "$ERROR_MSG"
            log_error "$COMMAND"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# TÉLÉCHARGEMENT DE FICHIER
#------------------------------------------------------------------------------
download_file() {
    local URL="$1"
    local MESSAGE="$2"
    execute_command "wget $URL" "$MESSAGE"
}

trap finish EXIT

# Fonction pour configurer XFCE selon le type d'installation
configure_xfce() {
    local CONFIG_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    local INSTALL_TYPE="$1"

    # Créer le répertoire de configuration si nécessaire
    mkdir -p "$CONFIG_DIR"

    # Configurer xfce4-panel.xml si whiskermenu n'est pas installé
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        sed -i 's/<property name="plugin-5" type="string" value="whiskermenu">/<property name="plugin-5" type="string" value="applicationsmenu">/' "$CONFIG_DIR/xfce4-panel.xml"
        sed -i '/<property name="plugin-5".*whiskermenu/,/<\/property>/c\    <property name="plugin-5" type="string" value="applicationsmenu"/>' "$CONFIG_DIR/xfce4-panel.xml"
    fi

    case "$INSTALL_TYPE" in
        "complète")
            # Configuration complète avec tous les éléments
            cat > "$CONFIG_DIR/xsettings.xml" << EOF
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

            cat > "$CONFIG_DIR/xfwm4.xml" << EOF
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
            local THEME_VALUE="Default"
            local ICON_VALUE="Adwaita"
            local CURSOR_VALUE="default"
            local WALLPAPER="/data/data/com.termux/files/usr/share/backgrounds/xfce/xfce-stripes.png"

            # Ajuster selon les choix personnalisés
            [ "$INSTALL_THEME" = true ] && THEME_VALUE="WhiteSur-Dark"
            [ "$INSTALL_ICONS" = true ] && ICON_VALUE="WhiteSur-dark"
            [ "$INSTALL_CURSORS" = true ] && CURSOR_VALUE="dist-dark"
            [ "$INSTALL_WALLPAPERS" = true ] && WALLPAPER="/data/data/com.termux/files/usr/share/backgrounds/whitesur/Monterey.jpg"

            # Générer xsettings.xml
            cat > "$CONFIG_DIR/xsettings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="$THEME_VALUE"/>
    <property name="IconThemeName" type="string" value="$ICON_VALUE"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="$CURSOR_VALUE"/>
    <property name="CursorThemeSize" type="int" value="32"/>
  </property>
</channel>
EOF

            # Générer xfwm4.xml
            cat > "$CONFIG_DIR/xfwm4.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$THEME_VALUE"/>
  </property>
</channel>
EOF

            # Générer xfce4-desktop.xml
            cat > "$CONFIG_DIR/xfce4-desktop.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="$WALLPAPER"/>
        </property>
      </property>
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="$WALLPAPER"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
            ;;
    esac

    # Appliquer les permissions
    chmod 644 "$CONFIG_DIR"/*.xml
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

    # Paquets de base
    BASE_PKGS=(
        'termux-x11-nightly'         # Serveur X11 pour Termux
        'virglrenderer-android'      # Accélération graphique
        'xfce4'                      # Interface graphique
        'xfce4-terminal'             # Terminal
    )

    # Paquets principaux
    FULL_PKGS=(
        'pavucontrol-qt'             # Contrôle du son
        'wmctrl'                     # Contrôle des fenêtres
        'netcat-openbsd'             # Utilitaire réseau
        'thunar-archive-plugin'      # Archives
        'xfce4-whiskermenu-plugin'   # Menu Whisker
        'xfce4-notifyd'              # Notifications
        'xfce4-screenshooter'        # Capture d'écran
        'xfce4-taskmanager'          # Gestion des tâches
    )

    # Paquets additionnels
    EXTRA_PKGS=(
        'gigolo'                     # Gestion de fichiers
        'jq'                         # Utilitaire JSON
        'mousepad'                   # Éditeur de texte
        'netcat-openbsd'             # Utilitaire réseau
        'parole'                     # Lecteur multimédia
        'pavucontrol-qt'             # Contrôle du son
        'ristretto'                   # Gestion d'images
        'thunar-archive-plugin'      # Archives
        'thunar-media-tags-plugin'   # Médias
        'wmctrl'                     # Contrôle des fenêtres
        'xfce4-artwork'              # Artwork
        'xfce4-battery-plugin'       # Batterie
        'xfce4-clipman-plugin'       # Presse-papiers
        'xfce4-cpugraph-plugin'      # Graphique CPU
        'xfce4-datetime-plugin'      # Date et temps
        'xfce4-dict'                 # Dictionnaire
        'xfce4-diskperf-plugin'      # Performances disque
        'xfce4-fsguard-plugin'       # Surveillance disque
        'xfce4-genmon-plugin'        # Widgets génériques
        'xfce4-mailwatch-plugin'     # Surveillance mails
        'xfce4-netload-plugin'       # Chargement réseau
        'xfce4-notes-plugin'         # Notes
        'xfce4-notifyd'              # Notifications
        'xfce4-places-plugin'        # Emplacements
        'xfce4-screenshooter'        # Capture d'écran
        'xfce4-taskmanager'          # Gestion des tâches
        'xfce4-systemload-plugin'    # Chargement système
        'xfce4-timer-plugin'         # Timer
        'xfce4-wavelan-plugin'       # Wi-Fi
        'xfce4-weather-plugin'       # Informations météorologiques
        'xfce4-whiskermenu-plugin'   # Menu Whisker
    )

    case "$INSTALL_TYPE" in
        "minimale")
            PKGS=("${BASE_PKGS[@]}")
            ;;
        "complète")
            PKGS=("${BASE_PKGS[@]}" "${FULL_PKGS[@]}")
            INSTALL_THEME=true
            INSTALL_ICONS=true
            INSTALL_WALLPAPERS=true
            INSTALL_CURSORS=true
            ;;
        "personnalisée")
            PKGS=("${BASE_PKGS[@]}")
            
            if $USE_GUM; then
                SELECTED_EXTRA=($(gum_choose_multi "Paquets additionnels :" "${EXTRA_PKGS[@]}"))
                PKGS+=("${SELECTED_EXTRA[@]}")
                
                # Sélection des éléments graphiques
                SELECTED_UI=($(gum_choose_multi "Eléments graphiques :" \
                    "Thème WhiteSur" \
                    "Icônes WhiteSur" \
                    "Fonds d'écran WhiteSur" \
                    "Curseurs Fluent"))
                
                [[ " ${SELECTED_UI[*]} " =~ "Thème WhiteSur" ]] && INSTALL_THEME=true
                [[ " ${SELECTED_UI[*]} " =~ "Icônes WhiteSur" ]] && INSTALL_ICONS=true
                [[ " ${SELECTED_UI[*]} " =~ "Fonds d'écran WhiteSur" ]] && INSTALL_WALLPAPERS=true
                [[ " ${SELECTED_UI[*]} " =~ "Curseurs Fluent" ]] && INSTALL_CURSORS=true
            else
                echo -e "\n${COLOR_BLUE}Paquets additionnels :${COLOR_RESET}"
                for i in "${!EXTRA_PKGS[@]}"; do
                    echo "$((i+1))) ${EXTRA_PKGS[i]}"
                done
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r CHOICES
                tput sgr0
                for CHOICE in $CHOICES; do
                    IDX=$((CHOICE-1))
                    [ $IDX -ge 0 ] && [ $IDX -lt ${#EXTRA_PKGS[@]} ] && PKGS+=("${EXTRA_PKGS[IDX]}")
                done
                
                echo -e "\n${COLOR_BLUE}Eléments graphiques :${COLOR_RESET}"
                echo "1) Thème WhiteSur"
                echo "2) Icônes WhiteSur"
                echo "3) Fonds d'écran WhiteSur"
                echo "4) Curseurs Fluent"
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r UI_CHOICES
                tput sgr0
                for CHOICE in $UI_CHOICES; do
                    case $CHOICE in
                        1) INSTALL_THEME=true ;;
                        2) INSTALL_ICONS=true ;;
                        3) INSTALL_WALLPAPERS=true ;;
                        4) INSTALL_CURSORS=true ;;
                    esac
                done
            fi
            ;;
    esac

    # Ajouter le navigateur choisi
    if [ "$BROWSER" = "firefox" ]; then
        PKGS+=('firefox')
        BROWSER_DESKTOP="firefox.desktop"
    elif [ "$BROWSER" = "chromium" ]; then
        PKGS+=('chromium')
        BROWSER_DESKTOP="chromium.desktop"
    fi

    # Installation des paquets
    for PKG in "${PKGS[@]}"; do
        execute_command "pkg install $PKG -y" "Installation de $PKG"
    done

    # Configuration du bureau
    if [ "$BROWSER" != "aucun" ]; then
        execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/$BROWSER_DESKTOP $HOME/Desktop && chmod +x $HOME/Desktop/$BROWSER_DESKTOP" "Configuration du bureau"
    else
        execute_command "mkdir -p $HOME/Desktop" "Configuration du bureau"
    fi

    # Installation des éléments graphiques selon les choix
    if [ "$INSTALL_WALLPAPERS" = true ] || [ "$INSTALL_THEME" = true ] || [ "$INSTALL_ICONS" = true ] || [ "$INSTALL_CURSORS" = true ]; then
        subtitle_msg "❯ Configuration UI"

        if [ "$INSTALL_WALLPAPERS" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Téléchargement des fonds d'écran"
            execute_command "unzip main.zip && \
                            mkdir -p $PREFIX/share/backgrounds/whitesur && \
                            cp -r WhiteSur-wallpapers-main/4k/* $PREFIX/share/backgrounds/whitesur/ && \
                            rm -rf WhiteSur-wallpapers-main main.zip" "Installation des fonds d'écran"
        fi

        if [ "$INSTALL_THEME" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Téléchargement du thème"
            execute_command "unzip 2024-11-18.zip && \
                            tar -xf WhiteSur-gtk-theme-2024-11-18/release/WhiteSur-Dark.tar.xz && \
                            mv WhiteSur-Dark/ $PREFIX/share/themes/ && \
                            rm -rf WhiteSur* && \
                            rm 2024-11-18.zip*" "Installation du thème"
        fi

        if [ "$INSTALL_ICONS" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes"
            execute_command "unzip master.zip && \
                            cd WhiteSur-icon-theme-master && \
                            mkdir -p $PREFIX/share/icons && \
                            ./install.sh --dest $PREFIX/share/icons --name WhiteSur && \
                            cd .. && \
                            rm -rf WhiteSur-icon-theme-master master.zip" "Installation des icônes"
        fi

        if [ "$INSTALL_CURSORS" = true ]; then
            download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement des curseurs"
            execute_command "unzip 2024-02-25.zip && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && \
                            rm -rf $HOME/Fluent* && \
                            rm 2024-02-25.zip*" "Installation des curseurs"
        fi
    fi

    # Pré-configuration XFCE
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/config.zip" "Téléchargement de la configuration XFCE"
    execute_command "unzip -o config.zip && \
                rm config.zip" "Installation de la configuration"

    # Post-configuration XFCE
    configure_xfce "$INSTALL_TYPE"
}

main "$@"