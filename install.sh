#!/bin/bash

# Variables globales
USE_GUM=false
EXECUTE_INITIAL_CONFIG=true
SHELL_CHOICE=false
PACKAGES_CHOICE=false
PLUGIN_CHOICE=false
FONT_CHOICE=false
XFCE_CHOICE=false
SCRIPT_CHOICE=false
VERBOSE=false

ONLY_GUM=true

# Variables de fichiers de configuration
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

# Couleurs en variables
COLOR_BLUE="\e[38;5;33m"
COLOR_RED="\e[38;5;196m"
COLOR_RESET="\e[0m"

# Configuration de la redirection
if [ "$VERBOSE" = false ]; then
    redirect="> /dev/null 2>&1"
else
    redirect=""
fi

# Fonction pour afficher l'aide
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
    echo "  --plugin | -plg   Module d'installation de packages Python"
    echo "  --font | -f       Module d'installation de la police"
    echo "  --xfce | -x       Module d'installation de XFCE et Debian Proot"
    echo "  --script| -sc     Module d'installation de OhMyTermuxScript"
    echo "  --skip | -sk      Ignorer la configuration initiale"
    echo "  --uninstall| -u   Désinstallation de Debian Proot"
    echo "  --help | -h       Afficher ce message d'aide"
}

# Gestion des arguments
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
        --plugin|-plg)
            PLUGIN_CHOICE=true
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
            ONLY_GUM=fals 
            shift
            ;;
        --script|-sc)
            SCRIPT_CHOICE=true
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
        --help|-h)
            show_help
            exit 0
            ;;
    esac
done

# Activer tous les modules si --gum est utilisé seul
if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    PLUGIN_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    SCRIPT_CHOICE=true
fi

# Fonction pour afficher des messages d'information en bleu
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Fonction pour afficher des messages de succès en vert
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "\e[38;5;82m$1\e[0m"
    fi
}

# Fonction pour afficher des messages d'erreur en rouge
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "\e[38;5;196m$1\e[0m"
    fi
}

# Fonction pour journaliser les erreurs
log_error() {
    local error_msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERREUR: $error_msg" >> "$HOME/ohmytermux.log"
}

# Fonction pour exécuter une commande et afficher le résultat
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

# Fonction pour afficher la bannerière en mode texte
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

# Fonction pour vérifier et installer gum
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

# TODO : Déplacer dans la fonction principale ?
check_and_install_gum

# Fonction de gestion des erreurs
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

# Fonction pour afficher la bannerière en mode graphique
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

# Fonction pour sauvegarder les fichiers
create_backups() {
    local backup_dir="$HOME/backup"
    
    # Création du répertoire de sauvegarde
    execute_command "mkdir -p \"$backup_dir\"" "Création du répertoire ~/backup"

    # Liste des fichiers à sauvegarder
    local files_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
        "$0"
    )

    # Copie des fichiers dans le répertoire de sauvegarde
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            execute_command "cp \"$file\" \"$backup_dir/\"" "Sauvegarde de $(basename "$file")"
        fi
    done
}

# Fonction pour changer le répertoire de sources
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Changer le répertoire de sources ?"; then
            termux-change-repo
        fi
    else
        read -p "${COLOR_BLUE}Changer le répertoire de sources ? (o/n) : ${COLOR_RESET}" choice
        if [ "$choice" = "o" ]; then
            termux-change-repo
        fi
    fi
}

# Fonction pour configurer l'accès au stockage
setup_storage() {
    show_banner
    if $USE_GUM; then
        gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Autoriser l'accès au stockage ?" && termux-setup-storage
    else
        read -p "${COLOR_BLUE}Autoriser l'accès au stockage ? (o/n) : ${COLOR_RESET}" choice
        [ "$choice" = "o" ] && termux-setup-storage
    fi
}

