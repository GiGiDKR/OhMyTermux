#!/bin/bash

USE_GUM=false
VERBOSE=false
BROWSER="chromium"

#------------------------------------------------------------------------------
# DISPLAY COLORS
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m' # Information
COLOR_GREEN='\033[38;5;82m' # Success
COLOR_GOLD='\033[38;5;220m' # Warning
COLOR_RED='\033[38;5;196m' # Error
COLOR_RESET='\033[0m' # Reset

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# SHOW HELP
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux Help"
    echo
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo " --gum | -g Use gum for user interface"
    echo " --verbose | -v Show verbose output"
echo " --browser | -b Choose browser (Chromium or Firefox)"
    echo " --version | -ver Choose installation type (full, minimal, custom)"
    echo " --help | -h Show this help message"
}

#------------------------------------------------------------------------------
# GLOBAL VARIABLES FOR CUSTOM INSTALLATION
#------------------------------------------------------------------------------
install_theme=false
install_icons=false
install_wallpapers=false
install_cursors=false
INSTALL_TYPE=""

#------------------------------------------------------------------------------
# ARGUMENTS MANAGEMENT
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
# GUM CONFIRMATION
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
# GUM CHOICE
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
# TEXT BANNER
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
# GRAPHIC BANNER
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
# ERROR MANAGEMENT
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERROR: Installation of OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERROR: Installation of OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error message(s) above.${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# INFO MESSAGES
#------------------------------------------------------------------------------
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# SUCCESS MESSAGES
#------------------------------------------------------------------------------
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# ERROR MESSAGES
#------------------------------------------------------------------------------
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# TITLE MESSAGES
#------------------------------------------------------------------------------
title_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 220 --bold
    else
        echo -e "\n${COLOR_GOLD}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# SUBTITLE MESSAGES
#------------------------------------------------------------------------------
subtitle_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33 --bold
    else
        echo -e "\n${COLOR_BLUE}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# ERROR LOG
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >>  "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# DYNAMIC DISPLAY OF COMMAND RESULTS
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
# FILE DOWNLOAD
#------------------------------------------------------------------------------
download_file() {
    local url=$1
    local message=$2
    execute_command "wget $url" "$message"
}

trap finish EXIT

# Function to configure XFCE according to the installation type
configure_xfce() {
    local config_dir="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    local install_type="$1"

    # CREATE CONFIGURATION DIRECTORY IF NECESSARY
    mkdir -p "$config_dir"

    # Configure xfce4-panel.xml if whiskermenu is not installed
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        sed -i 's/<property name="plugin-5" type="string" value="whiskermenu">/<property name="plugin-5" type="string" value="applicationsmenu">/' "$config_dir/xfce4-panel.xml"
        sed -i '/<property name="plugin-5".*whiskermenu/,/<\/property>/c\    <property name="plugin-5" type="string" value="applicationsmenu"/>' "$config_dir/xfce4-panel.xml"
    fi

    case "$INSTALL_TYPE" in
        "complète")
            # Complete configuration with all elements
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
            # Base configuration
            local theme_value="Default"
            local icon_value="Adwaita"
            local cursor_value="default"
            local wallpaper="/data/data/com.termux/files/usr/share/backgrounds/xfce/xfce-stripes.png"

            # Adjust according to the custom choices
            [ "$install_theme" = true ] && theme_value="WhiteSur-Dark"
            [ "$install_icons" = true ] && icon_value="WhiteSur-dark"
            [ "$install_cursors" = true ] && cursor_value="dist-dark"
            [ "$install_wallpapers" = true ] && wallpaper="/data/data/com.termux/files/usr/share/backgrounds/whitesur/Monterey.jpg"

            # Generate xsettings.xml
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

            # Generate xfwm4.xml
            cat > "$config_dir/xfwm4.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$theme_value"/>
  </property>
</channel>
EOF

            # Generate xfce4-desktop.xml
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

    # Apply permissions
    chmod 644 "$config_dir"/*.xml
}

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
main() {
    # Install gum if necessary
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo -e "${COLOR_BLUE}Installing gum${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi

    title_msg "❯ XFCE Installation"

    execute_command "pkg update -y && pkg upgrade -y" "Package update"

    # Base packages
    base_pkgs=(
        'termux-x11-nightly'         # X11 server for Termux
        'virglrenderer-android'      # Graphic acceleration
        'xfce4'                      # Graphic interface
        'xfce4-terminal'             # Terminal
    )

    # Paquets principaux
    full_pkgs=(
        'pavucontrol-qt'             # Sound control
        'wmctrl'                     # Window control
        'netcat-openbsd'             # Network utility
        'thunar-archive-plugin'      # Archives
        'xfce4-whiskermenu-plugin'   # Whisker menu
        'xfce4-notifyd'              # Notifications
        'xfce4-screenshooter'        # Screenshot
        'xfce4-taskmanager'          # Task manager
    )

    # Paquets additionnels
    extra_pkgs=(
        'gigolo'                     # Gestion de fichiers
        'jq'                         # JSON utility
        'mousepad'                   # Text editor
        'netcat-openbsd'             # Network utility
        'parole'                     # Media player
        'pavucontrol-qt'             # Sound control
        'ristretto'                  # Image manager
        'thunar-archive-plugin'      # Archives
        'thunar-media-tags-plugin'   # Media
        'wmctrl'                     # Window control
        'xfce4-artwork'              # Artwork
        'xfce4-battery-plugin'       # Battery
        'xfce4-clipman-plugin'       # Clipboard
        'xfce4-cpugraph-plugin'      # CPU graph
        'xfce4-datetime-plugin'      # Date and time
        'xfce4-dict'                 # Dictionary
        'xfce4-diskperf-plugin'      # Disk performance
        'xfce4-fsguard-plugin'       # Disk monitoring
        'xfce4-genmon-plugin'        # Generic widgets
        'xfce4-mailwatch-plugin'     # Mail monitoring
        'xfce4-netload-plugin'       # Network load
        'xfce4-notes-plugin'         # Notes
        'xfce4-notifyd'              # Notifications
        'xfce4-places-plugin'        # Locations
        'xfce4-screenshooter'        # Screenshot
        'xfce4-taskmanager'          # Task manager
        'xfce4-systemload-plugin'    # System load
        'xfce4-timer-plugin'         # Timer
        'xfce4-wavelan-plugin'       # Wi-Fi
        'xfce4-weather-plugin'       # Weather
        'xfce4-whiskermenu-plugin'   # Whisker menu
    )

    case "$INSTALL_TYPE" in
        "minimal")
            pkgs=("${base_pkgs[@]}")
            ;;
        "full")
            pkgs=("${base_pkgs[@]}" "${full_pkgs[@]}")
            install_theme=true
            install_icons=true
            install_wallpapers=true
            install_cursors=true
            ;;
        "custom")
            pkgs=("${base_pkgs[@]}")
            
            if $USE_GUM; then
                selected_extra=($(gum_choose "Additional packages :" "${extra_pkgs[@]}"))
                pkgs+=("${selected_extra[@]}")
                
                # Selection of UI elements
                selected_ui=($(gum_choose "UI elements :" \
                    "WhiteSur theme" \
                    "WhiteSur icons" \
                    "WhiteSur wallpapers" \
                    "Fluent cursors"))
                
                [[ " ${selected_ui[*]} " =~ "WhiteSur theme" ]] && install_theme=true
                [[ " ${selected_ui[*]} " =~ "WhiteSur icons" ]] && install_icons=true
                [[ " ${selected_ui[*]} " =~ "WhiteSur wallpapers" ]] && install_wallpapers=true
                [[ " ${selected_ui[*]} " =~ "Fluent cursors" ]] && install_cursors=true
            else
                echo -e "\n${COLOR_BLUE}Additional packages :${COLOR_RESET}"
                for i in "${!extra_pkgs[@]}"; do
                    echo "$((i+1))) ${extra_pkgs[i]}"
                done
                printf "${COLOR_GOLD}Enter your choice (separated by spaces) : ${COLOR_RESET}"
                tput setaf 3
                read -r choices
                tput sgr0
                for choice in $choices; do
                    idx=$((choice-1))
                    [ $idx -ge 0 ] && [ $idx -lt ${#extra_pkgs[@]} ] && pkgs+=("${extra_pkgs[idx]}")
                done
                
                echo -e "\n${COLOR_BLUE}UI elements :${COLOR_RESET}"
                echo "1) WhiteSur theme"
                echo "2) WhiteSur icons"
                echo "3) WhiteSur wallpapers"
                echo "4) Fluent cursors"
                printf "${COLOR_GOLD}Enter your choice (separated by spaces) : ${COLOR_RESET}"
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

    # Add the chosen browser
    if [ "$BROWSER" = "firefox" ]; then
        pkgs+=('firefox')
        browser_desktop="firefox.desktop"
    elif [ "$BROWSER" = "chromium" ]; then
        pkgs+=('chromium')
        browser_desktop="chromium.desktop"
    fi

    # Installation of packages
    for pkg in "${pkgs[@]}"; do
        execute_command "pkg install $pkg -y" "Installation of $pkg"
    done

    # Configuration du bureau
    if [ "$BROWSER" != "aucun" ]; then
        execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/$browser_desktop $HOME/Desktop && chmod +x $HOME/Desktop/$browser_desktop" "Desktop configuration"
    else
        execute_command "mkdir -p $HOME/Desktop" "Desktop configuration"
    fi

    # Installation of UI elements according to the choices
    if [ "$install_wallpapers" = true ] || [ "$install_theme" = true ] || [ "$install_icons" = true ] || [ "$install_cursors" = true ]; then
        subtitle_msg "❯ UI configuration"

        if [ "$install_wallpapers" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip" "Download wallpapers"
            execute_command "unzip main.zip && \
                            mkdir -p $PREFIX/share/backgrounds/whitesur && \
                            cp -r WhiteSur-wallpapers-main/4k/* $PREFIX/share/backgrounds/whitesur/ && \
                            rm -rf WhiteSur-wallpapers-main main.zip" "Wallpapers installation"
        fi

        if [ "$install_theme" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024-11-18.zip" "Download theme"
            execute_command "unzip 2024-11-18.zip && \
                            tar -xf WhiteSur-gtk-theme-2024-11-18/release/WhiteSur-Dark.tar.xz && \
                            mv WhiteSur-Dark/ $PREFIX/share/themes/ && \
                            rm -rf WhiteSur* && \
                            rm 2024-11-18.zip*" "Theme installation"
        fi

        if [ "$install_icons" = true ]; then
            download_file "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip" "Download icons"
            execute_command "unzip master.zip && \
                            cd WhiteSur-icon-theme-master && \
                            mkdir -p $PREFIX/share/icons && \
                            ./install.sh --dest $PREFIX/share/icons --name WhiteSur && \
                            cd .. && \
                            rm -rf WhiteSur-icon-theme-master master.zip" "Icons installation"
        fi

        if [ "$install_cursors" = true ]; then
            download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Download cursors"
            execute_command "unzip 2024-02-25.zip && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && \
                            mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && \
                            rm -rf $HOME/Fluent* && \
                            rm 2024-02-25.zip*" "Cursors installation"
        fi
    fi

    # Pre-configuration XFCE
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/config.zip" "Download XFCE configuration"
    execute_command "unzip -o config.zip && \
                rm config.zip" "Configuration installation"

    # Post-configuration XFCE
    configure_xfce "$INSTALL_TYPE"
}

main "$@"