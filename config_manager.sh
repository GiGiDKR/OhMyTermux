#!/bin/bash

#------------------------------------------------------------------------------
# VARIABLES GLOBALES
#------------------------------------------------------------------------------
CONFIG_FILE="$HOME/.config/OhMyTermux/config.ini"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"
BACKUP_DIR="$CONFIG_DIR/backups"

#------------------------------------------------------------------------------
# COULEURS D'AFFICHAGE
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Succès
COLOR_GOLD='\033[38;5;220m'   # Avertissement
COLOR_RED='\033[38;5;196m'    # Erreur
COLOR_RESET='\033[0m'         # Réinitialisation

#------------------------------------------------------------------------------
# MESSAGES D'ERREUR
#------------------------------------------------------------------------------
error_msg() {
    echo -e "${COLOR_RED}ERREUR: $1${COLOR_RESET}" >&2
}

#------------------------------------------------------------------------------
# MESSAGES DE SUCCÈS
#------------------------------------------------------------------------------
success_msg() {
    echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

#------------------------------------------------------------------------------
# VALIDATION DES VALEURS DE CONFIGURATION
#------------------------------------------------------------------------------
validate_config_value() {
    local section=$1
    local key=$2
    local value=$3
    
    # Vérifier le format de la section
    if [[ ! $section =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_msg "Nom de section invalide: $section"
        return 1
    fi
    
    # Vérifier le format de la clé
    if [[ ! $key =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_msg "Nom de clé invalide: $key"
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# SAUVEGARDE DE LA CONFIGURATION
#------------------------------------------------------------------------------
backup_config() {
    mkdir -p "$BACKUP_DIR"
    if [ -f "$CONFIG_FILE" ]; then
        local backup_file="$BACKUP_DIR/config_$(date +%Y%m%d_%H%M%S).ini.bak"
        if cp "$CONFIG_FILE" "$backup_file"; then
            success_msg "Sauvegarde créée: $backup_file"
            # Nettoyer les anciennes sauvegardes (garder les 5 plus récentes)
            ls -t "$BACKUP_DIR"/*.ini.bak | tail -n +6 | xargs -r rm
            return 0
        else
            error_msg "Échec de la sauvegarde"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# INITIALISATION DE LA CONFIGURATION
#------------------------------------------------------------------------------
init_config() {
    mkdir -p "$CONFIG_DIR"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOL
# Configuration OhMyTermux
# Créé le $(date '+%Y-%m-%d %H:%M:%S')

[general]
USE_GUM=false
VERBOSE=false
EXECUTE_INITIAL_CONFIG=true

[termux]
CHANGE_REPO=false
SETUP_STORAGE=false

[xfce]
INSTALL_THEME=false
INSTALL_ICONS=false
INSTALL_WALLPAPERS=false
INSTALL_CURSORS=false
SELECTED_THEME=
SELECTED_ICON_THEME=
SELECTED_WALLPAPER=

[proot]
PROOT_USERNAME=
TIMEZONE=
DEBIAN_VERSION=bookworm
DEBIAN_LOCALE=fr_FR.UTF-8
MESA_VULKAN_INSTALLED=false
EOL
        success_msg "Fichier de configuration créé: $CONFIG_FILE"
        return 0
    fi
    return 1
}

#------------------------------------------------------------------------------
# LECTURE D'UNE VALEUR
#------------------------------------------------------------------------------
read_config_value() {
    local section=$1
    local key=$2
    local default=$3
    
    if ! validate_config_value "$section" "$key" "$default"; then
        return 1
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(sed -n "/^\[$section\]/,/^\[/p" "$CONFIG_FILE" | grep "^$key=" | cut -d'=' -f2-)
        if [ -n "$value" ]; then
            echo "${value}" | tr -d '"'
            return 0
        fi
    fi
    echo "$default"
}

#------------------------------------------------------------------------------
# MISE À JOUR D'UNE VALEUR
#------------------------------------------------------------------------------
update_config_value() {
    local section=$1
    local key=$2
    local value=$3
    
    if ! validate_config_value "$section" "$key" "$value"; then
        return 1
    fi
    
    # Créer le fichier s'il n'existe pas
    if [ ! -f "$CONFIG_FILE" ]; then
        init_config
    fi
    
    # Faire une sauvegarde avant modification
    backup_config
    
    # Vérifier si la section existe
    if ! grep -q "^\[$section\]" "$CONFIG_FILE"; then
        echo -e "\n[$section]" >> "$CONFIG_FILE"
    fi
    
    # Mettre à jour ou ajouter la valeur
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sed -i "/^\[$section\]/,/^\[/s/^$key=.*/$key=$value/" "$CONFIG_FILE"
    else
        sed -i "/^\[$section\]/a $key=$value" "$CONFIG_FILE"
    fi
    
    success_msg "Configuration mise à jour: [$section] $key=$value"
    return 0
}

#------------------------------------------------------------------------------
# MISE À JOUR D'UNE SECTION COMPLÈTE
#------------------------------------------------------------------------------
update_config_section() {
    local section=$1
    local content=$2
    
    if ! validate_config_value "$section" "" ""; then
        return 1
    fi
    
    # Créer le fichier s'il n'existe pas
    if [ ! -f "$CONFIG_FILE" ]; then
        init_config
    fi
    
    # Faire une sauvegarde avant modification
    backup_config
    
    # Supprimer l'ancienne section tout en préservant les commentaires
    local tmp_file="${CONFIG_FILE}.tmp"
    awk -v section="$section" '
        BEGIN { in_section=0; buffer="" }
        /^#/ { print; next }  # Préserver les commentaires
        /^\[.*\]/ {
            if ($0 == "["section"]") {
                in_section=1
                buffer=""
            } else {
                if (in_section) {
                    in_section=0
                }
                print buffer
                buffer=$0
            }
            next
        }
        {
            if (!in_section) {
                if (buffer) {
                    print buffer
                    buffer=""
                }
                print
            }
        }
        END {
            if (buffer) print buffer
        }
    ' "$CONFIG_FILE" > "$tmp_file"
    
    # Ajouter la nouvelle section
    echo -e "\n[$section]$content" >> "$tmp_file"
    
    # Remplacer le fichier original
    mv "$tmp_file" "$CONFIG_FILE"
    
    success_msg "Section [$section] mise à jour"
    return 0
}

#------------------------------------------------------------------------------
# EXPORT DE LA CONFIGURATION
#------------------------------------------------------------------------------
export_config() {
    local export_file=$1
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error_msg "Aucun fichier de configuration à exporter"
        return 1
    fi
    
    if [ -z "$export_file" ]; then
        export_file="$CONFIG_DIR/config_export_$(date +%Y%m%d_%H%M%S).ini"
    fi
    
    if cp "$CONFIG_FILE" "$export_file"; then
        success_msg "Configuration exportée vers: $export_file"
        return 0
    else
        error_msg "Échec de l'export de la configuration"
        return 1
    fi
}

#------------------------------------------------------------------------------
# IMPORT DE LA CONFIGURATION
#------------------------------------------------------------------------------
import_config() {
    local import_file=$1
    
    if [ ! -f "$import_file" ]; then
        error_msg "Fichier d'import introuvable: $import_file"
        return 1
    fi
    
    # Faire une sauvegarde avant import
    backup_config
    
    if cp "$import_file" "$CONFIG_FILE"; then
        success_msg "Configuration importée depuis: $import_file"
        return 0
    else
        error_msg "Échec de l'import de la configuration"
        return 1
    fi
}
