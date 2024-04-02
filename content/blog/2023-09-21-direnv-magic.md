+++
title = "direnv magic: instant project environments"
slug = "direnv-magic"
date = 2023-09-21

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["nix", "dev", "swe", "12-factor-app"]
+++

# direnv magic

A very popular project for managing environment variables in projects today is `dotenv`. There are packages for various languages, like NodeJS and PHP. They are built on a simple principle: to load environment variables from a `.env` file located in the project root.

When it comes to the 12 Factor App, managing environment variables in source control is generally discouraged. Instead, environment variables should be set externally, like via the OS or a container orchestrator. However, `dotenv` packages rely on the application loading the `.env` file itself, which means that the application must process a file in order to retrieve its environment configuration.

As a whole, this practice is convenient for local development, but does not lend well to the Config principle of the 12 Factor App.

## an alternative approach

The `direnv` tool allows environment variables to be set based on the directory. With `direnv`, you can define environment variables in a `.envrc` file that will be loaded automatically when entering that directory. This avoids embedding environment configuration in the application code/source control, and makes variables configurable on a per-directory basis. It also entirely avoids having dependencies on files and the entirety of the `dotenv` package itself in a production application. You don't have to conditionally load files - the environment is configured automatically by the shell in local development environments, and configured by the orchestrator in production, like Kubernetes, in the exact same manner: **the environment variables**.

## the behavior

Working with `direnv`, you gain the ability to not only define environment variables in a `.envrc` file per directory, but also automatically configure your shell environment based on that file in other means. For example, you can automatically execute scripts or enter a Nix flake dev shell.

## automated, secure shell environments

Due to the simple approach of a `.envrc` file and automatic nature of `direnv`, it provides a streamlined solution for automatically entering development environments in a snap. It also requires that you permit a directory before `direnv` will load variables or execute scripts, preventing accidental exposure in untrusted directories.

## an example with Nix flakes

Suppose we have a Nix flake in our project repository that defines a development shell environment. With `direnv`, we can automatically enter this shell whenever we cd into the project directory. We'll start with this project's Nix flake, which provides a shell with the necessary tools to build and develop the blog.

```nix
{
  description = "0xc dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { pkgs }: {
    devShells."x86_64-linux".default = pkgs.mkShell {
      packages = with pkgs; [
        git
        zola
      ];

      PROJECT_NAME = "0xc";

      shellHook = ''
        echo $ Started devshell for $PROJECT_NAME
        echo
        uname -v
        echo
        git --version
        echo
        echo "zola version $(zola --version)"
        echo
      '';
    };
  };
}
```

That ensures that I can access both `git` and `zola` in my dev shell.

The `direnv` tool has native support for Nix flakes, so enabling this is a single line in our `.envrc`:

```
use flake
```

That's it! Now in the project, you'll have to permit `direnv` once:

```bash
direnv allow
```

Now you are ready to automatically enter your desired shell environment.

## graceful departures

Not only does `direnv` work well when navigating around projects, it also handles exiting an environment smoothly. Dependencies you may not have had that the Nix flake included in the dev shell, such as `zola`, will no longer be available after leaving the project directory.

```
[ ~/Code/blog ]: which zola
/nix/store/qsaq50z4hln6f86ymvp5f5j01wqg21c3-zola-0.17.2/bin/zola

[ ~/Code/blog ]: cd ..
direnv: unloading

[ ~/Code ]: which zola
which: no zola in (/nix/store/16d7k6ljgy635fz5jn1flnvpx1gnx9cp-glib-2.76.4-bin/bin:/run/wrappers/bin:/home/tcarrio/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:/home/tcarrio/.nix-profile/bin:/etc/profiles/per-user/tcarrio/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/home/tcarrio/.local/bin)
```
