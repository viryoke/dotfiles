{ config, ... }:
{
  # Inject GitHub access token from agenix secret into a separate nix conf file.
  # Nix reads all *.conf files in the config dir, so this won't conflict with
  # the main nix.conf managed outside home-manager.
  home.activation.nixGithubToken = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    _nixConfDir="${config.home.homeDirectory}/.config/nix"
    _tokenFile="$_nixConfDir/github-access-tokens.conf"
    if [ -n "${config.age.secrets.github_token.path or ""}" ] && [ -f "${config.age.secrets.github_token.path}" ]; then
      _ghToken="$(cat "${config.age.secrets.github_token.path}")"
      if [ -n "$_ghToken" ]; then
        mkdir -p "$_nixConfDir"
        echo "access-tokens = github.com=$_ghToken" > "$_tokenFile"
      fi
    else
      # Clean up stale token file if secret is not available
      [ -f "$_tokenFile" ] && rm -f "$_tokenFile"
    fi
    unset _nixConfDir _tokenFile _ghToken
  '';
}
