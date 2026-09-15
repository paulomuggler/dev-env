# rbenv configuration
# Ruby version management

# Initialize rbenv if installed (generated init is cached; see 00-devenv-cache.sh)
if command -v rbenv >/dev/null 2>&1; then
  devenv_cache_eval rbenv rbenv init - bash
fi
