let
  viryoke-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgKVg1J+1Epm+Dbdgu2q9jtuyYrf3He+T6dAUvoZ8lf viryoke@cachyos-desktop";
  viryoke-macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBJ3saQcwyNpXk+Fu4crDH0tUuSw3liEd0S+gayJ4kH viryoke@macbook";

  allKeys = [ viryoke-desktop viryoke-macbook ];
in
{
  "github_token.age".publicKeys = allKeys;
  "gitcode_token.age".publicKeys = allKeys;
}
