#!/bin/bash

#------------------------------------------------------------------------------
# GLOBAL VARIABLES
#------------------------------------------------------------------------------
# Interactive interface with gum
USE_GUM=false

# Initial configuration
EXECUTE_INITIAL_CONFIG=true

# Detailed operations display
VERBOSE=false

#------------------------------------------------------------------------------
# MODULE SELECTORS
#------------------------------------------------------------------------------
# Shell selection
SHELL_CHOICE=false

# Additional packages installation
PACKAGES_CHOICE=false

# Custom fonts installation
FONT_CHOICE=false
    
# XFCE environment installation
XFCE_CHOICE=false

# Debian Proot installation
PROOT_CHOICE=false

# Termux-X11 installation
X11_CHOICE=false

# Complete installation without interactions
FULL_INSTALL=false

# Use gum for interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# CONFIGURATION FILES
#------------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
FISHRC="$HOME/.config/fish/config.fish"

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
    REDIRECT="> /dev/null 2>&1"
else
    REDIRECT=""
fi

#------------------------------------------------------------------------------
# DISPLAY HELP
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux Help"
    echo ""
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g        Use gum for the user interface"
    echo "  --verbose | -v    Display detailed outputs"
    echo "  --shell | -sh     Installation module for the shell"
    echo "  --package | -pk   Installation module for packages"
    echo "  --font | -f       Installation module for the font"
    echo "  --xfce | -x       Installation module for XFCE"
    echo "  --proot | -pr     Installation module for Debian Proot"
    echo "  --x11             Installation module for Termux-X11"
    echo "  --skip            Ignore initial configuration"
    echo "  --uninstall       Uninstallation of Debian Proot"
    echo "  --full            Install all modules without confirmation"
    echo "  --help | -h       Display this help message"
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
        --shell|-sh)
            SHELL_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --package|-pk)
            PACKAGES_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --font|-f)
            FONT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --xfce|-x)
            XFCE_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --proot|-pr)
            PROOT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --x11)
            X11_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --skip)
            EXECUTE_INITIAL_CONFIG=false
            shift
            ;;
        --uninstall)
            uninstall_proot
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            REDIRECT=""
            shift
            ;;
        --full)
            FULL_INSTALL=true
            SHELL_CHOICE=true
            PACKAGES_CHOICE=true
            FONT_CHOICE=true
            XFCE_CHOICE=true
            PROOT_CHOICE=true
            X11_CHOICE=true
            SCRIPT_CHOICE=true
            ONLY_GUM=false
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

# Activate all modules if --gum is the only argument
if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    PROOT_CHOICE=true
    X11_CHOICE=true
    SCRIPT_CHOICE=true
fi

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
# DYNAMIC DISPLAY OF A COMMAND RESULT
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
# GUM CONFIRMATION
#------------------------------------------------------------------------------
gum_confirm() {
    local PROMPT="$1"
    if $FULL_INSTALL; then
        return 0 
    else
        gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$PROMPT"
    fi
}

#------------------------------------------------------------------------------
# GUM UNIQUE SELECTION
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
            # Return the first option by default
            echo "${OPTIONS[0]}"
        fi
    else
        gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
}

#------------------------------------------------------------------------------
# GUM MULTIPLE SELECTION
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
# TEXT BANNER DISPLAY
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
# GUM INSTALLATION
#------------------------------------------------------------------------------
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

#------------------------------------------------------------------------------
# ERROR MANAGEMENT
#------------------------------------------------------------------------------
finish() {
    local RET=$?
    if [ ${RET} -ne 0 ] && [ ${RET} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERROR: Installation of OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERROR: Installation of OhMyTermux impossible.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error message(s) above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# GRAPHIC BANNER DISPLAY
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
# FILES BACKUP
#------------------------------------------------------------------------------
create_backups() {
    local BACKUP_DIR="$HOME/.config/OhMyTermux/backup"
    
    # Create backup directory
    execute_command "mkdir -p \"$BACKUP_DIR\"" "Create backup directory"

    # List of files to backup
    local FILES_TO_BACKUP=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        #"$0"
    )

    # Copy files to backup directory
    for FILE in "${FILES_TO_BACKUP[@]}"; do
        if [ -f "$FILE" ]; then
            execute_command "cp \"$FILE\" \"$BACKUP_DIR/\"" "Backup of $(basename "$FILE")"
        fi
    done
}

#------------------------------------------------------------------------------
# REPOSITORY CHANGE
#------------------------------------------------------------------------------
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum_confirm "Change the repository mirror ?"; then
            termux-change-repo
        fi
    else
        printf "${COLOR_BLUE}Change the repository mirror ? (Y/n) : ${COLOR_RESET}"
        read -r -e -p "" -i "y" CHOICE
        [[ "$CHOICE" =~ ^[yY]$ ]] && termux-change-repo
    fi
}

