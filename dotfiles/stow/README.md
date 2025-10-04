# Stow Configuration Package

This package contains GNU Stow's configuration file.

## Files

- `dot-stowrc` → `~/.stowrc` - Stow configuration file

## Configuration

The `.stowrc` file enables the `--dotfiles` option by default, which allows files in stow packages named with a `dot-` prefix (e.g., `dot-bashrc`) to be symlinked as dotfiles (e.g., `.bashrc`) in the target directory.

### Key Settings

```
--dotfiles
```

This setting is automatically applied by the `stow_package()` function in `libs/utils.sh`, but having it in `.stowrc` also enables manual stow commands to work correctly.

## Notes

- This package is installed by `install-scripts/install-stow.sh`
- The `.stowrc` file is placed in the user's home directory (`~/.stowrc`)
- Having this config allows manual `stow` commands to work with dot-prefix notation
