cask "strawberry-music-player" do
  version "1.2.30"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/lassana/homebrew-tap/releases/download/strawberry-#{version}/strawberry-#{version}-arm64.dmg"
  name "Strawberry Music Player"
  desc "Music player and music collection organiser"
  homepage "https://www.strawberrymusicplayer.org/"

  livecheck do
    url "https://github.com/strawberrymusicplayer/strawberry"
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :monterey

  app "strawberry.app"

  # Upstream publishes no macOS binaries, so this tap builds each release from
  # source. The build is ad-hoc signed and not notarized, so Gatekeeper refuses
  # to launch the app while it carries the quarantine attribute.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/strawberry.app"]
  end

  uninstall quit: "org.strawberrymusicplayer.strawberry"

  zap trash: [
    "~/Library/Application Support/Strawberry",
    "~/Library/Caches/org.strawberrymusicplayer.strawberry",
    "~/Library/Caches/Strawberry",
    "~/Library/Preferences/org.strawberrymusicplayer.Strawberry.plist",
  ]
end
