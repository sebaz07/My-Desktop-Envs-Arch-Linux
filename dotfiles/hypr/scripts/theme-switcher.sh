#!/usr/bin/env bash
set -euo pipefail

config_dir="$HOME/.config"
script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
repo_root="$(cd -- "$(dirname -- "$script_path")/../../.." && pwd)"
dotfiles="$repo_root/dotfiles"
wallpapers="$HOME/.local/share/wallpapers"
waybar_themes="$dotfiles/waybar/themes"
wofi_themes="$dotfiles/wofi/themes"
zsh_themes="$dotfiles/zsh/themes"
fastfetch_themes="$dotfiles/fastfetch/themes"
btop_themes="$dotfiles/btop/themes"
cava_themes="$dotfiles/cava/themes"
kitty_themes="$dotfiles/kitty/themes"
mkdir -p "$config_dir/fastfetch" "$config_dir/cava" "$config_dir/kitty"
video="$repo_root/assets/sddm/pixel-dusk-city/bg.mp4"
choice="${1:-}"
hypr_instances="$(hyprctl instances 2>/dev/null || true)"
hypr_signature="${HYPRLAND_INSTANCE_SIGNATURE:-$(sed -n 's/^instance \([^:]*\):/\1/p' <<<"$hypr_instances" | head -n1)}"
hypr_socket="$(sed -n 's/^[[:space:]]*wl socket: //p' <<<"$hypr_instances" | head -n1)"
[[ -n "$hypr_socket" ]] && export WAYLAND_DISPLAY="$hypr_socket"
export HYPRLAND_INSTANCE_SIGNATURE="$hypr_signature"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
hyprctl_session() {
    HYPRLAND_INSTANCE_SIGNATURE="$hypr_signature" hyprctl "$@"
}
monitor_name="$(hyprctl_session monitors | sed -n 's/^Monitor \([^ ]*\).*/\1/p' | head -n1)"
border_colors='rgba(31b7ffff) rgba(9f9ce8ff) 45deg'

set_btop_theme() {
    local theme_path="$1" show_theme_bg="$2" btop_config="$HOME/.config/btop/btop.conf"
    [[ -f "$btop_config" ]] || return 0
    sed -i "s|^color_theme = .*|color_theme = \"$theme_path\"|" "$btop_config"
    sed -i "s|^theme_background = .*|theme_background = $show_theme_bg|" "$btop_config"
}

link_if_present() {
    local source="$1" destination="$2"
    [[ -s "$source" ]] || return 0
    ln -sfn "$source" "$destination"
}

link_with_fallback() {
    local source="$1" fallback="$2" destination="$3"
    if [[ -s "$source" ]]; then
        ln -sfn "$source" "$destination"
    else
        ln -sfn "$fallback" "$destination"
    fi
}

if [[ "$choice" == --current ]]; then
    choice="$(cat "$config_dir/hypr/current-theme" 2>/dev/null || printf 'Dusk City (animado)')"
fi
if [[ -z "$choice" ]]; then
    custom_choices=""
    while IFS= read -r custom_dir; do
        [[ -d "$custom_dir" ]] || continue
        custom_id="${custom_dir##*/}"
        custom_name="$(sed -n 's/^name=//p' "$custom_dir/metadata" 2>/dev/null | head -n1)"
        custom_name="${custom_name:-$custom_id}"
        custom_choices+="${custom_choices:+$'\n'}custom:$custom_id — $custom_name"
    done < <(find "$dotfiles/themes/custom" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort)
    choice="$(printf 'Dusk City (animado)\nSkull (verde agua)\nArch Blue\nJohan Neon\nLiberty\n%s' "$custom_choices" | sed '/^$/d' | wofi --dmenu --prompt 'Tema')" || exit 0
fi

if [[ "$choice" == custom:* ]]; then
    choice="${choice#custom:}"
    choice="${choice%% — *}"
