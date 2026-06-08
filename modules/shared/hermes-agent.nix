{
  # Hermes Agent uses Python + uv from dev-python.nix
  # This module provides workspace aliases only
  programs.zsh.shellAliases = {
    hermes = "cd ~/Workspace/hermes-agent && uv run python main.py";
    hermes-dev = "cd ~/Workspace/hermes-agent && uv run python main.py --dev";
  };
}
