#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Configuration
USE_GUM=false
VERBOSE=false
LOG_FILE="$HOME/ohmytermux_install.log"
EXECUTE_INITIAL_CONFIG=true
SHELL_CHOICE=false
PACKAGES_CHOICE=false
PLUGIN_CHOICE=false
FONT_CHOICE=false
XFCE_CHOICE=false
SCRIPT_CHOICE=false

BASHRC="$PREFIX/etc/bash.bashrc"
ZSHRC="$HOME/.zshrc"

# Couleurs (compatibles avec Termux)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Fonctions utilitaires
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERREUR]${NC} $*" >&2 | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $*" | tee -a "$LOG_FILE"
}

bash_banner() {
    clear
    COLOR="\e[38;5;33m"
    TOP_BORDER="╔════════════════════════════════════════╗"
    BOTTOM_BORDER="╚════════════════════════════════════════╝"
    EMPTY_LINE="║                                        ║"
    TEXT_LINE="║              OHMYTERMUX                ║"
    echo
    echo -e "${COLOR}${TOP_BORDER}"
    echo -e "${COLOR}${EMPTY_LINE}"
    echo -e "${COLOR}${TEXT_LINE}"
    echo -e "${COLOR}${EMPTY_LINE}"
    echo -e "${COLOR}${BOTTOM_BORDER}\e[0m"
    echo
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

show_help() {
    cat << EOF
Usage: $0 [options]

Options:
    --gum, -g         Utiliser gum pour l'interface
    --shell, -s       Installer un shell
    --package, -pkg   Installer des paquets
    --plugin, -plg    Installer des plugins
    --font, -f        Installer une police
    --xfce, -x        Installer XFCE
    --script, -sc     Exécuter des scripts supplémentaires
    --noconf, -nc     Ne pas exécuter la configuration initiale
    --verbose, -v     Afficher les détails des opérations
    --help, -h        Afficher ce message d'aide
EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gum|-g) USE_GUM=true ;;
            --shell|-s) SHELL_CHOICE=true ;;
            --package|-pkg) PACKAGES_CHOICE=true ;;
            --plugin|-plg) PLUGIN_CHOICE=true ;;
            --font|-f) FONT_CHOICE=true ;;
            --xfce|-x) XFCE_CHOICE=true ;;
            --script|-sc) SCRIPT_CHOICE=true ;;
            --noconf|-nc) EXECUTE_INITIAL_CONFIG=false ;;
            --verbose|-v) VERBOSE=true ;;
            --help|-h) show_help ;;
            *) error "Option non reconnue : $1" ;;
        esac
        shift
    done

    if ! $SHELL_CHOICE && ! $PACKAGES_CHOICE && ! $PLUGIN_CHOICE && ! $FONT_CHOICE && ! $XFCE_CHOICE && ! $SCRIPT_CHOICE; then
        SHELL_CHOICE=true
        PACKAGES_CHOICE=true
        PLUGIN_CHOICE=true
        FONT_CHOICE=true
        XFCE_CHOICE=true
        SCRIPT_CHOICE=true
    fi
}

run_command() {
    local title="$1"
    shift
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="$title" -- "$@"
    else
        show_banner
        log "$title..."
        if $VERBOSE; then
            "$@" | tee -a "$LOG_FILE"
        else
            "$@" >> "$LOG_FILE" 2>&1
        fi
    fi
}

check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        run_command "Installation de gum" pkg update -y
        run_command "Installation de gum" pkg install gum -y
    fi
}

