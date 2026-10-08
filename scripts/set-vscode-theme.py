#!/usr/bin/env python3
"""Apply a repo palette to VS Code user settings while preserving JSONC settings."""

from __future__ import annotations

import json
import os
import re
import shutil
import stat
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
BUILTIN = {"liberty", "johan-neon", "arch-blue", "skull-teal", "dusk-city", "neon-void", "amber-shibuya"}
REQUIRED_COLORS = {
    "background", "foreground", "surface", "primary", "secondary", "muted",
    "string", "type", "visual", "red", "green", "yellow", "blue", "magenta", "cyan",
}
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")


def skip_string(text: str, pos: int) -> int:
    pos += 1
    while pos < len(text):
        if text[pos] == "\\":
            pos += 2
        elif text[pos] == '"':
            return pos + 1
        else:
            pos += 1
    raise ValueError("JSONC tiene una cadena sin cerrar")


def skip_trivia(text: str, pos: int) -> int:
    while pos < len(text):
        if text[pos].isspace():
            pos += 1
        elif text.startswith("//", pos):
            end = text.find("\n", pos + 2)
            pos = len(text) if end < 0 else end + 1
        elif text.startswith("/*", pos):
            end = text.find("*/", pos + 2)
            if end < 0:
                raise ValueError("JSONC tiene un comentario sin cerrar")
            pos = end + 2
        else:
            return pos
    return pos


def scan_value(text: str, pos: int) -> int:
    if pos >= len(text):
        raise ValueError("Falta un valor en JSONC")
    if text[pos] == '"':
        return skip_string(text, pos)
    if text[pos] in "[{":
        stack = ["]" if text[pos] == "[" else "}"]
        pos += 1
        while pos < len(text) and stack:
            pos = skip_trivia(text, pos)
            if pos >= len(text):
                break
            char = text[pos]
            if char == '"':
                pos = skip_string(text, pos)
                continue
            if char == "[":
                stack.append("]")
            elif char == "{":
                stack.append("}")
            elif char in "]}":
                if char != stack[-1]:
                    raise ValueError("Paréntesis JSONC sin pareja")
                stack.pop()
            pos += 1
        if stack:
            raise ValueError("Objeto JSONC sin cerrar")
        return pos
    while pos < len(text) and text[pos] not in ",}":
        if text.startswith("//", pos) or text.startswith("/*", pos):
            break
        pos += 1
    while pos > 0 and text[pos - 1].isspace():
        pos -= 1
    return pos


def top_level_spans(text: str) -> tuple[dict[str, tuple[int, int]], int, int, bool]:
    pos = skip_trivia(text, 0)
    if pos >= len(text) or text[pos] != "{":
        raise ValueError("settings.json debe tener un objeto en la raíz")
    pos += 1
    spans: dict[str, tuple[int, int]] = {}
    count = 0
    trailing_comma = False
    while True:
        pos = skip_trivia(text, pos)
        if pos >= len(text):
            raise ValueError("Objeto de settings.json sin cerrar")
        if text[pos] == "}":
            return spans, pos, count, trailing_comma
        if text[pos] != '"':
            raise ValueError("Se esperaba el nombre de una opción en settings.json")
        key_end = skip_string(text, pos)
        key = json.loads(text[pos:key_end])
        pos = skip_trivia(text, key_end)
        if pos >= len(text) or text[pos] != ":":
            raise ValueError(f"Falta ':' después de la opción {key}")
        value_start = skip_trivia(text, pos + 1)
        value_end = scan_value(text, value_start)
        spans[key] = (value_start, value_end)
        count += 1
        pos = skip_trivia(text, value_end)
        if pos < len(text) and text[pos] == ",":
            pos = skip_trivia(text, pos + 1)
            if pos < len(text) and text[pos] == "}":
                return spans, pos, count, True
            trailing_comma = False
            continue
        if pos < len(text) and text[pos] == "}":
            return spans, pos, count, False
        raise ValueError("Se esperaba ',' o '}' en settings.json")


def jsonc_plain(text: str) -> str:
    """Remove JSONC comments and trailing commas without touching string data."""
    out: list[str] = []
    pos = 0
    while pos < len(text):
        if text[pos] == '"':
            end = skip_string(text, pos)
            out.append(text[pos:end])
            pos = end
        elif text.startswith("//", pos):
            end = text.find("\n", pos + 2)
            end = len(text) if end < 0 else end
            out.append(" " * (end - pos))
            pos = end
        elif text.startswith("/*", pos):
            end = text.find("*/", pos + 2)
            if end < 0:
                raise ValueError("JSONC tiene un comentario sin cerrar")
            end += 2
            comment = text[pos:end]
            out.append("".join("\n" if char == "\n" else " " for char in comment))
            pos = end
        else:
            out.append(text[pos])
            pos += 1
    clean = "".join(out)
    out = []
    pos = 0
    while pos < len(clean):
        if clean[pos] == '"':
            end = skip_string(clean, pos)
            out.append(clean[pos:end])
            pos = end
        elif clean[pos] == ",":
            next_pos = pos + 1
            while next_pos < len(clean) and clean[next_pos].isspace():
                next_pos += 1
            if next_pos < len(clean) and clean[next_pos] in "]}":
                out.append(" ")
            else:
                out.append(",")
            pos += 1
        else:
            out.append(clean[pos])
            pos += 1
    return "".join(out)


