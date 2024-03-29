# coding: utf-8
# Based on @yan12125’s: 
# https://github.com/hanxue/homebrew-versions/blob/6d05cb06d6292be579319b53a9cefa92855b6ab9/spidermonkey45.rb
class Spidermonkey68 < Formula
  desc "JavaScript-C++ Engine, version 68"
  homepage "https://developer.mozilla.org/en/SpiderMonkey"

  stable do
    url "https://archive.mozilla.org/pub/firefox/releases/68.9.0esr/source/firefox-68.9.0esr.source.tar.xz"
    sha256 "935105e1a8a97d64daffb372690e2b566b5f07641f01470929dbbc82d20d4407"
    version "68.9.0"
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
      ENV["CLFAGS"] = "-std=c++14"
      ENV["CXXFLAGS"] = "-mmacosx-version-min=10.9"
      ENV["LDFAGS"] = "-std=c++14"
      system "../js/src/configure", "--prefix=#{prefix}",
                                    "--enable-readline",
                                    "--with-system-icu",
                                    "--with-nspr-prefix=#{Formula["nspr"].opt_prefix}",
                                    "--enable-macos-target=10.9",
                                    "--disable-ctypes",
                                    "--disable-ion",
                                    "--disable-jemalloc",
                                    "--enable-optimize",
                                    "--enable-posix-nspr-emulation",
                                    "--enable-hardening",
                                    "--with-system-zlib",
                                    "--with-intl-api"

      # awkward hack
      ENV["CC"] = "clang++"
      # These need to be in separate steps.
      system "make"
      system "make", "install"

      # libmozglue.dylib is required for both the js shell and embedders
      # https://bugzilla.mozilla.org/show_bug.cgi?id=903764
      # lib.install "mozglue/build/libmozglue.dylib"

      mv lib/"libjs_static.ajs", lib/"libjs_static.a"
    end
  end

  test do
    path = testpath/"test.js"
    path.write "print('hello');"
    assert_equal "hello", shell_output("#{bin}/js #{path}").strip
  end
end

#__END__
#--- mozjs-60.1.1pre3/python/mozbuild/mozbuild/backend/recursivemake.py.orig	2020-01-05 14:57:39.000000000 +0100
#+++ mozjs-60.1.1pre3/python/mozbuild/mozbuild/backend/recursivemake.py	2020-01-05 14:57:49.000000000 +0100
#@@ -1431,7 +1431,7 @@
#                         else:
#                             install_manifest.add_pattern_link(f.srcdir, f, path)
#                     else:
#-                        install_manifest.add_link(f.full_path, dest)
#+                        install_manifest.add_copy(f.full_path, dest)
#                 else:
#                     install_manifest.add_optional_exists(dest)
#                     backend_file.write('%s_FILES += %s\n' % (
