{ config, ... }:
{
  home.activation.nixAccessTokens = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    _nixConfDir="${config.home.homeDirectory}/.config/nix"
    _tokenFile="$_nixConfDir/access-tokens.conf"
    _tokens=""

    if [ -n "${config.age.secrets.github_token.path or ""}" ] && [ -f "${config.age.secrets.github_token.path}" ]; then
      _ghToken="$(cat "${config.age.secrets.github_token.path}")"
      [ -n "$_ghToken" ] && _tokens="github.com=$_ghToken"
    fi

    if [ -n "${config.age.secrets.gitcode_token.path or ""}" ] && [ -f "${config.age.secrets.gitcode_token.path}" ]; then
      _gcToken="$(cat "${config.age.secrets.gitcode_token.path}")"
      [ -n "$_gcToken" ] && _tokens="$_tokens''${_tokens:+ }gitcode.com=$_gcToken"
    fi

    if [ -n "$_tokens" ]; then
      mkdir -p "$_nixConfDir"
      echo "access-tokens = $_tokens" > "$_tokenFile"
      chmod 600 "$_tokenFile"
    else
      [ -f "$_tokenFile" ] && rm -f "$_tokenFile"
    fi
    unset _nixConfDir _tokenFile _tokens _ghToken _gcToken
  '';
}