# Fonction pour configurer Termux
configure_termux() {

    info_msg "❯ Configuration de Termux"

    # Appel de la fonction de sauvegarde
    create_backups

    termux_dir="$HOME/.termux"

    # Configuration de colors.properties
    file_path="$termux_dir/colors.properties"
    if [ ! -f "$file_path" ]; then
        mkdir -p "$termux_dir"
        execute_command "cat <<EOL > \"$file_path\"
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
        execute_command "cat <<EOL > \"$file_path\"
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL" "Configuration des propriétés Termux"
    else
        execute_command "sed -i 's/^# allow-external-apps = true/allow-external-apps = true/; 
            s/^# use-black-ui = true/use-black-ui = true/; 
            s/^# bell-character = ignore/bell-character = ignore/; 
            s/^# fullscreen = true/fullscreen = true/' \"$file_path\"" "Configuration des propriétés Termux"
    fi
    
    # Suppression de la bannière de connexion
    execute_command "touch $HOME/.hushlogin" "Suppression de la bannière de connexion"

    # Téléchargement de la police
    execute_command "curl -fLo "$HOME/.termux/font.ttf" https://github.com/GiGiDKR/OhMyTermux/raw/1.0.9/files/font.ttf" "Téléchargement de la police par défaut"

    termux-reload-settings
}

# Fonction principale de configuration initiale
initial_config() {
    change_repo
    setup_storage

    if $USE_GUM; then
        show_banner
        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Activer la configuration recommandée ?"; then
            configure_termux
        fi
    else
        show_banner
        read -p "${COLOR_BLUE}Activer la configuration recommandée ? (o/n) : ${COLOR_RESET}" choice
        if [ "$choice" = "o" ]; then
            configure_termux
        fi
    fi
}

# Fonction pour installer le shell
install_shell() {
    if $SHELL_CHOICE; then
        info_msg "❯ Configuration du shell"
        if $USE_GUM; then
            shell_choice=$(gum choose --selected="zsh" --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=5 --header="Choisissez le shell à installer :" "bash" "zsh" "fish")
        else
            echo -e "${COLOR_BLUE}Choisissez le shell à installer :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) bash${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) fish${COLOR_RESET}"
            echo
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
                    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Oh-My-Zsh ?"; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des pré-requis"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    read -p "${COLOR_BLUE}Installer Oh-My-Zsh ? (o/n) : ${COLOR_RESET}" choice
                    if [ "$choice" = "o" ]; then
                        execute_command "pkg install -y wget curl git unzip" "Installation des pré-requis"
                        execute_command "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\"" "Installation de Oh-My-Zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                execute_command "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/zshrc" "Téléchargement de la configuration"

                if $USE_GUM; then
                    if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer PowerLevel10k ?"; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "  Installer le prompt OhMyTermux ?"; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/p10k.zsh" "Téléchargement prompt PowerLevel10k"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                else
                    read -p "${COLOR_BLUE}Installer PowerLevel10k ? (o/n) : ${COLOR_RESET}" choice
                    if [ "$choice" = "o" ]; then
                        execute_command "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" || true" "Installation de PowerLevel10k"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        read -p "${COLOR_BLUE}Installer le prompt OhMyTermux ? (o/n) : ${COLOR_RESET}" choice
                        if [ "$choice" = "o" ]; then
                            execute_command "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/p10k.zsh" "Téléchargement du prompt PowerLevel10k"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                fi

                execute_command "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/aliases.zsh && 
                    mkdir -p $HOME/.config/OhMyTermux && 
                    curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/files/help.md)" "Téléchargement de la configuration" || 
                    error_msg "Erreur lors du téléchargement des fichiers"

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
                # TODO : ajouter la configuration de Fish, de ses plugins et des alias (abbr)
                chsh -s fish
                ;;
        esac
    fi
}

# Fonction pour installer les plugins
install_zsh_plugins() {
    local plugins_to_install=()
    if $USE_GUM; then
        plugins_to_install=($(gum choose --selected="Tout installer" --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=9 --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer"))
        if [[ " ${plugins_to_install[*]} " == *" Tout installer "* ]]; then
            plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder")
        fi
    else
        info_msg "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
        echo
        info_msg "1) zsh-autosuggestions"
        info_msg "2) zsh-syntax-highlighting"
        info_msg "3) zsh-completions"
        info_msg "4) you-should-use"
        info_msg "5) zsh-abbr"
        info_msg "6) zsh-alias-finder"
        info_msg "7) Tout installer"
        echo
        read -p $"\e[33mEntrez les numéros des plugins : \e[0m" plugin_choices
        
        for choice in $plugin_choices; do
            case $choice in
                1) plugins_to_install+=("zsh-autosuggestions") ;;
                2) plugins_to_install+=("zsh-syntax-highlighting") ;;
                3) plugins_to_install+=("zsh-completions") ;;
                4) plugins_to_install+=("you-should-use") ;;
                5) plugins_to_install+=("zsh-abbr") ;;
                6) plugins_to_install+=("zsh-alias-finder") ;;
                7) plugins_to_install=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder") ;;
            esac
        done
    fi

    for plugin in "${plugins_to_install[@]}"; do
        install_plugin "$plugin"
    done

    update_zshrc "${plugins_to_install[@]}"
}

