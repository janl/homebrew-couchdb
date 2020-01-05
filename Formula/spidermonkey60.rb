# Based on @yan12125’s: 
# https://github.com/hanxue/homebrew-versions/blob/6d05cb06d6292be579319b53a9cefa92855b6ab9/spidermonkey45.rb
class Spidermonkey60 < Formula
  desc "JavaScript-C Engine, version 60"
  homepage "https://developer.mozilla.org/en/SpiderMonkey"

  stable do
    url "http://ftp.mozilla.org/pub/spidermonkey/prereleases/60/pre3/mozjs-60.1.1pre3.tar.bz2"
    sha256 "60c5a15c59908120af71b87a24f303b0c196c6620a6f52ef3149f4e1a377a373"
    # mozbuild installs symlinks in `make install`
    # https://bugzilla.mozilla.org/show_bug.cgi?id=1296289
    patch :DATA
  end

  bottle do
  end

  depends_on "readline"
  depends_on "nspr"
  depends_on "icu4c"
  depends_on "pkg-config" => :build
  depends_on "autoconf@2.13"

  conflicts_with "narwhal", :because => "both install a js binary"

  def install
    mkdir "brew-build" do
      system "../js/src/configure", "--prefix=#{prefix}",
                                    "--enable-readline",
                                    "--with-system-nspr",
                                    "--with-system-icu",
                                    "--with-nspr-prefix=#{Formula["nspr"].opt_prefix}",
                                    "--enable-macos-target=#{MacOS.version}"

      # These need to be in separate steps.
      system "make"
      system "make", "install"

      # libmozglue.dylib is required for both the js shell and embedders
      # https://bugzilla.mozilla.org/show_bug.cgi?id=903764
      lib.install "mozglue/build/libmozglue.dylib"

      mv lib/"libjs_static.ajs", lib/"libjs_static.a"
    end
  end

  test do
    path = testpath/"test.js"
    path.write "print('hello');"
    assert_equal "hello", shell_output("#{bin}/js #{path}").strip
  end
end
__END__
--- mozjs-60.1.1pre3/python/mozbuild/mozbuild/backend/recursivemake.py.orig	2020-01-05 14:57:39.000000000 +0100
+++ mozjs-60.1.1pre3/python/mozbuild/mozbuild/backend/recursivemake.py	2020-01-05 14:57:49.000000000 +0100
@@ -1431,7 +1431,7 @@
                         else:
                             install_manifest.add_pattern_link(f.srcdir, f, path)
                     else:
-                        install_manifest.add_link(f.full_path, dest)
+                        install_manifest.add_copy(f.full_path, dest)
                 else:
                     install_manifest.add_optional_exists(dest)
                     backend_file.write('%s_FILES += %s\n' % (