def settings_folder() -> Path:
    home = Path.home()
    if os.environ.get("VSCODE_PORTABLE"):
        return Path(os.environ["VSCODE_PORTABLE"]) / "user-data/User"
    if shutil.which("code"):
        return home / ".config/Code/User"
    if shutil.which("code-oss"):
        return home / ".config/Code - OSS/User"
    if shutil.which("codium"):
        return home / ".config/VSCodium/User"
    known = [
        home / ".config/Code/User",
        home / ".config/Code - OSS/User",
        home / ".config/VSCodium/User",
        home / ".var/app/com.visualstudio.code/config/Code/User",
    ]
    for folder in known:
        if (folder / "settings.json").exists():
            return folder
    raise FileNotFoundError("No encontré VS Code, Code OSS ni VSCodium")


def read_palette(theme_id: str) -> dict[str, str]:
    if theme_id in BUILTIN:
        palette_path = ROOT / "dotfiles/vscode/themes" / f"{theme_id}.json"
    else:
        palette_path = ROOT / "dotfiles/themes/custom" / theme_id / "vscode-colors.json"
    palette = json.loads(palette_path.read_text(encoding="utf-8"))
    if not isinstance(palette, dict) or not REQUIRED_COLORS.issubset(palette):
        raise ValueError(f"Paleta incompleta: {palette_path}")
    for key in REQUIRED_COLORS:
        if not isinstance(palette[key], str) or not HEX_COLOR.fullmatch(palette[key]):
            raise ValueError(f"Color inválido '{key}' en {palette_path}")
    return palette


def vscode_colors(p: dict[str, str]) -> tuple[dict[str, str], dict[str, str]]:
    ui = {
        "focusBorder": p["primary"],
        "foreground": p["foreground"],
        "descriptionForeground": p["muted"],
        "widget.shadow": p["background"] + "99",
        "selection.background": p["visual"],
        "textLink.foreground": p["primary"],
        "button.background": p["primary"],
        "button.foreground": p["background"],
        "badge.background": p["secondary"],
        "badge.foreground": p["background"],
        "progressBar.background": p["primary"],
        "titleBar.activeBackground": p["surface"],
        "titleBar.activeForeground": p["foreground"],
        "titleBar.inactiveBackground": p["background"],
        "activityBar.background": p["background"],
        "activityBar.foreground": p["primary"],
        "activityBar.inactiveForeground": p["muted"],
        "activityBar.activeBorder": p["primary"],
        "sideBar.background": p["background"],
        "sideBar.foreground": p["foreground"],
        "sideBar.border": p["surface"],
        "sideBarSectionHeader.background": p["surface"],
        "list.activeSelectionBackground": p["visual"],
        "list.activeSelectionForeground": p["foreground"],
        "list.hoverBackground": p["surface"],
        "editorGroupHeader.tabsBackground": p["background"],
        "tab.activeBackground": p["surface"],
        "tab.activeForeground": p["foreground"],
        "tab.inactiveBackground": p["background"],
        "tab.inactiveForeground": p["muted"],
        "statusBar.background": p["surface"],
        "statusBar.foreground": p["foreground"],
        "statusBar.debuggingBackground": p["secondary"],
        "statusBar.debuggingForeground": p["background"],
        "panel.background": p["background"],
        "panel.border": p["surface"],
        "terminal.background": p["background"],
        "terminal.foreground": p["foreground"],
        "terminal.ansiBlack": p["background"],
        "terminal.ansiRed": p["red"],
        "terminal.ansiGreen": p["green"],
        "terminal.ansiYellow": p["yellow"],
        "terminal.ansiBlue": p["blue"],
        "terminal.ansiMagenta": p["magenta"],
        "terminal.ansiCyan": p["cyan"],
        "terminal.ansiWhite": p["foreground"],
        "terminal.ansiBrightBlack": p["muted"],
        "terminal.ansiBrightRed": p["red"],
        "terminal.ansiBrightGreen": p["string"],
        "terminal.ansiBrightYellow": p["yellow"],
        "terminal.ansiBrightBlue": p["type"],
        "terminal.ansiBrightMagenta": p["secondary"],
        "terminal.ansiBrightCyan": p["primary"],
        "terminal.ansiBrightWhite": p["foreground"],
        "editor.background": p["background"],
        "editor.foreground": p["foreground"],
        "editorLineNumber.foreground": p["muted"],
        "editorLineNumber.activeForeground": p["primary"],
        "editorCursor.foreground": p["primary"],
        "editor.selectionBackground": p["visual"],
        "editor.lineHighlightBackground": p["surface"],
        "editorIndentGuide.background1": p["surface"],
        "editorBracketHighlight.foreground1": p["primary"],
        "editorBracketHighlight.foreground2": p["secondary"],
        "editorBracketHighlight.foreground3": p["type"],
        "editorGutter.modifiedBackground": p["primary"],
        "editorGutter.addedBackground": p["green"],
        "editorGutter.deletedBackground": p["red"],
        "diffEditor.insertedTextBackground": p["green"] + "33",
        "diffEditor.removedTextBackground": p["red"] + "33",
        "terminalCursor.foreground": p["primary"],
    }
    tokens = {
        "comments": p["muted"],
        "strings": p["string"],
        "functions": p["primary"],
        "keywords": p["secondary"],
        "types": p["type"],
        "numbers": p["yellow"],
    }
    return ui, tokens