# Fonction pour installer un plugin
install_plugin() {
    local plugin_name=$1
    local plugin_url=""

    case $plugin_name in
        "zsh-autosuggestions") plugin_url="https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        "zsh-syntax-highlighting") plugin_url="https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
        "zsh-completions") plugin_url="https://github.com/zsh-users/zsh-completions.git" ;;
        "you-should-use") plugin_url="https://github.com/MichaelAquilina/zsh-you-should-use.git" ;;
        "zsh-abbr") plugin_url="https://github.com/olets/zsh-abbr" ;;
        "zsh-alias-finder") plugin_url="https://github.com/akash329d/zsh-alias-finder" ;;
    esac

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin_name" ]; then
        execute_command "git clone '$plugin_url' '$HOME/.oh-my-zsh/custom/plugins/$plugin_name' --quiet" "Installation de $plugin_name"
    else
        info_msg "$plugin_name est déjà installé"
    fi
}

# Fonction pour mettre à jour la configuration de ZSH
update_zshrc() {
    local plugins=("$@")
    local default_plugins=(git command-not-found copyfile node npm vscode web-search timer)
    plugins+=("${default_plugins[@]}")

    # Supprimer les doublons
    readarray -t unique_plugins < <(printf '%s\n' "${plugins[@]}" | sort -u)

    local new_plugins_section="plugins=(\n"
    for plugin in "${unique_plugins[@]}"; do
        new_plugins_section+="\t$plugin\n"
    done
    new_plugins_section+=")"

    execute_command "sed -i '/^plugins=(/,/)/c\\${new_plugins_section}' '$ZSHRC'" "Ajout des plugins à zshrc"

    if ! grep -q "source \$ZSH/oh-my-zsh.sh" "$ZSHRC"; then
        echo -e "\n\nsource \$ZSH/oh-my-zsh.sh\n" >> "$ZSHRC"
    fi

    if [[ " ${unique_plugins[*]} " == *" zsh-completions "* ]]; then
        if ! grep -q "fpath+=.*zsh-completions" "$ZSHRC"; then
            sed -i "1ifpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" "$ZSHRC"
        fi
    fi
}

# Fonction pour installer les packages
install_packages() {
    if $PACKAGES_CHOICE; then
        info_msg "❯ Configuration des packages"
        if $USE_GUM; then
            PACKAGES=$(gum choose --selected="nala,eza,bat,lf,fzf,python" --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=21 --header="Sélectionner avec espace les packages à installer :" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
        else
            echo -e "${COLOR_BLUE}Sélectionner les packages à installer (séparés par des espaces) :${COLOR_RESET}"
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
            echo -e "${COLOR_BLUE}19) Tout installer${COLOR_RESET}"
            echo
            read -p "${COLOR_BLUE}Entrez les numéros des packages : ${COLOR_RESET}" package_choices
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
                    # TODO : Ajout d'alias supplémentaires pour d'autres packages
                esac
            done
        else
            echo -e "${COLOR_BLUE}Aucun package sélectionné.${COLOR_RESET}"
        fi
    fi
}

# Fonction pour ajouter des alias
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
alias dir="eza -lF --icons"' >> $BASHRC
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias l="eza --icons"
alias ls="eza -1 --icons"
alias ll="eza -lF -a --icons --total-size --no-permissions --no-time --no-user"
alias la="eza --icons -lgha --group-directories-first"
alias lt="eza --icons --tree"
alias lta="eza --icons --tree -lgha"
alias dir="eza -lF --icons"' >> $ZSHRC
            fi
            ;;
        bat)
            echo -e '\nalias cat="bat"' >> $BASHRC
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias cat="bat"' >> $ZSHRC
            fi
            ;;
        nala)
            echo -e '\nalias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"' >> $BASHRC
            if [ -f "$ZSHRC" ]; then
                echo -e '\nalias install="nala install -y"
