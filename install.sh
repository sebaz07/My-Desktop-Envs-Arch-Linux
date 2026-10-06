#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$REPO_ROOT/dotfiles"
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/my-desktop-envs/backups/$(date +%Y%m%d-%H%M%S)"
THEME="liberty"
ENABLE_SDDM=0
SET_DEFAULT_SHELL=0
INSTALL_PACKAGES=1

usage() {
  cat <<USAGE
Uso: ./install.sh [opciones]

  --theme ID             Tema inicial: liberty, johan-neon, arch-blue,
                         skull-teal o dusk-city (o tema capturado; default: liberty)
  --enable-sddm          Instala el tema Pixel Dusk City y habilita SDDM
  --set-default-shell    Establece Zsh como shell de inicio de sesión
  --no-packages          No instala paquetes con pacman
  -h, --help             Muestra esta ayuda
USAGE
}

while (($#)); do
  case "$1" in
    --theme) THEME="${2:?Falta el identificador del tema}"; shift 2 ;;
    --enable-sddm) ENABLE_SDDM=1; shift ;;
    --set-default-shell) SET_DEFAULT_SHELL=1; shift ;;
    --no-packages) INSTALL_PACKAGES=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opción desconocida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

CUSTOM_THEME="$DOTFILES/themes/custom/$THEME"
case "$THEME" in
  liberty|johan-neon|arch-blue|skull-teal|dusk-city) CUSTOM_THEME="" ;;
  *)
    [[ "$THEME" =~ ^[a-z0-9][a-z0-9-]*$ && -s "$CUSTOM_THEME/theme.conf" \
      && -s "$CUSTOM_THEME/waybar.css" && -s "$CUSTOM_THEME/wofi.css" \
      && -s "$CUSTOM_THEME/ghostty" ]] && compgen -G "$CUSTOM_THEME/wallpaper.*" >/dev/null || {
      printf 'Tema no reconocido o captura incompleta: %s\n' "$THEME" >&2
      exit 2
    }
    ;;
esac

if [[ "$EUID" -eq 0 ]]; then
  echo 'Ejecuta este script con tu usuario normal; sudo se usa solo cuando hace falta.' >&2
  exit 1
fi

