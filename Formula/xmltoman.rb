class Xmltoman < Formula
  desc "XML to manpage converter"
  homepage "https://sourceforge.net/projects/xmltoman/"
  url "https://downloads.sourceforge.net/project/xmltoman/xmltoman/xmltoman-0.4.tar.gz/xmltoman-0.4.tar.gz"
  sha256 "948794a316aaecd13add60e17e476beae86644d066cb60171fc6b779f2df14b0"
  license "GPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "2c1c3da70de5b5ca5d57b476a540ae3219c112f76c75e5716d7565a95797b3a1"
    sha256 cellar: :any_skip_relocation, big_sur:       "0d570defe5cd89116a1c4ed81782f9a57fc38fae3bd767d9bd41f68fb3d53e2d"
    sha256 cellar: :any_skip_relocation, catalina:      "547b65d2c4e637b2331382f907a1a9602864d7e1e579404ae96e765dc8a4f378"
    sha256 cellar: :any_skip_relocation, mojave:        "3e302a54f0f28d8e560d7015acef0f395f75a209a94401b8f8d01aa73d2b578a"
    sha256 cellar: :any_skip_relocation, high_sierra:   "029c288b1f70c0dc7711304b9b1af40a95f8f343a3af29f25dabb5dbc1cbad67"
    sha256 cellar: :any_skip_relocation, sierra:        "06a29d1545388d2111008cc244733f36971638e05408e1a7353fe9e142f91b76"
    sha256 cellar: :any_skip_relocation, el_capitan:    "010af030c01ebe6528bbdecfa1153fac5f6e082fa088e1803d0768bb268a509b"
    sha256 cellar: :any_skip_relocation, yosemite:      "6345ec17095eeec7fde97b609c0c88f07fcdd1e911fa7fd3b8db7f3e5b081b9c"
  end

  def install
    # generate the man files from their original XML sources
    system "./xmltoman xml/xmltoman.1.xml > xmltoman.1"
    system "./xmltoman xml/xmlmantohtml.1.xml > xmlmantohtml.1"

    man1.install %w[xmltoman.1 xmlmantohtml.1]
    bin.install %w[xmltoman xmlmantohtml]
    pkgshare.install %w[xmltoman.xsl xmltoman.dtd xmltoman.css]
  end
end