#------------------------------------------------------------------------------
# STORAGE CONFIGURATION
#------------------------------------------------------------------------------
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        show_banner
        if $USE_GUM; then
            if gum_confirm "Allow access to storage ?"; then
                termux-setup-storage
            fi
        else
            printf "${COLOR_BLUE}Allow access to storage ? (Y/n) : ${COLOR_RESET}"
            read -r -e -p "" -i "y" CHOICE
            [[ "$CHOICE" =~ ^[yY]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# TERMUX CONFIGURATION
#------------------------------------------------------------------------------
configure_termux() {
    title_msg "❯ Termux configuration"
    # Backup existing files
    create_backups
    TERMUX_DIR="$HOME/.termux"
    # Configure colors.properties
    FILE_PATH="$TERMUX_DIR/colors.properties"
    if [ ! -f "$FILE_PATH" ]; then
        execute_command "mkdir -p \"$TERMUX_DIR\" && cat > \"$FILE_PATH\" << 'EOL'
# https://github.com/Mayccoll/Gogh/blob/master/themes/argonaut.sh
background=#0e1019
foreground=#fffaf4
cursor=#fffaf4
color0=#232323
color1=#ff000f
color2=#8ce10b
color3=#ffb900
color4=#008df8
color5=#6d43a6
color6=#00d8eb
color7=#ffffff
color8=#444444
color9=#ff2740
color10=#abe15b
color11=#ffd242
color12=#0092ff
color13=#9a5feb
color14=#67fff0
color15=#ffffff
EOL" "Installation of the Argonaut theme"
    fi
    # Configure termux.properties
    FILE_PATH="$TERMUX_DIR/termux.properties"
    if [ ! -f "$FILE_PATH" ]; then
        execute_command "cat > \"$FILE_PATH\" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Termux properties configuration"
    else
        execute_command "sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' \"$FILE_PATH\" && \
        sed -i 's/^# use-black-ui = true/use-black-ui = true/' \"$FILE_PATH\" && \
        sed -i 's/^# bell-character = ignore/bell-character = ignore/' \"$FILE_PATH\" && \
        sed -i 's/^# fullscreen = true/fullscreen = true/' \"$FILE_PATH\"" "Termux configuration"
    fi
    # Delete login banner
    execute_command "touch $HOME/.hushlogin" "Delete login banner"
}

#------------------------------------------------------------------------------
# INITIAL CONFIGURATION
#------------------------------------------------------------------------------
initial_config() {
    change_repo

    # Update and upgrade packages preserving existing configurations
    clear
    show_banner
    execute_command "pkg update -y -o Dpkg::Options::=\"--force-confold\"" "Update repositories"
    execute_command "pkg upgrade -y -o Dpkg::Options::=\"--force-confold\"" "Upgrade packages"

    setup_storage

    if $USE_GUM; then
        show_banner
        if gum_confirm "Activate recommended configuration ?"; then
            configure_termux
        fi
    else
        show_banner
        printf "${COLOR_BLUE}Activate recommended configuration ? (Y/n) : ${COLOR_RESET}"
        read -r -e -p "" -i "y" CHOICE
        # Delete previous line
        tput cuu1  # Move up one line
        tput el    # Erase to end of line
        [[ "$CHOICE" =~ ^[yY]$ ]] && configure_termux
    fi
}

#------------------------------------------------------------------------------
# SHELL INSTALLATION
#------------------------------------------------------------------------------
install_shell() {
    if $SHELL_CHOICE; then
        title_msg "❯ Shell configuration"
        if $USE_GUM; then
            SHELL_CHOICE=$(gum_choose "Choose the shell to install :" --selected="zsh" --height=5 "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choose the shell to install :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Enter the number of your choice : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "2" CHOICE
            tput sgr0

            # Delete selection menu
            tput cuu 7  # Move up 7 lines
            tput ed     # Erase from cursor to end of screen

            case $CHOICE in
                1) SHELL_CHOICE="bash" ;;
                2) SHELL_CHOICE="zsh" ;;
                3) SHELL_CHOICE="fish" ;;
                *) SHELL_CHOICE="bash" ;;
            esac
        fi

        case $SHELL_CHOICE in
            "bash")
                echo -e "${COLOR_BLUE}Bash selected${COLOR_RESET}"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    execute_command "pkg install -y zsh" "ZSH installation"
                else
                    success_msg="✓ Zsh already installed"
                fi
                # Installation de Oh My Zsh et autres configurations ZSH
                title_msg "❯ ZSH configuration"
                if $USE_GUM; then
                    if gum_confirm "Install Oh-My-Zsh ?"; then
                        execute_command "pkg install -y wget curl git unzip" "Dependencies installation"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Install Oh-My-Zsh ? (Y/n) : ${COLOR_RESET}"
                    # Define default value of CHOICE variable
                    read -r -e -p "" -i "y" CHOICE
                    tput cuu1
                    tput el
                    if [[ "$CHOICE" =~ ^[yY]$ ]]; then
                        execute_command "pkg install -y wget curl git unzip" "Dependencies installation"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Oh-My-Zsh installation"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/src/zshrc" "Default configuration" || error_msg "Default configuration impossible"

                if $USE_GUM; then
                    if gum_confirm "Install PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "PowerLevel10k installation"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Install custom prompt ?"; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/src/p10k.zsh" "Custom prompt installation" || error_msg "Custom prompt installation impossible"
                            echo -e "\n# For customizing the prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can customize the prompt by running 'p10k configure' or editing ~/.p10k.zsh.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Install PowerLevel10k ? (Y/n) : ${COLOR_RESET}"
                    read -r -e -p "" -i "y" CHOICE
                    tput cuu1
                    tput el
                    if [[ "$CHOICE" =~ ^[yY]$ ]]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" > /dev/null 2>&1 || true" "PowerLevel10k installation"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Install OhMyTermux prompt ? (Y/n) : ${COLOR_RESET}"
                        read -r -e -p "" -i "y" CHOICE
                        tput cuu1
                        tput el
                        if [[ "$CHOICE" =~ ^[yY]$ ]]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/src/p10k.zsh" "OhMyTermux prompt installation" || error_msg "OhMyTermux prompt installation impossible"
                            echo -e "\n# For customizing the prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can customize the prompt by running 'p10k configure' or editing ~/.p10k.zsh.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/src/aliases.zsh && \
                                mkdir -p $HOME/.config/OhMyTermux && \
                                curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/src/help.md)" "Default configuration" || error_msg "Default configuration impossible"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_RED}ZSH is not installed. Impossible to install plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                title_msg "❯ Fish configuration"
                execute_command "pkg install -y fish" "Fish installation"
                
                # Fish configuration directory creation
                #execute_command "mkdir -p $HOME/.config/fish/functions" "Fish directory creation"
                
                # Fisher installation without interactive session
                #execute_command "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o $HOME/.config/fish/functions/fisher.fish" "Fisher download"
                
                # Tide installation via Fisher in non-interactive mode
                #execute_command "fish -c 'source $HOME/.config/fish/functions/fisher.fish && fisher install IlanCosman/tide@v5'" "Tide installation"
                
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# ZSH PLUGINS SELECTION
#------------------------------------------------------------------------------
install_zsh_plugins() {
    local PLUGINS_TO_INSTALL=()

    subtitle_msg "❯ ZSH plugins installation"

    if $USE_GUM; then
        mapfile -t PLUGINS_TO_INSTALL < <(gum_choose_multi "Select with SPACE the plugins to install :" --height=8 --selected="Install all" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder" "Install all")
        if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" Install all "* ]]; then
            PLUGINS_TO_INSTALL=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
        fi
    else
        echo "Select the plugins to install (SEPARATED BY SPACES) :"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-alias-finder"
        info_msg "6) Install all"
        echo
        printf "${COLOR_GOLD}Enter the numbers of the plugins : ${COLOR_RESET}"
        tput setaf 3
        read -r -e -p "" -i "6" PLUGIN_CHOICES
        tput sgr0
        tput cuu 10
        tput ed
        for CHOICE in $PLUGIN_CHOICES; do
            case $CHOICE in
                1) PLUGINS_TO_INSTALL+=("zsh-autosuggestions") ;;
                2) PLUGINS_TO_INSTALL+=("zsh-syntax-highlighting") ;;
                3) PLUGINS_TO_INSTALL+=("zsh-completions") ;;
                4) PLUGINS_TO_INSTALL+=("you-should-use") ;;
                5) PLUGINS_TO_INSTALL+=("zsh-alias-finder") ;;
                6) PLUGINS_TO_INSTALL=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
                break
                ;;
            esac
        done
    fi

    for PLUGIN in "${PLUGINS_TO_INSTALL[@]}"; do
        install_plugin "$PLUGIN"
    done

    # Define necessary variables
    local ZSHRC="$HOME/.zshrc"
    local SELECTED_PLUGINS="${PLUGINS_TO_INSTALL[*]}"
    local HAS_COMPLETIONS=false
    local HAS_OHMYTERMIX=true

    # Check if zsh-completions is installed
    if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" zsh-completions "* ]]; then
        HAS_COMPLETIONS=true
    fi

    update_zshrc "$ZSHRC" "$SELECTED_PLUGINS" "$HAS_COMPLETIONS" "$HAS_OHMYTERMIX"
}

