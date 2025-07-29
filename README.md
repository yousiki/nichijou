# nichijou

This repository contains my personal NixOS & Nix-darwin configurations.

## Overview

The nix flake is divided into two parts:

- `nix/flake-parts`: flake outputs generated using [flake-parts](https://github.com/hercules-ci/flake-parts) and flake modules from the ecosystem.
  - `nix/flake-parts/devshells.nix`: development shells.
  - `nix/flake-parts/formatter.nix`: all-in-one code formatter.
- `nix/snowfall`: a collection of NixOS & Nix-darwin modules and configurations, managed using [snowfall](https://github.com/snowfallorg/lib).

## Tags-based configuration

All modules in `nix/snowfall/modules` are automatically imported to all host configurations (and home-manager configurations).
Instead of enabling modules by selectively importing modules, the modules are managed using tags.
The tags are defined in `nix/snowfall/tags`, assigning each host with a set of tags, and the modules configure the system correspondingly.

Hence, **never import modules directly**, but instead please feel free to copy the code that you need from these modules for your own usage.
