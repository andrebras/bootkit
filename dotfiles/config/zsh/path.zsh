typeset -gU cdpath fpath mailpath path

eval "$(/opt/homebrew/bin/brew shellenv)"

path=(
  ${ASDF_DATA_DIR:-$HOME/.asdf}/shims(N)
  $HOME/.local/bin(N)
  /opt/homebrew/opt/libpq/bin(N)
  $HOME/.grok/bin(N)
  $HOME/.mix/escripts(N)
  $path
)