#------------------------------------------------------------------------------
# ZSH PLUGINS INSTALLATION
#------------------------------------------------------------------------------
install_plugin() {
    local PLUGIN_NAME=$1
    local PLUGIN_URL=""

    case $PLUGIN_NAME in
        "zsh-autosuggestions") PLUGIN_URL="https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        "zsh-syntax-highlighting") PLUGIN_URL="https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
        "zsh-completions") PLUGIN_URL="https://github.com/zsh-users/zsh-completions.git" ;;
        "you-should-use") PLUGIN_URL="https://github.com/MichaelAquilina/zsh-you-should-use.git" ;;
        "zsh-alias-finder") PLUGIN_URL="https://github.com/akash329d/zsh-alias-finder.git" ;;
    esac

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/$PLUGIN_NAME" ]; then
        execute_command "git clone '$PLUGIN_URL' '$HOME/.oh-my-zsh/custom/plugins/$PLUGIN_NAME' --quiet" "Installation of $PLUGIN_NAME"
    else
        info_msg "  $PLUGIN_NAME is already installed"
    fi
}

#------------------------------------------------------------------------------
# ZSH CONFIGURATION UPDATE
#------------------------------------------------------------------------------
update_zshrc() {
    local ZSHRC="$1"
    local SELECTED_PLUGINS="$2"
    local HAS_COMPLETIONS="$3"
    local HAS_OHMYTERMUX="$4"

    # Existing configuration deletion
    sed -i '/fpath.*zsh-completions\/src/d' "$ZSHRC"
    sed -i '/source \$ZSH\/oh-my-zsh.sh/d' "$ZSHRC"
    sed -i '/# For customizing the prompt/d' "$ZSHRC"
    sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/d' "$ZSHRC"
    sed -i '/# Source of custom aliases/d' "$ZSHRC"
    sed -i '/\[ -f.*aliases.*/d' "$ZSHRC"

    # Plugins section content creation
    local DEFAULT_PLUGINS="git command-not-found copyfile node npm timer vscode web-search z"
    local FILTERED_PLUGINS=$(echo "$SELECTED_PLUGINS" | sed 's/zsh-completions//g')
    local ALL_PLUGINS="$DEFAULT_PLUGINS $FILTERED_PLUGINS"

    local PLUGINS_SECTION="plugins=(\n"
    for PLUGIN in $ALL_PLUGINS; do
        PLUGINS_SECTION+="    $PLUGIN\n"
    done
    PLUGINS_SECTION+=")\n"

    # Plugins section deletion and replacement
    sed -i '/^plugins=(/,/)/d' "$ZSHRC"
    echo -e "$PLUGINS_SECTION" >> "$ZSHRC"

    # Add the configuration by section
    if [ "$HAS_COMPLETIONS" = "true" ]; then
        echo -e "\n# Load zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" >> "$ZSHRC"
    fi

    echo -e "\n# Load oh-my-zsh\nsource \$ZSH/oh-my-zsh.sh" >> "$ZSHRC"

    if [ "$HAS_OHMYTERMUX" = "true" ]; then
        echo -e "\n# For customizing the prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
    fi

    # Sourcing of centralized aliases
    echo -e "\n# Source of custom aliases\n[ -f \"$HOME/.config/OhMyTermux/aliases\" ] && . \"$HOME/.config/OhMyTermux/aliases\"" >> "$ZSHRC"
}

