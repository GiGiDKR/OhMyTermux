#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES DE CONTROLE PRINCIPALE
#------------------------------------------------------------------------------
# USE_GUM: Active l'interface utilisateur interactive avec gum
USE_GUM=false

# EXECUTE_INITIAL_CONFIG: Détermine si la configuration initiale doit être exécutée
EXECUTE_INITIAL_CONFIG=true

# VERBOSE: Active l'affichage détaillé des opérations
VERBOSE=false

#------------------------------------------------------------------------------
# SELECTEURS DE MODULES
#------------------------------------------------------------------------------
# SHELL_CHOICE: Active l'installation et configuration du shell (zsh/bash)
SHELL_CHOICE=false

# PACKAGES_CHOICE: Active l'installation des paquets additionnels
PACKAGES_CHOICE=false

# FONT_CHOICE: Active l'installation des polices personnalisées
FONT_CHOICE=false
    
# XFCE_CHOICE: Active l'installation de l'environnement XFCE et Debian Proot
XFCE_CHOICE=false

# FULL_INSTALL: Active l'installation complète de tous les modules sans confirmation
FULL_INSTALL=false

# ONLY_GUM: Active l'utilisation de gum pour toutes les interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# FICHIERS DE CONFIGURATION
#------------------------------------------------------------------------------
# Chemin vers le fichier de configuration Bash
BASHRC="$HOME/.bashrc"

# Chemin vers le fichier de configuration Zsh
ZSHRC="$HOME/.zshrc"

#TODO 
# Chemin vers le fichier de configuration Fish
#FISHRC="$HOME/.config/fish/config.fish"

#------------------------------------------------------------------------------
# CODES COULEUR POUR L'AFFICHAGE
#------------------------------------------------------------------------------
# Définition des codes ANSI pour la colorisation des sorties
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Succès
COLOR_GOLD='\033[38;5;220m'   # Avertissement
COLOR_RED='\033[38;5;196m'    # Erreur
COLOR_RESET='\033[0m'         # Réinitialisation

# Configuration de la redirection
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

# Activer tous les modules si --gum|-g est utilisé comme seul argument
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

