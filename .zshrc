# ── History ──────────────────────────────────────────────────────────────────
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

setopt extended_history      # Record timestamp of command in HISTFILE
setopt hist_ignore_dups      # Ignore consecutive duplicates
setopt hist_ignore_all_dups  # Remove older duplicate entries from history
setopt hist_ignore_space     # Don't save commands prefixed with a space
setopt hist_reduce_blanks    # Remove superfluous blanks before recording
setopt share_history         # Share history across all open terminals
setopt append_history        # Append rather than overwrite history on exit

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit

# Only regenerate .zcompdump once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle :compinstall filename '/home/melatonia/.zshrc'
zstyle ':completion:*' menu select          # Arrow-key navigable completion menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # Case-insensitive completion

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey -e  # Emacs keybindings

# ── Plugins ───────────────────────────────────────────────────────────────────
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# ── "Command not found" pacman handler ───────────────────────────────────────
function command_not_found_handler {
  local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
  printf 'zsh: command not found: %s\n' "$1"
  local entries=(
    ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"}
  )
  if (( ${#entries[@]} )); then
    printf "${bright}$1${reset} may be found in the following packages:\n"
    local pkg
    for entry in "${entries[@]}"; do
      local fields=( ${(0)entry} )
      if [[ "$pkg" != "${fields[2]}" ]]; then
        printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
      fi
      printf '    /%s\n' "${fields[4]}"
      pkg="${fields[2]}"
    done
  fi
  return 127
}

# ── Prompt ────────────────────────────────────────────────────────────────────
setopt PROMPT_SUBST

typeset -gA JOVIAL_PALETTE=(
  host    '%F{157}'
  user    '%F{253}'
  path    '%B%F{228}'
  conj.   '%F{102}'
  typing  '%F{252}'
  normal  '%F{252}'
  time    '%F{254}'
  success '%F{040}'
  error   '%F{203}'
)

PS1=""
PS1+="${JOVIAL_PALETTE[normal]}╭─["
PS1+="${JOVIAL_PALETTE[user]}%n%f"
PS1+="${JOVIAL_PALETTE[normal]}] "
PS1+="${JOVIAL_PALETTE[conj.]}as%f "
PS1+="${JOVIAL_PALETTE[host]}%m%f "
PS1+="${JOVIAL_PALETTE[conj.]}in%f "
PS1+="${JOVIAL_PALETTE[path]}%~%f"
PS1+=$'\n'
PS1+="${JOVIAL_PALETTE[typing]}╰──➤ %f"

RPS1="${JOVIAL_PALETTE[time]}%T%f"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias zed='zeditor'
alias ..='cd ..'
alias ...='cd ../..'

# ls / eza  (eza is the maintained fork of exa — install with: paru -S eza)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias l.='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2'          # directory tree
else
  alias ls='ls --color=auto'
  alias ll='ls -l --color=auto'
  alias la='ls -la --color=auto'
  alias l.='ls -a --color=auto'
fi

# paru / packages
alias yay='paru'
alias packages='pacman -Qe'

function orphans() {
  local pkgs
  pkgs=$(pacman -Qdtq)
  if [[ -n $pkgs ]]; then
    sudo pacman -Rs $pkgs
  else
    echo "no orphans to remove"
  fi
}

# Full system update
alias update='paru && rustup update && orphans && flatpak update && flatpak uninstall --unused && flatpak repair'

export PATH="$HOME/.cargo/bin:$PATH"

# ── Greeting ──────────────────────────────────────────────────────────────────
cat <<'EOF'
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)  melo.
EOF
