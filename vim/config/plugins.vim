call plug#begin('~/.vim/plugins')

" === Navigation / Buffers ===

" A tree explorer plugin for vim.
Plug 'scrooloose/nerdtree'

" Most Recently Used (MRU) Vim Plugin
" Plug 'yegappan/mru'

" Use RipGrep in Vim and display results in a quickfix list
""" " Plug 'jremmen/vim-ripgrep'

" Vim plugin to easily and quickly expand your splits to fit the file you are working on and collapse them back
" Plug 'blarghmatey/split-expander'

" Intelligently reopen files at your last edit position in Vim.
""" " Plug 'farmergreg/vim-lastplace'

" BufExplorer Plugin for Vim
" Plug 'jlanzarotta/bufexplorer'

" === GIT ===

" A Vim plugin which shows a git diff in the gutter (sign column) and stages/undoes hunks.
Plug 'airblade/vim-gitgutter'

" fugitive.vim: A Git wrapper so awesome, it should be illegal.
Plug 'tpope/vim-fugitive'

" rhubarb.vim: GitHub extension for fugitive.vim
Plug 'tpope/vim-rhubarb'

" === GIST ===

" vimscript for gist
" Requires: 'mattn/webapi-vim'
""" " Plug 'mattn/gist-vim'

" === Editing ===

" Perform all your vim insert mode completions with Tab
Plug 'ervandew/supertab'

" repeat.vim: enable repeating supported plugin maps with "."
""" " Plug 'tpope/vim-repeat'

" surround.vim: quoting/parenthesizing made simple
" Plug 'tpope/vim-surround'

" extended % matching for HTML, LaTeX, and many other languages
" Plug 'tmhedberg/matchit'

" Vim plugin: Create your own text objects
" Plug 'kana/vim-textobj-user'

" An extensible & universal comment plugin that also handles embedded filetypes
Plug 'vim-scripts/tComment'

" Toggles between hybrid and absolute line numbers automatically
""" " Plug 'jeffkreeftmeijer/vim-numbertoggle'

" True Sublime Text style multiple selections for Vim
" Plug 'terryma/vim-multiple-cursors'

" A vim plugin that simplifies the transition between multiline and single-line code
Plug 'AndrewRadev/splitjoin.vim'

" UltiSnips - The ultimate snippet solution for Vim.
Plug 'SirVer/ultisnips'

" === Color Schemes | Themes ===

" A 24bit colorscheme for Vim, Airline and Lightline
Plug 'jacoborus/tender.vim'

" VIM Darcula Theme
Plug 'blueshirts/darcula'

" Fatih's version of molokai
Plug 'fatih/molokai'

" a blue-tinted winter vimscape
Plug 'nightsense/snow'

" === Linting and Style ==

" .editorconfig plugin for Vim.
" Plug 'editorconfig/editorconfig-vim'

" Syntax checking hacks for vim
" Uses external linters/checkers.
" Plug 'vim-syntastic/syntastic'

" Better whitespace highlighting for Vim
" " Plug 'ntpeters/vim-better-whitespace'

" Asynchronous Lint Engine
" Requires: VIM 8+
" Alternative to syntastic.
Plug 'w0rp/ale'

" === UI ===

" A light and configurable statusline/tabline plugin for Vim
Plug 'itchyny/lightline.vim'

" lean & mean status/tabline for vim that's light as air
" Alt to 'itchyny/lightline.vim'
""" Plug 'vim-airline/vim-airline'

" color hex codes and color names
""" " Plug 'chrisbra/Colorizer'

" === TMUX ===

" vim plugin to interact with tmux
" Plug 'benmills/vimux'

" Seamless navigation between tmux panes and vim splits
" Plug 'christoomey/vim-tmux-navigator'

" === File system ===

" eunuch.vim: helpers for UNIX
" Plug 'tpope/vim-eunuch'

" Fuzzy file, buffer, mru, tag, etc finder. (Active fork of kien/ctrlp.vim)
Plug 'ctrlpvim/ctrlp.vim'

" `fzf` fuzzy search for Vim.
" Requires: `fzf` installed on the file system.
" Alternative to Ctrl-P.
""" " Plug 'junegunn/fzf.vim'

" === Syntax ===

" Go development plugin for Vim
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }

" A better JSON for Vim: distinct highlighting of keywords vs values, JSON-specific (non-JS) warnings, quote concealing.
Plug 'elzr/vim-json'

" Vim Markdown runtime files (use default if available instead)
""" " Plug 'tpope/vim-markdown'

" Distraction-free writing in Vim; nice with Markdown.
" Plug 'junegunn/goyo.vim'
" Plug 'junegunn/limelight.vim'

" Vastly improved Javascript indentation and syntax support in Vim.
""" " Plug 'pangloss/vim-javascript'

" React JSX syntax highlighting and indenting for vim.
""" " Plug 'mxw/vim-jsx'

" A Vim plugin that provides GraphQL file detection, syntax highlighting, and indentation.
""" " Plug 'jparise/vim-graphql'

" Copy syntax-highlighted code from vim to the OS X clipboard as RTF text
""" " Plug 'zerowidth/vim-copy-as-rtf'

" emmet for vim
""" " Plug 'mattn/emmet-vim'

" === Testing ===

" Run your tests at the speed of thought
" Plug 'janko-m/vim-test'

" === API Integrations ===

" vim interface to Web API
""" " Plug 'mattn/webapi-vim'

" === Coverage ===

" Has issue with Vim 8+
" Plug 'joonty/vim-phpqa'

" === Completion ===

" A Vim plugin that manages your tag files
Plug 'ludovicchabant/vim-gutentags'

" YouCompleteMe
" Plug 'Valloric/YouCompleteMe'

" deoplete has issues with Vim 8+
" if has('nvim')
"   Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" else
"   Plug 'Shougo/deoplete.nvim'
"   Plug 'roxma/nvim-yarp'
"   Plug 'roxma/vim-hug-neovim-rpc'
" endif
" let g:deoplete#enable_at_startup = 1

call plug#end()

