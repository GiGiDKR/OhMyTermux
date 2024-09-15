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

############
# FUNCTION #
############

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

check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "\e[38;5;33mInstallation de gum...\e[0m"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
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
            echo -e "\e[38;5;196mERREUR: Installation de OhMyTermux impossible.\e[0m"
        fi
        echo -e "\e[38;5;33mVeuillez vous référer au(x) message(s) d'erreur ci-dessus.\e[0m"
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

##################
# INITIAL CONFIG #
##################

initial_config() {
echo -e "\e[38;5;33mChanger le répertoire de sources ? (o/n)\e[0m"
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
    echo -e "\e[38;5;33mTéléchargement police par défaut...\e[0m"
    curl -L -o $HOME/.termux/font.ttf https://github.com/GiGiDKR/OhMyTermux/raw/main/files/font.ttf
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
    echo -e "\e[38;5;33m  Autoriser l'accès au stockage ? (o/n)\e[0m"
    read choice
    [ "$choice" = "o" ] && termux-setup-storage
fi
}

#########
# SHELL #
#########

install_shell() {
    if $SHELL_CHOICE; then
        show_banner
        if $USE_GUM; then
            shell_choice=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=5 --header="Choisissez le shell à installer :" "bash" "zsh" "fish")
        else
            echo -e "\e[38;5;33mChoisissez le shell à installer :\e[0m"
            echo -e "\e[38;5;33m1) bash\e[0m"
            echo -e "\e[38;5;33m2) zsh\e[0m"
            echo -e "\e[38;5;33m3) fish\e[0m"
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
                echo -e "\e[38;5;33mBash sélectionné, poursuite du script...\e[0m"
                ;;
            "zsh")
                if ! command -v zsh &> /dev/null; then
                    if $USE_GUM; then
                        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de ZSH" -- pkg install -y zsh
                    else
                        echo -e "\e[38;5;33mInstallation de ZSH...\e[0m"
                        pkg install -y zsh
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
                    echo -e "\e[38;5;33mVoulez-vous installer Oh My Zsh ? (o/n)\e[0m"
                    read choice
                    if [ "$choice" = "o" ]; then
                        echo -e "\e[38;5;33mInstallation des pré-requis...\e[0m"
                        pkg install -y wget curl git unzip
                        echo -e "\e[38;5;33mInstallation de Oh My Zsh...\e[0m"
                        git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" --quiet >/dev/null
                        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
                    fi
                fi

                curl -fLo "$ZSHRC" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/zshrc >/dev/null 2>&1

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
                            echo -e "\e[38;5;33mVous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.\e[0m"
                        fi
                    fi
                else
                    echo -e "\e[38;5;33mVoulez-vous installer PowerLevel10k ? (o/n)\e[0m"
                    read choice
                    if [ "$choice" = "o" ]; then
                        echo -e "\e[38;5;33mInstallation de PowerLevel10k...\e[0m"
                        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"  --quiet >/dev/null || true
                        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

                        echo -e "\e[38;5;33mInstaller le prompt OhMyTermux ? (o/n)\e[0m"
                        read choice
                        if [ "$choice" = "o" ]; then
                            echo -e "\e[38;5;33mTéléchargement du prompt PowerLevel10k...\e[0m"
                            curl -fLo "$HOME/.p10k.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/p10k.zsh
                            echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC"
                            echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC"
                        else
                            echo -e "\e[38;5;33mVous pouvez configurer le prompt PowerLevel10k manuellement en exécutant 'p10k configure' après l'installation.\e[0m"
                        fi
                    fi
                fi

                show_banner
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement de la configuration" -- sh -c 'curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh && mkdir -p $HOME/.config/OhMyTermux && curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/help.md)'
                else
                    echo -e "\e[38;5;33mTéléchargement de la configuration...\e[0m"
                    (curl -fLo "$HOME/.oh-my-zsh/custom/aliases.zsh" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/aliases.zsh && 
                    curl -fLo "$HOME/.config/OhMyTermux/help.md" https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/files/help.md) || 
                    echo -e "\e[38;5;31mErreur lors du téléchargement des fichiers\e[0m"
                fi

                if command -v zsh &> /dev/null; then
                    install_zsh_plugins
                else
                    echo -e "\e[38;5;33mZSH n'est pas installé. Impossible d'installer les plugins.\e[0m"
                fi
                chsh -s zsh
                ;;
            "fish")
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de Fish" -- pkg install -y fish
                else
                    echo -e "\e[38;5;33mInstallation de Fish...\e[0m"
                    pkg install -y fish
                fi
                # TODO : ajouter la configuration de Fish, de ses plugins et des alias (abbr)
                chsh -s fish
                ;;
        esac
    fi
}

