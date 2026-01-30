# 🎨 MintOS Sonoma Dark Theme Installer

![Version](https://img.shields.io/badge/version-2.0-blue)
![Linux Mint](https://img.shields.io/badge/Linux%20Mint-22.3-green)
![Desktop](https://img.shields.io/badge/Desktop-Cinnamon-orange)
![License](https://img.shields.io/badge/license-GPLv3-red)

---

⚠️ **WARNING – IMPORTANT NOTICE** ⚠️
**This project is developed, tested, and officially supported ONLY on Linux Mint 22.3 with Cinnamon Desktop Environment.**
Using this script on other distributions or desktop environments is **at your own risk**.

---

## 📋 Overview

**MintOS Sonoma Dark Theme Installer** is a professional, production‑ready Bash installer that transforms **Linux Mint 22.3 Cinnamon** into a **macOS Sonoma‑like dark desktop experience**.

The script provides **fully automated installation**, **strict validation**, **automatic backups**, and **post‑installation verification**, ensuring a safe and repeatable setup.

* **Developer:** Abderrahim KOUBBI
* **Version:** 2.0
* **License:** GNU General Public License v3.0 (GPL‑3.0)

---

## ✨ Features

* ✅ **100% Automated Installation** – Zero manual steps required
* 🔍 **Pre‑Flight Validation** – System, disk, network, and compatibility checks
* ✔️ **Post‑Installation Verification** – Confirms successful setup
* 📦 **Complete macOS‑Style Theme Stack**:

  * WhiteSur GTK Dark Theme
  * WhiteSur Dark Icon Theme
  * macOS Cursor Theme (apple_cursor)
  * Plank Dock with macOS‑style configuration
* 🖼️ **macOS Wallpapers**:

  * Sonoma (Dark & Light)
  * Ventura, Monterey, Big Sur
  * Additional dark abstract wallpapers
* 🔤 **macOS‑Like Fonts**:

  * Inter (San Francisco Pro alternative)
  * JetBrains Mono (SF Mono alternative)
  * Roboto & Noto fonts
* 🎨 **UI & Panel Tweaks**:

  * macOS‑style top panel (28px)
  * Window buttons on the left
  * macOS‑like application menu
  * Hot corners enabled
  * 4 workspaces (macOS‑style)
* 💾 **Automatic Backup System** – Timestamped rollback support
* 📝 **Detailed Logging** – Full installation logs for debugging
* 🔄 **Error Recovery** – Graceful failure handling
* 🔒 **Safety First** – No critical system file modifications

---

## 🖥️ System Requirements

### Minimum Specifications

```
Operating System: Linux Mint 22.3
Desktop Environment: Cinnamon 6.6+
Architecture: x86_64
Disk Space: 512 MB free
RAM: 2 GB minimum
Internet: Required
Privileges: sudo access
```

### Required Dependencies

Installed automatically if missing:

* git
* curl
* wget
* plank
* sassc
* optipng
* inkscape
* libglib2.0-dev
* libxml2-utils
* cmake
* build-essential

---

## 📥 Installation

### ⚠️ Important Notes

* The installer **requires sudo privileges**
* Cursor theme is installed system‑wide
* Existing themes and Cinnamon settings are backed up automatically

### Option 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/mintos-sonoma-dark.git
cd mintos-sonoma-dark
chmod +x install_mintos_sonoma.sh
./install_mintos_sonoma.sh
```

### Option 2: Direct Download

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/mintos-sonoma-dark/main/install_mintos_sonoma.sh
chmod +x install_mintos_sonoma.sh
./install_mintos_sonoma.sh
```

### Option 3: One‑Line Install

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/mintos-sonoma-dark/main/install_mintos_sonoma.sh | bash
```

⏱️ **Estimated Time:** 5–10 minutes

---

## 🔍 Validation Process

### Pre‑Installation Checks

* Linux Mint detection
* Cinnamon desktop verification
* Internet connectivity
* Disk space availability
* Repository accessibility
* Root execution prevention

### Post‑Installation Verification

| Component         | Verification                  |
| ----------------- | ----------------------------- |
| GTK Theme         | ~/.themes/WhiteSur-Dark       |
| Icons             | ~/.icons/WhiteSur-dark        |
| Cursor            | /usr/share/icons/apple_cursor |
| Cinnamon Settings | gsettings validation          |
| Plank Dock        | Binary check                  |

---

## 📂 Created Directories

```
~/.mintos_sonoma_dark/
├── installation.log
├── logs/
└── sources/

~/.mintos_backup_YYYYMMDD_HHMMSS/
├── themes_backup/
├── icons_backup/
└── cinnamon_settings.dconf
```

---

## 🔄 Rollback & Uninstall

### Restore Previous Setup

```bash
dconf load /org/cinnamon/ < ~/.mintos_backup_*/cinnamon_settings.dconf
pkill -HUP cinnamon
```

### Full Uninstall

```bash
rm -rf ~/.themes/WhiteSur-Dark*
rm -rf ~/.icons/WhiteSur-dark*
sudo rm -rf /usr/share/icons/apple_cursor
rm -rf ~/.mintos_sonoma_dark
pkill -HUP cinnamon
```

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0**.

You are free to:

* Use
* Modify
* Distribute

**Under the condition that all derivative works remain open‑source and licensed under GPL‑3.0.**

See the `LICENSE` file for full details.

---

## 👨‍💻 Author

**Abderrahim KOUBBI**

* GitHub: [https://github.com/YOUR_USERNAME](https://github.com/YOUR_USERNAME)

---

## 🙏 Acknowledgments

* Vince Liuice – WhiteSur GTK & Icons
* ful1e5 – Apple Cursor Theme
* Linux Mint Team
* Cinnamon Desktop Team

---

## ⭐ Support

If you find this project useful:

* ⭐ Star the repository
* 🐛 Report bugs
* 💡 Suggest improvements
* 📢 Share with the community

---

**Made with ❤️ for Linux Mint Cinnamon users**
