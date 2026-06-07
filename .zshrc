# ── History ──────────────────────────────────────────────────────────────────
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

typeset -U path PATH

setopt extended_history      # Record timestamp of command in HISTFILE
setopt hist_ignore_dups      # Ignore consecutive duplicates
setopt hist_ignore_all_dups  # Remove older duplicate entries from history
setopt hist_ignore_space     # Don't save commands prefixed with a space
setopt hist_reduce_blanks    # Remove superfluous blanks before recording
setopt share_history         # Share history across all open terminals
setopt append_history        # Append rather than overwrite history on exit
setopt auto_cd               # type a dir name to cd into it
setopt correct               # suggest corrections for mistyped commands
setopt interactive_comments  # allow # commnets in the interactive shell

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit

# Only regenerate .zcompdump once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -i
else
  compinit -C -i
fi

zstyle :compinstall filename '$HOME/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

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
autoload -Uz add-zsh-hook
zmodload zsh/datetime  # provides $EPOCHREALTIME

typeset -gF _melo_cmd_start=0
typeset -gi _melo_last_exit=0

function _melo_preexec()  { _melo_cmd_start=$EPOCHREALTIME; }
function _melo_precmd_capture() { _melo_last_exit=$?; }

function _melo_format_elapsed() {
  local -F e=$(( EPOCHREALTIME - _melo_cmd_start ))
  local -i s=$e
  local -i m=$(( s / 60 ))
  local -i h=$(( m / 60 ))

  if   (( s < 1  )); then printf ''
  elif (( h > 0  )); then printf '~%dh %dm' $h $(( m % 60 ))
  elif (( m > 0  )); then printf '~%dm %ds' $m $(( s % 60 ))
  else                    printf '~%ds'     $s
  fi
}

add-zsh-hook preexec _melo_preexec
add-zsh-hook precmd  _melo_precmd_capture  # must be registered FIRST

typeset -gA MELO_PALETTE=(
  host    '%F{#a5d6a7}'   # green200    – accent
  user    '%F{#eeeeee}'   # grey200    – near-white text
  path    '%B%F{#fff59d}' # yellow200  – bright path (bold preserved)
  conj.   '%F{#78909c}'   # blueGrey400 – muted separators
  git     '%F{#80cbc4}'   # teal200
  typing  '%F{#bdbdbd}'   # grey400    – prompt cursor line
  normal  '%F{#bdbdbd}'   # grey400    – structural chrome
  time    '%F{#e0e0e0}'   # grey300    – subtle right-prompt
  success '%F{#a5d6a7}'   # green200   – exit ok
  error   '%F{#ef9a9a}'   # red200     – exit fail
)

# ── Git branch (sync, lightweight) ───────────────────────────────────────────
typeset -g _melo_git_branch=""

function _melo_update_git() {
  local ref
  ref=$(git symbolic-ref HEAD 2>/dev/null) \
    || ref=$(git describe --tags --exact-match 2>/dev/null) \
    || ref=$(git rev-parse --short HEAD 2>/dev/null) \
    || { _melo_git_branch=""; return; }
  _melo_git_branch="${ref#refs/heads/}"
}

add-zsh-hook chpwd _melo_update_git
add-zsh-hook precmd _melo_update_git

