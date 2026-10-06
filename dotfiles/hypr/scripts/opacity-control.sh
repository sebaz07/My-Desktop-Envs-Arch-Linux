#!/usr/bin/env bash
set -euo pipefail

command -v wofi >/dev/null || { echo 'Wofi no está instalado.' >&2; exit 1; }
control="$(printf 'Opacidad del fondo de terminal\nBlur del escritorio detrás de terminales\n' \
    | wofi --dmenu --prompt '¿Qué quieres ajustar?')" || exit 0
[[ -n "$control" ]] || exit 0

if [[ "$control" == 'Blur del escritorio detrás de terminales' ]]; then
    blur_choice="$(printf 'Fondo nítido\nFondo difuminado\n' \
        | wofi --dmenu --prompt 'Efecto detrás de los terminales')" || exit 0
    [[ -n "$blur_choice" ]] || exit 0
    blur_config="$HOME/.config/hypr/terminal-blur.conf"
    mkdir -p "${blur_config%/*}"
    tmp="$(mktemp "${blur_config}.XXXXXX")"
    trap '[[ -n "${tmp:-}" && -e "$tmp" ]] && rm -f -- "$tmp"' EXIT
    if [[ "$blur_choice" == 'Fondo nítido' ]]; then
        printf '%s\n' 'windowrule = no_blur on, match:class ^(kitty|ghostty|com.mitchellh.ghostty)$' > "$tmp"
    else
        printf '%s\n' '# Hereda el blur general configurado en Hyprland.' > "$tmp"
    fi
    chmod 0644 "$tmp"
    mv -f -- "$tmp" "$blur_config"
    tmp=''
    if hyprctl reload; then
        command -v notify-send >/dev/null 2>&1 && notify-send 'Fondo de terminales' "$blur_choice" || true
    else
        echo 'Guardé el efecto. Hyprland lo aplicará cuando recargue su configuración.' >&2
    fi
    exit 0
fi

terminals=()
if command -v ghostty >/dev/null 2>&1; then terminals+=(Ghostty); fi
if command -v kitty >/dev/null 2>&1; then terminals+=(Kitty); fi
((${#terminals[@]})) || { echo 'No encontré Ghostty ni Kitty.' >&2; exit 1; }
terminal="$(printf '%s\n' "${terminals[@]}" | wofi --dmenu --prompt '¿Qué terminal quieres ajustar?')" || exit 0
[[ -n "$terminal" ]] || exit 0

case "$terminal" in
    Ghostty)
        command -v ghostty >/dev/null || { echo 'Ghostty no está instalado.' >&2; exit 1; }
        config="$HOME/.config/ghostty/background-opacity"
        default='0.70'
        key='background-opacity'
        ;;
    Kitty)
        command -v kitty >/dev/null || { echo 'Kitty no está instalado.' >&2; exit 1; }
        config="$HOME/.config/kitty/background-opacity.conf"
        default='1.0'
        key='background_opacity'
        ;;
    *) echo "Terminal inválido: $terminal" >&2; exit 2 ;;
esac

if [[ ! -s "$config" ]]; then
    mkdir -p "${config%/*}"
    if [[ "$terminal" == Ghostty ]]; then
        printf '%s = %s\n' "$key" "$default" > "$config"
    else
        printf '%s %s\n' "$key" "$default" > "$config"
    fi
fi

choices=""
for ((percent_choice = 100; percent_choice >= 5; percent_choice -= 5)); do
    label="${percent_choice}%"
    if (( percent_choice == 100 )); then label+=' — fondo opaco'; fi
    choices+="$label"$'\n'
done
choices+='0% — fondo totalmente transparente'
selection="$(printf '%s\n' "$choices" | wofi --dmenu --prompt "Opacidad del fondo $terminal")" || exit 0
[[ -n "$selection" ]] || exit 0
percent="${selection%%\%*}"
[[ "$percent" =~ ^([0-9]|[1-9][0-9]|100)$ ]] || { echo "Opacidad inválida: $selection" >&2; exit 2; }
value="$(awk -v n="$percent" 'BEGIN { printf "%.2f", n / 100 }')"

tmp="$(mktemp "${config}.XXXXXX")"
trap '[[ -n "${tmp:-}" && -e "$tmp" ]] && rm -f -- "$tmp"' EXIT
if [[ "$terminal" == Ghostty ]]; then
    printf '%s = %s\n' "$key" "$value" > "$tmp"
else
    printf '%s %s\n' "$key" "$value" > "$tmp"
fi
chmod 0644 "$tmp"
mv -f -- "$tmp" "$config"
tmp=''

if [[ "$terminal" == Ghostty ]]; then
    # Ghostty on Linux reloads config on SIGUSR2; this leaves glyph opacity untouched.
    if ghostty_pid="$(pgrep -xo ghostty)"; then
        kill -USR2 "$ghostty_pid"
    elif systemctl --user is-active --quiet app-com.mitchellh.ghostty.service; then
        systemctl --user reload app-com.mitchellh.ghostty.service
    fi
else
    # Kitty reloads its configuration on SIGUSR1.
    if kitty_pid="$(pgrep -xo kitty)"; then kill -USR1 "$kitty_pid"; fi
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Fondo de $terminal" "Opacidad: ${percent}% · el texto conserva su opacidad" || true
fi
