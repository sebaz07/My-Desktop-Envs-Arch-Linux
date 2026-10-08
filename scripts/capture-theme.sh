#!/usr/bin/env bash
set -euo pipefail

script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"
custom_root="$repo_root/dotfiles/themes/custom"
theme_id="${1:-}"
shift || true
display_name="$theme_id"
wallpaper_arg=""

usage() {
    cat <<'USAGE'
Uso: ./scripts/capture-theme.sh ID [--name NOMBRE] [--wallpaper ARCHIVO]

Captura los colores actuales de Waybar, Wofi, Ghostty, Kitty, Fastfetch,
Cava, btop y Powerlevel10k cuando están disponibles. Intenta detectar el
wallpaper de Hyprpaper; usa --wallpaper si no puede detectarlo.
USAGE
}

[[ -n "$theme_id" ]] || { usage >&2; exit 2; }
if [[ "$theme_id" == -h || "$theme_id" == --help ]]; then usage; exit 0; fi
[[ "$theme_id" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
    echo 'ID inválido: usa minúsculas, números y guiones.' >&2
    exit 2
}
case "$theme_id" in
    liberty|johan-neon|arch-blue|skull-teal|dusk-city|neon-void|amber-shibuya)
        printf 'Ese ID pertenece a un tema integrado: %s\n' "$theme_id" >&2
        exit 2
        ;;
esac

while (($#)); do
    case "$1" in
        --name) display_name="${2:?Falta nombre para mostrar}"; shift 2 ;;
        --wallpaper) wallpaper_arg="${2:?Falta ruta del wallpaper}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Opción desconocida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

destination="$custom_root/$theme_id"
[[ ! -e "$destination" && ! -L "$destination" ]] || { printf 'Ya existe el tema: %s\n' "$destination" >&2; exit 1; }
mkdir -p "$custom_root"
tmp="$(mktemp -d "$custom_root/.capture-$theme_id.XXXXXX")"
cleanup() { [[ -d "$tmp" ]] && rm -rf -- "$tmp"; }
trap cleanup EXIT

copy_if_file() {
    local source="$1" target="$2"
    if [[ -f "$source" && -s "$source" ]]; then
        cp -L -- "$source" "$tmp/$target"
        printf 'captured %s <- %s\n' "$target" "$source" >> "$tmp/captured.txt"
        return 0
    fi
    return 1
}

copy_if_file "$HOME/.config/waybar/style.css" waybar.css || true
copy_if_file "$HOME/.config/wofi/style.css" wofi.css || true
copy_if_file "$HOME/.config/kitty/current-theme.conf" kitty.conf || {
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
        awk '/^(background|foreground|selection_background|selection_foreground|selection_text|cursor|cursor_text_color|color[0-9]+)[[:space:]]/ { print }' \
            "$HOME/.config/kitty/kitty.conf" > "$tmp/kitty.conf"
        if [[ -s "$tmp/kitty.conf" ]]; then
            printf 'captured kitty.conf from kitty.conf colors\n' >> "$tmp/captured.txt"
        else
            rm -f -- "$tmp/kitty.conf"
        fi
    fi
}
copy_if_file "$HOME/.config/fastfetch/config.jsonc" fastfetch.jsonc || true
if [[ -s "$tmp/fastfetch.jsonc" ]] && ! grep -Eq '"modules"[[:space:]]*:' "$tmp/fastfetch.jsonc"; then
    rm -f -- "$tmp/fastfetch.jsonc"
    sed -i '/^captured fastfetch.jsonc /d' "$tmp/captured.txt"
    echo 'Fastfetch no define modules; se usará la config completa de Liberty como respaldo.' >&2
fi
copy_if_file "$HOME/.config/cava/config" cava.conf || true
copy_if_file "$HOME/.p10k.zsh" p10k.zsh || true

if [[ -f "$HOME/.config/ghostty/current-theme" ]]; then
    copy_if_file "$HOME/.config/ghostty/current-theme" ghostty || true
elif command -v ghostty >/dev/null 2>&1; then
    ghostty +show-config 2>/dev/null | awk -F ' = ' \
        '/^(background|foreground|selection-foreground|selection-background|palette|cursor-color|cursor-text|cursor-opacity|background-opacity|background-opacity-cells|background-blur|font-family|font-size|window-padding-x|window-padding-y) =/ { print }' \
        > "$tmp/ghostty"
    [[ -s "$tmp/ghostty" ]] && printf 'captured ghostty colors from effective config\n' >> "$tmp/captured.txt"
fi

btop_conf="$HOME/.config/btop/btop.conf"
if [[ -f "$btop_conf" ]]; then
    btop_theme="$(sed -n 's/^[[:space:]]*color_theme[[:space:]]*=[[:space:]]*"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' "$btop_conf" | head -n1)"
    if [[ -n "$btop_theme" ]]; then
        case "$btop_theme" in
            /*) btop_source="$btop_theme" ;;
            *) btop_source="$HOME/.config/btop/themes/$btop_theme"
               [[ -f "$btop_source" ]] || btop_source="/usr/share/btop/themes/$btop_theme" ;;
        esac
        if [[ -f "$btop_source" && -s "$btop_source" ]]; then
            cp -L -- "$btop_source" "$tmp/btop.theme"
            printf 'captured btop.theme <- %s\n' "$btop_source" >> "$tmp/captured.txt"
        fi
    fi
fi

wallpaper="$wallpaper_arg"
if [[ -z "$wallpaper" ]] && command -v hyprctl >/dev/null 2>&1; then
    wallpaper="$(hyprctl hyprpaper listactive 2>/dev/null | sed -n 's/.*image: //p' | head -n1)"
fi
if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    echo 'No encontré un wallpaper estático activo. Indica --wallpaper /ruta/al/archivo.' >&2
    exit 1
fi
wallpaper_name="${wallpaper##*/}"
[[ "$wallpaper_name" == *.* ]] || { echo 'El wallpaper necesita una extensión reconocida.' >&2; exit 1; }
extension="${wallpaper_name##*.}"
case "${extension,,}" in
    jpg|jpeg|png|webp) ;;
    *) printf 'Formato de wallpaper no admitido: %s\n' "$extension" >&2; exit 1 ;;