#------------------------------------------------------------------------------
# ADDITIONAL PACKAGES INSTALLATION
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        title_msg "❯ Additional packages configuration"
        if $USE_GUM; then
            PACKAGES=$(gum_choose_multi "Select with SPACE the packages to install :" --no-limit --height=18 --selected="nala,eza,bat,lf,fzf" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Install all")
        else
            echo "Select the packages to install (separated by SPACES) :"
            echo
            echo -e "${COLOR_BLUE}1) nala${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) eza${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) colorls${COLOR_RESET}"
            echo -e "${COLOR_BLUE}4) lsd${COLOR_RESET}"
            echo -e "${COLOR_BLUE}5) bat${COLOR_RESET}"
            echo -e "${COLOR_BLUE}6) lf${COLOR_RESET}"
            echo -e "${COLOR_BLUE}7) fzf${COLOR_RESET}"
            echo -e "${COLOR_BLUE}8) glow${COLOR_RESET}"
            echo -e "${COLOR_BLUE}9) tmux${COLOR_RESET}"
            echo -e "${COLOR_BLUE}10) python${COLOR_RESET}"
            echo -e "${COLOR_BLUE}11) nodejs${COLOR_RESET}"
            echo -e "${COLOR_BLUE}12) nodejs-lts${COLOR_RESET}"
            echo -e "${COLOR_BLUE}13) micro${COLOR_RESET}"
            echo -e "${COLOR_BLUE}14) vim${COLOR_RESET}"
            echo -e "${COLOR_BLUE}15) neovim${COLOR_RESET}"
            echo -e "${COLOR_BLUE}16) lazygit${COLOR_RESET}"
            echo -e "${COLOR_BLUE}17) open-ssh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}18) tsu${COLOR_RESET}"
            echo "19) Install all"
            echo            
            printf "${COLOR_GOLD}Enter the numbers of the packages : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "1 2 5 6 7" PACKAGE_CHOICES
            tput sgr0
            tput cuu 23
            tput ed
            PACKAGES=""
            for CHOICE in $PACKAGE_CHOICES; do
                case $CHOICE in
                    1) PACKAGES+="nala " ;;
                    2) PACKAGES+="eza " ;;
                    3) PACKAGES+="colorsls " ;;
                    4) PACKAGES+="lsd " ;;
                    5) PACKAGES+="bat " ;;
                    6) PACKAGES+="lf " ;;
                    7) PACKAGES+="fzf " ;;
                    8) PACKAGES+="glow " ;;
                    9) PACKAGES+="tmux " ;;
                    10) PACKAGES+="python " ;;
                    11) PACKAGES+="nodejs " ;;
                    12) PACKAGES+="nodejs-lts " ;;
                    13) PACKAGES+="micro " ;;
                    14) PACKAGES+="vim " ;;
                    15) PACKAGES+="neovim " ;;
                    16) PACKAGES+="lazygit " ;;
                    17) PACKAGES+="open-ssh " ;;
                    18) PACKAGES+="tsu " ;;
                    19) PACKAGES="nala eza colorsls lsd bat lf fzf glow tmux python nodejs nodejs-lts micro vim neovim lazygit open-ssh tsu" ;;
                esac
            done
        fi

        if [ -n "$PACKAGES" ]; then
            for PACKAGE in $PACKAGES; do
                execute_command "pkg install -y $PACKAGE" "Installation of $PACKAGE"

                # Add specific aliases after installation
                case $PACKAGE in
                    eza|bat|nala)
                        add_aliases_to_rc "$PACKAGE"
                        ;;
                esac
            done

            # Reload aliases to make them immediately available
            if [ -f "$HOME/.config/OhMyTermux/aliases" ]; then
                source "$HOME/.config/OhMyTermux/aliases"
            fi
        else
            echo -e "${COLOR_BLUE}No package selected.${COLOR_RESET}"
        fi
    fi
}

