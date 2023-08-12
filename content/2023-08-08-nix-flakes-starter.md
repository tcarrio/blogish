+++
title = "Nix Flakes Starter"
slug = "nix-flakes-starter"
date = 2023-08-11

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["functional", "open source", "automation", "build tools", "nix"]
+++

## What is Nix

Nix consists of many things, and because of the common naming of "Nix" throughout it all, it can be confusing beyond just the surface level.

- **Nix**OS: An Operating System powered by Nix configurations and package manager
- **Nix** language: A declarative, pure, functional, domain-specific language
- **Nix** package manager: A purely functional package manager

As it pertains to this post on Nix Flakes, we're mostly talking about the Nix _language_, which is used to implement a flake, and the Nix _package manager_, which can utilize and interact with flakes.

## Nix Flakes

If you look up Nix flakes, the first article you'll find it likely [the one on the NixOS Wiki][nixos-wiki-flakes]. This same article also clearly states at the top

> **Nix flakes** are an _experimental feature_ of the Nix package manager.

Well that sounds dangerous, unstable, fragile, etc. etc. Yeah it does. But a lot of the Nix community believe that Nix flakes are **The Future**. And it's been considered "experimental" for many years now, to be clear. But this post is less focused on the political discussion of flakes' stability and future and more on what it is, how to get started, and some example use cases.

### What Are Flakes

Flakes provide a kind of specification around how to define a Nix expression, how dependencies are managed between it and others, and provide general improvements to the Nix ecosystem such as reproducibility and composability. A flake consists of a file system tree which contains a `flake.nix` file in its root directory. You would expect to see something like the following in a Nix flake:

```
[0xc@sys ~]$ tree ./devshells
.
├── flake.lock
├── flake.nix
└── README.md

1 directory, 3 files
```

This `flake.nix` file offers a uniform [schema][flake schema] that allows other flakes to be referenced as dependencies, and the values produced by the Nix expression in the `flake.nix` file follow a specific structure to support certain use cases. Since a flake can reference others in a way that supports the lockfile mechanism, even composed Nix flakes support reproducibility.

The `nix` CLI also supports flakes as an experimental feature.

## Creating a Flake

With the `nix` CLI, you can run:

```
[0xc@sys ~]$ mkdir flake-test
[0xc@sys ~]$ cd flake-test
[0xc@sys ~]$ nix flake init
```

## Crafting a Flake File

As mentioned, there is a uniform schema to Flake files. The following attributes are defined at the top-level in a Nix flake:

Flake schema

The flake.nix file is a Nix file but that has special restrictions (more on that later).

**description**: a string describing the flake.
**inputs**: an attribute set of all the dependencies of the flake.
**outputs**: a function of one argument that takes an attribute set of all the realized inputs, and outputs another attribute set whose schema is described below.
**nixConfig**: an attribute set of values which reflect the values given to nix.conf. This can extend the normal behavior of a user's nix experience by adding flake-specific configuration, such as a binary cache.

[_Reference_][nixos-wiki-flakes]

The `description` is very straightforward, but let's break down the remaining attributes, particularly `inputs` and `outputs`.

### Inputs

<!-- TODO -->

The `inputs` schema allows the definition of zero or more flakes as references to the `outputs` schema. Any external requirements for the flake will be defined here, whether it's a CLI tool, library, or service.

The `inputs` allows you to define any number of flake inputs as local paths, Git repositories over SSH or HTTPS, and special shorthands for GitHub.

```nix
inputs = {
    # specifying a GitHub repository by org/repo and branch name ("master")
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    # specifying a Git repository by URL, using HTTPS or SSH protocol
    https-example.url = "git+https://git.example.test/org/repo?ref=branch&rev=deadbeef";
    ssh-example.url = "git+ssh://git.example.test/org/repo?ref=branch&rev=deadbeef";

    # specifying a shallow clone (won't clone the `.git` directory)
    shallow-clone-example.url = "git+file:/local/project/path?shallow=1";

    # specifying a local directory
    relative-path-dir-example.url = "path:/local/project/path";
    absolute-path-dir-example.url = "/local/project/path"

    # specifying a non-flake input
    not-a-flake = {
        url = "github:0xc/nonflake/branch";
        flake = false;
    };

    # specifying that the dependency's `inputs.nixpkgs` should inherit from this flake
    inherit-nixpkgs-example = {
        url = "github:another/example";
        inputs.nixpkgs.follows = "nixpkgs";
    };
}
```

These inputs and their controls give flakes substantially more power over deterministic build processes and consistency across the dependencies utilized within the inputs and the flake definitions' resources.

