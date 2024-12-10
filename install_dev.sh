#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES GLOBALES
#------------------------------------------------------------------------------
# Interface interactive avec gum
USE_GUM=false

# Configuration initiale
EXECUTE_INITIAL_CONFIG=true

# Sortie détaillée
VERBOSE=false

# Variables pour Debian PRoot
PROOT_USERNAME=""
PROOT_PASSWORD=""

#------------------------------------------------------------------------------
# SELECTEURS DE MODULES
#------------------------------------------------------------------------------
# Sélection du shell
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
    echo "  --package | -pk   Module d'installation des packages"
    echo "  --font | -f       Module d'installation de la police"
    echo "  --xfce | -x       Module d'installation de XFCE"
    echo "  --proot | -pr     Module d'installation de Debian PRoot"
    echo "  --x11             Module d'installation de Termux-X11"
    echo "  --skip            Ignorer la configuration initiale"
    echo "  --uninstall       Désinstallation de Debian Proot"
    echo "  --full            Installer tous les modules sans confirmation"
    echo "  --help | -h       Afficher ce message d'aide"
    echo
    echo "Exemples:"
    echo "  $0 --gum                     # Installation interactive avec gum"
    echo "  $0 --full user pass          # Installation complète avec identifiants"
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
            # Récupérer le nom d'utilisateur et le mot de passe s'ils sont fournis
            if [ -z "$PROOT_USERNAME" ]; then
                PROOT_USERNAME="$ARG"
                shift
            elif [ -z "$PROOT_PASSWORD" ]; then
                PROOT_PASSWORD="$ARG"
                shift
            else
                break
            fi
            ;;
    esac
done

# Si on est en mode FULL_INSTALL et que les identifiants ne sont pas fournis, les demander
if $FULL_INSTALL; then
    if [ -z "$PROOT_USERNAME" ]; then
        if $USE_GUM; then
            PROOT_USERNAME=$(gum input --placeholder "Entrez le nom d'utilisateur pour Debian PRoot")
        else
            printf "${COLOR_BLUE}Entrez le nom d'utilisateur pour Debian PRoot : ${COLOR_RESET}"
            read -r PROOT_USERNAME
        fi
    fi
    
    if [ -z "$PROOT_PASSWORD" ]; then
        while true; do
            if $USE_GUM; then
                PROOT_PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Entrer un mot de passe")
                PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirmer le mot de passe")
            else
                printf "${COLOR_BLUE}Entrer un mot de passe: ${COLOR_RESET}"
                read -r -s PROOT_PASSWORD
                echo
                printf "${COLOR_BLUE}Confirmer le mot de passe: ${COLOR_RESET}"
                read -r -s PASSWORD_CONFIRM
                echo
            fi

            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                if $USE_GUM; then
                    gum style --foreground 196 "Les mots de passe ne correspondent pas. Veuillez réessayer."
                else
                    echo -e "${COLOR_RED}Les mots de passe ne correspondent pas. Veuillez réessayer.${COLOR_RESET}"
                fi
            fi
        done
    fi
