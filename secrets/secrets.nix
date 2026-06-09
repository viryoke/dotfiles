let
  viryoke-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDP1zmZLvEp8TTXCr3NLvS7VRUJcV9uXgn/H+Qs3gEH viryoke@cachyos-desktop";
  viryoke-macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBJ3saQcwyNpXk+Fu4crDH0tUuSw3liEd0S+gayJ4kH viryoke@macbook";

  allKeys = [ viryoke-desktop viryoke-macbook ];
in
{
  "clash_subscription.age".publicKeys = allKeys;
  "github_token.age".publicKeys = allKeys;
}
