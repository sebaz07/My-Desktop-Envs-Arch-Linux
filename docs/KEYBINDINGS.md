# Atajos de Hyprland

La tecla `Super` corresponde a la tecla Windows. El archivo fuente es `dotfiles/hypr/hyprland.conf`.

## Ventanas y programas

| Atajo | Acción |
| --- | --- |
| `Super+Enter` | Abrir una nueva ventana de Ghostty |
| `Super+W`, `Super+Q` | Cerrar la ventana enfocada |
| `Super+Space` | Abrir Wofi |
| `Super+T` | Elegir tema |
| `Super+O` | Ajustar la transparencia del fondo y el blur de Ghostty/Kitty |
| `Super+E` | Abrir Thunar |
| `Super+L` | Bloquear con Qylock/QuickShell |
| `Super+V` | Alternar flotante |
| `Super+F` | Alternar pantalla completa |
| `Super+M` | Salir de Hyprland |

## Foco y movimiento

| Atajo | Acción |
| --- | --- |
| `Super+←/→/↑/↓` | Mover el foco |
| `Super+Shift+←/→/↑/↓` | Mover la ventana enfocada |

## Workspaces

Con `Super+O`, elige Ghostty o Kitty y selecciona la opacidad del fondo entre 0 % y 100 %, en pasos de 5 %. A 0 %, el fondo es totalmente transparente. Solo cambia el fondo del terminal; el texto conserva su opacidad. El ajuste se aplica en vivo y persiste en `~/.config/ghostty/background-opacity` o `~/.config/kitty/background-opacity.conf`.

El menú `Super+O` también permite elegir si Hyprland difumina el escritorio detrás de Ghostty/Kitty. Esa opción alterna entre nítido y el blur general de Hyprland; el blur general de otras ventanas no cambia.

- `Super+1..9`: ir al workspace 1..9.
- `Super+0`: ir al workspace 10.
- `Super+Shift+1..9`: mover ventana al workspace 1..9.
- `Super+Shift+0`: mover ventana al workspace 10.

## Captura, audio y brillo

- `Print`: captura de pantalla completa al portapapeles.
- `Super+Shift+S`: seleccionar una región y copiarla.
- Teclas multimedia: subir/bajar/silenciar volumen.
- Teclas de brillo: aumentar/disminuir brillo en pasos de 5 %.