fi
custom_theme="$dotfiles/themes/custom/$choice"
if [[ -d "$custom_theme" && -s "$custom_theme/theme.conf" \
    && -s "$custom_theme/waybar.css" && -s "$custom_theme/wofi.css" \
    && -s "$custom_theme/ghostty" ]] && compgen -G "$custom_theme/wallpaper.*" >/dev/null; then
    wallpaper_file=""
    for candidate in "$custom_theme"/wallpaper.*; do
        [[ -f "$candidate" ]] && { wallpaper_file="$candidate"; break; }
    done
    if [[ -n "$wallpaper_file" ]]; then
        pkill -x mpvpaper 2>/dev/null || true
        if ! pgrep -x hyprpaper >/dev/null; then hyprpaper >/dev/null 2>&1 & sleep 0.8; fi
        hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpaper_file"
    fi
    link_if_present "$custom_theme/waybar.css" "$config_dir/waybar/style.css"
    link_if_present "$custom_theme/wofi.css" "$config_dir/wofi/style.css"
    link_if_present "$custom_theme/ghostty" "$config_dir/ghostty/current-theme"
    link_with_fallback "$custom_theme/kitty.conf" "$kitty_themes/liberty.conf" "$config_dir/kitty/current-theme.conf"
    if [[ -s "$custom_theme/fastfetch.jsonc" ]] \
        && grep -Eq '"modules"[[:space:]]*:' "$custom_theme/fastfetch.jsonc"; then
        ln -sfn "$custom_theme/fastfetch.jsonc" "$config_dir/fastfetch/config.jsonc"
    else
        ln -sfn "$fastfetch_themes/liberty.jsonc" "$config_dir/fastfetch/config.jsonc"
    fi
    link_with_fallback "$custom_theme/cava.conf" "$cava_themes/liberty.conf" "$config_dir/cava/config"
    link_with_fallback "$custom_theme/p10k.zsh" "$zsh_themes/liberty.p10k.zsh" "$HOME/.p10k.zsh"
    link_if_present "$custom_theme/nvim-theme.lua" "$config_dir/hypr/nvim-theme.lua"
    if [[ -s "$custom_theme/btop.theme" ]]; then
        set_btop_theme "$custom_theme/btop.theme" false
    else
        set_btop_theme Default false
    fi
    border_colors="$(<"$custom_theme/theme.conf")"
