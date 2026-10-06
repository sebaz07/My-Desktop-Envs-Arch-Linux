# Crear y mantener temas

El selector vive en `dotfiles/hypr/scripts/theme-switcher.sh`. Cada tema usa un ID en minúsculas; ese ID se guarda en `~/.config/hypr/current-theme` y se aplica también al iniciar Hyprland.

VS Code puede seguir la misma paleta sin instalar una extensión de tema. Actívalo al instalar con `./install.sh --theme liberty --vscode-theme`; el script crea `~/.config/hypr/vscode-theme-enabled` y aplica colores de interfaz, editor, terminal y sintaxis mediante `workbench.colorCustomizations` y `editor.tokenColorCustomizations`. Se preservan otras opciones del usuario, se crea una copia inicial de `settings.json` y VS Code actualiza los colores en vivo. Sin `--vscode-theme`, el instalador y `Super+T` no escriben en VS Code. Esta opción requiere VS Code/Code OSS/VSCodium y Python 3; con `--no-packages`, deben estar instalados previamente.

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
2. Añade el ID al `case` de `install.sh`, al menú Wofi y al `case` de `theme-switcher.sh`. Para importar una configuración existente, usa el capturador de la sección siguiente y evita editar esos `case`.
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

## Auditar los temas existentes

Desde la raíz del repo:

```bash
./scripts/audit-repo.sh
```

La auditoría comprueba que cada tema integrado tenga wallpaper, hojas de estilo, tema Ghostty/Kitty, archivos Fastfetch/Cava/btop/Powerlevel10k, y que Fastfetch incluya `modules`. También revisa Ghostty `config-file`, `Super+T`, `Super+Q`, `Super+W`, el borde dinámico de Hyprland, el recurso de SDDM y la resolución de rutas del selector.

## Capturar la apariencia de otro Arch como tema

En el equipo que ya tiene la apariencia configurada, clona este repo y ejecuta:

```bash
./scripts/capture-theme.sh mi-tema --name "Mi tema"
```

El capturador intenta detectar el wallpaper activo de Hyprpaper. Si usa otro gestor o una animación, proporciona un wallpaper estático (`jpg`, `jpeg`, `png` o `webp`):

```bash
./scripts/capture-theme.sh mi-tema --name "Mi tema" --wallpaper ~/Pictures/fondo.png
```

Recoge CSS de Waybar/Wofi, colores efectivos de Ghostty, tema de Kitty, configuraciones de Fastfetch y Cava, tema btop, prompt Powerlevel10k cuando existan, el borde activo de Hyprland y el wallpaper. Genera además paletas para NvChad y VS Code desde los colores ANSI de Ghostty. El tema queda en `dotfiles/themes/custom/mi-tema`, aparece en `Super+T` y se puede instalar en otra máquina con:

```bash
./install.sh --theme mi-tema
```

Para sincronizar VS Code en esa máquina añade `--vscode-theme`.

La captura no importa atajos, paquetes, servicios, configuración completa de Hyprland, SDDM ni archivos arbitrarios de `~/.config`; esos datos pueden ser específicos del equipo o contener secretos. Los atajos siguen siendo parte del perfil base. Revisa los archivos recogidos antes de hacer commit, especialmente Fastfetch y Powerlevel10k si contienen comandos o rutas privadas. La captura requiere Waybar, Wofi, Ghostty y un wallpaper estático; si no detecta el fondo, pasa `--wallpaper`.
