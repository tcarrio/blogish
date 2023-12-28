+++
title = "Nvidia on NixOS"
slug = "nvidia-on-nixos"
date = 2023-11-15

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["nix", "graphics"]
+++

# Nvidia on NixOS

NixOS is a really awesome Linux distribution. The declarative, functional approach of defining a configuration that applies consistently to your system is an amazing feat. I have worked with principles akin to this in my professional work for years now, applying infrastructure-as-code methodologies with Terraform & HCL, Pulumi, and Ansible. So, I have not only installed NixOS on my development workstations and home servers, but also on my personal desktop. This device has an Nvidia GTX 1080Ti, and this blog encompasses some of the journey- the highs and the lows- of setting this system up.

> ⚠️ This blog post will continue to evolve, as I document more shortcomings and friction in the NixOS journey with Nvidia.

## The Highs

Declarative configuration is often much more concise and hands-off than the more imperative tools. Offerings like Ansible get you much closer to this, but not all the way. NixOS is truly **holistic** in its approach- with everything being possible to manage with Nix expressions, with the help of [home-manager] particularly. These can be broken out and shared between systems. Custom packages can be defined in one place and reused across all of your NixOS systems. You can reference my [nix-config]

## The Lows

Declarative has its downsides. The interface provided by the system for **what you want** is extremely important as to allow the implicit **how we do it** to be configurable. Suppose you have a system with an Nvidia graphics card- with NixOS, you can enable most of the behavior you'd like to have with this fairly easily. You include several lines such as which driver you want to use (proprietary vs open-source vs nouveau) as on example. The Nix expression is executed and determines the resulting system configuration.

This is the catch- suppose that how the system is configured does not align with your desires, then you better hope that overriding this is easy or even possible based on what NixOS offers.

In the case of this Nvidia example- many things *just work*, but there are a couple cases that *do not*, and these are the pain points that leave you stuck for weeks without a 100% functional system.

## The History

I switched from an Arch Linux system to NixOS in the desire to more easily maintain my workstation in entirety. My Arch system was over 6 years old and had reached over 1000 packages installed. What were half of these? What had I done to configure them? What configurations could be cleaned up? The evidence is scattered across the filesystem, only clear to those most familiar with the configuration rules of each particular software I had. This was a situation I wanted to escape- so I could better understand everything I had and also to be better able to maintain that system over the long-term.

Documentation separate from code tends to decay. Once it's committed, the drift begins. Code **as** documentation breaks from this problem at its core- you don't need to have entirely separate docs from your code- often times having a service enabled or configured in some way is **clear as day**.

```nix
{
    services."${serviceName}" = {
        enabled = true;
        customConfig = ''
            something something dark side
        '';
    };
}
```

Even enabling Nvidia hardware is remarkably simple!

```nix
{
    hardware.nvidia = with config.boot.kernelPackages.nvidiaPackages; {
        package = stable;
    };
}
```

The NixOS docs provide a list of which packages are available plainly [here](nvidia-driver-versions). You can now readily switch out various Nvidia driver versions with just a few characters. Want to run the latest beta version?

```nix
{
    hardware.nvidia = with config.boot.kernelPackages.nvidiaPackages; {
        package = beta;
    };
}
```

## Software-rendering: Not HOW I would have done it

This is the moment that **declarative** configuration became a pain. As I mentioned before, I replaced my Arch Linux system. I had a few games installed: Overwatch on Lutris and Elder Scrolls IV: Oblivion. These were the only two I played much of.

I installed Steam through my Nix config. Super easy.

I installed Elder Scrolls IV: Oblivion. Turned on the compatibility mode for Proton. Super easy.

Started up the game: 0.00000001 FPS.

It would appear I'm using software rendering. But why? Why in the world would my system even want to use software rendering when it has a **perfectly powerful discrete graphics card**?

Well, let's see what's available.

```sh
vulkaninfo --summary
```

This pops out a massive list of info, but the final section I'm including here is the most important piece:

```
Devices:
========
GPU0:
	apiVersion         = 1.3.260
	driverVersion      = 545.29.2.0
	vendorID           = 0x10de
	deviceID           = 0x1b06
	deviceType         = PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
	deviceName         = NVIDIA GeForce GTX 1080 Ti
	driverID           = DRIVER_ID_NVIDIA_PROPRIETARY
	driverName         = NVIDIA
	driverInfo         = 545.29.02
	conformanceVersion = 1.3.6.0
	deviceUUID         = 61ede7bb-89b8-5ef5-50a7-899e37452c5d
	driverUUID         = aa471f58-d70e-5a93-a86b-06356da49d1c
GPU1:
	apiVersion         = 1.3.246
	driverVersion      = 0.0.1
	vendorID           = 0x10005
	deviceID           = 0x0000
	deviceType         = PHYSICAL_DEVICE_TYPE_CPU
	deviceName         = llvmpipe (LLVM 16.0.6, 256 bits)
	driverID           = DRIVER_ID_MESA_LLVMPIPE
	driverName         = llvmpipe
	driverInfo         = Mesa 23.1.9 (LLVM 16.0.6)
	conformanceVersion = 1.3.1.1
	deviceUUID         = 6d657361-3233-2e31-2e39-000000000000
	driverUUID         = 6c6c766d-7069-7065-5555-494400000000
```

It would appear that a `llvmpipe` device is automatically configured here. But why? I didn't turn on Mesa myself, what is a Mesa driver doing here?

Well- there are plenty of packages that may rely on Mesa. In fact, a large number of them will. So this is going to be a dependency in the system and automatically be installed.

### Solution?

Honestly, I've tried a number of things so far: from overlays and explicit configurations to not include mesa in the stack when configuring opengl.

I'll update the post with a **Solved:** tag once I make it there. For now, I suffer. 😭

<!-- Reference -->

[home-manager]: https://nix-community.github.io/home-manager
[nix-config]: https://github.com/tcarrio/nix-config
[nvidia-driver-versions]: https://nixos.wiki/wiki/Nvidia#Determining_the_Correct_Driver_Version