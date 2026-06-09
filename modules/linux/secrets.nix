{ ... }: {
  age.secrets = {
    clash_subscription = {
      file = ../../secrets/clash_subscription.age;
    };
    github_token = {
      file = ../../secrets/github_token.age;
    };
  };
}
