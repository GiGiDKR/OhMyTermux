 ![Logo OhMyTermux](assets/logo.jpg)

# OhMyTermux 🧊

### **From selecting a shell to applying a cursor pack to performing stylish clicks in a complete Debian development environment that fits in your pocket  : dozens of parameters are available in [OhMyTermux](https://github.com/GiGiDKR/OhMyTermux).**

## Installation

>[!IMPORTANT]
> [Gum](https://github.com/charmbracelet/gum) allows simplified use of CLI scripts, **_it is recommended_** to use it by adding the `--gum` or `-g` argument.

🔥 To install **OhMyTermux** with **[Gum](https://github.com/charmbracelet/gum)**
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
```

🧊 Or to run a version that tries to get closer to simplicity and clarity
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

## About this program 

### Termux

<details>

<summary>Packages installed by default</summary>

- [wget](https://github.com/mirror/wget)
- [curl](https://github.com/curl/curl)
- [git](https://github.com/git/git)
- [unzip](https://en.m.wikipedia.org/wiki/ZIP_(file_format))

</details>

<details>

<summary>Individually selectable packages</summary>

- [nala](https://github.com/volitank/nala)
- [eza](https://github.com/eza-community/eza)
- [lsd](https://github.com/lsd-rs/lsd)
- [logo-ls](https://github.com/Yash-Handa/logo-ls)
- [bat](https://github.com/sharkdp/bat)
- [lf](https://github.com/gokcehan/lf)
- [fzf](https://github.com/junegunn/fzf)
- [glow](https://github.com/charmbracelet/glow)
- [python](https://github.com/python)
- [nodejs](https://github.com/nodejs/node)
- [nodejs-lts](https://github.com/nodejs/Release)
- [micro](https://github.com/zyedidia/micro)
- [vim](https://github.com/vim/vim)
- [neovim](https://github.com/neovim/neovim)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [open-ssh](https://www.openssh.com/)

</details>

<details>

<summary>Shell selection</summary>

- [Bash](https://git.savannah.gnu.org/cgit/bash.git/)
- [ZSH](https://www.zsh.org/)
- [Fish](https://github.com/fish-shell/fish-shell)

</details>
 
<details>

<summary>Zsh configuration</summary>

- [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
- [zsh-alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

</details>
    
<details>

<summary>Fish configuration</summary>

- [Oh-My-Fish](https://github.com/oh-my-fish/oh-my-fish)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [Pure](https://github.com/pure-fish/pure)
- [Fishline](https://github.com/0rax/fishline)
- [Virtualfish](https://github.com/justinmayer/virtualfish)
- [Fish Abbreviation Tips](https://github.com/gazorby/fish-abbreviation-tips)
- [Bang-Bang](https://github.com/oh-my-fish/plugin-bang-bang)
- [Fish You Should Use](https://github.com/paysonwallach/fish-you-should-use)
- [Catppuccin for Fish](https://github.com/catppuccin/fish)

</details>
 
<details>

<summary>Termux Display</summary>

- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) 
- [Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
  
</details>
 
<details>

<summary>Termux configuration</summary>

- Custom aliases (common aliases + specific aliases depending on the package or plugin installed)
- Symlink to internal storage user directories
  
</details>
  
<details>

<summary>OhMyTermuxScript</summary>
  
- Theme Selector
- Nerd Fonts Installer
- App-Installer (VSCode, PyCharm, Obsidian...)
- Native Termux XFCE4 desktop on Termux-X11
- Oh-My-Zsh [^2]
- Oh-My-Posh [^1]
- Electron Node.js
- XDRP (native Termux or proot-distro)
  
</details>
 
[^1]: In development :coming in version 1.0
[^2]: Optionally integrated into the main script
[^3]: In development (no release date yet)

### **XFCE**

- Setup an [XFCE](https://wiki.termux.com/wiki/Graphical_Environment#XFCE) desktop for native Termux.

  - Using [Termux-X11](https://github.com/termux/termux-x11) is preferred over VNC. The Termux-x11 server will be installed as well as the Android APK.

  - 3 XFCE configurations are available :
    <details>

    <summary>Minimal</summary>
    
    Only the necessary packages :
    ```
    termux-x11-nightly
    virglrenderer-android
    xfce4
    xfce4-terminal
    ```
    </details>

    <details>

    <summary>Recommended</summary>
 
    Minimal installation + following packages :
    ```
    netcat-openbsd            # Network Utility
    pavucontrol-qt            # Sound Control
    thunar-archive-plugin     # Archives
    wmctrl                    # Window Control 
    xfce4-notifyd             # Notifications
    xfce4-screenshooter       # Screenshot
    xfce4-taskmanagerb        # Task Manager
    xfce4-whiskermenu-plugin  # Whisker Menu
    ```
    And the following interface elements :
    ```
    WhiteSur-gtk-theme
    WhiteSur-icon-theme
    Fluent-cursors
    WhiteSur-wallpapers
    ```
    </details>

    <details>
 
    <summary>Custom</summary>
    
    The contents of the Minimal installation + the choice among :
    ```
    pavucontrol-qt            # Sound Control
    wmctrl                    # Window Control 
    netcat-openbsd            # Network Utility
    thunar-archive-plugin     # Archives
    xfce4-whiskermenu-plugin  # Whisker Menu
    xfce4-notifyd             # Notifications
    xfce4-screenshooter       # Screenshot
    xfce4-taskmanagerb        # Task Manager
    gigolo'                   # File Manager
    jq'                       # JSON Utility
    mousepad'                 # Text Editor
    netcat-openbsd'           # Network Utility
    parole'                   # Media Player
    pavucontrol-qt'           # Sound Control
    ristretto'                # Image Manager
    thunar-archive-plugin'    # Archives
    thunar-media-tags-plugin' # Media
    wmctrl                    # Window Control
    xfce4-artwork             # Artwork
    xfce4-battery-plugin      # Battery
    xfce4-clipman-plugin      # Clipboard
    xfce4-cpugraph-plugin'    # CPU Graph
    xfce4-datetime-plugin'    # Date and Time
    xfce4-dict'               # Dictionary
    xfce4-diskperf-plugin'    # Disk Performance
    xfce4-fsguard-plugin'     # Disk Monitoring
    xfce4-genmon-plugin'      # Generic Widgets
    xfce4-mailwatch-plugin'   # Mail Monitoring
    xfce4-netload-plugin'     # Network Loading
    xfce4-notes-plugin'       # Notes
    xfce4-notifyd'            # Notifications
    xfce4-places-plugin'      # Places
    xfce4-screenshooter'      # Screenshot
    xfce4-taskmanager'        # Task Manager
    xfce4-systemload-plugin'  # System Load
    xfce4-timer-plugin'       # Timer
    xfce4-wavelan-plugin'     # Wi-Fi
    xfce4-weather-plugin'     # Weather Information
    xfce4-whiskermenu-plugin' # Whisker Menu
    ```
    The choice among following interface elements :
    
    Theme :
    ```
    WhiteSur
    Fluent
    Lavanda
     ```
    Icons :
     ```
     WhiteSur
     McMojave-circle
     Tela
     Fluent
     Qogir
     ```
     Cursors :
     ```
     Fluent
     ```
     Wallpapers :
     ```
     WhiteSur-wallpapers
     ```
    </details>

- The ability to install a web browser, either [Chromium](https://www.chromium.org/) or Firefox.

> [!IMPORTANT]
> The recommended installation uses approximately **4 GB** of disk space

### Debian
[Debian PRoot](https://wiki.termux.com/wiki/PRoot) installation

## Usage

<details>
  
<summary>🧊 Starting the desktop</summary>

You will recieve a popup to allow installs from termux, this will open the APK for the Termux-X11 android app. While you do not have to allow installs from termux, you will still need to install manually by using a file browser and finding the APK in your downloads folder.

Use the command ```start``` to initiate a Termux-X11 session.

This will start the termux-x11 server, XFCE4 desktop and open the Termux-X11 app right into the desktop.

To enter the Debian proot install from terminal use the command ```debian```

Also note, you do not need to set display in Debian proot as it is already set. This means you can use the terminal to start any GUI application and it will startup.

</details>

<details>
  
<summary>🧊 Debain Proot</summary>

To enter proot use the command ```debian```, from there you can install aditional software with apt and use cp2menu in termux to copy the menu items over to termux xfce menu.

There are two scripts available for this setup as well :

```prun```  Running this followed by a command you want to run from the debian proot install will allow you to run stuff from the termux terminal without running ```debian``` to get into the proot itself.

```cp2menu``` Running this will pop up a window allowing you to copy .desktop files from debian proot into the termux xfce "start" menu so you won't need to launch them from terminal. A launcher is available in the System menu section.

</details>

&nbsp;

> [!WARNING]
> **Process completed (signal 9) - press Enter**

<details>
  
<summary>How to fix this Termux error</summary>

You need to run this adb command to fix the process 9 error that will force close Termux :
```
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```
To do this without using a PC you have several methods :
First, Connect to WIFI.

**Method 1 :** 
Install adb in Termux by running this code:
```
pkg install android-tools -y
```
Then open settings and enable developer's options by selecting "About phone" then hit "Build" 7 times.

Back out of this menu and go into developer's options, enable wireless debugging then click into there to get the port number then click pair device to get the pairing code.

Put settings into split screen mode by pressing the square button on the bottom right of your phone, and hold the settings icon until the split screen icon shows up.

Then select Termux and in settings select pair with a code. In Termux type `adb pair` then enter your pairing info.

After you have completed this process you can type adb connect and connect to your phone with the ip and port provided in the wireless debugging menu. You can then run the fix command :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

**Method 2 :**

Install LADB from [Playstore](https://play.google.com/store/apps/details?id=com.draco.ladb) or from [GitHub](https://github.com/hyperio546/ladb-builds/releases).

In split screen have one side LADB and the other side showing developer settings.
In developer settings, enable wireless debugging then click into there to get the port number then click pair device to get the pairing code.
Enter both those values into LADB.
Once it connects run the fix command :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

</details>

&nbsp;

## 💻 Version history

<details>
<summary>Version 0.0.1</summary>
Initial upload
</details> 

<details>
<summary>Version 0.0.2</summary>
Command line interface changes
</details> 

<details>
<summary>Version 0.0.3</summary>
~~Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)~~ (Rollback)
</details>

<details>
<summary>Version 0.0.4</summary>
Optimization of the alias system according to package and shell selection
</details> 

<details>
<summary>Version 0.0.5</summary>
Adding packages to the selectable list
</details> 
  
<details>
<summary>Version 0.0.6</summary>
Dynamic management of .zshrc configuration
</details> 
  
<details>
<summary>Version 0.0.7</summary>
Global modification of the main script by splitting each step into a function that can be executed alone (or combined with others) with the addition of an argument to the execution command
</details>

<details>
<summary>Version 0.0.8</summary>
  
  - Addition of the argument `--shell` to install a shell
  - Addition of the argument `--package` to install packages
  - Addition of the argument `--xfce` to install XFCE and Debian proot
  - Addition of the argument `--font` to install fonts
  - ~~Addition of the argument `--script` to install [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) [^1]~~ (Rollback)
  - Addition of the argument `--skip` to skip the initial configuration
</details> 

<details>
<summary>Version 0.0.9</summary>
Bug fixes and improvements
</details> 
  
<details>
<summary>Version 1.0.0</summary>
  - Overall improvement of the script
  - Addition of the creation of a password for the Debian proot user
  - Implementation of a non-verbose execution when gum is not used
  - Implementation of a system for displaying the result of the execution of commands (success/failure)
  - :checkered_flag: The rest is in development
</details>

&nbsp;

## 📖 To Do
- [ ] Integration of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)
- [ ] Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)
- [ ] Integrate Fish configuration (Plugins, Prompts, Alias)
- [ ] Add more selectable packages and Python modules
- [ ] Integrate in main script theme selection (Color schemes)
- [ ] Separate XFCE / Debian install to run native Termux XFCE
- [ ] Add options for Debian (Themes, Fonts, Wallpapers)
- [ ] Added an argument to not delete the main script in order to run it again
- [ ] Create a $PREFIX/bin function for executing the preserved main script

&nbsp;

> [!TIP]
> 🚩 French version is [available](README_fr.md).


**Automated and custom installation of [Termux](https://github.com/termux) : packages, shell, plugins, prompts, fonts and themes selectable.**

<details>

<summary>List of optional installations</summary>

- **[OhMyTermuxXFCE](https://github.com/GiGiDKR/OhMyTermux/edit/main/README.md#-xfce-and-debian-)** : A customized [Debian](https://www.debian.org/) proot-distro with a [XFCE](https://www.xfce.org/) desktop and an **[App-Installer](https://github.com/GiGiDKR/App-Installer)** which are not available in package manager.

- **[OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)** : A collection of useful scripts, executable from the main script or later. [^1]

- **[OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)** : Sync Obsidian on Android using Termux and Git. [^1]

</details>


>[!NOTE]
> It is possible to select functions independently (and combine them) :
> - Shell installation : `--shell | sh`
> - Packages installation : `--package | pkg`
> - Fonts installation : `--font | f`
> - XFCE / Debian-Proot : `--xfce | -x`
> - Skip initial configuration : `--skip` or `-sk`
> - :fuelpump: Full installation : `--full | -f`
> - Show detailed outputs : `--verbose | -v`
> - Help section : `--help | -h`
&nbsp;
