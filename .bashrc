# ~/.bashrc — only for interactive shells
[[ $- != *i* ]] && return

# ─── History & Window ───────────────────────────────────────────────────────
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
HISTSIZE=1000; HISTFILESIZE=2000

# ─── Lesspipe ───────────────────────────────────────────────────────────────
command -v lesspipe &>/dev/null && eval "$(SHELL=/bin/sh lesspipe)"

# ─── Debian chroot tag ──────────────────────────────────────────────────────
[[ -r /etc/debian_chroot ]] && debian_chroot=$(< /etc/debian_chroot)

# ─── Git branch parser ──────────────────────────────────────────────────────
if command -v git &>/dev/null; then
  parse_git_branch() {
    [ -d .git ] || return
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/(&)/'
  }
else
  parse_git_branch() { :; }
fi

# ─── Prompt style controls (preserve your variables) ───────────────────────
PROMPT_ALTERNATIVE=${PROMPT_ALTERNATIVE:-twoline}
NEWLINE_BEFORE_PROMPT=${NEWLINE_BEFORE_PROMPT:-yes}
force_color_prompt=yes

# detect color support
if tput setaf 1 &>/dev/null; then
  color_prompt=yes
else
  color_prompt=
fi

# ─── Build the prompt ───────────────────────────────────────────────────────
build_prompt() {
  if [[ $color_prompt == yes ]]; then
    VIRTUAL_ENV_DISABLE_PROMPT=1

    # set colors & symbols
    prompt_color='\[\033[;32m\]'
    info_color='\[\033[1;34m\]'
    prompt_symbol='🛸'
    if [[ $EUID -eq 0 ]]; then
      prompt_color='\[\033[;94m\]'
      info_color='\[\033[1;31m\]'
      prompt_symbol='💀'
    fi

    case "$PROMPT_ALTERNATIVE" in
      twoline)
        PS1="${prompt_color}┌──${debian_chroot:+($debian_chroot)──}${VIRTUAL_ENV:+(\[\033[0;1m\]$(basename "$VIRTUAL_ENV")${prompt_color})}\
(${info_color}\u ${prompt_symbol} \h${prompt_color})-[\[\033[0;1m\]\w${prompt_color}]\[\033[01;31m\] \
\$(parse_git_branch)\n${prompt_color}└─${info_color}\$\[\033[0m\] "
        ;;
      oneline)
        PS1="${VIRTUAL_ENV:+($(basename "$VIRTUAL_ENV")) }${debian_chroot:+($debian_chroot)}\
${info_color}\u@\h\[\033[00m\]:${prompt_color}\[\033[01m\]\w\[\033[00m\]\$ "
        ;;
      backtrack)
        PS1="${VIRTUAL_ENV:+($(basename "$VIRTUAL_ENV")) }${debian_chroot:+($debian_chroot)}\
\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
        ;;
    esac

    # optional blank line before prompt
    [[ $NEWLINE_BEFORE_PROMPT == yes ]] && PS1="\n$PS1"

  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
  fi
}

build_prompt
unset prompt_color info_color prompt_symbol
unset force_color_prompt color_prompt

# ─── GTK Terminal dark/light color toggle ───────────────────────────────────
# (restores your original OSC-10/11 behavior, via gsettings or dconf)
if command -v gsettings &>/dev/null; then
  cs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
  if [[ $cs == "'prefer-dark'" ]]; then
    # dark mode: light text on dark bg
    printf '\e]10;#C0C0C0\a\e]11;#1E1E1E\a'
  else
    # light mode: dark text on light bg
    printf '\e]10;#000000\a\e]11;#ffffdd\a'
  fi

# fallback for environments where color-scheme is in dconf
elif command -v dconf &>/dev/null; then
  cs=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)
  if [[ $cs == "'prefer-dark'" ]]; then
    printf '\e]10;#C0C0C0\a\e]11;#1E1E1E\a'
  else
    printf '\e]10;#000000\a\e]11;#ffffdd\a'
  fi
fi

# ─── Terminal title for xterm-like emulators ───────────────────────────────
case "$TERM" in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# ─── Colorized ls/grep & LESS ───────────────────────────────────────────────
if command -v dircolors &>/dev/null; then
  [[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" \
                       || eval "$(dircolors -b)"
  export LS_COLORS="$LS_COLORS:ow=30;44:"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias diff='diff --color=auto'
  alias ip='ip --color=auto'

  export LESS_TERMCAP_mb=$'\E[1;31m' LESS_TERMCAP_md=$'\E[1;36m'
  export LESS_TERMCAP_me=$'\E[0m'     LESS_TERMCAP_so=$'\E[01;33m'
  export LESS_TERMCAP_se=$'\E[0m'     LESS_TERMCAP_us=$'\E[1;32m'
  export LESS_TERMCAP_ue=$'\E[0m'
fi

# ─── Bash completion ────────────────────────────────────────────────────────
if ! shopt -oq posix && [[ -f /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

# ─── ESP32 toolchain ────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.espressif/tools/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin"
export IDF_PATH="$HOME/esp/esp-idf/"

# ─── Aliases & user customizations ─────────────────────────────────────────
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
alias copy='xclip -selection clipboard'