#------------------------------------------------------------------------------
# SPECIFIC ALIASES CONFIGURATION
#------------------------------------------------------------------------------
add_aliases_to_rc() {
    local PACKAGE=$1
    local ALIASES_FILE="$HOME/.config/OhMyTermux/aliases"
    
    case $PACKAGE in
        eza)
            cat >> "$ALIASES_FILE" << 'EOL'
# Alias eza
alias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"

EOL
            ;;
        bat)
            cat >> "$ALIASES_FILE" << 'EOL'
# Alias bat
alias cat="bat"

EOL
            ;;
        nala)
            cat >> "$ALIASES_FILE" << 'EOL'
# Alias nala
alias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"

EOL
            ;;
    esac
}

#------------------------------------------------------------------------------
# COMMON ALIASES CONFIGURATION
#------------------------------------------------------------------------------
common_alias() {
    # Centralized aliases file creation
    if [ ! -d "$HOME/.config/OhMyTermux" ]; then
        execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Configuration folder creation"
    fi

    ALIASES_FILE="$HOME/.config/OhMyTermux/aliases"

    cat > "$ALIASES_FILE" << 'EOL'
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Basic commands
alias h="history"
alias q="exit"
alias c="clear"
alias md="mkdir"
alias rm="rm -rf"
alias s="source"
alias n="nano"
alias cm="chmod +x"

# Configuration
alias bashrc="nano $HOME/.bashrc"
alias zshrc="nano $HOME/.zshrc"
alias aliases="nano $HOME/.config/OhMyTermux/aliases"
alias help="cat $HOME/.config/OhMyTermux/help.md"

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gcl="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"

# Termux
alias termux="termux-reload-settings"
alias storage="termux-setup-storage"
alias share="termux-share"
alias open="termux-open"
alias url="termux-open-url"
alias clip="termux-clipboard-set"
alias notification="termux-notification"
alias vibrate="termux-vibrate"
alias battery="termux-battery-status"
alias torch="termux-torch"
alias volume="termux-volume"
alias wifi="termux-wifi-connectioninfo"
alias tts="termux-tts-speak"
alias call="termux-telephony-call"
alias contact="termux-contact-list"
alias sms="termux-sms-send"
alias location="termux-location"

EOL

    # Add sourcing .bashrc
    echo -e "\n# Source of custom aliases\n[ -f \"$ALIASES_FILE\" ] && . \"$ALIASES_FILE\"" >> "$BASHRC"
    # The sourcing of .zshrc is done in update_zshrc()
}

