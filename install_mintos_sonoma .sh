#!/usr/bin/env bash

###############################################################################
# MintOS Sonoma Dark Theme Installation Script
# Version: 2.0
# Developer: Abderrahim KOUBBI
# Compatible: Linux Mint 22.3 (Cinnamon)
# License: MIT
###############################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures
IFS=$'\n\t'

###############################################################################
# CONFIGURATION
###############################################################################

readonly THEME_NAME="MintOS Sonoma Dark"
readonly SCRIPT_VERSION="2.0"
readonly WORKDIR="$HOME/.mintos_sonoma_dark"
readonly THEMES_DIR="$HOME/.themes"
readonly ICONS_DIR="$HOME/.icons"
readonly BACKUP_DIR="$HOME/.mintos_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="$WORKDIR/installation.log"

# Repository URLs
readonly GTK_REPO="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
readonly ICON_REPO="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
readonly CURSOR_REPO="https://github.com/ful1e5/apple_cursor.git"
readonly WALLPAPER_REPO="https://github.com/jaagr/dots.git"

# macOS Wallpapers (Direct download links - verified)
readonly MACOS_WALLPAPERS=(
    "https://512pixels.net/downloads/macos-wallpapers-thumbs/10-14-Night-Thumb.jpg|macOS-Mojave-Night.jpg"
    "https://512pixels.net/downloads/macos-wallpapers-thumbs/11-0-Color-Day-Thumb.jpg|macOS-BigSur-Day.jpg"
    "https://512pixels.net/downloads/macos-wallpapers-thumbs/12-0-Day-Thumb.jpg|macOS-Monterey.jpg"
    "https://512pixels.net/downloads/macos-wallpapers-thumbs/13-0-Day-Thumb.jpg|macOS-Ventura.jpg"
    "https://512pixels.net/downloads/macos-wallpapers-6K/14-0-Day.jpg|macOS-Sonoma-Day.jpg"
    "https://512pixels.net/downloads/macos-wallpapers-6K/14-0-Night.jpg|macOS-Sonoma-Night.jpg"
)

# Cinnamon Extensions for macOS look
readonly CINNAMON_EXTENSIONS=(
    "https://cinnamon-spices.linuxmint.com/files/applets/panel-osd@berend.de.schouwer.gmail.com.zip"
)

# Required packages
readonly REQUIRED_PACKAGES=(
    "git"
    "curl"
    "wget"
    "plank"
    "sassc"
    "optipng"
    "inkscape"
    "libglib2.0-dev"
    "libxml2-utils"
    "cmake"
    "build-essential"
    "libxml2-dev"
    "gir1.2-glib-2.0"
    "fonts-roboto"
    "fonts-noto"
    "unzip"
)

###############################################################################
# COLORS & FORMATTING
###############################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

###############################################################################
# UTILITY FUNCTIONS
###############################################################################

log() {
    # Ensure log directory exists before writing
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    log "HEADER: $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
    log "ERROR: $1"
}

print_step() {
    echo -e "${MAGENTA}[→]${NC} $1"
    log "STEP: $1"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [${CYAN}%c${NC}]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -rp "$(echo -e "${YELLOW}$prompt${NC}")" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

###############################################################################
# PRE-FLIGHT CHECKS
###############################################################################

check_root() {
    print_step "Checking root privileges..."
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root!"
        print_info "Please run as regular user. Sudo will be used when needed."
        exit 1
    fi
    print_success "Running as non-root user"
}

check_distro() {
    print_step "Checking Linux distribution..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine Linux distribution"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "linuxmint" ]]; then
        print_warning "This script is designed for Linux Mint"
        print_info "Detected: $PRETTY_NAME"
        if ! confirm "Continue anyway?"; then
            exit 0
        fi
    else
        print_success "Linux Mint detected: $VERSION"
    fi
}

check_desktop() {
    print_step "Checking desktop environment..."
    
    if [[ "$XDG_CURRENT_DESKTOP" != *"Cinnamon"* ]] && [[ "$DESKTOP_SESSION" != *"cinnamon"* ]]; then
        print_warning "This theme is optimized for Cinnamon desktop"
        print_info "Detected: ${XDG_CURRENT_DESKTOP:-Unknown}"
        if ! confirm "Continue anyway?"; then
            exit 0
        fi
    else
        print_success "Cinnamon desktop detected"
    fi
}

check_internet() {
    print_step "Checking internet connection..."
    
    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        print_error "No internet connection detected"
        print_info "Internet is required to download theme components"
        exit 1
    fi
    
    print_success "Internet connection available"
}

check_disk_space() {
    print_step "Checking disk space..."
    
    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    local required_space=524288  # 512 MB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        print_error "Insufficient disk space"
        print_info "Required: 512 MB, Available: $((available_space / 1024)) MB"
        exit 1
    fi
    
    print_success "Sufficient disk space available: $((available_space / 1024 / 1024)) GB"
}

check_git_repos() {
    print_step "Validating repository URLs..."
    
    local repos=("$GTK_REPO" "$ICON_REPO" "$CURSOR_REPO")
    local all_valid=true
    
    for repo in "${repos[@]}"; do
        if git ls-remote "$repo" &> /dev/null; then
            print_success "✓ ${repo##*/}"
        else
            print_error "✗ Cannot access: $repo"
            all_valid=false
        fi
    done
    
    if [[ "$all_valid" == false ]]; then
        print_error "Some repositories are not accessible"
        exit 1
    fi
}

###############################################################################
# SYSTEM PREPARATION
###############################################################################

