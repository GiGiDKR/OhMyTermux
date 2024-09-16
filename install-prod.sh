#!/bin/bash

USE_GUM=false
EXECUTE_INITIAL_CONFIG=true
SHELL_CHOICE=false
PACKAGES_CHOICE=false
PLUGIN_CHOICE=false
FONT_CHOICE=false
XFCE_CHOICE=false
SCRIPT_CHOICE=false
VERBOSE=false

BASHRC="$PREFIX/etc/bash.bashrc"
ZSHRC="$HOME/.zshrc"

ONLY_GUM=true

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

for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --shell|-s)
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
            ONLY_GUM=false
            shift
            ;;
        --script|-sc)
            SCRIPT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --noconf|-nc)
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
    esac
done

if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    PLUGIN_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    SCRIPT_CHOICE=true
fi

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

check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installation de gum...${COLOR_RESET}"
        eval "pkg update -y $redirect && pkg install gum -y $redirect"
    fi
}

check_and_install_gum

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

show_banner

initial_config() {
echo -e "${COLOR_BLUE}Changer le répertoire de sources ? (o/n)${COLOR_RESET}"
read change_repo_choice
if [ "$change_repo_choice" = "o" ]; then
    termux-change-repo
fi

termux_dir="$HOME/.termux"
file_path="$termux_dir/colors.properties"
if [ ! -f "$file_path" ]; then
    mkdir -p "$termux_dir"
    cat <<EOL > "$file_path"
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
fi

show_banner
if $USE_GUM; then
    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement police par défaut" -- curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf
else
    echo -e "${COLOR_BLUE}Téléchargement police par défaut...${COLOR_RESET}"
    eval "curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf $redirect"
fi

file_path="$termux_dir/termux.properties"

if [ ! -f "$file_path" ]; then
    cat <<EOL > "$file_path"
allow-external-apps = true
use-black-ui = true
bell-character = ignore
fullscreen = true
EOL
else
    sed -i 's/^# allow-external-apps = true/allow-external-apps = true/; 
        s/^# use-black-ui = true/use-black-ui = true/; 
        s/^# bell-character = ignore/bell-character = ignore/; 
        s/^# fullscreen = true/fullscreen = true/' "$file_path"
fi

touch .hushlogin
termux-reload-settings

show_banner
if $USE_GUM; then
    gum confirm --prompt.foreground="33" --selected.background="33" "  Autoriser l'accès au stockage ?" && termux-setup-storage
else
    echo -e "${COLOR_BLUE}  Autoriser l'accès au stockage ? (o/n)${COLOR_RESET}"
    read choice
    [ "$choice" = "o" ] && termux-setup-storage
fi
}

