#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES GLOBALES
#------------------------------------------------------------------------------
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
    echo "  --version | -ver  Choisir le type d'installation (minimale, recommandée, personnalisée)"
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
SELECTED_THEME="WhiteSur"
SELECTED_THEMES=()
SELECTED_ICON_THEME="WhiteSur"
SELECTED_ICON_THEMES=()
SELECTED_WALLPAPER="Monterey.jpg"

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
            REDIRECT=""
            shift
            ;;
        --browser|-b)
            BROWSER="${2}"
            shift 2
            ;;
        --version=*)
            INSTALL_TYPE="${arg#*=}"
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

    gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
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

    gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
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
        echo -e "${COLOR_BLUE}Veuillez vous rférer au(x) message(s) d'erreur ci-dessus.${COLOR_RESET}"
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
    local USERNAME=$(whoami)
    local HOSTNAME=$(hostname)
    local CWD=$(pwd)
    echo "[$(date +'%d/%m/%Y %H:%M:%S')] ERREUR: $ERROR_MSG | Utilisateur: $USERNAME | Machine: $HOSTNAME | Répertoire: $CWD" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
#------------------------------------------------------------------------------
execute_command() {
    local COMMAND="$1"
    local INFO_MSG="$2"
    local SUCCESS_MSG="✓ $INFO_MSG"
    local ERROR_MSG="✗ $INFO_MSG"
    local ERROR_DETAILS

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            gum style "$SUCCESS_MSG" --foreground 82
        else
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            gum style "$ERROR_MSG - $ERROR_DETAILS" --foreground 196
            log_error "$ERROR_DETAILS"
            return 1
        fi
    else
        tput sc
        info_msg "$INFO_MSG"
        
        if eval "$COMMAND $REDIRECT"; then
            tput rc
            tput el
            success_msg "$SUCCESS_MSG"
        else
            tput rc
            tput el
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            error_msg "$ERROR_MSG - $ERROR_DETAILS"
            log_error "$ERROR_DETAILS"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# TÉLÉCHARGEMENT DE FICHIER
#------------------------------------------------------------------------------
download_file() {
    local URL=$1
    local MESSAGE=$2
    execute_command "wget $URL" "$MESSAGE"
}

trap finish EXIT

#------------------------------------------------------------------------------
# CONFIGURATION DE XFCE
#------------------------------------------------------------------------------
configure_xfce() {
    local CONFIG_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    local INSTALL_TYPE="$1"
    local BROWSER_DESKTOP

    # Définir le fichier .desktop du navigateur
    if [ "$BROWSER" = "firefox" ]; then
        BROWSER_DESKTOP="firefox"
    elif [ "$BROWSER" = "chromium" ]; then
        BROWSER_DESKTOP="chromium"
    else
        BROWSER_DESKTOP="$BROWSER"
    fi

    # Créer le répertoire de configuration si nécessaire
    mkdir -p "$CONFIG_DIR" >/dev/null 2>&1

    # Configurer le navigateur par défaut
    cat > "$CONFIG_DIR/xfce4-mime-settings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-mime-settings" version="1.0">
  <property name="last" type="empty">
    <property name="window-width" type="int" value="550"/>
    <property name="window-height" type="int" value="400"/>
    <property name="mime-width" type="int" value="300"/>
    <property name="status-width" type="int" value="75"/>
    <property name="default-width" type="int" value="150"/>
  </property>
  <property name="default" type="empty">
    <property name="x-scheme-handler/http" type="string" value="$BROWSER_DESKTOP.desktop"/>
    <property name="x-scheme-handler/https" type="string" value="$BROWSER_DESKTOP.desktop"/>
  </property>
</channel>
EOF

    # Créer le fichier mimeapps.list
    mkdir -p "$HOME/.config" >/dev/null 2>&1
    cat > "$HOME/.config/mimeapps.list" << EOF
[Default Applications]
x-scheme-handler/http=$BROWSER_DESKTOP.desktop
x-scheme-handler/https=$BROWSER_DESKTOP.desktop
text/html=$BROWSER_DESKTOP.desktop
application/xhtml+xml=$BROWSER_DESKTOP.desktop

[Added Associations]
x-scheme-handler/http=$BROWSER_DESKTOP.desktop
x-scheme-handler/https=$BROWSER_DESKTOP.desktop
text/html=$BROWSER_DESKTOP.desktop
application/xhtml+xml=$BROWSER_DESKTOP.desktop
EOF

    # Configurer xfce4-terminal
    mkdir -p "$HOME/.config/xfce4/terminal" >/dev/null 2>&1
    cat > "$HOME/.config/xfce4/terminal/terminalrc" << EOF
[Configuration]
FontName=Monospace 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=120x30
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.800000
TitleMode=TERMINAL_TITLE_HIDE
ScrollingLines=10000
ColorForeground=#c0caf5
ColorBackground=#1a1b26
ColorCursor=#c0caf5
ColorPalette=#15161e;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#a9b1d6;#414868;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#c0caf5
EOF

    # Configurer xfce4-panel.xml si whiskermenu n'est pas installé
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        sed -i 's/<property name="plugin-5" type="string" value="whiskermenu">/<property name="plugin-5" type="string" value="applicationsmenu">/' "$CONFIG_DIR/xfce4-panel.xml" >/dev/null 2>&1
        sed -i '/<property name="plugin-5".*whiskermenu/,/<\/property>/c\    <property name="plugin-5" type="string" value="applicationsmenu"/>' "$CONFIG_DIR/xfce4-panel.xml" >/dev/null 2>&1
    fi

    case "$INSTALL_TYPE" in
        "recommandée")
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
            if [ "$INSTALL_THEME" = true ]; then
                case $SELECTED_THEME in
                    "WhiteSur") THEME_VALUE="WhiteSur-Dark" ;;
                    "Fluent") THEME_VALUE="Fluent-dark-compact" ;;
                    "Lavanda") THEME_VALUE="Lavanda-dark-compact" ;;
                esac
            fi

            if [ "$INSTALL_ICONS" = true ]; then
                case $SELECTED_ICON_THEME in
                    "WhiteSur") ICON_VALUE="WhiteSur-dark" ;;
                    "McMojave-circle") ICON_VALUE="McMojave-circle-dark" ;;
                    "Tela") ICON_VALUE="Tela-dark" ;;
                    "Fluent") ICON_VALUE="Fluent-dark" ;;
                    "Qogir") ICON_VALUE="Qogir-dark" ;;
                esac
            fi

            [ "$INSTALL_CURSORS" = true ] && CURSOR_VALUE="dist-dark"
            [ "$INSTALL_WALLPAPERS" = true ] && WALLPAPER="/data/data/com.termux/files/usr/share/backgrounds/whitesur/${SELECTED_WALLPAPER}.jpg"

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
      <property name="monitorBuiltinDisplay" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="$WALLPAPER"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-home" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-trash" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF
            ;;
    esac

    # Appliquer les permissions
    chmod 644 "$CONFIG_DIR"/*.xml >/dev/null 2>&1
}

#------------------------------------------------------------------------------
# SAUVEGARDE DE LA CONFIGURATION DES THÈMES
#------------------------------------------------------------------------------
save_theme_config() {
    mkdir -p "$HOME/.config/OhMyTermux"
    cat > "$HOME/.config/OhMyTermux/theme_config.tmp" << EOF
INSTALL_THEME=$INSTALL_THEME
INSTALL_ICONS=$INSTALL_ICONS
INSTALL_WALLPAPERS=$INSTALL_WALLPAPERS
INSTALL_CURSORS=$INSTALL_CURSORS
SELECTED_THEME="$SELECTED_THEME"
SELECTED_ICON_THEME="$SELECTED_ICON_THEME"
SELECTED_WALLPAPER="$SELECTED_WALLPAPER"
EOF
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

    # Paquets nécessaires
    BASE_PKGS=(
        'termux-x11-nightly'         # Serveur X11 pour Termux
        'virglrenderer-android'      # Accélération graphique
        'xfce4'                      # Interface graphique
        'xfce4-terminal'             # Terminal
    )

    # Paquets recommandés
    RECOMMENDED_PKGS=(
        'pavucontrol-qt'             # Contrôle du son
        'wmctrl'                     # Contrôle des fenêtres
        'netcat-openbsd'             # Utilitaire réseau
        'thunar-archive-plugin'      # Archives
        'xfce4-whiskermenu-plugin'   # Menu Whisker
        'xfce4-notifyd'              # Notifications
        'xfce4-screenshooter'        # Capture d'écran
        'xfce4-taskmanager'          # Gestion des tâches
    )

    # Paquets optionnels
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
        "recommandée")
            PKGS=("${BASE_PKGS[@]}" "${RECOMMENDED_PKGS[@]}")
            INSTALL_THEME=true
            INSTALL_ICONS=true
            INSTALL_WALLPAPERS=true
            INSTALL_CURSORS=true
            SELECTED_THEMES=("WhiteSur")
            SELECTED_ICON_THEMES=("WhiteSur")
            SELECTED_THEME="WhiteSur"
            SELECTED_ICON_THEME="WhiteSur"
            SELECTED_WALLPAPER="Monterey"
            ;;
        "personnalisée")
            PKGS=("${BASE_PKGS[@]}")

            if $USE_GUM; then
                SELECTED_EXTRA=($(gum_choose_multi "Sélectionner les paquets à installer :" "${EXTRA_PKGS[@]}"))
                if [ ${#SELECTED_EXTRA[@]} -gt 0 ]; then
                    PKGS+=("${SELECTED_EXTRA[@]}")
                fi

                SELECTED_UI=($(gum_choose_multi "Sélectionner les éléments à installer :" \
                    "Thèmes" \
                    "Icônes" \
                    "Fonds d'écran" \
                    "Curseurs"))

                if [[ " ${SELECTED_UI[*]} " =~ "Thèmes" ]]; then
                    SELECTED_THEMES=($(gum_choose_multi "Sélectionner les thèmes à installer :" \
                        "WhiteSur" \
                        "Fluent" \
                        "Lavanda"))

                    if [ ${#SELECTED_THEMES[@]} -gt 0 ]; then
                        INSTALL_THEME=true
                        if [ ${#SELECTED_THEMES[@]} -gt 1 ]; then
                            SELECTED_THEME=$(gum_choose "Sélectionner le thème à appliquer :" "${SELECTED_THEMES[@]}")
                        else
                            SELECTED_THEME="${SELECTED_THEMES[0]}"
                        fi
                    fi
                fi

                if [[ " ${SELECTED_UI[*]} " =~ "Icônes" ]]; then
                    # Tableau associatif pour mapper les noms d'affichage aux valeurs réelles
                    declare -A ICON_DISPLAY_NAMES=(
                        ["WhiteSur"]="WhiteSur"
                        ["McMojave"]="McMojave-circle"
                        ["Tela"]="Tela"
                        ["Fluent"]="Fluent"
                        ["Qogir"]="Qogir"
                    )
                    
                    # Utiliser les noms d'affichage pour la sélection
                    SELECTED_DISPLAY_NAMES=($(gum_choose_multi "Sélectionner les packs d'icônes à installer :" \
                        "WhiteSur" \
                        "McMojave" \
                        "Tela" \
                        "Fluent" \
                        "Qogir"))

                    # Convertir les noms d'affichage en valeurs réelles
                    SELECTED_ICON_THEMES=()
                    for display_name in "${SELECTED_DISPLAY_NAMES[@]}"; do
                        SELECTED_ICON_THEMES+=("${ICON_DISPLAY_NAMES[$display_name]}")
                    done

                    if [ ${#SELECTED_ICON_THEMES[@]} -gt 0 ]; then
                        INSTALL_ICONS=true
                        if [ ${#SELECTED_ICON_THEMES[@]} -gt 1 ]; then
                            if $USE_GUM; then
                                SELECTED_ICON_THEME=$(gum_choose "Sélectionner le pack d'icônes à appliquer :" "${SELECTED_ICON_THEMES[@]}")
                            else
                                echo -e "\n${COLOR_BLUE}Packs d'icônes sélectionnés :${COLOR_RESET}"
                                for i in "${!SELECTED_ICON_THEMES[@]}"; do
                                    echo "$((i+1))) ${SELECTED_ICON_THEMES[i]}"
                                done
                                printf "${COLOR_GOLD}Sélectionner le pack d'icônes à appliquer (1-${#SELECTED_ICON_THEMES[@]}) : ${COLOR_RESET}"
                                tput setaf 3
                                read -r APPLY_CHOICE
                                tput sgr0
                                SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[$((APPLY_CHOICE-1))]}"
                            fi
                        else
                            SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[0]}"
                        fi
                    fi
                fi

                if [[ " ${SELECTED_UI[*]} " =~ "Fonds d'écran" ]]; then
                    INSTALL_WALLPAPERS=true
                    SELECTED_WALLPAPER=$(gum_choose "Choisir le fond d'écran à appliquer :" \
                        "Monterey" \
                        "Monterey-dark" \
                        "Monterey-light" \
                        "Monterey-morning" \
                        "Sonoma-dark" \
                        "Sonoma-light" \
                        "Ventura-dark" \
                        "Ventura-light" \
                        "WhiteSur" \
                        "WhiteSur-dark" \
                        "WhiteSur-light" \
                        "WhiteSur-morning")
                fi

                [[ " ${SELECTED_UI[*]} " =~ "Curseurs" ]] && INSTALL_CURSORS=true
            else
                echo -e "\n${COLOR_BLUE}Interface graphique :${COLOR_RESET}"
                echo
                echo "1) Thèmes"
                echo "2) Icônes"
                echo "3) Fonds d'écran"
                echo "4) Curseurs"
                echo
                printf "${COLOR_GOLD}Sélectionner les éléments (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r UI_CHOICES
                tput sgr0
                tput cuu 8
                tput el

                if [[ $UI_CHOICES =~ 1 ]]; then
                    echo -e "\n${COLOR_BLUE}Thèmes disponibles :${COLOR_RESET}"
                    echo
                    echo "1) WhiteSur"
                    echo "2) Fluent"
                    echo "3) Lavanda"
                    echo
                    printf "${COLOR_GOLD}Sélectionner les thèmes (séparés par des espaces) : ${COLOR_RESET}"
                    tput setaf 3
                    read -r THEME_CHOICES
                    tput sgr0
                    tput cuu 7
                    tput el

                    for choice in $THEME_CHOICES; do
                        case $choice in
                            1) SELECTED_THEMES+=("WhiteSur") ;;
                            2) SELECTED_THEMES+=("Fluent") ;;
                            3) SELECTED_THEMES+=("Lavanda") ;;
                        esac
                    done

                    if [ ${#SELECTED_THEMES[@]} -gt 0 ]; then
                        INSTALL_THEME=true
                        if [ ${#SELECTED_THEMES[@]} -gt 1 ]; then
                            echo -e "\n${COLOR_BLUE}Thèmes sélectionnés :${COLOR_RESET}"
                            echo
                            for i in "${!SELECTED_THEMES[@]}"; do
                                echo "$((i+1))) ${SELECTED_THEMES[i]}"
                            done
                            echo
                            printf "${COLOR_GOLD}Sélectionner le thème à appliquer (1-${#SELECTED_THEMES[@]}) : ${COLOR_RESET}"
                            tput setaf 3
                            read -r APPLY_CHOICE
                            tput sgr0
                            # Calcul dynamique du nombre de lignes à effacer
                            LINES_TO_CLEAR=$((4 + ${#SELECTED_THEMES[@]}))
                            tput cuu $LINES_TO_CLEAR
                            tput ed
                            SELECTED_THEME="${SELECTED_THEMES[$((APPLY_CHOICE-1))]}"
                        else
                            SELECTED_THEME="${SELECTED_THEMES[0]}"
                        fi
                    fi
                fi

                if [[ $UI_CHOICES =~ 2 ]]; then
                    echo -e "\n${COLOR_BLUE}Packs d'icônes disponibles :${COLOR_RESET}"
                    echo
                    echo "1) WhiteSur"
                    echo "2) McMojave"
                    echo "3) Tela"
                    echo "4) Fluent"
                    echo "5) Qogir"
                    echo
                    printf "${COLOR_GOLD}Sélectionner les packs d'icônes à installer (séparés par des espaces) : ${COLOR_RESET}"
                    tput setaf 3
                    read -r ICON_CHOICES
                    tput sgr0
                    tput cuu 9
                    tput el

                    for ICON_CHOICE in $ICON_CHOICES; do
                        case $ICON_CHOICE in
                            1) SELECTED_ICON_THEMES+=("WhiteSur") ;;
                            2) SELECTED_ICON_THEMES+=("McMojave-circle") ;;
                            3) SELECTED_ICON_THEMES+=("Tela") ;;
                            4) SELECTED_ICON_THEMES+=("Fluent") ;;
                            5) SELECTED_ICON_THEMES+=("Qogir") ;;
                        esac
                    done

                    if [ ${#SELECTED_ICON_THEMES[@]} -gt 0 ]; then
                        INSTALL_ICONS=true
                        if [ ${#SELECTED_ICON_THEMES[@]} -gt 1 ]; then
                            if $USE_GUM; then
                                SELECTED_ICON_THEME=$(gum_choose "Sélectionner le pack d'icônes à appliquer :" "${SELECTED_ICON_THEMES[@]}")
                            else
                                echo -e "\n${COLOR_BLUE}Packs d'icônes sélectionnés :${COLOR_RESET}"
                                echo
                                for i in "${!SELECTED_ICON_THEMES[@]}"; do
                                    echo "$((i+1))) ${SELECTED_ICON_THEMES[i]}"
                                done
                                echo
                                printf "${COLOR_GOLD}Sélectionner le pack d'icônes à appliquer (1-${#SELECTED_ICON_THEMES[@]}) : ${COLOR_RESET}"
                                tput setaf 3
                                read -r APPLY_CHOICE
                                tput sgr0
                                LINES_TO_CLEAR=$((4 + ${#SELECTED_ICON_THEMES[@]}))
                                tput cuu $LINES_TO_CLEAR
                                tput ed
                                SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[$((APPLY_CHOICE-1))]}"
                            fi
                        else
                            SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[0]}"
                        fi
                    fi
                fi

                if [[ $UI_CHOICES =~ 3 ]]; then
                    INSTALL_WALLPAPERS=true
                    echo -e "\n${COLOR_BLUE}Fonds d'écran disponibles :${COLOR_RESET}"
                    echo
                    echo "1) Monterey"
                    echo "2) Monterey-dark"
                    echo "3) Monterey-light"
                    echo "4) Monterey-morning"
                    echo "5) Sonoma-dark"
                    echo "6) Sonoma-light"
                    echo "7) Ventura-dark"
                    echo "8) Ventura-light"
                    echo "9) WhiteSur"
                    echo "10) WhiteSur-dark"
                    echo "11) WhiteSur-light"
                    echo "12) WhiteSur-morning"
                    echo
                    printf "${COLOR_GOLD}Sélectionner le fond d'écran à appliquer (1-12) : ${COLOR_RESET}"
                    tput setaf 3
                    read -r WALLPAPER_CHOICE
                    tput sgr0
                    tput cuu 16
                    tput el

                    case $WALLPAPER_CHOICE in
                        1) SELECTED_WALLPAPER="Monterey" ;;
                        2) SELECTED_WALLPAPER="Monterey-dark" ;;
                        3) SELECTED_WALLPAPER="Monterey-light" ;;
                        4) SELECTED_WALLPAPER="Monterey-morning" ;;
                        5) SELECTED_WALLPAPER="Sonoma-dark" ;;
                        6) SELECTED_WALLPAPER="Sonoma-light" ;;
                        7) SELECTED_WALLPAPER="Ventura-dark" ;;
                        8) SELECTED_WALLPAPER="Ventura-light" ;;
                        9) SELECTED_WALLPAPER="WhiteSur" ;;
                        10) SELECTED_WALLPAPER="WhiteSur-dark" ;;
                        11) SELECTED_WALLPAPER="WhiteSur-light" ;;
                        12) SELECTED_WALLPAPER="WhiteSur-morning" ;;
                    esac
                fi

                [[ $UI_CHOICES =~ 4 ]] && INSTALL_CURSORS=true
            fi
            ;;
    esac

    # Ajout du navigateur aux paquets
    if [ "$BROWSER" = "firefox" ]; then
        PKGS+=('firefox')
        BROWSER_DESKTOP="firefox.desktop"
    elif [ "$BROWSER" = "chromium" ]; then
        PKGS+=('chromium')
        BROWSER_DESKTOP="chromium.desktop"
    fi

    subtitle_msg "❯ Installation des paquets"
    for PKG in "${PKGS[@]}"; do
        execute_command "pkg install $PKG -y" "Installation de $PKG"
    done

    # Configuration du bureau
    if [ "$BROWSER" != "aucun" ]; then
        execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/$BROWSER_DESKTOP $HOME/Desktop && chmod +x $HOME/Desktop/$BROWSER_DESKTOP" "Configuration du bureau"
    else
        execute_command "mkdir -p $HOME/Desktop" "Configuration du bureau"
    fi

    # Installation personnalisée des éléments graphiques
    if [ "$INSTALL_WALLPAPERS" = true ] || [ "$INSTALL_THEME" = true ] || [ "$INSTALL_ICONS" = true ] || [ "$INSTALL_CURSORS" = true ]; then

        subtitle_msg "❯ Configuration de l'interface"

        if [ "$INSTALL_WALLPAPERS" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Téléchargement des fonds d'écran"
            execute_command "unzip main.zip && \
                            mkdir -p $PREFIX/share/backgrounds/whitesur && \
                            cp -r WhiteSur-wallpapers-main/4k/* $PREFIX/share/backgrounds/whitesur/ && \
                            rm -rf WhiteSur-wallpapers-main main.zip" "Installation des fonds d'écran"
        fi

        if [ "$INSTALL_THEME" = true ]; then
            # Installation des thèmes sélectionnés
            for THEME in "${SELECTED_THEMES[@]}"; do
                case $THEME in
                    "WhiteSur")
                        ARCHIVE="whitesur-theme.zip"
                        download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Téléchargement du thème WhiteSur"
                        execute_command "mv 2024-11-18.zip $ARCHIVE && \
                                        unzip $ARCHIVE && \
                                        tar -xf WhiteSur-gtk-theme-2024-11-18/release/WhiteSur-Dark.tar.xz && \
                                        mv WhiteSur-Dark/ $PREFIX/share/themes/ && \
                                        rm -rf WhiteSur-gtk-theme-2024-11-18 $ARCHIVE" "Installation du thème WhiteSur"
                        ;;
                    "Fluent")
                        ARCHIVE="fluent-theme.zip"
                        download_file "https://github.com/vinceliuice/Fluent-gtk-theme/archive/refs/heads/master.zip" "Téléchargement du thème Fluent"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd Fluent-gtk-theme-master && \
                                    ./install.sh -d $PREFIX/share/themes -t dark -s compact && \
                                    cd .. && \
                                    rm -rf Fluent-gtk-theme-master $ARCHIVE" "Installation du thème Fluent"
                        ;;
                    "Lavanda")
                        ARCHIVE="lavanda-theme.zip"
                        download_file "https://github.com/vinceliuice/Lavanda-gtk-theme/archive/refs/heads/main.zip" "Téléchargement du thème Lavanda"
                        execute_command "mv main.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd Lavanda-gtk-theme-main && \
                                    ./install.sh -d $PREFIX/share/themes -c dark -s compact && \
                                    cd .. && \
                                    rm -rf Lavanda-gtk-theme-main $ARCHIVE" "Installation du thème Lavanda"
                        ;;
                esac
            done
        fi

        if [ "$INSTALL_ICONS" = true ]; then
            # Installation des thèmes d'icônes sélectionnés
            for ICON_THEME in "${SELECTED_ICON_THEMES[@]}"; do
                case $ICON_THEME in
                    "WhiteSur")
                        ARCHIVE="whitesur-icons.zip"
                        download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes WhiteSur"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd WhiteSur-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf WhiteSur-icon-theme-master $ARCHIVE" "Installation des icônes WhiteSur"
                        ;;
                    "McMojave-circle")
                        ARCHIVE="mcmojave-icons.zip"
                        download_file "https://github.com/vinceliuice/McMojave-circle/archive/refs/heads/master.zip" "Téléchargement des icônes McMojave-circle"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd McMojave-circle-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf McMojave-circle-master $ARCHIVE" "Installation des icônes McMojave-circle"
                        ;;
                    "Tela")
                        ARCHIVE="tela-icons.zip"
                        download_file "https://github.com/vinceliuice/Tela-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Tela"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd Tela-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Tela-icon-theme-master $ARCHIVE" "Installation des icônes Tela"
                        ;;
                    "Fluent")
                        ARCHIVE="fluent-icons.zip"
                        download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Fluent"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd Fluent-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Fluent-icon-theme-master $ARCHIVE" "Installation des icônes Fluent"
                        ;;
                    "Qogir")
                        ARCHIVE="qogir-icons.zip"
                        download_file "https://github.com/vinceliuice/Qogir-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Qogir"
                        execute_command "mv master.zip $ARCHIVE && \
                                    unzip $ARCHIVE && \
                                    cd Qogir-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Qogir-icon-theme-master $ARCHIVE" "Installation des icônes Qogir"
                        ;;
                esac
            done
        fi

        if [ "$INSTALL_CURSORS" = true ]; then
            # Installation des curseurs
            ARCHIVE="2024-02-25.zip"
            download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Téléchargement des curseurs"
            execute_command "unzip $ARCHIVE && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && \
                            rm -rf Fluent-icon-theme-2024-02-25 $ARCHIVE" "Installation des curseurs"
        fi
    fi

    # Pré-configuration XFCE
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/1.0.0/src/config.zip" "Téléchargement de la configuration XFCE"
    execute_command "unzip -o config.zip && \
                rm config.zip" "Installation de la configuration"

    # Post-configuration XFCE
    configure_xfce "$INSTALL_TYPE"

    # Sauvegarder la configuration des thèmes
    save_theme_config
}

main "$@"