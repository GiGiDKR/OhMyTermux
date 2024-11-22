#!/bin/bash

#------------------------------------------------------------------------------
# MAIN CONTROL VARIABLES
#------------------------------------------------------------------------------
# Note: Activates interactive user interface with gum
USE_GUM=false

# Note: Determines if initial configuration should be executed
EXECUTE_INITIAL_CONFIG=true

# Note: Activates detailed operation display
VERBOSE=false

#------------------------------------------------------------------------------
# MODULE SELECTORS
#------------------------------------------------------------------------------
# Note: Activates shell installation and configuration (zsh/bash)
SHELL_CHOICE=false

# Note: Activates additional package installation
PACKAGES_CHOICE=false

# Note: Activates custom font installation
FONT_CHOICE=false
    
# Note: Activates XFCE environment and Debian Proot installation
XFCE_CHOICE=false

# Note: Activates complete installation of all modules without confirmation
FULL_INSTALL=false

# Note: Activates gum usage for all interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# CONFIGURATION FILES
#------------------------------------------------------------------------------
# Note: Path to Bash configuration file
BASHRC="$HOME/.bashrc"

# Note: Path to Zsh configuration file
ZSHRC="$HOME/.zshrc"

# TODO: Fish 
# Note: Path to Fish configuration file
#FISHRC="$HOME/.config/fish/config.fish"

#------------------------------------------------------------------------------
# COLOR CODES FOR DISPLAY
#------------------------------------------------------------------------------
# Note: Definition of ANSI codes for output colorization
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Success
COLOR_GOLD='\033[38;5;220m'   # Warning
COLOR_RED='\033[38;5;196m'    # Error
COLOR_RESET='\033[0m'         # Reset

# Note: Redirect configuration
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# HELP FUNCTION
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux Help"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g        Use gum for user interface"
    echo "  --verbose | -v    Display detailed output"
    echo "  --shell | -sh     Shell installation module"
    echo "  --package | -pkg  Package installation module"
    echo "  --font | -f       Font installation module"
    echo "  --xfce | -x       XFCE and Debian Proot installation module"
    echo "  --skip | -sk      Skip initial configuration"
    echo "  --uninstall| -u   Uninstall Debian Proot"
    echo "  --help | -h       Display this help message"
    echo "  --full | -f       Install all modules without confirmation"
}

#------------------------------------------------------------------------------
# ARGUMENT HANDLING
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
        --font)
            FONT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --xfce|-x)
            XFCE_CHOICE=true
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

# Activate all modules if --gum|-g is used as the only argument
if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
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
# ERROR LOGGING
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $error_msg" >> "$HOME/ohmytermux.log"
}

#------------------------------------------------------------------------------
# EXECUTION OF A COMMAND AND DISPLAY THE RESULT
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
# CONFIRMATION WITH GUM
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
# SELECTION WITH GUM
#------------------------------------------------------------------------------
gum_choose() {
    local prompt="$1"
    shift
    local selected=""
    local options=()
    local height=10  # Default value

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
# CHECK AND INSTALL GUM
#------------------------------------------------------------------------------
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installing gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

# FIXME: Move to main function
check_and_install_gum

#------------------------------------------------------------------------------
# ERROR HANDLING
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERROR: Unable to install OhMyTermux."
        else
            echo -e "${COLOR_RED}ERROR: Unable to install OhMyTermux.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error message(s) above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# DISPLAY THE BANNER IN GRAPHIC MODE
#------------------------------------------------------------------------------
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
# BACKUP FILES
#------------------------------------------------------------------------------
create_backups() {
    local backup_dir="$HOME/.backup"
    
    # Create backup directory
    execute_command "mkdir -p \"$backup_dir\"" "Creating ~/.backup directory"

    # List of files to backup
    local files_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        #"$0"
    )

    # Copy files to backup directory
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            execute_command "cp \"$file\" \"$backup_dir/\"" "Backing up $(basename "$file")"
        fi
    done
}

#------------------------------------------------------------------------------
# CHANGE REPOSITORY
#------------------------------------------------------------------------------
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum_confirm "Change repository mirror ?"; then
            termux-change-repo
        fi
    else
        printf "${COLOR_BLUE}Change repository mirror ? (Y/n): ${COLOR_RESET}"
        read -r choice
        [[ "$choice" =~ ^[yY]$ ]] && termux-change-repo
    fi
}

