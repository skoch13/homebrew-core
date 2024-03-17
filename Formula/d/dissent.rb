class Dissent < Formula
  desc "GTK4 Discord client in Go"
  homepage "https://github.com/diamondburned/dissent"
  url "https://github.com/diamondburned/dissent/archive/refs/tags/v0.0.21.tar.gz"
  sha256 "3c3caefc722fa21e0129a0b6779cdbb61fe41e559b8d44bd4288f283922b15f2"
  license "GPL-3.0-or-later"
  head "https://github.com/diamondburned/dissent.git", branch: "main"

  depends_on "go" => :build
  depends_on "glib"
  depends_on "gobject-introspection"
  depends_on "graphene"
  depends_on "gtk4"
  depends_on "libadwaita"
  depends_on "libcanberra"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    require "pty"

    PTY.spawn(bin/"dissent") do |_r, w, _pid|
      sleep 1
      w.write "\cC"
      begin
        assert_predicate testpath/"Library/Application Support/dissent", :exist?
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end
  end
end
