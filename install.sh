#!/bin/bash

USE_GUM=false
EXECUTE_INITIAL_CONFIG=true
SHELL_CHOICE=false
PACKAGES_CHOICE=false
PLUGIN_CHOICE=false
FONT_CHOICE=false
XFCE_CHOICE=false
SCRIPT_CHOICE=false
BASHRC="$PREFIX/etc/bash.bashrc"
ZSHRC="$HOME/.zshrc"
ONLY_GUM=true

# Fonction pour afficher un message d'erreur
error_msg() {
    if $USE_GUM; then
        gum style --foreground 196 "$1"
    else
        echo -e "\e[38;5;196m$1\e[0m"
    fi
}

# Fonction pour afficher un message d'information
info_msg() {
    if $USE_GUM; then
        gum style --foreground 33 "$1"
    else
        echo -e "\e[38;5;33m$1\e[0m"
    fi
}

# Traitement des arguments en ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --gum|-g) USE_GUM=true ;;
        --shell|-s) SHELL_CHOICE=true; ONLY_GUM=false ;;
        --package|-pkg) PACKAGES_CHOICE=true; ONLY_GUM=false ;;
        --plugin|-plg) PLUGIN_CHOICE=true; ONLY_GUM=false ;;
        --font|-f) FONT_CHOICE=true; ONLY_GUM=false ;;
        --xfce|-x) XFCE_CHOICE=true; ONLY_GUM=false ;;
        --script|-sc) SCRIPT_CHOICE=true; ONLY_GUM=false ;;
        --noconf|-nc) EXECUTE_INITIAL_CONFIG=false ;;
        *) error_msg "Option non reconnue : $1" ;;
    esac
    shift
done

if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    PLUGIN_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    SCRIPT_CHOICE=true
fi

check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        info_msg "Installation de gum..."
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

finish() {
    local ret=$?
    if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
        echo
        error_msg "ERREUR: Installation de OhMyTermux impossible."
        info_msg "Veuillez vous référer au(x) message(s) d'erreur ci-dessus."
    fi
}

trap finish EXIT