#------------------------------------------------------------------------------
# SETUP STORAGE
#------------------------------------------------------------------------------
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        show_banner
        if $USE_GUM; then
            if gum_confirm "Allow access to storage ?"; then
                termux-setup-storage
            fi
        else
            printf "${COLOR_BLUE}Allow access to storage ? (Y/n): ${COLOR_RESET}"
            read -r choice
            [[ "$choice" =~ ^[yY]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# CONFIGURE TERMUX
#------------------------------------------------------------------------------
configure_termux() {

    info_msg "❯ Termux Configuration"

    # Call backup function
    create_backups

    termux_dir="$HOME/.termux"

    # Configuration of colors.properties
    file_path="$termux_dir/colors.properties"
    if [ ! -f "$file_path" ]; then
        execute_command "mkdir -p \"$termux_dir\" && cat > \"$file_path\" << 'EOL'
## Name: TokyoNight
# Special
foreground = #c0caf5
background = #1a1b26
cursor = #c0caf5
# Black/Grey
color0 = #15161e
color8 = #414868
# Red
color1 = #f7768e
color9 = #f7768e
# Green
color2 = #9ece6a
color10 = #9ece6a
# Yellow
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
# White/Grey
color7 = #a9b1d6
color15 = #c0caf5
# Other
color16 = #ff9e64
color17 = #db4b4b
EOL" "Installing TokyoNight theme"
    fi

    # Configuration of termux.properties
    file_path="$termux_dir/termux.properties"
    if [ ! -f "$file_path" ]; then
        execute_command "cat > \"$file_path\" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Configuring Termux properties"
    fi
    
    # Remove login banner
    execute_command "touch $HOME/.hushlogin" "Removing login banner"
    # Download font
    execute_command "curl -fLo \"$HOME/.termux/font.ttf\" https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/font.ttf" "Downloading default font" || error_msg "Unable to download default font"
    termux-reload-settings
}

#------------------------------------------------------------------------------
# INITIAL CONFIGURATION
#------------------------------------------------------------------------------
initial_config() {
    change_repo
    setup_storage

    if $USE_GUM; then
        show_banner
        if gum_confirm "Enable recommended configuration ?"; then
            configure_termux
        fi
    else
        show_banner
        printf "${COLOR_BLUE}Enable recommended configuration ? (Y/n): ${COLOR_RESET}"
        read -r choice
        if [ "$choice" = "yY" ]; then
            configure_termux
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALL SHELL
#------------------------------------------------------------------------------
install_shell() {
    if $SHELL_CHOICE; then
        info_msg "❯ Shell configuration"
        if $USE_GUM; then
            shell_choice=$(gum_choose "Choose shell to install:" --selected="zsh" --height=5 "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choose shell to install:${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Enter your choice number: ${COLOR_RESET}"
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

                # Oh My Zsh installation and other ZSH configurations
                info_msg "❯ ZSH Configuration"
                if $USE_GUM; then
                    if gum_confirm "Install Oh-My-Zsh ?"; then
                        execute_command "pkg install -y wget curl git unzip" "Installing dependencies"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installing Oh-My-Zsh"
                        # FIXME: Optional ?
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Install Oh-My-Zsh ? (Y/n): ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[yY]$ ]]; then
                        execute_command "pkg install -y wget curl git unzip" "Installing dependencies"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installing Oh-My-Zsh"
                        # FIXME: Optional ?
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/zshrc" "Downloading configuration" || error_msg "Unable to download configuration"

                if $USE_GUM; then
                    if gum_confirm "Install PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installing PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Install OhMyTermux prompt ?"; then                            
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Downloading OhMyTermux prompt" || error_msg "Unable to download OhMyTermux prompt"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~\/.p10k.zsh ]] || source ~\/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can customize the prompt by running 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Install PowerLevel10k ? (Y/n): ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[yY]$ ]]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installing PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Install OhMyTermux prompt ? (Y/n): ${COLOR_RESET}"
                        read -r choice
                        if [[ "$choice" =~ ^[yY]$ ]]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Downloading OhMyTermux prompt" || error_msg "Unable to download OhMyTermux prompt"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~\/.p10k.zsh ]] || source ~\/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}You can customize the prompt by running 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/aliases.zsh && 
                    mkdir -p $HOME/.config/OhMyTermux && \
                    curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/help.md)" "Downloading configuration" || error_msg "Unable to download configuration"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_RED}ZSH is not installed. Unable to install plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                info_msg "❯ Fish Configuration"
                execute_command "pkg install -y fish" "Installing Fish"
                # TODO: Fish
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# SELECT PLUGINS ZSH 
#------------------------------------------------------------------------------
install_zsh_plugins() {
    local plugins_to_install=()
    if $USE_GUM; then
        mapfile -t plugins_to_install < <(gum_choose "Select plugins to install with SPACE:" --height=8 --selected="Install All" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder" "Install All")
        if [[ " ${plugins_to_install[*]} " == *" Install All "* ]]; then
            plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
        fi
    else
        echo "Select plugins to install (SEPARATED BY SPACES):"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-alias-finder"
        info_msg "6) Install All"
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

    # Define necessary variables
    local zshrc="$HOME/.zshrc"
    local selected_plugins="${plugins_to_install[*]}"
    local has_completions=false
    local has_ohmytermux=true  # Adjust based on your configuration

    # Check if zsh-completions is installed
    if [[ " ${plugins_to_install[*]} " == *" zsh-completions "* ]]; then
        has_completions=true
    fi

    update_zshrc "$zshrc" "$selected_plugins" "$has_completions" "$has_ohmytermux"
}

#------------------------------------------------------------------------------
# INSTALL ZSH PLUGINS
#------------------------------------------------------------------------------
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

    # Deletes actual configuration
    sed -i '/fpath.*zsh-completions\/src/d' "$zshrc"
    sed -i '/source \$ZSH\/oh-my-zsh.sh/d' "$zshrc"
    sed -i '/# To customize prompt/d' "$zshrc"
    sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/d' "$zshrc"

    # Create plugins section content
    local default_plugins="git command-not-found copyfile node npm timer vscode web-search z"
    local filtered_plugins=$(echo "$selected_plugins" | sed 's/zsh-completions//g')
    local all_plugins="$default_plugins $filtered_plugins"

    local plugins_section="plugins=(\n"
    for plugin in $all_plugins; do
        plugins_section+="    $plugin\n"
    done
    plugins_section+=")\n"

    # Delete and replace plugins section
    sed -i '/^plugins=(/,/)/d' "$zshrc"
    echo -e "$plugins_section" >> "$zshrc"

    # Add configuration by section
    if [ "$has_completions" = "true" ]; then
        echo -e "\n# Load zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" >> "$zshrc"
    fi

    echo -e "\n# Load oh-my-zsh\nsource \$ZSH/oh-my-zsh.sh" >> "$zshrc"

    if [ "$has_ohmytermux" = "true" ]; then
        echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
    fi
}

#------------------------------------------------------------------------------
# INSTALL ADDITIONAL PACKAGES
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        info_msg "❯ Package configuration"
        if $USE_GUM; then
            PACKAGES=$(gum_choose "Select packages to install with SPACE:" --no-limit --height=12 --selected="nala,eza,bat,lf,fzf,python" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Install All")
        else
            echo "Select packages to install (separated by spaces):"
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
            echo "19) Install All"
            echo            
            printf "${COLOR_GOLD}Enter the numbers of the packages: ${COLOR_RESET}"
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
            echo -e "${COLOR_BLUE}No packages selected.${COLOR_RESET}"
        fi
    fi
}

#------------------------------------------------------------------------------
# SPECIFIC ALIASES CONFIGURATION
#------------------------------------------------------------------------------
add_aliases_to_rc() {
    local package=$1
    local aliases_file="$HOME/.config/OhMyTermux/aliases"
    
    case $package in
        eza)
            cat >> "$aliases_file" << 'EOL'

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
            cat >> "$aliases_file" << 'EOL'

# Alias bat
alias cat="bat"
EOL
            ;;
        nala)
            cat >> "$aliases_file" << 'EOL'

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
    # Create centralized alias file
    execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Creating configuration directory"
    
    aliases_file="$HOME/.config/OhMyTermux/aliases"
    
    cat > "$aliases_file" << 'EOL'
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Base commands
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

# Git
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
EOL

    # Add sourcing to .bashrc
    echo -e "\n# Source of custom aliases\n[ -f \"$aliases_file\" ] && . \"$aliases_file\"" >> "$BASHRC"

    # Add sourcing to .zshrc if existing
    if [ -f "$ZSHRC" ]; then
        echo -e "\n# Source of custom aliases\n[ -f \"$aliases_file\" ] && . \"$aliases_file\"" >> "$ZSHRC"
    fi
}