# Jovial-style length helper: expands prompt sequences then strips ANSI codes
# (S%%) cannot handle hex %F{#rrggbb} colors — must strip ANSI bytes directly
function _melo_strlen() {
  local str="${(%)1}"
  local result=""
  local unstyle_regex=$'\e\[[0-9;]*[a-zA-Z]'
  while [[ -n $str ]]; do
    if [[ $str =~ $unstyle_regex ]]; then
      result+=${str[1,MBEGIN-1]}
      str=${str[MEND+1,-1]}
    else
      break
    fi
  done
  result+=$str
  echo ${#result}
}

function _melo_build_ps1() {
  local host_seg="${MELO_PALETTE[host]}%m%f"
  local user_seg="${MELO_PALETTE[user]}%n%f"
  local git_seg=""
  [[ -n $_melo_git_branch ]] && \
    git_seg="${MELO_PALETTE[conj.]} on %f${MELO_PALETTE[normal]}(%f${MELO_PALETTE[git]}${_melo_git_branch}${MELO_PALETTE[normal]})%f"

  local -i w_host=$(_melo_strlen "${host_seg}")
  local -i w_user=$(_melo_strlen "${user_seg}")
  local -i w_path=$(_melo_strlen "%~")
  local -i w_git=$(_melo_strlen "${git_seg}")

  local -i t_host=$(( 3 + w_host + 5 + w_user + 4 + w_path + w_git ))
  local -i t_user=$(( w_user + 4 + w_path + w_git ))
  local -i t_git=$(( w_git ))

  local host_block="${MELO_PALETTE[normal]}╭─[%f${host_seg}${MELO_PALETTE[normal]}] ${MELO_PALETTE[conj.]}as%f "
  local host_hidden="${MELO_PALETTE[normal]}╭─%f"

  PS1=""
  PS1+="%-${t_host}(l.${host_block}.${host_hidden})"
  PS1+="%-${t_user}(l.${user_seg} ${MELO_PALETTE[conj.]}in%f .)"
  PS1+="${MELO_PALETTE[path]}%~%b%f"
  [[ -n $_melo_git_branch ]] && PS1+="%-${t_git}(l.${git_seg}.)"
  PS1+=$'\n'
  PS1+="${MELO_PALETTE[typing]}╰──➤ %f"

  local elapsed_seg=""
  if (( _melo_cmd_start > 0 )); then
    local raw_elapsed=$(_melo_format_elapsed)
    if [[ -n $raw_elapsed ]]; then
      elapsed_seg="%F{#ffe082}$(_melo_format_elapsed)%f"
    fi
    _melo_cmd_start=0
  fi

  if   (( _melo_last_exit != 0 ));  then RPS1="${MELO_PALETTE[conj.]}exit:${MELO_PALETTE[error]}${_melo_last_exit}%f"
  elif [[ -n $elapsed_seg ]];       then RPS1="$elapsed_seg"
  else                                   RPS1="${MELO_PALETTE[time]}%B%T%b%f"
  fi
}

add-zsh-hook precmd _melo_build_ps1

# Redraw on terminal resize so time and responsive parts reflow
function _melo_winch() { zle && zle reset-prompt; }
trap '_melo_winch' WINCH

RPS1=""

# ── Aliases ───────────────────────────────────────────────────────────────────
alias zed='zeditor'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'

# zoxide (smart cd)
eval "$(zoxide init zsh --cmd cd)"

# fzf with fd backend

[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]]   && source /usr/share/fzf/completion.zsh

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --bind "ctrl-/:toggle-preview"' 

alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --all'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# lazygit
alias lg='lazygit'

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
  pkgs=(${(f)"$(pacman -Qdtq)"})
  if (( ${#pkgs[@]} == 0 )); then
    echo "no orphans to remove"
    return 0
  fi
  echo "orphaned packages:"
  printf '  %s\n' "${pkgs[@]}"
  echo ""
  read -q "REPLY?remove ${#pkgs[@]} package(s)? [y/N] "
  echo ""
  if [[ $REPLY == "y" ]]; then
    sudo pacman -Rs "${pkgs[@]}"
  else
    echo "aborted"
  fi
}

# Full system update
function update() {
  paru
  command -v rustup &>/dev/null && rustup update
  orphans
  flatpak update
  flatpak uninstall --unused
  flatpak repair
}

# idle
alias sleepy='quickshell -c ~/.config/quickshell/idle-overlay'

export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"


# ── Greeting ──────────────────────────────────────────────────────────────────
cat <<'EOF'
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)  melo.
EOF

# bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="base16"

alias cat='bat --paging=never --style=plain'
