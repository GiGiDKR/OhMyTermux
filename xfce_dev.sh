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
║                                        ���
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
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $redirect"; then
            success_msg "$SUCCESS_MSG"
        else
            error_msg "$ERROR_MSG"
            log_error "$COMMAND"
            return 1
        fi
    else
        info_msg "$INFO_MSG"
        if eval "$COMMAND $redirect"; then
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
    local URL=$1
    local MESSAGE=$2
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
        sed -i 's/<property name="plugin-5" type="string" value="whiskermenu">/<property name="plugin-5" type="string" value="applicationsmenu">/' "$config_dir/xfce4-panel.xml"
        sed -i '/<property name="plugin-5".*whiskermenu/,/<\/property>/c\    <property name="plugin-5" type="string" value="applicationsmenu"/>' "$config_dir/xfce4-panel.xml"
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
        "recommandée")
            PKGS=("${BASE_PKGS[@]}" "${RECOMMENDED_PKGS[@]}")
            INSTALL_THEME=true
            INSTALL_ICONS=true
            INSTALL_WALLPAPERS=true
            INSTALL_CURSORS=true
            ;;
        "personnalisée")
            PKGS=("${BASE_PKGS[@]}")

            if $USE_GUM; then
                subtitle_msg "❯ Sélection des paquets additionnels"
                SELECTED_EXTRA=($(gum_choose_multi "Sélectionner les paquets à installer :" "${EXTRA_PKGS[@]}"))
                if [ ${#SELECTED_EXTRA[@]} -gt 0 ]; then
                    PKGS+=("${SELECTED_EXTRA[@]}")
                fi

                subtitle_msg "❯ Personnalisation de l'interface"
                SELECTED_THEMES=($(gum_choose_multi "Sélectionner les thèmes à installer :" \
                    "WhiteSur" \
                    "Fluent" \
                    "Lavanda"))

                if [ ${#SELECTED_THEMES[@]} -gt 0 ]; then
                    INSTALL_THEME=true
                    if [ ${#SELECTED_THEMES[@]} -gt 1 ]; then
                        SELECTED_THEME=$(gum_choose "Choisir le thème à appliquer :" "${SELECTED_THEMES[@]}")
                    else
                        SELECTED_THEME="${SELECTED_THEMES[0]}"
                    fi
                fi

                SELECTED_EXTRA=($(gum_choose_multi "Paquets additionnels :" "${EXTRA_PKGS[@]}"))
                PKGS+=("${SELECTED_EXTRA[@]}")
                
                SELECTED_ICON_THEMES=($(gum_choose_multi "Sélectionner les thèmes d'icônes à installer :" \
                    "WhiteSur" \
                    "McMojave-circle" \
                    "Tela" \
                    "Fluent" \
                    "Qogir"))

                if [ ${#SELECTED_ICON_THEMES[@]} -gt 0 ]; then
                    INSTALL_ICONS=true
                    if [ ${#SELECTED_ICON_THEMES[@]} -gt 1 ]; then
                        SELECTED_ICON_THEME=$(gum_choose "Choisir le thème d'icônes à appliquer :" "${SELECTED_ICON_THEMES[@]}")
                    else
                        SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[0]}"
                    fi
                fi

                SELECTED_UI=($(gum_choose_multi "Eléments graphiques :" \
                    "Fonds d'écran WhiteSur" \
                    "Curseurs Fluent"))

                if [[ " ${SELECTED_UI[*]} " =~ "Fonds d'écran WhiteSur" ]]; then
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

                [[ " ${SELECTED_UI[*]} " =~ "Curseurs Fluent" ]] && INSTALL_CURSORS=true
            else
                echo -e "\n${COLOR_BLUE}Thèmes disponibles :${COLOR_RESET}"
                echo "1) WhiteSur"
                echo "2) Fluent"
                echo "3) Lavanda"
                printf "${COLOR_GOLD}Choisir les thèmes à installer (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r THEME_CHOICES
                tput sgr0

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
                        for i in "${!SELECTED_THEMES[@]}"; do
                            echo "$((i+1))) ${SELECTED_THEMES[i]}"
                        done
                        printf "${COLOR_GOLD}Choisir le thème à appliquer (1-${#SELECTED_THEMES[@]}) : ${COLOR_RESET}"
                        tput setaf 3
                        read -r APPLY_CHOICE
                        tput sgr0
                        SELECTED_THEME="${SELECTED_THEMES[$((APPLY_CHOICE-1))]}"
                    else
                        SELECTED_THEME="${SELECTED_THEMES[0]}"
                    fi
                fi

                echo -e "\n${COLOR_BLUE}Paquets additionnels :${COLOR_RESET}"
                for i in "${!EXTRA_PKGS[@]}"; do
                    echo "$((i+1))) ${EXTRA_PKGS[i]}"
                done
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r CHOICES
                tput sgr0
                for CHOICE in $CHOICES; do
                    idx=$((CHOICE-1))
                    [ $idx -ge 0 ] && [ $idx -lt ${#EXTRA_PKGS[@]} ] && PKGS+=("${EXTRA_PKGS[idx]}")
                done

                echo -e "\n${COLOR_BLUE}Eléments graphiques :${COLOR_RESET}"
                echo "1) Fonds d'écran WhiteSur"
                echo "2) Curseurs Fluent"
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r UI_CHOICES
                tput sgr0

                if [[ $UI_CHOICES =~ 1 ]]; then
                    INSTALL_WALLPAPERS=true
                    echo -e "\n${COLOR_BLUE}Fonds d'écran disponibles :${COLOR_RESET}"
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
                    printf "${COLOR_GOLD}Choisir le fond d'écran à appliquer (1-12) : ${COLOR_RESET}"
                    tput setaf 3
                    read -r WALLPAPER_CHOICE
                    tput sgr0

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

                [[ $UI_CHOICES =~ 2 ]] && INSTALL_CURSORS=true

                echo -e "\n${COLOR_BLUE}Thèmes d'icônes disponibles :${COLOR_RESET}"
                echo "1) WhiteSur"
                echo "2) McMojave-circle"
                echo "3) Tela"
                echo "4) Fluent"
                echo "5) Qogir"
                printf "${COLOR_GOLD}Choisir les thèmes d'icônes à installer (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r ICON_CHOICES
                tput sgr0

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
                        echo -e "\n${COLOR_BLUE}Thèmes d'icônes sélectionnés :${COLOR_RESET}"
                        for i in "${!SELECTED_ICON_THEMES[@]}"; do
                            echo "$((i+1))) ${SELECTED_ICON_THEMES[i]}"
                        done
                        printf "${COLOR_GOLD}Choisir le thème d'icônes à appliquer (1-${#SELECTED_ICON_THEMES[@]}) : ${COLOR_RESET}"
                        tput setaf 3
                        read -r APPLY_CHOICE
                        tput sgr0
                        SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[$((APPLY_CHOICE-1))]}"
                    else
                        SELECTED_ICON_THEME="${SELECTED_ICON_THEMES[0]}"
                    fi
                fi
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

    # Installation personnalisée des éléments graphiques
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
            # Installation des thèmes sélectionnés
            for THEME in "${SELECTED_THEMES[@]}"; do
                case $THEME in
                    "WhiteSur")
                        download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.zip" "Téléchargement du thème WhiteSur"
                        execute_command "unzip master.zip && \
                                    cd WhiteSur-gtk-theme-master && \
                                    ./install.sh -d $PREFIX/share/themes -c dark -s standard && \
                                    cd .. && \
                                    rm -rf WhiteSur-gtk-theme-master master.zip" "Installation du thème WhiteSur"
                        ;;
                    "Fluent")
                        download_file "https://github.com/vinceliuice/Fluent-gtk-theme/archive/refs/heads/master.zip" "Téléchargement du thème Fluent"
                        execute_command "unzip master.zip && \
                                    cd Fluent-gtk-theme-master && \
                                    ./install.sh -d $PREFIX/share/themes -t dark -s compact && \
                                    cd .. && \
                                    rm -rf Fluent-gtk-theme-master master.zip" "Installation du thème Fluent"
                        ;;
                    "Lavanda")
                        download_file "https://github.com/vinceliuice/Lavanda-gtk-theme/archive/refs/heads/main.zip" "Téléchargement du thème Lavanda"
                        execute_command "unzip main.zip && \
                                    cd Lavanda-gtk-theme-main && \
                                    ./install.sh -d $PREFIX/share/themes -c dark -s compact && \
                                    cd .. && \
                                    rm -rf Lavanda-gtk-theme-main main.zip" "Installation du thème Lavanda"
                        ;;
                esac
            done
        fi

        if [ "$INSTALL_ICONS" = true ]; then
            # Installation des thèmes d'icônes sélectionnés
            for ICON_THEME in "${SELECTED_ICON_THEMES[@]}"; do
                case $ICON_THEME in
                    "WhiteSur")
                        download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes WhiteSur"
                        execute_command "unzip master.zip && \
                                    cd WhiteSur-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf WhiteSur-icon-theme-master master.zip" "Installation des icônes WhiteSur"
                        ;;
                    "McMojave-circle")
                        download_file "https://github.com/vinceliuice/McMojave-circle/archive/refs/heads/master.zip" "Téléchargement des icônes McMojave-circle"
                        execute_command "unzip master.zip && \
                                    cd McMojave-circle-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf McMojave-circle-master master.zip" "Installation des icônes McMojave-circle"
                        ;;
                    "Tela")
                        download_file "https://github.com/vinceliuice/Tela-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Tela"
                        execute_command "unzip master.zip && \
                                    cd Tela-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Tela-icon-theme-master master.zip" "Installation des icônes Tela"
                        ;;
                    "Fluent")
                        download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Fluent"
                        execute_command "unzip master.zip && \
                                    cd Fluent-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Fluent-icon-theme-master master.zip" "Installation des icônes Fluent"
                        ;;
                    "Qogir")
                        download_file "https://github.com/vinceliuice/Qogir-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes Qogir"
                        execute_command "unzip master.zip && \
                                    cd Qogir-icon-theme-master && \
                                    ./install.sh --dest $PREFIX/share/icons && \
                                    cd .. && \
                                    rm -rf Qogir-icon-theme-master master.zip" "Installation des icônes Qogir"
                        ;;
                esac
            done
        fi

        if [ "$INSTALL_CURSORS" = true ]; then
            # Installation des curseurs
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