#!/bin/bash

#------------------------------------------------------------------------------
# GLOBAL VARIABLES
#------------------------------------------------------------------------------
USE_GUM=false
VERBOSE=false
INSTALL_THEME=false
INSTALL_ICONS=false
INSTALL_WALLPAPERS=false
INSTALL_CURSORS=false
SELECTED_THEME=""
SELECTED_ICON_THEME=""
SELECTED_WALLPAPER=""

#------------------------------------------------------------------------------
# DISPLAY COLORS
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Success
COLOR_GOLD='\033[38;5;220m'   # Warning
COLOR_RED='\033[38;5;196m'    # Error
COLOR_RESET='\033[0m'         # Reset

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    REDIRECT=">/dev/null 2>&1"
else
    REDIRECT=""
fi

#------------------------------------------------------------------------------
# DISPLAY HELP
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux Help"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Use gum for the user interface"
    echo "  --verbose | -v Display detailed outputs"
    echo "  --help | -h    Display this help message"
}

#------------------------------------------------------------------------------
# ARGUMENTS MANAGEMENT
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
# ERROR LOGGING
#------------------------------------------------------------------------------
log_error() {
    local ERROR_MSG="$1"
    local USERNAME=$(whoami)
    local HOSTNAME=$(hostname)
    local CWD=$(pwd)
    echo "[$(date +'%d/%m/%Y %H:%M:%S')] ERREUR: $ERROR_MSG | Utilisateur: $USERNAME | Machine: $HOSTNAME | Répertoire: $CWD" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# DYNAMIC DISPLAY OF THE RESULT OF A COMMAND
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
# CHECKING DEPENDENCIES
#------------------------------------------------------------------------------
check_dependencies() {
    if [ "$USE_GUM" = true ]; then
        if $USE_GUM && ! command -v gum &> /dev/null; then
            echo -e "${COLOR_BLUE}Installing gum${COLOR_RESET}"
            pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
        fi
    fi

    if ! command -v proot-distro &> /dev/null; then
        error_msg "Please install proot-distro before continuing."
        exit 1
    fi
}

#------------------------------------------------------------------------------
# DISPLAY THE BANNER IN TEXT MODE
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
# DISPLAY THE BANNER
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
    local RET=$?
    if [ ${RET} -ne 0 ] && [ ${RET} -ne 130 ]; then
        echo
        if [ "$USE_GUM" = true ]; then
            gum style --foreground 196 "ERROR : Installation of OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERROR : Installation of OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error messages above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# INSTALLATION OF PROOT PACKAGES
#------------------------------------------------------------------------------
install_packages_proot() {
    local PKGS_PROOT=('sudo' 'wget' 'nala' 'xfconf')
    for PKG in "${PKGS_PROOT[@]}"; do
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install $PKG -y" "Installation de $PKG"
    done
}

#------------------------------------------------------------------------------
# CREATE A USER IN PROOT WITH PASSWORD
#------------------------------------------------------------------------------
create_user_proot() {
    execute_command "
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$USERNAME'
        echo '$USERNAME:$PASSWORD' | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chpasswd
    " "Création de l'utilisateur"
}

#------------------------------------------------------------------------------
# CONFIGURATION OF THE USER RIGHTS
#------------------------------------------------------------------------------
configure_user_rights() {
    execute_command "
        # Add the user to the sudo group
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 usermod -aG sudo '$USERNAME'

        # Create the sudoers.d file for the user
        echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' > '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers.d/$USERNAME'
        chmod 0440 '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers.d/$USERNAME'

        # Configure the main sudoers file
        echo '%sudo ALL=(ALL:ALL) ALL' >> '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'

        # Check permissions
        chmod 440 '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'
        chown root:root '$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers'
    " "Configuration of sudo rights"
}

#------------------------------------------------------------------------------
# INSTALLATION OF MESA-VULKAN
#------------------------------------------------------------------------------
install_mesa_vulkan() {
    local MESA_PACKAGE="mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb"
    local MESA_URL="https://github.com/GiGiDKR/OhMyTermux/raw/1.0.0/src/$MESA_PACKAGE"

    if ! proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dpkg -s mesa-vulkan-kgsl &> /dev/null; then
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $MESA_URL" "Downloading Mesa-Vulkan"
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$MESA_PACKAGE" "Installing Mesa-Vulkan"
    else
        info_msg "Mesa-Vulkan is already installed."
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION OF THEMES AND ICONS
#------------------------------------------------------------------------------
configure_themes_and_icons() {
    # Load the configuration from the temporary file
    if [ -f "$HOME/.config/OhMyTermux/theme_config.tmp" ]; then
        source "$HOME/.config/OhMyTermux/theme_config.tmp"
    fi

    # Create the necessary directories
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes"
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons"
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/backgrounds/whitesur"

    # Copy the themes if installed
    if [ "$INSTALL_THEME" = true ] && [ -n "$SELECTED_THEME" ]; then
        case $SELECTED_THEME in
            "WhiteSur")
                execute_command "cp -r $PREFIX/share/themes/WhiteSur-Dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration of the WhiteSur theme"
                ;;
            "Fluent")
                execute_command "cp -r $PREFIX/share/themes/Fluent-dark-compact $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration of the Fluent theme"
                ;;
            "Lavanda")
                execute_command "cp -r $PREFIX/share/themes/Lavanda-dark-compact $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/themes/" "Configuration of the Lavanda theme"
                ;;
        esac
    fi

    # Copy the icons if installed
    if [ "$INSTALL_ICONS" = true ] && [ -n "$SELECTED_ICON_THEME" ]; then
        case $SELECTED_ICON_THEME in
            "WhiteSur")
                execute_command "cp -r $PREFIX/share/icons/WhiteSur-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the WhiteSur icons"
                ;;
            "McMojave-circle")
                execute_command "cp -r $PREFIX/share/icons/McMojave-circle-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the McMojave icons"
                ;;
            "Tela")
                execute_command "cp -r $PREFIX/share/icons/Tela-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the Tela icons"
                ;;
            "Fluent")
                execute_command "cp -r $PREFIX/share/icons/Fluent-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the Fluent icons"
                ;;
            "Qogir")
                execute_command "cp -r $PREFIX/share/icons/Qogir-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the Qogir icons"
                ;;
        esac
    fi

    # Copy the wallpapers if installed
    if [ "$INSTALL_WALLPAPERS" = true ]; then
        execute_command "cp -r $PREFIX/share/backgrounds/whitesur/* $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/backgrounds/whitesur/" "Configuration of the wallpapers"
    fi

    # Copy the cursors if installed
    if [ "$INSTALL_CURSORS" = true ]; then
        execute_command "cp -r $PREFIX/share/icons/dist $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the cursors"
        execute_command "cp -r $PREFIX/share/icons/dist-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/" "Configuration of the dark cursors"
    fi

    # Delete the temporary configuration file
    rm -f "$HOME/.config/OhMyTermux/theme_config.tmp"
}

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
check_dependencies
title_msg "❯ Installation of Debian Proot"

