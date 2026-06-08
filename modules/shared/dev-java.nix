{ pkgs, ... }: {
  home.packages = with pkgs; [
    jdk21
    maven
    gradle
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
  };
}
