#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES DE CONTROLE PRINCIPALE
#------------------------------------------------------------------------------
# Note: Active l'interface utilisateur interactive avec gum
USE_GUM=false

# Note: Détermine si la configuration initiale doit être exécutée
EXECUTE_INITIAL_CONFIG=true

# Note: Active l'affichage détaillé des opérations
VERBOSE=false

#------------------------------------------------------------------------------
# SELECTEURS DE MODULES
#------------------------------------------------------------------------------
# Note: Active l'installation et configuration du shell (zsh/bash)
SHELL_CHOICE=false

# Note: Active l'installation des paquets additionnels
PACKAGES_CHOICE=false

# Note: Active l'installation des polices personnalisées
FONT_CHOICE=false
    
# Note: Active l'installation de l'environnement XFCE et Debian Proot
XFCE_CHOICE=false

# Note: Active l'installation complète de tous les modules sans confirmation
FULL_INSTALL=false

# Note: Active l'utilisation de gum pour toutes les interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# FICHIERS DE CONFIGURATION
#------------------------------------------------------------------------------
# Note: Chemin vers le fichier de configuration Bash
BASHRC="$HOME/.bashrc"

# Note: Chemin vers le fichier de configuration Zsh
ZSHRC="$HOME/.zshrc"

# TODO: Fish
# Note: Chemin vers le fichier de configuration Fish
#FISHRC="$HOME/.config/fish/config.fish"

#------------------------------------------------------------------------------
# CODES COULEUR POUR L'AFFICHAGE
#------------------------------------------------------------------------------
# Note: Définition des codes ANSI pour la colorisation des sorties
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Succès
COLOR_GOLD='\033[38;5;220m'   # Avertissement
COLOR_RED='\033[38;5;196m'    # Erreur
COLOR_RESET='\033[0m'         # Réinitialisation

# Note: Configuration de la redirection
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
else
    redirect=""
fi

#------------------------------------------------------------------------------
# FONCTION D'AIDE
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
    echo "  --package | -pkg  Module d'installation des packagés"
    echo "  --font | -f       Module d'installation de la police"
    echo "  --xfce | -x       Module d'installation de XFCE et Debian Proot"
    echo "  --skip | -sk      Ignorer la configuration initiale"
    echo "  --uninstall| -u   Désinstallation de Debian Proot"
    echo "  --help | -h       Afficher ce message d'aide"
    echo "  --full | -f       Installer tous les modules sans confirmation"
}

#------------------------------------------------------------------------------
# GESTION DES ARGUMENTS
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
        # TODO: Fonction de désinstalation à implémenter
        #--uninstall|-u)
        #    uninstall_proot
        #    exit 0
        #    ;;
        --verbose|-v)
            verbose=true
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

# Note: Activer tous les modules si --gum|-g est utilisé comme seul argument
if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    SCRIPT_CHOICE=true
fi

#------------------------------------------------------------------------------
# AFFICHAGE DES MESSAGES D'INFORMATION
#------------------------------------------------------------------------------
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# AFFICHAGE DES MESSAGES DE SUCCÈS
#------------------------------------------------------------------------------
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# AFFICHAGE DES MESSAGES D'ERREUR
#------------------------------------------------------------------------------
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# JOURNALISATION DES ERREURS
#------------------------------------------------------------------------------
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/ohmytermux.log"
}

#------------------------------------------------------------------------------
# EXECUTION D'UNE COMMANDE ET AFFICHAGE DU RÉSULTAT
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
# CONFIRMATION AVEC GUM
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
# SÉLECTION AVEC GUM
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
# VÉRIFICATION ET INSTALLATION DE GUM
#------------------------------------------------------------------------------
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

# FIXME: Déplacer dans la fonction principale
check_and_install_gum

