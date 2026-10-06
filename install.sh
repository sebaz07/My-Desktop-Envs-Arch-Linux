#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$REPO_ROOT/dotfiles"
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/my-desktop-envs/backups/$(date +%Y%m%d-%H%M%S)"
THEME="liberty"
ENABLE_SDDM=0
SET_DEFAULT_SHELL=0
INSTALL_PACKAGES=1
VSCODE_THEME=0
FORCE_MENU=0
NO_MENU=0
INITIAL_ARGS=$#

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_CYAN=$'\033[38;5;51m'
C_BLUE=$'\033[38;5;39m'
C_MAGENTA=$'\033[38;5;213m'
C_GREEN=$'\033[38;5;82m'
C_YELLOW=$'\033[38;5;220m'
C_RED=$'\033[38;5;203m'

usage() {
  cat <<USAGE
Uso: ./install.sh [opciones]

  --theme ID             Tema inicial: liberty, johan-neon, arch-blue,
                         skull-teal o dusk-city (o tema capturado; default: liberty)
  --enable-sddm          Instala el tema Pixel Dusk City y habilita SDDM
  --set-default-shell    Establece Zsh como shell de inicio de sesión
  --vscode-theme        Sincroniza VS Code con el tema del escritorio
  --no-packages          No instala paquetes con pacman
  --menu                 Abre el menú interactivo antes de instalar
  --no-menu              No abre el menú automáticamente
  -h, --help             Muestra esta ayuda
USAGE
}

while (($#)); do
  case "$1" in
    --theme) THEME="${2:?Falta el identificador del tema}"; shift 2 ;;
    --enable-sddm) ENABLE_SDDM=1; shift ;;
    --set-default-shell) SET_DEFAULT_SHELL=1; shift ;;
    --vscode-theme) VSCODE_THEME=1; shift ;;
    --no-packages) INSTALL_PACKAGES=0; shift ;;
    --menu) FORCE_MENU=1; shift ;;
    --no-menu) NO_MENU=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opción desconocida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

show_banner() {
  printf '%s' "$C_CYAN"
  cat <<'BANNER'
  ███████╗███████╗██████╗  █████╗ ███████╗
  ██╔════╝██╔════╝██╔══██╗██╔══██╗╚══███╔╝
  ███████╗█████╗  ██████╔╝███████║  ███╔╝
  ╚════██║██╔══╝  ██╔══██╗██╔══██║ ███╔╝
  ███████║███████╗██████╔╝██║  ██║███████╗
  ╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝

       ▄▀█ █▀█ █▀▀ █ █   █   █ █▄ █ █ █ ▀█▀
       █▀█ █▀▄ ██▄ █ █▄▄ █▄▄ █ █ ▀█ █▄█  █
BANNER
  printf '%s%s%s\n' "$C_MAGENTA" '       ARCH LINUX  •  DESKTOP ENVIRONMENT' "$C_RESET"
}

interactive_menu() {
  local answer choice index theme_list=()
  while IFS= read -r theme_id; do theme_list+=("$theme_id"); done < <(
    printf '%s\n' liberty johan-neon arch-blue skull-teal dusk-city
    if [[ -d "$DOTFILES/themes/custom" ]]; then
      find "$DOTFILES/themes/custom" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
    fi
  )
  while :; do
    [[ -t 1 ]] && clear 2>/dev/null || true
    show_banner
    printf '\n%s%sConfiguración de instalación%s\n\n' "$C_BOLD" "$C_BLUE" "$C_RESET"
    printf '  Tema:              %s%s%s\n' "$C_CYAN" "$THEME" "$C_RESET"
    printf '  Paquetes pacman:   %s\n' "$([[ $INSTALL_PACKAGES == 1 ]] && printf 'Sí' || printf 'No')"
    printf '  Activar SDDM:      %s\n' "$([[ $ENABLE_SDDM == 1 ]] && printf 'Sí' || printf 'No')"
    printf '  Shell Zsh default: %s\n' "$([[ $SET_DEFAULT_SHELL == 1 ]] && printf 'Sí' || printf 'No')"
    printf '  Tema VS Code:      %s\n\n' "$([[ $VSCODE_THEME == 1 ]] && printf 'Sí' || printf 'No')"
    printf '%s  1%s  Elegir tema\n  2  Alternar instalación de paquetes\n  3  Alternar SDDM\n  4  Alternar Zsh como shell predeterminado\n  5  Alternar sincronización de VS Code\n' "$C_BOLD" "$C_RESET"
    printf '  %s6%s  %sEmpezar instalación%s\n  7  Salir\n\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$C_RESET"
    read -r -p '  Selección [1-7]: ' answer || exit 130
    case "$answer" in
      1)
        printf '\n%sTemas disponibles:%s\n' "$C_BOLD" "$C_RESET"
        for index in "${!theme_list[@]}"; do printf '  %d) %s\n' "$((index + 1))" "${theme_list[$index]}"; done
        read -r -p '  Número de tema (Enter conserva el actual): ' choice || exit 130
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#theme_list[@]} )); then
          THEME="${theme_list[$((choice - 1))]}"
        else
          printf '%sTema sin cambios.%s\n' "$C_DIM" "$C_RESET"
          sleep 1
        fi
        ;;
      2) INSTALL_PACKAGES=$((1 - INSTALL_PACKAGES)) ;;
      3) ENABLE_SDDM=$((1 - ENABLE_SDDM)) ;;
      4) SET_DEFAULT_SHELL=$((1 - SET_DEFAULT_SHELL)) ;;
      5) VSCODE_THEME=$((1 - VSCODE_THEME)) ;;
      6) break ;;
      7) printf '\nInstalación cancelada.\n'; exit 0 ;;
      *) printf '%sOpción inválida.%s\n' "$C_RED" "$C_RESET"; sleep 1 ;;
    esac
  done
}