#------------------------------------------------------------------------------
# FONT INSTALLATION
#------------------------------------------------------------------------------
install_font() {
    if $FONT_CHOICE; then
        title_msg "❯ Font configuration"
        if $USE_GUM; then
            FONT=$(gum_choose "Select the font to install :" --height=13 --selected="Default font" "Default font" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo "Select the font to install :"
            echo
            echo -e "${COLOR_BLUE}1) Default font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) CaskaydiaCove Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) FiraCode Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}4) Hack Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}5) JetBrainsMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}6) Meslo Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}7) RobotoMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}8) SourceCodePro Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}9) UbuntuMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}10) AnonymousPro Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}11) Terminus Nerd Font${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Enter the number of your choice : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "1" CHOICE
            tput sgr0
            tput cuu 15
            tput ed
            case $CHOICE in
                1) FONT="Default font" ;;
                2) FONT="CaskaydiaCove Nerd Font" ;;
                3) FONT="FiraCode Nerd Font" ;;
                4) FONT="Hack Nerd Font" ;;
                5) FONT="JetBrainsMono Nerd Font" ;;
                6) FONT="Meslo Nerd Font" ;;
                7) FONT="RobotoMono Nerd Font" ;;
                8) FONT="SourceCodePro Nerd Font" ;;
                9) FONT="UbuntuMono Nerd Font" ;;
                10) FONT="AnonymousPro Nerd Font" ;;
                11) FONT="Terminus Nerd Font" ;;
                *) FONT="Police par défaut" ;;
            esac
        fi

        case $FONT in
            "Default font")
                execute_command "curl -fLo \"$HOME/.termux/font.ttf\" 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf'" "Installation of the default font"
                termux-reload-settings
                ;;
            *)
                FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
                execute_command "curl -L -o $HOME/.termux/font.ttf \"$FONT_URL\"" "Installation of $FONT"
                termux-reload-settings
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# XFCE ENVIRONMENT INSTALLATION
#------------------------------------------------------------------------------
install_xfce() {
    if $XFCE_CHOICE; then
        local XFCE_VERSION
        title_msg "❯ XFCE configuration"
        if $USE_GUM; then
            if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install XFCE ?"; then
                # Version choice
                XFCE_VERSION=$(gum_choose "Select the XFCE version to install :" --height=5 --selected="recommended" \
                "minimal" \
                "recommended" \
                "custom")
            fi
        else
            printf "${COLOR_BLUE}Install XFCE ? (Y/n) : ${COLOR_RESET}"
            read -r -e -p "" -i "y" CHOICE
            if [[ "$CHOICE" =~ ^[yY]$ ]]; then
                echo -e "${COLOR_BLUE}Select the XFCE version to install :${COLOR_RESET}"
                echo
                echo "1) Minimal"
                echo "2) Recommended"
                echo "3) Custom"
                echo
                printf "${COLOR_GOLD}Enter your choice (1/2/3) : ${COLOR_RESET}"
                tput setaf 3
                read -r -e -p "" -i "2" CHOICE
                tput sgr0
                tput cuu 7
                tput ed
                case $CHOICE in
                    1) XFCE_VERSION="minimal" ;;
                    2) XFCE_VERSION="recommended" ;;
                    3) XFCE_VERSION="custom" ;;
                    *) XFCE_VERSION="recommended" ;;
                esac
            fi
        fi

        # Browser choice (except for the minimal version)
        local BROWSER_CHOICE="none"
        if [ "$XFCE_VERSION" != "minimal" ]; then
            if $USE_GUM; then
                BROWSER_CHOICE=$(gum_choose "Select a web browser :" --height=5 --selected="chromium" "chromium" "firefox" "none")
            else
                echo -e "${COLOR_BLUE}Select a web browser :${COLOR_RESET}"
                echo
                echo "1) Chromium (default)"
                echo "2) Firefox"
                echo "3) None"
                echo
                printf "${COLOR_GOLD}Enter your choice (1/2/3) : ${COLOR_RESET}"
                tput setaf 3
                read -r -e -p "" -i "1" CHOICE
                tput sgr0
                tput cuu 7
                tput ed
                case $CHOICE in
                    1) BROWSER_CHOICE="chromium" ;;
                    2) BROWSER_CHOICE="firefox" ;;
                    3) BROWSER_CHOICE="none" ;;
                    *) BROWSER_CHOICE="chromium" ;;
                esac
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Dependencies installation"

        PACKAGES=('wget' 'x11-repo' 'tur-repo' 'pulseaudio')

        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installation of $PACKAGE"
        done
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/xfce.sh" "Downloading XFCE script" || error_msg "Impossible to download XFCE script"
        execute_command "chmod +x xfce.sh" "Execution of XFCE script"
        
        if $USE_GUM; then
            ./xfce.sh --gum --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
        else
            ./xfce.sh --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
        fi
    fi
}

