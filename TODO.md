[] research and consider adding nvim-ufo for better code folding



[] port the setup away from iTerm2 into something like kitty, wezterm, or some other multiplatform emulator with similar features and better configurabilty. iTerm2 uses pList entries, portability of configs sucks. Also osx only, no support for kitty (image rendering on terminal), wezterm (lua config, cross-platform), alacritty (yaml config, cross-platform, gpu accelerated), etc. Essential to have 'Hotkey Window'-like functionality. Also, our terminal emulator setup is 0% managed by the setup done here, and we want that to be 100%, so the dev-env- bootstrap already gives a good t. emulator configged



[x] fix color schemes in tmux and nvim clashing, looking broken



[x] make install scripts and config package for iTerm2


[x] add Glow plugin for markdown preview in-buffer (DONE)



[x] study and consider submitting the flit/leap fix PR



[x] fix rbenv loading error in .bash_path (line 12: rbenv: command not found)



[x] clean up tmux plugin submodule deletions from git status (dotfiles/tmux/.config/tmux/plugins/*)



[x] update lazy-llm submodule to latest (includes @ path completion feature)



[x] review and finalize LazyVim health check fixes (lynx, neovim npm, tmux TERM) (WONT DO, not fixing all, rbenv and CPANM not needed for now)



[x] add install-glow.sh script following modular install pattern



[x] add more LSP servers, test and configure LSPs in nvim



[x] prepare repo for linux support (Debian/Ubuntu/Omarchy ?): package install function on scripts can be abstracted per-branch (e.g., using brew for osx, apt-get for debian/ubuntu, etc.), but install scripts could mostly stay the same and just call the utility package install wrapper that is different per-platform; of course, individual scripts still retain the ability to implement their own platform-specific logic as needed).



[x] test and fix install in Debian/Ubuntu (DONE - tested in Ubuntu 22.04 LTS VM, works reasonably well)



[x] enable C# LSP server (DONE - .NET SDK installed, OmniSharp ready)



[x] fix the surround/leap/flit/search keybinding conflicts (e.g., `s` key, `gs`, s/S f/F t/T) etc. (WONT DO, just use gz bindings for surround, `s` for leap).



[x] add install scripts for compression tools like gzip, xz, tar, etc.



[x] add fzf-lua and new keybindings to pick files including hidden and .gitignore files



