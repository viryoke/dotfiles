{ ... }: {
  age.secrets = {
    github_token = {
      file = ../../secrets/github_token.age;
    };
  };
}
