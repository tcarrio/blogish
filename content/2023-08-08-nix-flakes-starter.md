+++
title = "Nix Flakes Starter"
slug = "nix-flakes-starter"
date = 2023-08-08
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["functional", "open source", "automation", "build tools"]
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

### Outputs

<!-- TODO -->


<!-- References -->

[nixos-wiki-flakes]: https://nixos.wiki/wiki/Flakes
[flake schema]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format