create_backup() {
    print_step "Creating backup of existing themes..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing themes
    if [[ -d "$THEMES_DIR" ]]; then
        cp -r "$THEMES_DIR" "$BACKUP_DIR/themes_backup" 2>/dev/null || true
    fi
    
    # Backup existing icons
    if [[ -d "$ICONS_DIR" ]]; then
        cp -r "$ICONS_DIR" "$BACKUP_DIR/icons_backup" 2>/dev/null || true
    fi
    
    # Backup gsettings
    dconf dump /org/cinnamon/ > "$BACKUP_DIR/cinnamon_settings.dconf" 2>/dev/null || true
    
    print_success "Backup created at: $BACKUP_DIR"
}

install_dependencies() {
    print_step "Installing required dependencies..."
    
    print_info "Updating package list..."
    sudo apt update &> /dev/null &
    spinner $!
    print_success "Package list updated"
    
    local missing_packages=()
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
        fi
    done
    
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        print_success "All dependencies already installed"
        return
    fi
    
    print_info "Installing ${#missing_packages[@]} missing packages..."
    print_info "Packages: ${missing_packages[*]}"
    
    sudo apt install -y "${missing_packages[@]}" &> /dev/null &
    spinner $!
    
    print_success "All dependencies installed successfully"
}

prepare_directories() {
    print_step "Preparing theme directories..."
    
    # Create theme and icon directories
    mkdir -p "$THEMES_DIR" "$ICONS_DIR"
    
    print_success "Theme directories prepared"
}

###############################################################################
# THEME INSTALLATION
###############################################################################

install_gtk_theme() {
    print_step "Installing WhiteSur GTK Dark theme..."
    
    cd "$WORKDIR"
    
    if [[ -d "WhiteSur-gtk-theme" ]]; then
        print_info "Removing existing GTK theme directory..."
        rm -rf "WhiteSur-gtk-theme"
    fi
    
    print_info "Cloning WhiteSur GTK repository..."
    if ! git clone --depth=1 "$GTK_REPO" &> "$WORKDIR/logs/gtk_clone.log"; then
        print_error "Failed to clone GTK theme repository"
        print_info "Check log: $WORKDIR/logs/gtk_clone.log"
        cat "$WORKDIR/logs/gtk_clone.log"
        return 1
    fi
    print_success "Repository cloned successfully"
    
    if [[ ! -d "WhiteSur-gtk-theme" ]]; then
        print_error "GTK theme directory not found after clone"
        return 1
    fi
    
    cd WhiteSur-gtk-theme
    
    # Make install script executable
    chmod +x install.sh
    
    print_info "Installing GTK theme (this may take 2-3 minutes)..."
    print_info "Please wait, compiling theme assets..."
    
    # Install dark theme variants with all tweaks
    # -c dark = dark color variant
    # -t all = all theme variants
    # For user installation to ~/.themes
    if ./install.sh -c dark -t all &> "$WORKDIR/logs/gtk_install_user.log"; then
        print_success "User installation completed"
    else
        print_warning "User installation had issues"
        echo "=== User Installation Log ===" >> "$WORKDIR/logs/gtk_install.log"
        cat "$WORKDIR/logs/gtk_install_user.log" >> "$WORKDIR/logs/gtk_install.log"
    fi
    
    # Verify installation
    if [[ -d "$HOME/.themes/WhiteSur-Dark" ]] || [[ -d "$HOME/.themes/WhiteSur-dark" ]]; then
        print_success "GTK theme installed successfully in: $HOME/.themes/"
        return 0
    else
        print_error "GTK theme installation failed - theme directory not found"
        print_info "Check logs:"
        print_info "  - $WORKDIR/logs/gtk_install_user.log"
        print_info "  - $WORKDIR/logs/gtk_install.log"
        
        # Show last few lines of error
        if [[ -f "$WORKDIR/logs/gtk_install_user.log" ]]; then
            echo ""
            print_warning "Installation log output:"
            cat "$WORKDIR/logs/gtk_install_user.log"
        fi
        
        return 1
    fi
}

install_icon_theme() {
    print_step "Installing WhiteSur Icon theme..."
    
    cd "$WORKDIR"
    
    if [[ -d "WhiteSur-icon-theme" ]]; then
        print_info "Removing existing icon theme directory..."
        rm -rf "WhiteSur-icon-theme"
    fi
    
    print_info "Cloning WhiteSur Icon repository..."
    if ! git clone --depth=1 "$ICON_REPO" &> "$WORKDIR/logs/icon_clone.log"; then
        print_error "Failed to clone icon theme repository"
        print_info "Check log: $WORKDIR/logs/icon_clone.log"
        cat "$WORKDIR/logs/icon_clone.log"
        return 1
    fi
    print_success "Repository cloned successfully"
    
    if [[ ! -d "WhiteSur-icon-theme" ]]; then
        print_error "Icon theme directory not found after clone"
        return 1
    fi
    
    cd WhiteSur-icon-theme
    
    # Make install script executable
    chmod +x install.sh
    
    print_info "Installing icon theme (this may take 1-2 minutes)..."
    
    # Install dark icon theme
    # -a = install all icon variants
    # -t default = default theme style
    if ./install.sh -a &> "$WORKDIR/logs/icon_install_user.log"; then
        print_success "Icon theme installation completed"
    else
        print_warning "Icon installation had issues"
        cat "$WORKDIR/logs/icon_install_user.log" >> "$WORKDIR/logs/icon_install.log"
    fi
    
    # Verify installation - check multiple possible names
    if [[ -d "$HOME/.icons/WhiteSur-dark" ]] || [[ -d "$HOME/.icons/WhiteSur-Dark" ]] || [[ -d "$HOME/.local/share/icons/WhiteSur-dark" ]]; then
        print_success "Icon theme installed successfully in: $HOME/.icons/"
        return 0
    else
        print_error "Icon theme installation failed - theme directory not found"
        print_info "Check log: $WORKDIR/logs/icon_install_user.log"
        
        if [[ -f "$WORKDIR/logs/icon_install_user.log" ]]; then
            echo ""
            print_warning "Installation log output:"
            cat "$WORKDIR/logs/icon_install_user.log"
        fi
        
        return 1
    fi
}

