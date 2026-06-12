{ config, ... }: {
  home.file.".config/pixi/config.toml".text = ''
    [mirrors]
    "https://pypi.org/simple" = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
  '';

  home.activation.aiLearningPixi = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    _aiDir="${config.home.homeDirectory}/Workspace/ai-learning"
    mkdir -p "$_aiDir"
    [ ! -f "$_aiDir/pixi.toml" ] && cp ${../../templates/ai-learning/pixi.toml} "$_aiDir/pixi.toml" && chmod +w "$_aiDir/pixi.toml"
    [ ! -f "$_aiDir/.gitignore" ] && cp ${../../templates/ai-learning/.gitignore} "$_aiDir/.gitignore" && chmod +w "$_aiDir/.gitignore"
    unset _aiDir
  '';
}
