# 0xc

Notes and posts and more gathered and altogether maniacally tossed together.

## stack

- [Zola]
- [Git]
- [GitHub Actions]
- [GitHub Pages]
- [Zola Deploy Action]
- [Zola After Dark Theme]
- [Direnv]
- [Nix]

[Zola] is a static site generator written in Rust which provides the bulk of functionality in this blog. Zola has many themes available, in my case I'm using the [Zola After Dark Theme]. The repository is kept very minimal since I'm utilizing [Git] submodules to reference the external repository.

[GitHub Actions] is utilized for deploying to [GitHub Pages]. The [Zola Deploy Action] provides a simple way to configure CI jobs to execute. In my case, I am able to build for PRs and publish in `main`.

[Nix] makes it simple across systems to quickly start up a shell with a Zola executable in the path and everything else it needs.

## develop

I'm going to assume you're me and have [Nix] and [Direnv] installed because I'm the only real consumer of said repository so if I'm not me then something has gone horribly wrong. Tag along.

```bash
nix develop

# $ Started devshell for 0xc
#
# [0xc]$ ...

zola serve

# Web server is available at http://127.0.0.1:1111...
```

That's it. [Nix] drops you into a shell with all tooling necessary. This repository is pretty lightweight with just `git` and `zola` but the premise applies everywhere. Feel free to check it out!

<!-- References: in no particular order but maybe ascending -->

[Direnv]: https://direnv.net/
[Git]: https://git-scm.org
[GitHub Actions]: https://github.com/features/actions
[GitHub Pages]: https://pages.github.com/
[Nix]: https://nixos.org
[Zola After Dark Theme]: https://github.com/getzola/after-dark
[Zola Deploy Action]: https://github.com/shalzz/zola-deploy-action
[Zola]: https://getzola.org