fi

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
    local USERNAME=$(whoami)
    local HOSTNAME=$(hostname)
    local CWD=$(pwd)
    echo "[$(date +'%d/%m/%Y %H:%M:%S')] ERREUR: $ERROR_MSG | Utilisateur: $USERNAME | Machine: $HOSTNAME | Répertoire: $CWD" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# AFFICHAGE DYNAMIQUE DU RÉSULTAT D'UNE COMMANDE
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
            gum style "$ERROR_MSG" --foreground 196
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
            error_msg "$ERROR_MSG"
            log_error "$ERROR_DETAILS"
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
║                OHMYTERMUX              ║
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
    local BACKUP_DIR="$HOME/.config/OhMyTermux/backups"
    
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
# FONCTION POUR TELECHARGER ET EXECUTER UN SCRIPT
#------------------------------------------------------------------------------
download_and_execute() {
    local URL="$1"
    local SCRIPT_NAME=$(basename "$URL")
    local DESCRIPTION="${2:-$SCRIPT_NAME}"
    shift 2
    local EXEC_ARGS="$@"

    # Vérifier si le fichier existe déjà et le supprimer
    [ -f "$SCRIPT_NAME" ] && rm "$SCRIPT_NAME"

    # Télécharger avec curl en mode silencieux mais avec barre de progression
    #if ! curl -L --progress-bar -o "$SCRIPT_NAME" "$URL"; then
    if ! curl -L -o "$SCRIPT_NAME" "$URL" 2>/dev/null; then
        error_msg "Impossible de télécharger le script $DESCRIPTION"
        return 1
    fi

    # Vérifier que le fichier a bien été téléchargé
    if [ ! -f "$SCRIPT_NAME" ]; then
        error_msg "Le fichier $SCRIPT_NAME n'a pas été créé"
        return 1
    fi

    # Rendre le script exécutable
    if ! chmod +x "$SCRIPT_NAME"; then
        error_msg "Impossible de rendre le script $DESCRIPTION exécutable"
        return 1
    fi

    # Exécuter le script avec les arguments
    if ! ./"$SCRIPT_NAME" $EXEC_ARGS; then
        error_msg "Erreur lors de l'exécution du script $DESCRIPTION"
        return 1
    fi

    return 0
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
        read -r -e -p "" -i "o" CHOICE
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
            read -r -e -p "" -i "n" CHOICE
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
        mkdir -p "$TERMUX_DIR"
        cat > "$FILE_PATH" << 'EOL'
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
EOL
        success_msg "✓ Installation du thème Argonaut"
    fi

    # Configuration des alias communs
    common_alias
    
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
    # Si on est en mode FULL_INSTALL, demander les identifiants au début
    if $FULL_INSTALL; then
        title_msg "❯ Configuration de Debian PRoot"
        if [ -z "$PROOT_USERNAME" ]; then
            if $USE_GUM; then
                PROOT_USERNAME=$(gum input --placeholder "Entrez le nom d'utilisateur pour Debian PRoot")
                PROOT_PASSWORD=$(gum input --password --placeholder "Entrez le mot de passe pour Debian PRoot")
            else
                printf "${COLOR_BLUE}Entrez le nom d'utilisateur pour Debian PRoot : ${COLOR_RESET}"
                read -r PROOT_USERNAME
                printf "${COLOR_BLUE}Entrez le mot de passe pour Debian PRoot : ${COLOR_RESET}"
                read -r -s PROOT_PASSWORD
                echo
            fi
        fi
    fi

    change_repo

    # Mise à jour et mise à niveau des paquets en préservant les configurations existantes
    clear
    show_banner
    execute_command "pkg update -y -o Dpkg::Options::=\"--force-confold\"" "Mise à jour des dépôts"
    execute_command "pkg upgrade -y -o Dpkg::Options::=\"--force-confold\"" "Mise à niveau des paquets"

    setup_storage

    if $USE_GUM; then
        show_banner
        if gum_confirm "Activer la configuration recommandée ?"; then
            configure_termux
        fi
    else
        show_banner
        printf "${COLOR_BLUE}Activer la configuration recommandée ? (O/n) : ${COLOR_RESET}"
        read -r -e -p "" -i "o" CHOICE
        # Effacer la ligne précédente
        tput cuu1  # Remonte d'une ligne
        tput el    # Efface jusqu'à la fin de la ligne
        [[ "$CHOICE" =~ ^[oO]$ ]] && configure_termux
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
            read -r -e -p "" -i "2" CHOICE
            tput sgr0

            # Effacer le menu de sélection
            tput cuu 7  # Remonte le curseur de 7 lignes
            tput ed     # Efface du curseur à la fin de l'écran

            case $CHOICE in
                1) SHELL_CHOICE="bash" ;;
                2) SHELL_CHOICE="zsh" ;;
                3) SHELL_CHOICE="fish" ;;
                *) SHELL_CHOICE="bash" ;;
            esac
        fi

        case $SHELL_CHOICE in
            "bash")
                success_msg "✓ Séléction de Bash"
                install_prompt
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    execute_command "pkg install -y zsh" "Installation de ZSH"
                else
                    success_msg="✓ Zsh déjà installé"
                fi
                # Installation de Oh My Zsh et autres configurations ZSH
                title_msg "❯ Configuration de ZSH"
                if [ ! -d "$HOME/.oh-my-zsh" ]; then
                    if $USE_GUM; then
                        if gum_confirm "Installer Oh-My-Zsh ?"; then
                            execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                            execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                            cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                        fi
                    else
                        printf "${COLOR_BLUE}Installer Oh-My-Zsh ? (O/n) : ${COLOR_RESET}"
                        read -r -e -p "" -i "o" CHOICE
                        tput cuu1
                        tput el
                        if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                            execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                            execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                            cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                        fi
                    fi
                else
                    success_msg "✓ Oh-My-Zsh déjà installé"
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/zshrc" "Configuration par défaut" || error_msg "Configuration par défaut impossible"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                    install_prompt
                else
                    echo -e "${COLOR_RED}ZSH n'est pas installé. Impossible d'installer les plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                title_msg "❯ Configuration de Fish"
                execute_command "pkg install -y fish" "Installation de Fish"
                execute_command "mkdir -p $HOME/.config/fish/functions" "Création du répertoire fish"
                # Installation de Fisher en mode non-interactif
                execute_command "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o $HOME/.config/fish/functions/fisher.fish" "Téléchargement de Fisher"
                # Installation de Tide via Fisher en mode non-interactif
                execute_command "fish -c 'source $HOME/.config/fish/functions/fisher.fish && fisher install IlanCosman/tide@v5'" "Installation de Tide"
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DU PROMPT
#------------------------------------------------------------------------------
install_prompt() {
    local PROMPT_CHOICE
    local CURRENT_SHELL="${SHELL_CHOICE:-zsh}"
    
    if [ "$CURRENT_SHELL" = "bash" ]; then
        if $USE_GUM; then
            PROMPT_CHOICE=$(gum_choose "Choisissez le prompt à installer :" --height=4 --selected="Oh-My-Posh" "Oh-My-Posh" "Starship")
        else
            echo -e "${COLOR_BLUE}Choisissez le prompt à installer :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) Oh-My-Posh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) Starship${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Entrez votre choix (1/2) : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "1" CHOICE
            tput sgr0
            tput cuu 5
            tput ed
            
            case $CHOICE in
                1) PROMPT_CHOICE="Oh-My-Posh" ;;
                2) PROMPT_CHOICE="Starship" ;;
                *) PROMPT_CHOICE="Oh-My-Posh" ;;
            esac
        fi
    else
        if $USE_GUM; then
            PROMPT_CHOICE=$(gum_choose "Choisissez le prompt à installer :" --height=5 --selected="PowerLevel10k" "PowerLevel10k" "Oh-My-Posh" "Starship")
        else
            echo -e "${COLOR_BLUE}Choisissez le prompt à installer :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) PowerLevel10k${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) Oh-My-Posh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) Starship${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Entrez votre choix (1/2/3) : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "1" CHOICE
            tput sgr0
            tput cuu 7
            tput ed
            
            case $CHOICE in
                1) PROMPT_CHOICE="PowerLevel10k" ;;
                2) PROMPT_CHOICE="Oh-My-Posh" ;;
                3) PROMPT_CHOICE="Starship" ;;
                *) PROMPT_CHOICE="PowerLevel10k" ;;
            esac
        fi
    fi

    case $PROMPT_CHOICE in
        "PowerLevel10k")
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
                read -r -e -p "" -i "o" CHOICE
                tput cuu1
                tput el
                if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                    execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" > /dev/null 2>&1 || true" "Installation de PowerLevel10k"
                    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                    printf "${COLOR_BLUE}Installer le prompt personnalisé ? (O/n) : ${COLOR_RESET}"
                    read -r -e -p "" -i "o" CHOICE
                    tput cuu1
                    tput el
                    if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                        execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Installation du prompt personnalisé" || error_msg "Impossible d'installer le prompt personnalisé"
                        echo -e "\n# Pour personnaliser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$ZSHRC"
                        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                    else
                        echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt en exécutant 'p10k configure'.${COLOR_RESET}"
                    fi
                fi
            fi
            ;;
            
        "Oh-My-Posh")
            execute_command "pkg install -y oh-my-posh" "Installation de Oh-My-Posh"
            
            # Installation optionnelle d'une police Nerd
            if [ ! -f "$HOME/.termux/font.ttf" ]; then
                execute_command "curl -fLo \"$HOME/.termux/font.ttf\" --create-dirs https://raw.githubusercontent.com/termux/termux-styling/master/app/src/main/assets/fonts/DejaVu-Sans-Mono.ttf" "Installation de la police Nerd"
            fi
            
            # Récupération de la liste complète des thèmes
            THEMES_DIR="/data/data/com.termux/files/usr/share/oh-my-posh/themes"
            if [ -d "$THEMES_DIR" ]; then
                # Création d'un tableau avec tous les thèmes disponibles
                mapfile -t AVAILABLE_THEMES < <(find "$THEMES_DIR" -name "*.omp.json" -exec basename {} .omp.json \; | sort)
            else
                error_msg "Répertoire des thèmes Oh-My-Posh non trouvé"
                return 1
            fi

            # Sélection du thème
            if $USE_GUM; then
                THEME=$(printf '%s\n' "${AVAILABLE_THEMES[@]}" | gum_choose \
                    "Choisissez un thème Oh-My-Posh :" \
                    --height=25)
            else
                # Affichage de la liste numérotée des thèmes
                echo -e "${COLOR_BLUE}Choisissez un thème Oh-My-Posh :${COLOR_RESET}"
                echo
                for i in "${!AVAILABLE_THEMES[@]}"; do
                    # Formatage du numéro pour l'alignement (3 caractères)
                    NUM=$(printf "%3d" $((i+1)))
                    if [ "${AVAILABLE_THEMES[$i]}" = "jandedobbeleer" ]; then
                        echo -e "${COLOR_BLUE}${NUM}) ${AVAILABLE_THEMES[$i]} (par défaut)${COLOR_RESET}"
                    else
                        echo -e "${COLOR_BLUE}${NUM}) ${AVAILABLE_THEMES[$i]}${COLOR_RESET}"
                    fi
                done
                echo
                # Calcul du nombre de lignes à effacer (nombre de thèmes + 3 lignes pour le texte supplémentaire)
                LINES_TO_CLEAR=$((${#AVAILABLE_THEMES[@]}+3))
                printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
                tput setaf 3
                read -r -e -p "" -i "1" CHOICE
                tput sgr0
                # Effacement du menu
                tput cuu $LINES_TO_CLEAR
                tput ed

                # Validation du choix
                if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#AVAILABLE_THEMES[@]}" ]; then
                    THEME="${AVAILABLE_THEMES[$((CHOICE-1))]}"
                else
                    THEME="jandedobbeleer"
                fi
                fi

            # Configuration pour ZSH
            if [ ! -f "$ZSHRC" ]; then
                touch "$ZSHRC"
            fi
            sed -i '/# Initialiser oh-my-posh/d' "$ZSHRC"
            sed -i '/eval "$(oh-my-posh init/d' "$ZSHRC"
            cat >> "$ZSHRC" << EOF

# Initialiser oh-my-posh
eval "\$(oh-my-posh init zsh --config /data/data/com.termux/files/usr/share/oh-my-posh/themes/${THEME}.omp.json)"
EOF

            # Configuration pour Bash
            if [ ! -f "$HOME/.bashrc" ]; then
                touch "$HOME/.bashrc"
            fi
            sed -i '/# Initialiser oh-my-posh/d' "$HOME/.bashrc"
            sed -i '/eval "$(oh-my-posh init/d' "$HOME/.bashrc"
            cat >> "$HOME/.bashrc" << EOF

# Initialiser oh-my-posh
eval "\$(oh-my-posh init bash --config /data/data/com.termux/files/usr/share/oh-my-posh/themes/${THEME}.omp.json)"
EOF
            ;;
        "Starship")
            execute_command "pkg install -y starship" "Installation de Starship"
            
            # Installation optionnelle d'une police Nerd
            if [ ! -f "$HOME/.termux/font.ttf" ]; then
                execute_command "curl -fLo \"$HOME/.termux/font.ttf\" --create-dirs https://raw.githubusercontent.com/termux/termux-styling/master/app/src/main/assets/fonts/DejaVu-Sans-Mono.ttf" "Installation de la police Nerd"
            fi

            # Création du répertoire de configuration si nécessaire
            mkdir -p "$HOME/.config"

            # Sélection du preset
            if $USE_GUM; then
                PRESET=$(gum_choose "Choisissez un preset Starship :" --height=15 --selected="Personnalisé" \
                    "Personnalisé" \
                    "Nerd Font Symbols" \
                    "Bracketed Segments" \
                    "No Empty Icons" \
                    "No Runtime Versions" \
                    "Plain Text Symbols" \
                    "Pastel Powerline" \
                    "Tokyo Night" \
                    "Pure Preset" \
                    "Gruvbox Rainbow" \
                    "Jetpack" \
                    "No Nerd Font" \
                    "Rice" \
                    "Solarized")
            else
                echo -e "${COLOR_BLUE}Choisissez un preset Starship :${COLOR_RESET}"
                echo
                echo -e "${COLOR_BLUE}1)  Personnalisé${COLOR_RESET}"
                echo -e "${COLOR_BLUE}2)  Nerd Font Symbols${COLOR_RESET}"
                echo -e "${COLOR_BLUE}3)  Bracketed Segments${COLOR_RESET}"
                echo -e "${COLOR_BLUE}4)  No Empty Icons${COLOR_RESET}"
                echo -e "${COLOR_BLUE}5)  No Runtime Versions${COLOR_RESET}"
                echo -e "${COLOR_BLUE}6)  Plain Text Symbols${COLOR_RESET}"
                echo -e "${COLOR_BLUE}7)  Pastel Powerline${COLOR_RESET}"
                echo -e "${COLOR_BLUE}8)  Tokyo Night${COLOR_RESET}"
                echo -e "${COLOR_BLUE}9)  Pure Preset${COLOR_RESET}"
                echo -e "${COLOR_BLUE}10) Gruvbox Rainbow${COLOR_RESET}"
                echo -e "${COLOR_BLUE}11) Jetpack${COLOR_RESET}"
                echo -e "${COLOR_BLUE}12) No Nerd Font${COLOR_RESET}"
                echo -e "${COLOR_BLUE}13) Rice${COLOR_RESET}"
                echo -e "${COLOR_BLUE}14) Solarized${COLOR_RESET}"
                echo
                printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
                tput setaf 3
                read -r -e -p "" -i "1" CHOICE
                tput sgr0
                tput cuu 18
                tput ed
                
                case $CHOICE in
                    1) PRESET="Personnalisé" ;;
                    2) PRESET="Nerd Font Symbols" ;;
                    3) PRESET="Bracketed Segments" ;;
                    4) PRESET="No Empty Icons" ;;
                    5) PRESET="No Runtime Versions" ;;
                    6) PRESET="Plain Text Symbols" ;;
                    7) PRESET="Pastel Powerline" ;;
                    8) PRESET="Tokyo Night" ;;
                    9) PRESET="Pure Preset" ;;
                    10) PRESET="Gruvbox Rainbow" ;;
                    11) PRESET="Jetpack" ;;
                    12) PRESET="No Nerd Font" ;;
                    13) PRESET="Rice" ;;
                    14) PRESET="Solarized" ;;
                    *) PRESET="Personnalisé" ;;
                esac
            fi

            case $PRESET in
                "Nerd Font Symbols")
                    starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"
                    ;;
                "Bracketed Segments") 
                    starship preset bracketed-segments -o "$HOME/.config/starship.toml"
                    ;;
                "No Empty Icons")
                    starship preset no-empty-icons -o "$HOME/.config/starship.toml"
                    ;;
                "No Runtime Versions")
                    starship preset no-runtime-versions -o "$HOME/.config/starship.toml"
                    ;;
                "Plain Text Symbols")
                    starship preset plain-text-symbols -o "$HOME/.config/starship.toml"
                    ;;
                "Pastel Powerline")
                    starship preset pastel-powerline -o "$HOME/.config/starship.toml"
                    ;;
                "Tokyo Night")
                    starship preset tokyo-night -o "$HOME/.config/starship.toml"
                    ;;
                "Pure Preset")
                    starship preset pure -o "$HOME/.config/starship.toml"
                    ;;
                "Gruvbox Rainbow")
                    starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"
                    ;;
                "Jetpack")
                    starship preset jetpack -o "$HOME/.config/starship.toml"
                    ;;
                "No Nerd Font")
                    starship preset no-nerd-font -o "$HOME/.config/starship.toml"
                    ;;
                "Rice")
                    starship preset rice -o "$HOME/.config/starship.toml"
                    ;;
                "Solarized")
                    starship preset solarized -o "$HOME/.config/starship.toml"
                    ;;
                *)
                    # Configuration personnalisée par défaut
                    cat > "$HOME/.config/starship.toml" << 'EOF'
