set laststatus=2
set noruler
set noshowmode
set noshowcmd

let g:lightline = {
      \   'active': {
      \     'left': [['mode', 'paste'], ['readonly', 'filename', 'modified']],
      \     'right': [['lineinfo'], ['gitbranch'], ['fileformat', 'fileencoding', 'filetype']]
      \   },
      \   'component': {
      \     'gitbranch': '%{GitHead()}',
      \   },
      \   'colorscheme': 'snow_dark',
      \   'separator': { 'left': "\uE0B0", 'right': '' },
\ }

function GitHead()
        return exists('*fugitive#head') ? "\uE0A0". fugitive#head() : ''
endfunction

augroup AutoGitStatus
      autocmd!
      autocmd BufWritePost,BufRead *.*,* call s:checkDirty()
augroup END
function! s:checkDirty()
      let state = systemlist('expr $(git status --porcelain 2>/dev/null| egrep "^(M| M)" | wc -l)')
      call LightlinePalette(state[0])
      call lightline#colorscheme()
endfunction


function! LightlinePalette(state)
" === SNOW_DARK THEME OVERRIDES

let s:gry0 = "#1f262c"
let s:gry1 = "#2f3a45"
let s:gry2 = "#818e9b"
let s:gry3 = "#a0acba"
let s:gry4 = "#eaeff5"
let s:red_ = "#bb897b"
let s:yllw = "#d8c165"
let s:gren = "#7f9d77"
let s:blue = "#759abd"
let s:gitstatus = a:state == "0" ? "#c0ffa3" : "#ff5555"
let s:gitstatusbg = a:state == "0" ? "#000000" : "#000000"

let s:p = lightline#palette()
let s:p.normal.right    = [[ s:gry0, s:gry2 ], [ s:gitstatus, s:gitstatusbg ], [ s:gry3, s:gry1 ]]
let s:p.insert.right    = [[ s:gry0, s:gren ], [ s:gitstatus, s:gitstatusbg ], [ s:gry0, s:gren ]]
let s:p.visual.right    = [[ s:gry0, s:blue ], [ s:gitstatus, s:gitstatusbg ], [ s:gry0, s:blue ]]

let g:lightline#colorscheme#snow_dark#palette =
  \ lightline#colorscheme#fill(s:p)

endfunction