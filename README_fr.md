![Logo OhMyTermux](assets/logo.jpg)

> [!CAUTION]
> :warning: Ce projet est en cours de développement, utilisez-le à vos propres risques.
> 
> :construction: État actuel du projet : **beta v1** <sup>(en développement)</sup>
> 
> :information_source: *Je ne suis qu'un programmeur amateur avec quelques compétences en administration système, donc j'apprends de mes erreurs que vous verrez* 👀


# OhMyTermux 🧊

**Installation automatisée et personnalisée de [Termux](https://github.com/termux) : paquets, shell, plugins, prompts, polices et thèmes sélectionnables.**

<details>

<summary>Liste des installations optionnelles</summary>

- **[OhMyTermuxXFCE](https://github.com/GiGiDKR/OhMyTermux/edit/main/README.md#-xfce-et-debian-)** : Un [Debian](https://www.debian.org/) proot-distro personnalisé avec un bureau [XFCE](https://www.xfce.org/) et un **[App-Installer](https://github.com/GiGiDKR/App-Installer)** qui ne sont pas disponibles dans le gestionnaire de paquets.

- **[OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)** : Une collection de scripts utiles, exécutables depuis le script principal ou ultérieurement. [^1]

- **[OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)** : Synchronisez Obsidian sur Android en utilisant Termux et Git. [^1]

</details>

## Installation

🧊 Pour installer **OhMyTermux**
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install_fr.sh -o install_fr.sh && chmod +x install_fr.sh && ./install_fr.sh
```

>[!IMPORTANT]
> **[Gum](https://github.com/charmbracelet/gum) permet une utilisation simplifiée des scripts CLI, _il est recommandé_ de l'utiliser en ajoutant l'argument `--gum` ou `-g`.**

🔥 Pour installer **OhMyTermux** avec **[Gum](https://github.com/charmbracelet/gum)**
```bash
curl -sL https://raw.githubusercontent.com/GiGiDKR/OhMyTermux/1.0.0/install_fr.sh -o install_fr.sh && chmod +x install_fr.sh && ./install_fr.sh --gum
```

>[!NOTE]
> Il est possible de sélectionner les fonctions indépendamment (et de les combiner) :
> - Installation du shell : `--shell | sh`
> - Installation des paquets : `--package | pkg`
> - Installation des polices : `--font | f`
> - XFCE / Debian-Proot : `--xfce | -x`
> - Ignorer la configuration initiale : `--skip` ou `-sk`
> - :fuelpump: Installation complète : `--full | -f`
> - Afficher les sorties détaillées : `--verbose | -v`
> - Section d'aide : `--help | -h`
&nbsp;

### À propos de ce programme 

<details>

<summary>🧊 Paquets installés par défaut</summary>

- [wget](https://github.com/mirror/wget)
- [curl](https://github.com/curl/curl)
- [git](https://github.com/git/git)
- [unzip](https://en.m.wikipedia.org/wiki/ZIP_(file_format))

</details>

<details>

<summary>🧊 Paquets sélectionnables individuellement</summary>

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

<summary>🧊 Sélection du shell</summary>

- [Bash](https://git.savannah.gnu.org/cgit/bash.git/)
- [ZSH](https://www.zsh.org/)
- [Fish](https://github.com/fish-shell/fish-shell)

</details>

<details>

<summary>🧊🧊 Configuration Zsh</summary>

- [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
- [zsh-alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

</details>

<details>

<summary>🧊🧊 Configuration Fish</summary>

- [Oh-My-Fish](https://github.com/oh-my-fish/oh-my-fish)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [Pure](https://github.com/pure-fish/pure)
- [Fishline](https://github.com/0rax/fishline)
- [Virtualfish](https://github.com/justinmayer/virtualfish)
- [Fish Abbreviation Tips](https://github.com/gazorby/fish-abbreviation-tips)
- [Bang-Bang](https://github.com/oh-my-fish/plugin-bang-bang)
- [Fish You Should Use](https://github.com/paysonwallach/fish-you-should-use)
- [Catppuccin pour Fish](https://github.com/catppuccin/fish)

</details>

<details>

<summary>🧊 Affichage Termux</summary>

- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
- [Schémas de couleurs](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

</details>

<details>

<summary>🧊 Configuration Termux</summary>

- Alias personnalisés (alias communs + alias spécifiques selon le paquet ou le plugin installé)
- Lien symbolique vers les répertoires utilisateur du stockage interne

</details>

<details>

<summary>🧊 OhMyTermuxScript</summary>

- Sélecteur de thème
- Installateur de Nerd Fonts
- App-Installer (VSCode, PyCharm, Obsidian...)
- Bureau XFCE4 natif Termux sur Termux-X11
- Oh-My-Zsh [^2]
- Oh-My-Posh [^1]
- Electron Node.js
- XDRP (Termux natif ou proot-distro)

</details>

[^1]: En développement : à venir dans la version 1.0
[^2]: Intégré en option dans le script principal
[^3]: En développement (pas de date de sortie prévue)

&nbsp;

## **XFCE et Debian**

Configurez un bureau XFCE termux et une installation Debian proot.
Cette configuration utilise Termux-X11, le serveur termux-x11 sera installé et il vous sera demandé d'autoriser termux à installer l'APK Android.
Vous n'avez qu'à choisir votre nom d'utilisateur et suivre les instructions.

> [!IMPORTANT]
> Cela prendra environ 4 Go d'espace de stockage

<details>

<summary>🧊 Démarrer le bureau</summary>

Vous recevrez une fenêtre contextuelle pour autoriser les installations depuis termux, cela ouvrira l'APK pour l'application Android Termux-X11. Bien que vous n'ayez pas à autoriser les installations depuis termux, vous devrez quand même installer manuellement en utilisant un explorateur de fichiers et en trouvant l'APK dans votre dossier de téléchargements.

Utilisez la commande ```start``` pour lancer une session Termux-X11.

Cela démarrera le serveur termux-x11, le bureau XFCE4 et ouvrira l'application Termux-X11 directement dans le bureau.

Pour entrer dans l'installation Debian proot depuis le terminal, utilisez la commande ```debian```

Notez également que vous n'avez pas besoin de définir l'affichage dans Debian proot car il est déjà configuré. Cela signifie que vous pouvez utiliser le terminal pour démarrer n'importe quelle application GUI et elle démarrera.

</details>

<details>

<summary>🧊 Debian Proot</summary>

Pour entrer dans proot, utilisez la commande ```debian```, à partir de là, vous pouvez installer des logiciels supplémentaires avec apt et utiliser cp2menu dans termux pour copier les éléments du menu vers le menu xfce de termux.

Il existe deux scripts disponibles pour cette configuration :

```prun``` En exécutant ceci suivi d'une commande que vous souhaitez exécuter depuis l'installation debian proot, vous pourrez exécuter des choses depuis le terminal termux sans avoir à exécuter ```debian``` pour entrer dans le proot lui-même.

```cp2menu``` En exécutant ceci, une fenêtre apparaîtra vous permettant de copier les fichiers .desktop du proot debian dans le menu "démarrer" de termux xfce afin que vous n'ayez pas besoin de les lancer depuis le terminal. Un lanceur est disponible dans la section menu Système.

</details>

&nbsp;

> [!WARNING]
> **Processus terminé (signal 9) - appuyez sur Entrée**

<details>

<summary>Comment corriger cette erreur Termux</summary>

Vous devez exécuter cette commande adb pour corriger l'erreur du processus 9 qui forcera la fermeture de Termux :
```
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```
Pour faire cela sans utiliser un PC, vous avez plusieurs méthodes :
D'abord, connectez-vous au WIFI.

**Méthode 1 :**
Installez adb dans Termux en exécutant ce code :
```
pkg install android-tools -y
```
Ensuite, ouvrez les paramètres et activez les options développeur en sélectionnant "À propos du téléphone" puis appuyez sur "Build" 7 fois.

Revenez en arrière et allez dans les options développeur, activez le débogage sans fil puis cliquez dessus pour obtenir le numéro de port puis cliquez sur appairer l'appareil pour obtenir le code d'appairage.

Mettez les paramètres en mode écran partagé en appuyant sur le bouton carré en bas à droite de votre téléphone, et maintenez l'icône des paramètres jusqu'à ce que l'icône d'écran partagé apparaisse.

Puis sélectionnez Termux et dans les paramètres sélectionnez appairer avec un code. Dans Termux tapez `adb pair` puis entrez vos informations d'appairage.

Après avoir terminé ce processus, vous pouvez taper adb connect et vous connecter à votre téléphone avec l'ip et le port fournis dans le menu de débogage sans fil. Vous pouvez ensuite exécuter la commande de correction :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

**Méthode 2 :**

Installez LADB depuis le [Playstore](https://play.google.com/store/apps/details?id=com.draco.ladb) ou depuis [GitHub](https://github.com/hyperio546/ladb-builds/releases).

En écran partagé, ayez d'un côté LADB et de l'autre les paramètres développeur.
Dans les paramètres développeur, activez le débogage sans fil puis cliquez dessus pour obtenir le numéro de port puis cliquez sur appairer l'appareil pour obtenir le code d'appairage.
Entrez ces deux valeurs dans LADB.
Une fois connecté, exécutez la commande de correction :

```adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"```

</details>

&nbsp;

## 💻 Historique des versions

<details>
<summary>Version 0.0.1</summary>
Upload initial
</details>

<details>
<summary>Version 0.0.2</summary>
Modifications de l'interface en ligne de commande
</details>

<details>
<summary>Version 0.0.3</summary>
~~Intégration de [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)~~ (Retour en arrière)
</details>

<details>
<summary>Version 0.0.4</summary>
Optimisation du système d'alias selon la sélection des paquets et du shell
</details>

<details>
<summary>Version 0.0.5</summary>
Ajout de paquets à la liste sélectionnable
</details>

<details>
<summary>Version 0.0.6</summary>
Gestion dynamique de la configuration .zshrc
</details>

<details>
<summary>Version 0.0.7</summary>
Modification globale du script principal en divisant chaque étape en une fonction pouvant être exécutée seule (ou combinée avec d'autres) avec l'ajout d'un argument à la commande d'exécution
</details>

<details>
<summary>Version 0.0.8</summary>

- Ajout de l'argument `--shell` pour installer un shell
- Ajout de l'argument `--package` pour installer des paquets
- Ajout de l'argument `--xfce` pour installer XFCE et Debian proot
- Ajout de l'argument `--font` pour installer des polices
- ~~Ajout de l'argument `--script` pour installer [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript) [^1]~~ (Retour en arrière)
- Ajout de l'argument `--skip` pour ignorer la configuration initiale
</details>

<details>
<summary>Version 0.0.9</summary>
Corrections de bugs et améliorations
</details>

<details>
<summary>Version 1.0.0</summary>
- Amélioration globale du script
- Ajout de la création d'un mot de passe pour l'utilisateur Debian proot
- Implémentation d'une exécution non verbeuse lorsque gum n'est pas utilisé
- Implémentation d'un système d'affichage du résultat de l'exécution des commandes (succès/échec)
- :checkered_flag: Le reste est en développement
</details>

&nbsp;

## 📖 À faire
- [ ] Intégration de [OhMyTermuxScript](https://github.com/GiGiDKR/OhMyTermuxScript)
- [ ] Intégration de [OhMyObsidian](https://github.com/GiGiDKR/OhMyObsidian)
- [ ] Intégrer la configuration Fish (Plugins, Prompts, Alias)
- [ ] Ajouter plus de paquets et modules Python sélectionnables
- [ ] Intégrer dans le script principal la sélection de thème (Schémas de couleurs)
- [ ] Séparer l'installation XFCE / Debian pour exécuter XFCE natif Termux
- [ ] Ajouter des options pour Debian (Thèmes, Polices, Fonds d'écran)
- [ ] Ajout d'un argument pou ne pas supprimer le script principal afin de pouvoir le réexécuter
- [ ] Créer une fonction $PREFIX/bin pour exécuter le script principal préservé

&nbsp;

> [!TIP]
> 🚩 La version anglaise est [disponible](README.md).