### Outputs

The magic of a flake. This is where we actually define the resources of a flake, and the schema provides us several mechanisms for things like development shells, applications, build targets, overlays, and more.

#### Applications

These are predefined run targets in your flake. These are suitable for packaging your application so you can execute it consistently.

Utilized with the `nix run` command. Within the outputs, you can specify these by doing:

```nix
apps.${system}.<target-name> = {
    type = "app";
    program = "run-the-thing";
};
```

This can be executed using `nix run .#target-name`.

If you want to execute this with arguments you would run `nix run .#target-name -- ...`

#### Development shells

Dev shells are an extremely useful feature of flakes. There are some differences to the legacy Nix shell and the new `devShells` functionality of Nix flakes.

**TODO: Add more info on these differences**

You can define `devShells` in the `outputs`, and the most convenient way is using the `mkShell` function exposed in the `nixpkgs` input argument. Suppose you have the nixpkgs repository input as `pkgs`, then you would be able to do

```nix
outputs = { self, pkgs }: {
    devShells = {
        default = pkgs.mkShell {
            packages = [pkgs.git];
        };

        go = pkgs.mkShell {
            packages = [pkgs.go];
        }
    };
};
```

The default target can be invoked with `nix develop .` and in this case will provide the `git` package, available in your PATH.

To invoke the `go` target, you would do `nix develop .#go`. Then we'd have the Go toolchain loaded and available so we could run or compile some Go code with `go build main.go`.


#### Overlays

Overlays are an interesting albeit somewhat advanced topic in Nix, but the goal of overlays is to support advanced flake customization capabilities, such as overriding packages within a flake. Overlays supercedes an old approach to this which was limited in scope to this one simple use case, called `packageOverride` and `overridePackages`.

Overlays are defined as a nested function whose first argument is `final` and second argument is `prev`. 

The following diagram visualizes the flow of the overlay function components throughout the system.

```
+---------------------+-----------------------+------------------------------+
|                     |                       |                              |
|                     |                       |                              |
|  +-------------+    |  +-------------+      |  +--------------+            |
|  |             |    |  |             |      |  |              |            |
|  +-----+       |    |  +-----+       |      |  +-----+        |            |
+->|final|       |    +->|final|       |      +->|final|        |            |
   +-----+       |       +-----+       |         +-----+        |            |
   |             |       |             |         |              |            |
   |    main     +---+   |             +--+      |              +------+     |
   |             |   |   |             |  |      |              |      |     |
   |             |   |   +-----+       |  |      +-----+        |      |     |
   |             |   +-->|prev |       |  |    +>|prev |        |      |     |
   |             |   |   +-----+       |  |    | +-----+        |      |     |
   |             |   |   |             |  |    | |              |      |     |
   +-------------+   |   +-------------+  |    | +--------------+      |     |
                     |                    |    |                       |     |
                     |                    |    |                       |     |
                     |                    |    |                       |     |
                     |                  +-v--+ |                     +-v--+  |
                     |                  |    | |                     |    |  |
                     +------------------> // +-+---------------------> // +--+
                                        +----+                       +----+
```

Within your flake, you can define overlays with the following:

```nix
# Specifying an overlay by "name"
overlays."<name>" = final: prev: { };
# Specifying the default overlay
overlays.default = final: prev: { };
```

These can be utilized in interesting ways, a good example is how the NodeJS runtimes and NPM dependencies like [Yarn] can be configured with overlays to ensure the correct underlying runtime is used for the package.

My [devshells] repository showcases this. A _paraphrased_ version of the code would be:

```nix
let
    node16Overlay = self: super: {
        nodejs = self.nodejs-16_x;
    };
    yarn16Overlay = self: super: {
        yarn = super.yarn.override {
            nodejs = self.nodejs-16_x;
        };
    };
    pkgsNode16 = import nixpkgs {
        inherit system;
        overlays = [node16Overlay yarn16Overlay];
    };
in rec {
    devShells = {
        default = pkgs.mkShell {
            packages = with pkgsNode16; [
                nodejs-16_x
                yarn
            ];
        };
    };
}
```

#### And more

There are _even more_ use cases for Nix flake outputs, that I won't dive into much here. The resources mentioned throughout this article are extremely useful though, and there is tremendous depth to Nix that you can dive into.


<!-- References -->

[nixos-wiki-flakes]: https://nixos.wiki/wiki/Flakes
[flake schema]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format
[Yarn]: https://yarnpkg.com/
[devshells]: https://github.com/tcarrio/devshells