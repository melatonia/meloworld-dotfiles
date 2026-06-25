# yazi · meloworld cheatsheet

> `prepend_keymap` overrides win. Default keybinds still work unless explicitly shadowed.

---

## Navigation

| Key                | Action                             |
| ------------------ | ---------------------------------- |
| `h`                | Go to parent directory             |
| `l` / `Enter`      | Enter directory / open file        |
| `j` / `k`          | Cursor down / up                   |
| `J` / `K`          | Cursor down 5 / up 5               |
| `gg` / `G`         | Jump to top / bottom               |
| `H` / `M` / `L`    | Top / middle / bottom of screen    |
| `<Back>` / `<Fwd>` | Browser-style back / forward       |
| `-`                | Go to parent (leave)               |
| `.`                | **Toggle hidden files** _(custom)_ |

---

## Bookmarks `g …` _(custom)_

| Key   | Goes to          |
| ----- | ---------------- |
| `g h` | `~/`             |
| `g c` | `~/.config`      |
| `g d` | `~/Downloads`    |
| `g D` | `~/Documents`    |
| `g m` | `~/Music`        |
| `g p` | `~/Pictures`     |
| `g r` | `~/Projects`     |
| `g .` | `~/.config/yazi` |

---

## Open & Edit

| Key           | Action                                                      |
| ------------- | ----------------------------------------------------------- |
| `Enter` / `o` | Open with default rule                                      |
| `O`           | Open with… (interactive picker)                             |
| `e`           | Edit in `$EDITOR` (blocks yazi)                             |
| `!`           | **Orphan shell** — run cmd, yazi stays _(custom)_           |
| `<C-s>`       | **Blocking shell** — yazi hides, you get a shell _(custom)_ |

---

## Selection & Visual

| Key       | Action                                      |
| --------- | ------------------------------------------- |
| `<Space>` | Toggle selection on hovered file            |
| `v`       | Enter visual (range) select mode            |
| `V`       | Enter visual unset mode                     |
| `<Esc>`   | Clear selection / cancel find / exit visual |
| `<C-a>`   | Select all                                  |
| `<C-r>`   | Invert selection                            |

---

## File Operations

| Key   | Action                                          |
| ----- | ----------------------------------------------- |
| `y y` | Yank (copy) selected                            |
| `y p` | **Copy full path** to clipboard _(custom)_      |
| `y d` | **Copy directory path** _(custom)_              |
| `y n` | **Copy filename** _(custom)_                    |
| `y s` | **Copy name without extension** _(custom)_      |
| `x`   | Cut selected                                    |
| `p`   | Paste                                           |
| `P`   | Paste (force overwrite)                         |
| `d`   | Trash selected (with confirm)                   |
| `D`   | **Permanently delete** (no trash) _(custom)_    |
| `a`   | **Rename — cursor before extension** _(custom)_ |
| `A`   | **Rename — cursor at end** _(custom)_           |
| `I`   | **Rename — cursor at start** _(custom)_         |
| `r`   | Rename (default, cursor before extension)       |
| `n`   | Create file (`name/` for directory)             |

---

## Searching & Filtering

| Key       | Action                                        |
| --------- | --------------------------------------------- |
| `<C-f>`   | **Search via `fd`** (filename) _(custom)_     |
| `<C-g>`   | **Search via `rg`** (file content) _(custom)_ |
| `/`       | Find in current dir (incremental)             |
| `n` / `N` | Next / prev find match                        |
| `f`       | Filter current listing (live)                 |

---

## Sorting `s …` _(custom)_

| Key   | Sort order                       |
| ----- | -------------------------------- |
| `s n` | Natural (1 < 2 < 10), dirs first |
| `s m` | Newest modified first            |
| `s s` | Largest size first               |
| `s e` | By extension, dirs first         |

---

## Linemode `<A-…>` _(custom)_

| Key     | Shows on right       |
| ------- | -------------------- |
| `<A-s>` | File size            |
| `<A-m>` | Modified time        |
| `<A-p>` | Permissions          |
| `<A-n>` | Nothing              |
| `<A-t>` | Size + modified time |

---

## Tabs

| Key         | Action                                |
| ----------- | ------------------------------------- |
| `T`         | **New tab at current dir** _(custom)_ |
| `1` – `9`   | Switch to tab N                       |
| `[` / `]`   | Prev / next tab                       |
| `<C-Tab>`   | **Next tab** _(custom)_               |
| `<C-S-Tab>` | **Prev tab** _(custom)_               |
| `<C-w>`     | **Close current tab** _(custom)_      |

---

## Overlays & UI

| Key         | Action                      |
| ----------- | --------------------------- |
| `~` or `F1` | Help menu (searchable)      |
| `W`         | Task manager                |
| `Tab`       | Spot (file info / metadata) |
| `<Esc>`     | Close overlay / cancel      |

---

## Input box (when renaming, cd, etc.)

| Key     | Action                                   |
| ------- | ---------------------------------------- |
| `<C-u>` | **Kill to beginning of line** _(custom)_ |
| `<C-k>` | **Kill to end of line** _(custom)_       |
| `<C-w>` | **Kill word backward** _(custom)_        |
| `<A-d>` | **Kill word forward** _(custom)_         |
| `<A-b>` | **Move word backward** _(custom)_        |
| `<A-f>` | **Move word forward** _(custom)_         |
| `<C-c>` | Cancel                                   |

---

## Tips

- **Bulk rename**: select files → `r` → opens `$EDITOR` with a list; edit names, save, quit.
- **Flat view**: `<C-f>` → leave search term empty → shows all files recursively.
- **Spot a file**: `Tab` shows full metadata, mime-type, permissions — useful before `open`.
- **Config files**: all three live in `~/.config/yazi/` — `yazi.toml`, `keymap.toml`, `theme.toml`, `init.lua`.
- **Reload config**: just quit and reopen; or `<C-s>` into a shell and `exec yazi`.

---

_Keys marked _(custom)_ are meloworld additions — not yazi defaults._