#FIX 
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
        printf "${COLOR_BLUE}Changer le miroir des dépôts ? (o/n) : ${COLOR_RESET}"
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
            printf "${COLOR_BLUE}Autoriser l'accès au stockage ? (o/n) : ${COLOR_RESET}"
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
    #FIX 
    #file_path="$termux_dir/colors.properties"
    file_path="$termux_dir/colors.properties.debug"
    if [ ! -f "$file_path" ]; then
        mkdir -p "$termux_dir"
        cat > "$file_path" << 'EOL'
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
EOL
        success_msg "Installation du thème TokyoNight"
    fi

    # Configuration de termux.properties
    file_path="$termux_dir/termux.properties"
    if [ ! -f "$file_path" ]; then
        cat > "$file_path" << 'EOL'
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL
        success_msg "Configuration des propriétés Termux"
    fi
    
    # Suppression de la bannière de connexion
    execute_command "touch $HOME/.hushlogin" "Suppression de la bannière de connexion"
    # Téléchargement de la police
    execute_command "curl -fLo \"$HOME/.termux/font.ttf\" https://github.com/GiGiDKR/OhMyTermux/raw/1.1.0/files/font.ttf" "Téléchargement de la police par défaut" || error_msg "Impossible de télécharger la police par défaut"
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
        printf "${COLOR_BLUE}Activer la configuration recommandée ? (o/n) : ${COLOR_RESET}"
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
                        #FIX 
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    printf "${COLOR_BLUE}Installer Oh-My-Zsh ? (o/n) : ${COLOR_RESET}"
                    read -r choice
                    if [ "$choice" = "o" ]; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des dépendances"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        #FIX 
                        #cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/files/zshrc" "Téléchargement de la configuration" || error_msg "Impossible de télécharger la configuration"

                if $USE_GUM; then
                    if gum_confirm "Installer PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum_confirm "Installer le prompt OhMyTermux ?"; then                            
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/files/p10k.zsh" "Téléchargement du prompt OhMyTermux" || error_msg "Impossible de télécharger le prompt OhMyTermux"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                else
                    printf "${COLOR_BLUE}Installer PowerLevel10k ? (o/n) : ${COLOR_RESET}"
                    read -r choice
                    if [ "$choice" = "o" ]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        printf "${COLOR_BLUE}Installer le prompt OhMyTermux ? (o/n) : ${COLOR_RESET}"
                        read -r choice
                        if [ "$choice" = "o" ]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/files/p10k.zsh" "Téléchargement du prompt OhMyTermux" || error_msg "Impossible de télécharger le prompt OhMyTermux"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/files/aliases.zsh && 
                    mkdir -p $HOME/.config/OhMyTermux && \
                    curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/files/help.md)" "Téléchargement de la configuration" || error_msg "Impossible de télécharger la configuration"

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
                #TODO 
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

    update_zshrc "${plugins_to_install[@]}"
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
    local plugins=("$@")
    local default_plugins=(git command-not-found copyfile node npm vscode web-search timer)
    plugins+=("${default_plugins[@]}")

    # Supprimer les doublons et zsh-completions de la liste des plugins
    readarray -t unique_plugins < <(printf '%s\n' "${plugins[@]}" | grep -v "zsh-completions" | sort -u)

    # Vérifier si zsh-completions est dans la liste originale des plugins
    local has_completions=false
    if [[ " ${plugins[*]} " == *" zsh-completions "* ]]; then
        has_completions=true
    fi

    # Créer la nouvelle section plugins
    local new_plugins_section="plugins=("
    for plugin in "${unique_plugins[@]}"; do
        new_plugins_section+="$plugin "
    done
    new_plugins_section+=")"

    # Mettre à jour le fichier zshrc
    if $has_completions; then
        if ! grep -q "fpath+=.*zsh-completions" "$ZSHRC"; then
            if grep -q "# Load oh-my-zsh" "$ZSHRC"; then
                sed -i "/# Load oh-my-zsh/i\\fpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src\n" "$ZSHRC"
            elif grep -q "source.*oh-my-zsh.sh" "$ZSHRC"; then
                sed -i "/source.*oh-my-zsh.sh/i\\fpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src\n" "$ZSHRC"
            else
                sed -i '1i\fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src\n' "$ZSHRC"
            fi
        fi
    fi

    # Trouver la position de source $ZSH/oh-my-zsh.sh
    if grep -q "source.*oh-my-zsh.sh" "$ZSHRC"; then
        local source_line=$(grep -n "source.*oh-my-zsh.sh" "$ZSHRC" | cut -d: -f1)
        sed -i "${source_line}i\\${new_plugins_section}\n" "$ZSHRC"
    else
        echo -e "\n${new_plugins_section}" >> "$ZSHRC"
        echo -e "\nsource \$ZSH/oh-my-zsh.sh\n" >> "$ZSHRC"
    fi
}

#------------------------------------------------------------------------------
# INSTALLATION DES PAQUETS ADDITIONNELS
#------------------------------------------------------------------------------
install_packages() {
    if $PACKAGES_CHOICE; then
        info_msg "❯ Configuration des packages"
        if $USE_GUM; then
            PACKAGES=$(gum_choose "Sélectionner avec espace les packages à installer :" --no-limit --height=12 --selected="nala,eza,bat,lf,fzf,python" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
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

                # Managing aliases by installed package
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
                    #TODO 
                esac
            done
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
    case $package in
        eza)
            echo -e '\nalias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"' >> "$BASHRC"
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"' >> "$ZSHRC"
            fi
            ;;
        bat)
            echo -e '\nalias cat="bat"' >> "$BASHRC"
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias cat="bat"' >> "$ZSHRC"
            fi
            ;;
        nala)
            echo -e '\nalias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"' >> "$BASHRC"
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"' >> "$ZSHRC"
            fi
            ;;
        #TODO 
    esac
}

