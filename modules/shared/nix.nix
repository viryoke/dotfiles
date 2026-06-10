{ config, ... }:
{
  # Inject GitHub access token from agenix secret into ~/.config/nix/nix.conf.
  # Nix only reads nix.conf (not other *.conf files), so we append/update
  # the access-tokens line in-place.
  home.activation.nixGithubToken = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    _nixConf="${config.home.homeDirectory}/.config/nix/nix.conf"
    if [ -n "${config.age.secrets.github_token.path or ""}" ] && [ -f "${config.age.secrets.github_token.path}" ]; then
      _ghToken="$(cat "${config.age.secrets.github_token.path}")"
      if [ -n "$_ghToken" ]; then
        mkdir -p "$(dirname "$_nixConf")"
        # Remove existing access-tokens line (if any), then append fresh one
        if [ -f "$_nixConf" ]; then
          sed -i '/^access-tokens\s*=/d' "$_nixConf"
        fi
        echo "access-tokens = github.com=$_ghToken" >> "$_nixConf"
      fi
    fi
    # Clean up stale separate conf file (Nix doesn't read extra *.conf files)
    rm -f "${config.home.homeDirectory}/.config/nix/github-access-tokens.conf"
    unset _nixConf _ghToken
  '';
}