#------------------------------------------------------------------------------
# GESTION DES ERREURS
#------------------------------------------------------------------------------
finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
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
            --width 40 \
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
    local backup_dir="$HOME/.backup"
    
    # Création du répertoire de sauvegarde
    execute_command "mkdir -p \"$backup_dir\"" "Création du répertoire ~/.backup"

    # Liste des fichiers à sauvegarder
    local files_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        #"$0"
    )

    # Copie des fichiers dans le répertoire de sauvegarde
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            execute_command "cp \"$file\" \"$backup_dir/\"" "Sauvegarde de $(basename "$file")"
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
        read -r choice
        [[ "$choice" =~ ^[oO]$ ]] && termux-change-repo
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
            read -r choice
            [[ "$choice" =~ ^[oO]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# CONFIGURATION DE TERMUX
#------------------------------------------------------------------------------
configure_termux() {

    info_msg "❯ Configuration de Termux"

    # Appel de la fonction de sauvegarde
    create_backups

    termux_dir="$HOME/.termux"

    # Configuration de colors.properties
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
EOL" "Installation du thème TokyoNight"
    fi

    # Configuration de termux.properties
    file_path="$termux_dir/termux.properties"
    if [ ! -f "$file_path" ]; then
        execute_command "cat > \"$file_path\" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Configuration des propriétés Termux"
    fi
    
    # Suppression de la bannière de connexion
    execute_command "touch $HOME/.hushlogin" "Suppression de la bannière de connexion"
    # Téléchargement de la police
    execute_command "curl -fLo \"$HOME/.termux/font.ttf\" https://github.com/GiGiDKR/OhMyTermux/raw/dev/src/font.ttf" "Téléchargement de la police par défaut" || error_msg "Impossible de télécharger la police par défaut"
    termux-reload-settings
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
        read -r choice
        if [ "$choice" = "oO" ]; then
            configure_termux
        fi
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DU SHELL
#------------------------------------------------------------------------------
install_shell() {
    if $SHELL_CHOICE; then
        info_msg "❯ Configuration du shell"
        if $USE_GUM; then
            shell_choice=$(gum_choose "Choisissez le shell à installer :" --selected="zsh" --height=5 "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choisissez le shell à installer :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
            printf "${COLOR_GOLD}Entrez le numéro de votre choix : ${COLOR_RESET}"
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
                echo -e "${COLOR_BLUE}Bash sélectionné${COLOR_RESET}"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    execute_command "pkg install -y zsh" "Installation de ZSH"
                else
                    success_msg="✓ Zsh déjà installé"
                fi

                # Installation de Oh My Zsh et autres configurations ZSH
                info_msg "❯ Configuration de ZSH"
                if $USE_GUM; then
                    if gum_confirm "Installer Oh-My-Zsh ?"; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        # FIXME: Optionel ?
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Installer Oh-My-Zsh ? (O/n) : ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[oO]$ ]]; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        # FIXME: Optionel ? 
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/zshrc" "Téléchargement de la configuration" || error_msg "Impossible de télécharger la configuration"

                if $USE_GUM; then
                    if gum_confirm "Installer PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Installer le prompt OhMyTermux ?"; then                            
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Téléchargement du prompt OhMyTermux" || error_msg "Impossible de télécharger le prompt OhMyTermux"
                            echo -e "\n# Pour customiser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt en exécutant 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Installer PowerLevel10k ? (O/n) : ${COLOR_RESET}"
                    read -r choice
                    if [[ "$choice" =~ ^[oO]$ ]]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Installer le prompt OhMyTermux ? (O/n) : ${COLOR_RESET}"
                        read -r choice
                        if [[ "$choice" =~ ^[oO]$ ]]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/p10k.zsh" "Téléchargement du prompt OhMyTermux" || error_msg "Impossible de télécharger le prompt OhMyTermux"
                            echo -e "\n# Pour customiser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt en exécutant 'p10k configure'.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/aliases.zsh && 
                    mkdir -p $HOME/.config/OhMyTermux && \
                    curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/src/help.md)" "Téléchargement de la configuration" || error_msg "Impossible de télécharger la configuration"

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_RED}ZSH n'est pas installé. Impossible d'installer les plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                info_msg "❯ Configuration de Fish"
                execute_command "pkg install -y fish" "Installation de Fish"
                # TODO: Fish 
                chsh -s fish
                ;;
        esac
    fi
}