def apply(theme_id: str) -> Path:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", theme_id):
        raise ValueError("ID de tema inválido")
    palette = read_palette(theme_id)
    ui, tokens = vscode_colors(palette)
    settings_path = settings_folder() / "settings.json"
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    text = settings_path.read_text(encoding="utf-8") if settings_path.exists() else "{}\n"
    parsed = json.loads(jsonc_plain(text))
    if not isinstance(parsed, dict):
        raise ValueError("La raíz de settings.json debe ser un objeto")

    existing_ui = parsed.get("workbench.colorCustomizations", {})
    existing_tokens = parsed.get("editor.tokenColorCustomizations", {})
    if not isinstance(existing_ui, dict) or not isinstance(existing_tokens, dict):
        raise ValueError("Las personalizaciones de color existentes deben ser objetos JSON")
    existing_ui = dict(existing_ui)
    existing_tokens = dict(existing_tokens)
    for key, value in list(existing_ui.items()):
        if key.startswith("[") and isinstance(value, dict):
            scoped = dict(value)
            scoped.update(ui)
            existing_ui[key] = scoped
    existing_ui.update(ui)
    for key, value in list(existing_tokens.items()):
        if key.startswith("[") and isinstance(value, dict):
            scoped = dict(value)
            scoped.update(tokens)
            existing_tokens[key] = scoped
    existing_tokens.update(tokens)

    values = {
        "workbench.colorCustomizations": existing_ui,
        "editor.tokenColorCustomizations": existing_tokens,
    }
    spans, closing, member_count, has_trailing_comma = top_level_spans(text)
    replacements: list[tuple[int, int, str]] = []
    missing: list[tuple[str, str]] = []
    for key, value in values.items():
        encoded = json.dumps(value, ensure_ascii=False, indent=2)
        encoded = encoded.replace("\n", "\n  ")
        if key in spans:
            start, end = spans[key]
            replacements.append((start, end, encoded))
        else:
            missing.append((key, encoded))
    for start, end, replacement in sorted(replacements, reverse=True):
        text = text[:start] + replacement + text[end:]
    if missing:
        comma = "," if member_count and not has_trailing_comma else ""
        additions = comma + "\n" + ",\n".join(
            f'  {json.dumps(key)}: {value}' for key, value in missing
        ) + "\n"
        text = text[:closing] + additions + text[closing:]

    # Keep a one-time copy of the user's original JSONC settings for easy recovery.
    backup = settings_path.with_name("settings.json.my-desktop-envs-backup")
    if settings_path.exists() and not backup.exists():
        shutil.copy2(settings_path, backup)
    mode = stat.S_IMODE(settings_path.stat().st_mode) if settings_path.exists() else 0o600
    fd, temp_name = tempfile.mkstemp(prefix=".settings-", dir=settings_path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as temp_file:
            temp_file.write(text)
            temp_file.flush()
            os.fsync(temp_file.fileno())
        os.chmod(temp_name, mode)
        os.replace(temp_name, settings_path)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    return settings_path


if __name__ == "__main__":
    try:
        selected = sys.argv[1] if len(sys.argv) == 2 else "liberty"
        path = apply(selected)
        print(f"VS Code: tema {selected} aplicado en {path}")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"No pude configurar VS Code: {error}", file=sys.stderr)
        raise SystemExit(1)
