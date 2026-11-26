cask "coolterm" do
  version "2.4.0.3.0.1425"
  sha256 "190a1f67d0362ce7ae4b531552925ef28e40004052c3be1fe9bf653e0678cddd"

  url "https://freeware.the-meiers.org/CoolTermMac.dmg"
  name "CoolTerm"
  desc "Serial port terminal"
  homepage "https://freeware.the-meiers.org/"

  livecheck do
    url "https://freeware.the-meiers.org/version/CoolTerm.ver"
    regex(/^\s*v?(\d+(?:\.\d+)+)\s*$/i)
  end

  depends_on :macos

  app "CoolTerm.app"

  # Upstream builds are not notarized, so Gatekeeper refuses to launch the app
  # while it carries the quarantine attribute.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/CoolTerm.app"]
  end

  uninstall quit: "org.the-meiers.coolterm"

  zap trash: [
    "~/Library/Preferences/CoolTerm_Prefs.plist",
    "~/Library/Saved Application State/org.the-meiers.coolterm.savedState",
  ]
end
