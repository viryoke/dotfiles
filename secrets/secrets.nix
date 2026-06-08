let
  viryoke = "ssh-ed25519 AAAA...REPLACE_WITH_ACTUAL_PUBLIC_KEY... viryoke@desktop";
  cachyos-desktop = "ssh-ed25519 AAAA...REPLACE_WITH_ACTUAL_PUBLIC_KEY... root@cachyos-desktop";
  macbook = "ssh-ed25519 AAAA...REPLACE_WITH_ACTUAL_PUBLIC_KEY... viryoke@macbook";

  allKeys = [ viryoke cachyos-desktop macbook ];
in
{
  "ssh_id_ed25519.age".publicKeys = allKeys;
  "openai_api_key.age".publicKeys = allKeys;
  "github_token.age".publicKeys = allKeys;
  "tailscale_auth_key.age".publicKeys = allKeys;
  "clash_subscription.age".publicKeys = allKeys;
}
