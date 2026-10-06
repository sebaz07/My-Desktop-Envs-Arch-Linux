# Use the user-local Arch build if present; otherwise use the system Zsh.
zsh_usr="$HOME/.local/opt/arch-zsh/usr"
if [[ -d "$zsh_usr/lib/zsh/5.9.2" ]]; then
  module_path=("$zsh_usr/lib/zsh/5.9.2" $module_path)
  fpath=("$zsh_usr/share/zsh/functions"/**/(/N) "$zsh_usr/share/zsh/site-functions" $fpath)
fi
zsh_bin="$HOME/.local/bin/zsh"
[[ -x "$zsh_bin" ]] || zsh_bin="$(command -v zsh 2>/dev/null)"
[[ -n "$zsh_bin" ]] && export SHELL="$zsh_bin"
unset zsh_usr
unset zsh_bin