install_shell() {
    if $SHELL_CHOICE; then
        show_banner
        if $USE_GUM; then
            shell_choice=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=5 --header="Choisissez le shell à installer :" "bash" "zsh" "fish")
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
                echo -e "${COLOR_BLUE}Bash sélectionné, poursuite du script...${COLOR_RESET}"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    if $USE_GUM; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de ZSH" -- pkg install -y zsh
                    else
                        echo -e "${COLOR_BLUE}Installation de ZSH...${COLOR_RESET}"
                        eval "pkg install -y zsh $redirect"
                    fi
                fi

                # Installation de Oh My Zsh et autres configurations ZSH
                show_banner
                if $USE_GUM; then
                    if gum confirm --prompt.foreground="33" --selected.background="33" "Voulez-vous installer Oh My Zsh ?"; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des pré-requis" -- pkg install -y wget curl git unzip
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Oh My Zsh" -- git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    echo -e "${COLOR_BLUE}Voulez-vous installer Oh My Zsh ? (o/n)${COLOR_RESET}"
                    read choice
                    if [ "$choice" = "o" ]; then
                        echo -e "${COLOR_BLUE}Installation des pré-requis...${COLOR_RESET}"
                        eval "pkg install -y wget curl git unzip $redirect"
                        echo -e "${COLOR_BLUE}Installation de Oh My Zsh...${COLOR_RESET}"
                        eval "git clone https://github.com/ohmyzsh/ohmyzsh.git \"$HOME/.oh-my-zsh\" --quiet $redirect"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                eval "curl -fLo \"$ZSHRC\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/zshrc $redirect"

                show_banner
                if $USE_GUM; then
                    if gum confirm --prompt.foreground="33" --selected.background="33" "Voulez-vous installer PowerLevel10k ?"; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de PowerLevel10k" -- \
                        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || true
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        show_banner
                        if gum confirm --prompt.foreground="33" --selected.background="33" "  Installer le prompt OhMyTermux ?"; then
                            gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement prompt PowerLevel10k" -- \
                            curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                else
                    echo -e "${COLOR_BLUE}Voulez-vous installer PowerLevel10k ? (o/n)${COLOR_RESET}"
                    read choice
                    if [ "$choice" = "o" ]; then
                        echo -e "${COLOR_BLUE}Installation de PowerLevel10k...${COLOR_RESET}"
                        eval "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$HOME/.oh-my-zsh/custom/themes/powerlevel10k\" --quiet $redirect || true"
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        echo -e "${COLOR_BLUE}Installer le prompt OhMyTermux ? (o/n)${COLOR_RESET}"
                        read choice
                        if [ "$choice" = "o" ]; then
                            echo -e "${COLOR_BLUE}Téléchargement du prompt PowerLevel10k...${COLOR_RESET}"
                            eval "curl -fLo \"$HOME/.p10k.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh $redirect"
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "${COLOR_BLUE}Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.${COLOR_RESET}"
                        fi
                    fi
                fi

                show_banner
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de la configuration" -- sh -c 'curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh && mkdir -p $HOME/.config/OhMyTermux && curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/help.md'
                else
                    echo -e "${COLOR_BLUE}Téléchargement de la configuration...${COLOR_RESET}"
                    eval "(curl -fLo \"$HOME/.oh-my-zsh/custom/aliases.zsh\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh && 
                    mkdir -p $HOME/.config/OhMyTermux && 
                    curl -fLo \"$HOME/.config/OhMyTermux/help.md\" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/help.md) $redirect" || 
                    echo -e "${COLOR_RED}Erreur lors du téléchargement des fichiers${COLOR_RESET}"
                fi

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "${COLOR_BLUE}ZSH n'est pas installé. Impossible d'installer les plugins.${COLOR_RESET}"
                fi
                chsh -s zsh
                ;;
            "fish")
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Fish" -- pkg install -y fish
                else
                    echo -e "${COLOR_BLUE}Installation de Fish...${COLOR_RESET}"
                    eval "pkg install -y fish $redirect"
                fi
                # TODO : ajouter la configuration de Fish, de ses plugins et des alias (abbr)
                chsh -s fish
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
            echo -e "${COLOR_BLUE}Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :${COLOR_RESET}"
            echo
            echo -e "${COLOR_BLUE}1) zsh-autosuggestions${COLOR_RESET}"
            echo -e "${COLOR_BLUE}2) zsh-syntax-highlighting${COLOR_RESET}"
            echo -e "${COLOR_BLUE}3) zsh-completions${COLOR_RESET}"
            echo -e "${COLOR_BLUE}4) you-should-use${COLOR_RESET}"
            echo -e "${COLOR_BLUE}5) zsh-abbr${COLOR_RESET}"
            echo -e "${COLOR_BLUE}6) zsh-alias-finder${COLOR_RESET}"
            echo -e "${COLOR_BLUE}7) Tout installer${COLOR_RESET}"
            echo
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
                install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
                ;;
            "zsh-syntax-highlighting")
                install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
                ;;
            "zsh-completions")
                install_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions.git"
                ;;
            "you-should-use")
                install_plugin "you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git"
                ;;
            "zsh-abbr")
                install_plugin "zsh-abbr" "https://github.com/olets/zsh-abbr"
                ;;
            "zsh-alias-finder")
                install_plugin "zsh-alias-finder" "https://github.com/akash329d/zsh-alias-finder"
                ;;
        esac
    done
    update_zshrc
    fi
}

install_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    if $USE_GUM; then
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation $plugin_name" -- \
        git clone "$plugin_url" "$HOME/.oh-my-zsh/custom/plugins/$plugin_name" || true
    else
        echo -e "${COLOR_BLUE}Installation $plugin_name...${COLOR_RESET}"
        eval "git clone \"$plugin_url\" \"$HOME/.oh-my-zsh/custom/plugins/$plugin_name\" --quiet $redirect || true"
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

    sed -i "/^plugins=(/,/)/c\plugins=(\n\t${plugin_list}\n)" "$zshrc"

    if [[ "$PLUGINS" == *"zsh-completions"* ]]; then
        if ! grep -q "fpath+=" "$zshrc"; then
            sed -i '/^source $ZSH\/oh-my-zsh.sh$/i\fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$zshrc"
        fi
    fi
}