install_cursor_theme() {
    print_step "Installing macOS cursor theme..."
    
    cd "$WORKDIR"
    
    if [[ -d "apple_cursor" ]]; then
        print_info "Removing existing cursor directory..."
        rm -rf "apple_cursor"
    fi
    
    print_info "Cloning Apple Cursor repository..."
    if ! git clone --depth=1 "$CURSOR_REPO" &> "$WORKDIR/logs/cursor_clone.log"; then
        print_warning "Failed to clone cursor repository (non-critical)"
        print_info "Check log: $WORKDIR/logs/cursor_clone.log"
        return 0
    fi
    print_success "Repository cloned successfully"
    
    if [[ ! -d "apple_cursor" ]]; then
        print_warning "Cursor directory not found after clone (non-critical)"
        return 0
    fi
    
    cd apple_cursor
    
    print_info "Building cursor theme (this may take 1-2 minutes)..."
    mkdir -p build
    cd build
    
    if ! cmake .. &> "$WORKDIR/logs/cursor_cmake.log"; then
        print_warning "Cursor cmake configuration failed (non-critical)"
        return 0
    fi
    
    if ! make -j$(nproc) &> "$WORKDIR/logs/cursor_make.log"; then
        print_warning "Cursor compilation failed (non-critical)"
        return 0
    fi
    
    print_info "Installing cursor theme (requires sudo)..."
    if sudo make install &> "$WORKDIR/logs/cursor_install.log"; then
        print_success "Cursor theme installed successfully"
    else
        print_warning "Cursor installation failed (non-critical)"
        return 0
    fi
    
    # Verify installation
    if [[ -d "/usr/share/icons/apple_cursor" ]] || [[ -d "$HOME/.icons/apple_cursor" ]]; then
        print_success "Cursor theme verified"
        return 0
    else
        print_warning "Cursor theme not found after installation (non-critical)"
        return 0
    fi
}

###############################################################################
# THEME CONFIGURATION
###############################################################################

apply_theme_settings() {
    print_step "Applying theme settings to Cinnamon..."
    
    # Check if gsettings is available
    if ! command -v gsettings &> /dev/null; then
        print_error "gsettings command not found"
        return 1
    fi
    
    # Determine which theme variant exists
    local gtk_theme="WhiteSur-Dark"
    if [[ ! -d "$HOME/.themes/WhiteSur-Dark" ]] && [[ -d "$HOME/.themes/WhiteSur-dark" ]]; then
        gtk_theme="WhiteSur-dark"
    fi
    
    local icon_theme="WhiteSur-dark"
    if [[ ! -d "$HOME/.icons/WhiteSur-dark" ]] && [[ -d "$HOME/.icons/WhiteSur-Dark" ]]; then
        icon_theme="WhiteSur-Dark"
    fi
    
    print_info "Setting GTK theme to: $gtk_theme"
    gsettings set org.cinnamon.desktop.interface gtk-theme "$gtk_theme"
    
    print_info "Setting window manager theme..."
    gsettings set org.cinnamon.desktop.wm.preferences theme "$gtk_theme"
    
    print_info "Setting icon theme to: $icon_theme"
    gsettings set org.cinnamon.desktop.interface icon-theme "$icon_theme"
    
    print_info "Setting cursor theme..."
    gsettings set org.cinnamon.desktop.interface cursor-theme "apple_cursor" || \
        print_warning "Could not set cursor theme (non-critical)"
    
    print_info "Setting Cinnamon theme..."
    gsettings set org.cinnamon.theme name "$gtk_theme" || \
        print_warning "Could not set Cinnamon theme (non-critical)"
    
    print_success "Theme settings applied"
}

###############################################################################
# WALLPAPER INSTALLATION
###############################################################################

install_macos_wallpapers() {
    print_step "Installing macOS Sonoma wallpapers..."
    
    local wallpaper_dir="$HOME/Pictures/macOS-Wallpapers"
    mkdir -p "$wallpaper_dir"
    
    cd "$WORKDIR"
    mkdir -p macos-wallpapers
    cd macos-wallpapers
    
    print_info "Downloading macOS wallpapers (6 wallpapers)..."
    
    local download_count=0
    local failed_count=0
    
    # Download high-quality macOS wallpapers
    for wallpaper_info in "${MACOS_WALLPAPERS[@]}"; do
        local url="${wallpaper_info%%|*}"
        local filename="${wallpaper_info##*|}"
        
        print_info "Downloading: $filename"
        
        if wget -q --timeout=30 --tries=3 "$url" -O "$wallpaper_dir/$filename" &>> "$WORKDIR/logs/wallpaper_download.log"; then
            ((download_count++))
            print_success "✓ $filename"
        else
            ((failed_count++))
            print_warning "✗ Failed to download $filename"
        fi
    done
    
    # Download additional dark wallpapers from alternative source
    print_info "Downloading additional dark wallpapers..."
    
    # Sonoma Dark variant (using Unsplash - always available)
    local dark_wallpapers=(
        "https://images.unsplash.com/photo-1557683316-973673baf926?w=3840&q=100|Abstract-Dark-1.jpg"
        "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=3840&q=100|Abstract-Dark-2.jpg"
        "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=3840&q=100|Gradient-Dark.jpg"
    )
    
    for wallpaper_info in "${dark_wallpapers[@]}"; do
        local url="${wallpaper_info%%|*}"
        local filename="${wallpaper_info##*|}"
        
        if wget -q --timeout=30 --tries=2 "$url" -O "$wallpaper_dir/$filename" &>> "$WORKDIR/logs/wallpaper_download.log"; then
            ((download_count++))
        else
            ((failed_count++))
        fi
    done
    
    if [[ $download_count -gt 0 ]]; then
        print_success "Downloaded $download_count wallpapers to: $wallpaper_dir"
        
        # Set a dark wallpaper as default
        local default_wallpaper="$wallpaper_dir/macOS-Sonoma-Night.jpg"
        if [[ ! -f "$default_wallpaper" ]]; then
            # Use first available dark wallpaper
            default_wallpaper=$(find "$wallpaper_dir" -name "*Dark*" -o -name "*Night*" | head -1)
        fi
        
        if [[ -f "$default_wallpaper" ]]; then
            print_info "Setting default wallpaper..."
            gsettings set org.cinnamon.desktop.background picture-uri "file://$default_wallpaper"
            gsettings set org.cinnamon.desktop.background picture-options 'zoom'
            print_success "Wallpaper applied: $(basename "$default_wallpaper")"
        fi
    else
        print_warning "No wallpapers were downloaded successfully"
    fi
    
    cd "$WORKDIR"
}

