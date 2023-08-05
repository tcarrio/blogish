{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env.PROJECT_NAME = "0xc";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    zola
  ];

  enterShell = ''
    hello
    git --version
    zola --version
  '';

  # https://devenv.sh/languages/
  # languages.nix.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = "echo hello from $PROJECT_NAME";

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";
}