install_packages() {
    if $PACKAGES_CHOICE; then
        show_banner
        if $USE_GUM; then
            PACKAGES=$(gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=21 --header="Sélectionner avec espace les packages à installer :" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
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
            read -p "Entrez les numéros des packages : " package_choices
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

        installed_packages=""

        show_banner
        if [ -n "$PACKAGES" ]; then
            for PACKAGE in $PACKAGES; do
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $PACKAGE" -- pkg install -y $PACKAGE
                else
                    echo -e "${COLOR_BLUE}Installation de $PACKAGE...${COLOR_RESET}"
                    eval "pkg install -y $PACKAGE $redirect"
                fi
                installed_packages+="Installé : $PACKAGE\n"
                show_banner 
                echo -e "$installed_packages"

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

common_alias() {
# Define general aliases in a variable
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
alias cm="chmod +x"
alias g="git"
alias gc="git clone"
alias push="git pull && git add . && git commit -m '\''mobile push'\'' && git push"'

echo -e "$aliases" >> "$BASHRC"

if [ -f "$ZSHRC" ]; then
    echo -e "$aliases" >> "$ZSHRC"
fi

# TODO : Ajout Fish
#if [ -f "$HOME/.config/fish/config.fish" ]; then
#    # Convertir les alias bash en format fish
#    echo "$aliases" | sed 's/alias \(.*\)="\(.*\)"/alias \1 "\2"/' >> "$HOME/.config/fish/config.fish"
#fi

}

install_font() {
    if $FONT_CHOICE; then
        show_banner
         if $USE_GUM; then
            FONT=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=14 --header="Sélectionner la police à installer :" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
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
            echo
            read -p "Entrez le numéro de votre choix : " choice
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
                *) FONT="Police par défaut" ;;
            esac
        fi

        case $FONT in
            "Police par défaut")
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement police par défaut" -- curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf
                else
                    echo -e "${COLOR_BLUE}Téléchargement police par défaut...${COLOR_RESET}"
                    eval "curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf $redirect"
                fi
                ;;
            *)
                font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/${FONT// /}/Regular/complete/${FONT// /}%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement $FONT" -- curl -L -o $HOME/.termux/font.ttf "$font_url"
                else
                    echo -e "${COLOR_BLUE}Téléchargement $FONT...${COLOR_RESET}"
                    eval "curl -L -o $HOME/.termux/font.ttf \"$font_url\" $redirect"
                fi
                ;;
        esac
        termux-reload-settings
    fi
}

install_xfce() {
    if $XFCE_CHOICE; then
        show_banner
        if $USE_GUM; then
            if ! gum confirm --prompt.foreground="33" --selected.background="33" "Installer XFCE ?"; then
                return
            fi
        else
            echo -e "${COLOR_BLUE}Installer XFCE ? (o/n)${COLOR_RESET}"
            read choice
            if [ "$choice" != "o" ]; then
                return
            fi
        fi

        # Installation de XFCE et DEBIAN
        show_banner
        pkgs=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')

        # Installation des pré-requis
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des pré-requis" -- pkg install ncurses-ui-libs && pkg uninstall dbus -y
        else
            echo -e "${COLOR_BLUE}Installation des pré-requis...\e[0m"
            eval "pkg install ncurses-ui-libs && pkg uninstall dbus -y $redirect"
        fi

        # Installation des paquets nécessaires
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des paquets nécessaires" -- pkg install "${pkgs[@]}" -y
        else
            echo -e "${COLOR_BLUE}Installation des paquets nécessaires...\e[0m"
            eval "pkg install \"${pkgs[@]}\" -y $redirect"
        fi

        # Installation de Debian
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Debian" -- proot-distro install debian
        else
            echo -e "${COLOR_BLUE}Installation de Debian...\e[0m"
            eval "proot-distro install debian $redirect"
        fi

        # Création des fichiers de configuration
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Création des fichiers de configuration" -- bash -c '
                echo "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dbus-launch --exit-with-session startxfce4" > $PREFIX/bin/start
                echo "pkill -f \"app_process / com.termux.x11\"" > $PREFIX/bin/kill_termux_x11
                echo "[Desktop Entry]
Type=Application
Name=Kill Termux:X11
Exec=$PREFIX/bin/kill_termux_x11
Icon=system-shutdown
Categories=System;" > $PREFIX/share/applications/kill_termux_x11.desktop
                chmod +x $PREFIX/bin/start $PREFIX/bin/kill_termux_x11
            '
        else
            echo -e "${COLOR_BLUE}Création des fichiers de configuration...\e[0m"
            eval 'echo "proot-distro login debian --shared-tmp -- env DISPLAY=:1.0 dbus-launch --exit-with-session startxfce4" > $PREFIX/bin/start'
            eval 'echo "pkill -f \"app_process / com.termux.x11\"" > $PREFIX/bin/kill_termux_x11'
            eval 'echo "[Desktop Entry]
Type=Application
Name=Kill Termux:X11
Exec=$PREFIX/bin/kill_termux_x11
Icon=system-shutdown
Categories=System;" > $PREFIX/share/applications/kill_termux_x11.desktop'
            eval "chmod +x $PREFIX/bin/start $PREFIX/bin/kill_termux_x11"
        fi

        # Installation des paquets dans Debian
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des paquets dans Debian" -- bash -c '
                proot-distro login debian --shared-tmp -- apt update
                proot-distro login debian --shared-tmp -- apt upgrade -y
                proot-distro login debian --shared-tmp -- apt install -y xfce4 xfce4-terminal dbus-x11 tigervnc-standalone-server
            '
        else
            echo -e "${COLOR_BLUE}Installation des paquets dans Debian...\e[0m"
            eval "proot-distro login debian --shared-tmp -- apt update $redirect"
            eval "proot-distro login debian --shared-tmp -- apt upgrade -y $redirect"
            eval "proot-distro login debian --shared-tmp -- apt install -y xfce4 xfce4-terminal dbus-x11 tigervnc-standalone-server $redirect"
        fi

        # Configuration de XFCE
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Configuration de XFCE" -- bash -c '
                proot-distro login debian --shared-tmp -- mkdir -p /root/.vnc
                echo "#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &" | proot-distro login debian --shared-tmp -- tee /root/.vnc/xstartup > /dev/null
                proot-distro login debian --shared-tmp -- chmod +x /root/.vnc/xstartup
            '
        else
            echo -e "${COLOR_BLUE}Configuration de XFCE...\e[0m"
            eval "proot-distro login debian --shared-tmp -- mkdir -p /root/.vnc"
            eval "echo \"#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &\" | proot-distro login debian --shared-tmp -- tee /root/.vnc/xstartup > /dev/null"
            eval "proot-distro login debian --shared-tmp -- chmod +x /root/.vnc/xstartup"
        fi
    fi
}