#------------------------------------------------------------------------------
# SÉLECTION DES PLUGINS ZSH 
#------------------------------------------------------------------------------
install_zsh_plugins() {
    local plugins_to_install=()
    if $USE_GUM; then
        mapfile -t plugins_to_install < <(gum_choose "Sélectionner avec ESPACE les plugins à installer :" --height=8 --selected="Tout installer" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder" "Tout installer")
        if [[ " ${plugins_to_install[*]} " == *" Tout installer "* ]]; then
            plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-alias-finder")
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

    # Définir les variables nécessaires
    local zshrc="$HOME/.zshrc"
    local selected_plugins="${plugins_to_install[*]}"
    local has_completions=false
    local has_ohmytermux=true  # Adapter selon votre configuration

    # Vérifier si zsh-completions est installé
    if [[ " ${plugins_to_install[*]} " == *" zsh-completions "* ]]; then
        has_completions=true
    fi

    update_zshrc "$zshrc" "$selected_plugins" "$has_completions" "$has_ohmytermux"
}

#------------------------------------------------------------------------------
# INSTALLATION DES PLUGINS ZSH
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
        execute_command "git clone '$plugin_url' '$HOME/.oh-my-zsh/custom/plugins/$plugin_name' --quiet" "Installation de $plugin_name"
    else
        info_msg "$plugin_name est déjà installé"
    fi
}