else
case "$choice" in
    'Dusk City'|'Dusk City (animado)'|dusk|dusk-city)
        pkill -x hyprpaper 2>/dev/null || true
        pkill -x mpvpaper 2>/dev/null || true
        if command -v mpvpaper >/dev/null && [[ -f "$video" ]]; then
            mpvpaper -p -o 'no-audio loop-file=inf' ALL "$video" >/dev/null 2>&1 &
        else
            if ! pgrep -x hyprpaper >/dev/null; then hyprpaper >/dev/null 2>&1 & sleep 0.8; fi
            hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpapers/pixel-dusk-city.png"
        fi
        ln -sfn "$waybar_themes/dusk-city.css" "$config_dir/waybar/style.css"
        ln -sfn "$wofi_themes/dusk-city.css" "$config_dir/wofi/style.css"
        ln -sfn "$dotfiles/ghostty/themes/dusk-city" "$config_dir/ghostty/current-theme"
        ln -sfn "$zsh_themes/dusk-city.p10k.zsh" "$HOME/.p10k.zsh"
        ln -sfn "$fastfetch_themes/dusk-city.jsonc" "$config_dir/fastfetch/config.jsonc"
        ln -sfn "$cava_themes/dusk-city.conf" "$config_dir/cava/config"
        ln -sfn "$kitty_themes/dusk-city.conf" "$config_dir/kitty/current-theme.conf"
        set_btop_theme "$btop_themes/dusk-city.theme" true
        border_colors='rgba(89dcebff) rgba(f38ba8ff) 45deg'
        ;;
    Skull|skull|'Skull (dorado)'|'Skull (verde agua)'|skull-teal|amber)
        pkill -x mpvpaper 2>/dev/null || true
        if ! pgrep -x hyprpaper >/dev/null; then
            hyprpaper >/dev/null 2>&1 &
            sleep 0.8
        fi
        hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpapers/skull.png"
        ln -sfn "$waybar_themes/skull-amber.css" "$config_dir/waybar/style.css"
        ln -sfn "$wofi_themes/skull-teal.css" "$config_dir/wofi/style.css"
        ln -sfn "$dotfiles/ghostty/themes/skull-teal" "$config_dir/ghostty/current-theme"
        ln -sfn "$zsh_themes/skull-teal.p10k.zsh" "$HOME/.p10k.zsh"
        ln -sfn "$fastfetch_themes/skull-teal.jsonc" "$config_dir/fastfetch/config.jsonc"
        ln -sfn "$cava_themes/skull-teal.conf" "$config_dir/cava/config"
        ln -sfn "$kitty_themes/skull-teal.conf" "$config_dir/kitty/current-theme.conf"
        set_btop_theme "$btop_themes/skull-teal.theme" true
        border_colors='rgba(70d3b5ff) rgba(e8b870ff) 45deg'
        ;;
    'Arch Blue'|arch-blue)
        pkill -x mpvpaper 2>/dev/null || true
        if ! pgrep -x hyprpaper >/dev/null; then
            hyprpaper >/dev/null 2>&1 &
            sleep 0.8
        fi
        hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpapers/arch-blue.png"
        ln -sfn "$waybar_themes/arch-blue.css" "$config_dir/waybar/style.css"
        ln -sfn "$wofi_themes/arch-blue.css" "$config_dir/wofi/style.css"
        ln -sfn "$dotfiles/ghostty/themes/arch-blue" "$config_dir/ghostty/current-theme"
        ln -sfn "$zsh_themes/kushal-arch-blue.p10k.zsh" "$HOME/.p10k.zsh"
        ln -sfn "$fastfetch_themes/arch-blue.jsonc" "$config_dir/fastfetch/config.jsonc"
        ln -sfn "$cava_themes/arch-blue.conf" "$config_dir/cava/config"
        ln -sfn "$kitty_themes/arch-blue.conf" "$config_dir/kitty/current-theme.conf"
        set_btop_theme "$btop_themes/arch-blue.theme" true
        border_colors='rgba(31b7ffff) rgba(9f9ce8ff) 45deg'
        ;;
    'Johan Neon'|johan-neon|johan)
        pkill -x mpvpaper 2>/dev/null || true
        if ! pgrep -x hyprpaper >/dev/null; then
            hyprpaper >/dev/null 2>&1 &
            sleep 0.8
        fi
        hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpapers/johan-neon.png"
        ln -sfn "$waybar_themes/johan-neon.css" "$config_dir/waybar/style.css"
        ln -sfn "$wofi_themes/johan-neon.css" "$config_dir/wofi/style.css"
        ln -sfn "$dotfiles/ghostty/themes/johan-neon" "$config_dir/ghostty/current-theme"
        ln -sfn "$zsh_themes/johan-neon.p10k.zsh" "$HOME/.p10k.zsh"
        ln -sfn "$fastfetch_themes/johan-neon.jsonc" "$config_dir/fastfetch/config.jsonc"
        ln -sfn "$cava_themes/johan-neon.conf" "$config_dir/cava/config"
        ln -sfn "$kitty_themes/johan-neon.conf" "$config_dir/kitty/current-theme.conf"
        set_btop_theme "$btop_themes/johan-neon.theme" false
        border_colors='rgba(00d9ffff) rgba(f02bd4ff) 45deg'
        ;;
    Liberty|liberty|Liberty-Monochrome)
        pkill -x mpvpaper 2>/dev/null || true
        if ! pgrep -x hyprpaper >/dev/null; then
            hyprpaper >/dev/null 2>&1 &
            sleep 0.8
        fi
        hyprctl_session hyprpaper wallpaper "$monitor_name,$wallpapers/liberty.jpg"
        ln -sfn "$waybar_themes/liberty.css" "$config_dir/waybar/style.css"
        ln -sfn "$wofi_themes/liberty.css" "$config_dir/wofi/style.css"
        ln -sfn "$dotfiles/ghostty/themes/liberty" "$config_dir/ghostty/current-theme"
        ln -sfn "$zsh_themes/liberty.p10k.zsh" "$HOME/.p10k.zsh"
        ln -sfn "$fastfetch_themes/liberty.jsonc" "$config_dir/fastfetch/config.jsonc"
        ln -sfn "$cava_themes/liberty.conf" "$config_dir/cava/config"
        ln -sfn "$kitty_themes/liberty.conf" "$config_dir/kitty/current-theme.conf"
        set_btop_theme "$btop_themes/liberty.theme" false
        border_colors='rgba(f2f2f2ff) rgba(888888ff) 45deg'
        ;;
    *)
        printf 'Tema desconocido: %s\n' "$choice" >&2
        exit 2
        ;;
esac
fi

printf 'general {\n    col.active_border = %s\n}\n' "$border_colors" > "$config_dir/hypr/theme.conf"
hyprctl_session keyword general:col.active_border "$border_colors"
if ghostty_pid="$(pgrep -xo ghostty)"; then
    kill -USR2 "$ghostty_pid" 2>/dev/null || true
fi

pkill -x waybar 2>/dev/null || true
sleep 0.2
hyprctl_session dispatch exec waybar >/dev/null
printf '%s\n' "$choice" > "$config_dir/hypr/current-theme"

if [[ -e "$config_dir/hypr/vscode-theme-enabled" ]] && command -v python3 >/dev/null 2>&1; then
    vscode_theme="$choice"
    case "$choice" in
        'Dusk City'|'Dusk City (animado)'|dusk) vscode_theme=dusk-city ;;
        Skull|skull|'Skull (dorado)'|'Skull (verde agua)'|amber) vscode_theme=skull-teal ;;
        'Arch Blue') vscode_theme=arch-blue ;;
        'Johan Neon'|johan) vscode_theme=johan-neon ;;
        Liberty|Liberty-Monochrome) vscode_theme=liberty ;;
    esac
    if ! python3 "$repo_root/scripts/set-vscode-theme.py" "$vscode_theme"; then
        echo 'Aviso: no se pudo sincronizar el tema de VS Code.' >&2
    fi
fi