alias uninstall="nala remove -y"
alias update="nala update"
alias upgrade="nala upgrade -y"
alias search="nala search"
alias list="nala list --upgradeable"
alias show="nala show"' >> $ZSHRC
            fi
            ;;
        # TODO : Ajout d'alias pour d'autres packages
    esac
}

# Définition des alias communs
common_alias() {
aliases='alias ..="cd .."
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
alias bashrc="nano \$HOME/.bashrc"
alias zshrc="nano \$HOME/.zshrc"
alias cm="chmod +x"
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m '\''mobile push'\'' && git push"'

echo -e "$aliases" >> "$BASHRC"

if [ -f "$ZSHRC" ]; then
    echo -e "$aliases" >> "$ZSHRC"
fi

# TODO : Ajout d'alias pour Fish
#if [ -f "$HOME/.config/fish/config.fish" ]; then
#    # Convertir les alias bash en format fish
#    echo "$aliases" | sed 's/alias \(.*\)="\(.*\)"/alias \1 "\2"/' >> "$HOME/.config/fish/config.fish"
#fi
}

# TODO : Ajout de plugins pour Python

# Fonction pour installer la police
install_font() {
    if $FONT_CHOICE; then
        info_msg "❯ Configuration de la police"
        if $USE_GUM; then
            FONT=$(gum choose --selected="Police par défaut" --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=13 --header="Sélectionner la police à installer :" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo -e "${COLOR_BLUE}Sélectionner la police à installer :${COLOR_RESET}"
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
            read -p "${COLOR_BLUE}Entrez le numéro de votre choix : ${COLOR_RESET}" choice
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

# Fonction pour installer XFCE
install_xfce() {
    if $XFCE_CHOICE; then
        info_msg "❯ Configuration de XFCE"
        if $USE_GUM; then
            if ! gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer XFCE ?"; then
                return
            fi
        else
            read -p "${COLOR_BLUE}Installer XFCE ? (o/n)${COLOR_RESET}" choice
            if [ "$choice" != "o" ]; then
                return
            fi
        fi

        execute_command "pkg install ncurses-ui-libs && pkg uninstall dbus -y" "Installation des pré-requis"

        PACKAGES=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')
    
        for PACKAGE in "${PACKAGES[@]}"; do
            execute_command "pkg install -y $PACKAGE" "Installation de $PACKAGE"
        done

        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/xfce.sh" "Téléchargement du script XFCE"
        execute_command "chmod +x xfce.sh" "Attribution des permissions d'exécution"
        
        if $USE_GUM; then
            ./xfce.sh --gum
        else
            ./xfce.sh
        fi
        
        INSTALL_UTILS=true
    fi
}

# Fonction pour installer Proot
install_proot() {
    info_msg "❯ Configuration de Proot"
    if $USE_GUM; then
        if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer Debian Proot ?"; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/proot.sh" "Téléchargement du script Proot"
            execute_command "chmod +x proot.sh" "Attribution des permissions d'exécution"
            ./proot.sh --gum
            INSTALL_UTILS=true
        fi
    else
        read -p "${COLOR_BLUE}Installer Debian Proot ? (o/n)${COLOR_RESET}" choice
        if [ "$choice" = "o" ]; then
            execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/proot.sh" "Téléchargement du script Proot"
            execute_command "chmod +x proot.sh" "Attribution des permissions d'exécution"
            ./proot.sh
            INSTALL_UTILS=true
        fi
    fi
}

get_username() {
    user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home"
    username=$(ls -1 "$user_dir" | head -n 1)
    if [ -z "$username" ]; then
        echo "Aucun utilisateur trouvé" >&2
        return 1
    fi
    echo "$username"
}

# Fonction pour installer les utilitaires
install_utils() {
    if $INSTALL_UTILS; then
        execute_command "curl -O https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/utils.sh" "Téléchargement du script Utils"
        execute_command "chmod +x utils.sh" "Attribution des permissions d'exécution"
        ./utils.sh

        username=$(get_username)
    if [ $? -ne 0 ]; then
        error_msg "Impossible de récupérer le nom d'utilisateur."
        return 1
    fi

        bashrc_proot="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/.bashrc"
        if [ ! -f "$bashrc_proot" ]; then
            error_msg "Le fichier .bashrc n'existe pas pour l'utilisateur $username."
            execute_command "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 touch $bashrc_proot" "Création du fichier .bashrc"
        fi

        # Ajouts au fichier $bashrc_proot
        execute_command "echo "export DISPLAY=:1.0

alias zink=\"MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform\"
alias hud=\"GALLIUM_HUD=fps\"
alias ..=\"cd ..\"
alias q=\"exit\"
alias c=\"clear\"
alias cat=\"bat\"
alias apt=\"sudo nala\"
alias install=\"sudo nala install -y\"
alias update=\"sudo nala update\"
alias upgrade=\"sudo nala upgrade -y\"
alias remove=\"sudo nala remove -y\"
alias list=\"nala list --upgradeable\"
alias show=\"nala show\"
alias search=\"nala search\"
alias start=\"echo \\\"Veuillez exécuter depuis Termux et non Debian proot.\\\"\"
alias cm=\"chmod +x\"
alias clone=\"git clone\"
alias push=\"git pull && git add . && git commit -m \\\"mobile push\\\" && git push\"
alias bashrc=\"nano \$HOME/.bashrc\"" >> $bashrc_proot" "Configurations .bashrc proot"

        # Ajouts au fichier $BASHRC
        execute_command "echo "# Fonction pour récupérer le nom d'utilisateur
get_username() {
    user_dir=\"\$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home\"
    username=\$(ls -1 \"\$user_dir\" | head -n 1)
    if [ -z \"\$username\" ]; then
        echo \"Aucun utilisateur trouvé\" >&2
        return 1
    fi
    echo \"\$username\"
}

alias debian=\"proot-distro login debian --shared-tmp --user \$(get_username)\"" >> $BASHRC" "Configuration .bashrc termux"

        # Ajout au fichier $ZSHRC si existant
        if [ -f "$ZSHRC" ]; then
            execute_command "echo "# Fonction pour récupérer le nom d'utilisateur
get_username() {
    user_dir=\"\$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home\"
    username=\$(ls -1 \"\$user_dir\" | head -n 1)
    if [ -z \"\$username\" ]; then
        echo \"Aucun utilisateur trouvé\" >&2
        return 1
    fi
    echo \"\$username\"
}

alias debian=\"proot-distro login debian --shared-tmp --user \$(get_username)\"" >> "$ZSHRC" "Configuration .zshrc termux"
        fi
    fi
}

# Fonction pour installer Termux-X11
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
        read -p "${COLOR_BLUE}Installer Termux-X11 ? (o/n)${COLOR_RESET}" choice
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

# Fonction pour installer OhMyTermuxScript
install_script() {
    info_msg "❯ Configuration de OhMyTermuxScript"
    if $SCRIPT_CHOICE; then
        SCRIPT_DIR="$HOME/OhMyTermuxScript"
        if [ ! -d "$SCRIPT_DIR" ]; then
            if $USE_GUM; then
                if gum confirm --affirmative "Oui" --negative "Non" --prompt.foreground="33" --selected.background="33" "Installer OhMyTermuxScript ?"; then
                    execute_command 'git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh' "Installation de OhMyTermuxScript"
                    info_msg "Pour accéder à OhMyTermuxScript saisissez : 'cd $SCRIPT_DIR', 'ls' et './nomduscript.sh' pour exécuter un script"
                fi
            else
                read -p "${COLOR_BLUE}Installer OhMyTermuxScript ? (o/n)${COLOR_RESET}" choice
                if [ "$choice" = "o" ]; then
                    execute_command 'git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh' "Installation de OhMyTermuxScript"
                    info_msg "Pour accéder à OhMyTermuxScript saisissez : 'cd $SCRIPT_DIR', 'ls' et './nomduscript.sh' pour exécuter un script"
                fi
            fi
        fi
    fi
}

# Fonction principale
show_banner
if $EXECUTE_INITIAL_CONFIG; then
    initial_config
fi
install_shell
install_packages
common_alias
install_font
install_xfce
install_proot
install_utils
install_termux_x11
install_script

info_msg "❯ Nettoyage des fichiers temporaires"
# Nettoyage des fichiers temporaires
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
    read -p "${COLOR_BLUE}Exécuter OhMyTermux ? (o/n)${COLOR_RESET}" choice
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