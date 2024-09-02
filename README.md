# OhMyTermux 🧊

**Automated and custom installation of [Termux](https://github.com/termux) : packages, shell, plugins, prompts, fonts and themes selectable.**

**[OhMyTermuxXFCE](https://github.com/GiGiDKR/OhMyTermux/edit/main/README.md#-xfce-and-debian-) : A customized [Debian](https://www.debian.org/) proot-distro and [XFCE](https://www.xfce.org/) desktop .**

**[OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) : A collection of useful scripts, executable from the main script or later. [^1]**

> [!TIP]
> To choose between different items it is recommended to use [gum](https://github.com/charmbracelet/gum) which provides a simplified selection (Space for multiple selections and Enter to validate).

&nbsp;


## Installation

🧊 To install with [gum](https://github.com/charmbracelet/gum)

```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh --gum
```

Or install without
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

&nbsp;

## About this program 

🧊 **Packages installed :**

- [wget](https://github.com/mirror/wget)
- [curl](https://github.com/curl/curl)
- [git](https://github.com/git/git)
- [zsh](https://github.com/zsh-users/zsh)
- [unzip](https://en.m.wikipedia.org/wiki/ZIP_(file_format))

🧊 **Individually selectable packages :**

- [nala](https://github.com/volitank/nala)
- [eza](https://github.com/eza-community/eza)
- [lsd](https://github.com/lsd-rs/lsd)
- [bat](https://github.com/sharkdp/bat)
- [lf](https://github.com/gokcehan/lf)
- [fzf](https://github.com/junegunn/fzf)
- [glow](https://github.com/charmbracelet/glow)
- [python](https://github.com/python)
- [micro](https://github.com/zyedidia/micro)


🧊 **Shell selection :**

- [Bash](https://git.savannah.gnu.org/cgit/bash.git/)
- [ZSH](https://www.zsh.org/)
- [Fish](https://github.com/fish-shell/fish-shell)


  🧊 **Configuration ZSH :**

    - [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
    - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
    - [zsh-completions](https://github.com/zsh-users/zsh-completions)
    - [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
    - [zsh-abbr](https://github.com/olets/zsh-abbr)
    - [zsh-alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

  🧊 **Configuration Fish [^1] :**
  
   - [Oh-My-Fish](https://github.com/oh-my-fish/oh-my-fish)
   - [Fisher](https://github.com/jorgebucaran/fisher)
   - [Pure](https://github.com/pure-fish/pure)
   - [Fishline](https://github.com/0rax/fishline)
   - [Virtualfish](https://github.com/justinmayer/virtualfish)
   - [Fish Abbreviation Tips](https://github.com/gazorby/fish-abbreviation-tips)
   - [Bang-Bang](https://github.com/oh-my-fish/plugin-bang-bang)
   - [Fish You Should Use](https://github.com/paysonwallach/fish-you-should-use)
   - [Catppuccin for Fish](https://github.com/catppuccin/fish)

🧊 **Configuring Termux Display :**

- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) 
- [Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

🧊 **Helpful Termux configuration :**

- Custom aliases
- Symlink to internal storage user directories [^1]


🧊 **Useful scripts [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)** [^1] :

- Theme Selector
- Nerd Fonts Installer
- App-Installer (VSCode, PyCharm, Obsidian...) [^2]
- Native Termux XFCE4 desktop on Termux-X11 [^3]
- Oh-My-Zsh [^2]
- Oh-My-Posh [^1]
- Electron Node.js
- XDRP (native Termux or proot-distro)

[^1]: Coming in version 1.1 with the full integration of OhMyTermuxScript 
[^2]: Optionally integrated into the main script
[^3]: In development (no release date yet)

# 🔥 **XFCE and Debian :**

Sets up a termux XFCE desktop and a Debian proot install.
This setup uses Termux-X11, the termux-x11 server will be installed and you will be prompted to allow termux to install the Android APK.
You only need to pick your username and follow the prompts.

> [!IMPORTANT]
> This will take roughly 4GB of storage space

&nbsp;

## Starting the desktop

You will recieve a popup to allow installs from termux, this will open the APK for the Termux-X11 android app. While you do not have to allow installs from termux, you will still need to install manually by using a file browser and finding the APK in your downloads folder.

Use the command ```start``` to initiate a Termux-X11 session.

This will start the termux-x11 server, XFCE4 desktop and open the Termux-X11 app right into the desktop.

To enter the Debian proot install from terminal use the command ```debian```

Also note, you do not need to set display in Debian proot as it is already set. This means you can use the terminal to start any GUI application and it will startup.

&nbsp;

## Debain Proot

To enter proot use the command ```debian```, from there you can install aditional software with apt and use cp2menu in termux to copy the menu items over to termux xfce menu.

There are two scripts available for this setup as well :

```prun```  Running this followed by a command you want to run from the debian proot install will allow you to run stuff from the termux terminal without running ```debian``` to get into the proot itself.

```cp2menu``` Running this will pop up a window allowing you to copy .desktop files from debian proot into the termux xfce "start" menu so you won't need to launch them from terminal. A launcher is available in the System menu section.

&nbsp;

> [!CAUTION]
> Process completed (signal 9) - press Enter
>
> Install LADB from [Playstore](https://play.google.com/store/apps/details?id=com.draco.ladb) or from [GitHub](https://github.com/hyperio546/ladb-builds/releases).
> 
> Connect to WIFI.  
>
> In split screen have one side LADB and the other side showing developer settings.
>
> In developer settings, enable wireless debugging then click into there to get the port number then click pair device to get the pairing code.
>
> Enter both those values into LADB.
>
> Once it connects run this command :
> 
> ```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

&nbsp;

## 💻 Update log

- Version 1.0.0 :
    - Initial upload
- Version 1.0.1 :
    - Command line interface changes
    - Integration partial of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) [^1]
- Version 1.0.2 :
    - Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)
- Version 1.1 : 
  - In development

&nbsp;

## 📖 To Do
- [X] Integration of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) (Partial)
- [ ] Integration of [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) (Full)
- [ ] Integration of [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)
- [ ] Integrate Fish configuration (Plugins, Prompts, Alias)
- [ ] Add more selectable packages and Python modules
- [ ] Integrate in main script theme selection (Color schemes)
- [ ] Separate XFCE / Debian install to run native Termux XFCE
- [ ] Add options for Debian (Themes, Fonts, Wallpapers)

&nbsp;