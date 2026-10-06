# homebrew-tap

Homebrew formula for [cliproxy-rs](https://github.com/vayungodara/cliproxy-rs).

```sh
brew install vayungodara/tap/cliproxy-rs
brew services start cliproxy-rs
```

The formula installs the release binary for macOS (Apple silicon or Intel) or Linux (arm64 or x86_64). Nothing is compiled. On first install it writes `$(brew --prefix)/etc/cliproxy-rs/config.yaml`, which listens only on `127.0.0.1:8317`, and puts generated client and management keys in `keys.env` next to it. Upgrades keep your config and keys.

The formula is updated when a new cliproxy-rs release is published. Problems go to the [cliproxy-rs issues](https://github.com/vayungodara/cliproxy-rs/issues). The full install guide is in [INSTALL.md](https://github.com/vayungodara/cliproxy-rs/blob/master/docs/INSTALL.md).
