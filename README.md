# My Desktop Envs — Arch Linux / Hyprland

Configuración reproducible del entorno Arch Linux de sebaz07: Hyprland, Waybar, Wofi, SDDM, Ghostty/Kitty, Zsh + Oh My Zsh, Fastfetch, btop, Cava y NvChad. Incluye wallpapers y selector de temas coordinado.

## Instalación rápida

Clona el repositorio y ejecuta el instalador con tu usuario normal:

```bash
git clone https://github.com/sebaz07/My-Desktop-Envs-Arch-Linux.git
cd My-Desktop-Envs-Arch-Linux
./install.sh --theme liberty --enable-sddm --set-default-shell
```

Al ejecutarlo sin argumentos desde una terminal, aparece el menú interactivo `SEBAZ ARCH LINUX`. Ahí puedes seleccionar tema y alternar paquetes, SDDM, shell Zsh y sincronización de VS Code. Usa `./install.sh --menu` para abrirlo explícitamente; los argumentos existentes siguen funcionando sin menú.

Para sincronizar también los colores de VS Code (opcional):

```bash
./install.sh --theme liberty --vscode-theme
```

El instalador instala paquetes oficiales de Arch, respalda configuraciones existentes en `~/.local/state/my-desktop-envs/backups/`, enlaza los dotfiles, instala Oh My Zsh/plugins, instala los wallpapers, prepara el lockscreen Qylock y configura el tema SDDM Pixel Dusk City. SDDM se habilita solo si indicas `--enable-sddm`; activar un display manager puede reemplazar el inicio gráfico actual.

Opciones:

- `--theme liberty|johan-neon|arch-blue|skull-teal|dusk-city|neon-void|amber-shibuya`: tema inicial (por defecto `liberty`).
- `--enable-sddm`: instala el tema SDDM incluido y habilita el servicio.
- `--set-default-shell`: hace Zsh el shell de inicio de sesión.
- `--vscode-theme`: activa y aplica en VS Code los colores del tema elegido; `Super+T` los sincroniza después.
- `--no-packages`: omite `pacman`, para reutilizar una instalación existente.
- `--menu`: abre el menú interactivo antes de instalar; sin argumentos se abre automáticamente en una terminal.
- `--no-menu`: omite el menú automático.

Después de instalar, cierra sesión y elige **Hyprland** en SDDM. El tema guardado se vuelve a aplicar al entrar.

## Temas disponibles

| ID | Wallpaper | Colores |
| --- | --- | --- |
| `dusk-city` | Pixel Dusk City animado (y PNG de respaldo) | Azul noche, cian, coral |
| `skull-teal` | `skull.png` | Verde agua, oro |
| `arch-blue` | `arch-blue.png` | Azul eléctrico, azul cielo |
| `johan-neon` | `johan-neon.png` | Cian eléctrico, magenta |
| `johan2` | `wallpaper.png` | Carbón, azul hielo, sepia |
| `liberty` | `liberty.jpg` | Blanco y negro, grises |
| `scarlet-lycoris` | `wallhaven-vp2qv3.png` | Rojo amapola, carmesí, negro |
| `pomo-sunset` | `wallhaven-pomo69.jpg` | Azul noche, coral, lavanda |
| `glitch-dream` | `background.png` | Cian, azul hielo, lavanda, rosa |
| `neon-void` | `neon-void.png` | Cian eléctrico, violeta, magenta |
| `amber-shibuya` | `amber-shibuya.png` | Ámbar, naranja, negro urbano |

Pulsa **Super+T** para abrir el selector. El tema sincroniza wallpaper, Waybar, Wofi, Ghostty, Kitty, Fastfetch, Cava, btop, prompt Zsh, NvChad y bordes de Hyprland. VS Code se sincroniza si se activó con `--vscode-theme`; no requiere una extensión de Marketplace y conserva el tema/extensiones instalados, aplicando colores de interfaz y sintaxis en vivo.

Fastfetch conserva su salida completa en todos los temas: logo, usuario, sistema, kernel, uptime, paquetes, shell, entorno gráfico, CPU, GPU, memoria, discos, red y colores.

## Atajos

`Super` es la tecla Windows. La lista completa está en [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md).

