<div align="center">

# 🌿 meloworld

*a rice that feels like /home <3*

</div>

---

![banner](assets/banner.png)

---

![desktop preview](assets/desktop.png)

<details>
<summary>☀️ light mode</summary>
<br>

![desktop light mode preview](assets/desktop-light.png)

</details>

---

meloworld is my personal arch linux desktop built around mangowm and quickshell. ghibli wallpapers, warm colors, everything animated. every popup, widget, and notification is part of the same visual system. same row height, same font, same spacing throughout.

| | |
|---|---|
| **os** | Arch Linux |
| **wm** | [MangoWM](https://github.com/mangowm/mango) |
| **shell layer** | [Quickshell](https://quickshell.org/) |
| **launcher** | Rofi |
| **terminal** | [Ghostty](https://ghostty.org/) |
| **shell** | zsh |
| **editor** | [Zed](https://zed.dev/) |
| **font** | [JetBrainsMono Nerd Font](https://www.nerdfonts.com/) |

---

## 🌸 features

<details>
<summary>🪟 bar & workspaces</summary>
<br>

![bar](assets/bar.png)
![bar light](assets/bar-light.png)

workspace pills slide in when you open something and slide out when you close it. scroll the mouse wheel to switch workspaces. all status pills on the right open their respective popups.

</details>

<details>
<summary>🎄 launcher</summary>
<br>

![launcher](assets/launcher.png)
![launcher grid](assets/launcher-grid.png)
![clipboard](assets/clipboard.png)
![emoji](assets/emoji.png)
![wallpaper selector](assets/wallpaper-selector.png)

a custom launcher written with quickshell with modes. aimed to replace rofi for more flexibility. you can switch between modes with the prefixes. /h for hidden apps, /w for wallpapers, /g for grid-list view switch.

</details>

<details>
<summary>☀️ dashboard</summary>
<br>

![dashboard](assets/dashboard.png)

a left panel with quick toggles, system stats, and notification history. greetings change dynamically based on the time of day.

</details>

<details>
<summary>🪴 popups</summary>
<br>

all animated — slide down from the top when they open, slide back up when they close. all share the same design language.

**🎼 media player**

![media player](assets/media.png)

supports shuffle and repeat on supported apps. uses the material expressive 3 progress bar. switches between players with chevron arrows.

---

**🔊 audio**

![audio popup](assets/audio.png)

device selection for output and input. volume and mic sliders side by side. click the icon to mute — everything dims when muted. single-device setups hide the selector automatically.

---

**🦷 bluetooth**

![bluetooth popup](assets/bluetooth.png)

paired devices, scan button, filtered scan list that hides raw MAC addresses. list caps at five entries and scrolls — tells you when there's more above or below.

---

**🛜 wifi**

![wifi popup](assets/wifi.png)

previously connected networks, autoscan, password entry. same scrolling behavior as bluetooth.

---

**⚡ power profile**

![power popup](assets/power.png)

uses power-profiles-daemon. the border changes color with whatever profile is active.

**📅 calendar**

![calendar](assets/calendar.png)

simple calendar with months view.

</details>

<details>
<summary>🌻 notifications</summary>
<br>

![notifications](assets/notifications.png)

slide in from the right. each app gets its own accent color derived from the app name — same app always gets the same color. critical notifications go red regardless. a small timer ring drains as the notification ages. hover to pause. click to dismiss.

</details>

<details>
<summary>🔑 sddm & lockscreen</summary>
<br>

![sddm theme](assets/sddm.png)

a custom sddm theme built on the same aesthetic so the login screen feels like part of the desktop rather than something bolted on.

</details>

<details>
<summary>🧑🏼‍💻 zed theme</summary>
<br>

![zed theme](assets/zed.png)

matches the same color palette. blurred and non-blurred variants included.

</details>

<details>
<summary>🌙 discord theme</summary>
<br>

![discord theme](assets/discord.png)

the discord theme is based on [midnight](https://github.com/refact0r/midnight-discord). i have only adapted the colors to match the look. 

</details>


<details>
<summary>🐱 idle screen</summary>
<br>

![idle](assets/idle.png)

a sleeping cat appears after a few minutes of inactivity. dims the screen, breathing animation, animated z's. any input dismisses it with a fade.

</details>

---

## 🍁 install

**automatic (arch linux)**

```bash
git clone https://github.com/melatonia/meloworld-dotfiles
cd meloworld-dotfiles
chmod +x install.sh
./install.sh
```

<details>
<summary>manual install</summary>
<br>

```bash
git clone https://github.com/melatonia/meloworld-dotfiles
cd meloworld-dotfiles

cp -r quickshell ~/.config/
cp -r mango ~/.config/
cp -r ghostty ~/.config/
cp -r hypr ~/.config/
cp -r vesktop ~/.config/
cp -r zathura ~/.config/
cp -r zed ~/.config/
cp -r .zshrc ~/.zshrc
find ~/.config/{quickshell,mango,rofi} -type f -name "*.sh" -exec chmod +x {} +
sudo cp -r meloworld-sddm /usr/share/sddm/themes/
```

add to `/etc/sddm.conf.d/theme.conf`:
```
[Theme]
Current=meloworld-sddm
```

apply gtk themes and window preferences:
```bash
gsettings set org.gnome.desktop.wm.preferences button-layout ":"
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

set zsh as your default shell:
```bash
chsh -s $(which zsh)
```

</details>

<details>
<summary>dependencies</summary>
<br>

```bash
paru -S mangowm quickshell pipewire pipewire-pulse wireplumber bluez bluez-utils brightnessctl ghostty power-profiles-daemon ttf-jetbrains-mono-nerd grim slurp awww bibata-cursor-theme-bin papirus-icon-theme zed zsh zsh-autosuggestions zsh-syntax-highlighting adw-gtk-theme xdg-desktop-portal-wlr hypridle hyprlock cliphist wl-clipboard playerctl zoxide bat fd ripgrep lazygit switcheroo-control

sudo systemctl enable --now bluetooth power-profiles-daemon switcheroo-control
```

</details>

<details>
<summary>some usage tips</summary>
<br>


- im open to questions and feature requests, dont hesitate to hit me up on reddit or github (i dont check these places often so if i reply late dont worry)
- for night light to work, you need to set your location in the file (~/.config/mango/scripts/nightlight.sh) (it works depending on the time so you might not notice immediately, just try to turn off and on in night time.)
- you can set your profile picture by just clicking the dashboard area.
- you can switch between launcher modes with the prefixes. /h for hidden apps, /w for wallpapers, /g for grid-list view switch. 
- dashboard and launcher have apps pinning and switcheroo-control support.
- the brightness and audio pills and sliders are scrollable. also you can scroll the workspaces by scrolling on the numbers or super + scroll on anywhere.

</details>

---

## 📦 extras

the sound files (login chime, notification, screenshot, usb connect/remove) were made by me in bitwig studio. use them freely, a credit would be appreciated :3

i use zen browser with the [transparent zen extension](https://sameerasw.com/zen) and `#212121CC` background. for firefox, [Firefox Gnome Theme](https://github.com/rafaelmardojai/firefox-gnome-theme) works well.

---

## 🍀 credits

the popup design language — row style, accent stripes, device selectors — was heavily inspired by [crylia-theme](https://github.com/Crylia/crylia-theme) by [Crylia](https://github.com/Crylia). a beautiful awesomewm rice that made the whole thing feel possible. everything here is reimplemented from scratch in qml, but the soul came from there.

the discord themes are based on [midnight](https://github.com/refact0r/midnight-discord) and [system24](https://github.com/refact0r/system24) by [refact0r](https://www.refact0r.dev), both MIT licensed, with colors adapted to the meloworld palette.

go leave them a star! ⭐

---

<div align="center">

*all the world is lucky to be your home* 🌿

</div>
