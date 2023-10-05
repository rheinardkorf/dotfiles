# Rheinard's dotfiles

More info on how this was done... https://www.atlassian.com/git/tutorials/dotfiles

## Starting from scratch

```bash
git init --bare $HOME/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> $HOME/.bashrc
```

`config` now becomes the $HOME version of `git`. Examples:

```bash
config status
config add .vimrc
config commit -m "Add vimrc"
```

## Cloning the dotfiles

Add your destination source folder (the bare repo) to a root level `.gitignore` file in $HOME.

```bash
echo ".cfg" >> .gitignore
```

Set your config alias.

```bash 
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

Clone the repo in $HOME.

```bash
git clone --bare git@github.com:rheinardkorf/dotfiles.git $HOME/.cfg
```

Checkout the main branch in $HOME.

```bash
config checkout
```

!!! In case of conflict error...

```bash
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

Only show the files you are actually tracking in your repo...

```bash
config config --local status.showUntrackedFiles no
```



