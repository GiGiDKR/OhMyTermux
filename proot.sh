#!/bin/bash

set -euo pipefail

USE_GUM=false
VERBOSE=false

# Colors in variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

# Redirection configuration
if [ "$VERBOSE" = false ]; then
    redirect=">/dev/null 2>&1"
else
    redirect=""
fi

# Function to display help
show_help() {
    clear
    echo "OhMyTermux Help"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g     Use gum for user interface"
    echo "  --verbose | -v Display detailed output"
    echo "  --help | -h    Display this help message"
}

# Gestion des arguments
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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $error_msg" >> "$HOME/.config/OhMyTermux/install.log"
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
            gum style "$success_msg" --foreground 82
        else
            gum style "$error_msg" --foreground 196
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
# CHECK REQUIRED DEPENDENCIES
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
# DISPLAY BANNER
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
# ERROR HANDLING FUNCTION
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if [ "$USE_GUM" = true ]; then
            gum style --foreground 196 "ERROR: OhMyTermux installation failed."
        else
            echo -e "${COLOR_RED}ERROR: OhMyTermux installation failed.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error messages above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# INSTALL REQUIRED PACKAGES IN PROOT
#------------------------------------------------------------------------------
install_packages_proot() {
    local pkgs_proot=('sudo' 'wget' 'nala' 'jq')
    for pkg in "${pkgs_proot[@]}"; do
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt install $pkg -y" "Installing $pkg"
    done
}

#------------------------------------------------------------------------------
# CREATE A USER IN PROOT WITH PASSWORD
#------------------------------------------------------------------------------
create_user_proot() {
    execute_command "
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd storage
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 groupadd wheel
        proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash '$username'
        echo '$username:$password' | proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 chpasswd
    " "Creating user"
}

#------------------------------------------------------------------------------
# CONFIGURE USER RIGHTS
#------------------------------------------------------------------------------
configure_user_rights() {
    execute_command '
        chmod u+rw "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        echo "$username ALL=(ALL:ALL) ALL" | tee -a "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
        chmod u-w "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/etc/sudoers"
    ' "User rights elevation"
}

#------------------------------------------------------------------------------
# INSTALL MESA-VULKAN
#------------------------------------------------------------------------------
install_mesa_vulkan() {
    local mesa_package="mesa-vulkan-kgsl_24.1.0-devel-20240120_arm64.deb"
    local mesa_url="https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/$mesa_package"
    
    if ! proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dpkg -s mesa-vulkan-kgsl &> /dev/null; then
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 wget $mesa_url" "Downloading Mesa-Vulkan"
        execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 sudo apt install -y ./$mesa_package" "Installing Mesa-Vulkan"
    else
        info_msg "Mesa-Vulkan is already installed."
    fi
}

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
main() {
    check_dependencies
    title_msg "❯ Installing Debian Proot"

if [ $# -eq 0 ]; then
    if [ "$USE_GUM" = true ]; then
        username=$(gum input --prompt "Username: " --placeholder "Enter your username")
        while true; do
            password=$(gum input --password --prompt "Password: " --placeholder "Enter your password")
            password_confirm=$(gum input --password --prompt "Confirm password: " --placeholder "Enter your password again")
            if [ "$password" = "$password_confirm" ]; then
                break
            else
                gum style --foreground "#FF0000" "Passwords do not match. Please try again."
            fi
        done
    else
        echo -e "${COLOR_BLUE}Enter your username: ${COLOR_RESET}"
        read -r username
        while true; do
            echo -e "${COLOR_BLUE}Enter your password: ${COLOR_RESET}"
            read -rs password
            echo -e "${COLOR_BLUE}Confirm your password: ${COLOR_RESET}"
            read -rs password_confirm
            if [ "$password" = "$password_confirm" ]; then
                break
            else
                echo -e "${COLOR_RED}Passwords do not match. Please try again.${COLOR_RESET}"
            fi
        done
    fi
elif [ $# -eq 1 ]; then
    username="$1"
    if [ "$USE_GUM" = true ]; then
        while true; do
            password=$(gum input --password --prompt "Password: " --placeholder "Enter your password")
            password_confirm=$(gum input --password --prompt "Confirm password: " --placeholder "Enter your password again")
            if [ "$password" = "$password_confirm" ]; then
                break
            else
                gum style --foreground "#FF0000" "Passwords do not match. Please try again."
            fi
        done
    else
        while true; do
            echo -e "${COLOR_BLUE}Enter your password: ${COLOR_RESET}"
            read -rs password
            echo -e "${COLOR_BLUE}Confirm your password: ${COLOR_RESET}"
            read -rs password_confirm
            if [ "$password" = "$password_confirm" ]; then
                break
            else
                echo -e "${COLOR_RED}Passwords do not match. Please try again.${COLOR_RESET}"
            fi
        done
    fi
elif [ $# -eq 2 ]; then
    username="$1"
    password="$2"
else
    show_help
    exit 1
fi

execute_command "proot-distro install debian" "Installation of the distribution"

#------------------------------------------------------------------------------
# CHECK INSTALLATION OF DEBIAN
#------------------------------------------------------------------------------
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
    error_msg "Debian installation failed."
    exit 1
fi

execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt update" "Checking for updates"
execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 apt upgrade -y" "Updating packages"

install_packages_proot

create_user_proot
configure_user_rights

#------------------------------------------------------------------------------
# CONFIGURE TIMEZONE
#------------------------------------------------------------------------------
timezone=$(getprop persist.sys.timezone)
execute_command "
    proot-distro login debian -- rm /etc/localtime
    proot-distro login debian -- cp /usr/share/zoneinfo/$timezone /etc/localtime
" "Configuring timezone"

#------------------------------------------------------------------------------
# CONFIGURE ICONS AND THEMES
#------------------------------------------------------------------------------
mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons
execute_command "cp -r $PREFIX/share/icons/dist-dark $PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/icons/dist-dark" "Configuring icons"

#------------------------------------------------------------------------------
# CONFIGURE CURSORS
#------------------------------------------------------------------------------
execute_command "cat <<'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.Xresources
Xcursor.theme: dist-dark
EOF" "Configuring cursors"

#------------------------------------------------------------------------------
# CONFIGURE THEMES AND FONTS
#------------------------------------------------------------------------------
execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 bash -c \"mkdir -p /home/$username/.fonts/ /home/$username/.themes/\"" "Configuring themes and fonts"

install_mesa_vulkan