esac
cp -L -- "$wallpaper" "$tmp/wallpaper.$extension"
printf 'captured wallpaper.%s <- %s\n' "$extension" "$wallpaper" >> "$tmp/captured.txt"

border=""
if [[ -f "$HOME/.config/hypr/theme.conf" ]]; then
    border="$(sed -n 's/^[[:space:]]*col\.active_border[[:space:]]*=[[:space:]]*//p' "$HOME/.config/hypr/theme.conf" | head -n1)"
fi
if [[ -z "$border" && -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    border="$(sed -n 's/^[[:space:]]*col\.active_border[[:space:]]*=[[:space:]]*//p' "$HOME/.config/hypr/hyprland.conf" | head -n1)"
fi
border="${border:-rgba(31b7ffff) rgba(9f9ce8ff) 45deg}"
[[ "$border" =~ ^[[:space:]a-zA-Z0-9#(),.%_-]+$ ]] || border='rgba(31b7ffff) rgba(9f9ce8ff) 45deg'
printf '%s\n' "$border" > "$tmp/theme.conf"
printf 'name=%s\n' "$display_name" > "$tmp/metadata"

if [[ ! -s "$tmp/waybar.css" || ! -s "$tmp/wofi.css" || ! -s "$tmp/ghostty" ]]; then
    echo 'Capturé el wallpaper, pero faltan estilos base de Waybar, Wofi o Ghostty.' >&2
    echo 'Instala/configura esas aplicaciones primero y vuelve a ejecutar la captura.' >&2
    exit 1
fi

ghostty_hex() {
    local key="$1" fallback="$2" value
    value="$(sed -n "s/^$key = #\{0,1\}\([[:xdigit:]]\{6\}\).*$/\1/p" "$tmp/ghostty" | head -n1)"
    [[ "$value" =~ ^[[:xdigit:]]{6}$ ]] || value="$fallback"
    printf '#%s' "$value"
}
bg="$(ghostty_hex background 10121c)"
fg="$(ghostty_hex foreground e8efff)"
primary="$(sed -n 's/^palette = 4=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
secondary="$(sed -n 's/^palette = 5=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
muted="$(sed -n 's/^palette = 8=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
green="$(sed -n 's/^palette = 2=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
primary="${primary:-#89b4fa}"
secondary="${secondary:-#cba6f7}"
muted="${muted:-#818ba9}"
green="${green:-#a6e3a1}"
surface="$(ghostty_hex selection-background 252b40)"
red="$(sed -n 's/^palette = 1=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
yellow="$(sed -n 's/^palette = 3=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
blue="$(sed -n 's/^palette = 4=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
magenta="$(sed -n 's/^palette = 5=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
cyan="$(sed -n 's/^palette = 6=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
type_color="$(sed -n 's/^palette = 14=#\{0,1\}\([[:xdigit:]]\{6\}\).*$/#\1/p' "$tmp/ghostty" | head -n1)"
red="${red:-#f38ba8}"; yellow="${yellow:-#f9e2af}"; blue="${blue:-$primary}"
magenta="${magenta:-$secondary}"; cyan="${cyan:-#94e2d5}"; type_color="${type_color:-$primary}"
cat > "$tmp/vscode-colors.json" <<JSON
{
  "background": "$bg", "foreground": "$fg", "surface": "$surface",
  "primary": "$primary", "secondary": "$secondary", "muted": "$muted",
  "string": "$green", "type": "$type_color", "visual": "$surface",
  "red": "$red", "green": "$green", "yellow": "$yellow", "blue": "$blue",
  "magenta": "$magenta", "cyan": "$cyan"
}
JSON
printf 'captured vscode-colors.json from Ghostty palette\n' >> "$tmp/captured.txt"
cat > "$tmp/nvim-theme.lua" <<LUA
return {
  Normal = { fg = "$fg", bg = "none" },
  NormalNC = { fg = "$fg", bg = "none" },
  NormalFloat = { fg = "$fg", bg = "$bg" },
  FloatBorder = { fg = "$secondary", bg = "$bg" },
  WinSeparator = { fg = "$primary" },
  CursorLine = { bg = "$surface" },
  CursorLineNr = { fg = "$primary", bold = true },
  LineNr = { fg = "$muted" },
  Comment = { fg = "$muted", italic = true },
  String = { fg = "$green" },
  Function = { fg = "$primary" },
  Keyword = { fg = "$secondary" },
  Type = { fg = "$primary" },
  Visual = { bg = "$surface" },
  ["@function"] = { fg = "$primary" },
  ["@keyword"] = { fg = "$secondary" },
  ["@type"] = { fg = "$primary" },
}
LUA

mv -- "$tmp" "$destination"
trap - EXIT
printf 'Tema capturado: %s (%s)\n' "$display_name" "$theme_id"
printf 'Ruta: %s\n' "$destination"
printf 'Archivos recogidos:\n'
sed 's/^/  - /' "$destination/captured.txt"
printf '\nRevisa el contenido antes de publicar: una configuración Fastfetch o un prompt personalizado puede incluir comandos propios.\n'