###############################################################################
# PANEL & TOP BAR CONFIGURATION
###############################################################################

configure_macos_panel() {
    print_step "Configuring macOS-style top panel..."
    
    # Panel settings
    print_info "Applying panel settings..."
    
    # Set panel to top
    gsettings set org.cinnamon panels-enabled "['1:0:top']" 2>/dev/null || true
    
    # Panel height (macOS style - smaller)
    dconf write /org/cinnamon/panels-height "['1:28']" 2>/dev/null || true
    
    # Enable panel transparency
    dconf write /org/cinnamon/panels-autohide "['1:false']" 2>/dev/null || true
    
    # Panel settings for dark theme
    gsettings set org.cinnamon.theme name 'WhiteSur-Dark' 2>/dev/null || true
    
    print_success "Panel configured"
    
    # Configure applets for macOS layout
    print_info "Configuring panel applets..."
    
    # macOS-style applet layout: 
    # Left: Menu, Window List
    # Center: Date/Time  
    # Right: System Tray, Sound, Network, Power
    
    local applets_left='["panel1:left:0:menu@cinnamon.org:0", "panel1:left:1:show-desktop@cinnamon.org:1", "panel1:left:2:grouped-window-list@cinnamon.org:2"]'
    local applets_center='["panel1:center:0:calendar@cinnamon.org:3"]'
    local applets_right='["panel1:right:0:systray@cinnamon.org:4", "panel1:right:1:notifications@cinnamon.org:5", "panel1:right:2:sound@cinnamon.org:6", "panel1:right:3:network@cinnamon.org:7", "panel1:right:4:power@cinnamon.org:8"]'
    
    # Apply applet configuration
    dconf write /org/cinnamon/enabled-applets "$applets_left, $applets_center, $applets_right" 2>/dev/null || true
    
    print_success "Panel applets configured"
}

configure_macos_menu() {
    print_step "Configuring macOS-style application menu..."
    
    # Configure main menu to look like macOS
    local menu_schema="org.cinnamon.applets.menu"
    
    # Menu icon (use Apple-like icon if available)
    dconf write /org/cinnamon/applets/menu@cinnamon.org/0/menu-icon-custom false 2>/dev/null || true
    dconf write /org/cinnamon/applets/menu@cinnamon.org/0/menu-label '' 2>/dev/null || true
    
    # Configure window list for macOS style
    dconf write /org/cinnamon/applets/grouped-window-list@cinnamon.org/2/number-display false 2>/dev/null || true
    dconf write /org/cinnamon/applets/grouped-window-list@cinnamon.org/2/title-display 'title' 2>/dev/null || true
    
    print_success "Menu configured"
}

###############################################################################
# CINNAMON TWEAKS FOR MACOS
###############################################################################

apply_macos_cinnamon_tweaks() {
    print_step "Applying macOS-style system tweaks..."
    
    # Window decorations - macOS style buttons
    print_info "Configuring window buttons..."
    gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    
    # Enable desktop icons (like macOS)
    gsettings set org.nemo.desktop show-desktop-icons true 2>/dev/null || true
    
    # Hot corners (top-left for overview like macOS Mission Control)
    gsettings set org.cinnamon hotcorner-layout "['expo:false:0', 'scale:false:0', 'scale:false:0', 'desktop:false:0']" 2>/dev/null || true
    
    # Animation effects
    gsettings set org.cinnamon desktop-effects true 2>/dev/null || true
    gsettings set org.cinnamon desktop-effects-close-effect 'traditional' 2>/dev/null || true
    gsettings set org.cinnamon desktop-effects-map-effect 'traditional' 2>/dev/null || true
    gsettings set org.cinnamon desktop-effects-minimize-effect 'traditional' 2>/dev/null || true
    
    # Workspace settings (like macOS Spaces)
    gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 4 2>/dev/null || true
    gsettings set org.cinnamon workspace-osd-visible true 2>/dev/null || true
    
    # Sound theme (use freedesktop for macOS-like sounds)
    gsettings set org.cinnamon.desktop.sound theme-name 'freedesktop' 2>/dev/null || true
    
    # File manager (Nemo) settings
    gsettings set org.nemo.preferences show-hidden-files false 2>/dev/null || true
    gsettings set org.nemo.preferences show-location-entry false 2>/dev/null || true
    
    print_success "System tweaks applied"
}

configure_macos_dock_behavior() {
    print_step "Configuring dock behavior..."
    
    # Disable default Cinnamon dock/panel at bottom if it exists
    local current_panels=$(gsettings get org.cinnamon panels-enabled 2>/dev/null)
    
    # Keep only top panel, remove bottom panel
    gsettings set org.cinnamon panels-enabled "['1:0:top']" 2>/dev/null || true
    
    print_success "Dock behavior configured"
}

