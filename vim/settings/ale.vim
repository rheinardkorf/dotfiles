let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'php': ['phpcbf'],
\}

let g:ale_pattern_options = {
\   '*/vendor/*': {'ale_enabled': 0},
\   '*/node_modules/*': {'ale_enabled': 0},
\   '*/dev-lib/*': {'ale_enabled': 0},
\   '*/tests/*': {'ale_enabled': 0},
\}

let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1