#------------------------------------------------------------------------------
# CONFIGURATION DES ALIAS COMMUNS
#------------------------------------------------------------------------------
common_alias() {
aliases="
alias ..=\"cd ..\"
alias ...=\"cd ../..\"
alias ....=\"cd ../../..\"
alias .....=\"cd ../../../..\"
alias h=\"history\"
alias q=\"exit\"
alias c=\"clear\"
alias md=\"mkdir\"
alias rm=\"rm -rf\"
alias s=\"source\"
alias n=\"nano\"
alias bashrc=\"nano \$HOME/.bashrc\"
alias zshrc=\"nano \$HOME/.zshrc\"
alias cm=\"chmod +x\"
alias g=\"git\"
alias gc=\"git clone\"
alias push=\"git pull && git add . && git commit -m 'mobile push' && git push\""

echo -e "$aliases" >> "$BASHRC"

if [ -f "$ZSHRC" ]; then
    echo -e "$aliases" >> "$ZSHRC"
fi

#TODO 
#if [ -f "$HOME/.config/fish/config.fish" ]; then
#    # Convertir les alias bash en format fish
#    echo "$aliases" | sed 's/alias \(.*\)="\(.*\)"/alias \1 "\2"/' >> "$HOME/.config/fish/config.fish"
#fi
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

# Variable globale pour suivre si XFCE ou Proot a été installé
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
            printf "${COLOR_BLUE}Installer XFCE ? (o/n) : ${COLOR_RESET}"
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
        
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/xfce.sh" "Téléchargement du script XFCE" || error_msg "Impossible de télécharger le script XFCE"
        execute_command "chmod +x xfce.sh" "Attribution des permissions d'exécution"
        
        if $USE_GUM; then
            ./xfce.sh --gum
        else
            ./xfce.sh
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
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/proot.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
            execute_command "chmod +x proot.sh" "Attribution des permissions d'exécution"
            ./proot.sh --gum
            INSTALL_UTILS=true
        fi
    else    
        printf "${COLOR_BLUE}Installer Debian Proot ? (o/n) : ${COLOR_RESET}"
        read -r choice
        if [ "$choice" = "o" ]; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/proot.sh" "Téléchargement du script Proot" || error_msg "Impossible de télécharger le script Proot"
            execute_command "chmod +x proot.sh" "Attribution des permissions d'exécution"
            ./proot.sh
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
    username=$(find "$user_dir" -maxdepth 1 -type d -printf "%f\n" | grep -v '^$' | head -n 1)
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
    if $INSTALL_UTILS; then
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.1.0/utils.sh" "Téléchargement du script Utils" || error_msg "Impossible de télécharger le script Utils"
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

        # Ajout au fichier $BASHRC
        bashrc_content="
get_username() {
    user_dir=\"\$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home\"
    username=\$(find \"\$user_dir\" -maxdepth 1 -type d -printf \"%f\\n\" | grep -v '^$' | head -n 1)
    if [ -z \"\$username\" ]; then
        echo \"Aucun utilisateur trouvé\" >&2
        return 1
    fi
    echo \"\$username\"
}

alias debian=\"proot-distro login debian --shared-tmp --user \$(get_username)\"
"

        execute_command "echo '$bashrc_content' >> '$BASHRC'" "Configuration .bashrc termux"

        # Ajout au fichier $ZSHRC si existant
        if [ -f "$ZSHRC" ]; then
            execute_command "echo '$bashrc_content' >> '$ZSHRC'" "Configuration .zshrc termux"
        fi
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
            printf "${COLOR_BLUE}Installer Termux-X11 ? (o/n) : ${COLOR_RESET}"
            read -r choice
            if [ "$choice" = "o" ]; then
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
if $EXECUTE_INITIAL_CONFIG; then
    initial_config
fi
if $USE_GUM; then
    execute_command "pkg install -y ncurses-utils" "Installation des dépendances"
else
    execute_command "pkg install -y ncurses-utils >/dev/null 2>&1" "Installation des dépendances"
fi
install_shell
install_packages
common_alias
install_font
install_xfce
install_proot
install_utils
install_termux_x11
info_msg "❯ Nettoyage des fichiers temporaires"
rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1
success_msg "✓ Suppression des scripts d'installation"

# Exécution de OhMyTermux
if $USE_GUM; then
    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Exécuter OhMyTermux ?"; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}OhMyTermux sera actif au prochain démarrage de Termux.${COLOR_RESET}"
    fi
else
    printf "${COLOR_BLUE}Exécuter OhMyTermux ? (o/n) : ${COLOR_RESET}"
    read -r choice
    if [ "$choice" = "o" ]; then
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