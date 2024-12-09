# OhMyTermux 🧊

![Banner](assets/ohmytermux_5.jpg)

### **De la sélection d'un shell à l'application d'un pack de curseurs afin de cliquer avec style dans les menus d'un environnement de développement Debian complet tenant dans votre poche : des dizaines de paramètres sont disponibles dans [OhMyTermux](https://github.com/GiGiDKR/OhMyTermux).**

![Version](https://img.shields.io/badge/version-1.0.0-magenta) ![GitHub last commit](https://img.shields.io/github/last-commit/GiGiDKR/OhMyTermux?style=flat&color=green&link=https%3A%2F%2Fgithub.com%2FGiGiDKR%2FOhMyTermux) ![GitHub repo file or directory count](https://img.shields.io/github/directory-file-count/GiGiDKR/OhMyTermux)  ![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/GiGiDKR/OhMyTermux) ![GitHub repo size](https://img.shields.io/github/repo-size/GiGiDKR/OhMyTermux)
![GitHub Repo stars](https://img.shields.io/github/stars/GiGiDKR/OhMyTermux?style=flat&color=gold) ![GitHub forks](https://img.shields.io/github/forks/GiGIDKR/OhMyTermux?style=flat&color=gold)

## Installation

1. Installez Termux depuis [F-Droid](https://f-droid.org/en/packages/com.termux) ou [GitHub](https://github.com/termux/termux-app). Sinon, utilisez la version [Play Store](https://play.google.com/store/apps/details?id=com.termux&pcampaignid=web_share) qui a été récemment mise à jour.

2. Installez **OhMyTermux** avec **[Gum](https://github.com/charmbracelet/gum)** 🔥 :
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install_fr.sh -o install_fr.sh && chmod +x install_fr.sh && ./install_fr.sh --gum
```

>[!IMPORTANT]
> [Gum](https://github.com/charmbracelet/gum) permet une utilisation simplifiée des scripts CLI, **_il est recommandé_** de l'utiliser en ajoutant l'argument `--gum` ou `-g`.

2. [ALT] Installer OhMyTermux sans Gum 🧊 :
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install_fr.sh -o install_fr.sh && chmod +x install_fr.sh && ./install_fr.sh
```

>[!NOTE]
> Il est possible d'exécuter des fonctions indépendamment (et de les combiner) :
>
> ```
> --shell | -sh             # Sélection du shell
> --package | -pk           # Installation des paquets
> --xfce | -x               # Installation de XFCE
> --proot | -pr             # Installation de Debian PRoot
> --font | f                # Sélection de police
> --x11 | -x                # Installation de Termux-X11
> --skip | -sk              # Ignorer la configuration initiale
> --verbose | -v            # Sorties détaillées
> --help | -h               # Afficher l'aide
> ```

## À propos de ce programme

 ![SubBanner1](assets/ohmytermux_1.jpg)

### Termux

<details>

<summary>Packages installés par défaut</summary>

- [wget](https://github.com/mirror/wget)
- [curl](https://github.com/curl/curl)
- [git](https://github.com/git/git)
- [unzip](https://en.m.wikipedia.org/wiki/ZIP_(file_format))

</details>

<details>

<summary>Packages sélectionnables individuellement</summary>

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

<summary>Sélection du shell</summary>

- [Bash](https://git.savannah.gnu.org/cgit/bash.git/)
- [ZSH](https://www.zsh.org/)
- [Fish](https://github.com/fish-shell/fish-shell)

</details>

<details>

<summary>Configuration Zsh</summary>

- [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
- [zsh-alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

</details>

<details>

<summary>Configuration de Fish</summary>

- [Oh-My-Fish](https://github.com/oh-my-fish/oh-my-fish)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [Pure](https://github.com/pure-fish/pure)
- [Fishline](https://github.com/0rax/fishline)
- [Virtualfish](https://github.com/justinmayer/virtualfish)
- [Conseils sur les abréviations de poisson](https://github.com/gazorby/fish-abbreviation-tips)
- [Bang-Bang](https://github.com/oh-my-fish/plugin-bang-bang)
- [Poisson que vous devriez utiliser](https://github.com/paysonwallach/fish-you-should-use)
- [Catppuccin pour poisson](https://github.com/catppuccin/fish)

</details>

<details>

<summary>Affichage Termux</summary>

- [Polices Nerd](https://github.com/ryanoasis/nerd-fonts)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

</details>

<details>

<summary>Configuration de Termux</summary>

- Alias ​​personnalisés (alias communs + alias spécifiques en fonction du package ou du plugin installé)

</details>

### **XFCE**

- Configurer un bureau Termux [XFCE](https://wiki.termux.com/wiki/Graphical_Environment#XFCE) natif.

- L'utilisation de [Termux-X11](https://github.com/termux/termux-x11) plutôt que VNC a été retenue. Le serveur Termux-x11 sera installé ainsi que l'APK Android. Une fenêtre contextuelle vous demandant d'autoriser les installations à partir de Termux sera affichée. Si vous ne le souhaitez pas, installez l'APK depuis votre répertoire de téléchargement.

- 3 configurations sont disponibles :
<details>

<summary>Minimale</summary>

Uniquement les paquets nécessaires :
```
termux-x11-nightly       # Termux-X11
virglrenderer-android    # VirGL
xfce4                    # XFCE
xfce4-terminal           # Terminal
```
</details>

<details>

<summary>Recommandée</summary>

Installation minimale + les paquets suivants :
```
netcat-openbsd            # Utilitaire réseau
pavucontrol-qt            # Contrôle du son
thunar-archive-plugin     # Archives
wmctrl # Contrôle des fenêtres
xfce4-notifyd             # Notifications
xfce4-screenshooter       # Capture d'écran
xfce4-taskmanagerb        # Gestionnaire des tâches
xfce4-whiskermenu-plugin  # Menu Whisker
```
Et les éléments d'interface suivants :
```
WhiteSur-Theme           # https://github.com/vinceliuice/WhiteSur-gtk-theme
WhiteSur-Icon            # https://github.com/vinceliuice/WhiteSur-icon-theme
Fluent-Cursors           # https://github.com/vinceliuice/Fluent-cursors
WhiteSur-Wallpapers      # https://github.com/vinceliuice/WhiteSur-wallpapers
```
</details>

<details>

<summary>Personnalisée</summary>

Le contenu de l'installation minimale + le choix parmi :
```
jq                       # Utilitaire JSON
gigolo                   # Gestionnaire de fichiers
mousepad                 # Éditeur de texte
netcat-openbsd           # Utilitaire réseau
parole                   # Lecteur multimédia
pavucontrol-qt           # Contrôle du son
ristretto                # Gestionnaire d'images
thunar-archive-plugin    # Archives
thunar-media-tags-plugin # Média
wmctrl                   # Contrôle de fenêtre
xfce4-artwork            # Illustration
xfce4-battery-plugin     # Batterie
xfce4-clipman-plugin     # Presse-papiers
xfce4-cpugraph-plugin    # Graphique CPU
xfce4-datetime-plugin    # Date et heure
xfce4-dict               # Dictionnaire
xfce4-diskperf-plugin    # Performances du disque
xfce4-fsguard-plugin     # Surveillance du disque
xfce4-genmon-plugin      # Widgets génériques
xfce4-mailwatch-plugin   # Surveillance du courrier électronique
xfce4-netload-plugin     # Chargement réseau
xfce4-notes-plugin       # Notes
xfce4-notifyd            # Notifications
xfce4-places-plugin      # Lieux
xfce4-screenshooter      # Capture d'écran
xfce4-taskmanager        # Gestionnaire des tâches
xfce4-systemload-plugin  # Chargement du système
xfce4-timer-plugin       # Minuterie
xfce4-wavelan-plugin     # Wi-Fi
xfce4-weather-plugin     # Informations météo
xfce4-whiskermenu-plugin # Menu Whisker
```
Le choix parmi les éléments d'interface suivants :

Thème :
```
WhiteSur-Theme           # https://github.com/vinceliuice/WhiteSur-gtk-theme
Fluent-Theme             # https://github.com/vinceliuice/Fluent-gtk-theme
Lavanda-Theme            # https://github.com/vinceliuice/Lavanda-gtk-theme
```
Icônes :
```
WhiteSur-Icon            # https://github.com/vinceliuice/WhiteSur-icon-theme
McMojave-Circle          # https://github.com/vinceliuice/McMojave-circle-icon-theme
Tela-Icon                # https://github.com/vinceliuice/Tela-icon-theme
Fluent-Icon              # https://github.com/vinceliuice/Fluent-icon-theme
Qogir-Icon               # https://github.com/vinceliuice/Qogir-icon-theme
```
Curseurs :
```
Fluent-Cursors           # https://github.com/vinceliuice/Fluent-cursors
```
Fonds d'écran :
```
WhiteSur-Wallpapers      # https://github.com/vinceliuice/WhiteSur-wallpapers
```
</details>

- La possibilité d'installer un navigateur Web, soit [Chromium](https://www.chromium.org/) ou Firefox.

> [!IMPORTANT]
> L'installation recommandée utilise environ **4 Go** d'espace disque

### Debian
[Debian PRoot](https://wiki.termux.com/wiki/PRoot) avec un [installateur d'application](https://github.com/GiGiDKR/App-Installer) qui ne sont pas disponibles avec Termux ou les gestionnaires de paquets Debian.

## Utilisation

🧊 Démarrage du bureau

- Pour démarrer une session Termux-X11, utilisez ```start```

- Pour accéder à l'installation de Debian PRoot depuis le terminal, utilisez ```debian```

🧊 Debain Proot

- Il existe deux scripts disponibles pour cette configuration :

- ```prun```  L'exécution de ceci suivie d'une commande que vous souhaitez exécuter depuis l'installation de Debian proot vous permettra d'exécuter des éléments depuis le terminal termux sans exécuter ```debian``` pour accéder au proot lui-même.

- ```cp2menu``` L'exécution de ceci fera apparaître une fenêtre vous permettant de copier les fichiers .desktop depuis debian proot dans le menu « démarrer » de termux xfce afin que vous n'ayez pas besoin de les lancer depuis le terminal. Un lanceur est disponible dans la section du menu Système.

</details>

## Screenshots

![Termux List](assets/termux_ls.png)
![Debian PRoot](assets/debian_proot.png)

&nbsp;

> [!WARNING]
> **Processus terminé (signal 9) - appuyez sur Entrée**

<details>

<summary>Comment corriger cette erreur Termux</summary>

Vous devez exécuter cette commande adb pour corriger l'erreur du processus 9 qui forcera la fermeture de Termux :
```
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```
Pour faire cela sans utiliser de PC, vous avez plusieurs méthodes :
Tout d'abord, connectez-vous au WIFI.

**Méthode 1 :**
Installez adb dans Termux en exécutant ce code :
```
pkg install android-tools -y
```
Ouvrez ensuite les paramètres et activez les options du développeur en sélectionnant « À propos du téléphone », puis appuyez 7 fois sur « Créer ».

Revenez à ce menu et accédez aux options du développeur, activez le débogage sans fil, puis cliquez dessus pour obtenir le numéro de port, puis cliquez sur « Appairer l'appareil » pour obtenir le code d'appairage.

Mettez les paramètres en mode écran partagé en appuyant sur le bouton carré en bas à droite de votre téléphone et maintenez l'icône des paramètres enfoncée jusqu'à ce que l'icône d'écran partagé apparaisse.

Sélectionnez ensuite Termux et dans les paramètres, sélectionnez « Appairer avec un code ». Dans Termux, saisissez « adb pair » puis saisissez vos informations d'appairage.

Une fois ce processus terminé, vous pouvez saisir adb connect et vous connecter à votre téléphone avec l'adresse IP et le port fournis dans le menu de débogage sans fil. Vous pouvez ensuite exécuter la commande fix :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

**Méthode 2 :**

Installez LADB depuis [Playstore](https://play.google.com/store/apps/details?id=com.draco.ladb) ou depuis [GitHub](https://github.com/hyperio546/ladb-builds/releases).

En écran partagé, ayez un côté LADB et l'autre côté affichant les paramètres du développeur.
Dans les paramètres du développeur, activez le débogage sans fil, puis cliquez dessus pour obtenir le numéro de port, puis cliquez sur associer l'appareil pour obtenir le code d'association.
Entrez ces deux valeurs dans LADB.
Une fois connecté, exécutez la commande fix :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

</details>

&nbsp;

![SubBanner2](assets/ohmytermux_6.jpg)

## 💻 Historique des versions

Version 1.0.0 :
- Version initiale

&nbsp;

## 📖 À faire
- [X] Installation séparée de XFCE / Debian pour exécuter le XFCE natif de Termux
- [X] Ajouter des éléments d'interface graphique sélectionnables (Thèmes, Polices, Curseurs, Fonds d'écran)
- [X] Ajouter un mot de passe pour l'utilisateur proot Debian
- [ ] Intégrer la configuration de Fish (Plugins, Prompts, Alias)
- [ ] Ajouter plus de paquets sélectionnables
- [ ] Ajouter des modules Python
- [ ] Intégrer une sélection de thèmes Termux
- [ ] Intégration de [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)
- [ ] Intégration de [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)

&nbsp;

> [!TIP]
> 🚩 La version anglaise est [disponible](README.md).

## A short overview :

https://github.com/user-attachments/assets/ec49fc8d-bc69-4b95-ade4-5ca2ae57a105

![SubBanner3](assets/ohmytermux_2.jpg)

