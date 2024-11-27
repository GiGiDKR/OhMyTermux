#!/bin/bash

USE_GUM=false
VERBOSE=false

#------------------------------------------------------------------------------
# COLORS
#------------------------------------------------------------------------------
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

#------------------------------------------------------------------------------
# REDIRECT CONFIGURATION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# HELP
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux help"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Use gum for the user interface"
    echo "  --verbose | -v Show detailed outputs"
    echo "  --help | -h    Show this help message"
}

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
# BANNER
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
# FINISH
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
# INFORMATION MESSAGES
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
        echo -e "\n${COLOR_GOLD}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# ERROR LOGGING
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# EXECUTION COMMAND AND DYNAMIC DISPLAY RESULT
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
# INSTALL PACKAGE
#------------------------------------------------------------------------------
#install_package() {
#    local pkg=$1
#    execute_command "pkg install $pkg -y" "Install $pkg"
#}

#------------------------------------------------------------------------------
# DOWNLOAD FILES
#------------------------------------------------------------------------------
download_file() {
    local url=$1
    local message=$2
    execute_command "wget $url" "$message"
}

trap finish EXIT

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
main() {
    # Install gum if necessary
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo -e "${COLOR_BLUE}Installing gum${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi

    title_msg "❯ Installing XFCE"

    execute_command "pkg update -y && pkg upgrade -y" "Updating packages"

    # Install packages
    pkgs=('virglrenderer-android' 'xfce4' 'xfce4-goodies' 'papirus-icon-theme' 'pavucontrol-qt' 'jq' 'wmctrl' 'firefox' 'netcat-openbsd' 'termux-x11-nightly')


    for pkg in "${pkgs[@]}"; do
        execute_command "pkg install $pkg -y" "Installing $pkg"
    done

    # Configure desktop
    execute_command "mkdir -p $HOME/Desktop && cp $PREFIX/share/applications/firefox.desktop $HOME/Desktop && chmod +x $HOME/Desktop/firefox.desktop" "Configure desktop"

    # Download wallpaper
    download_file "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/waves.png" "Download wallpaper"
    execute_command "mkdir -p $PREFIX/share/backgrounds/xfce/ && mv waves.png $PREFIX/share/backgrounds/xfce/" "Configure wallpaper"

    # Download theme
    download_file "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2024.11.18.zip" "Download WhiteSur-Dark"
    execute_command "unzip 2024.11.18.zip && tar -xf WhiteSur-gtk-theme-2024.11.18/release/WhiteSur-Dark.tar.xz && mv WhiteSur-Dark/ $PREFIX/share/themes/ && rm -rf WhiteSur* && rm 2024.11.18.zip" "Install theme"

    # Download cursor
    download_file "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2024-02-25.zip" "Download Fluent Cursor"
    execute_command "unzip 2024-02-25.zip && mv Fluent-icon-theme-2024-02-25/cursors/dist $PREFIX/share/icons/ && mv Fluent-icon-theme-2024-02-25/cursors/dist-dark $PREFIX/share/icons/ && rm -rf $HOME/Fluent* && rm 2024-02-25.zip" "Install cursors"

    # Download configuration
    download_file "https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/config.zip" "Download XFCE configuration"
    execute_command "unzip -o config.zip && rm config.zip" "Install configuration"
}

main "$@"