initial_config() {
    if $EXECUTE_INITIAL_CONFIG; then
        show_banner
        if $USE_GUM; then
            if gum confirm "Changer le répertoire de sources ?"; then
                run_command "Changement du répertoire de sources" termux-change-repo
            fi
        else
            echo -e "${BLUE}Changer le répertoire de sources ? (o/n)${NC}"
            read -r change_repo_choice
            if [ "$change_repo_choice" = "o" ]; then
                run_command "Changement du répertoire de sources" termux-change-repo
            fi
        fi

        termux_dir="$HOME/.termux"
        file_path="$termux_dir/colors.properties"
        if [ ! -f "$file_path" ]; then
            mkdir -p "$termux_dir"
            run_command "Création du fichier colors.properties" bash -c "cat > '$file_path' << EOL
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
EOL"
        fi

        run_command "Téléchargement police par défaut" curl -L -o "$HOME/.termux/font.ttf" https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf

        file_path="$termux_dir/termux.properties"
        if [ ! -f "$file_path" ]; then
            run_command "Création du fichier termux.properties" bash -c "cat > '$file_path' << EOL
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL"
        else
            run_command "Mise à jour du fichier termux.properties" sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$file_path"
            run_command "Mise à jour du fichier termux.properties" sed -i 's/^# use-black-ui = true/use-black-ui = true/' "$file_path"
            run_command "Mise à jour du fichier termux.properties" sed -i 's/^# bell-character = ignore/bell-character = ignore/' "$file_path"
            run_command "Mise à jour du fichier termux.properties" sed -i 's/^# fullscreen = true/fullscreen = true/' "$file_path"
        fi

        run_command "Création du fichier .hushlogin" touch .hushlogin
        run_command "Rechargement des paramètres Termux" termux-reload-settings

        show_banner
        if $USE_GUM; then
            if gum confirm "Autoriser l'accès au stockage ?"; then
                run_command "Configuration de l'accès au stockage" termux-setup-storage
            fi
        else
            echo -e "${BLUE}Autoriser l'accès au stockage ? (o/n)${NC}"
            read -r storage_choice
            if [ "$storage_choice" = "o" ]; then
                run_command "Configuration de l'accès au stockage" termux-setup-storage
            fi
        fi
    fi
}

install_shell() {
    if $SHELL_CHOICE; then
        show_banner
        if $USE_GUM; then
            shell_choice=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=5 --header="Choisissez le shell à installer :" "bash" "zsh" "fish")
        else
            echo -e "${BLUE}Choisissez le shell à installer :${NC}"
            echo -e "1) bash"
            echo -e "2) zsh"
            echo -e "3) fish"
            read -p "Entrez le numéro de votre choix : " choice
            case $choice in
                1) shell_choice="bash" ;;
                2) shell_choice="zsh" ;;
                3) shell_choice="fish" ;;
                *) shell_choice="bash" ;;
            esac
        fi

        case $shell_choice in
            "bash")
                log "Bash sélectionné, poursuite du script..."
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    run_command "Installation de ZSH" pkg install -y zsh
                fi

                show_banner
                if $USE_GUM; then
                    if gum confirm "Voulez-vous installer Oh My Zsh ?"; then
                        run_command "Installation des pré-requis" pkg install -y wget curl git unzip
                        run_command "Installation de Oh My Zsh" git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                        run_command "Copie du fichier zshrc" cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    echo -e "${BLUE}Voulez-vous installer Oh My Zsh ? (o/n)${NC}"
                    read -r choice
                    if [ "$choice" = "o" ]; then
                        run_command "Installation des pré-requis" pkg install -y wget curl git unzip
                        run_command "Installation de Oh My Zsh" git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                        run_command "Copie du fichier zshrc" cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                run_command "Téléchargement de la configuration zsh" curl -fLo "$ZSHRC" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/zshrc

                show_banner
                if $USE_GUM; then
                    if gum confirm "Voulez-vous installer PowerLevel10k ?"; then
                        run_command "Installation de PowerLevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
                        run_command "Configuration de PowerLevel10k" sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        show_banner
                        if gum confirm "Installer le prompt OhMyTermux ?"; then
                            run_command "Téléchargement prompt PowerLevel10k" curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            log "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                        fi
                    fi
                else
                    echo -e "${BLUE}Voulez-vous installer PowerLevel10k ? (o/n)${NC}"
                    read -r choice
                    if [ "$choice" = "o" ]; then
                        run_command "Installation de PowerLevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
                        run_command "Configuration de PowerLevel10k" sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        echo -e "${BLUE}Installer le prompt OhMyTermux ? (o/n)${NC}"
                        read -r choice
                        if [ "$choice" = "o" ]; then
                            run_command "Téléchargement prompt PowerLevel10k" curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            log "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                        fi
                    fi
                fi

                run_command "Téléchargement de la configuration" bash -c 'curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh && mkdir -p $HOME/.config/OhMyTermux && curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/help.md'

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    error "ZSH n'est pas installé. Impossible d'installer les plugins."
                fi
                run_command "Changement du shell par défaut" chsh -s zsh
                ;;
            "fish")
                run_command "Installation de Fish" pkg install -y fish
                # TODO : ajouter la configuration de Fish, de ses plugins et des alias (abbr)
                run_command "Changement du shell par défaut" chsh -s fish
                ;;
        esac
    fi
}

