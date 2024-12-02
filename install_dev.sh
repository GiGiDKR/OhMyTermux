#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES DE CONTROLE PRINCIPALE
#------------------------------------------------------------------------------
# Interface interactive avec gum
USE_GUM=false

# Configuration initiale
EXECUTE_INITIAL_CONFIG=true

# Affichage détaillé des opérations
VERBOSE=false

#------------------------------------------------------------------------------
# SELECTEURS DE MODULES
#------------------------------------------------------------------------------
# Selection du shell
SHELL_CHOICE=false

# Installation de paquets additionnels
PACKAGES_CHOICE=false

# Installation de polices personnalisées
FONT_CHOICE=false
    
# Installation de l'environnement XFCE
XFCE_CHOICE=false

# Installation de Debian Proot
PROOT_CHOICE=false

# Installation de Termux-X11
X11_CHOICE=false

# Installation complète sans interactions
FULL_INSTALL=false

# Utilisation de gum pour les interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# FICHIERS DE CONFIGURATION
#------------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
FISHRC="$HOME/.config/fish/config.fish"

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
    REDIRECT="> /dev/null 2>&1"
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
    echo "  --shell | -sh     Module d'installation du shell"
    echo "  --package | -pkg  Module d'installation des packages"
    echo "  --font | -f       Module d'installation de la police"
    echo "  --xfce | -x       Module d'installation de XFCE"
    echo "  --proot | -p      Module d'installation de Debian Proot"
    echo "  --x11 | -x11      Module d'installation de Termux-X11"
    echo "  --skip | -sk      Ignorer la configuration initiale"
    echo "  --uninstall| -u   Désinstallation de Debian Proot"
    echo "  --full | -f       Installer tous les modules sans confirmation"
    echo "  --help | -h       Afficher ce message d'aide"
}

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
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

# Activation de tous les modules si --gum est le seul argument
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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $ERROR_MSG" >> "$HOME/.config/OhMyTermux/install.log"
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
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            gum style "$SUCCESS_MSG" --foreground 82
        else
            gum style "$ERROR_MSG" --foreground 196
            log_error "$COMMAND"
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
            error_msg "$ERROR_MSG"
            log_error "$COMMAND"
            return 1
        fi
    fi
}

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

    if $FULL_INSTALL; then
        if [ -n "$SELECTED" ]; then
            echo "$SELECTED"
        else
            # Retourner la première option par défaut
            echo "${OPTIONS[0]}"
        fi
    else
        gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
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
# INSTALLATION DE GUM
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

trap finish EXIT

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
# SAUVEGARDE DES FICHIERS
#------------------------------------------------------------------------------
create_backups() {
    local BACKUP_DIR="$HOME/.config/OhMyTermux/backup"
    
    # Création du répertoire de sauvegarde
    execute_command "mkdir -p \"$BACKUP_DIR\"" "Création du répertoire de sauvegarde"

    # Liste des fichiers à sauvegarder
    local FILES_TO_BACKUP=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        #"$0"
    )

    # Copie des fichiers dans le répertoire de sauvegarde
    for FILE in "${FILES_TO_BACKUP[@]}"; do
        if [ -f "$FILE" ]; then
            execute_command "cp \"$FILE\" \"$BACKUP_DIR/\"" "Sauvegarde de $(basename "$FILE")"
        fi
    done
}

