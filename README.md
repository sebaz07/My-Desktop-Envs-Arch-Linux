# My Desktop Envs — Arch Linux / Hyprland

Configuración reproducible del entorno Arch Linux de sebaz07: Hyprland, Waybar, Wofi, SDDM, Ghostty/Kitty, Zsh + Oh My Zsh, Fastfetch, btop, Cava y NvChad. Incluye wallpapers y selector de temas coordinado.

## Instalación rápida

Clona el repositorio y ejecuta el instalador con tu usuario normal:

```bash
git clone https://github.com/sebaz07/My-Desktop-Envs-Arch-Linux.git
cd My-Desktop-Envs-Arch-Linux
./install.sh --theme liberty --enable-sddm --set-default-shell
```

El instalador instala paquetes oficiales de Arch, respalda configuraciones existentes en `~/.local/state/my-desktop-envs/backups/`, enlaza los dotfiles, instala Oh My Zsh/plugins, instala los wallpapers, prepara el lockscreen Qylock y configura el tema SDDM Pixel Dusk City. SDDM se habilita solo si indicas `--enable-sddm`; activar un display manager puede reemplazar el inicio gráfico actual.

Opciones:

- `--theme liberty|johan-neon|arch-blue|skull-teal|dusk-city`: tema inicial (por defecto `liberty`).
- `--enable-sddm`: instala el tema SDDM incluido y habilita el servicio.
- `--set-default-shell`: hace Zsh el shell de inicio de sesión.
- `--no-packages`: omite `pacman`, para reutilizar una instalación existente.

Después de instalar, cierra sesión y elige **Hyprland** en SDDM. El tema guardado se vuelve a aplicar al entrar.

## Temas disponibles

| ID | Wallpaper | Colores |
| --- | --- | --- |
| `dusk-city` | Pixel Dusk City animado (y PNG de respaldo) | Azul noche, cian, coral |
| `skull-teal` | `skull.png` | Verde agua, oro |
| `arch-blue` | `arch-blue.png` | Azul eléctrico, azul cielo |
| `johan-neon` | `johan-neon.png` | Cian eléctrico, magenta |
| `liberty` | `liberty.jpg` | Blanco y negro, grises |

Pulsa **Super+T** para abrir el selector. El tema sincroniza wallpaper, Waybar, Wofi, Ghostty, Kitty, Fastfetch, Cava, btop, prompt Zsh y bordes de Hyprland. NvChad lee el tema activo al iniciar y aplica los acentos Johan Neon o Liberty.

Fastfetch conserva su salida completa en todos los temas: logo, usuario, sistema, kernel, uptime, paquetes, shell, entorno gráfico, CPU, GPU, memoria, discos, red y colores.

## Atajos

`Super` es la tecla Windows. La lista completa está en [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md).

- `Super+Enter`: nueva ventana de Ghostty.
- `Super+W` o `Super+Q`: cerrar ventana.
- `Super+Space`: lanzador Wofi.
- `Super+T`: selector de tema.
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
