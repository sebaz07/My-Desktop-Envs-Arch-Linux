# SDDM, QuickShell y agentes

El login usa SDDM y el tema Pixel Dusk City de Qylock. El tema completo, su video y la licencia están en `assets/sddm/pixel-dusk-city/`.

Instala el sistema y activa el tema/servicio con:

```bash
./install.sh --no-packages --theme liberty --enable-sddm
```

El instalador copia el tema a `/usr/share/sddm/themes/pixel-dusk-city`, crea `/etc/sddm.conf.d/10-my-desktop-envs.conf` y habilita `sddm.service`. En equipos con otro display manager, elige cuál quedará habilitado antes de reiniciar; no se deshabilita automáticamente ninguno.

El bloqueo de sesión es una integración de QuickShell/Qylock. El instalador clona [Qylock](https://github.com/Darkkal44/qylock), instala la capa `assets/quickshell-lockscreen/` y conecta sus temas. `Super+L` y `hypridle` usan el mismo script. `hyprlock` permanece instalado como alternativa.

El agente Polkit es `polkit-gnome-authentication-agent-1`, iniciado en `hyprland.conf`. Presenta el diálogo de contraseña cuando una aplicación necesita privilegios. NetworkManager usa `nm-applet --indicator` en la bandeja; audio usa los servicios PipeWire/WirePlumber de usuario.

`mpvpaper` no está en los repositorios oficiales de Arch. Si tienes `yay`:

```bash
yay -S mpvpaper
```

Sin ese paquete, el selector usa el PNG Dusk City estático. El video de SDDM sigue funcionando por separado.