#------------------------------------------------------------------------------
# CHANGEMENT DE DEPOT
#------------------------------------------------------------------------------
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum_confirm "Changer le miroir des dépôts ?"; then
            termux-change-repo
        fi
    else
        printf "${COLOR_BLUE}Changer le miroir des dépôts ? (O/n) : ${COLOR_RESET}"
        read -r CHOICE
        [[ "$CHOICE" =~ ^[oO]$ ]] && termux-change-repo
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION DU STOCKAGE
#------------------------------------------------------------------------------
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        show_banner
        if $USE_GUM; then
            if gum_confirm "Autoriser l'accès au stockage ?"; then
                termux-setup-storage
            fi
        else
            printf "${COLOR_BLUE}Autoriser l'accès au stockage ? (O/n) : ${COLOR_RESET}"
            read -r CHOICE
            [[ "$CHOICE" =~ ^[oO]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION DE TERMUX
#------------------------------------------------------------------------------
configure_termux() {
    title_msg "❯ Configuration de Termux"
    # Sauvegarde des fichiers existants
    create_backups
    TERMUX_DIR="$HOME/.termux"
    # Configuration de colors.properties
    FILE_PATH="$TERMUX_DIR/colors.properties"
    if [ ! -f "$FILE_PATH" ]; then
        execute_command "mkdir -p \"$TERMUX_DIR\" && cat > \"$FILE_PATH\" << 'EOL'
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
EOL" "Installation du thème TokyoNight"
    fi
    # Configuration de termux.properties
    FILE_PATH="$TERMUX_DIR/termux.properties"
    if [ ! -f "$FILE_PATH" ]; then
        execute_command "cat > \"$FILE_PATH\" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Configuration des propriétés Termux"
    else
        execute_command "sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' \"$FILE_PATH\" && \
        sed -i 's/^# use-black-ui = true/use-black-ui = true/' \"$FILE_PATH\" && \
        sed -i 's/^# bell-character = ignore/bell-character = ignore/' \"$FILE_PATH\" && \
        sed -i 's/^# fullscreen = true/fullscreen = true/' \"$FILE_PATH\"" "Configuration de Termux"
    fi
    # Suppression de la bannière de connexion
    execute_command "touch $HOME/.hushlogin" "Suppression de la bannière de connexion"
}

#------------------------------------------------------------------------------
# CONFIGURATION INITIALE
#------------------------------------------------------------------------------
initial_config() {
    change_repo
    setup_storage

    if $USE_GUM; then
        show_banner
        if gum_confirm "Activer la configuration recommandée ?"; then
            configure_termux
        fi
    else
        show_banner
        printf "${COLOR_BLUE}Activer la configuration recommandée ? (O/n) : ${COLOR_RESET}"
        read -r CHOICE
        if [ "$CHOICE" = "oO" ]; then
            configure_termux
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DU SHELL
#------------------------------------------------------------------------------
install_shell() {
    if $SHELL_CHOICE; then
        title_msg "❯ Configuration du shell"
        if $USE_GUM; then
            SHELL_CHOICE=$(gum_choose "Choisissez le shell à installer :" --selected="zsh" --height=5 "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choisissez le shell à installer :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
            tput setaf 3
            read -r CHOICE
            tput sgr0
            case $CHOICE in
                1) SHELL_CHOICE="bash" ;;
                2) SHELL_CHOICE="zsh" ;;
                3) SHELL_CHOICE="fish" ;;
                *) SHELL_CHOICE="bash" ;;
            esac
        fi

        case $SHELL_CHOICE in
            "bash")
                echo -e "${COLOR_BLUE}Bash sélectionné${COLOR_RESET}"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    execute_command "pkg install -y zsh" "Installation de ZSH"
                else
                    success_msg="✓ Zsh déjà installé"
                fi
                # Installation de Oh My Zsh et autres configurations ZSH
                title_msg "❯ Configuration de ZSH"
                if $USE_GUM; then
                    if gum_confirm "Installer Oh-My-Zsh ?"; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Installer Oh-My-Zsh ? (O/n) : ${COLOR_RESET}"
                    read -r CHOICE
                    if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/zshrc" "Configuration par défaut" || error_msg "Configuration par défaut impossible"

                if $USE_GUM; then
                    if gum_confirm "Installer PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Installer le prompt personnalisé ?"; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Installation du prompt personnalisé" || error_msg "Impossible d'installer le prompt personnalisé"
                            echo -e "\n# Pour personnaliser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt en exécutant 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Installer PowerLevel10k ? (O/n) : ${COLOR_RESET}"
                    read -r CHOICE
                    if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Installer le prompt OhMyTermux ? (O/n) : ${COLOR_RESET}"
                        read -r CHOICE
                        if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Installation du prompt OhMyTermux" || error_msg "Impossible d'installer le prompt OhMyTermux"
                            echo -e "\n# Pour personnaliser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt en exécutant 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/aliases.zsh && \
                                mkdir -p $HOME/.config/OhMyTermux && \
                                curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/help.md)" "Configuration par défaut" || error_msg "Configuration par défaut impossible"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_RED}ZSH n'est pas installé. Impossible d'installer les plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                title_msg "❯ Configuration de Fish"
                execute_command "pkg install -y fish" "Installation de Fish"
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# SÉLECTION DES PLUGINS ZSH 
#------------------------------------------------------------------------------
install_zsh_plugins() {
    local PLUGINS_TO_INSTALL=()

    subtitle_msg "❯ Installation des plugins"

    if $USE_GUM; then
        mapfile -t PLUGINS_TO_INSTALL < <(gum_choose_multi "Sélectionner avec ESPACE les plugins à installer :" --height=8 --selected="Tout installer" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder" "Tout installer")
        if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" Tout installer "* ]]; then
            PLUGINS_TO_INSTALL=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
        fi
    else
        echo "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-alias-finder"
        info_msg "6) Tout installer"
        echo
        printf "${COLOR_GOLD}Entrez les numéros des plugins : ${COLOR_RESET}"
        tput setaf 3
        read -r PLUGIN_CHOICES
        tput sgr0
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

    # Définir les variables nécessaires
    local ZSHRC="$HOME/.zshrc"
    local SELECTED_PLUGINS="${PLUGINS_TO_INSTALL[*]}"
    local HAS_COMPLETIONS=false
    local HAS_OHMYTERMIX=true

    # Vérifier si zsh-completions est installé
    if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" zsh-completions "* ]]; then
        HAS_COMPLETIONS=true
    fi

    update_zshrc "$ZSHRC" "$SELECTED_PLUGINS" "$HAS_COMPLETIONS" "$HAS_OHMYTERMIX"
}

