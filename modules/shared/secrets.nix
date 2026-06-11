{ ... }: {
  age.secrets = {
    github_token = {
      file = ../../secrets/github_token.age;
    };
    gitcode_token = {
      file = ../../secrets/gitcode_token.age;
    };
  };
}
