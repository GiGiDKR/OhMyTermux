#!/bin/bash

#------------------------------------------------------------------------------
# MAIN CONTROL VARIABLES
#------------------------------------------------------------------------------
# Interactive interface with gum
USE_GUM=false

# Initial configuration
EXECUTE_INITIAL_CONFIG=true

# Detailed display of operations
VERBOSE=false

#------------------------------------------------------------------------------
# MODULE SELECTORS
#------------------------------------------------------------------------------
# Shell selection
SHELL_CHOICE=false

# Installation of additional packages
PACKAGES_CHOICE=false

# Installation of custom fonts
FONT_CHOICE=false

# Installation of the XFCE environment
XFCE_CHOICE=false

# Installation of Debian Proot
PROOT_CHOICE=false

# Installation of Termux-X11
X11_CHOICE=false

# Full installation without interactions
FULL_INSTALL=false

# Usage gum for interactions
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
COLOR_BLUE='\033[38;5;33m'  # Information
COLOR_GREEN='\033[38;5;82m' # Success
COLOR_GOLD='\033[38;5;220m' # Warning
COLOR_RED='\033[38;5;196m'  # Error
COLOR_RESET='\033[0m'       # Reset

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
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
    echo " --shell | -sh Shell installation module"
    echo " --package | -pkg Package installation module"
    echo " --font | -f Font installation module"
    echo " --xfce | -x XFCE installation module"
    echo " --proot | -p Debian Proot installation module"
    echo " --x11 | -x11 Termux-X11 Proot installation module"
    echo " --skip | -sk Skip initial configuration"
    echo " --uninstall| -u Uninstall Debian Proot"
    echo " --full | -f Install all modules without confirmation"
    echo " --help | -h Show this help message"
}

#------------------------------------------------------------------------------
# ARGUMENT MANAGEMENT
#------------------------------------------------------------------------------
for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --shell|-sh)
            SHELL_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --package|-pkg)
            PACKAGES_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --make)
            FONT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --xfce|-x)
            XFCE_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --proot|-p)
            PROOT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --x11|-x11)
            X11_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --skip|-sk)
            EXECUTE_INITIAL_CONFIG=false
            shift
            ;;
        --uninstall|-u)
            uninstall_proot
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            redirect=""
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
    esac
done

# Enabling all modules if --gum is the only argument
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
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $error_msg" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# DYNAMIC DISPLAY OF THE RESULT OF A COMMAND
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
        tput sc
        info_msg "$info_msg"

        if eval "$command $redirect"; then
            tput rc
            tput el
            success_msg "$success_msg"
        else
            tput rc
            tput el
            error_msg "$error_msg"
            log_error "$command"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# GUM CONFIRMATION
#------------------------------------------------------------------------------
gum_confirm() {
    local prompt="$1"
    if $FULL_INSTALL; then
        return 0
    else
        gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$prompt"
    fi
}

#------------------------------------------------------------------------------
# GUM SELECTION
#------------------------------------------------------------------------------
gum_choose() {
    local prompt="$1"
    shift
    local selected=""
    local options=()
    local height=10

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

    if $FULL_INSTALL; then
        if [ -n "$selected" ]; then
            echo "$selected"
        else
            echo "${options[@]}"
        fi
    else
        gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$height" --header="$prompt" --selected="$selected" "${options[@]}"
    fi
}

#------------------------------------------------------------------------------
# DISPLAYING THE BANNER IN TEXT MODE
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
        echo -e "${COLOR_BLUE}Installing gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

#------------------------------------------------------------------------------
# ERROR HANDLING
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERROR: Installation of OhMyTermux impossible."
        else
            echo -e "${COLOR_RED}ERROR: Unable to install OhMyTermux.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error message(s) above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# DISPLAYING THE BANNER IN GRAPHICAL MODE
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
            "OHMYTERMUX"
    else
        bash_banner
    fi
}

