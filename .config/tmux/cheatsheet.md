 TMUX CHEATSHEET                         prefix = Ctrl-Space   (q to close)
 ─────────────────────────────────────────────────────────────────────────

 THE MENTAL MODEL
   session  = a project        (replaces "a Ghostty window per project")
   window   = a tab            (editor / server / git ...)
   pane     = a split inside a window

 FROM THE SHELL
   t / Ctrl-f     sesh picker -> jump to (or create) a session
   t .  / t <dir> session for the current / given directory
   ta             attach to the last session (or start "main")
   z <name>       cd via zoxide (also teaches sesh your favourite dirs)
   keep [note]    keep the last command (-l: this machine only, not in dotfiles)
   Ctrl-g         pick a kept command onto the prompt
                  (history is per session: gone when the session closes)

 SESSIONS (sesh)
   prefix f       sesh picker (popup)
     type         fuzzy filter        ctrl+o   toggle preview
     dot / tmx    aliases: dotfiles, tmux config (~/.config/sesh/sesh.toml)
   prefix N       new session by name, in the current folder
                  (e.g. a scratch session; switches if it exists)
   prefix s       tmux tree view of sessions & windows
   prefix Tab     previous session
   prefix P       promote: move this window into its own session
                  (e.g. unleash/fix-auth); it keeps running
   prefix $       rename session
   prefix d       detach (everything keeps running)
   prefix X       kill current session

 WINDOWS
   prefix c       new window (same dir)
   prefix 1..9    go to window N
   prefix n / p   next / previous window
   prefix C-Space toggle last window
   prefix ,       rename window
   prefix < / >   move window left / right
   prefix &       kill window

 PANES
   prefix | / -   split side-by-side / stacked (same dir)
   prefix h j k l move between panes     (mouse click works too)
   prefix H J K L resize (repeatable)    (mouse drag borders too)
   prefix z       zoom pane full screen / back
   prefix x       kill pane
   prefix !       break pane out into its own window
   prefix `       floating scratch shell

 CLAUDE AGENTS (markers set by Claude Code hooks)
   󰚩 on a window  Claude is waiting for you (permission / question); orange
   ✓  on a window  Claude finished; go have a look
   󰚩 name (right)  a Claude is waiting in another session
                  markers clear when you reply

 COPY / SCROLL
   mouse wheel    scroll back
   prefix v       enter copy mode (vi keys; ? search up, / down, n next)
     v  / C-v     start selection / rectangle
     y            copy to macOS clipboard, exit
     q            exit copy mode

 MISC
   prefix r       reload config
   prefix ?       this cheatsheet     prefix /   every key binding
   prefix I / U   install / update plugins
   prefix C-s     save sessions now   prefix C-r restore
                  (also auto-saved every 15 min, restored when tmux starts)
