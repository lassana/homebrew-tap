# lassana/homebrew-tap

## QOwnNotes

The official `qownnotes` cask is disabled because upstream builds are not
notarized ([pbek/QOwnNotes#3528](https://github.com/pbek/QOwnNotes/issues/3528)).
This cask installs the same upstream DMG and removes the quarantine attribute
after install, so Gatekeeper does not block it.

```sh
brew install --cask lassana/tap/qownnotes
```

A nightly workflow bumps the cask to the latest upstream release.