#------------------------------------------------------------------------------
# INSTALLATION DES PLUGINS ZSH
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
        execute_command "git clone '$PLUGIN_URL' '$HOME/.oh-my-zsh/custom/plugins/$PLUGIN_NAME' --quiet" "Installation de $PLUGIN_NAME"
    else
        info_msg "  $PLUGIN_NAME est déjà installé"
    fi
}

#------------------------------------------------------------------------------
# MISE À JOUR DE LA CONFIGURATION DE ZSH
#------------------------------------------------------------------------------
update_zshrc() {
    local ZSHRC="$1"
    local SELECTED_PLUGINS="$2"
    local HAS_COMPLETIONS="$3"
    local HAS_OHMYTERMUX="$4"

    # Suppression de la configuration existante
    sed -i '/fpath.*zsh-completions\/src/d' "$ZSHRC"
    sed -i '/source \$ZSH\/oh-my-zsh.sh/d' "$ZSHRC"
    sed -i '/# Pour personnaliser le prompt/d' "$ZSHRC"
    sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\]/d' "$ZSHRC"
    sed -i '/# Source des alias personnalisés/d' "$ZSHRC"
    sed -i '/\[ -f.*aliases.*/d' "$ZSHRC"

    # Création du contenu de la section plugins
    local DEFAULT_PLUGINS="git command-not-found copyfile node npm timer vscode web-search z"
    local FILTERED_PLUGINS=$(echo "$SELECTED_PLUGINS" | sed 's/zsh-completions//g')
    local ALL_PLUGINS="$DEFAULT_PLUGINS $FILTERED_PLUGINS"

    local PLUGINS_SECTION="plugins=(\n"
    for PLUGIN in $ALL_PLUGINS; do
        PLUGINS_SECTION+="    $PLUGIN\n"
    done
    PLUGINS_SECTION+=")\n"

    # Suppression et remplacement de la section plugins
    sed -i '/^plugins=(/,/)/d' "$ZSHRC"
    echo -e "$PLUGINS_SECTION" >> "$ZSHRC"

    # Ajout de la configuration par séction
    if [ "$HAS_COMPLETIONS" = "true" ]; then
        echo -e "\n# Charger zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" >> "$ZSHRC"
    fi

    echo -e "\n# Charger oh-my-zsh\nsource \$ZSH/oh-my-zsh.sh" >> "$ZSHRC"

    if [ "$HAS_OHMYTERMUX" = "true" ]; then
        echo -e "\n# Pour personnaliser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
    fi

    # Sourcing des alias centralisés
    echo -e "\n# Source des alias personnalisés\n[ -f \"$HOME/.config/OhMyTermux/aliases\" ] && . \"$HOME/.config/OhMyTermux/aliases\"" >> "$ZSHRC"
}

