<div align="center">

# 🌿 meloworld

*a rice that feels like /home <3*

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![MangoWM](https://img.shields.io/badge/MangoWM-212121?style=for-the-badge&logoColor=white)
![Quickshell](https://img.shields.io/badge/Quickshell-80CBC4?style=for-the-badge&logoColor=black)

</div>

---

![desktop preview](assets/desktop.png)

---

## 🌱 about

Meloworld is my personal Arch Linux desktop. built around MangoWM and Quickshell. the wallpapers are ghibli landscapes and the whole thing is meant to feel warm, colorful, and alive.

every popup, widget, and notification is part of the same visual system. same row height, same font, same spacing throughout. things slide in, things slide out.

---

## 🍃 the setup

| | |
|---|---|
| **os** | Arch Linux |
| **wm** | [MangoWM](https://github.com/mangowm/mango) |
| **shell layer** | [Quickshell](https://quickshell.org/) |
| **launcher** | Rofi |
| **terminal** | [Ghostty](https://ghostty.org/) |
| **shell** | zsh |
| **editor** | [Zed](https://zed.dev/) |
| **font** | [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)|

---

## 🌸 the bar

workspace pills that slide in when you open something and slide out when you close it. scroll the mouse wheel to switch workspaces.

---

## 🪴 the popups

all animated — slide down from the top when they open, slide back up when they close. all share the same design language so they feel like they belong together.

### 🎼 media player

![media player](assets/media.png)

a simple media player. supports shuffle and repeat on supported apps. uses the material expressive 3 progress bar. 

### 🔊 audio

![audio popup](assets/audio.png)

device selection for output and input. volume and mic sliders side by side. click the icon to mute. everything dims when muted. if you only have one audio device, the selector hides itself.

### 🦷 bluetooth

![bluetooth popup](assets/bluetooth.png)

paired devices, scan button, and a filtered scan list that hides raw MAC addresses so you're not staring at noise. the list caps at five entries and scrolls. tells you when there's more above or below.

### 🛜 wifi

![wifi popup](assets/wifi.png)

previously connected networks, autoscan, password enter field. similar to bluetooth the list caps and scrolls.

### ⚡ power profile

![power popup](assets/power.png)

it uses power-profiles-daemon. the border changes color with whatever's active.

---

## 🌻 notifications

![notifications](assets/notifications.png)

slide in from the right. each app gets its own accent color, derived from the app name — so the same app always gets the same color. critical notifications go red regardless. there's a small timer ring that drains as the notification ages. hover to pause. click to dismiss.

---

## 🔑 SDDM

![sddm theme](assets/sddm.png)

i also created a sddm theme based on the same aesthetic. so it smoothly gets to desktop

---

## 🧑🏼‍💻 zed

![zed theme](assets/zed.png)

the zed theme is based on the same color palette. there is both blurred and non-blurred variants in the theme. i prefer the blur variant.

---

## 🍁 install

# Automatic Install for Arch Linux

```bash
git clone https://github.com/melatonia/meloworld-dotfiles
cd meloworld-dotfiles
chmod +x install.sh
./install.sh
```

# Manual Install
```bash
git clone https://github.com/melatonia/meloworld-dotfiles
cd meloworld-dotfiles

cp -r quickshell ~/.config/
cp -r mango ~/.config/
cp -r ghostty ~/.config/
cp -r hypr ~/.config/
cp -r rofi ~/.config/
cp -r zed ~/.config/
cp -r .zshrc ~/.zshrc
sudo cp -r meloworld-sddm /usr/share/sddm/themes/
```

then add these lines to `/etc/sddm.conf.d/theme.conf` for sddm theme
```
[Theme]
Current=meloworld-sddm
```

you can use this code to remove window buttons from apps.
```bash
gsettings set org.gnome.desktop.wm.preferences button-layout ":"
```

### dependencies

```bash
paru -S mangowm quickshell pipewire pipewire-pulse wireplumber bluez bluez-utils brightnessctl ghostty power-profiles-daemon polkit-gnome ttf-jetbrains-mono-nerd rofi rofimoji grim slurp awww bibata-cursor-theme-bin papirus-icon-theme zed zsh zsh-autosuggestions zsh-syntax-highlighting adw-gtk-theme xdg-desktop-portal-wlr hypridle playerctl

sudo systemctl enable --now bluetooth power-profiles-daemon
```

> ⚠️ use Quickshell **0.2.1 from the extra repo** — not the git version. the API is different and things will break.

---

## 📦 extras

all the current sound files are created by me using bitwig studio. you can use them however you want but i would appreciate a credit :3

i'm currently using zen browser with [transparent zen extension](https://sameerasw.com/zen) and `#212121CC` background. but if you want to use firefox i recommend using the [Firefox Gnome Theme](https://github.com/rafaelmardojai/firefox-gnome-theme)

---

## ✅ to-do list

- [x] consistent design system and color palette
- [x] fixing the widget overlap
- [x] removing the hardcoded values 
- [x] fix: smoother scrolling for sliders 
- [x] battery saver mode
- [x] fix: adding right click context menu to the tray
- [x] feature: not sure but a simple date widget
- [x] improvement: a more consistent lockscreen theme
- [x] improvement: a better rofi theme
- [x] feature: more sounds (currently login chime, notification, screenshot and usb connect-remove sound exists)
- [x] feature: osd's for brightness and audio 


---

## 🍀 credits

the popup design language — the row style, the accent stripes, the device selectors — was heavily inspired by [crylia-theme](https://github.com/Crylia/crylia-theme) by [Crylia](https://github.com/Crylia). a beautiful AwesomeWM rice that made the whole thing feel possible. everything here is reimplemented from scratch in QML, but the soul came from there.

go leave them a star! ⭐

---

<div align="center">

*all the world is lucky to be your home* 🌿

</div>
