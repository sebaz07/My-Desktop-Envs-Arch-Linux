# Crear y mantener temas

El selector vive en `dotfiles/hypr/scripts/theme-switcher.sh`. Cada tema usa un ID en minúsculas; ese ID se guarda en `~/.config/hypr/current-theme` y se aplica también al iniciar Hyprland.

## Archivos por tema

Para un ID como `mi-tema`, crea los recursos correspondientes:

```text
assets/wallpapers/mi-tema.png
 dotfiles/waybar/themes/mi-tema.css
 dotfiles/wofi/themes/mi-tema.css
 dotfiles/ghostty/themes/mi-tema
 dotfiles/kitty/themes/mi-tema.conf
 dotfiles/fastfetch/themes/mi-tema.jsonc
 dotfiles/btop/themes/mi-tema.theme
 dotfiles/cava/themes/mi-tema.conf
 dotfiles/zsh/themes/mi-tema.p10k.zsh
```

Usa una sola paleta coherente en CSS, ANSI, gráficas, launcher y prompt. Mantén los fondos oscuros/translúcidos y el texto con contraste. En Fastfetch incluye siempre `modules`; si se omite, solo se verá el logo.

## Añadirlo al selector

1. Copia el wallpaper a `assets/wallpapers/` con un nombre estable.
2. Añade el ID al `case` de `install.sh`, al menú Wofi y al `case` de `theme-switcher.sh`.
3. En el selector enlaza Waybar, Wofi, Fastfetch, Cava, Kitty y el `.p10k.zsh`; selecciona el tema Ghostty, actualiza los bordes de Hyprland y el tema de btop.
4. Para NvChad, agrega un bloque condicional en `dotfiles/nvim/lua/chadrc.lua` que consulte `current-theme`.
5. Añade una fila a la tabla de `README.md` y describe los atajos/recursos si cambian.

## Validación manual

```bash
bash -n install.sh dotfiles/hypr/scripts/theme-switcher.sh
fastfetch --config dotfiles/fastfetch/themes/mi-tema.jsonc --pipe true
```

En una sesión Hyprland, cambia con `Super+T` o aplica directamente:

```bash
~/.config/hypr/scripts/theme-switcher.sh mi-tema
```

Comprueba wallpaper, una sola Waybar, Wofi, Ghostty, Fastfetch y un shell Zsh nuevo. NvChad toma el acento del tema al abrir Neovim.