#------------------------------------------------------------------------------
# BACKUP FILES
#------------------------------------------------------------------------------
create_backups() {
    local backup_dir="$HOME/.config/OhMyTermux/backup"

    # Create backup directory
    execute_command "mkdir -p \"$backup_dir\"" "Create backup directory"

    # List of files to backup
    local files_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        "$0"
)

    # Copy files to backup directory
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            execute_command "cp \"$file\" \"$backup_dir/\"" "Backup of $(basename "$file")"
        fi
    done
}

#------------------------------------------------------------------------------
# CHANGING REPOSITORY
#------------------------------------------------------------------------------
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum_confirm "Change repository mirror?"; then
            termux-change-repo
        fi
    else
        printf "${COLOR_BLUE}Change repository mirror? (Y/n): ${COLOR_RESET}"
        read -r choice
        [[ "$choice" =~ ^[oO]$ ]] && termux-change-repo
    fi
}

#------------------------------------------------------------------------------
# STORAGE CONFIGURATION
#------------------------------------------------------------------------------
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        show_banner
        if $USE_GUM; then
        if gum_confirm "Allow access to storage?"; then
            termux-setup-storage
            fi
        else
            printf "${COLOR_BLUE}Allow access to storage? (Y/n): ${COLOR_RESET}"
            read -r choice
            [[ "$choice" =~ ^[oO]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# TERMUX CONFIGURATION
#------------------------------------------------------------------------------
configure_termux() {
    title_msg "❯ Configuring Termux"
    # Backup of existing files
    create_backups
    termux_dir="$HOME/.termux"
    # Configuring colors.properties
    file_path="$termux_dir/colors.properties"
    if [ ! -f "$file_path" ]; then
        execute_command "mkdir -p \"$termux_dir\" && cat > \"$file_path\" << 'EOL'
## Name: TokyoNight
# Special
foreground = #c0caf5
background = #1a1b26
cursor = #c0caf5
#Black/Grey
color0 = #15161e
color8 = #414868
#Red
color1 = #f7768e
color9 = #f7768e
# Green
color2 = #9ece6a
color10 = #9ece6a
#Yellow
color3 = #e0af68
color11 = #e0af68
# Blue
color4 = #7aa2f7
color12 = #7aa2f7
# Magenta
color5 = #bb9af7
color13 = #bb9af7
# Cyan
color6 = #7dcfff
color14 = #7dcfff
#White/Grey
color7 = #a9b1d6
color15 = #c0caf5
#Other
color16 = #ff9e64
color17 = #db4b4b
EOL" "Installing the TokyoNight theme"
    fi
    # Configuring termux.properties
    file_path="$termux_dir/termux.properties"
    if [ ! -f "$file_path" ]; then
        execute_command "cat > \"$file_path\" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Configuring Termux Properties"
    else
        execute_command "sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' \"$file_path\" && \
                        sed -i 's/^# use-black-ui = true/use-black-ui = true/' \"$file_path\" && \
                        sed -i 's/^# bell-character = ignore/bell-character = ignore/' \"$file_path\" && \
                        sed -i 's/^# fullscreen = true/fullscreen = true/' \"$file_path\"" "Configuring Termux"
    fi
    # Removing the banner from login
    execute_command "touch $HOME/.hushlogin" "Remove login banner"
}

#------------------------------------------------ -----------------------------
# INITIAL CONFIGURATION
#------------------------------------------------ -----------------------------
initial_config() {
    change_repo
    setup_storage

    if $USE_GUM; then
        show_banner
        if gum_confirm "Enable recommended configuration?"; then
            configure_termux
        fi
    else
        show_banner
        printf "${COLOR_BLUE}Enable recommended configuration? (Y/n): ${COLOR_RESET}"
        read -r choice
        if [ "$choice" = "oO" ]; then
            configure_termux
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION OF THE SHELL
#------------------------------------------------------------------------------
install_shell() {
    if $SHELL_CHOICE; then
        title_msg "❯ Shell configuration"
        if $USE_GUM; then
            shell_choice=$(gum_choose "Choose the shell to install:" --selected="zsh" --height=5 "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choose the shell to install:${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Enter the number of your choice: ${COLOR_RESET}"
            tput setaf 3
            read -r choice
            tput sgr0
            case $choice in
                1) shell_choice="bash" ;;
                2) shell_choice="zsh" ;;
                3) shell_choice="fish" ;;
                *) shell_choice="bash" ;;
            esac
        fi

        case $shell_choice in
            "bash")
                echo -e "${COLOR_BLUE}Bash selected${COLOR_RESET}"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    execute_command "pkg install -y zsh" "Installing ZSH"
                else
                    success_msg="✓ Zsh already installed"
                fi
                # Installing Oh My Zsh and other ZSH configurations
                title_msg "❯ Configuring ZSH"
                if $USE_GUM; then
                    if gum_confirm "Install Oh-My-Zsh?"; then
                        execute_command "pkg install -y wget curl git unzip" "Installing dependencies"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installing Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Install Oh-My-Zsh? (Y/n): ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[oO]$ ]]; then
                        execute_command "pkg install -y wget curl git unzip" "Installing dependencies"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installing Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/zshrc" "Default configuration" || error_msg "Unable to configure default"

                if $USE_GUM; then
                    if gum_confirm "Install PowerLevel10k?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installing PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Install OhMyTermux prompt?"; then                            
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Installing OhMyTermux prompt" || error_msg "Unable to install OhMyTermux prompt"
                            echo -e "\n# To customize the prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can configure the prompt by running 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Install PowerLevel10k ? (O/n) : ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[oO]$ ]]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Install OhMyTermux prompt? (O/n) : ${COLOR_RESET}"
                        read -r choice
                        if [[ "$choice" =~ ^[oO]$ ]]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Installing OhMyTermux prompt" || error_msg "Unable to install OhMyTermux prompt"
                            echo -e "\n# To customize the prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can configure the prompt by running 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/aliases.zsh && \
                                mkdir -p $HOME/.config/OhMyTermux && \
                                curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/help.md)" "Default Configuration" || error_msg "Failed to configure default configuration"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_RED}ZSH is not installed. Unable to install plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                title_msg "❯ Fish Configuration"
                execute_command "pkg install -y fish" "Installing Fish"
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# ZSH PLUGIN SELECTION
#------------------------------------------------------------------------------
install_zsh_plugins() {
    local plugins_to_install=()

    subtitle_msg "❯ Installing plugins"

    if $USE_GUM; then
        mapfile -t plugins_to_install < <(gum_choose "Select with SPACE the plugins to install:" --height=8 --selected="Install all" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder" "Install all")
        if [[ " ${plugins_to_install[*]} " == *" Install all "* ]]; then
            plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
        fi
    else
        echo "Select plugins to install (SPACE SEPARATED):"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-alias-finder"
        info_msg "6) Install all"
        echo
        printf "${COLOR_GOLD}Enter plugin numbers: ${COLOR_RESET}"
        tput setaf 3
        read -r plugin_choices
        tput sgr0
        for choice in $plugin_choices; do
            case $choice in
                1) plugins_to_install+=("zsh-autosuggestions") ;;
                2) plugins_to_install+=("zsh-syntax-highlighting") ;;
                3) plugins_to_install+=("zsh-completions") ;;
                4) plugins_to_install+=("you-should-use") ;;
                5) plugins_to_install+=("zsh-alias-finder") ;;
                6) plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
                break
                ;;
            esac
        done
    fi

    for plugin in "${plugins_to_install[@]}"; do
        install_plugin "$plugin"
    done

    # Set the necessary variables
    zshrc="$HOME/.zshrc"
    selected_plugins="${plugins_to_install[*]}"
    has_completions=false
    has_ohmytermux=true

    # Check if zsh-completions is installed
    if [[ " ${plugins_to_install[*]} " == *" zsh-completions "* ]]; then
        has_completions=true
    fi

    update_zshrc "$zshrc" "$selected_plugins" "$has_completions" "$has_ohmytermux"
}