# Obtenir l'aide sur la configuration : https://starship.rs/config/
format = """$username$hostname$directory$git_branch$git_status$cmd_duration$line_break$character"""

# Désactiver la nouvelle ligne par défaut
add_newline = false

[directory]
style = "blue bold"
truncation_length = 3
truncate_to_repo = true

[character]
success_symbol = "[❯](purple bold)"
error_symbol = "[❯](red bold)"
vimcmd_symbol = "[❮](green bold)"

[git_branch]
format = "[$branch]($style)"
style = "bright-black"

[git_status]
format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)"
style = "cyan"
conflicted = "​"
untracked = "​"
modified = "​"
staged = "​"
renamed = "​"
deleted = "​"
stashed = "≡"

[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bright-black"

[cmd_duration]
format = "[$duration]($style) "
style = "yellow"

[python]
format = "[$virtualenv]($style) "
style = "bright-black"

[username]
style_user = "white bold"
style_root = "black bold"
format = "[$user]($style) "
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "on [$hostname](bold red) "
disabled = false
EOF
                    ;;
            esac

            # Configuration pour ZSH
            if [ ! -f "$ZSHRC" ]; then
                touch "$ZSHRC"
            fi
            sed -i '/# Initialiser Starship/d' "$ZSHRC"
            sed -i '/eval "$(starship init/d' "$ZSHRC"
            echo -e "\n# Initialiser Starship\neval \"\$(starship init zsh)\"" >> "$ZSHRC"

            # Configuration pour Bash
            if [ ! -f "$HOME/.bashrc" ]; then
                touch "$HOME/.bashrc"
            fi
            sed -i '/# Initialiser Starship/d' "$HOME/.bashrc"
            sed -i '/eval "$(starship init/d' "$HOME/.bashrc"
            echo -e "\n# Initialiser Starship\neval \"\$(starship init bash)\"" >> "$HOME/.bashrc"
            ;;
    esac
}