if [ $# -eq 0 ]; then
    if [ "$USE_GUM" = true ]; then
        USERNAME=$(gum input --prompt "Username: " --placeholder "Enter a username")
        while true; do
            PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Enter a password")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirm the password")
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground "#FF0000" "The passwords do not match. Please try again."
            fi
        done
    else
        echo -e "${COLOR_BLUE}Enter a username: ${COLOR_RESET}"
        read -r USERNAME
        tput cuu1
        tput el
        while true; do
            echo -e "${COLOR_BLUE}Enter a password: ${COLOR_RESET}"
            read -rs PASSWORD
            tput cuu1
            tput el
            echo -e "${COLOR_BLUE}Confirm the password: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            tput cuu1
            tput el 
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}The passwords do not match. Please try again.${COLOR_RESET}"
                tput cuu1
                tput el
            fi
        done
    fi
elif [ $# -eq 1 ]; then
    USERNAME="$1"
    if [ "$USE_GUM" = true ]; then
        while true; do
            PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Enter a password")
            PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirm the password")
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                gum style --foreground "#FF0000" "The passwords do not match. Please try again."
            fi
        done
    else
        while true; do
            echo -e "${COLOR_BLUE}Enter a password: ${COLOR_RESET}"
            read -rs PASSWORD
            tput cuu1
            tput el
            echo -e "${COLOR_BLUE}Confirm the password: ${COLOR_RESET}"
            read -rs PASSWORD_CONFIRM
            tput cuu1
            tput el
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${COLOR_RED}The passwords do not match. Please try again.${COLOR_RESET}"
                tput cuu1
                tput el
            fi
        done
    fi
elif [ $# -eq 2 ]; then
    USERNAME="$1"
    PASSWORD="$2"
else
    show_help
    exit 1
fi

execute_command "proot-distro install debian" "Installation of the distribution"

#------------------------------------------------------------------------------
# CHECKING THE INSTALLATION OF DEBIAN
#------------------------------------------------------------------------------
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
    error_msg "The installation of Debian failed."
    exit 1
fi

execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update" "Searching for updates"
execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y" "Updating packages"

install_packages_proot

subtitle_msg "❯ Configuration of the distribution"

create_user_proot
configure_user_rights

#------------------------------------------------------------------------------
# CONFIGURATION OF THE TIMEZONE
#------------------------------------------------------------------------------
TIMEZONE=$(getprop persist.sys.timezone)
execute_command "
    proot-distro login debian -- rm /etc/localtime
    proot-distro login debian -- cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
" "Configuration of the timezone"

#------------------------------------------------------------------------------
# GRAPHICAL CONFIGURATION
#------------------------------------------------------------------------------
configure_themes_and_icons

#------------------------------------------------------------------------------
# INSTALLATION OF MESA-VULKAN
#------------------------------------------------------------------------------
install_mesa_vulkan