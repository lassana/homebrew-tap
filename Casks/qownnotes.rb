cask "qownnotes" do
  version "26.11.16"
  sha256 "e861cc7a27d5308197162d0b2bb64c4cb82470f060434f07ae0015c57fae552a"

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