#------------------------------------------------------------------------------
# SÉLECTION DE PLUGINS ZSH 
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

    # Suppression de la configuration existante
    sed -i '/fpath.*zsh-completions\/src/d' "$ZSHRC"
    sed -i '/source \$ZSH\/oh-my-zsh.sh/d' "$ZSHRC"
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
        echo -e "\n# Initialiser zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" >> "$ZSHRC"
    fi

    echo -e "\n# Initialiser oh-my-zsh\nsource \$ZSH/oh-my-zsh.sh" >> "$ZSHRC"

    # Sourcing des alias centralisés
    echo -e "\n# Source des alias personnalisés\n[ -f \"$HOME/.config/OhMyTermux/aliases\" ] && . \"$HOME/.config/OhMyTermux/aliases\"" >> "$ZSHRC"
}

#------------------------------------------------------------------------------
# INSTALLATION DES PAQUETS ADDITIONNELS
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        title_msg "❯ Configuration des packages"
        local DEFAULT_PACKAGES=("nala" "eza" "bat" "lf" "fzf")
        
        if $USE_GUM; then
            if $FULL_INSTALL; then
                PACKAGES=("${DEFAULT_PACKAGES[@]}")
            else
                # Convertir la sortie de gum en tableau
                IFS=$'\n' read -r -d '' -a PACKAGES < <(gum choose --no-limit \
                    --selected.foreground="33" \
                    --header.foreground="33" \
                    --cursor.foreground="33" \
                    --height=18 \
                    --header="Sélectionner avec espace les packages à installer :" \
                    --selected="nala" --selected="eza" --selected="bat" --selected="lf" --selected="fzf" \
                    "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" \
                    "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" \
                    "Tout installer")

                if [[ " ${PACKAGES[*]} " == *" Tout installer "* ]]; then
                    PACKAGES=("nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" \
                            "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu")
                fi
            fi
        else
            echo "Sélectionner les packages à installer (séparés par des espaces) :"
            echo
            echo -e "${COLOR_BLUE}1)  nala${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2)  eza${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3)  colorls${COLOR_RESET}"
            echo -e "${COLOR_BLUE}4)  lsd${COLOR_RESET}"
            echo -e "${COLOR_BLUE}5)  bat${COLOR_RESET}"
            echo -e "${COLOR_BLUE}6)  lf${COLOR_RESET}"
            echo -e "${COLOR_BLUE}7)  fzf${COLOR_RESET}"
            echo -e "${COLOR_BLUE}8)  glow${COLOR_RESET}"
            echo -e "${COLOR_BLUE}9)  tmux${COLOR_RESET}"
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
            read -r -e -p "" -i "1 2 5 6 7" PACKAGE_CHOICES
            tput sgr0
            tput cuu 23
            tput ed
            
            if [[ "$PACKAGE_CHOICES" == *"19"* ]]; then
                PACKAGES=("nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" \
                        "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu")
            else
                PACKAGES=()
                for CHOICE in $PACKAGE_CHOICES; do
                    case $CHOICE in
                        1) PACKAGES+=("nala") ;;
                        2) PACKAGES+=("eza") ;;
                        3) PACKAGES+=("colorls") ;;
                        4) PACKAGES+=("lsd") ;;
                        5) PACKAGES+=("bat") ;;
                        6) PACKAGES+=("lf") ;;
                        7) PACKAGES+=("fzf") ;;
                        8) PACKAGES+=("glow") ;;
                        9) PACKAGES+=("tmux") ;;
                        10) PACKAGES+=("python") ;;
                        11) PACKAGES+=("nodejs") ;;
                        12) PACKAGES+=("nodejs-lts") ;;
                        13) PACKAGES+=("micro") ;;
                        14) PACKAGES+=("vim") ;;
                        15) PACKAGES+=("neovim") ;;
                        16) PACKAGES+=("lazygit") ;;
                        17) PACKAGES+=("open-ssh") ;;
                        18) PACKAGES+=("tsu") ;;
                    esac
                done
            fi
        fi

        if [ ${#PACKAGES[@]} -gt 0 ]; then
            for PACKAGE in "${PACKAGES[@]}"; do
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
            echo -e "${COLOR_BLUE}1)  Police par défaut${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2)  CaskaydiaCove Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3)  FiraCode Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}4)  Hack Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}5)  JetBrainsMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}6)  Meslo Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}7)  RobotoMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}8)  SourceCodePro Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}9)  UbuntuMono Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}10) AnonymousPro Nerd Font${COLOR_RESET}"
            echo -e "${COLOR_BLUE}11) Terminus Nerd Font${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
            tput setaf 3
            read -r -e -p "" -i "1" CHOICE
            tput sgr0
            tput cuu 15
            tput ed
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
        local XFCE_VERSION="recommandée"
        local BROWSER_CHOICE="chromium"

        if ! $FULL_INSTALL; then
            if $USE_GUM; then
                if gum_confirm "Installer XFCE ?"; then
                    # Choix de la version
                    XFCE_VERSION=$(gum_choose "Sélectionner la version de XFCE à installer :" --height=5 --selected="recommandée" \
                    "minimale" \
                    "recommandée" \
                    "personnalisée")

                    # Sélection du navigateur (sauf pour la version minimale)
                    if [ "$XFCE_VERSION" != "minimale" ]; then
                        BROWSER_CHOICE=$(gum_choose "Séléctionner un navigateur web :" --height=5 --selected="chromium" "chromium" "firefox" "aucun")
                    fi
                else
                    return
                fi
            else
                printf "${COLOR_BLUE}Installer XFCE ? (O/n) : ${COLOR_RESET}"
                read -r -e -p "" -i "o" CHOICE
                if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                    echo -e "${COLOR_BLUE}Sélectionner la version de XFCE à installer :${COLOR_RESET}"
                    echo
                    echo "1) Minimale"
                    echo "2) Recommandée"
                    echo "3) Personnalisée"
                    echo
                    printf "${COLOR_GOLD}Entrez votre choix (1/2/3) : ${COLOR_RESET}"
                    tput setaf 3
                    read -r -e -p "" -i "2" CHOICE
                    tput sgr0
                    tput cuu 7
                    tput ed
                    case $CHOICE in
                        1) XFCE_VERSION="minimale" ;;
                        2) XFCE_VERSION="recommandée" ;;
                        3) XFCE_VERSION="personnalisée" ;;
                        *) XFCE_VERSION="recommandée" ;;
                    esac

                    if [ "$XFCE_VERSION" != "minimale" ]; then
                        echo -e "${COLOR_BLUE}Séléctionner un navigateur web :${COLOR_RESET}"
                        echo
                        echo "1) Chromium (par défaut)"
                        echo "2) Firefox"
                        echo "3) Aucun"
                        echo
                        printf "${COLOR_GOLD}Entrez votre choix (1/2/3) : ${COLOR_RESET}"
                        tput setaf 3
                        read -r -e -p "" -i "1" CHOICE
                        tput sgr0
                        tput cuu 7
                        tput ed
                        case $CHOICE in
                            1) BROWSER_CHOICE="chromium" ;;
                            2) BROWSER_CHOICE="firefox" ;;
                            3) BROWSER_CHOICE="aucun" ;;
                            *) BROWSER_CHOICE="chromium" ;;
                        esac
                    fi
                else
                    return
                fi
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installation des dépendances"

        PACKAGES=('wget' 'x11-repo' 'tur-repo' 'pulseaudio')

        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installation de $PACKAGE"
        done

        if $USE_GUM; then
            download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce_dev.sh" "XFCE" --gum --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
        else
            download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce_dev.sh" "XFCE" --version="$XFCE_VERSION" --browser="$BROWSER_CHOICE"
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
        title_msg "❯ Configuration de PRoot"
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "Téléchargement du script PRoot" || error_msg "Impossible de télécharger le script PRoot"
        execute_command "chmod +x proot_dev.sh" "Exécution du script PRoot"
        
        # Si les identifiants sont déjà fournis
        if [ -n "$PROOT_USERNAME" ] && [ -n "$PROOT_PASSWORD" ]; then
            if $USE_GUM; then
                execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "PRoot" --gum --username="$PROOT_USERNAME" --password="$PROOT_PASSWORD"
                install_utils
            else
                execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "PRoot" --username="$PROOT_USERNAME" --password="$PROOT_PASSWORD"
                install_utils
            fi
        else
            if $USE_GUM; then
                if gum_confirm "Installer Debian PRoot ?"; then
                    execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                    download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot_dev.sh" "PRoot" --gum
                    install_utils
                fi
            else    
                printf "${COLOR_BLUE}Installer Debian PRoot ? (O/n) : ${COLOR_RESET}"
                read -r -e -p "" -i "o" CHOICE
                tput cuu1
                tput el
                if [[ "$CHOICE" =~ ^[oO]$ ]]; then
                    execute_command "pkg install proot-distro -y" "Installation de proot-distro"
                    ./proot_dev.sh
                    install_utils
                fi
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
    download_and_execute "https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/utils_fr.sh" "Utils"

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
            if gum_confirm "Installer Termux-X11 ?"; then
                INSTALL_X11=true
            fi
        else
            printf "${COLOR_BLUE}Installer Termux-X11 ? (O/n) : ${COLOR_RESET}"
            read -r -e -p "" -i "n" choice
            tput cuu1
            tput el
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
        info_msg "Installation des dépendances"
        pkg install -y ncurses-utils >/dev/null 2>&1
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
    install_termux_x11
fi

# Finalisation
title_msg "❯ Sauvegarde des scripts d'installation"
mkdir -p $HOME/.config/OhMyTermux >/dev/null 2>&1
mv -f xfce_dev.sh proot_dev.sh utils_fr.sh install_dev.sh $HOME/.config/OhMyTermux/ >/dev/null 2>&1

# Rechargement du shell
if $USE_GUM; then
    if gum_confirm "Exécuter OhMyTermux ?"; then
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
    read -r -e -p "" -i "o" choice
    if [[ "$choice" =~ ^[oO]$ ]]; then
        clear
        if [ "$SHELL_CHOICE" = true ]; then
            exec zsh -l
        else
            exec $SHELL_CHOICE
        fi
    else
        tput cuu1
        tput el
        echo -e "${COLOR_BLUE}Pour utiliser toutes les fonctionnalités :${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Saisir : ${COLOR_RESET} ${COLOR_GREEN}exec zsh -l${COLOR_RESET}"
        echo -e "${COLOR_BLUE}- Ou redémarrer Termux${COLOR_RESET}"
    fi
fi