#------------------------------------------------------------------------------
# INSTALL FONT
#------------------------------------------------------------------------------
install_font() {
    if $FONT_CHOICE; then
        info_msg "❯ Font configuration"
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
                1) FONT="Default Font" ;;
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
                *) FONT="Default Font" ;;
            esac
        fi

        case $FONT in
            "Default Font")
                success_msg "✓ Default font installed"
                ;;
            *)
                font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
                execute_command "curl -L -o $HOME/.termux/font.ttf \"$font_url\"" "Installing $FONT"
                termux-reload-settings
                ;;
        esac

    fi
}

# Note: Global variable to track if XFCE or Proot has been installed
INSTALL_UTILS=false

#------------------------------------------------------------------------------
# INSTALL XFCE
#------------------------------------------------------------------------------
install_xfce() {
    if $XFCE_CHOICE; then
        info_msg "❯ XFCE Configuration"
        if $USE_GUM; then
            if ! gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install XFCE ?"; then
                return
            fi
        else
            printf "${COLOR_BLUE}Install XFCE ? (Y/n): ${COLOR_RESET}"
            read -r choice
            if [[ "$choice" =~ ^[yY]$ ]]; then
                return
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installing dependencies"

        PACKAGES=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')
    
        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installing $PACKAGE"
        done
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce.sh" "Downloading XFCE script" || error_msg "Unable to download XFCE script"
        execute_command "chmod +x xfce.sh" "Setting execution permissions"
        
        if $USE_GUM; then
            ./xfce.sh --gum
        else
            ./xfce.sh
        fi
        
        INSTALL_UTILS=true
    fi
}

