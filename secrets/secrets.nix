let
  # cachyos-desktop user key
  viryoke-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDP1zmZLvEp8TTXCr3NLvS7VRUJcV9uXgn/H+Qs3gEH viryoke@cachyos-desktop";

  # TODO: add macbook key later
  # viryoke-macbook = "ssh-ed25519 AAAA... viryoke@macbook";

  allKeys = [ viryoke-desktop ];
in
{
  "clash_subscription.age".publicKeys = allKeys;
  "github_token.age".publicKeys = allKeys;
}