#------------------------------------------------------------------------------
# INSTALLATION DES PAQUETS ADDITIONNELS
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        title_msg "❯ Configuration des packages"
        if $USE_GUM; then
            PACKAGES=$(gum_choose_multi "Sélectionner avec espace les packages à installer :" --no-limit --height=18 --selected="nala,eza,bat,lf,fzf" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
        else
            echo "Sélectionner les packages à installer (séparés par des espaces) :"
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
            echo "19) Tout installer"
            echo            
            printf "${COLOR_GOLD}Entrez les numéros des packages : ${COLOR_RESET}"
            tput setaf 3
            read -r PACKAGE_CHOICES
            tput sgr0
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
                execute_command "pkg install -y $PACKAGE" "Installation de $PACKAGE"

                # Ajout des alias spécifiques après l'installation
                case $PACKAGE in
                    eza|bat|nala)
                        add_aliases_to_rc "$PACKAGE"
                        ;;
                esac
            done

            # Recharger les alias pour les rendre disponibles immédiatement
            if [ -f "$HOME/.config/OhMyTermux/aliases" ]; then
                source "$HOME/.config/OhMyTermux/aliases"
            fi
        else
            echo -e "${COLOR_BLUE}Aucun package sélectionné.${COLOR_RESET}"
        fi
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION DES ALIAS SPECIFIQUES
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
# CONFIGURATION DES ALIAS COMMUNS
#------------------------------------------------------------------------------
common_alias() {
    # Création du fichier d'alias centralisé
    if [ ! -d "$HOME/.config/OhMyTermux" ]; then
        execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Création du dossier de configuration"
    fi

    ALIASES_FILE="$HOME/.config/OhMyTermux/aliases"

    cat > "$ALIASES_FILE" << 'EOL'
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Commandes de base
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

    # Ajout du sourcing .bashrc
    echo -e "\n# Source des alias personnalisés\n[ -f \"$ALIASES_FILE\" ] && . \"$ALIASES_FILE\"" >> "$BASHRC"
    # Le sourcing .zshrc est fait dans update_zshrc()
}

#------------------------------------------------------------------------------
# INSTALLATION DE LA POLICE
#------------------------------------------------------------------------------
install_font() {
    if $FONT_CHOICE; then
        title_msg "❯ Configuration de la police"
        if $USE_GUM; then
            FONT=$(gum_choose "Sélectionner la police à installer :" --height=13 --selected="Police par défaut" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo "Sélectionner la police à installer :"
            echo
            echo -e "${COLOR_BLUE}1) Police par défaut${COLOR_RESET}"
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
            printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
            tput setaf 3
            read -r CHOICE
            tput sgr0
            case $CHOICE in
                1) FONT="Police par défaut" ;;
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
            "Police par défaut")
                execute_command "curl -fLo \"$HOME/.termux/font.ttf\" 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf'" "Installation de la police par défaut"
                termux-reload-settings
                ;;
            *)
                FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
                execute_command "curl -L -o $HOME/.termux/font.ttf \"$FONT_URL\"" "Installation de $FONT"
                termux-reload-settings
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DE L'ENVIRONNEMENT XFCE
#------------------------------------------------------------------------------
install_xfce() {
    if $XFCE_CHOICE; then
        title_msg "❯ Configuration de XFCE"
        
        # Choix de la version
        local XFCE_VERSION
        if $USE_GUM; then
            XFCE_VERSION=$(gum_choose "Sélectionner la version de XFCE à installer :" --height=5 --selected="recommandée" \
                "minimale" \
                "recommandée" \
                "personnalisée")
        else
            echo -e "${COLOR_BLUE}Sélectionner la version de XFCE à installer :${COLOR_RESET}"
            echo "1) Minimale"
            echo "2) Recommandée"
            echo "3) Personnalisée"
            printf "${COLOR_GOLD}Entrez votre choix (1/2/3) : ${COLOR_RESET}"
            tput setaf 3
            read -r CHOICE
            tput sgr0
            case $CHOICE in
                1) XFCE_VERSION="minimale" ;;
                2) XFCE_VERSION="recommandée" ;;
                3) XFCE_VERSION="personnalisée" ;;
                *) XFCE_VERSION="recommandée" ;;
            esac
        fi

        # Sélection du navigateur (sauf pour la version légère)
        local BROWSER_CHOICE="aucun"
        if [ "$XFCE_VERSION" != "minimale" ]; then
            if $USE_GUM; then
                BROWSER_CHOICE=$(gum_choose "Séléctionner un navigateur web :" --height=5 --selected="chromium" "chromium" "firefox" "aucun")
            else
                echo -e "${COLOR_BLUE}Séléctionner un navigateur web :${COLOR_RESET}"
                echo "1) Chromium (par défaut)"
                echo "2) Firefox"
                echo "3) Aucun"
                printf "${COLOR_GOLD}Entrez votre choix (1/2/3) : ${COLOR_RESET}"
                tput setaf 3
                read -r CHOICE
                tput sgr0
                case $CHOICE in
                    1) BROWSER_CHOICE="chromium" ;;
                    2) BROWSER_CHOICE="firefox" ;;
                    3) BROWSER_CHOICE="aucun" ;;
                    *) BROWSER_CHOICE="chromium" ;;
                esac
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installation des dépendances"

        PACKAGES=('wget' 'x11-repo' 'tur-repo' 'pulseaudio')

        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installation de $PACKAGE"
        done
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce_dev.sh" "Téléchargement du script XFCE" || error_msg "Impossible de télécharger le script XFCE"
        execute_command "chmod +x xfce_dev.sh" "Exécution du script XFCE"
        
        if $USE_GUM; then
            ./xfce_dev.sh --gum --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
        else
            ./xfce_dev.sh --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DES SCRIPTS XFCE
