# fluxer-releases

Automated NixOS-compatible mirror for [Fluxer](https://fluxer.app) AppImage releases.

Fluxer is distributed only as an AppImage. This repo:

- Mirrors every release to GitHub Releases for stable, versioned URLs
- Exposes a Nix flake with a working NixOS wrapper (`appimageTools.wrapType2`)
- Preserves the original AppImage intact alongside the wrapper
- Maintains `versions.json` as a public audit trail of all SHA256 hashes

> [!CAUTION]
> As of the writing of this note, Fluxer's release endpoints don't provide a sha256 hash. You can verify yourself here: https://api.fluxer.app/dl/desktop/stable/linux/x64/latest
>
> This means that I have to currently assume the hashes I calculate are correct. I will be keeping an eye on it and update the repo if need be.

---

## Usage (NixOS flake input)

In your `flake.nix`:

```nix
inputs = {
  fluxer.url = "github:flurbudurbur/fluxer-releases";
  # no follows needed — fluxer pins its own nixpkgs
};
```

Then use the package in your config:

```nix
environment.systemPackages = [
  inputs.fluxer.packages.x86_64-linux.fluxer
];
```

To upgrade to a new Fluxer release:

```sh
nix flake update fluxer   # in your nixos-system directory
```

---

## Building locally

```sh
git clone https://github.com/flurbudurbur/fluxer-releases
cd fluxer-releases
nix build .#fluxer
./result/bin/fluxer
```

The build produces:

- `result/bin/fluxer` — NixOS wrapper (FHS sandbox via `wrapType2`)

The original AppImage is available as a GitHub Release artifact on each tagged release.

---

## Verification

All releases are listed in [`versions.json`](versions.json) with SHA256 hashes in both hex and Nix SRI format.

To verify a downloaded AppImage against the audit trail:

```sh
# Get expected hash for a version
jq '.[] | select(.version == "0.0.8") | .sha256_hex' versions.json

# Download the AppImage from the GitHub Release, then verify
sha256sum fluxer-0.0.8-x86_64.AppImage
```

---

## How it works

A GitHub Actions workflow ([`.github/workflows/check-update.yml`](.github/workflows/check-update.yml)) runs daily at 06:00 UTC:

1. Queries `https://api.fluxer.app/dl/desktop/stable/linux/x64/latest` for the latest version
2. If already in `versions.json`, exits (no-op)
3. If new: downloads the AppImage, computes SHA256, creates a GitHub Release, updates `flake.nix` and `versions.json`, and commits
