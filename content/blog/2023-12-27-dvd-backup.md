+++
title = "DVD Backups on Linux"
slug = "dvd-backups-on-linux"
date = 2023-12-27

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["nix", "dvd", "backup", "linux"]
+++

# DVD Backup

I recently went through the process up backing up a series of DVDs from my partners childhood. Since this process entailed multiple systems and both CPU and GPU hardware for video rendering, I figured I would capture some the steps at a high level that I took to accomplish the task.

## Background: The Hardware

During this run-through I utilized a number of systems. Namely, I pulled out my [Lenovo T510][lenovo-t510-nix] to make use of the DVD bay, my DiskStation 420 for intermediate network storage and backup of the DVD and MP4 files, and [my personal desktop][glass-nix] with both an AMD Ryzen and GTX 1080Ti- both come into play in the following.

## Backing up DVDs with dvdbackup

Unsurprisingly, the tool `dvdbackup` exists as a means to backup DVDs. It mostly retains the same filesystem structure as the mounted DVD, but it's a useful tool for inspecting and saving videos from a DVD.

```sh
# CWD must be where you want to save your DVD backup
dvdbackup -i /dev/sr0 -o . -M
```

What you'll end up with is the main feature of the DVD but in the typical hierarchy of the original DVD itself, had you mounted `/dev/sr0` directly.

> ℹ️ If you need to recover a damaged disk, you may need to use a tool like `dvdisaster` or `ddrescue`. There is no guarantee your data is recoverable.

## Splicing the video files

The VOB files can be directly concatenated, and is this is exactly how you would perform a splicing of the video content before conversion.

```sh
cat VTS_01_*.VOB > video.vob
```

> ⚠️ If you include the `VIDEOTS.VOB` file you may encounter audio issues with your spliced video. 

## Syncing to the SFTP server

```sh
scp ./video.vob 0xc@nas-ds418-00:/path/to/target/video.vob
```

All of your operations from here _can_ be entirely remote, if you utilize a filesystem mount for the SFTP server, and have a stable connection. In one case I encountered a packet failure and resorted to copying to and from my local system responsible for the conversions going forward.

> ℹ️ For hostnames, I'm utilizing **[tailscale]** for both private P2P networking **and** DNS resolution of private hosts.

## Converting from VOB to MP4

This was done in two separate modes: CPU and GPU. I'm on NixOS, so for me I dropped into separate shells of non-NVENC-supported ffmpeg and an NVENC-supported ffmpeg.

One key component is that for the DVD videos (which are 420p) the best (the most 1:1 comparatively) format to target is `yuv420p`.

### On-network conversion

Suppose you have an SFTP server, you can mount that locally and then perform the following conversions directly in the network share.

```sh
cd /run/user/1000/gvfs/sftp\:host\=nas-ds418-00\,user\=0xc/path/to/target
```

Now, within the network share, you could run the following instructions for CPU/GPU.

> ℹ️ Alternatively, `scp` the VOB files to the local machine first

### CPU acceleration

```sh
# without NVENC support

ffmpeg -i video.vob -vf format=yuv420p video.mp4
```

### GPU acceleration

```sh
nix-shell -p ffmpeg-full

# in the subshell

ffmpeg -hwaccel_device 0 -hwaccel cuda -i video.vob -c:v h264_nvenc -vf format=yuv420p video.mp4
```

## Enhancements

A project I was considering toying around with that might have made it simpler to work is the [Network Block Device (NBD) project][nbd]. This exists as a user-space tool for interacting with block devices that are mounted over the network. As an example, a T510 with a DVD disk drive accessible over the network could expose the disk device via NBD, and my desktop could mount it. This would save me from having to switch back and forth between the two systems.

With NixOS, this is directly supported as a *service*:

```nix
_:

{
  services.nbd.server = {
    enable = true;
    listenAddress = "0.0.0.0";

    exports = {
      dvd-drive = {
        path = "/dev/sr0";
        allowAddresses = [ "10.0.0.0/8" ];
      };
    };
  };
}
```

Then, mount the share from another system with

```sh
# as root
nbd-client t510 -N dvd-drive /dev/sr0
```

Now you can open the network-attached DVD via VLC as though it were a local device:

```sh
vlc /dev/sr0
```

Next, enjoy T2: Judgement Day 👋

<!-- References -->

[lenovo-t510-nix]: https://github.com/tcarrio/nix-config/blob/main/nixos/workstation/t510/default.nix
[glass-nix]: https://github.com/tcarrio/nix-config/blob/main/nixos/workstation/glass/default.nix
[nbd]: https://nbd.sourceforge.io/