#------------------------------------------------------------------------------
# INSTALL DEBIAN PROOT
#------------------------------------------------------------------------------
install_proot() {
    info_msg "❯ Proot Configuration"
    if $USE_GUM; then
        if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Debian Proot ?"; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot.sh" "Downloading Proot script" || error_msg "Unable to download Proot script"
            execute_command "chmod +x proot.sh" "Setting execution permissions"
            ./proot.sh --gum
            INSTALL_UTILS=true
        fi
    else    
        printf "${COLOR_BLUE}Install Debian Proot ? (Y/n): ${COLOR_RESET}"
        read -r choice
        if [[ "$choice" =~ ^[yY]$ ]]; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot.sh" "Downloading Proot script" || error_msg "Unable to download Proot script"
            execute_command "chmod +x proot.sh" "Setting execution permissions"
            ./proot.sh
            INSTALL_UTILS=true
        fi
    fi
}

#------------------------------------------------------------------------------
# GET USERNAME
#------------------------------------------------------------------------------
get_username() {
    local user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    local username
    username=$(ls -1 "$user_dir" 2>/dev/null | grep -v '^$' | head -n 1)
    if [ -z "$username" ]; then
        echo "No user found" >&2
        return 1
    fi
    echo "$username"
}

#------------------------------------------------------------------------------
# INSTALL UTILITIES
#------------------------------------------------------------------------------
install_utils() {
    if [ "$INSTALL_UTILS" = true ]; then
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/utils.sh" "Downloading Utils script" || error_msg "Unable to download Utils script"
        execute_command "chmod +x utils.sh" "Setting execution permissions"
        ./utils.sh

        if ! username=$(get_username); then
            error_msg "Unable to get username."
            return 1
        fi

        bashrc_proot="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian/home/${username}/.bashrc"
        if [ ! -f "$bashrc_proot" ]; then
            error_msg "The .bashrc file doesn't exist for user $username."
            execute_command "proot-distro login debian --shared-tmp --env DISPLAY=:1.0 -- touch \"$bashrc_proot\"" "Creating .bashrc file"
        fi

        cat << "EOL" >> "$bashrc_proot"
export DISPLAY=:1.0

alias zink="MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform"
alias hud="GALLIUM_HUD=fps"
alias ..="cd .."
alias q="exit"
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
alias bashrc="nano \$HOME/.bashrc"
EOL

        username=$(get_username)

        tmp_file="${TMPDIR}/rc_content"
        touch "$tmp_file"

        cat << EOL >> "$tmp_file"

# Alias to connect to Debian Proot
alias debian="proot-distro login debian --shared-tmp --user ${username}"
EOL

        if [ -f "$BASHRC" ]; then
            cat "$tmp_file" >> "$BASHRC"
            success_msg "✓ Configuration of .bashrc termux"
        else
            touch "$BASHRC" 
            cat "$tmp_file" >> "$BASHRC"
            success_msg "✓ Creation and configuration of .bashrc termux"
        fi

        if [ -f "$ZSHRC" ]; then
            cat "$tmp_file" >> "$ZSHRC"
            success_msg "✓ Configuration of .zshrc termux"
        else
            touch "$ZSHRC"
            cat "$tmp_file" >> "$ZSHRC"
            success_msg "✓ Creation and configuration of .zshrc termux"
        fi

        rm "$tmp_file"
    fi
}