install_zsh_plugins() {
    if command -v zsh &> /dev/null; then
        show_banner
        if $USE_GUM; then
            PLUGINS=$(gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer")
        else
            echo -e "${BLUE}Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :${NC}"
            echo -e "1) zsh-autosuggestions"
            echo -e "2) zsh-syntax-highlighting"
            echo -e "3) zsh-completions"
            echo -e "4) you-should-use"
            echo -e "5) zsh-abbr"
            echo -e "6) zsh-alias-finder"
            echo -e "7) Tout installer"
            read -p "Entrez les numéros des plugins : " plugin_choices
            PLUGINS=""
            for choice in $plugin_choices; do
                case $choice in
                    1) PLUGINS+="zsh-autosuggestions " ;;
                    2) PLUGINS+="zsh-syntax-highlighting " ;;
                    3) PLUGINS+="zsh-completions " ;;
                    4) PLUGINS+="you-should-use " ;;
                    5) PLUGINS+="zsh-abbr " ;;
                    6) PLUGINS+="zsh-alias-finder " ;;
                    7) PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder" ;;
                esac
            done
        fi

        if [[ "$PLUGINS" == *"Tout installer"* ]]; then
            PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-abbr zsh-alias-finder"
        fi

        for PLUGIN in $PLUGINS; do
            show_banner
            case $PLUGIN in
                "zsh-autosuggestions")
                    run_command "Installation zsh-autosuggestions" git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
                    ;;
                "zsh-syntax-highlighting")
                    run_command "Installation zsh-syntax-highlighting" git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
                    ;;
                "zsh-completions")
                    run_command "Installation zsh-completions" git clone "https://github.com/zsh-users/zsh-completions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
                    ;;
                "you-should-use")
                    run_command "Installation you-should-use" git clone "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$HOME/.oh-my-zsh/custom/plugins/you-should-use"
                    ;;
                "zsh-abbr")
                    run_command "Installation zsh-abbr" git clone "https://github.com/olets/zsh-abbr" "$HOME/.oh-my-zsh/custom/plugins/zsh-abbr"
                    ;;
                "zsh-alias-finder")
                    run_command "Installation zsh-alias-finder" git clone "https://github.com/akash329d/zsh-alias-finder" "$HOME/.oh-my-zsh/custom/plugins/zsh-alias-finder"
                    ;;
            esac
        done
        update_zshrc
    fi
}

update_zshrc() {
    local zshrc="$HOME/.zshrc"
    cp "$zshrc" "${zshrc}.bak"

    existing_plugins=$(sed -n '/^plugins=(/,/)/p' "$zshrc" | grep -v '^plugins=(' | grep -v ')' | sed 's/^[[:space:]]*//' | tr '\n' ' ')

    local plugin_list="$existing_plugins"
    for plugin in $PLUGINS; do
        if [[ ! "$plugin_list" =~ "$plugin" ]]; then
            plugin_list+="$plugin "
        fi
    done

    run_command "Mise à jour du fichier zshrc" sed -i "/^plugins=(/,/)/c\plugins=($plugin_list)" "$zshrc"
}

add_aliases_to_rc() {
    local package=$1
    case $package in
        eza)
            run_command "Ajout des alias eza" bash -c 'echo -e "\nalias l=\"eza --icons\"
alias ls=\"eza -1 --icons\"
alias ll=\"eza -lF -a --icons --total-size --no-permissions --no-time --no-user\"
alias la=\"eza --icons -lgha --group-directories-first\"
alias lt=\"eza --icons --tree\"
alias lta=\"eza --icons --tree -lgha\"
alias dir=\"eza -lF --icons\"" >> $BASHRC'
            if [ -f "$ZSHRC" ]; then
                run_command "Ajout des alias eza (ZSH)" bash -c 'echo -e "\nalias l=\"eza --icons\"