#------------------------------------------------------------------------------
# MISE À JOUR DE LA CONFIGURATION DE ZSH
#------------------------------------------------------------------------------
update_zshrc() {
    local zshrc="$1"
    local selected_plugins="$2"
    local has_completions="$3"
    local has_ohmytermux="$4"

    # Vérifier si le fichier existe, sinon le créer avec la configuration de base
    if [ ! -f "$zshrc" ]; then
        cat > "$zshrc" << 'EOL'
# Path to your oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh

# Theme configuration
ZSH_THEME="powerlevel10k/powerlevel10k"

EOL
    fi

    sed -i '/fpath.*zsh-completions\/src/d; /^# Load zsh-completions/!d' "$zshrc"

    # Mettre à jour la section plugins
    local default_plugins="git command-not-found copyfile node npm timer vscode web-search z"
    local filtered_plugins=$(echo "$selected_plugins" | sed 's/zsh-completions//g')
    local all_plugins="$default_plugins $filtered_plugins"

    # Créer le contenu de la section plugins
    local plugins_section="plugins=(\n"
    for plugin in $all_plugins; do
        plugins_section+="    $plugin\n"
    done
    plugins_section+=")\n"

    # Sauvegarder temporairement le contenu avant la section plugins
    sed -n '1,/^plugins=(/{/^plugins=(/!p}' "$zshrc" > "$zshrc.tmp"

    # Sauvegarder le contenu après source $ZSH/oh-my-zsh.sh
    sed -n '/source \$ZSH\/oh-my-zsh.sh/,$p' "$zshrc" > "$zshrc.tmp2"

    # Reconstruire le fichier
    cat "$zshrc.tmp" > "$zshrc"
    echo -e "$plugins_section" >> "$zshrc"

    # Ajouter zsh-completions path si nécessaire
    if [ "$has_completions" = "true" ]; then
        echo -e "# Charger zsh-completions\nfpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src\n" >> "$zshrc"
    fi

    echo "# Charger oh-my-zsh" >> "$zshrc"
    echo "source \$ZSH/oh-my-zsh.sh" >> "$zshrc"

    # Restaurer le reste du contenu
    if [ -f "$zshrc.tmp2" ]; then
        grep -v "source \$ZSH/oh-my-zsh.sh" "$zshrc.tmp2" >> "$zshrc"
    fi

    # Nettoyer les fichiers temporaires
    rm -f "$zshrc.tmp" "$zshrc.tmp2"

    if [ "$has_ohmytermux" = "true" ]; then
        sed -i '/# Pour customiser le prompt, exécuter/d' "$zshrc"
        sed -i '/\[\[ ! -f ~\/.p10k.zsh \]\] || source/d' "$zshrc"

        echo -e "\n# Pour customiser le prompt, exécuter \`p10k configure\` ou éditer ~/.p10k.zsh." >> "$zshrc"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DES PAQUETS ADDITIONNELS
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        info_msg "❯ Configuration des packages"
        if $USE_GUM; then
            PACKAGES=$(gum_choose "Sélectionner avec espace les packages à installer :" --no-limit --height=12 --selected="nala,eza,bat,lf,fzf" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
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
# CONFIGURATION DES ALIAS COMMUNS
#------------------------------------------------------------------------------
common_alias() {
    # Création du fichier d'alias centralisé
    execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Création du dossier de configuration"
    
    aliases_file="$HOME/.config/OhMyTermux/aliases"
    
    cat > "$aliases_file" << 'EOL'
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

# Git
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
EOL

    # Ajout du sourcing dans .bashrc
    echo -e "\n# Source des alias personnalisés\n[ -f \"$aliases_file\" ] && . \"$aliases_file\"" >> "$BASHRC"

    # Ajout du sourcing dans .zshrc si existant
    if [ -f "$ZSHRC" ]; then
        echo -e "\n# Source des alias personnalisés\n[ -f \"$aliases_file\" ] && . \"$aliases_file\"" >> "$ZSHRC"
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DE LA POLICE
#------------------------------------------------------------------------------
install_font() {
    if $FONT_CHOICE; then
        info_msg "❯ Configuration de la police"
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
            read -r choice
            tput sgr0
            case $choice in
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
                success_msg "✓ Police par défaut installée"
                ;;
            *)
                font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
                execute_command "curl -L -o $HOME/.termux/font.ttf \"$font_url\"" "Installation de $FONT"
                termux-reload-settings
                ;;
        esac

    fi
}

# Note: Variable globale pour suivre si XFCE ou Proot a été installé
INSTALL_UTILS=false

#------------------------------------------------------------------------------
# INSTALLATION DE L'ENVIRONNEMENT XFCE
#------------------------------------------------------------------------------
install_xfce() {
    if $XFCE_CHOICE; then
        info_msg "❯ Configuration de XFCE"
        if $USE_GUM; then
            if ! gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer XFCE ?"; then
                return
            fi
        else
            printf "${COLOR_BLUE}Installer XFCE ? (O/n) : ${COLOR_RESET}"
            read -r choice
            if [ "$choice" != "o" ]; then
                return
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installation des dépendances"

        PACKAGES=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')
    
        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installation de $PACKAGE"
        done
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/xfce-FR.sh" "Téléchargement du script XFCE" || error_msg "Impossible de télécharger le script XFCE"
        execute_command "chmod +x xfce-FR.sh" "Attribution des permissions d'exécution"
        
        if $USE_GUM; then
            ./xfce-FR.sh --gum
        else
            ./xfce-FR.sh
        fi
        
        INSTALL_UTILS=true
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DE DEBIAN PROOT
#------------------------------------------------------------------------------
install_proot() {
    info_msg "❯ Configuration de Proot"
    if $USE_GUM; then
        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Debian Proot ?"; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot-FR.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
            execute_command "chmod +x proot-FR.sh" "Attribution des permissions d'exécution"
            ./proot-FR.sh --gum
            INSTALL_UTILS=true
        fi
    else    
        printf "${COLOR_BLUE}Installer Debian Proot ? (O/n) : ${COLOR_RESET}"
        read -r choice
        if [[ "$choice" =~ ^[oO]$ ]]; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/proot-FR.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
            execute_command "chmod +x proot-FR.sh" "Attribution des permissions d'exécution"
            ./proot-FR.sh
            INSTALL_UTILS=true
        fi
    fi
}

#------------------------------------------------------------------------------
# RECUPERATION DU NOM D'UTILISATEUR
#------------------------------------------------------------------------------
get_username() {
    local user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    local username
    username=$(ls -1 "$user_dir" 2>/dev/null | grep -v '^$' | head -n 1)
    if [ -z "$username" ]; then
        echo "Aucun utilisateur trouvé" >&2
        return 1
    fi
    echo "$username"
}

#------------------------------------------------------------------------------
# INSTALLATION DES UTILITAIRES
#------------------------------------------------------------------------------
install_utils() {
    if [ "$INSTALL_UTILS" = true ]; then
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/dev/utils.sh" "Téléchargement du script Utils" || error_msg "Impossible de télécharger le script Utils"
        execute_command "chmod +x utils.sh" "Attribution des permissions d'exécution"
        ./utils.sh

        if ! username=$(get_username); then
            error_msg "Impossible de récupérer le nom d'utilisateur."
            return 1
        fi

        bashrc_proot="${PREFIX}/var/lib/proot-distro/installed-rootfs/debian/home/${username}/.bashrc"
        if [ ! -f "$bashrc_proot" ]; then
            error_msg "Le fichier .bashrc n'existe pas pour l'utilisateur $username."
            execute_command "proot-distro login debian --shared-tmp --env DISPLAY=:1.0 -- touch \"$bashrc_proot\"" "Création du fichier .bashrc"
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
alias start='echo "Veuillez exécuter depuis Termux et non Debian proot."'
alias cm="chmod +x"
alias clone="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"
alias bashrc="nano \$HOME/.bashrc"
EOL

        username=$(get_username)

        tmp_file="${TMPDIR}/rc_content"
        touch "$tmp_file"

        cat << EOL >> "$tmp_file"

# Alias pour se connecter à Debian Proot
alias debian="proot-distro login debian --shared-tmp --user ${username}"
EOL

        if [ -f "$BASHRC" ]; then
            cat "$tmp_file" >> "$BASHRC"
            success_msg "✓ Configuration de .bashrc termux"
        else
            touch "$BASHRC" 
            cat "$tmp_file" >> "$BASHRC"
            success_msg "✓ Création et configuration de .bashrc termux"
        fi

        if [ -f "$ZSHRC" ]; then
            cat "$tmp_file" >> "$ZSHRC"
            success_msg "✓ Configuration de .zshrc termux"
        else
            touch "$ZSHRC"
            cat "$tmp_file" >> "$ZSHRC"
            success_msg "✓ Création et configuration de .zshrc termux"
        fi

        rm "$tmp_file"
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DE TERMUX-X11
#------------------------------------------------------------------------------
install_termux_x11() {
    info_msg "❯ Configuration de Termux-X11"
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
        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Termux-X11 ?"; then
            install_x11=true
        fi
        else
            printf "${COLOR_BLUE}Installer Termux-X11 ? (O/n) : ${COLOR_RESET}"
            read -r choice
            if [[ "$choice" =~ ^[oO]$ ]]; then
                install_x11=true
            fi
        fi

        if $install_x11; then
            local apk_url="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
            local apk_file="$HOME/storage/downloads/termux-x11.apk"

        execute_command "wget \"$apk_url\" -O \"$apk_file\"" "Téléchargement de Termux-X11"

        if [ -f "$apk_file" ]; then
            termux-open "$apk_file"
            echo -e "${COLOR_BLUE}Veuillez installer l'APK manuellement.${COLOR_RESET}"
            echo -e "${COLOR_BLUE}Une fois l'installation terminée, appuyez sur Entrée pour continuer.${COLOR_RESET}"
            read -r
            rm "$apk_file"
        else
            error_msg "✗ Erreur lors de l'installation de Termux-X11"
        fi
    fi
}

#------------------------------------------------------------------------------
# FONCTION PRINCIPALE
#------------------------------------------------------------------------------
show_banner

# Note: Installation des dépendances nécessaires
if $USE_GUM; then
    execute_command "pkg install -y ncurses-utils" "Installation des dépendances"
else
    execute_command "pkg install -y ncurses-utils >/dev/null 2>&1" "Installation des dépendances"
fi

# Note: Vérifier si des arguments spécifiques ont été fournis
if [ "$SHELL_CHOICE" = true ] || [ "$PACKAGES_CHOICE" = true ] || [ "$FONT_CHOICE" = true ] || [ "$XFCE_CHOICE" = true ]; then
    # Exécuter uniquement les fonctions demandées
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
    # Note: Exécuter l'installation complète si aucun argument spécifique n'est fourni
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

# Note: Nettoyage et message de fin
info_msg "❯ Nettoyage des fichiers temporaires"
rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1
success_msg "✓ Suppression des scripts d'installation"

# Note: Rechargement du shell
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Exécuter OhMyTermux (recharger le shell) ?"; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}Pour utiliser toutes les fonctionnalités, saisir :${COLOR_RESET}"
        echo -e "${COLOR_GREEN}exec zsh -l${COLOR_RESET} ${COLOR_BLUE}(recommandé - recharge complètement le shell)${COLOR_RESET}"
        echo -e "${COLOR_GREEN}source ~/.zshrc${COLOR_RESET} ${COLOR_BLUE}(recharge uniquement .zshrc)${COLOR_RESET}"
        echo -e "${COLOR_BLUE}Ou redémarrer Termux${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Exécuter OhMyTermux ? (O/n) : ${COLOR_RESET}"
    read -r choice
    if [[ "$choice" =~ ^[oO]$ ]]; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}OhMyTermux sera actif au prochain démarrage de Termux.${COLOR_RESET}"
    fi
fi