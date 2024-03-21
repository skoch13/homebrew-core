class Netdata < Formula
  desc "Diagnose infrastructure problems with metrics, visualizations & alarms"
  homepage "https://netdata.cloud/"
  url "https://github.com/netdata/netdata/releases/download/v1.45.0/netdata-v1.45.0.tar.gz"
  sha256 "798cf5860600cde2c2fa67c16d27c98f596dbc517992bc39be50277c5049fcb5"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 arm64_sonoma:   "c8101e05d417e88592f1580f111f062ed2c64f7a107271ac9ecd50ac76f1b0eb"
    sha256 arm64_ventura:  "e0eadb2f33af018b9ba4435c6b53eb98e804170b980c1603c9487dae793002b7"
    sha256 arm64_monterey: "fa982cd46ddabb9a20302e6c2a059969d5a9b8361a2beac09583808ba33310d8"
    sha256 sonoma:         "bd24418a3bad424f6178bccbfd045f16bb0616d8b5b73b3dd397edff6a2c7da0"
    sha256 ventura:        "41d6ce9afd539e97dccecb5da9d7ac7cecf37e867db82708953cbddbbe4e2742"
    sha256 monterey:       "471ef2176b93e22b9b8fa12fda8e7de0e971bfd1fdc1e8d2890b74fd4c1688f8"
    sha256 x86_64_linux:   "eaf7d9f20de88f1e860c8f3709cb98d9d0cc37dc45f200d2d5e1df2fb6bdaf48"
  end

  depends_on "cmake" => :build
  depends_on "go" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "brotli"
  depends_on "freeipmi"
  depends_on "json-c"
  depends_on "libuv"
  depends_on "libyaml"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "zstd"

  uses_from_macos "zlib"

  on_linux do
    depends_on "util-linux"
  end

  # On Mac, cmake build only supports finding OpenSSL libs via `brew` commands.
  # https://github.com/netdata/netdata/issues/17242
  patch :DATA

  def install
    # https://github.com/protocolbuffers/protobuf/issues/9947
    ENV.append_to_cflags "-DNDEBUG"

    args = %w[
      -DENABLE_PLUGIN_GO=On
      -DENABLE_BUNDLED_PROTOBUF=On
      -DENABLE_PLUGIN_SYSTEMD_JOURNAL=Off
      -DENABLE_PLUGIN_CUPS=On
      -DENABLE_PLUGIN_DEBUGFS=Off
      -DENABLE_PLUGIN_PERF=Off
      -DENABLE_PLUGIN_SLABINFO=Off
      -DENABLE_PLUGIN_CGROUP_NETWORK=Off
      -DENABLE_PLUGIN_LOCAL_LISTENERS=Off
      -DENABLE_PLUGIN_NETWORK_VIEWER=Off
      -DENABLE_PLUGIN_EBPF=Off
      -DENABLE_PLUGIN_LOGS_MANAGEMENT=Off
      -DENABLE_LOGS_MANAGEMENT_TESTS=Off
      -DENABLE_ACLK=On
      -DENABLE_CLOUD=On
      -DENABLE_BUNDLED_JSONC=Off
      -DENABLE_DBENGINE=On
      -DENABLE_H2O=On
      -DENABLE_ML=On
      -DENABLE_PLUGIN_APPS=On
      -DENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=Off
      -DENABLE_EXPORTER_MONGODB=Off
      -DENABLE_PLUGIN_FREEIPMI=On
      -DENABLE_PLUGIN_NFACCT=Off
      -DENABLE_PLUGIN_XENSTAT=Off
    ]

    if OS.mac?
      inreplace "CMakeLists.txt", "${BREW_OPENSSL_PREFIX}/include", Formula["openssl@3"].opt_include
      inreplace "CMakeLists.txt", "${BREW_OPENSSL_PREFIX}/lib", Formula["openssl@3"].opt_lib
      # args << "UUID_LIBS=-lc"
      # args << "UUID_CFLAGS=-I/usr/include"
    else
      # TODO: fix these since the CMake transition
      args << "UUID_LIBS=-luuid"
      args << "UUID_CFLAGS=-I#{Formula["util-linux"].opt_include}"
    end

    system "cmake", " -S", ".", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (etc/"netdata").install "system/netdata.conf"
  end

  def post_install
    (var/"cache/netdata/unittest-dbengine/dbengine").mkpath
    (var/"lib/netdata/registry").mkpath
    (var/"lib/netdata/lock").mkpath
    (var/"log/netdata").mkpath
    (var/"netdata").mkpath
  end

  service do
    run ["#{Formula["netdata"].opt_prefix}/usr/sbin/netdata", "-D"]
    working_dir var
  end

  test do
    system "#{Formula["netdata"].opt_prefix}/usr/sbin/netdata", "-W", "set", "registry", "netdata unique id file",
                              "#{testpath}/netdata.unittest.unique.id",
                              "-W", "set", "registry", "netdata management api key file",
                              "#{testpath}/netdata.api.key"
  end
end
__END__
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 8bd91c8d8..a2e9b5aa1 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -481,33 +481,6 @@ if(NOT MACOS)
         pkg_check_modules(CRYPTO libcrypto)
         pkg_check_modules(OPENSSL REQUIRED openssl)
 else()
-        # I think this is moot because we can only use openssl 3.x
-        execute_process(COMMAND
-                        brew --prefix --installed openssl
-                        RESULT_VARIABLE BREW_OPENSSL
-                        OUTPUT_VARIABLE BREW_OPENSSL_PREFIX
-                        OUTPUT_STRIP_TRAILING_WHITESPACE)
-
-        if((BREW_OPENSSL NOT EQUAL 0) OR (NOT EXISTS "${BREW_OPENSSL_PREFIX}"))
-                execute_process(COMMAND
-                                brew --prefix --installed openssl@3
-                                RESULT_VARIABLE BREW_OPENSSL
-                                OUTPUT_VARIABLE BREW_OPENSSL_PREFIX
-                                OUTPUT_STRIP_TRAILING_WHITESPACE)
-
-                if((BREW_OPENSSL NOT EQUAL 0) OR (NOT EXISTS "${BREW_OPENSSL_PREFIX}"))
-                        execute_process(COMMAND
-                                        brew --prefix --installed openssl@1.1
-                                        RESULT_VARIABLE BREW_OPENSSL
-                                        OUTPUT_VARIABLE BREW_OPENSSL_PREFIX
-                                        OUTPUT_STRIP_TRAILING_WHITESPACE)
-
-                        if((BREW_OPENSSL NOT EQUAL 0) OR (NOT EXISTS "${BREW_OPENSSL_PREFIX}"))
-                                message(FATAL_ERROR "Could not find openssl prefix with brew")
-                        endif()
-                endif()
-        endif()
-
         set(OPENSSL_INCLUDE_DIRS "${BREW_OPENSSL_PREFIX}/include")
         set(OPENSSL_CFLAGS_OTHER "")
         set(OPENSSL_LDFLAGS "-L${BREW_OPENSSL_PREFIX}/lib;-lssl;-lcrypto")