alias ls=\"eza -1 --icons\"
alias ll=\"eza -lF -a --icons --total-size --no-permissions --no-time --no-user\"
alias la=\"eza --icons -lgha --group-directories-first\"
alias lt=\"eza --icons --tree\"
alias lta=\"eza --icons --tree -lgha\"
alias dir=\"eza -lF --icons\"" >> $ZSHRC'
            fi
            ;;
        bat)
            run_command "Ajout de l'alias bat" bash -c 'echo -e "\nalias cat=\"bat\"" >> $BASHRC'
            if [ -f "$ZSHRC" ]; then
                run_command "Ajout de l'alias bat (ZSH)" bash -c 'echo -e "\nalias cat=\"bat\"" >> $ZSHRC'
            fi
            ;;
        nala)
            run_command "Ajout des alias nala" bash -c 'echo -e "\nalias install=\"nala install -y\"
alias uninstall=\"nala remove -y\"
alias update=\"nala update\"
alias upgrade=\"nala upgrade -y\"
alias search=\"nala search\"
alias list=\"nala list --upgradeable\"
alias show=\"nala show\"" >> $BASHRC'
            if [ -f "$ZSHRC" ]; then
                run_command "Ajout des alias nala (ZSH)" bash -c 'echo -e "\nalias install=\"nala install -y\"
alias uninstall=\"nala remove -y\"
alias update=\"nala update\"
alias upgrade=\"nala upgrade -y\"
alias search=\"nala search\"
alias list=\"nala list --upgradeable\"
alias show=\"nala show\"" >> $ZSHRC'
            fi
            ;;
    esac

    # Ajout des alias généraux
    local aliases='alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias h="history"
alias q="exit"
alias c="clear"
alias md="mkdir"
alias rm="rm -rf"
alias s="source"
alias n="nano"
alias cm="chmod +x"
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m '\''mobile push'\'' && git push"'

    run_command "Ajout des alias généraux" bash -c "echo -e \"\n$aliases\" >> \"$BASHRC\""

    if [ -f "$ZSHRC" ]; then
        run_command "Ajout des alias généraux (ZSH)" bash -c "echo -e \"\n$aliases\" >> \"$ZSHRC\""
    fi
}

install_packages() {
    if $PACKAGES_CHOICE; then
        show_banner
        if $USE_GUM; then
            PACKAGES=$(gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=21 --header="Sélectionner avec espace les packages à installer :" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
        else
            echo -e "${BLUE}Sélectionner les packages à installer (séparés par des espaces) :${NC}"
            echo -e "1) nala"
            echo -e "2) eza"
            echo -e "3) colorls"   
            echo -e "4) lsd"         
            echo -e "5) bat"
            echo -e "6) lf"
            echo -e "7) fzf"
            echo -e "8) glow"
            echo -e "9) tmux"
            echo -e "10) python"
            echo -e "11) nodejs"
            echo -e "12) nodejs-lts"
            echo -e "13) micro"
            echo -e "14) vim"
            echo -e "15) neovim"
            echo -e "16) lazygit"
            echo -e "17) open-ssh"
            echo -e "18) tsu"
            echo -e "19) Tout installer"
            read -p "Entrez les numéros des packages : " package_choices
            PACKAGES=""
            for choice in $package_choices; do
                case $choice in
                    1) PACKAGES+="nala " ;;
                    2) PACKAGES+="eza " ;;
                    3) PACKAGES+="colorls " ;;
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
                    19) PACKAGES="nala eza colorls lsd bat lf fzf glow tmux python nodejs nodejs-lts micro vim neovim lazygit open-ssh tsu" ;;
                esac
            done
        fi

        installed_packages=""

        show_banner
        if [ -n "$PACKAGES" ]; then
            for PACKAGE in $PACKAGES; do
                run_command "Installation de $PACKAGE" pkg install -y $PACKAGE
                installed_packages+="Installé : $PACKAGE\n"
                show_banner 
                echo -e "$installed_packages"

                # Gestion des alias par package installé
                case $PACKAGE in
                    eza)
                        add_aliases_to_rc "eza"
                        ;;
                    bat)
                        add_aliases_to_rc "bat"
                        ;;
                    nala)
                        add_aliases_to_rc "nala"
                        ;;
                esac
            done
        else
            log "Aucun package sélectionné."
        fi
    fi
}

