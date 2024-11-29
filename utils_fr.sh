#!/bin/bash

#------------------------------------------------------------------------------
# PRUN
# Lancer des programmes dans le terminal proot
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/prun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 $@

EOF
chmod +x $PREFIX/bin/prun

#------------------------------------------------------------------------------
# ZRUN
# Lancer des programmes avec le pilote Zink
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/zrun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform $@

EOF
chmod +x $PREFIX/bin/zrun

#------------------------------------------------------------------------------
# ZRUN HUD
# Afficher le HUD de Zink
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/zrunhud
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform GALLIUM_HUD=fps $@

EOF
chmod +x $PREFIX/bin/zrunhud

#------------------------------------------------------------------------------
# CP2MENU
# Lancer des programmes à partir du menu xfce au lieu du terminal
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/cp2menu
#!/bin/bash

cd

user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"

# Obtenir le nom d'utilisateur
username=$(basename "$user_dir"/*)

action=$(zenity --list --title="Choisir une action" --text="Sélectionnez une action :" --radiolist --column="" --column="Action" TRUE "Copier le fichier .desktop" FALSE "Supprimer le fichier .desktop")

if [[ -z $action ]]; then
  zenity --info --text="Aucune action sélectionnée. Abandon..." --title="Opération annulée"
  exit 0
fi

if [[ $action == "Copier le fichier .desktop" ]]; then
  selected_file=$(zenity --file-selection --title="Sélectionner le fichier .desktop" --file-filter="*.desktop" --filename="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/applications")

  if [[ -z $selected_file ]]; then
    zenity --info --text="Aucun fichier sélectionné. Abandon..." --title="Opération annulée"
    exit 0
  fi

  desktop_filename=$(basename "$selected_file")

  cp "$selected_file" "$PREFIX/share/applications/"
  sed -i "s/^Exec=\(.*\)$/Exec=pd login debian --user $username --shared-tmp -- env DISPLAY=:1.0 \1/" "$PREFIX/share/applications/$desktop_filename"

  zenity --info --text="Opération terminée avec succès !" --title="Succès"
elif [[ $action == "Supprimer le fichier .desktop" ]]; then
  selected_file=$(zenity --file-selection --title="Sélectionner le fichier .desktop à supprimer" --file-filter="*.desktop" --filename="$PREFIX/share/applications")

  if [[ -z $selected_file ]]; then
    zenity --info --text="Aucun fichier sélectionné pour suppression. Abandon..." --title="Opération annulée"
    exit 0
  fi

  desktop_filename=$(basename "$selected_file")

  rm "$selected_file"

  zenity --info --text="Le fichier '$desktop_filename' a été supprimé avec succès !" --title="Succès"
fi

EOF
chmod +x $PREFIX/bin/cp2menu

echo "[Desktop Entry]
Version=1.0
Type=Application
Name=cp2menu
Comment=
Exec=cp2menu
Icon=edit-move
Categories=System;
Path=
Terminal=false
StartupNotify=false
" > $PREFIX/share/applications/cp2menu.desktop 
chmod +x $PREFIX/share/applications/cp2menu.desktop 

#------------------------------------------------------------------------------
# APP INSTALLER
# Installer des apps indisponibles dans les dépôts Termux / Debian proot
#------------------------------------------------------------------------------
cat <<'EOF' > "$PREFIX/bin/app-installer"
#!/bin/bash

# Définition du répertoire de l'installateur
INSTALLER_DIR="$HOME/.App-Installer"
REPO_URL="https://github.com/GiGIDKR/OhMyAppInstaller.git"
DESKTOP_DIR="$HOME/Desktop"
APP_DESKTOP_FILE="$DESKTOP_DIR/app-installer.desktop"

# Vérification de l'existence du répertoire
if [ ! -d "$INSTALLER_DIR" ]; then
    # Le répertoire n'existe pas, cloner le dépôt
    git clone "$REPO_URL" "$INSTALLER_DIR" > /dev/null 2>&1
else
    "$INSTALLER_DIR/app-installer"
fi

# Vérification de l'existence du fichier .desktop
if [ ! -f "$APP_DESKTOP_FILE" ]; then
    # Le fichier .desktop n'existe pas, le créer
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=App Installer
    Comment=
    Exec=$PREFIX/bin/app-installer
    Icon=package-install
    Categories=System;
    Path=
    Terminal=false
    StartupNotify=false
" > "$APP_DESKTOP_FILE"
    chmod +x "$APP_DESKTOP_FILE"
fi

# Attribution des droits d'exécution
chmod +x "$INSTALLER_DIR/app-installer"

EOF
chmod +x "$PREFIX/bin/app-installer"
bash $PREFIX/bin/app-installer > /dev/null 2>&1

# Création du raccourci
if [ ! -f "$HOME/Desktop/app-installer.desktop" ]; then
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=App Installer
    Comment=
    Exec=$PREFIX/bin/app-installer
    Icon=package-install
    Categories=System;
    Path=
    Terminal=false
    StartupNotify=false
" > "$HOME/Desktop/app-installer.desktop"
    chmod +x "$HOME/Desktop/app-installer.desktop"
fi  

#------------------------------------------------------------------------------
# SCRIPT DE DÉMARRAGE
# Démarrer Termux-X11 et XFCE
#------------------------------------------------------------------------------
cat <<'EOF' > start
#!/bin/bash

# Activer PulseAudio sur le réseau
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

#GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 program

#MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform program

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Définir le serveur audio
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1


EOF

chmod +x start
mv start $PREFIX/bin

#------------------------------------------------------------------------------
# SCRIPT D'ARRÊT
# Stopper Termux-X11 et XFCE
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/kill_termux_x11
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

chmod +x $PREFIX/bin/kill_termux_x11

# Création du raccourci
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=Stop
Comment=
Exec=kill_termux_x11
Icon=shutdown
Categories=System;
Path=
StartupNotify=false
" > $HOME/Desktop/kill_termux_x11.desktop
chmod +x $HOME/Desktop/kill_termux_x11.desktop
mv $HOME/Desktop/kill_termux_x11.desktop $PREFIX/share/applications