#--------------------------------------------------------------------------------
# INSTALLING ZSH PLUGINS
#--------------------------------------------------------------------------------
install_plugin() {
    local plugin_name=$1
    local plugin_url=""

    case $plugin_name in
        "zsh-autosuggestions") plugin_url="https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        "zsh-syntax-highlighting") plugin_url="https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
        "zsh-completions") plugin_url="https://github.com/zsh-users/zsh-completions.git" ;;
        "you-should-use") plugin_url="https://github.com/MichaelAquilina/zsh-you-should-use.git" ;;
        "zsh-alias-finder") plugin_url="https://github.com/akash329d/zsh-alias-finder.git" ;;
    esac

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin_name" ]; then
        execute_command "git clone '$plugin_url' '$HOME/.oh-my-zsh/custom/plugins/$plugin_name' --quiet" "Installing $plugin_name"
    else
        info_msg "$plugin_name is already installed"
    fi
}

#------------------------------------------------------------------------------
# UPDATE ZSH CONFIGURATION
#------------------------------------------------------------------------------
update_zshrc() {
local zshrc="$1"
local selected_plugins="$2"
    local has_completions="$3"
    local has_ohmytermux="$4"

    # Remove existing configuration
    sed -i '/fpath.*zsh-completions\/src/d' "$zshrc"
    sed -i '/source \$ZSH\/oh-my-zsh.sh/d' "$zshrc"
    sed -i '/# To customize the prompt/d' "$zshrc"
    sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/d' "$zshrc"
    sed -i '/# Source of custom aliases/d' "$zshrc"
    sed -i '/\[ -f.*aliases.*/d' "$zshrc"

    # Creation of content for the plugins section
    local default_plugins="git command-not-found copyfile node npm timer vscode web-search z"
    local filtered_plugins=$(echo "$selected_plugins" | sed 's/zsh-completions//g')
    local all_plugins="$default_plugins $filtered_plugins"

    local plugins_section="plugins=(\n"
    for plugin in $all_plugins; do
        plugins_section+=" $plugin\n"
    done
    plugins_section+=")\n"

    # Removed and replaced the plugins section
    sed -i '/^plugins=(/,/)/d' "$zshrc"
    echo -e "$plugins_section" >> "$zshrc"

    # Added configuration by section
    if [ "$has_completions" = "true" ]; then
        echo -e "\n# Load zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" >> "$zshrc"
    fi

    echo -e "\n# Load oh-my-zsh\nsource \$ZSH/oh-my-zsh.sh" >> "$zshrc"

    if [ "$has_ohmytermux" = "true" ]; then
        echo -e "\n# To customize the prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
    fi

    # Sourcing centralized aliases
    echo -e "\n# Source custom aliases\n[ -f \"$HOME/.config/OhMyTermux/aliases\" ] && . \"$HOME/.config/OhMyTermux/aliases\"" >> "$zshrc"
}