###############
# PLUGINS ZSH #
###############

install_zsh_plugins() {
    if command -v zsh &> /dev/null; then
        show_banner
        if $USE_GUM; then
            PLUGINS=$(gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --header="Sélectionner avec ESPACE les plugins à installer :" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "you-should-use" "zsh-abbr" "zsh-alias-finder" "Tout installer")
        else
            echo -e "\e[38;5;33mSélectionner les plugins à installer (SÉPARÉS PAR DES ESPACES) :\e[0m"
        echo -e "\e[38;5;33m1) zsh-autosuggestions\e[0m"
        echo -e "\e[38;5;33m2) zsh-syntax-highlighting\e[0m"
        echo -e "\e[38;5;33m3) zsh-completions\e[0m"
        echo -e "\e[38;5;33m4) you-should-use\e[0m"
        echo -e "\e[38;5;33m5) zsh-abbr\e[0m"
        echo -e "\e[38;5;33m6) zsh-alias-finder\e[0m"
        echo -e "\e[38;5;33m7) Tout installer\e[0m"
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
        echo -e "\e[38;5;33mInstallation $plugin_name...\e[0m"
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

############
# PACKAGES #
############

install_packages() {
    if $PACKAGES_CHOICE; then
        show_banner
        if $USE_GUM; then
            PACKAGES=$(gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=21 --header="Sélectionner avec espace les packages à installer :" "nala" "eza" "colorls" "lsd" "bat" "lf" "fzf" "glow" "tmux" "python" "nodejs" "nodejs-lts" "micro" "vim" "neovim" "lazygit" "open-ssh" "tsu" "Tout installer")
        else
            echo -e "\e[38;5;33mSélectionner les packages à installer (séparés par des espaces) :\e[0m"
            echo -e "\e[38;5;33m1) nala\e[0m"
            echo -e "\e[38;5;33m2) eza\e[0m"
            echo -e "\e[38;5;33m3) colorls\e[0m"   
            echo -e "\e[38;5;33m4) lsd\e[0m"         
            echo -e "\e[38;5;33m5) bat\e[0m"
            echo -e "\e[38;5;33m6) lf\e[0m"
            echo -e "\e[38;5;33m7) fzf\e[0m"
            echo -e "\e[38;5;33m8) glow\e[0m"
            echo -e "\e[38;5;33m9) tmux\e[0m"
            echo -e "\e[38;5;33m10) python\e[0m"
            echo -e "\e[38;5;33m11) nodejs\e[0m"
            echo -e "\e[38;5;33m12) nodejs-lts\e[0m"
            echo -e "\e[38;5;33m13) micro\e[0m"
            echo -e "\e[38;5;33m14) vim\e[0m"
            echo -e "\e[38;5;33m15) neovim\e[0m"
            echo -e "\e[38;5;33m16) lazygit\e[0m"
            echo -e "\e[38;5;33m17) open-ssh\e[0m"
            echo -e "\e[38;5;33m18) tsu\e[0m"
            echo -e "\e[38;5;33m19) Tout installer\e[0m"
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
                    echo -e "\e[38;5;33mInstallation de $PACKAGE...\e[0m"
                    pkg install -y $PACKAGE  >/dev/null 2>&1
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
            echo -e "\e[38;5;33mAucun package sélectionné.\e[0m"
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
    echo -e"$aliases" >> "$ZSHRC"
fi

# TODO : Ajout Fish
#if [ -f "$HOME/.config/fish/config.fish" ]; then
#    # Convertir les alias bash en format fish
#    echo "$aliases" | sed 's/alias \(.*\)="\(.*\)"/alias \1 "\2"/' >> "$HOME/.config/fish/config.fish"
#fi

}

# TODO : Ajouter l'installation de Color Schemes
#show_banner
#if $USE_GUM; then
#   if gum confirm --prompt.foreground="33" --selected.background="33" "Installer des thèmes pour Termux ?"; then
#        # Définir et créer les répertoires
#        CONFIG=$HOME/.config
#        COLORS_DIR_TERMUXSTYLE=$HOME/.termux/colors/termuxstyle
#        COLORS_DIR_TERMUX=$HOME/.termux/colors/termux
#        COLORS_DIR_XFCE4TERMINAL=$HOME/.termux/colors/xfce4terminal

#        mkdir -p $CONFIG $COLORS_DIR_TERMUXSTYLE $COLORS_DIR_TERMUX $COLORS_DIR_XFCE4TERMINAL

#        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des thèmes" -- bash -c '
#            curl -L -o $HOME/.termux/colors.zip https://github.com/GiGiDKR/OhMyTermux/raw/main/files/colors.zip &&
#            unzip -o "$HOME/.termux/colors.zip" -d "$HOME/.termux/"
#        '
#    fi
#else
#    echo -e "\e[38;5;33mInstaller des thèmes pour Termux ? (o/n)\e[0m"
#    read choice
#    if [ "$choice" = "o" ]; then
#        # Définir et créer les répertoires
#        CONFIG=$HOME/.config
#        COLORS_DIR_TERMUXSTYLE=$HOME/.termux/colors/termuxstyle
#        COLORS_DIR_TERMUX=$HOME/.termux/colors/termux
#        COLORS_DIR_XFCE4TERMINAL=$HOME/.termux/colors/xfce4terminal

#        mkdir -p $CONFIG $COLORS_DIR_TERMUXSTYLE $COLORS_DIR_TERMUX $COLORS_DIR_XFCE4TERMINAL

#        echo -e "\e[38;5;33mInstallation des thèmes...\e[0m"
#        curl -L -o $HOME/.termux/colors.zip https://github.com/GiGiDKR/OhMyTermux/raw/main/files/colors.zip
#        unzip -o "$HOME/.termux/colors.zip" -d "$HOME/.termux/"
#    fi
#fi

#rm "$HOME/.termux/colors.zip" >/dev/null 2>&1

########
# FONT #
########

install_font() {
    if $FONT_CHOICE; then
        show_banner
        if $USE_GUM; then
            FONT=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height=14 --header="Sélectionner la police à installer :" "Police par défaut" "CaskaydiaCove Nerd Font" "FiraMono Nerd Font" "JetBrainsMono Nerd Font" "Mononoki Nerd Font" "VictorMono Nerd Font" "RobotoMono Nerd Font" "DejaVuSansMono Nerd Font" "UbuntuMono Nerd Font" "AnonymousPro Nerd Font" "Terminus Nerd Font")
        else
            echo -e "\e[38;5;33mSélectionner la police à installer :\e[0m"
            echo -e "\e[38;5;33m1) Police par défaut\e[0m"
            echo -e "\e[38;5;33m2) CaskaydiaCove Nerd Font\e[0m"
            echo -e "\e[38;5;33m3) FiraMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m4) JetBrainsMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m5) Mononoki Nerd Font\e[0m"
            echo -e "\e[38;5;33m6) VictorMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m7) RobotoMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m8) DejaVuSansMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m9) UbuntuMono Nerd Font\e[0m"
            echo -e "\e[38;5;33m10) AnonymousPro Nerd Font\e[0m"
            echo -e "\e[38;5;33m11) Terminus Nerd Font\e[0m"
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
                *) echo -e "\e[38;5;33mChoix invalide\e[0m"; exit 1 ;;
            esac
        fi

        echo -e "\e[38;5;33mInstallation de la police sélectionnée...\e[0m"
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
                echo -e "\e[38;5;33mPolice déjà installée.\e[0m"
                ;;
            *)
                echo -e "\e[38;5;33mPolice non reconnue : $FONT\e[0m"
                ;;
        esac
    fi
}

