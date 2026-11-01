+++
title = "Previewing ZFS Anyraid With nix"
description = "Taking a look at new zfs `anyraid` vdev."
date = 2025-09-21

[taxonomies]
tags = ["zfs", "nix"]
+++

Klara Systems is in the process of upstreaming a new ZFS vdev type.

> Anyraid allows devices of mismatched sizes to be combined together into a
> single top-level vdev. In the current version, Anyraid only supports
> mirror-type parity, but raidz-type parity is planned for the near future.
> -- <cite>[OpenZFS PR](https://github.com/openzfs/zfs/pull/17567)</cite>

This may take a while to merge and get released, but I'm excited to try this out.

# Building With Nix

nixpkgs packages several versions of zfs in the following manner

```bash
tree pkgs/os-specific/linux/zfs/
pkgs/os-specific/linux/zfs/
├── 2_2.nix
├── 2_3.nix
├── generic.nix
└── unstable.nix
```

generic.nix provides a function to compile zfs, and 2_2.nix, 2_3.nix and unstable.nix call this function supplying the hash.  

So I could just:
- modify generic.nix to accept github owner and repository as argument since it's hard-coded to openzfs project
- fix the fact that master branch renamed arc_summary to zarcsummary 
- add anyraid.nix with customized parameters
- add `zfs_anyraid` package wherever `zfs_unstable` is defined

See [diff](https://github.com/NixOS/nixpkgs/compare/master...svistoi:nixpkgs:anyraid)

# NixOS Integration Testing

nixpkgs contains some zfs tests, though none for anyraid vdev.  However for sanity checking that it builds, I wanted to run the tests

```bash
nix run .#nixosTests.zfs.anyraid.driver
```

# Deploying To A Server

I then configure my fork as flake input `nixpkgs-anyraid.url = "github:svistoi/nixpkgs/anyraid";` and build a server nixosConfigurations

with following options
```nix
boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_6_16;
boot.zfs.package = lib.mkForce pkgs.zfs_anyraid;
boot.supportedFilesystems = ["zfs"];
networking.hostId = "67262970";
```

The server configuration is out of scope of this.  I've learned a lot about about flake layouts from some notable repositories:
- https://github.com/MatthewCroughan/nixcfg
- https://github.com/wimpysworld/nix-config
- https://github.com/srid/nixos-config
- https://github.com/jakehamilton/config

# Creating A Pool With Anyraid vdev

```bash
zpool create -f tank anyraid <list of devices>
```