#------------------------------------------------------------------------------
# INSTALLING ADDITIONAL PACKAGES
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        title_msg "❯ Package Configuration"
        if $USE_GUM; then
            PACKAGES=$(gum_choose "Select with space the packages to install:" --no-limit --height=18 --selected="nala,eza,bat,lf,fzf" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Install all")
        else
            echo "Select the packages to install (separated by spaces):"
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
            echo -e "${COLOR_BLUE}19) Install all${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Enter package numbers: ${COLOR_RESET}"
            tput setaf 3
            read -r package_choices
            tput sgr0
            PACKAGES=""
            for choice in $package_choices; do
                case $choice in
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
                execute_command "pkg install -y $PACKAGE" "Installing $PACKAGE"

                # Added specific aliases after installation
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
            echo -e "${COLOR_BLUE}No packages selected.${COLOR_RESET}"
        fi
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION OF SPECIFIC ALIAS
#------------------------------------------------------------------------------
add_aliases_to_rc() {
    local package=$1
    local aliases_file="$HOME/.config/OhMyTermux/aliases"

    case $package in
        eza)
            cat >> "$aliases_file" << 'EOL'
# Alias ​​eza
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
            cat >> "$aliases_file" << 'EOL'
# Alias ​​beats
aka cat="bat"

EOL
            ;;
        nala)
            cat >> "$aliases_file" << 'EOL'
