+++
title = "NixOS Secrets with Agenix and Systemd"
slug = "nixos-agenix-systemd-secrets"
date = 2023-09-19

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["nix", "open source", "secrets", "sysadmin"]
+++

## Prologue: What is NixOS?

I will assume that you're here to learn more about managing secrets on a NixOS system. If you want to learn more about NixOS itself, check out the [NixOS manual]. There is a lot to catch up on.

> FYI, I have more updates to push to this blog post, but I want it available in case others run into the same issue I did for utilizing `agenix` in Systemd service units.

## Managing Secrets on NixOS

NixOS being an entirely automated system has to conquer some of the same battles fought by other tools in the same space- Terraform for example automates the provisioning of resources and systems, and needs a way to maintain secrets on those. These should be kept as safe as possible, and as such has primitives around secrets. NixOS similarly has many tools that can be used, some reused across the industry like `age` and `sops`. They provide a full comparison of these tools and their integration with the NixOS system [here][NixOS Secrets Wiki].

## Age and Agenix

The tool [age] is a modern encryption tool designed to be simple to work with, requires no configuration out-of-the-box, and is designed to be composable. This makes it a great tool to use with Nix. The [agenix] project utilizes `age` in order to provide a pattern for managing secrets, and is separated into the CLI and the NixOS module. The CLI is used for interacting with secrets, and a `secrets.nix` file is provided in order to configure the target recipients for secret files, with these files existing in paths beneath the root directory of that `secrets.nix` file. Within your NixOS configuration, you can import the module, and then reference existing secrets and how they should be utilized in the system.

## Where Does Systemd Come Into Play?

Well, I was building off an existing blog post by Tailscale on how to configure a NixOS server for Minecraft on a Tailnet. I'm mostly concerned on automatically wiring up a Tailscale service securely on my NixOS servers, so I wanted to apply the same principle while utilizing one of the secrets managing tools.

So in this post, I'll demonstrate this in the way I implemented the NixOS configuration to utilize `agenix` for automatic Tailscale connection with a secret token, managed in code securely with `age` encryption.

## TODO

!! I have to expand on a lot of this content more, but I want to dump some code snippets before I lose context and sleep.

### secrets.nix

```nix
let
    keys = [ "ssh-rsa foobarbaz... host@system" ];
in
{
    "tailscale.age".publicKeys = keys;
}
```

### tailscale.nix

We'll break this out into four sections, but they can all be managed in one file.

```nix
# tailscale.nix
{ config, pkgs, ... }: {
    # the nix expression containing age secret configuration, enabling tailscale packages and service, networking rules, and the systemd autoconnect unit file

    # Here, we mount the token file
    age.secrets.tailscale-token = {
        file = ./tailscale.age;
        owner = "root";
        group = "root";
        mode = "600";
    };

    # We'll install the package to the system, enable the service, and set up some networking rules
    environment.systemPackages = with pkgs; [ tailscale ];
    services.tailscale.enable = true;
    networking = {
        firewall = {
            checkReversePath = "loose";
            allowedUDPPorts = [ config.services.tailscale.port ];
            trustedInterfaces = [ "tailscale0" ];
        };
    };

    # Here is the magic, where we automatically connect with the tailscale CLI by passing our secret token, and ensure that agenix mounting was completed
    systemd.services.tailscale-autoconnect = {
        description = "Automatic connection to Tailscale";

        # We must make sure that both the tailscale service and the agenix file mounting are running / complete before trying to connect to tailscale
        after = [ "network-pre.target" "tailscale.service" "run-agenix.d.mount" ];
        wants = [ "network-pre.target" "tailscale.service" "run-agenix.d.mount" ];
        wantedBy = [ "multi-user.target" ];

        # Set this service as a oneshot job
        serviceConfig.Type = "oneshot";

        # Run the following shell script for the job, passing the mounted secret for the tailscale connection
        script = with pkgs; ''
            # wait for tailscaled to settle
            sleep 2

            # check if we are already authenticated to tailscale
            status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
            if [ $status = "Running" ]; then
                exit 0
            fi

            # otherwise authenticate with tailscale
            ${tailscale}/bin/tailscale up -authkey "$(cat "${config.age.secrets.tailscale-token.path}")"
        '';
    };
}
```

## tl;dr

Agenix itself mounts files with Systemd in the `run-agenix.mount` unit. As such, you can utilize the mechanism of Systemd service definitions, namely `after` and `wants`, in order to ensure that the `agenix` secret mounts have been completed prior to starting your service. In this way, you can be sure that the secret is available.

If you want to read more on NixOS configuration, you can check out my [nix-config] repository which maintains several of my systems.

<!-- References -->

[NixOS Manual]: https://nixos.org/manual/
[NixOS Secrets Wiki]: https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes
[age]: https://age-encryption.org/
[agenix]: https://github.com/ryantm/agenix
[nix-config]: https://github.com/tcarrio/nix-config