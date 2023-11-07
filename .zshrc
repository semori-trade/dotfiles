# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
ZSH_TMUX_AUTOSTART="true"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,bold"

plugins=(zsh-autosuggestions git)

source $ZSH/oh-my-zsh.sh

# Add alias for python2
alias python="python3"
alias pip="pip3"

bindkey '\t ' autosuggest-accept
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.oh-my-zsh/plugins/git/git.plugin.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias lzd='lazydocker'
alias lzg='lazygit'

# nice hack when we pres tmux bind + ] and call function that we attach to bd
function run_binding_code() {
  tmux bind ] run -b "$*";
}
alias bd="run_binding_code"

function run_browse() {
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --kiosk "https://google.com?q=$1"
}
alias chr="run_browse"

# TODO: Get research what is it o.O
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
else
    export VISUAL="nvim"
    export EDITOR="nvim"
fi

export EDITOR=nvim

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

# TODO: Zinit not workign correct yet. Should migrate from oh-my-zsh to zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
#
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# set ulimit for prevent error with max number of files
ulimit -n 10240

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_241.jdk/Contents/Home

#GO PATH
export GOPATH=$HOME/go

#nvim config PATH
export NVIM_CONFIG=$HOME/.config/nvim/init.lua

#alacrity config PATH
export ALACRITTY_CONFIG=$HOME/.config/alacritty/alacritty.yml

#tmux config PATH
export TMUX_CONFIG=$HOME/.tmux.conf

#tmux config PATH
export ZSH_CONFIG=$HOME/.zshrc

# PATHS
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="~/Library/Android/sdk/tools:$PATH"
export PATH="~/Library/Android/sdk/platform-tools:$PATH"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.docker/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$NVIM_CONFIG/:$PATH"
export PATH="$ALACRITTY_CONFIG/:$PATH"
export PATH="$TMUX_CONFIG/:$PATH"
export PATH="$ZSH_CONFIG/:$PATH"
