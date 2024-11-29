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
    echo "  --gum | -g        Utiliser gum pour l'interface utilisateur"
    echo "  --verbose | -v    Afficher les sorties détaillées"
    echo "  --browser | -b    Choisir le navigateur (Chromium ou Firefox)"
    echo "  --version | -ver  Choisir le type d'installation (complète, minimale, personnalisée)"
    echo "  --help | -h       Afficher ce message d'aide"
}

#------------------------------------------------------------------------------
# VARIABLES GLOBALES POUR L'INSTALLATION PERSONNALISÉE
#------------------------------------------------------------------------------
install_theme=false
install_icons=false
install_wallpapers=false
install_cursors=false
INSTALL_TYPE=""

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
    local prompt="$1"
    if $FULL_INSTALL; then
        return 0 
    else
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$prompt"
    fi
}

#------------------------------------------------------------------------------
# SÉLECTION GUM
#------------------------------------------------------------------------------
gum_choose() {
    local prompt="$1"
    shift
    local selected=""
    local options=()
    local height=10  # Valeur par défaut

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                selected="${1#*=}"
                ;;
            --height=*)
                height="${1#*=}"
                ;;
            *)
                options+=("$1")
                ;;
        esac
        shift
    done
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
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >>  "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
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
# TÉLÉCHARGEMENT DE FICHIER
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

    # Configurer xfce4-panel.xml si whiskermenu n'est pas installé
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        sed -i 's/<property name="plugin-5" type="string" value="whiskermenu">/<property name="plugin-5" type="string" value="applicationsmenu">/' "$config_dir/xfce4-panel.xml"
        sed -i '/<property name="plugin-5".*whiskermenu/,/<\/property>/c\    <property name="plugin-5" type="string" value="applicationsmenu"/>' "$config_dir/xfce4-panel.xml"
    fi

    case "$INSTALL_TYPE" in
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

    # Paquets de base
    base_pkgs=(
        'termux-x11-nightly'         # Serveur X11 pour Termux
        'virglrenderer-android'      # Accélération graphique
        'xfce4'                      # Interface graphique
        'xfce4-terminal'             # Terminal
    )

    # Paquets principaux
    full_pkgs=(
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
    extra_pkgs=(
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
            pkgs=("${base_pkgs[@]}")
            ;;
        "complète")
            pkgs=("${base_pkgs[@]}" "${full_pkgs[@]}")
            install_theme=true
            install_icons=true
            install_wallpapers=true
            install_cursors=true
            ;;
        "personnalisée")
            pkgs=("${base_pkgs[@]}")
            
            if $USE_GUM; then
                selected_extra=($(gum_choose "Paquets additionnels :" "${extra_pkgs[@]}"))
                pkgs+=("${selected_extra[@]}")
                
                # Sélection des éléments graphiques
                selected_ui=($(gum_choose "Eléments graphiques :" \
                    "Thème WhiteSur" \
                    "Icônes WhiteSur" \
                    "Fonds d'écran WhiteSur" \
                    "Curseurs Fluent"))
                
                [[ " ${selected_ui[*]} " =~ "Thème WhiteSur" ]] && install_theme=true
                [[ " ${selected_ui[*]} " =~ "Icônes WhiteSur" ]] && install_icons=true
                [[ " ${selected_ui[*]} " =~ "Fonds d'écran WhiteSur" ]] && install_wallpapers=true
                [[ " ${selected_ui[*]} " =~ "Curseurs Fluent" ]] && install_cursors=true
            else
                echo -e "\n${COLOR_BLUE}Paquets additionnels :${COLOR_RESET}"
                for i in "${!extra_pkgs[@]}"; do
                    echo "$((i+1))) ${extra_pkgs[i]}"
                done
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r choices
                tput sgr0
                for choice in $choices; do
                    idx=$((choice-1))
                    [ $idx -ge 0 ] && [ $idx -lt ${#extra_pkgs[@]} ] && pkgs+=("${extra_pkgs[idx]}")
                done
                
                echo -e "\n${COLOR_BLUE}Eléments graphiques :${COLOR_RESET}"
                echo "1) Thème WhiteSur"
                echo "2) Icônes WhiteSur"
                echo "3) Fonds d'écran WhiteSur"
                echo "4) Curseurs Fluent"
                printf "${COLOR_GOLD}Entrez votre choix (séparés par des espaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r ui_choices
                tput sgr0
                for choice in $ui_choices; do
                    case $choice in
                        1) install_theme=true ;;
                        2) install_icons=true ;;
                        3) install_wallpapers=true ;;
                        4) install_cursors=true ;;
                    esac
                done
            fi
            ;;
    esac

    # Ajouter le navigateur choisi
    if [ "$BROWSER" = "firefox" ]; then
        pkgs+=('firefox')
        browser_desktop="firefox.desktop"
    elif [ "$BROWSER" = "chromium" ]; then
        pkgs+=('chromium')
        browser_desktop="chromium.desktop"
    fi

    # Installation des paquets
    for pkg in "${pkgs[@]}"; do
        execute_command "pkg install $pkg -y" "Installation de $pkg"
    done

    # Installation des éléments graphiques selon les choix
    if [ "$install_wallpapers" = true ] || [ "$install_theme" = true ] || [ "$install_icons" = true ] || [ "$install_cursors" = true ]; then
        subtitle_msg "❯ Configuration UI"

        if [ "$install_wallpapers" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Téléchargement des fonds d'écran"
            execute_command "unzip main.zip && \
                            mkdir -p $PREFIX/share/backgrounds/whitesur && \
                            cp -r WhiteSur-wallpapers-main/4k/* $PREFIX/share/backgrounds/whitesur/ && \
                            rm -rf WhiteSur-wallpapers-main main.zip" "Installation des fonds d'écran"
        fi

        if [ "$install_theme" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Téléchargement du thème"
            execute_command "unzip 2024-11-18.zip && \
                            tar -xf WhiteSur-gtk-theme-2024-11-18/release/WhiteSur-Dark.tar.xz && \
                            mv WhiteSur-Dark/ $PREFIX/share/themes/ && \
                            rm -rf WhiteSur* && \
                            rm 2024-11-18.zip*" "Installation du thème"
        fi

        if [ "$install_icons" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Téléchargement des icônes"
            execute_command "unzip master.zip && \
                            cd WhiteSur-icon-theme-master && \
                            mkdir -p $PREFIX/share/icons && \
                            ./install.sh --dest $PREFIX/share/icons --name WhiteSur && \
                            cd .. && \
                            rm -rf WhiteSur-icon-theme-master master.zip" "Installation des icônes"
        fi

        if [ "$install_cursors" = true ]; then
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