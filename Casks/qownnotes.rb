cask "qownnotes" do
  version "26.11.15"
  sha256 "61b9c79f435e3d62b2b845d2caa4d383537b53d142e4456392255a9e91e5f134"

  url "https://github.com/pbek/QOwnNotes/releases/download/v#{version}/QOwnNotes.dmg"
  name "QOwnNotes"
  desc "Plain-text file notepad and todo-list manager"
  homepage "https://www.qownnotes.org/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "QOwnNotes.app"

  # Upstream builds are not notarized (pbek/QOwnNotes#3528), so Gatekeeper
  # refuses to launch the app while it carries the quarantine attribute.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/QOwnNotes.app"]
  end

  uninstall quit: "com.PBE.QOwnNotes"

  zap trash: [
    "~/Library/Preferences/com.pbe.QOwnNotes.plist",
    "~/Library/Saved Application State/com.PBE.QOwnNotes.savedState",
  ]
end
