{ config, ... }: {
  home.file.".config/pixi/config.toml".text = ''
    [mirrors]
    "https://pypi.org/simple" = ["https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"]
  '';

  home.activation.aiLearningDevenv = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    _aiDir="${config.home.homeDirectory}/Workspace/ai-learning"
    mkdir -p "$_aiDir"
    [ ! -f "$_aiDir/devenv.nix" ] && cp ${../../templates/ai-learning/devenv.nix} "$_aiDir/devenv.nix" && chmod +w "$_aiDir/devenv.nix"
    [ ! -f "$_aiDir/devenv.yaml" ] && cp ${../../templates/ai-learning/devenv.yaml} "$_aiDir/devenv.yaml" && chmod +w "$_aiDir/devenv.yaml"
    [ ! -f "$_aiDir/.gitignore" ] && cp ${../../templates/ai-learning/.gitignore} "$_aiDir/.gitignore" && chmod +w "$_aiDir/.gitignore"
    unset _aiDir
  '';
}
