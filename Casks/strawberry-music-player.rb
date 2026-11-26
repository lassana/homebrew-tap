cask "strawberry-music-player" do
  version "1.2.31"
  sha256 "cffc0cd453f3126a930b9e67f547e54d9fde0c8754fdead8185d2b2f5c68c037"

  url "https://github.com/strawberrymusicplayer/strawberry/releases/download/#{version}/strawberry-#{version}.tar.xz"
  name "Strawberry Music Player"
  desc "Music player and music collection organiser"
  homepage "https://www.strawberrymusicplayer.org/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "strawberry.app"

  # Upstream publishes no macOS binaries, so the app is built from the source
  # tarball at install time. Upstream's dependency bundle only works from
  # /opt/strawberry_macos_arm64_release, hence the sudo steps around the build.
  preflight_steps do
    run "/usr/bin/curl",
        args:           [
          "--fail", "--silent", "--show-error", "--location", "--retry", "3",
          "--output", "{{staged_path}}/dependencies.tar.xz",
          "https://github.com/strawberrymusicplayer/strawberry-macos-dependencies/releases/latest/download/strawberry-macos-arm64-release.tar.xz"
        ],
        network_access: true
    run "/usr/bin/tar", args: ["-C", "/", "-xf", "{{staged_path}}/dependencies.tar.xz"], sudo: true
    run "/bin/bash",
        args:           [
          "{{HOMEBREW_PREFIX}}/Library/Taps/lassana/homebrew-tap/scripts/strawberry-build.sh",
          "{{staged_path}}", "{{version}}"
        ],
        network_access: true,
        print_stdout:   true
  end

  # The build is ad-hoc signed and not notarized, so Gatekeeper refuses to
  # launch the app while it carries the quarantine attribute of the download.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/strawberry.app"]
    remove "/opt/strawberry_macos_arm64_release", recursive: true, sudo: true
  end

  uninstall quit: "org.strawberrymusicplayer.strawberry"

  zap trash: [
    "~/Library/Application Support/Strawberry",
    "~/Library/Caches/org.strawberrymusicplayer.strawberry",
    "~/Library/Caches/Strawberry",
    "~/Library/Preferences/org.strawberrymusicplayer.Strawberry.plist",
  ]
end