if (( INSTALL_PACKAGES )); then
  command -v pacman >/dev/null || { echo 'Este instalador requiere Arch Linux/pacman.' >&2; exit 1; }
  mapfile -t packages < <(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$REPO_ROOT/packages/arch.txt")
  sudo pacman -S --needed --noconfirm "${packages[@]}"
fi

mkdir -p "$BACKUP_ROOT" "$WALLPAPER_DIR" "$HOME/.config/hypr" "$HOME/.config/waybar" \
  "$HOME/.config/wofi" "$HOME/.config/ghostty" "$HOME/.config/fastfetch" \
  "$HOME/.config/btop" "$HOME/.config/btop/themes" "$HOME/.config/cava" \
  "$HOME/.config/kitty" \
  "$HOME/.config/zsh" "$HOME/.local/share"

backup_existing() {
  local destination="$1" backup_path
  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_path="$BACKUP_ROOT/${destination#"$HOME/"}"
    mkdir -p "$(dirname "$backup_path")"
    mv -- "$destination" "$backup_path"
    printf 'Respaldo: %s -> %s\n' "$destination" "$backup_path"
  fi
}

link_config() {
  local source="$1" destination="$2" current
  mkdir -p "$(dirname "$destination")"
  if [[ -L "$destination" ]]; then
    current="$(readlink -f "$destination" 2>/dev/null || true)"
    [[ "$current" == "$source" ]] && return 0
  fi
  backup_existing "$destination"
  ln -sfn "$source" "$destination"
}

install_copy() {
  local source="$1" destination="$2"
  mkdir -p "$(dirname "$destination")"
  backup_existing "$destination"
  cp -a "$source" "$destination"
}

# Keep each built-in wallpaper in the normal user wallpaper directory.
install -m 0644 "$REPO_ROOT/assets/wallpapers/"* "$WALLPAPER_DIR/"

if [[ -n "$CUSTOM_THEME" ]]; then
  custom_wallpaper=""
  for candidate in "$CUSTOM_THEME"/wallpaper.*; do
    [[ -f "$candidate" ]] && { custom_wallpaper="$candidate"; break; }
  done
  if [[ -n "$custom_wallpaper" ]]; then
    install -m 0644 "$custom_wallpaper" "$WALLPAPER_DIR/$THEME.${custom_wallpaper##*.}"
  fi
fi

# Hyprland, its single-instance theme switcher, bar, launcher and terminal.
for file in hyprland.conf hypridle.conf hyprpaper.conf hyprlock.conf; do
  link_config "$DOTFILES/hypr/$file" "$HOME/.config/hypr/$file"
done
link_config "$DOTFILES/hypr/scripts" "$HOME/.config/hypr/scripts"
link_config "$DOTFILES/waybar/config" "$HOME/.config/waybar/config"
link_config "$DOTFILES/waybar/modules.json" "$HOME/.config/waybar/modules.json"
link_config "$DOTFILES/wofi/config" "$HOME/.config/wofi/config"
if [[ -n "$CUSTOM_THEME" ]]; then
  link_config "${CUSTOM_THEME}/waybar.css" "$HOME/.config/waybar/style.css"
  link_config "${CUSTOM_THEME}/wofi.css" "$HOME/.config/wofi/style.css"
else
  link_config "$DOTFILES/waybar/themes/$THEME.css" "$HOME/.config/waybar/style.css"
  link_config "$DOTFILES/wofi/themes/$THEME.css" "$HOME/.config/wofi/style.css"
fi
link_config "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
link_config "$DOTFILES/ghostty/themes" "$HOME/.config/ghostty/themes"
if [[ -n "$CUSTOM_THEME" ]]; then
  link_config "${CUSTOM_THEME}/ghostty" "$HOME/.config/ghostty/current-theme"
else
  link_config "$DOTFILES/ghostty/themes/$THEME" "$HOME/.config/ghostty/current-theme"
fi
link_config "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_config "$DOTFILES/kitty/themes" "$HOME/.config/kitty/themes"
if [[ -n "$CUSTOM_THEME" ]]; then
  for spec in \
    'kitty.conf:kitty/current-theme.conf:dotfiles/kitty/themes/liberty.conf' \
    'fastfetch.jsonc:fastfetch/config.jsonc:dotfiles/fastfetch/themes/liberty.jsonc' \
    'cava.conf:cava/config:dotfiles/cava/themes/liberty.conf' \
    'p10k.zsh:.p10k.zsh:dotfiles/zsh/themes/liberty.p10k.zsh' \
    'nvim-theme.lua:.config/hypr/nvim-theme.lua:-'; do
    source_file="${spec%%:*}"
    rest="${spec#*:}"
    destination="${rest%%:*}"
    fallback="${rest#*:}"
    source_path="$CUSTOM_THEME/$source_file"
    if [[ "$source_file" == fastfetch.jsonc && -s "$source_path" ]] \
      && ! grep -Eq '"modules"[[:space:]]*:' "$source_path"; then
      source_path="$REPO_ROOT/dotfiles/fastfetch/themes/liberty.jsonc"
    fi
    if [[ ! -s "$source_path" ]]; then
      [[ "$fallback" != - ]] || continue
      source_path="$REPO_ROOT/$fallback"
    fi
    link_config "$source_path" "$HOME/$destination"
  done
else
  link_config "$DOTFILES/kitty/themes/$THEME.conf" "$HOME/.config/kitty/current-theme.conf"
  link_config "$DOTFILES/fastfetch/themes/$THEME.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  link_config "$DOTFILES/cava/themes/$THEME.conf" "$HOME/.config/cava/config"
  link_config "$DOTFILES/zsh/themes/$THEME.p10k.zsh" "$HOME/.p10k.zsh"
fi
link_config "$DOTFILES/btop/themes" "$HOME/.config/btop/themes"
install_copy "$DOTFILES/btop/btop.conf" "$HOME/.config/btop/btop.conf"
if [[ -n "$CUSTOM_THEME" && -s "$CUSTOM_THEME/btop.theme" ]]; then
  btop_theme_path="$CUSTOM_THEME/btop.theme"
  btop_background=false
else
  btop_theme_path="$DOTFILES/btop/themes/$THEME.theme"
  btop_background=false
  [[ "$THEME" == dusk-city || "$THEME" == skull-teal || "$THEME" == arch-blue ]] && btop_background=true
  [[ -f "$btop_theme_path" ]] || btop_theme_path=Default
fi
sed -i "s|^color_theme = .*|color_theme = \"$btop_theme_path\"|; s|^theme_background = .*|theme_background = $btop_background|" \
  "$HOME/.config/btop/btop.conf"
link_config "$DOTFILES/nvim" "$HOME/.config/nvim"
link_config "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
link_config "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"

# Theme-specific terminal colors and Hyprland border survive a reboot.
if [[ -n "$CUSTOM_THEME" ]]; then
  border="$(<"$CUSTOM_THEME/theme.conf")"
else
  case "$THEME" in
    liberty) border='rgba(f2f2f2ff) rgba(888888ff) 45deg' ;;
    johan-neon) border='rgba(00d9ffff) rgba(f02bd4ff) 45deg' ;;
    arch-blue) border='rgba(31b7ffff) rgba(9f9ce8ff) 45deg' ;;
    skull-teal) border='rgba(70d3b5ff) rgba(e8b870ff) 45deg' ;;
    dusk-city) border='rgba(89dcebff) rgba(f38ba8ff) 45deg' ;;
  esac
