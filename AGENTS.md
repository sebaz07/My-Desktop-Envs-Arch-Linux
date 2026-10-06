# Instrucciones para agentes de código

- Mantén los IDs de tema (`liberty`, `johan-neon`, `arch-blue`, `skull-teal`, `dusk-city`) iguales en instalador, selector, wallpapers y nombres de archivo.
- La fuente mantenida es `dotfiles/`; no escribas cambios generados de vuelta a `~/`.
- No borres ni sobrescribas configuraciones del usuario durante la instalación: usa el respaldo de `install.sh`.
- Cada archivo Fastfetch por tema debe incluir `modules`; valida que muestre el sistema además del logo.
- Mantén `Super+W` y `Super+Q` para cerrar ventanas y `Super+T` para el selector.
- Conserva los avisos de licencia y autoría de `assets/sddm/` y wallpapers.
- Documenta paquetes no oficiales en `packages/aur.txt`; no ejecutes helpers AUR automáticamente.
- El video de Dusk City requiere `mpvpaper`; conserva el fondo estático de respaldo.