bash_banner() {
    clear
    echo -e "\e[38;5;33m
╔════════════════════════════════════════╗
║                                        ║
║              OHMYTERMUX                ║
║                                        ║
╚════════════════════════════════════════╝
\e[0m"
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

check_and_install_gum

show_banner

initial_config() {
    if $USE_GUM; then
        if gum confirm --prompt.foreground="33" --selected.background="33" "Changer le répertoire de sources ?"; then
            termux-change-repo
        fi
    else
        info_msg "Changer le répertoire de sources ? (o/n)"
        read change_repo_choice
        if [ "$change_repo_choice" = "o" ]; then
            termux-change-repo
        fi
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
        gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement police par défaut" -- curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/files/font.ttf
    else
        info_msg "Téléchargement police par défaut..."
        curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/files/font.ttf
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
        sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$file_path"
        sed -i 's/^# use-black-ui = true/use-black-ui = true/' "$file_path"
        sed -i 's/^# bell-character = ignore/bell-character = ignore/' "$file_path"
        sed -i 's/^# fullscreen = true/fullscreen = true/' "$file_path"
    fi

    touch .hushlogin

    termux-reload-settings

    show_banner

    if $USE_GUM; then
        gum confirm --prompt.foreground="33" --selected.background="33" "  Autoriser l'accès au stockage ?" && termux-setup-storage
    else
        info_msg "  Autoriser l'accès au stockage ? (o/n)"
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
            info_msg "Choisissez le shell à installer :"
            info_msg "1) bash"
            info_msg "2) zsh"
            info_msg "3) fish"
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
                info_msg "Bash sélectionné, poursuite du script..."
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    if $USE_GUM; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de ZSH" -- pkg install -y zsh
                    else
                        info_msg "Installation de ZSH..."
                        pkg install -y zsh
                    fi
                fi
                show_banner
                if $USE_GUM; then
                    if gum confirm --prompt.foreground="33" --selected.background="33" "Voulez-vous installer Oh My Zsh ?"; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des pré-requis" -- pkg install -y wget curl git unzip
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Oh My Zsh" -- git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                else
                    info_msg "Voulez-vous installer Oh My Zsh ? (o/n)"
                    read choice
                    if [ "$choice" = "o" ]; then
                        info_msg "Installation des pré-requis..."
                        pkg install -y wget curl git unzip
                        info_msg "Installation de Oh My Zsh..."
                        git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" --quiet >/dev/null
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi
                curl -fLo "$ZSHRC" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/zshrc >/dev/null 2>&1
                show_banner
                if $USE_GUM; then
                    if gum confirm --prompt.foreground="33" --selected.background="33" "Voulez-vous installer PowerLevel10k ?"; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de PowerLevel10k" -- \
                        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || true
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
                        show_banner
                        if gum confirm --prompt.foreground="33" --selected.background="33" "  Installer le prompt OhMyTermux ?"; then
                            gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement prompt PowerLevel10k" -- \
                            curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            info_msg "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                        fi
                    fi
                else
                    info_msg "Voulez-vous installer PowerLevel10k ? (o/n)"
                    read choice
                    if [ "$choice" = "o" ]; then
                        info_msg "Installation de PowerLevel10k..."
                        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"  --quiet >/dev/null || true
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
                        info_msg "Installer le prompt OhMyTermux ? (o/n)"
                        read choice
                        if [ "$choice" = "o" ]; then
                            info_msg "Téléchargement du prompt PowerLevel10k..."
                            curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            info_msg "Vous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation."
                        fi
                    fi
                fi
                show_banner
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de la configuration" -- sh -c 'curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh && mkdir -p $HOME/.config/OhMyTermux && curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/help.md)'
                else
                    info_msg "Téléchargement de la configuration..."
                    (curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/aliases.zsh &&
                    curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.6/files/help.md) ||
                    error_msg "Erreur lors du téléchargement des fichiers"
                fi
                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    error_msg "ZSH n'est pas installé. Impossible d'installer les plugins."
                fi
                chsh -s zsh
                ;;
            "fish")
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Fish" -- pkg install -y fish
                else
                    info_msg "Installation de Fish..."
                    pkg install -y fish
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
            info_msg "Sélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :"
            info_msg "1) zsh-autosuggestions"
            info_msg "2) zsh-syntax-highlighting"
            info_msg "3) zsh-completions"
            info_msg "4) you-should-use"
            info_msg "5) zsh-abbr"
            info_msg "6) zsh-alias-finder"
            info_msg "7) Tout installer"
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
        info_msg "Installation $plugin_name..."
        git clone "$plugin_url" "$HOME/.oh-my-zsh/custom/plugins/$plugin_name" --quiet >/dev/null || true
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
            info_msg "Sélectionner les packages à installer (séparés par des espaces) :"
            info_msg "1) nala"
            info_msg "2) eza"
            info_msg "3) colorls"
            info_msg "4) lsd"
            info_msg "5) bat"
            info_msg "6) lf"
            info_msg "7) fzf"
            info_msg "8) glow"
            info_msg "9) tmux"
            info_msg "10) python"
            info_msg "11) nodejs"
            info_msg "12) nodejs-lts"
            info_msg "13) micro"
            info_msg "14) vim"
            info_msg "15) neovim"
            info_msg "16) lazygit"
            info_msg "17) open-ssh"
            info_msg "18) tsu"
            info_msg "19) Tout installer"
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
                    info_msg "Installation de $PACKAGE..."
                    pkg install -y $PACKAGE  >/dev/null 2>&1
                fi
                installed_packages+="✓ $PACKAGE installé.\n"
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
            info_msg "Aucun package sélectionné."
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

    echo -e "\n$aliases" >> "$BASHRC"
    if [ -f "$ZSHRC" ]; then
        echo -e "\n$aliases" >> "$ZSHRC"
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
            info_msg "Sélectionner la police à installer :"
            info_msg "1) Police par défaut"
            info_msg "2) CaskaydiaCove Nerd Font"
            info_msg "3) FiraMono Nerd Font"
            info_msg "4) JetBrainsMono Nerd Font"
            info_msg "5) Mononoki Nerd Font"
            info_msg "6) VictorMono Nerd Font"
            info_msg "7) RobotoMono Nerd Font"
            info_msg "8) DejaVuSansMono Nerd Font"
            info_msg "9) UbuntuMono Nerd Font"
            info_msg "10) AnonymousPro Nerd Font"
            info_msg "11) Terminus Nerd Font"
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
                *) error_msg "Choix invalide"; return ;;
            esac
        fi

        info_msg "Installation de la police sélectionnée..."
        case $FONT in
            "CaskaydiaCove Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/CaskaydiaCoveNerdFont-Regular.ttf" >/dev/null 2>&1
                ;;
            "FiraMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/FiraMono-Regular.ttf" >/dev/null 2>&1
                ;;
            "JetBrainsMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/JetBrainsMono-Regular.ttf" >/dev/null 2>&1
                ;;
            "Mononoki Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/Mononoki-Regular.ttf" >/dev/null 2>&1
                ;;
            "VictorMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/mayTermux/myTermux/raw/main/.fonts/VictorMono-Regular.ttf" >/dev/null 2>&1
                ;;
            "RobotoMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/RobotoMonoNerdFont.ttf" >/dev/null 2>&1
                ;;
            "DejaVuSansMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/DejaVuSansMonoNerdFont.ttf" >/dev/null 2>&1
                ;;
            "UbuntuMono Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/UbuntuMonoNerdFont.ttf" >/dev/null 2>&1
                ;;
            "AnonymousPro Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/AnonymousProNerdFont.ttf" >/dev/null 2>&1
                ;;
            "Terminus Nerd Font")
                curl -L -o "$HOME/.termux/font.ttf" "https://github.com/adi1090x/termux-style/raw/master/fonts/TerminusNerdFont.ttf" >/dev/null 2>&1
                ;;
            "Police par défaut")
                info_msg "Police déjà installée."
                ;;
            *)
                error_msg "Police non reconnue : $FONT"
                ;;
        esac
    fi
}