#------------------------------------------------------------------------------
# XFCE SCRIPTS INSTALLATION
#------------------------------------------------------------------------------
install_xfce_scripts() {
    title_msg "❯ XFCE scripts configuration"
    
    # Start script installation
    cat <<'EOF' > start
#!/bin/bash

# Activate PulseAudio on the network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Define the audio server
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1
EOF

    execute_command "chmod +x start && mv start $PREFIX/bin" "Start script installation"

    # Stop script installation
    cat <<'EOF' > "$PREFIX/bin/kill_termux_x11"
#!/bin/bash

# Checking the execution of processes in Termux or Proot
if pgrep -f 'apt|apt-get|dpkg|nala' > /dev/null; then
    zenity --info --text="A software is being installed in Termux or Proot. Please wait for these processes to finish before continuing."
    exit 1
fi

# Getting the process IDs of Termux-X11 and XFCE sessions
termux_x11_pid=$(pgrep -f /system/bin/app_process.*com.termux.x11.Loader)
xfce_pid=$(pgrep -f "xfce4-session")

# Stop the processes only if they exist
if [ -n "$termux_x11_pid" ]; then
    kill -9 "$termux_x11_pid" 2>/dev/null
fi

if [ -n "$xfce_pid" ]; then
    kill -9 "$xfce_pid" 2>/dev/null
fi

# Display dynamic message
if [ -n "$termux_x11_pid" ] || [ -n "$xfce_pid" ]; then
    zenity --info --text="Termux-X11 and XFCE sessions closed."
else
    zenity --info --text="Termux-X11 or XFCE session not found."
fi

# Stop the Termux application only if the PID exists
info_output=$(termux-info)
if pid=$(echo "$info_output" | grep -o 'TERMUX_APP_PID=[0-9]\+' | awk -F= '{print $2}') && [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null
fi

exit 0

EOF

    execute_command "chmod +x $PREFIX/bin/kill_termux_x11" "Stop script installation"


    # Shortcut creation
    mkdir -p "$PREFIX/share/applications"
    cat <<'EOF' > "$PREFIX/share/applications/kill_termux_x11.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Stop
Comment=
Exec=kill_termux_x11
Icon=shutdown
Categories=System;
Path=
StartupNotify=false
EOF

    execute_command "chmod +x $PREFIX/share/applications/kill_termux_x11.desktop" "Shortcut creation"
}

#------------------------------------------------------------------------------
# DEBIAN PROOT INSTALLATION
#------------------------------------------------------------------------------
install_proot() {
    if $PROOT_CHOICE; then
        title_msg "❯ Proot configuration"
        if $USE_GUM; then
            if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Debian Proot ?"; then
                execute_command "pkg install proot-distro -y" "Proot-distro installation"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/proot.sh" "Downloading Proot script" || error_msg "Impossible to download Proot script"
                execute_command "chmod +x proot.sh" "Execution of Proot script"
                ./proot.sh --gum
            fi
        else    
            printf "${COLOR_BLUE}Install Debian Proot ? (Y/n) : ${COLOR_RESET}"
            read -r -e -p "" -i "y" CHOICE
            tput cuu1
            tput el
            if [[ "$CHOICE" =~ ^[yY]$ ]]; then
                execute_command "pkg install proot-distro -y" "Proot-distro installation"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/proot.sh" "Downloading Proot script" || error_msg "Impossible to download Proot script"
                execute_command "chmod +x proot.sh" "Execution of Proot script"
                ./proot.sh
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# USERNAME RECOVERY
#------------------------------------------------------------------------------
get_username() {
    local USER_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    local USERNAME
    USERNAME=$(ls -1 "$USER_DIR" 2>/dev/null | grep -v '^$' | head -n 1)
    if [ -z "$USERNAME" ]; then
        echo "No user found" >&2
        return 1
    fi
    echo "$USERNAME"
}

#------------------------------------------------------------------------------
# UTILITIES INSTALLATION
#------------------------------------------------------------------------------
install_utils() {
    title_msg "❯ Utilities configuration"
    execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/utils.sh" "Downloading Utils script" || error_msg "Impossible to download Utils script"
    execute_command "chmod +x utils.sh" "Execution of Utils script"
    ./utils.sh

    if ! USERNAME=$(get_username); then
        error_msg "Impossible to recover the username."
        return 1
    fi

    BASHRC_PROOT="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian/home/${USERNAME}/.bashrc"
    if [ ! -f "$BASHRC_PROOT" ]; then
        error_msg "The .bashrc file does not exist for the user $USERNAME."
        execute_command "proot-distro login debian --shared-tmp --env DISPLAY=:1.0 -- touch \"$BASHRC_PROOT\"" "Bash Debian configuration"
    fi

    cat << "EOL" >> "$BASHRC_PROOT"

export DISPLAY=:1.0

alias zink="MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform"
alias hud="GALLIUM_HUD=fps"
alias ..="cd .."
alias l="ls -CF"
alias ll="ls -l"
alias la="ls -A"
alias q="exit"
alias s="source"
alias c="clear"
alias cat="bat"
alias apt="sudo nala"
alias install="sudo nala install -y"
alias update="sudo nala update"
alias upgrade="sudo nala upgrade -y"
alias remove="sudo nala remove -y"
alias list="nala list --upgradeable"
alias show="nala show"
alias search="nala search"
alias start='echo "Please run from Termux and not Debian proot."'
alias cm="chmod +x"
alias clone="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
alias g="git"
alias n="nano"
alias bashrc="nano \$HOME/.bashrc"
EOL

    USERNAME=$(get_username)

    TMP_FILE="${TMPDIR}/rc_content"
    touch "$TMP_FILE"

    cat << EOL >> "$TMP_FILE"

# Alias to connect to Debian Proot
alias debian="proot-distro login debian --shared-tmp --user ${USERNAME}"
EOL

    if [ -f "$BASHRC" ]; then
        cat "$TMP_FILE" >> "$BASHRC"
        success_msg "✓ Bash Termux configuration"
    else
        touch "$BASHRC" 
        cat "$TMP_FILE" >> "$BASHRC"
        success_msg "✓ Bash Termux creation and configuration"
    fi
    if [ -f "$ZSHRC" ]; then
        cat "$TMP_FILE" >> "$ZSHRC"
        success_msg "✓ ZSH Termux configuration"
    else
        touch "$ZSHRC"
        cat "$TMP_FILE" >> "$ZSHRC"
        success_msg "✓ ZSH Termux creation and configuration"
    fi
    rm "$TMP_FILE"
}

#------------------------------------------------------------------------------
# TERMUX-X11 INSTALLATION
#------------------------------------------------------------------------------
install_termux_x11() {
    if $X11_CHOICE; then
        title_msg "❯ Termux-X11 configuration"
        local FILE_PATH="$HOME/.termux/termux.properties"
    
        if [ ! -f "$FILE_PATH" ]; then
            mkdir -p "$HOME/.termux"
            cat <<EOL > "$FILE_PATH"
allow-external-apps = true
EOL
        else
            sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$FILE_PATH"
        fi
    fi

    local INSTALL_X11=false

    if $X11_CHOICE; then
        if $USE_GUM; then
            if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Termux-X11 ?"; then
                INSTALL_X11=true
            fi
        else
            printf "${COLOR_BLUE}Install Termux-X11 ? (Y/n) : ${COLOR_RESET}"
            read -r -e -p "" -i "n" choice
            tput cuu1
            tput el
            if [[ "$choice" =~ ^[yY]$ ]]; then
                INSTALL_X11=true
            fi
        fi

        if $INSTALL_X11; then
            local APK_URL="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
            local APK_FILE="$HOME/storage/downloads/termux-x11.apk"

            execute_command "wget \"$APK_URL\" -O \"$APK_FILE\"" "Termux-X11 download"

            if [ -f "$APK_FILE" ]; then
                termux-open "$APK_FILE"
                echo -e "${COLOR_BLUE}Please install the APK manually.${COLOR_RESET}"
                echo -e "${COLOR_BLUE}Once the installation is complete, press Enter to continue.${COLOR_RESET}"
                read -r
                rm "$APK_FILE"
            else
                error_msg "✗ Error during Termux-X11 installation"
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
show_banner

# Checking and installing necessary dependencies
if ! command -v tput &> /dev/null; then
    if $USE_GUM; then
        execute_command "pkg install -y ncurses-utils" "Installation des dépendances"
    else
        info_msg "Dependencies installation"
        pkg install -y ncurses-utils >/dev/null 2>&1
    fi
fi

# Checking if specific arguments have been provided
if [ "$SHELL_CHOICE" = true ] || [ "$PACKAGES_CHOICE" = true ] || [ "$FONT_CHOICE" = true ] || [ "$XFCE_CHOICE" = true ] || [ "$PROOT_CHOICE" = true ] || [ "$X11_CHOICE" = true ]; then
    if $EXECUTE_INITIAL_CONFIG; then
        initial_config
    fi
    if [ "$SHELL_CHOICE" = true ]; then
        install_shell
    fi
    if [ "$PACKAGES_CHOICE" = true ]; then
        install_packages
    fi
    if [ "$FONT_CHOICE" = true ]; then
        install_font
    fi
    if [ "$XFCE_CHOICE" = true ]; then
        install_xfce
    fi
    if [ "$XFCE_CHOICE" = true ] && [ "$PROOT_CHOICE" = false ]; then
        install_xfce_scripts
    fi
    if [ "$PROOT_CHOICE" = true ]; then
        install_proot
        install_utils
    fi
    if [ "$X11_CHOICE" = true ]; then
        install_termux_x11
    fi
else
    # Execute the complete installation if no specific argument is provided
    if $EXECUTE_INITIAL_CONFIG; then
        initial_config
    fi
    install_shell
    common_alias
    install_packages
    install_font
    install_xfce
    install_proot
    install_utils
    install_termux_x11
fi

# Cleaning and end message
title_msg "❯ Cleaning temporary files"
rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1
success_msg "✓ Installation scripts deletion"

# Shell reloading
if $USE_GUM; then
    if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Execute OhMyTermux ?"; then
        clear
        if [ "$SHELL_CHOICE" = "zsh" ]; then
            exec zsh -l
        else
            exec $SHELL_CHOICE
        fi
    else
        echo -e "${COLOR_BLUE}To use all features :${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Type : ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Or restart Termux${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Execute OhMyTermux ? (Y/n) : ${COLOR_RESET}"
    read -r -e -p "" -i "y" choice
    if [[ "$choice" =~ ^[yY]$ ]]; then
        clear
        if [ "$SHELL_CHOICE" = true ]; then
            exec zsh -l
        else
            exec $SHELL_CHOICE
        fi
    else
        tput cuu1
        tput el
        echo -e "${COLOR_BLUE}To use all features :${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Type : ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Or restart Termux${COLOR_RESET}"
    fi
fi