#################
# XFCE / DEBIAN #
#################

install_xfce() {
    if $XFCE_CHOICE; then
        show_banner
        local install_xfce=false

        # Demander à l'utilisateur s'il veut installer XFCE et DEBIAN
        if $USE_GUM; then
            if gum confirm --prompt.foreground="33" --selected.background="33" " Installer XFCE et DEBIAN ?"; then
                install_xfce=true
            fi
        else
            echo -e "\e[38;5;33m Installer XFCE et DEBIAN ? (o/n)\e[0m"
            read choice
            if [ "$choice" = "o" ]; then
                install_xfce=true
            fi
        fi

        # Si l'utilisateur ne veut pas installer XFCE, installer seulement les packages nécessaires
        if ! $install_xfce; then
            PACKAGES="ncurses-utils"
            for PACKAGE in $PACKAGES; do
                if $USE_GUM; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de $PACKAGE" -- pkg install -y $PACKAGE 
                else
                    echo -e "\e[38;5;33mInstallation de $PACKAGE...\e[0m"
                    pkg install -y $PACKAGE >/dev/null 2>&1
                fi
            done
            export PATH="$PATH:$PREFIX/bin"
            show_banner
            
            # Demander à l'utilisateur s'il veut exécuter OhMyTermux
            local execute_ohmytermux=false
            if $USE_GUM; then
                if gum confirm --prompt.foreground="33" --selected.background="33" " Exécuter OhMyTermux ?"; then
                    execute_ohmytermux=true
                fi
            else
                echo -e "\e[38;5;33m Exécuter OhMyTermux ? (o/n)\e[0m"
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
                echo -e "\e[38;5;33mOhMyTermux sera actif au prochain démarrage de Termux.\e[0m"
            fi
            return
        fi

        # Installation de XFCE et DEBIAN
        show_banner
        pkgs=('wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio')

        # Installation des pré-requis
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des pré-requis" -- pkg install ncurses-ui-libs && pkg uninstall dbus -y
        else
            echo -e "\e[38;5;33mInstallation des pré-requis...\e[0m"
            pkg install ncurses-ui-libs && pkg uninstall dbus -y
        fi

        # Mise à jour des paquets
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Mise à jour des paquets" -- pkg update -y
        else
            echo -e "\e[38;5;33mMise à jour des paquets...\e[0m"
            pkg update -y
        fi

        # Installation des paquets nécessaires
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation des paquets nécessaires" -- pkg install "${pkgs[@]}" -y
        else
            echo -e "\e[38;5;33mInstallation des paquets nécessaires...\e[0m"
            pkg install "${pkgs[@]}" -y
        fi

        # Téléchargement des scripts
        show_banner
        if $USE_GUM; then
            gum spin --spinner.foreground="33" --title.foreground="33" --title="Téléchargement des scripts" -- bash -c "
                wget https://github.com/GiGiDKR/OhMyTermux/raw/main/xfce.sh &&
                wget https://github.com/GiGiDKR/OhMyTermux/raw/main/proot.sh &&
                wget https://github.com/GiGiDKR/OhMyTermux/raw/main/utils.sh
            "
        else
            echo -e "\e[38;5;33mTéléchargement des scripts...\e[0m"
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/xfce.sh
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/proot.sh
            wget https://github.com/GiGiDKR/OhMyTermux/raw/main/utils.sh
        fi
        chmod +x *.sh

        # Exécution des scripts
        show_banner
        if $USE_GUM; then
            ./xfce.sh --gum
            ./proot.sh --gum
        else
            ./xfce.sh
            ./proot.sh
        fi
        ./utils.sh

        # Ajout de la fonction get_username et de l'alias debian
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

##############
# Termux-X11 #
##############

install_termux_x11() {
    show_banner
    local install_x11=false

    if $USE_GUM; then
        if gum confirm --prompt.foreground="33" --selected.background="33" " Installer Termux-X11 ?"; then
            install_x11=true
        fi
    else
        echo -e "\e[38;5;33m Installer Termux-X11 ? (o/n)\e[0m"
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
            echo -e "\e[38;5;33mTéléchargement de Termux-X11 APK...\e[0m"
            wget "$apk_url" -O "$apk_file"
        fi

        if [ -f "$apk_file" ]; then
            termux-open "$apk_file"
            echo -e "\e[38;5;33mVeuillez installer l'APK manuellement.\e[0m"
            echo -e "\e[38;5;33mUne fois l'installation terminée, appuyez sur Entrée pour continuer.\e[0m"
            read -r
            rm "$apk_file"
        else
            echo -e "\e[38;5;31mErreur : Le téléchargement de l'APK a échoué.\e[0m"
        fi
    fi
}

####################
# OhMyTermuxScript #
####################

install_script() {
    if $SCRIPT_CHOICE; then
        SCRIPT_DIR="$HOME/OhMyTermuxScript"
        if [ ! -d "$SCRIPT_DIR" ]; then
            if $USE_GUM; then
                if gum confirm --prompt.foreground="33" --selected.background="33" "  Installer OhMyTermuxScript ?"; then
                    gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de OhMyTermuxScript" -- bash -c 'git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh'
                fi
            else
                echo -e "\e[38;5;33m  Installer OhMyTermuxScript ? (o/n)\e[0m"
                read -r choice
                if [ "$choice" = "o" ]; then
                    echo -e "\e[38;5;33mInstallation de OhMyTermuxScript...\e[0m"
                    git clone https://github.com/GiGiDKR/OhMyTermuxScript.git "$HOME/OhMyTermuxScript" && chmod +x $HOME/OhMyTermuxScript/*.sh
                fi
            fi
        fi
    fi
}

# TODO : Implémenter l'éxecution des scripts
#execute_script() {
#if [ -d "$SCRIPT_DIR" ]; then
#    mapfile -t scripts < <(find "$SCRIPT_DIR" -name "*.sh" -type f)
#
#    script_names=()
#    for script in "${scripts[@]}"; do
#        script_names+=("$(basename "$script")")
#    done
#
#    while true; do
#        show_banner
#        echo -e "\e[38;5;33m            Sélection de script\n\e[0m"
#
#        if $USE_GUM; then
#            script_choice=$(gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" "${script_names[@]}" "QUITTER")
#            if [ "$script_choice" == "> QUITTER" ]; then
#                clear
#                return
#            fi
#        else
#            select script_choice in "${script_names[@]}" "QUITTER"; do
#                if [[ $REPLY -eq $(( ${#script_names[@]} + 1 )) ]]; then
#                    clear
#                    return
#                elif [[ 1 -le $REPLY && $REPLY -le ${#script_names[@]} ]]; then
#                    selected_script="${scripts[$((REPLY-1))]}"
#                    break
#                else
#                    show_banner
#                    echo -e "\e[38;5;196m         Aucun script correspondant\e[0m"
#                    sleep 1
#                    continue 2
#                fi
#            done
#        fi
#        if [ -n "$selected_script" ]; then
#            bash "$selected_script"
#        else
#            echo "Aucun script sélectionné."
#        fi
#    done
#else
#    echo "Le répertoire $SCRIPT_DIR n'existe pas."
#fi
#}

#if $USE_GUM; then
#    if gum confirm --prompt.foreground="33" --selected.background="33" "Exécuter un script ?"; then
#        execute_script
#    fi
#else
#    read -p "     Exécuter un script ? (o/n) " choice
#    if [ "$choice" = "o" ]; then
#        execute_script
#    fi
#fi

# TODO : Implémenter OhMyObsidian
################
# OhMyObsidian #
################
#if $USE_GUM; then
#    if gum confirm --prompt.foreground="33" --selected.background="33" " Installer OhMyObsidian ?"; then
#        gum spin --spinner.foreground="33" --title.foreground="33" --title="Installation de OhMyObsidian" -- \
#        bash -c 'curl -o $HOME/install.sh https://raw.githubusercontent.com/GiGiDKR/OhMyObsidian/main/install.sh && chmod +x $HOME/install.sh && $HOME/install.sh'
#    fi
#else
#    echo -e "\e[38;5;33m Installer OhMyObsidian ? (o/n)\e[0m"
#    read -r choice
#    if [ "$choice" = "o" ]; then
#        echo -e "\e[38;5;33mInstallation de OhMyObsidian...\e[0m"
#        curl -o $HOME/install.sh https://raw.githubusercontent.com/GiGiDKR/OhMyObsidian/main/install.sh && chmod +x $HOME/install.sh && $HOME/install.sh
#    fi
#fi

###############################
# Partie principale du script #
###############################
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

#################
# Fin du script #
#################

rm -f xfce.sh proot.sh utils.sh install.sh >/dev/null 2>&1

show_banner
if $USE_GUM; then
    if gum confirm --prompt.foreground="33" --selected.background="33" "   Exécuter OhMyTermux ?"; then
        clear
        #if [ -f "$ZSHRC" ]; then
        #    source "$ZSHRC"
        #else
        #    source $BASHRC
        #fi
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "\e[38;5;33mOhMyTermux sera actif au prochain démarrage de Termux.\e[0m"
    fi
else
    echo -e "\e[38;5;33m   Exécuter OhMyTermux ? (o/n)\e[0m"
    read choice
    if [ "$choice" = "o" ]; then
        clear
        #if [ -f "$ZSHRC" ]; then
        #    source "$ZSHRC"
        #else
        #    source $BASHRC
        #fi
        if [ "$shell_choice" = "zsh" ]; then
            exec zsh -l
        else
            exec $shell_choice
        fi
    else
        echo -e "\e[38;5;33mOhMyTermux sera actif au prochain démarrage de Termux.\e[0m"
    fi
fi