if (( NO_MENU == 0 )) && { (( FORCE_MENU )) || { (( INITIAL_ARGS == 0 )) && [[ -t 0 ]]; }; }; then
  interactive_menu
fi

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/my-desktop-envs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
CURRENT_PHASE='inicialización'
trap 'status=$?; printf "\\n%s[ERROR]%s Falló la fase: %s\\n  Línea: %s\\n  Comando: %s\\n  Código: %s\\n  Log completo: %s\\n" "$C_RED" "$C_RESET" "$CURRENT_PHASE" "$LINENO" "$BASH_COMMAND" "$status" "$LOG_FILE" >&2; exit "$status"' ERR

phase() {
  CURRENT_PHASE="$1"
  printf '\n%s╭─ %s%s\n' "$C_BLUE" "$CURRENT_PHASE" "$C_RESET"
}

show_banner
printf '\n%sLog de esta instalación:%s %s\n' "$C_DIM" "$C_RESET" "$LOG_FILE"

phase 'Validando opciones y sistema'
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

if (( VSCODE_THEME )); then
  phase 'Validando VS Code y Python'
  command -v code >/dev/null 2>&1 || command -v code-oss >/dev/null 2>&1 \
    || command -v codium >/dev/null 2>&1 || {
      echo 'No encuentro VS Code, Code OSS ni VSCodium. Instálalo y vuelve a ejecutar --vscode-theme.' >&2
      exit 1
    }
  if ! command -v python3 >/dev/null 2>&1; then
    if (( INSTALL_PACKAGES )); then
      need_python=1
    else
      echo 'La opción --vscode-theme requiere python3.' >&2
      exit 1
    fi
  fi
fi

if (( INSTALL_PACKAGES )); then
  phase 'Instalando paquetes oficiales con pacman'
  command -v pacman >/dev/null || { echo 'Este instalador requiere Arch Linux/pacman.' >&2; exit 1; }
  mapfile -t packages < <(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$REPO_ROOT/packages/arch.txt")
  if (( VSCODE_THEME )) && [[ "${need_python:-0}" == 1 ]]; then packages+=(python); fi
  sudo pacman -S --needed --noconfirm "${packages[@]}"
fi

phase 'Preparando directorios y respaldos'
mkdir -p "$BACKUP_ROOT" "$WALLPAPER_DIR" "$HOME/.config/hypr" "$HOME/.config/waybar" \
  "$HOME/.config/wofi" "$HOME/.config/ghostty" "$HOME/.config/fastfetch" \
  "$HOME/.config/btop" "$HOME/.config/btop/themes" "$HOME/.config/cava" \
  "$HOME/.config/kitty" \
  "$HOME/.config/zsh" "$HOME/.local/share"

if [[ ! -s "$HOME/.config/ghostty/background-opacity" ]]; then
  printf 'background-opacity = 0.70\n' > "$HOME/.config/ghostty/background-opacity"
fi
if [[ ! -s "$HOME/.config/kitty/background-opacity.conf" ]]; then
  printf 'background_opacity 1.0\n' > "$HOME/.config/kitty/background-opacity.conf"
fi
if [[ ! -s "$HOME/.config/hypr/terminal-blur.conf" ]]; then
  printf '%s\n' 'windowrule = no_blur on, match:class ^(kitty|ghostty|com.mitchellh.ghostty)$' \
    > "$HOME/.config/hypr/terminal-blur.conf"
fi

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
phase 'Instalando wallpapers y preparando el tema'
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
phase 'Enlazando configuraciones del escritorio'
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
phase 'Guardando colores activos de Hyprland y terminales'
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
phase 'Instalando Oh My Zsh, plugins y temas de prompt'
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
phase 'Preparando lockscreen y SDDM'
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

phase 'Activando servicios de usuario y red'
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null \
  || printf '%sAviso:%s no pude activar los servicios de audio del usuario.\n' "$C_YELLOW" "$C_RESET"
sudo systemctl enable --now NetworkManager.service 2>/dev/null \
  || printf '%sAviso:%s no pude activar NetworkManager.\n' "$C_YELLOW" "$C_RESET"

if (( SET_DEFAULT_SHELL )); then
  phase 'Configurando Zsh como shell de inicio de sesión'
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

if (( VSCODE_THEME )); then
  phase 'Aplicando la paleta de VS Code'
  touch "$HOME/.config/hypr/vscode-theme-enabled"
  python3 "$REPO_ROOT/scripts/set-vscode-theme.py" "$THEME"
fi

printf '\nInstalación lista. Tema inicial: %s\nRespaldo de configuraciones previas: %s\n' "$THEME" "$BACKUP_ROOT"
printf 'Log completo: %s\n' "$LOG_FILE"
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