install_font() {
    if $FONT_CHOICE; then
        show_banner
        if $USE_GUM; then
            FONT=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=14 --header="Sélectionner la police à installer :" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo -e "${BLUE}Sélectionner la police à installer :${NC}"
            echo -e "1) Police par défaut"
            echo -e "2) CaskaydiaCove Nerd Font"
            echo -e "3) FiraMono Nerd Font"
            echo -e "4) JetBrainsMono Nerd Font"
            echo -e "5) Mononoki Nerd Font"
            echo -e "6) VictorMono Nerd Font"
            echo -e "7) RobotoMono Nerd Font"
            echo -e "8) DejaVuSansMono Nerd Font"
            echo -e "9) UbuntuMono Nerd Font"
            echo -e "10) AnonymousPro Nerd Font"
            echo -e "11) Terminus Nerd Font"
            read -p "Entrez le numéro de votre choix : " font_choice
            case $font_choice in
                1) FONT="Police par défaut" ;;
                2) FONT="CaskaydiaCove Nerd Font" ;;
                3) FONT="FiraMono Nerd Font" ;;
                4) FONT="JetBrainsMono Nerd Font" ;;
                5) FONT="Mononoki Nerd Font" ;;
                6) FONT="VictorMono Nerd Font" ;;
                7) FONT="RobotoMono Nerd Font" ;;
                8) FONT="DejaVuSansMono Nerd Font" ;;
                9) FONT="UbuntuMono Nerd Font" ;;
                10) FONT="AnonymousPro Nerd Font" ;;
                11) FONT="Terminus Nerd Font" ;;
                *) FONT="Police par défaut" ;;
            esac
        fi

        log "Installation de la police sélectionnée..."
        case $FONT in
            "CaskaydiaCove Nerd Font")
                run_command "Téléchargement de CaskaydiaCove Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/CaskaydiaCoveNerdFont-Regular.ttf"
                ;;
            "FiraMono Nerd Font")
                run_command "Téléchargement de FiraMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/FiraMono-Regular.ttf"
                ;;
            "JetBrainsMono Nerd Font")
                run_command "Téléchargement de JetBrainsMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/JetBrainsMono-Regular.ttf"
                ;;
            "Mononoki Nerd Font")
                run_command "Téléchargement de Mononoki Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/Mononoki-Regular.ttf"
                ;;
            "VictorMono Nerd Font")
                run_command "Téléchargement de VictorMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/VictorMono-Regular.ttf"
                ;;
            "RobotoMono Nerd Font")
                run_command "Téléchargement de RobotoMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/RobotoMonoNerdFont.ttf"
                ;;
            "DejaVuSansMono Nerd Font")
                run_command "Téléchargement de DejaVuSansMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/DejaVuSansMonoNerdFont.ttf"
                ;;
            "UbuntuMono Nerd Font")
                run_command "Téléchargement de UbuntuMono Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/UbuntuMonoNerdFont.ttf"
                ;;
            "AnonymousPro Nerd Font")
                run_command "Téléchargement de AnonymousPro Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/AnonymousProNerdFont.ttf"
                ;;
            "Terminus Nerd Font")
                run_command "Téléchargement de Terminus Nerd Font" curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/TerminusNerdFont.ttf"
                ;;
            "Police par défaut")
                log "Police déjà installée."
                ;;
            *)
                error "Police non reconnue : $FONT"
                ;;
        esac
    fi
}

#install_plugins() {
#    if $PLUGIN_CHOICE; then
#        # ... (le reste du code de install_plugins reste inchangé)
#    fi
#}

