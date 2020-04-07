# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, patches are not accepted
# for this formula. The NeoMutt project has a Homebrew tap for their
# patched version of Mutt: https://github.com/neomutt/homebrew-neomutt

class Mutt < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.13.5.tar.gz"
  sha256 "6cd71b5b3e6b255afef6bed3b5e1e8ee9819b3d7c9839fd95e798045882aa653"

  bottle do
    sha256 "3bcdd2904f7a76d195020188134d9b4566a3d905f43e70a2041c684e6fa9bce3" => :catalina
    sha256 "64fcaf845a5dc2500e73cc6ae1988679ce139b1573d07b6d899a804d4033382a" => :mojave
    sha256 "0bdcaa2f901111df911aeebb4b69b67f8907a614b3187d12f82aca17c07bd744" => :high_sierra
  end

  head do
    url "https://gitlab.com/muttmua/mutt.git"

    resource "html" do
      url "https://muttmua.gitlab.io/mutt/manual-dev.html"
    end
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gpgme"
  depends_on "openssl@1.1"
  depends_on "tokyo-cabinet"

  uses_from_macos "bzip2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  patch do
    url "https://raw.githubusercontent.com/ttaylorr/homebrew-mutt/master/patch/0001-postpone.c-retain-message_id-when-resending.patch"
    sha256 "ec9910670d48ae62f89b2d51131f3e5a5e1d93fc22fb466ab4452a869f9143f4"
  end

  patch do
    url "https://raw.githubusercontent.com/ttaylorr/homebrew-mutt/master/patch/0002-imap-respect-GMail-labels.patch"
    sha256 "b1ed46572e3f52ab7cc825db9533b38e4e1db5453f39984ddfabc128e4314693"
  end

  def install
    user_in_mail_group = Etc.getgrnam("mail").mem.include?(ENV["USER"])
    effective_group = Etc.getgrgid(Process.egid).name

    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --enable-debug
      --enable-hcache
      --enable-imap
      --enable-pop
      --enable-sidebar
      --enable-smtp
      --with-gss
      --with-sasl
      --with-ssl=#{Formula["openssl@1.1"].opt_prefix}
      --with-tokyocabinet
      --enable-gpgme
    ]

    system "./prepare", *args
    system "make"

    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = #{effective_group}" unless user_in_mail_group

    system "make", "install"
    doc.install resource("html") if build.head?
  end

  def caveats
    <<~EOS
      mutt_dotlock(1) has been installed, but does not have the permissions lock
      spool files in /var/mail. To grant the necessary permissions, run

        sudo chgrp mail #{bin}/mutt_dotlock
        sudo chmod g+s #{bin}/mutt_dotlock

      Alternatively, you may configure `spoolfile` in your .muttrc to a file inside
      your home directory.
    EOS
  end

  test do
    system bin/"mutt", "-D"
    touch "foo"
    system bin/"mutt_dotlock", "foo"
    system bin/"mutt_dotlock", "-u", "foo"
  end
end
