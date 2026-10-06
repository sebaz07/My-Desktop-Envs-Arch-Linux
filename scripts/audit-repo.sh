#!/usr/bin/env bash
set -uo pipefail

script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"
cd "$repo_root"
live=0
if (($#)); then
    [[ "$#" -eq 1 && "$1" == --live ]] || { echo 'Uso: ./scripts/audit-repo.sh [--live]' >&2; exit 2; }
    live=1
fi
errors=0
warnings=0

fail() { printf 'ERROR: %s\n' "$*" >&2; ((errors += 1)); }
warn() { printf 'AVISO: %s\n' "$*" >&2; ((warnings += 1)); }
ok() { printf 'OK: %s\n' "$*"; }
need_file() { [[ -s "$1" ]] || fail "falta o está vacío: $1"; }

declare -A wallpaper=(
    [liberty]=liberty.jpg
    [johan-neon]=johan-neon.png
    [arch-blue]=arch-blue.png
    [skull-teal]=skull.png
    [dusk-city]=pixel-dusk-city.png
)
declare -A waybar=(
    [liberty]=liberty.css
    [johan-neon]=johan-neon.css
    [arch-blue]=arch-blue.css
    [skull-teal]=skull-amber.css
    [dusk-city]=dusk-city.css
)
declare -A prompt=(
    [liberty]=liberty.p10k.zsh
    [johan-neon]=johan-neon.p10k.zsh
    [arch-blue]=kushal-arch-blue.p10k.zsh
    [skull-teal]=skull-teal.p10k.zsh
    [dusk-city]=dusk-city.p10k.zsh
)
themes=(liberty johan-neon arch-blue skull-teal dusk-city)

for theme in "${themes[@]}"; do
    need_file "assets/wallpapers/${wallpaper[$theme]}"
    need_file "dotfiles/waybar/themes/${waybar[$theme]}"
    need_file "dotfiles/wofi/themes/$theme.css"
    need_file "dotfiles/ghostty/themes/$theme"
    need_file "dotfiles/kitty/themes/$theme.conf"
    need_file "dotfiles/fastfetch/themes/$theme.jsonc"
    need_file "dotfiles/cava/themes/$theme.conf"
    need_file "dotfiles/btop/themes/$theme.theme"
    need_file "dotfiles/zsh/themes/${prompt[$theme]}"
    rg -q '"modules"[[:space:]]*:' "dotfiles/fastfetch/themes/$theme.jsonc" \
        || fail "Fastfetch no define modules para $theme"
    rg -Fq "$theme" dotfiles/nvim/lua/chadrc.lua \
        || fail "NvChad no define una paleta para $theme"
done
rg -q 'nvim-theme\.lua' dotfiles/nvim/lua/chadrc.lua \
    || fail 'NvChad no carga la paleta de temas capturados'

rg -q '^config-file = ~/.config/ghostty/current-theme$' dotfiles/ghostty/config \
    || fail 'Ghostty debe cargar el tema con config-file y la ruta current-theme'
rg -q '^bind = \$mainMod, T, exec, ~/.config/hypr/scripts/theme-switcher.sh$' dotfiles/hypr/hyprland.conf \
    || fail 'falta Super+T para el selector'
rg -q '^bind = \$mainMod, Q, killactive$' dotfiles/hypr/hyprland.conf \
    || fail 'falta Super+Q para cerrar ventanas'
rg -q '^bind = SUPER, W, killactive$' dotfiles/hypr/hyprland.conf \
    || fail 'falta Super+W para cerrar ventanas'
for binding in \
    'bind = $mainMod, Return, exec, $terminal' \
    'bind = $mainMod, M, exit' \
    'bind = $mainMod, E, exec, $fileManager' \
    'bind = $mainMod, Space, exec, $menu' \
    'bind = $mainMod, V, togglefloating' \
    'bind = $mainMod, F, fullscreen' \
    'bind = $mainMod, L, exec, ~/.local/share/quickshell-lockscreen/lock.sh' \
    'bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy' \
    'bind = , Print, exec, grim - | wl-copy' \
    'bindel = ,XF86AudioRaiseVolume,exec,wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+' \
    'bindel = ,XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-' \
    'bindl = ,XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle' \
    'bindel = ,XF86MonBrightnessUp,exec,brightnessctl set 5%+' \
    'bindel = ,XF86MonBrightnessDown,exec,brightnessctl set 5%-'; do
    grep -Fq "$binding" dotfiles/hypr/hyprland.conf || fail "falta el atajo: $binding"
done
for number in {1..9}; do
    grep -Fq "bind = \$mainMod, $number, workspace, $number" dotfiles/hypr/hyprland.conf \
        || fail "falta el atajo de workspace Super+$number"
    grep -Fq "bind = \$mainMod SHIFT, $number, movetoworkspace, $number" dotfiles/hypr/hyprland.conf \
        || fail "falta el atajo de mover ventana a workspace $number"
done
grep -Fq 'bind = $mainMod, 0, workspace, 10' dotfiles/hypr/hyprland.conf \
    || fail 'falta el workspace 10 (Super+0)'
grep -Fq 'bind = $mainMod SHIFT, 0, movetoworkspace, 10' dotfiles/hypr/hyprland.conf \
    || fail 'falta mover al workspace 10 (Super+Shift+0)'
rg -q 'readlink -f -- "\$\{BASH_SOURCE\[0\]\}"' dotfiles/hypr/scripts/theme-switcher.sh \
    || fail 'el selector debe resolver su ruta física antes de calcular el repo'
rg -q '^source = ~/.config/hypr/theme.conf$' dotfiles/hypr/hyprland.conf \
    || fail 'Hyprland debe leer el borde activo desde theme.conf'
if rg -q 'sed -i .*DOTFILES/hypr/hyprland.conf' install.sh; then
    fail 'el instalador modifica un archivo fuente del repo'
fi
need_file assets/sddm/LICENSE.Qylock
need_file assets/sddm/pixel-dusk-city/bg.mp4
need_file assets/wallpapers/pixel-dusk-city.png
rg -q '^mpvpaper$' packages/aur.txt || fail 'mpvpaper debe documentarse como paquete AUR opcional'

custom_root=dotfiles/themes/custom
if [[ -d "$custom_root" ]]; then
    while IFS= read -r -d '' dir; do
        for required in theme.conf waybar.css wofi.css ghostty; do
            need_file "$dir/$required"
        done
        compgen -G "$dir/wallpaper.*" >/dev/null || fail "falta wallpaper para $dir"
    done < <(find "$custom_root" -mindepth 1 -maxdepth 1 -type d -print0)
fi

if (( live )); then
    check_live_link() {
        local path="$1" resolved
        resolved="$(readlink -e "$HOME/$path" 2>/dev/null || true)"
        [[ -n "$resolved" ]] || { fail "enlace/configuración activa rota: ~/$path"; return; }
        [[ "$resolved" == "$repo_root"/* ]] || fail "~/$path no apunta a este repo ($resolved)"
    }
    for path in \
        .config/hypr/hyprland.conf .config/hypr/scripts \
        .config/waybar/config .config/waybar/modules.json .config/waybar/style.css \
        .config/wofi/config .config/wofi/style.css \
        .config/ghostty/config .config/ghostty/current-theme .config/ghostty/themes \
        .config/kitty/kitty.conf .config/kitty/current-theme.conf \
        .config/fastfetch/config.jsonc .config/cava/config .config/nvim \
        .zshrc .zshenv .p10k.zsh; do
        check_live_link "$path"
    done
    active_theme="$(cat "$HOME/.config/hypr/current-theme" 2>/dev/null || true)"
    [[ -n "$active_theme" ]] || fail 'falta ~/.config/hypr/current-theme'
    active_key="${active_theme,,}"
    active_key="${active_key%% (*}"
    active_key="${active_key// /-}"
    case "$active_key" in
        liberty-monochrome) active_key=liberty ;;
        skull) active_key=skull-teal ;;
        'dusk-city-animado') active_key=dusk-city ;;
    esac
    custom_active="$repo_root/dotfiles/themes/custom/$active_key"
    expect_live_target() {
        local link="$1" target="$2" actual
        actual="$(readlink -e "$HOME/$link" 2>/dev/null || true)"
        [[ "$actual" == "$target" ]] || fail "~/$link no corresponde al tema activo $active_key"
    }
    if [[ -d "$custom_active" ]]; then
        expect_live_target .config/waybar/style.css "$custom_active/waybar.css"
        expect_live_target .config/wofi/style.css "$custom_active/wofi.css"
        expect_live_target .config/ghostty/current-theme "$custom_active/ghostty"
        [[ -s "$custom_active/kitty.conf" ]] || custom_kitty="$repo_root/dotfiles/kitty/themes/liberty.conf"
        [[ -s "$custom_active/cava.conf" ]] || custom_cava="$repo_root/dotfiles/cava/themes/liberty.conf"
        [[ -s "$custom_active/p10k.zsh" ]] || custom_p10k="$repo_root/dotfiles/zsh/themes/liberty.p10k.zsh"
        if [[ -s "$custom_active/fastfetch.jsonc" ]] \
            && grep -Eq '"modules"[[:space:]]*:' "$custom_active/fastfetch.jsonc"; then
            custom_fastfetch="$custom_active/fastfetch.jsonc"
        else
            custom_fastfetch="$repo_root/dotfiles/fastfetch/themes/liberty.jsonc"
        fi
        expect_live_target .config/kitty/current-theme.conf "${custom_kitty:-$custom_active/kitty.conf}"
        expect_live_target .config/cava/config "${custom_cava:-$custom_active/cava.conf}"
        expect_live_target .p10k.zsh "${custom_p10k:-$custom_active/p10k.zsh}"
        expect_live_target .config/fastfetch/config.jsonc "$custom_fastfetch"
        if [[ -s "$custom_active/nvim-theme.lua" ]]; then
            expect_live_target .config/hypr/nvim-theme.lua "$custom_active/nvim-theme.lua"
        fi
        wallpaper_source="$(find "$custom_active" -maxdepth 1 -type f -name 'wallpaper.*' -print -quit)"
        [[ -n "$wallpaper_source" ]] || fail "falta wallpaper para el tema activo $active_key"
    else
        case "$active_key" in
            liberty|johan-neon|arch-blue|skull-teal|dusk-city) ;;
            *) fail "tema activo desconocido: $active_theme"; active_key=liberty ;;
        esac
        waybar_id="$active_key"
        prompt_id="$active_key"
        [[ "$active_key" != skull-teal ]] || waybar_id=skull-amber
        [[ "$active_key" != arch-blue ]] || prompt_id=kushal-arch-blue
        expect_live_target .config/waybar/style.css "$repo_root/dotfiles/waybar/themes/$waybar_id.css"
        expect_live_target .config/wofi/style.css "$repo_root/dotfiles/wofi/themes/$active_key.css"
        expect_live_target .config/ghostty/current-theme "$repo_root/dotfiles/ghostty/themes/$active_key"
        expect_live_target .config/kitty/current-theme.conf "$repo_root/dotfiles/kitty/themes/$active_key.conf"
        expect_live_target .config/fastfetch/config.jsonc "$repo_root/dotfiles/fastfetch/themes/$active_key.jsonc"
        expect_live_target .config/cava/config "$repo_root/dotfiles/cava/themes/$active_key.conf"
        expect_live_target .p10k.zsh "$repo_root/dotfiles/zsh/themes/$prompt_id.p10k.zsh"
        wallpaper_file="${wallpaper[$active_key]}"
        [[ -s "$HOME/.local/share/wallpapers/$wallpaper_file" ]] || fail "falta wallpaper instalado: $wallpaper_file"
    fi
    grep -Eq '"modules"[[:space:]]*:' "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null \
        || fail 'Fastfetch activo no tiene modules'
    [[ -s "$HOME/.config/hypr/theme.conf" ]] || fail 'falta el borde Hyprland activo'
    [[ -s "$HOME/.config/btop/btop.conf" ]] || fail 'falta la config activa de btop'
    btop_theme="$(sed -n 's/^[[:space:]]*color_theme[[:space:]]*=[[:space:]]*"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' "$HOME/.config/btop/btop.conf" | head -n1)"
    if [[ "$btop_theme" != Default && ! -s "$btop_theme" ]]; then
        fail "btop no encuentra su tema activo: $btop_theme"
    fi
    shell_path="$(getent passwd "$USER" | cut -d: -f7)"
    ghostty_config="$(ghostty +show-config 2>/dev/null || true)"
    if [[ "$shell_path" != *zsh ]] \
        && ! grep -Eq '^command[[:space:]]*=[[:space:]]*/.*zsh$' <<< "$ghostty_config"; then
        fail 'la cuenta no usa Zsh y Ghostty no tiene command apuntando a Zsh'
    fi
    ok 'rutas y archivos del entorno activo apuntan al repo'
fi

if (( errors == 0 )); then
    printf 'Auditoría: sin errores (%d avisos).\n' "$warnings"
    exit 0
fi
printf 'Auditoría: %d errores, %d avisos.\n' "$errors" "$warnings" >&2
exit 1
