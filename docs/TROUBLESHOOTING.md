# Diagnóstico y reparaciones

Guarda primero el síntoma y la salida de los comandos de diagnóstico. No publiques tokens ni contraseñas.

## Ghostty dice que no encuentra `current-theme`

El archivo fuente está en `dotfiles/ghostty/config`. Debe usar `config-file`, no `include`:

```ini
config-file = ~/.config/ghostty/current-theme
```

Comprueba que el enlace exista y resuelva a uno de los archivos de tema del repo:

```bash
readlink ~/.config/ghostty/current-theme
readlink -e ~/.config/ghostty/current-theme
ghostty +show-config | rg '^(background|foreground|config-file) ='
```

Si `readlink -e` no imprime una ruta, repara el enlace conservando el tema activo:

```bash
theme="$(cat ~/.config/hypr/current-theme)"
ln -sfn "$HOME/My-Desktop-Envs-Arch-Linux/dotfiles/ghostty/themes/$theme" \
  "$HOME/.config/ghostty/current-theme"
```

IDs válidos: `liberty`, `johan-neon`, `arch-blue`, `skull-teal`, `dusk-city`, `neon-void`, `amber-shibuya`. Ghostty puede recargar con `Ctrl+Shift+,`; si se cambió el shell de inicio, abre una terminal nueva.

## `Super+T` cambia el escritorio, pero rompe Ghostty o el prompt Zsh

Los enlaces del tema se actualizan en `dotfiles/hypr/scripts/theme-switcher.sh`. Hyprland ejecuta ese script desde `~/.config/hypr/scripts`, que es un symlink al repo. Si el script calcula su raíz con `dirname "$BASH_SOURCE"` sin resolver el enlace, puede deducir `~/dotfiles` (que no existe) en vez del repo real; los enlaces que crea entonces quedan rotos.

El script debe resolver primero su ruta física y derivar la raíz desde ahí:

```bash
script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
repo_root="$(cd -- "$(dirname -- "$script_path")/../../.." && pwd)"
```

Comprueba Ghostty y Powerlevel10k después de usar el selector:

```bash
readlink -e ~/.config/ghostty/current-theme
readlink -e ~/.p10k.zsh
```

Ambos deben resolver dentro de `My-Desktop-Envs-Arch-Linux/dotfiles/`. El selector enlaza `.p10k.zsh` con `dotfiles/zsh/themes/<id>.p10k.zsh`; Zsh carga ese archivo al iniciar.

## Oh My Zsh no aparece en una terminal nueva

`export SHELL=...` dentro de `.zshrc` no cambia el shell que ya inició la terminal. Comprueba el shell de login y prueba Zsh interactivo:

```bash
getent passwd "$USER" | cut -d: -f7
~/.local/bin/zsh -i -c 'print -r -- "OMZ=${+functions[omz]} tema=$ZSH_THEME"; exit'
```

`OMZ=1` confirma que Oh My Zsh cargó. La instalación local de este equipo usa un binario en `~/.local/bin/zsh`; Ghostty puede seleccionarlo con `command = /home/<usuario>/.local/bin/zsh` en la configuración local `~/.config/ghostty/config.ghostty`. Para convertirlo en shell de login para todas las terminales, ejecuta `./install.sh --no-packages --set-default-shell`; el instalador registra Zsh en `/etc/shells` y cambia el shell de la cuenta. Se requiere autenticación administrativa.

Powerlevel10k toma sus colores desde `~/.p10k.zsh`. Si Oh My Zsh carga, pero el prompt conserva colores viejos, verifica que el enlace resuelva al archivo del tema activo con `readlink -e ~/.p10k.zsh` y abre una terminal nueva. Los mensajes `can't change option: monitor` o `gitstatus failed to initialize` al lanzar Zsh interactivo con `-c` sin TTY corresponden a ese contexto de diagnóstico; verifica el prompt en una terminal real.

## `git push` parece quedarse subiendo

Comprueba si todavía existe un proceso de push y cuál remoto se usa:

```bash
pgrep -a -f 'git push|git-remote-https|git-remote-ssh'
git remote -v
git status --short --branch
```

Comprueba la sesión de GitHub sin mostrar credenciales:

```bash
gh auth status
git ls-remote origin HEAD
```

Si `gh auth status` informa un token inválido, vuelve a autenticar con `gh auth login` o `gh auth refresh -h github.com` y reintenta `git push --verbose origin main`. Para diagnosticar una subida lenta, `git push --progress --verbose origin main` muestra el avance por etapa. Si HTTPS sigue fallando pero tienes una clave SSH autorizada, comprueba `ssh -T git@github.com` y publica con el remoto SSH (`git push github main`, si ese remoto existe). No pegues tokens en el repo ni en logs.

En esta revisión no había un proceso Git de subida activo. El remoto `origin` usa HTTPS; una respuesta anterior de `gh auth status` reportó token inválido. Los commits locales de reparación (`3089aa5` y `853a4f0`) deben incluirse al publicar la rama `main`.