#------------------------------------------------------------------------------
# INSTALL TERMUX-X11
#------------------------------------------------------------------------------
install_termux_x11() {
    info_msg "❯ Termux-X11 Configuration"
    local file_path="$HOME/.termux/termux.properties"

    if [ ! -f "$file_path" ]; then
        mkdir -p "$HOME/.termux"
        cat <<EOL > "$file_path"
allow-external-apps = true
EOL
    else
        sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$file_path"
    fi

    local install_x11=false

    if $USE_GUM; then
        if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Install Termux-X11 ?"; then
            install_x11=true
        fi
    else
        printf "${COLOR_BLUE}Install Termux-X11 ? (Y/n): ${COLOR_RESET}"
        read -r choice
        if [[ "$choice" =~ ^[yY]$ ]]; then
            install_x11=true
        fi
    fi

    if $install_x11; then
        local apk_url="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
        local apk_file="$HOME/storage/downloads/termux-x11.apk"

        execute_command "wget \"$apk_url\" -O \"$apk_file\"" "Downloading Termux-X11"

        if [ -f "$apk_file" ]; then
            termux-open "$apk_file"
            echo -e "${COLOR_BLUE}Please install the APK manually.${COLOR_RESET}"
            echo -e "${COLOR_BLUE}Once installation is complete, press Enter to continue.${COLOR_RESET}"
            read -r
            rm "$apk_file"
        else
            error_msg "✗ Error during Termux-X11 installation"
        fi
    fi
}

#------------------------------------------------------------------------------
# MAIN FUNCTION
#------------------------------------------------------------------------------
show_banner

# Note: Installation dependencies
if $USE_GUM; then
    execute_command "pkg install -y ncurses-utils" "Installation dependencies"
else
    execute_command "pkg install -y ncurses-utils >/dev/null 2>&1" "Installation dependencies"
fi

# Note: Check if specific arguments have been provided
if [ "$SHELL_CHOICE" = true ] || [ "$PACKAGES_CHOICE" = true ] || [ "$FONT_CHOICE" = true ] || [ "$XFCE_CHOICE" = true ]; then
    # Execute only the requested functions
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
        install_proot
        install_utils
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

# Note: Cleaning temporary files
info_msg "❯ Cleaning temporary files"
rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1
success_msg "✓ Removing installation scripts"

# Note: Reloading the shell
if $USE_GUM; then
    if gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" "Run OhMyTermux (reload the shell) ?"; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}For use all the functions, you can type :${COLOR_RESET}"
        echo -e "${COLOR_GREEN}exec zsh -l${COLOR_RESET} ${COLOR_BLUE}(recommended - reload the shell)${COLOR_RESET}"
        echo -e "${COLOR_GREEN}source ~/.zshrc${COLOR_RESET} ${COLOR_BLUE}(reload only .zshrc)${COLOR_RESET}"
        echo -e "${COLOR_BLUE}Or restart Termux${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Run OhMyTermux (reload the shell) ? (Y/n): ${COLOR_RESET}"
    read -r choice
    if [[ "$choice" =~ ^[yY]$ ]]; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}OhMyTermux will be active on next Termux startup.${COLOR_RESET}"
    fi
fi