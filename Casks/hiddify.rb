cask "hiddify" do
  version "5.9.15"
  sha256 "5d095a63af1130535f3f2dc50342242df2c2ea5bc153151c8ef79923cc6cbd3f"

  url "https://github.com/hiddify/hiddify-app/releases/download/v#{version}/Hiddify-MacOS.dmg"
  name "Hiddify"
  desc "Multi-protocol proxy client based on sing-box"
  homepage "https://hiddify.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  app "Hiddify.app"

  # Upstream builds are ad-hoc signed and not notarized, so Gatekeeper
  # refuses to launch the app while it carries the quarantine attribute.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Hiddify.app"]
  end

  uninstall quit: "apple.hiddify.com"

  zap trash: [
    "~/Library/Application Support/apple.hiddify.com",
    "~/Library/Preferences/apple.hiddify.com.plist",
  ]
end
