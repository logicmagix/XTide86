# Changelog
## [1.2.0] - 2025-06-01
### Changed
- Project renamed to `tide42` (formerly `xtide86`)
- Installer, wrapper, and manpage updated accordingly
- Legacy support for `xtide86 --update` remains functional

### Added
- `--force-update` flag to reset local changes and reinstall from latest Git tag
- `--lite`, `-li` mode for running `nvim` without tmux (quick edit mode)
- Help output and manpage expanded with clearer flag documentation

### Fixed
- Swapfile suppression for NERDTree buffers to avoid `.swp` file spam
- False positive dirty state in updater due to untracked/generated files
- `.gitignore` restored to ignore `install.sh`, manpages, and swapfiles

### Notes
- Declared `1.2.0` as first stable release after extended field testing
- Internals cleaned, redundant permissions removed from `install.sh`


## [1.1.0] - 2025-05-28
### Added
- Full 256-color support using `tmux-256color`
- Enhanced color handling in `tide42.sh` and `init.vim`
- Open existing and new files in `tide42.sh`
- Update from repo capability in `tide42.sh`


## [1.0.0] - 2025-05-24
- Initial release of tide42 with core tmux/nvim integration