# Alias ​​nala
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
# COMMON ALIAS CONFIGURATION
#------------------------------------------------------------------------------
common_alias() {    
    # Create the centralized alias file
    if [ ! -d "$HOME/.config/OhMyTermux" ]; then
        execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Creating the configuration folder"
    fi

    aliases_file="$HOME/.config/OhMyTermux/aliases"

    cat > "$aliases_file" << 'EOL'
# Navigation
alias ..=" cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../. ./.."

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

#Git
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

#Termux
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

    # Add .bashrc sourcing
    echo -e "\n# Source custom aliases\n[ -f \"$aliases_file\" ] && . \"$aliases_file\"" >> "$BASHRC"
    # Sourcing .zshrc is done in update_zshrc()
}

#------------------------------------------------------------------------------
# FONT INSTALLATION
#------------------------------------------------------------------------------
install_font() {
    if $FONT_CHOICE; then
        title_msg "❯ Font configuration"
        if $USE_GUM; then
            FONT=$(gum_choose "Select font to install:" --height=13 --selected="Default Font" "Default Font" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo "Select font to install:"
            echo
            echo -e "${COLOR_BLUE}1) Default Font${COLOR_RESET}"
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
            printf "${COLOR_GOLD}Enter the number of your choice: ${COLOR_RESET}"
            tput setaf 3
            read -r choice
            tput sgr0
            case $choice in
                1) FONT="Default font" ;;
                2 ) FONT="CaskaydiaCove Nerd Font" ;;
                3) FONT="FiraCode Nerd Font" ;;
                4) FONT="Hack Nerd Font" ;;
                5) FONT="JetBrainsMono Nerd Font" ;;
                6) FONT="Meslo Nerd Font" ;;
                7) FONT="RobotoMono Nerd Font" ;;
                8) FONT="SourceCodePro Nerd Font" ;;
                9) FONT="UbuntuMono Nerd Font" ;;
                10) FONT="AnonymousPro Nerd Font" ;;
                11) FONT="Terminus Nerd Font" ;;
                *) FONT="Default Font" ;;
            esac
        fi

        case $FONT in
            "Default Font")
                execute_command "curl -fLo \"$HOME/.termux/font.ttf \" 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf'" "Installing the default font"
                termux-reload-settings
                ;;
            *)
                font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font %20Complete%20Mono.ttf"
                execute_command "curl -L -o $HOME/.termux/font.ttf \"$font_url\"" "Installing $FONT"
                termux-reload-settings
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION OF THE XFCE ENVIRONMENT
#------------------------------------------------------------------------------
install_xfce() {
    if $XFCE_CHOICE; then
        title_msg "❯ Configuring XFCE"

        # Choice of version
        local xfce_version
        if $USE_GUM; then
            xfce_version=$(gum_choose "Select the version of XFCE to install:" --height=5 --selected="full" \
            "minimal" \
            "full" \
            "custom")
        else
            echo -e "${COLOR_BLUE} Select the version of XFCE to install:${COLOR_RESET}"
            echo -e "${COLOR_BLUE}1) Minimal (essential packages)${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) Full (all packages)${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) Custom (selection of components)${COLOR_RESET}"
            printf "${COLOR_GOLD}Enter your choice (1/2/3): ${COLOR_RESET}"
            tput setaf 3
            read -r choice
            tput sgr0
            case $choice in
                1) xfce_version="minimal" ;;
                2) xfce_version="full" ;;
                3) xfce_version="custom" ;;
                *) xfce_version="full" ;;
            esac
        fi

        # Browser selection (except for light version)
        local browser_choice="none"
        if [ "$xfce_version" != "minimal" ]; then
            if $USE_GUM; then
                browser_choice=$(gum_choose "Select a web browser:" --height=5 --selected="chromium" "chromium" "firefox" "none")
            else
                echo -e "${COLOR_BLUE}Select a web browser:${COLOR_RESET}"
                echo -e "${COLOR_BLUE}1) Chromium (default)${COLOR_RESET}"
                echo -e "${COLOR_BLUE}2) Firefox${COLOR_RESET}"
                echo -e "${COLOR_BLUE}3) None${COLOR_RESET}"
                printf "${COLOR_GOLD}Enter your choice (1/2/3): ${COLOR_RESET}"
                tput setaf 3
                read -r choice
                tput sgr0
                case $choice in
                    1) browser_choice="chromium" ;;
                    2) browser_choice="firefox" ;;
                    3) browser_choice="none" ;;
                    *) browser_choice="chromium" ;;
                esac
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installing dependencies"

        PACKAGES=('wget' 'x11-repo' 'tur-repo' 'pulseaudio')

        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installing $PACKAGE"
        done

        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce-dev.sh" "Downloading XFCE script" || error_msg "Unable to download XFCE script"
        execute_command "chmod +x xfce-dev.sh" "Executing the XFCE script"

        if $USE_GUM; then
            ./xfce-dev.sh --gum --version="$xfce_version" --browser="$browser_choice"
        else
            ./xfce-dev.sh --version="$xfce_version" --browser="$browser_choice"
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION OF XFCE SCRIPTS
#------------------------------------------------------------------------------
install_xfce_scripts() {
    title_msg "❯ Configuring XFCE scripts"

    # Installing the startup script
    cat <<'EOF' > start
#!/bin/bash

# Enable PulseAudio on the network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11:1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Set audio server
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1
EOF

    execute_command "chmod +x start && mv start $PREFIX/bin" "Installation of startup script"

    # Installing the shutdown script
    cat <<'EOF' > "$PREFIX/bin/kill_termux_x11"
#!/bin/bash

# Checking if processes are running in Termux or Proot
if pgrep -f 'apt|apt-get|dpkg|nala' > /dev/null; then
zenity --info --text="A software is being installed in Termux or Proot. Please wait for these processes to finish before continuing."
exit 1
fi

# Retrieve Termux-X11 and XFCE session process IDs
termux_x11_pid=$(pgrep -f /system/bin/app_process.*com.termux.x11.Loader)
xfce_pid=$(pgrep -f "xfce4-session")

# Stop processes only if they exist
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

    execute_command "chmod +x $PREFIX/bin/kill_termux_x11" "Installation of shutdown script"


    # Creation of the shortcut
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

    execute_command "chmod +x $PREFIX/share/applications/kill_termux_x11.desktop" "Creation of the shortcut"
}