install_xfce() {
    if $XFCE_CHOICE; then
        show_banner
        local install_xfce=false
        if $USE_GUM; then
            if gum confirm --prompt.foreground="33" --selected.background="33" " Installer XFCE et DEBIAN ?"; then
                install_xfce=true
            fi
        else
            info_msg " Installer XFCE et DEBIAN ? (o/n)"
            read choice
            if [ "$choice" = "o" ]; then
                install_xfce=true
            fi
        fi

        if ! $install_xfce; then
            PACKAGES="ncurses-utils"
            for PACKAGE in $PACKAGES; do
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $PACKAGE" -- pkg install -y $PACKAGE
                else
                    info_msg "Installation de $PACKAGE..."
                    pkg install -y $PACKAGE >/dev/null 2>&1
                fi
            done
            export PATH="$PATH:$PREFIX/bin"
            show_banner

            local execute_ohmytermux=false
            if $USE_GUM; then
                if gum confirm --prompt.foreground="33" --selected.background="33" " Exécuter OhMyTermux ?"; then
                    execute_ohmytermux=true
                fi
            else
                info_msg " Exécuter OhMyTermux ? (o/n)"
                read choice
                if [ "$choice" = "o" ]; then
                    execute_ohmytermux=true
                fi
            fi
            if $execute_ohmytermux; then
                termux-reload-settings
                rm -f install.sh
                clear
                exec $shell_choice
            else
                termux-reload-settings
                rm -f install.sh
                info_msg "OhMyTermux sera actif au prochain démarrage de Termux."
            fi
            return
        fi

        show_banner
        pkgs=('wget' 'ncurses-utils' 'dbus-x11' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des pré-requis" -- pkg install ncurses-ui-libs && pkg uninstall dbus -y
        else
            info_msg "Installation des pré-requis..."
            pkg install ncurses-ui-libs && pkg uninstall dbus -y
        fi
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Mise à jour des paquets" -- pkg update -y
        else
            info_msg "Mise à jour des paquets..."
            pkg update -y
        fi
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des paquets nécessaires" -- pkg install "${pkgs[@]}" -y
        else
            info_msg "Installation des paquets nécessaires..."
            pkg install "${pkgs[@]}" -y
        fi
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement des scripts" -- bash -c "
                wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/xfce.sh &&
                wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/proot.sh &&
                wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/utils.sh
            "
        else
            info_msg "Téléchargement des scripts..."
            wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/xfce.sh
            wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/proot.sh
            wget https://github.com/GiGiDKR/OhMyTermux/raw/1.0.6/utils.sh
        fi
        chmod +x *.sh
        show_banner
        if $USE_GUM; then
            ./xfce.sh --gum
            ./proot.sh --gum
        else
            ./xfce.sh
            ./proot.sh
        fi
        ./utils.sh
        add_get_username_function
    fi
}

add_get_username_function() {
    local function_text='
function get_username() {
    user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"
    username=$(basename "$user_dir"/*)
    echo $username
}

alias debian="proot-distro login debian --shared-tmp --user $(get_username)"
'
    echo -e "$function_text" >> "$BASHRC"

    if [ -f "$ZSHRC" ]; then
        echo -e "$function_text" >> "$ZSHRC"
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
        info_msg " Installer Termux-X11 ? (o/n)"
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
            info_msg "Téléchargement de Termux-X11 APK..."
            wget "$apk_url" -O "$apk_file"
        fi
        if [ -f "$apk_file" ]; then
            termux-open "$apk_file"
            info_msg "Veuillez installer l'APK manuellement."
            info_msg "Une fois l'installation terminée, appuyez sur Entrée pour continuer."
            read -r
            rm "$apk_file"
        else
            error_msg "Erreur : Le téléchargement de l'APK a échoué."
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
                info_msg "  Installer OhMyTermuxScript ? (o/n)"
                read -r choice
                if [ "$choice" = "o" ]; then
                    info_msg "Installation de OhMyTermuxScript..."
                    git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh
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
        info_msg "OhMyTermux sera actif au prochain démarrage de Termux."
    fi
else
    info_msg "   Exécuter OhMyTermux ? (o/n)"
    read choice
    if [ "$choice" = "o" ]; then
        clear
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        info_msg "OhMyTermux sera actif au prochain démarrage de Termux."
    fi
fi
