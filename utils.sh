#!/bin/bash

#------------------------------------------------------------------------------
# PRUN
# Launch programs in the proot terminal
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/prun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 $@

EOF
chmod +x $PREFIX/bin/prun

#------------------------------------------------------------------------------
# ZRUN
# Launch programs with the Zink driver
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/zrun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform $@

EOF
chmod +x $PREFIX/bin/zrun

#------------------------------------------------------------------------------
# ZRUN HUD
# Display the Zink HUD
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/zrunhud
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform GALLIUM_HUD=fps $@

EOF
chmod +x $PREFIX/bin/zrunhud

#------------------------------------------------------------------------------
# CP2MENU
# Launch programs from the XFCE menu instead of the terminal
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/cp2menu
#!/bin/bash

cd

user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"

# Get the username
username=$(basename "$user_dir"/*)

action=$(zenity --list --title="Choose an action" --text="Choose an action :" --radiolist --column="" --column="Action" TRUE "Copy the .desktop file" FALSE "Delete the .desktop file")

if [[ -z $action ]]; then
  zenity --info --text="No action selected. Abandon..." --title="Operation cancelled"
  exit 0
fi

if [[ $action == "Copy the .desktop file" ]]; then
  selected_file=$(zenity --file-selection --title="Select the .desktop file" --file-filter="*.desktop" --filename="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/applications")

  if [[ -z $selected_file ]]; then
    zenity --info --text="No file selected. Abandon..." --title="Operation cancelled"
    exit 0
  fi

  desktop_filename=$(basename "$selected_file")

  cp "$selected_file" "$PREFIX/share/applications/"
  sed -i "s/^Exec=\(.*\)$/Exec=pd login debian --user $username --shared-tmp -- env DISPLAY=:1.0 \1/" "$PREFIX/share/applications/$desktop_filename"
  
  zenity --info --text="Operation completed successfully !" --title="Success"
elif [[ $action == "Delete the .desktop file" ]]; then
  selected_file=$(zenity --file-selection --title="Select the .desktop file to delete" --file-filter="*.desktop" --filename="$PREFIX/share/applications")

  if [[ -z $selected_file ]]; then
    zenity --info --text="No file selected for deletion. Abandon..." --title="Operation cancelled"
    exit 0
  fi

  desktop_filename=$(basename "$selected_file")

  rm "$selected_file"

  zenity --info --text="The '$desktop_filename' file has been deleted successfully !" --title="Success"
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
# Install apps unavailable in the Termux / Debian proot repositories
#------------------------------------------------------------------------------
cat <<'EOF' > "$PREFIX/bin/app-installer"
#!/bin/bash

# Define the installer directory
INSTALLER_DIR="$HOME/.App-Installer"
REPO_URL="https://github.com/GiGIDKR/OhMyAppInstaller.git"
BRANCH="easybashgui"
DESKTOP_DIR="$HOME/Desktop"
APP_DESKTOP_FILE="$DESKTOP_DIR/app-installer.desktop"

# Check the existence of the directory
if [ ! -d "$INSTALLER_DIR" ]; then
    # The directory does not exist, clone the repository
    git clone --branch "$BRANCH" "$REPO_URL" "$INSTALLER_DIR" > /dev/null 2>&1
else
    "$INSTALLER_DIR/app-installer"
fi

# Check the existence of the .desktop file
if [ ! -f "$APP_DESKTOP_FILE" ]; then
    # The .desktop file does not exist, create it
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

# Assign execution rights
chmod +x "$INSTALLER_DIR/app-installer"

EOF
chmod +x "$PREFIX/bin/app-installer"
bash $PREFIX/bin/app-installer > /dev/null 2>&1

# Create the shortcut
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
# START SCRIPT
# Start Termux-X11 and XFCE
#------------------------------------------------------------------------------
cat <<'EOF' > start
#!/bin/bash

# Activate PulseAudio on the network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

#GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 program

#MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform program

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Define the audio server
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1

EOF

chmod +x start
mv start $PREFIX/bin

#------------------------------------------------------------------------------
# STOP SCRIPT
# Stop Termux-X11 and XFCE
#------------------------------------------------------------------------------
cat <<'EOF' > $PREFIX/bin/kill_termux_x11
#!/bin/bash
  
# Check the execution of the processes in Termux or Proot
if pgrep -f 'apt|apt-get|dpkg|nala' > /dev/null; then
  zenity --info --text="A software is being installed in Termux or Proot. Please wait for these processes to finish before continuing."
  exit 1
fi

# Get the process IDs of the Termux-X11 and XFCE sessions
termux_x11_pid=$(pgrep -f /system/bin/app_process.*com.termux.x11.Loader)
xfce_pid=$(pgrep -f "xfce4-session")

# Stop the processes only if they exist
if [ -n "$termux_x11_pid" ]; then
  kill -9 "$termux_x11_pid" 2>/dev/null
fi

if [ -n "$xfce_pid" ]; then
  kill -9 "$xfce_pid" 2>/dev/null
fi

# Display a dynamic message
if [ -n "$termux_x11_pid" ] || [ -n "$xfce_pid" ]; then
  zenity --info --text="Termux-X11 and XFCE sessions closed."
else
  zenity --info --text="Termux-X11 or XFCE session not found."
fi

# Stop the Termux application only if the PID exists
info_output=$(termux-info)
if pid=$(echo "$info_output" | grep -o 'TERMUX_APP_PID=[0-9]\+' | awk -F= '{print $2}') && [ -n "$pid" ]; then
  kill "$pid" 2>/dev/null
fi

exit 0

EOF

chmod +x $PREFIX/bin/kill_termux_x11

# Create the shortcut
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