- `Super+Enter`: nueva ventana de Ghostty.
- `Super+W` o `Super+Q`: cerrar ventana.
- `Super+Space`: lanzador Wofi.
- `Super+T`: selector de tema.
- `Super+O`: menú para ajustar la opacidad del fondo de Ghostty/Kitty y alternar el blur del escritorio detrás de los terminales.
- `Super+E`: Thunar.
- `Super+L`: lockscreen QuickShell/Qylock.
- `Super+V`: flotante; `Super+F`: pantalla completa.
- `Super+1..0`: cambiar workspace; `Super+Shift+1..0`: mover ventana.
- `Super+flechas`: cambiar foco; `Super+Shift+flechas`: mover ventana.
- `Print`: captura completa; `Super+Shift+S`: seleccionar región.
- Teclas multimedia: volumen y brillo.

## Componentes y servicios

- **Hyprland**: compositor, ventanas, workspaces, animaciones y hotkeys.
- **Waybar**: panel superior con workspaces, reloj, audio, red y bandeja.
- **Wofi**: lanzador y selector de temas.
- **hyprpaper / mpvpaper**: wallpapers estáticos y animación Dusk City.
- **hypridle / QuickShell**: inactividad y pantalla de bloqueo; `hyprlock` está disponible como alternativa.
- **SDDM**: pantalla de inicio de sesión con Pixel Dusk City; archivos/licencia en `assets/sddm/`.
- **polkit-gnome**: agente de autenticación para acciones administrativas desde apps gráficas.
- **NetworkManager + nm-applet**: conexión de red desde la bandeja.
- **PipeWire + WirePlumber**: audio de usuario.
- **Ghostty y Kitty**: terminales con transparencias, tipografía Nerd Font y colores por tema.
- **Zsh, Oh My Zsh, Powerlevel10k y zsh-autosuggestions**: shell y prompt.
- **Fastfetch, btop y Cava**: información del sistema, monitor y visualizador.
- **NvChad/Neovim**: editor. La primera ejecución de Neovim instala sus plugins.

La lista de paquetes oficiales está en `packages/arch.txt`. `mpvpaper` es opcional y se obtiene del AUR; sin él, Dusk City usa el fondo PNG estático. Las instrucciones de SDDM y AUR están en [docs/SDDM.md](docs/SDDM.md).

## Árbol del repositorio

```text
assets/             Wallpapers y recursos licenciados de Qylock
packages/           Paquetes oficiales y opcionales AUR
dotfiles/            Configuración de Hyprland y aplicaciones
docs/                Atajos, SDDM, temas y mantenimiento
install.sh          Instalador Arch idempotente con copias de seguridad
AGENTS.md           Convenciones para mantener el repositorio
```

## Añadir un tema

Sigue [docs/THEMES.md](docs/THEMES.md). En resumen: añade el wallpaper, crea los archivos de paleta por aplicación, añade una opción al selector y valida Fastfetch/Hyprland antes de publicar.

Para auditar que los temas integrados, wallpapers, colores y atajos sigan completos, ejecuta `./scripts/audit-repo.sh`. Para guardar la apariencia de un Arch ya configurado como un tema seleccionable, usa `./scripts/capture-theme.sh mi-tema`; el flujo y sus límites están en [docs/THEMES.md](docs/THEMES.md).

## Recursos y atribuciones

- La pantalla de inicio Pixel Dusk City proviene de [Qylock](https://github.com/Darkkal44/qylock) y conserva su licencia GPL-3.0 en `assets/sddm/LICENSE.Qylock`.
- Los wallpapers `johan-neon.png`, `liberty.jpg`, `arch-blue.png`, `skull.png` y Pixel Dusk City se mantienen como recursos visuales aportados/descargados para esta configuración; sus derechos pertenecen a sus respectivos autores.
- El prompt Kushal enlaza al [repositorio oh-my-zsh_Kushal-Theme](https://github.com/sebaz07/oh-my-zsh_Kushal-Theme).

## Actualizar

```bash
cd My-Desktop-Envs-Arch-Linux
git pull
./install.sh --no-packages --theme "$(cat ~/.config/hypr/current-theme)"
```

También puedes inspeccionar primero los cambios de configuración y respaldos. El instalador no borra tus copias anteriores.

## Diagnóstico rápido

Para errores de Ghostty, Zsh/Oh My Zsh, el selector `Super+T` o una publicación GitHub detenida, consulta [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). Incluye los síntomas observados y comandos para verificar y reparar rutas, shell y autenticación.

Cada ejecución guarda la salida completa en `~/.local/state/my-desktop-envs/logs/`. Si falla una fase, el instalador muestra el comando, la línea y la ruta del log.
