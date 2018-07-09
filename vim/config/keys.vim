" Re-map <leader>
let mapleader = ","

" Ctrl-E: MRU Files
map <c-e> :CtrlPMRUFiles<CR>

" Jump to definition under cursor
map <silent> <leader>jd :CtrlPTag<cr><C-\>w<cr>

" Quick exit INSERT mode
imap jj <ESC>`^

" Toggle NERDTree
nmap <Leader>d :NERDTreeToggle<CR>