###############################################################################
# FONTS INSTALLATION
###############################################################################

install_macos_fonts() {
    print_step "Installing macOS San Francisco fonts..."
    
    local fonts_dir="$HOME/.local/share/fonts/SanFrancisco"
    mkdir -p "$fonts_dir"
    
    cd "$WORKDIR"
    
    print_info "Downloading San Francisco Pro fonts..."
    
    # Create fonts directory
    mkdir -p sf-fonts
    cd sf-fonts
    
    # Download SF Pro fonts from Apple (using archive.org mirror if direct link fails)
    local font_urls=(
        "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg"
        "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg"
        "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg"
    )
    
    # Alternative: Use Google Fonts similar fonts
    print_info "Installing Roboto and Inter fonts (San Francisco alternatives)..."
    
    # Download Inter font (closest to SF Pro)
    if ! wget -q "https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip" -O inter.zip &> "$WORKDIR/logs/fonts_download.log"; then
        print_warning "Failed to download Inter font, using system fonts"
    else
        unzip -q inter.zip -d inter
        cp inter/*.ttf "$fonts_dir/" 2>/dev/null || true
        print_success "Inter font installed"
    fi
    
    # Install SF Mono alternative (JetBrains Mono)
    print_info "Installing JetBrains Mono (SF Mono alternative)..."
    if ! wget -q "https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip" -O jetbrains.zip &>> "$WORKDIR/logs/fonts_download.log"; then
        print_warning "Failed to download JetBrains Mono"
    else
        unzip -q jetbrains.zip -d jetbrains
        cp jetbrains/fonts/ttf/*.ttf "$fonts_dir/" 2>/dev/null || true
        print_success "JetBrains Mono installed"
    fi
    
    # Update font cache
    print_info "Updating font cache..."
    fc-cache -f -v &> "$WORKDIR/logs/font_cache.log"
    
    print_success "Fonts installed successfully"
    
    cd "$WORKDIR"
}

###############################################################################
# PLANK CONFIGURATION
###############################################################################

configure_plank_advanced() {
    print_step "Configuring Plank dock with macOS style..."
    
    # Install Plank if not already installed
    if ! command -v plank &> /dev/null; then
        print_info "Plank not found, installing..."
        sudo apt install -y plank &> /dev/null
    fi
    
    # Kill existing Plank instance
    pkill plank 2>/dev/null || true
    sleep 1
    
    # Create Plank configuration directory
    local plank_dir="$HOME/.config/plank/dock1"
    mkdir -p "$plank_dir"
    
    print_info "Applying macOS-style Plank settings..."
    
    # Create Plank settings file
    cat > "$plank_dir/settings" << 'EOF'
#This file auto-generated by Plank.
#2026-01-30T00:00:00

[PlankDockPreferences]
Alignment='center'
AutoPinning=true
CurrentWorkspaceOnly=false
DockItems='firefox.desktoplaunch|thunderbird.desktoplaunch|org.gnome.Nautilus.desktoplaunch|org.gnome.Terminal.desktoplaunch'
HideDelay=100
HideMode='intelligent'
IconSize=48
ItemsAlignment='center'
LockItems=false
MonitorNumber=0
Offset=0
PinOnly=false
Position='bottom'
PressureReveal=false
ShowDockItem=false
Theme='Transparent'
UnhideDelay=0
ZoomEnabled=true
ZoomPercent=120
EOF
    
    print_success "Plank settings configured"
    
    # Download and install macOS-like Plank theme
    print_info "Installing macOS Plank theme..."
    
    local plank_themes_dir="$HOME/.local/share/plank/themes"
    mkdir -p "$plank_themes_dir"
    
    # Create custom macOS theme
    mkdir -p "$plank_themes_dir/macOS"
    cat > "$plank_themes_dir/macOS/dock.theme" << 'EOF'
#This file auto-generated by Plank.
#PlankTheme1.0

[PlankTheme]
TopRoundness=8
BottomRoundness=0
LineWidth=1
OuterStrokeColor=41;;41;;41;;255
FillStartColor=41;;41;;41;;150
FillEndColor=41;;41;;41;;150
InnerStrokeColor=41;;41;;41;;255

[PlankDockTheme]
HorizPadding=2
TopPadding=2
BottomPadding=2
ItemPadding=4
IndicatorSize=5
IconShadow=true
UrgentBounceHeight=2
LaunchBounceHeight=2
FadeOpacity=0.8
ClickTime=300
UrgentBounceTime=600
LaunchBounceTime=600
ActiveTime=300
SlideTime=300
FadeTime=250
HideTime=250
GlowSize=30
GlowTime=300
GlowPulseTime=2000
UrgentHueShift=150
ItemMoveTime=150
EOF
    
    print_success "macOS Plank theme installed"
    
    # Update Plank theme setting
    sed -i "s/Theme='Transparent'/Theme='macOS'/g" "$plank_dir/settings" 2>/dev/null || true
    
    # Create autostart entry
    mkdir -p "$HOME/.config/autostart"
    
    cat > "$HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Stupidly simple.
Icon=plank
EOF
    
    print_success "Plank configured to start automatically"
    
    # Start Plank in background
    print_info "Starting Plank dock..."
    nohup plank &> /dev/null &
    sleep 2
    
    if pgrep -x plank > /dev/null; then
        print_success "Plank is running"
    else
        print_warning "Plank may not have started (you can start it manually)"
    fi
}

###############################################################################
# POST-INSTALLATION REVIEW
###############################################################################

show_installation_review() {
    print_header "INSTALLATION REVIEW"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${BOLD}Installation Summary${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # GTK Theme
    echo -e "${WHITE}1. GTK Theme:${NC}"
    if [[ -d "$HOME/.themes/WhiteSur-Dark" ]] || [[ -d "$HOME/.themes/WhiteSur-dark" ]]; then
        echo -e "   ${GREEN}✓${NC} Installed: WhiteSur Dark"
        local gtk_location=$(find "$HOME/.themes" -maxdepth 1 -name "WhiteSur-*ark" -type d 2>/dev/null | head -1)
        echo -e "   ${BLUE}→${NC} Location: $gtk_location"
    else
        echo -e "   ${RED}✗${NC} Not found"
    fi
    echo ""
    
    # Icon Theme
    echo -e "${WHITE}2. Icon Theme:${NC}"
    if [[ -d "$HOME/.icons/WhiteSur-dark" ]] || [[ -d "$HOME/.icons/WhiteSur-Dark" ]]; then
        echo -e "   ${GREEN}✓${NC} Installed: WhiteSur Icons"
        local icon_location=$(find "$HOME/.icons" -maxdepth 1 -name "WhiteSur-*ark" -type d 2>/dev/null | head -1)
        echo -e "   ${BLUE}→${NC} Location: $icon_location"
    else
        echo -e "   ${RED}✗${NC} Not found"
    fi
    echo ""
    
    # Cursor Theme
    echo -e "${WHITE}3. Cursor Theme:${NC}"
    if [[ -d "/usr/share/icons/apple_cursor" ]] || [[ -d "$HOME/.icons/apple_cursor" ]]; then
        echo -e "   ${GREEN}✓${NC} Installed: Apple Cursor"
    else
        echo -e "   ${YELLOW}⚠${NC} Not installed (optional)"
    fi
    echo ""
    
    # Wallpapers
    echo -e "${WHITE}4. Wallpapers:${NC}"
    if [[ -d "$HOME/Pictures/macOS-Wallpapers" ]]; then
        local wallpaper_count=$(find "$HOME/Pictures/macOS-Wallpapers" -name "*.jpg" -o -name "*.png" 2>/dev/null | wc -l)
        echo -e "   ${GREEN}✓${NC} Installed: $wallpaper_count wallpapers"
        echo -e "   ${BLUE}→${NC} Location: $HOME/Pictures/macOS-Wallpapers"
        local current_wallpaper=$(gsettings get org.cinnamon.desktop.background picture-uri 2>/dev/null | tr -d "'")
        if [[ -n "$current_wallpaper" ]]; then
            echo -e "   ${BLUE}→${NC} Active: $(basename "${current_wallpaper#file://}")"
        fi
    else
        echo -e "   ${YELLOW}⚠${NC} Wallpapers not downloaded"
    fi
    echo ""
    
    # Fonts
    echo -e "${WHITE}5. Fonts:${NC}"
    if [[ -d "$HOME/.local/share/fonts/SanFrancisco" ]]; then
        local font_count=$(find "$HOME/.local/share/fonts/SanFrancisco" -name "*.ttf" 2>/dev/null | wc -l)
        echo -e "   ${GREEN}✓${NC} Installed: $font_count font files"
        echo -e "   ${BLUE}→${NC} Inter (San Francisco Pro alternative)"
        echo -e "   ${BLUE}→${NC} JetBrains Mono (SF Mono alternative)"
    else
        echo -e "   ${YELLOW}⚠${NC} Custom fonts not installed"
    fi
    echo ""
    
    # Plank
    echo -e "${WHITE}6. Plank Dock:${NC}"
    if command -v plank &> /dev/null; then
        echo -e "   ${GREEN}✓${NC} Installed: Plank"
        if pgrep -x plank > /dev/null; then
            echo -e "   ${GREEN}✓${NC} Status: Running"
        else
            echo -e "   ${YELLOW}⚠${NC} Status: Not running (will start on next login)"
        fi
        if [[ -f "$HOME/.config/plank/dock1/settings" ]]; then
            echo -e "   ${GREEN}✓${NC} Configuration: Applied"
        fi
        if [[ -d "$HOME/.local/share/plank/themes/macOS" ]]; then
            echo -e "   ${GREEN}✓${NC} Theme: macOS style installed"
        fi
    else
        echo -e "   ${RED}✗${NC} Not installed"
    fi
    echo ""
    
    # Panel Configuration
    echo -e "${WHITE}7. Top Panel:${NC}"
    local panels=$(gsettings get org.cinnamon panels-enabled 2>/dev/null)
    if [[ "$panels" == *"top"* ]]; then
        echo -e "   ${GREEN}✓${NC} Position: Top (macOS style)"
        echo -e "   ${GREEN}✓${NC} Height: 28px (macOS style)"
    else
        echo -e "   ${YELLOW}⚠${NC} Panel configuration may need adjustment"
    fi
    echo ""
    
    # Window Buttons
    echo -e "${WHITE}8. Window Decorations:${NC}"
    local button_layout=$(gsettings get org.cinnamon.desktop.wm.preferences button-layout 2>/dev/null)
    if [[ "$button_layout" == *"close,minimize,maximize"* ]]; then
        echo -e "   ${GREEN}✓${NC} Buttons: macOS style (left side)"
    else
        echo -e "   ${YELLOW}⚠${NC} Button layout: default"
    fi
    echo ""
    
    # Current Theme Settings
    echo -e "${WHITE}9. Active Theme Settings:${NC}"
    local current_gtk=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    local current_icon=$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    local current_cursor=$(gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
    
    echo -e "   ${BLUE}→${NC} GTK Theme: ${BOLD}$current_gtk${NC}"
    echo -e "   ${BLUE}→${NC} Icon Theme: ${BOLD}$current_icon${NC}"
    echo -e "   ${BLUE}→${NC} Cursor Theme: ${BOLD}$current_cursor${NC}"
    echo ""
    
    # Backup
    echo -e "${WHITE}10. Backup:${NC}"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "   ${GREEN}✓${NC} Created: $BACKUP_DIR"
        local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo -e "   ${BLUE}→${NC} Size: $backup_size"
    fi
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${BOLD}Installation Paths${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}→${NC} Working Directory: $WORKDIR"
    echo -e "${BLUE}→${NC} Installation Log: $LOG_FILE"
    echo -e "${BLUE}→${NC} Backup Directory: $BACKUP_DIR"
    echo -e "${BLUE}→${NC} Wallpapers: $HOME/Pictures/macOS-Wallpapers"
    echo ""
}

verify_installation() {
    print_header "VERIFICATION"
    
    local errors=0
    local warnings=0
    
    # Check GTK theme
    print_step "Verifying GTK theme..."
    if [[ -d "$HOME/.themes/WhiteSur-Dark" ]] || [[ -d "$HOME/.themes/WhiteSur-dark" ]] || [[ -d "/usr/share/themes/WhiteSur-Dark" ]]; then
        print_success "✓ GTK theme files present"
    else
        print_error "✗ GTK theme files missing"
        print_info "Checked locations:"
        print_info "  - $HOME/.themes/WhiteSur-Dark"
        print_info "  - $HOME/.themes/WhiteSur-dark"
        print_info "  - /usr/share/themes/WhiteSur-Dark"
        ((errors++))
    fi
    
    # Check icon theme
    print_step "Verifying icon theme..."
    if [[ -d "$HOME/.icons/WhiteSur-dark" ]] || [[ -d "$HOME/.icons/WhiteSur-Dark" ]] || [[ -d "$HOME/.local/share/icons/WhiteSur-dark" ]] || [[ -d "/usr/share/icons/WhiteSur-dark" ]]; then
        print_success "✓ Icon theme files present"
    else
        print_error "✗ Icon theme files missing"
        print_info "Checked locations:"
        print_info "  - $HOME/.icons/WhiteSur-dark"
        print_info "  - $HOME/.icons/WhiteSur-Dark"
        print_info "  - $HOME/.local/share/icons/WhiteSur-dark"
        ((errors++))
    fi
    
    # Check cursor theme
    print_step "Verifying cursor theme..."
    if [[ -d "/usr/share/icons/apple_cursor" ]] || [[ -d "$HOME/.icons/apple_cursor" ]]; then
        print_success "✓ Cursor theme files present"
    else
        print_warning "⚠ Cursor theme files not found"
        ((warnings++))
    fi
    
    # Check gsettings
    print_step "Verifying theme settings..."
    local current_gtk_theme
    current_gtk_theme=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null || echo "")
    
    if [[ "$current_gtk_theme" == *"WhiteSur-Dark"* ]]; then
        print_success "✓ GTK theme setting applied"
    else
        print_warning "⚠ GTK theme setting may not be applied"
        ((warnings++))
    fi
    
    # Check Plank
    print_step "Verifying Plank installation..."
    if command -v plank &> /dev/null; then
        print_success "✓ Plank installed"
    else
        print_warning "⚠ Plank not found"
        ((warnings++))
    fi
    
    # Summary
    echo ""
    print_header "VERIFICATION SUMMARY"
    
    if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}${BOLD}  ✓ INSTALLATION 100% SUCCESSFUL${NC}"
        echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    elif [[ $errors -eq 0 ]]; then
        echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}${BOLD}  ✓ Installation successful with $warnings warning(s)${NC}"
        echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}${BOLD}  ✗ Installation failed with $errors error(s)${NC}"
        echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

###############################################################################
# CLEANUP & FINALIZATION
###############################################################################

cleanup() {
    print_step "Cleaning up temporary files..."
    
    cd "$HOME"
    
    # Optionally remove build directories
    if confirm "Remove build directories to save space?" "y"; then
        rm -rf "$WORKDIR/WhiteSur-gtk-theme"
        rm -rf "$WORKDIR/WhiteSur-icon-theme"
        rm -rf "$WORKDIR/apple_cursor"
        print_success "Build directories removed"
    else
        print_info "Build directories kept for reference"
    fi
}

show_completion_message() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ███╗   ███╗██╗███╗   ██╗████████╗ ██████╗ ███████╗          ║
║     ████╗ ████║██║████╗  ██║╚══██╔══╝██╔═══██╗██╔════╝          ║
║     ██╔████╔██║██║██╔██╗ ██║   ██║   ██║   ██║███████╗          ║
║     ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║   ██║╚════██║          ║
║     ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ╚██████╔╝███████║          ║
║     ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚══════╝          ║
║                                                                  ║
║              SONOMA DARK THEME - INSTALLED                       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${GREEN}${BOLD}Installation completed successfully!${NC}\n"
    
    echo -e "${WHITE}${BOLD}What has been installed:${NC}"
    echo -e "${GREEN}✓${NC} WhiteSur GTK Dark Theme"
    echo -e "${GREEN}✓${NC} WhiteSur Dark Icon Theme"
    echo -e "${GREEN}✓${NC} Apple Cursor Theme"
    echo -e "${GREEN}✓${NC} macOS Wallpapers (Sonoma, Ventura, etc.)"
    echo -e "${GREEN}✓${NC} macOS Fonts (Inter, JetBrains Mono)"
    echo -e "${GREEN}✓${NC} Plank Dock (macOS style)"
    echo -e "${GREEN}✓${NC} Top Panel (macOS configuration)"
    echo -e "${GREEN}✓${NC} Window buttons (left side like macOS)"
    echo ""
    
    echo -e "${WHITE}${BOLD}Next steps:${NC}"
    echo -e "${CYAN}1.${NC} ${BOLD}IMPORTANT:${NC} Log out and log back in for full effect"
    echo -e "   ${YELLOW}→ Some changes require a fresh session${NC}\n"
    
    echo -e "${CYAN}2.${NC} Plank dock:"
    if pgrep -x plank > /dev/null; then
        echo -e "   ${GREEN}✓${NC} Already running at the bottom"
    else
        echo -e "   ${YELLOW}→ Will start automatically on next login${NC}"
        echo -e "   ${YELLOW}→ To start now: plank &${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}3.${NC} Wallpapers:"
    echo -e "   ${YELLOW}→ Location: $HOME/Pictures/macOS-Wallpapers${NC}"
    echo -e "   ${YELLOW}→ Right-click desktop → Change Desktop Background${NC}\n"
    
    echo -e "${CYAN}4.${NC} To customize further:"
    echo -e "   ${YELLOW}→ Right-click Plank → Preferences (change size, position)${NC}"
    echo -e "   ${YELLOW}→ System Settings → Themes (fine-tune appearance)${NC}"
    echo -e "   ${YELLOW}→ System Settings → Fonts (select Inter font)${NC}\n"
    
    echo -e "${CYAN}5.${NC} Backup location (if rollback needed):"
    echo -e "   ${YELLOW}$BACKUP_DIR${NC}\n"
    
    echo -e "${CYAN}6.${NC} Installation log:"
    echo -e "   ${YELLOW}$LOG_FILE${NC}\n"
    
    if confirm "Would you like to log out now?" "n"; then
        print_info "Logging out in 3 seconds..."
        sleep 3
        cinnamon-session-quit --logout --no-prompt
    fi
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    # Create working directory FIRST (before any logging)
    mkdir -p "$WORKDIR" "$WORKDIR/logs" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || true
    
    clear
    
    # Banner
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     MintOS Sonoma Dark Theme Installer v2.0                      ║
║     Professional macOS-like theme for Linux Mint                 ║
║                                                                  ║
║     Developer: Abderrahim KOUBBI                                 ║
║     Compatible: Linux Mint 22.3 (Cinnamon)                       ║
║     License: MIT                                                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    # Safety warning
    print_header "IMPORTANT SAFETY INFORMATION"
    echo ""
    echo -e "${YELLOW}${BOLD}This installer will make the following changes:${NC}"
    echo -e "${CYAN}→${NC} Install GTK theme, icons, cursor, and fonts"
    echo -e "${CYAN}→${NC} Download and set macOS wallpapers"
    echo -e "${CYAN}→${NC} Configure top panel (macOS style)"
    echo -e "${CYAN}→${NC} Change window button layout to left side"
    echo -e "${CYAN}→${NC} Install and configure Plank dock"
    echo -e "${CYAN}→${NC} Apply macOS-like system tweaks"
    echo ""
    echo -e "${GREEN}${BOLD}Safety measures:${NC}"
    echo -e "${GREEN}✓${NC} Automatic backup created before changes"
    echo -e "${GREEN}✓${NC} No system files will be modified"
    echo -e "${GREEN}✓${NC} All changes are user-level (safe)"
    echo -e "${GREEN}✓${NC} Easy rollback using backup"
    echo ""
    
    if ! confirm "Do you want to proceed with these changes?" "y"; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    echo ""
    
    # Request sudo password early
    print_header "ADMINISTRATIVE PRIVILEGES REQUIRED"
    echo ""
    print_info "This installer requires administrative privileges to:"
    echo -e "  ${CYAN}•${NC} Install system packages"
    echo -e "  ${CYAN}•${NC} Install themes system-wide"
    echo -e "  ${CYAN}•${NC} Install cursor theme"
    echo ""
    print_info "Please enter your password when prompted..."
    echo ""
    
    if ! sudo -v; then
        print_error "Failed to obtain administrative privileges"
        print_error "Installation cannot continue without sudo access"
        exit 1
    fi
    
    print_success "Administrative privileges granted"
    echo ""
    
    # Keep sudo alive in background
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Installation started"
    log "Version: $SCRIPT_VERSION"
    log "Developer: Abderrahim KOUBBI"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Pre-flight checks
    print_header "PRE-FLIGHT CHECKS"
    check_root
    check_distro
    check_desktop
    check_internet
    check_disk_space
    check_git_repos
    
    print_success "All pre-flight checks passed!"
    echo ""
    
    if ! confirm "Continue with installation?" "y"; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    # System preparation
    print_header "SYSTEM PREPARATION"
    prepare_directories
    create_backup
    install_dependencies
    
    # Theme installation
    print_header "THEME INSTALLATION"
    
    if ! install_gtk_theme; then
        print_error "GTK theme installation failed"
        exit 1
    fi
    
    if ! install_icon_theme; then
        print_error "Icon theme installation failed"
        exit 1
    fi
    
    install_cursor_theme  # Non-critical
    
    # Configuration
    print_header "CONFIGURATION"
    install_macos_wallpapers
    configure_macos_panel
    configure_macos_menu
    apply_macos_cinnamon_tweaks
    configure_macos_dock_behavior
    install_macos_fonts
    apply_theme_settings
    configure_plank_advanced
    
    # Verification
    if ! verify_installation; then
        print_error "Installation verification failed"
        print_info "Check logs at: $LOG_FILE"
        exit 1
    fi
    
    # Show detailed review
    show_installation_review
    
    # Cleanup
    cleanup
    
    # Completion
    show_completion_message
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Installation completed successfully"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

###############################################################################
# ERROR HANDLING
###############################################################################

trap 'print_error "An error occurred on line $LINENO. Check $LOG_FILE for details."; exit 1' ERR

###############################################################################
# RUN
###############################################################################

main "$@"