#------------------------------------------------------------------------------
install_xfce_scripts() {
    title_msg "❯ Configuration des scripts XFCE"
    
    # Installation du script de démarrage
    cat <<'EOF' > start
#!/bin/bash

# Activer PulseAudio sur le réseau
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Définir le serveur audio
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1
EOF

    execute_command "chmod +x start && mv start $PREFIX/bin" "Installation du script de démarrage"

    # Installation du script d'arrêt
    cat <<'EOF' > "$PREFIX/bin/kill_termux_x11"
#!/bin/bash

# Vérification de l'exécution des processus dans Termux ou Proot
if pgrep -f 'apt|apt-get|dpkg|nala' > /dev/null; then
    zenity --info --text="Un logiciel est en cours d'installation dans Termux ou Proot. Veuillez attendre la fin de ces processus avant de continuer."
    exit 1
fi

# Récupération d'identifiants des processus sessions Termux-X11 et XFCE
termux_x11_pid=$(pgrep -f /system/bin/app_process.*com.termux.x11.Loader)
xfce_pid=$(pgrep -f "xfce4-session")

# Stopper les processus uniquement s'ils existent
if [ -n "$termux_x11_pid" ]; then
    kill -9 "$termux_x11_pid" 2>/dev/null
fi

if [ -n "$xfce_pid" ]; then
    kill -9 "$xfce_pid" 2>/dev/null
fi

# Affichage de message dynamique
if [ -n "$termux_x11_pid" ] || [ -n "$xfce_pid" ]; then
    zenity --info --text="Sessions Termux-X11 et XFCE fermées."
else
    zenity --info --text="Session Termux-X11 ou XFCE non trouvée."
fi

# Stopper l'application Termux uniquement si le PID existe
info_output=$(termux-info)
if pid=$(echo "$info_output" | grep -o 'TERMUX_APP_PID=[0-9]\+' | awk -F= '{print $2}') && [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null
fi

exit 0

EOF

    execute_command "chmod +x $PREFIX/bin/kill_termux_x11" "Installation du script d'arrêt"


    # Création du raccourci
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

    execute_command "chmod +x $PREFIX/share/applications/kill_termux_x11.desktop" "Création du raccourci"
}

#------------------------------------------------------------------------------
# INSTALLATION DE DEBIAN PROOT
#------------------------------------------------------------------------------
install_proot() {
    if $PROOT_CHOICE; then
        title_msg "❯ Configuration de Proot"
        if $USE_GUM; then
            if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Debian Proot ?"; then
                execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
                execute_command "chmod +x proot_dev.sh" "Exécution du script Proot"
                ./proot_dev.sh --gum
            fi
        else    
            printf "${COLOR_BLUE}Installer Debian Proot ? (O/n) : ${COLOR_RESET}"
            read -r CHOICE
            if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
                execute_command "chmod +x proot_dev.sh" "Exécution du script Proot"
                ./proot_dev.sh
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# RECUPERATION DU NOM D'UTILISATEUR
#------------------------------------------------------------------------------
get_username() {
    local USER_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    local USERNAME
    USERNAME=$(ls -1 "$USER_DIR" 2>/dev/null | grep -v '^$' | head -n 1)
    if [ -z "$USERNAME" ]; then
        echo "Aucun utilisateur trouvé" >&2
        return 1
    fi
    echo "$USERNAME"
}

#------------------------------------------------------------------------------
# INSTALLATION DES UTILITAIRES
#------------------------------------------------------------------------------
install_utils() {
    title_msg "❯ Configuration des utilitaires"
    execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/utils.sh" "Téléchargement du script Utils" || error_msg "Impossible de télécharger le script Utils"
    execute_command "chmod +x utils.sh" "Exécution du script Utils"
    ./utils.sh

    if ! USERNAME=$(get_username); then
        error_msg "Impossible de récupérer le nom d'utilisateur."
        return 1
    fi

    BASHRC_PROOT="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian/home/${USERNAME}/.bashrc"
    if [ ! -f "$BASHRC_PROOT" ]; then
        error_msg "Le fichier .bashrc n'existe pas pour l'utilisateur $USERNAME."
        execute_command "proot-distro login debian --shared-tmp --env DISPLAY=:1.0 -- touch \"$BASHRC_PROOT\"" "Configuration Bash Debian"
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

# Alias pour se connecter à Debian Proot
alias debian="proot-distro login debian --shared-tmp --user ${USERNAME}"
EOL

    if [ -f "$BASHRC" ]; then
        cat "$TMP_FILE" >> "$BASHRC"
        success_msg "✓ Configuration Bash Termux"
    else
        touch "$BASHRC" 
        cat "$TMP_FILE" >> "$BASHRC"
        success_msg "✓ Création et configuration Bash Termux"
    fi
    if [ -f "$ZSHRC" ]; then
        cat "$TMP_FILE" >> "$ZSHRC"
        success_msg "✓ Configuration ZSH Termux"
    else
        touch "$ZSHRC"
        cat "$TMP_FILE" >> "$ZSHRC"
        success_msg "✓ Création et configuration ZSH Termux"
    fi
    rm "$TMP_FILE"
}

#------------------------------------------------------------------------------
# INSTALLATION DE TERMUX-X11
#------------------------------------------------------------------------------
install_termux_x11() {
    if $X11_CHOICE; then
        title_msg "❯ Configuration de Termux-X11"
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
            if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Termux-X11 ?"; then
                INSTALL_X11=true
            fi
        else
            printf "${COLOR_BLUE}Installer Termux-X11 ? (O/n) : ${COLOR_RESET}"
            read -r choice
            if [[ "$choice" =~ ^[oO]$ ]]; then
                INSTALL_X11=true
            fi
        fi

        if $INSTALL_X11; then
            local APK_URL="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
            local APK_FILE="$HOME/storage/downloads/termux-x11.apk"

            execute_command "wget \"$APK_URL\" -O \"$APK_FILE\"" "Téléchargement de Termux-X11"

            if [ -f "$APK_FILE" ]; then
                termux-open "$APK_FILE"
                echo -e "${COLOR_BLUE}Veuillez installer l'APK manuellement.${COLOR_RESET}"
                echo -e "${COLOR_BLUE}Une fois l'installation terminée, appuyez sur Entrée pour continuer.${COLOR_RESET}"
                read -r
                rm "$APK_FILE"
            else
                error_msg "✗ Erreur lors de l'installation de Termux-X11"
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
show_banner

# Vérification et installation des dépendances nécessaires
if ! command -v tput &> /dev/null; then
    if $USE_GUM; then
        execute_command "pkg install -y ncurses-utils" "Installation des dépendances"
    else
        execute_command "pkg install -y ncurses-utils >/dev/null 2>&1" "Installation des dépendances"
    fi
fi

# Vérifier si des arguments spécifiques ont été fournis
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
    # Exécuter l'installation complète si aucun argument spécifique n'est fourni
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

# Nettoyage et message de fin
title_msg "❯ Nettoyage des fichiers temporaires"
rm -f xfce_dev.sh proot_dev.sh utils.sh install_dev.sh >/dev/null 2>&1
success_msg "✓ Suppression des scripts d'installation"

# Rechargement du shell
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Exécuter OhMyTermux ?"; then
        clear
        if [ "$SHELL_CHOICE" = "zsh" ]; then
            exec zsh -l
        else
            exec $SHELL_CHOICE
        fi
    else
        echo -e "${COLOR_BLUE}Pour utiliser toutes les fonctionnalités :${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Saisir : ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Ou redémarrer Termux${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Exécuter OhMyTermux ? (O/n) : ${COLOR_RESET}"
    read -r choice
    if [[ "$choice" =~ ^[oO]$ ]]; then
        clear
        if [ "$SHELL_CHOICE" = true ]; then
            exec zsh -l
        else
            exec $SHELL_CHOICE
        fi
    else
        echo -e "${COLOR_BLUE}Pour utiliser toutes les fonctionnalités :${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Saisir : ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Ou redémarrer Termux${COLOR_RESET}"
    fi
fi