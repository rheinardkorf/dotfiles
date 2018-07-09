" Use cache for gutentags
" Note: This prevents `tags` files getting created in each project.
"       Unchecked, this could get big quickly.
let g:gutentags_cache_dir = expand('~/.gutentags')

" Exclude files from getting tagged.
let g:gutentags_ctags_exclude = ['*.css', '*.html', '*.js', '*.json', '*.xml',
                            \ '*.phar', '*.ini', '*.rst', '*.md',
                            \ '.git', '.svn', '*.hg', '.idea',
                            \ '*vendor/*/test*', '*vendor/*/Test*',
                            \ '*vendor/*/fixture*', '*vendor/*/Fixture*',
                            \ 'tags', '.tags',
                            \ '*var/cache*', '*var/log*']