install_xfce() {
    if $XFCE_CHOICE; then
        show_banner
        if $USE_GUM; then
            if gum confirm --prompt.foreground="33" --selected.background="33" " Installer OhMyTermux XFCE ?"; then
                username=$(gum input --placeholder "Entrez votre nom d'utilisateur")
            else
                PACKAGES="$PACKAGES ncurses-utils"

                for PACKAGE in $PACKAGES; do
                    run_command "Installation de $PACKAGE" pkg install -y $PACKAGE
                done
                export PATH="$PATH:$PREFIX/bin"
                show_banner
                if gum confirm --prompt.foreground="33" --selected.background="33" " Exécuter OhMyTermux ?"; then
                    run_command "Rechargement des paramètres Termux" termux-reload-settings
                    rm -f install.sh
                    clear
                    exec $shell_choice
                else
                    run_command "Rechargement des paramètres Termux" termux-reload-settings
                    rm -f install.sh
                    log "OhMyTermux sera actif au prochain démarrage de Termux."
                fi
                exit 0
            fi
        else
            log " Installer OhMyTermux XFCE ? (o/n)"
            read choice
            if [ "$choice" = "n" ]; then
                PACKAGES="$PACKAGES ncurses-utils"

                for PACKAGE in $PACKAGES; do
                    run_command "Installation de $PACKAGE" pkg install -y $PACKAGE
                done
                export PATH="$PATH:$PREFIX/bin"
                show_banner
                log " Exécuter OhMyTermux ? (o/n)"
                read choice
                if [ "$choice" = "o" ]; then
                    run_command "Rechargement des paramètres Termux" termux-reload-settings
                    rm -f install.sh
                    clear
                    exec $shell_choice
                else
                    run_command "Rechargement des paramètres Termux" termux-reload-settings
                    rm -f install.sh
                    log "OhMyTermux sera actif au prochain démarrage de Termux."
                fi
                exit 0
            fi
        fi

        show_banner
        pkgs=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')

        show_banner
        run_command "Installation des pré-requis" pkg install ncurses-ui-libs && pkg uninstall dbus -y

        show_banner
        run_command "Mise à jour des paquets" pkg update -y

        show_banner
        run_command "Installation des paquets nécessaires" pkg install "${pkgs[@]}" -y

        show_banner
        run_command "Téléchargement des scripts" bash -c "
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/xfce.sh &&
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/proot.sh &&
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/utils.sh
        "
        run_command "Configuration des permissions des scripts" chmod +x *.sh

        show_banner
        if $USE_GUM; then
            run_command "Exécution de xfce.sh" ./xfce.sh --gum
            run_command "Exécution de proot.sh" ./proot.sh --gum
        else
            run_command "Exécution de xfce.sh" ./xfce.sh $username
            run_command "Exécution de proot.sh" ./proot.sh $username
        fi
        run_command "Exécution de utils.sh" ./utils.sh

        # Get username function for alias to execute Debian 
        run_command "Ajout de l'alias Debian" bash -c 'echo -e "\nfunction get_username() {
        user_dir=\"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/\"
        username=$(basename \"$user_dir\"/*)
        echo \$username
}

alias debian=\"proot-distro login debian --shared-tmp --user \$(get_username)\"" >> $BASHRC'

        if [ -f "$ZSHRC" ]; then
            run_command "Ajout de l'alias Debian (ZSH)" bash -c 'echo -e "\nfunction get_username() {
            user_dir=\"$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/\"
            username=$(basename \"$user_dir\"/*)
            echo \$username
}

alias debian=\"proot-distro login debian --shared-tmp --user \$(get_username)\"" >> $ZSHRC'
        fi
        # Termux-X11 
        show_banner
        if $USE_GUM; then
            if gum confirm --prompt.foreground="33" --selected.background="33" " Installer Termux-X11 ?"; then
                show_banner
                run_command "Téléchargement de Termux-X11 APK" wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
                run_command "Déplacement de l'APK" mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
                run_command "Ouverture de l'APK" termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk
                run_command "Suppression de l'APK" rm $HOME/storage/downloads/app-arm64-v8a-debug.apk
            fi
        else
            log " Installer Termux-X11 ? (o/n)"
            read choice
            if [ "$choice" = "o" ]; then
                show_banner
                run_command "Téléchargement de Termux-X11 APK" wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
                run_command "Déplacement de l'APK" mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
                run_command "Ouverture de l'APK" termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk
                run_command "Suppression de l'APK" rm $HOME/storage/downloads/app-arm64-v8a-debug.apk
            fi
        fi
    fi
}

main() {
    parse_arguments "$@"
    check_and_install_gum
    
    show_banner
    log "Début de l'installation de OhMyTermux"
    
    initial_config
    install_shell
    install_packages
    #install_plugins
    install_font
    install_xfce
    
    show_banner
    success "Installation de OhMyTermux terminée avec succès"
}

trap 'error "Une erreur est survenue. Consultez le fichier de log : $LOG_FILE"' ERR

main "$@"