#!/bin/bash
set -euxo pipefail


#
# install vim.

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF


#
# configure the shell.

cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return # bail when not running interactively.
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

cat >~/.bash_history <<'EOF'
lxc list
lxc launch images:debian/12 debian
lxc exec debian -- bash
lxc delete debian --force
EOF

# configure the ubuntu user home.
su ubuntu -c bash <<'EOF'
set -euxo pipefail

cat >~/.bash_history <<'EOFU'
sudo -i
EOFU
EOF
