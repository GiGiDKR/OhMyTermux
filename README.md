# OhMyTermux 🧊

**Automated and custom installation of [Termux](https://github.com/termux) : packages, shell, plugins, prompts, fonts and themes selectable.** 👀

Optional installation of:

- **[OhMyTermuxXFCE](https://github.com/GiGiDKR/OhMyTermux/edit/main/README.md#-xfce-and-debian-)** : A customized [Debian](https://www.debian.org/) proot-distro with a [XFCE](https://www.xfce.org/) desktop and an **[App-Installer](https://github.com/GiGiDKR/App-Installer)** which are not available in package manager.

- **[OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)** : A collection of useful scripts, executable from the main script or later. [^1]

- **[OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)** : Sync Obsidian on Android using Termux and Git. [^1]

&nbsp;

> [!CAUTION]
> ⚠️ This project is under development, use it at your own risk.
>
> The various branches of the repository are currently not up to date.
>
> Please wait for version 1.1 before using this project or check the code before running it !

> [!IMPORTANT]
> 🚩 To facilitate progress, the French language is preferred to provide the user CLI.
>
> A French version of this text is [available](README-FR.md).

&nbsp;

## Installation

🧊 To install **OhMyTermux**
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

>[!TIP]
> **[Gum](https://github.com/charmbracelet/gum)** allows simplified use of CLI scripts, it is recommended to use it by adding the `--gum` or `-g` argument.

🔥 To install **OhMyTermux** with **[Gum](https://github.com/charmbracelet/gum)**
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.9/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
```

>[!NOTE]
> It is possible to execute only one function of the script by use the corresponding argument :
> - Shell installation : `--shell` or `-sh`
> - Packages installation : `--package` or `-pkg`
> - Fonts installation : `--font` or `-f`
> - XFCE / Debian-Proot : `--xfce` or `-x`
> - OhMyTermuxScript : `--script` or `-sc`
> - Skip initial configuration : `--skip` or `-sk`
>
> **Multiple arguments can be combined.**

&nbsp;

### About this program 

#### 🧊 **Packages installed by default**

- [wget](https://github.com/mirror/wget)
- [curl](https://github.com/curl/curl)
- [git](https://github.com/git/git)
- [zsh](https://github.com/zsh-users/zsh)
- [unzip](https://en.m.wikipedia.org/wiki/ZIP_(file_format))

#### 🧊 **Individually selectable packages**

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


#### 🧊 **Shell selection**

- [Bash](https://git.savannah.gnu.org/cgit/bash.git/)
- [ZSH](https://www.zsh.org/)
- [Fish](https://github.com/fish-shell/fish-shell)


  ##### 🧊 **ZSH configuration**

    - [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
    - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
    - [zsh-completions](https://github.com/zsh-users/zsh-completions)
    - [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
    - [zsh-abbr](https://github.com/olets/zsh-abbr)
    - [zsh-alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

  ##### 🧊 **Fish configuration [^1]**
  
   - ~~[Oh-My-Fish](https://github.com/oh-my-fish/oh-my-fish)~~
   - ~~[Fisher](https://github.com/jorgebucaran/fisher)~~
   - ~~[Pure](https://github.com/pure-fish/pure)~~
   - ~~[Fishline](https://github.com/0rax/fishline)~~
   - ~~[Virtualfish](https://github.com/justinmayer/virtualfish)~~
   - ~~[Fish Abbreviation Tips](https://github.com/gazorby/fish-abbreviation-tips)~~
   - ~~[Bang-Bang](https://github.com/oh-my-fish/plugin-bang-bang)~~
   - ~~[Fish You Should Use](https://github.com/paysonwallach/fish-you-should-use)~~
   - ~~[Catppuccin for Fish](https://github.com/catppuccin/fish)~~

  #### 🧊 **Termux Display**

- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) 
- [Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

  #### 🧊 **Termux configuration**

- Custom aliases
- Symlink to internal storage user directories [^1]

  #### 🧊 **[OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)** [^1]

- Theme Selector
- Nerd Fonts Installer
- App-Installer (VSCode, PyCharm, Obsidian...) [^2]
- Native Termux XFCE4 desktop on Termux-X11 [^3]
- Oh-My-Zsh [^2]
- Oh-My-Posh [^1]
- Electron Node.js
- XDRP (native Termux or proot-distro)

[^1]: In development :coming in version 1.1
[^2]: Optionally integrated into the main script
[^3]: In development (no release date yet)

&nbsp;

## **XFCE and Debian**

Sets up a termux XFCE desktop and a Debian proot install.
This setup uses Termux-X11, the termux-x11 server will be installed and you will be prompted to allow termux to install the Android APK.
You only need to pick your username and follow the prompts.

> [!IMPORTANT]
> This will take roughly 4GB of storage space

### 🧊 Starting the desktop

You will recieve a popup to allow installs from termux, this will open the APK for the Termux-X11 android app. While you do not have to allow installs from termux, you will still need to install manually by using a file browser and finding the APK in your downloads folder.

Use the command ```start``` to initiate a Termux-X11 session.

This will start the termux-x11 server, XFCE4 desktop and open the Termux-X11 app right into the desktop.

To enter the Debian proot install from terminal use the command ```debian```

Also note, you do not need to set display in Debian proot as it is already set. This means you can use the terminal to start any GUI application and it will startup.

### 🧊 Debain Proot

To enter proot use the command ```debian```, from there you can install aditional software with apt and use cp2menu in termux to copy the menu items over to termux xfce menu.

There are two scripts available for this setup as well :

```prun```  Running this followed by a command you want to run from the debian proot install will allow you to run stuff from the termux terminal without running ```debian``` to get into the proot itself.

```cp2menu``` Running this will pop up a window allowing you to copy .desktop files from debian proot into the termux xfce "start" menu so you won't need to launch them from terminal. A launcher is available in the System menu section.

&nbsp;


> [!WARNING]
> ***Process completed (signal 9) - press Enter***
>
> You need to run this adb command to fix the process 9 error that will force close Termux :
> ```
> adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
> ```
>
> To do this without using a PC you have several methods :
>
> First, Connect to WIFI.
>
> **Method 1 :**
> 
> Install adb in Termux by running this code:
> ```
> pkg install android-tools -y
> ```
> Then open settings and enable developer's options by selecting "About phone" then hit "Build" 7 times.
> 
> Back out of this menu and go into developer's options, enable wireless debugging then click into there to get the port number then click pair device to get the pairing code.
> 
> Put settings into split screen mode by pressing the square button on the bottom right of your phone, and hold the settings icon until the split screen icon shows up.
> 
> Then select Termux and in settings select pair with a code. In Termux type `adb pair` then enter your pairing info.
> 
> After you have completed this process you can type adb connect and connect to your phone with the ip and port provided in the wireless debugging menu. You can then run the fix command.
> > ```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```
> 
> **Method 2 :**
> 
> Install LADB from [Playstore](https://play.google.com/store/apps/details?id=com.draco.ladb) or from [GitHub](https://github.com/hyperio546/ladb-builds/releases).
> 
> In split screen have one side LADB and the other side showing developer settings.
>
> In developer settings, enable wireless debugging then click into there to get the port number then click pair device to get the pairing code.
>
> Enter both those values into LADB.
>
> Once it connects run the fix command.
> > ```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

&nbsp;

## 💻 Version history

- Version 1.0.0 :
    - Initial upload
- Version 1.0.1 :
    - Command line interface changes
    - Installation of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) [^1]
- Version 1.0.2 :
    ~~- Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)~~ (Rollback)
- Version 1.0.3 :
    - Optimization of the alias system according to package and shell selection
- Version 1.0.4 :
    - Adding packages to the selectable list
- Version 1.0.5 :
    - Dynamic management of .zshrc configuration
- Version 1.0.6 :
    - Global modification of the main script by splitting each step into a function that can be executed alone (or combined with others) with the addition of an argument to the execution command
- Version 1.0.7 :
    - Addition of the argument `--shell` to install a shell
    - Addition of the argument `--package` to install packages
    - Addition of the argument `--xfce` to install XFCE and Debian proot
    - Addition of the argument `--font` to install fonts
    - Addition of the argument `--script` to install [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) [^1]
    - Addition of the argument `--skip` to skip the initial configuration
- Version 1.0.8 :
    - Bug fixes and improvements
- Version 1.0.9 :
    - Overall improvement of the script
    - Addition of the creation of a password for the Debian proot user
    - Implementation of a non-verbose execution when gum is not used
    - Implementation of a system for displaying the result of the execution of commands (success/failure)
- Version 1.1 : 
    - In development

&nbsp;

## 📖 To Do
- [X] Installation of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)
- [ ] Execution of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)
- [ ] Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)
- [ ] Integrate Fish configuration (Plugins, Prompts, Alias)
- [ ] Add more selectable packages and Python modules
- [ ] Integrate in main script theme selection (Color schemes)
- [ ] Separate XFCE / Debian install to run native Termux XFCE
- [ ] Add options for Debian (Themes, Fonts, Wallpapers)
- [ ] Added an argument to not delete the main script in order to run it again
- [ ] Create a $PREFIX/bin function for executing the preserved main script

&nbsp;