install_termux_x11() {
    show_banner
    local install_x11=false

    if $USE_GUM; then
        if gum confirm --prompt.foreground="33" --selected.background="33" " Installer Termux-X11 ?"; then
            install_x11=true
        fi
    else
        echo -e "${COLOR_BLUE} Installer Termux-X11 ? (o/n)${COLOR_RESET}"
        read -r choice
        if [ "$choice" = "o" ]; then
            install_x11=true
        fi
    fi

    if $install_x11; then
        show_banner
        local apk_url="https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk"
        local apk_file="$HOME/storage/downloads/termux-x11.apk"

        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de Termux-X11 APK" -- wget "$apk_url" -O "$apk_file"
        else
            echo -e "${COLOR_BLUE}Téléchargement de Termux-X11 APK...\e[0m"
            eval "wget \"$apk_url\" -O \"$apk_file\" $redirect"
        fi

        if [ -f "$apk_file" ]; then
            termux-open "$apk_file"
            echo -e "${COLOR_BLUE}Veuillez installer l'APK manuellement.\e[0m"
            echo -e "${COLOR_BLUE}Une fois l'installation terminée, appuyez sur Entrée pour continuer.\e[0m"
            read -r
            rm "$apk_file"
        else
            echo -e "${COLOR_RED}Erreur : Le téléchargement de l'APK a échoué.\e[0m"
        fi
    fi
}

install_script() {
    if $SCRIPT_CHOICE; then
        SCRIPT_DIR="$HOME/OhMyTermuxScript"
        if [ ! -d "$SCRIPT_DIR" ]; then
            if $USE_GUM; then
                if gum confirm --prompt.foreground="33" --selected.background="33" "  Installer OhMyTermuxScript ?"; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de OhMyTermuxScript" -- bash -c 'git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh'
                fi
            else
                echo -e "${COLOR_BLUE}  Installer OhMyTermuxScript ? (o/n)${COLOR_RESET}"
                read -r choice
                if [ "$choice" = "o" ]; then
                    echo -e "${COLOR_BLUE}Installation de OhMyTermuxScript...\e[0m"
                    eval "git clone https://github.com/GiGiDKR/OhMyTermuxScript.git \"$HOME/OhMyTermuxScript\" && chmod +x $HOME/OhMyTermuxScript/*.sh $redirect"
                fi
            fi
        fi
    fi
}

show_banner

if $EXECUTE_INITIAL_CONFIG; then
    initial_config
fi
install_shell
install_packages
common_alias
install_font
install_xfce
install_termux_x11
install_script

rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1

show_banner
if $USE_GUM; then
    if gum confirm --prompt.foreground="33" --selected.background="33" "   Exécuter OhMyTermux ?"; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}OhMyTermux sera actif au prochain démarrage de Termux.\e[0m"
    fi
else
    echo -e "${COLOR_BLUE}   Exécuter OhMyTermux ? (o/n)${COLOR_RESET}"
    read choice
    if [ "$choice" = "o" ]; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "${COLOR_BLUE}OhMyTermux sera actif au prochain démarrage de Termux.\e[0m"
    fi
fi