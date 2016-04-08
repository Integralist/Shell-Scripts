#!/bin/bash

# Enable a form of 'strict mode' for Bash
set -euo pipefail
IFS=$'\n\t'

# Decrease delay between repeated keys
defaults write NSGlobalDomain KeyRepeat -int 0
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write com.apple.TextEdit SmartQuotes -bool false
defaults write com.apple.TextEdit SmartDashes -bool false

# Configure menu bar clock to something useful
defaults write com.apple.menuextra.clock "DateFormat" "EEE d MMM  HH:mm:ss"
defaults write com.apple.menuextra.clock "FlashDateSeparators" 0
defaults write com.apple.menuextra.clock "IsAnalog" 0

# Install xcode
xcode-select --install

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update

# Install Bash
brew install bash
echo /usr/local/bin/bash | sudo tee -a /etc/shells
chsh -s /usr/local/bin/bash

# Configure Bash
curl -LSso ~/.bashrc https://raw.githubusercontent.com/Integralist/dotfiles/master/.bashrc

cat > ~/.bash_profile <<EOF
if [ -f $HOME/.bashrc ]; then
  source ~/.bashrc
  cd .
fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi
EOF

cat > ~/.inputrc <<EOF
TAB: menu-complete
"\e[Z": "\e-1\C-i"
EOF

# Install NeoVim
brew tap neovim/neovim && brew install --HEAD neovim

# Configure NeoVim/Vim
mkdir -p ~/.vim/{autoload,bundle}
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
curl -LSso ~/.vimrc https://raw.githubusercontent.com/Integralist/dotfiles/master/.vimrc
curl -LSso ~/usr/local/bin/voom https://raw.githubusercontent.com/airblade/voom/master/voom
alias voom="VIM_DIR=~/.vim voom"
voom

vim -E -s <<EOF
:set spell
:quit
EOF

# Install Curl with OpenSSL and HTTP2
brew install curl --with-openssl --with-nghttp2 && brew link curl --force

# Install other brew packages
packages=(\
  argon/mas/mas\
  bash-completion\
  bundler-completion\
  docker-compose-completion\
  docker-machine\
  docker\
  gem-completion\
  gist\
  git\
  go\
  gpg\
  irssi\
  leiningen\
  mutt\
  netcat\
  ngrok\
  node\
  rbenv\
  reattach-to-user-namespace\
  ruby-build\
  siege\
  sift\
  speedtest-cli\
  terminal-notifier\
  the_silver_searcher\
  tmate\
  tmux\
  tree\
  urlview\
  watch\
  wget\
  wireshark\
)
for package in "${packages[@]}"
do
  brew install $package
done

# Configure Git
curl -LSso ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

cat > ~/.gitignore-global <<EOF
# bundler
.gem
.bin
.ruby-version
failed_cukes.sh

# miscellaneous
*.DS_Store
.sass-cache
.grunt
tags
*.swp
logs
*.log
.vagrant*
EOF

git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
git config --global alias.st status
git config --global alias.unstage "reset HEAD --"
git config --global apply.whitespace nowarn
git config --global color.branch.current yellow reverse
git config --global color.branch.local yellow
git config --global color.branch.remote green
git config --global color.commit red
git config --global color.diff-highlight.newhighlight=green bold 22
git config --global color.diff-highlight.newnormal=green bold
git config --global color.diff-highlight.oldhighlight=red bold 52
git config --global color.diff-highlight.oldnormal=red bold
git config --global color.diff.frag magenta
git config --global color.diff.meta yellow
git config --global color.diff.new green
git config --global color.diff.old red
git config --global color.status.added red
git config --global color.status.changed blue
git config --global color.status.untracked magenta
git config --global color.ui true
git config --global core.editor nvim
git config --global core.excludesfile ~/.gitignore-global
git config --global core.ignorecase false
git config --global merge.conflictstyle diff3
git config --global merge.tool vimdiff
git config --global mergetool.prompt true
git config --global push.default upstream
git config --global url.git@github.com:.insteadof https://github.com/
git config --global user.email mark.mcdx@gmail.com
git config --global user.name Integralist

# Install applications from Mac App Store
mas installed 411246225 # Caffeine
mas installed 458034879 # Dash
mas installed 549083868 # Display Menu
mas installed 409789998 # Twitter

# Miscellaneous
echo COMMAND open %s > ~/.urlview # use <Ctrl-b> within mutt to activate
echo --color --format documentation --format=Nc > ~/.rspec
curl -LSso ~/.tmux.conf https://raw.githubusercontent.com/Integralist/dotfiles/master/.tmux.conf
curl -LSso ~/smyck.terminal https://raw.githubusercontent.com/Integralist/dotfiles/master/terminal-themes/Smyck.terminal
open ~/smyck.terminal