#------------------------------------------------------------------------------
# INSTALLATION OF DEBIAN PROOT
#------------------------------------------------------------------------------
install_proot() {
    if $PROOT_CHOICE; then
        title_msg "❯ Configuring Proot"
        if $USE_GUM; then
            if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Debian Proot?"; then
                execute_command "pkg install proot-distro -y" "Installing proot-distro"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot-dev.sh" "Downloading Proot script" || error_msg "Unable to download Proot script"
                execute_command "chmod +x proot-dev.sh" "Executing the Proot script"
                ./proot-dev.sh --gum
            fi
        else
            printf "${COLOR_BLUE}Install Debian Proot? (Y/n): ${COLOR_RESET}"
            read -r choice
            if [[ "$choice" =~ ^[oO]$ ]]; then
                execute_command "pkg install proot-distro -y" "Installing proot-distro"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot-dev.sh" "Downloading Proot script" || error_msg "Unable to download Proot script"
                execute_command "chmod +x proot-dev.sh" "Executing Proot script"
                ./proot-dev.sh
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# USERNAME RECOVERY
#------------------------------------------------------------------------------
get_username() {
    local user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    local username
    username=$(ls -1 "$user_dir" 2>/dev/null | grep -v '^$' | head -n 1)
    if [ -z "$username" ]; then
        echo "No users found" >&2
        return 1
    fi
    echo "$username"
}

#------------------------------------------------------------------------------
# INSTALLING UTILITIES
#------------------------------------------------------------------------------
install_utils() {
    title_msg "❯ Configuring Utilities"
    execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/utils.sh" "Downloading Utils Script" || error_msg "Unable to download Utils Script"
    execute_command "chmod +x utils.sh" "Executing Utils Script"
    ./utils.sh

    if ! username=$(get_username); then
        error_msg "Unable to retrieve username."
        return 1
    fi

    bashrc_proot="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian/home/${username}/.bashrc"
    if [ ! -f "$bashrc_proot" ]; then
        error_msg "The .bashrc file does not exist for user $username."
        execute_command "proot-distro login debian --shared-tmp --env DISPLAY=:1.0 -- touch \"$bashrc_proot\"" "Debian Bash Configuration"
    fi

    cat << "EOL" >> "$bashrc_proot"

export DISPLAY=:1.0

alias zink="MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform"
alias hud="GALLIUM_HUD=fps"
alias..="cd.."
alias l="ls -CF"
alias ll="ls -l"
alias la="ls -A"
alias q="exit"
alias s="source"
alias c="clear"
aka cat="bat"
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

    username=$(get_username)

    tmp_file="${TMPDIR}/rc_content"
    touch "$tmp_file"

    cat << EOL >> "$tmp_file"

# Aliases to connect to Debian Proot
alias debian="proot-distro login debian --shared-tmp --user ${username}"
EOL

    if [ -f "$BASHRC" ]; then
        cat "$tmp_file" >> "$BASHRC"
        success_msg "✓ Bash Termux Configuration"
    else
        touch "$BASHRC"
        cat "$tmp_file" >> "$BASHRC"
        success_msg "✓ Creating and configuring Bash Termux"
    fi
    if [ -f "$ZSHRC" ]; then
        cat "$tmp_file" >> "$ZSHRC"
        success_msg "✓ ZSH Termux Configuration"
    else
        touch "$ZSHRC"
        cat "$tmp_file" >> "$ZSHRC"
        success_msg "✓ Creation and configuration ZSH Termux"
    fi
    rm "$tmp_file"
}

#------------------------------------------------------------------------------
# INSTALLATION OF TERMUX-X11
#------------------------------------------------------------------------------
install_termux_x11() {
    if $X11_CHOICE; then
        title_msg "❯ Configuring Termux-X11"
        local file_path="$HOME/.termux/termux.properties"

        if [ ! -f "$file_path" ]; then
            mkdir -p "$HOME/.termux"
            cat <<EOL > "$file_path"
allow-external-apps = true
EOL
        else
            sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$file_path"
        fi
    fi

    local install_x11=false

    if $X11_CHOICE; then
        if $USE_GUM; then
            if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Termux-X11?"; then
                install_x11=true
            fi
        else
            printf "${COLOR_BLUE}Install Termux-X11? (Y/n): ${COLOR_RESET}"
            read -r choice
            if [[ "$choice" =~ ^[oO]$ ]]; then
                install_x11=true
            fi
        fi

        if $install_x11; then
            local apk_url="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
            local apk_file="$HOME/storage/downloads/termux-x11.apk"

            execute_command "wget ​​\"$apk_url\" -O \"$apk_file\"" "Downloading Termux-X11"

            if [ -f "$apk_file" ]; then
                termux-open "$apk_file"
                echo -e "${COLOR_BLUE}Please install the APK manually.${COLOR_RESET}"
                echo -e "${COLOR_BLUE}Once the installation is complete, press Enter to continue.$ {COLOR_RESET}"
                read -r
                rm "$apk_file"
            else
                error_msg "✗ Error installing Termux-X11"
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
        execute_command "pkg install -y ncurses-utils" "Installing dependencies"
    else
            execute_command "pkg install -y ncurses-utils >/dev/null 2>&1" "Installing dependencies"
        fi
    fi

# Checking if specific arguments were provided
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
    # Run full install if no specific arguments are provided
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

# Cleanup and exit message
title_msg "❯ Cleaning up temporary files"
rm -f xfce-dev.sh proot-dev.sh utils.sh install-dev.sh >/dev/null 2>&1
success_msg "✓ Removing install scripts"

# Reloading shell
if $USE_GUM; then
    if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Run OhMyTermux?"; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}To use all features:${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Enter: ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Or restart Termux${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Run OhMyTermux? (Y/n): ${COLOR_RESET}"
    read -r choice
    if [[ "$choice" =~ ^[oO]$ ]]; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}To use all features:${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Enter: ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Or restart Termux${COLOR_RESET}"
    fi
fi