fi
printf '%s\n' "$THEME" > "$HOME/.config/hypr/current-theme"
printf 'general {\n    col.active_border = %s\n}\n' "$border" > "$HOME/.config/hypr/theme.conf"

# Oh My Zsh, the Kushal prompt config, Powerlevel10k and autosuggestions.
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

if [[ ! -d "$HOME/qylock/.git" ]]; then
  git clone --depth 1 https://github.com/Darkkal44/qylock.git "$HOME/qylock"
fi
mkdir -p "$HOME/.oh-my-zsh/custom/plugins" "$HOME/.oh-my-zsh/custom/themes"
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi
if [[ ! -d "$HOME/.local/share/oh-my-zsh-Kushal-Theme" ]]; then
  git clone --depth 1 https://github.com/sebaz07/oh-my-zsh_Kushal-Theme.git \
    "$HOME/.local/share/oh-my-zsh-Kushal-Theme"
fi

# Install Qylock's QuickShell lockscreen assets and the included SDDM theme.
install_copy "$REPO_ROOT/assets/quickshell-lockscreen" "$HOME/.local/share/quickshell-lockscreen"
ln -sfn "$HOME/qylock/themes" "$HOME/.local/share/quickshell-lockscreen/themes_link"
if (( ENABLE_SDDM )); then
  sudo install -d /usr/share/sddm/themes/pixel-dusk-city /etc/sddm.conf.d
  sudo cp -a "$REPO_ROOT/assets/sddm/pixel-dusk-city/." /usr/share/sddm/themes/pixel-dusk-city/
  sudo tee /etc/sddm.conf.d/10-my-desktop-envs.conf >/dev/null <<'SDDM'
[Theme]
Current=pixel-dusk-city
SDDM
  sudo systemctl enable sddm.service
fi

systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true

if (( SET_DEFAULT_SHELL )); then
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    echo 'Zsh no está instalado. Instala packages/arch.txt y vuelve a ejecutar --set-default-shell.' >&2
    exit 1
  fi
  grep -Fxq "$zsh_path" /etc/shells || { echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; }
  if command -v pkexec >/dev/null 2>&1; then
    pkexec chsh -s "$zsh_path" "$USER"
  else
    chsh -s "$zsh_path"
  fi
fi

# Apply immediately when already inside Hyprland; otherwise exec-once applies it at login.
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl dispatch exec "$HOME/.config/hypr/scripts/theme-switcher.sh $THEME"
fi

printf '\nInstalación lista. Tema inicial: %s\nRespaldo de configuraciones previas: %s\n' "$THEME" "$BACKUP_ROOT"
if (( ENABLE_SDDM == 0 )); then
  echo 'Para activar SDDM, vuelve a ejecutar: ./install.sh --no-packages --theme '"$THEME"' --enable-sddm'
fi
if (( SET_DEFAULT_SHELL == 0 )); then
  if command -v zsh >/dev/null 2>&1; then
    echo 'Zsh está instalado; usa --set-default-shell para elegirlo como shell de inicio de sesión.'
  else
    echo 'Zsh aún no está instalado; ejecuta el instalador sin --no-packages para instalarlo.'
  fi
fi
