# Bottles: tests.yml (`brew test-bot`) builds them for each pull request that
# changes this file, and publish.yml (`brew pr-pull`) uploads them to the
# tap's GitHub Releases and commits the `bottle do` block: don't edit that
# block by hand.
class SsLib < Formula
  desc "Signal-slot library for C, for embedded systems and games"
  homepage "https://github.com/dardevelin/ss_lib"
  url "https://github.com/dardevelin/ss_lib/releases/download/v3.0.1/ss_lib-v3.0.1.tar.gz"
  sha256 "4c755a83f155edc88918335cc4c17c0e09e15fea62b29d46cabf872e535845fa"
  license "MIT"
  head "https://github.com/dardevelin/ss_lib.git", branch: "main"

  bottle do
    root_url "https://github.com/dardevelin/homebrew-ss-lib/releases/download/ss-lib-3.0.1"
    sha256 cellar: :any, arm64_tahoe:   "f704fb131e04287aee621cd3c12940f5a516e7a18cc20ca8ec288e6cfc633db8"
    sha256 cellar: :any, arm64_sequoia: "111504a0873be8fb6f90e37fa141768968f86ce1a15b70ca53108097a1d0740d"
    sha256 cellar: :any, arm64_linux:   "49578ca33f3f00d51ec306664154e9a277053e44a30bcd3b1dbfcecfac38166e"
    sha256 cellar: :any, x86_64_linux:  "2944fdac77cd566225e5db6784568795d0b58f1f3cb176cba960b6b0a43ffe0d"
  end

  def install
    # The installed ss_lib.pc and CMake package (ss_lib::ss_lib) carry these
    # feature definitions, so programs built with either match the library.
    features = %w[
      -DSS_ENABLE_THREAD_SAFETY=1
      -DSS_ENABLE_PERFORMANCE_STATS=1
      -DSS_ENABLE_ISR_SAFE=0
    ]
    system "make", "install", "PREFIX=#{prefix}", "FEATURES=#{features.join(" ")}"

    # Pre-generated in the release; a HEAD build generates it
    system "./create_single_header.sh", "include/ss_lib_single.h" if build.head?
    include.install "include/ss_lib_single.h"

    doc.install "README.md", "CHANGELOG.md", "docs"
  end

  test do
    # find_package(ss_lib 3) works from either install; make writes these
    %w[ss_libConfig ss_libConfigVersion ss_libTargets].each do |f|
      assert_path_exists lib/"cmake/ss_lib/#{f}.cmake"
    end

    (testpath/"test_basic.c").write <<~C
      #include <ss_lib.h>
      #include <stdio.h>

      static void handler(const ss_data_t* data, void* user_data) {
        (void)user_data;
        printf("Value: %d\\n", ss_data_get_int(data, -1));
      }

      int main(void) {
        ss_bus_t* bus = NULL;
        if (ss_bus_create(&bus, 0) != SS_OK) return 1;
        if (ss_signal_register(bus, "test") != SS_OK) return 1;
        if (ss_connect(bus, "test", handler, NULL) != SS_OK) return 1;
        if (ss_emit_int(bus, "test", 42) != SS_OK) return 1;
        printf("Version: %s\\n", ss_version());
        ss_bus_destroy(bus);
        return 0;
      }
    C
    # The flags pkg-config would give, read from the installed ss_lib.pc
    pc = (lib/"pkgconfig/ss_lib.pc").read
    flags = pc[/^Cflags: (.*)$/, 1].gsub("${includedir}", include.to_s).split
    flags += ["-L#{lib}", "-lss_lib"]
    assert_includes flags, "-DSS_ENABLE_THREAD_SAFETY=1"
    system ENV.cc, "test_basic.c", "-o", "test_basic", *flags
    output = shell_output("./test_basic")
    assert_match "Value: 42", output
    assert_match "Version: #{version}", output unless build.head?

    (testpath/"test_single.c").write <<~C
      #define SS_IMPLEMENTATION
      #include "ss_lib_single.h"
      #include <stdio.h>

      static void handler(const ss_data_t* data, void* user_data) {
        (void)user_data;
        printf("Value: %d\\n", ss_data_get_int(data, -1));
      }

      int main(void) {
        ss_bus_t* bus = NULL;
        if (ss_bus_create(&bus, 0) != SS_OK) return 1;
        ss_signal_register(bus, "counter");
        ss_connect(bus, "counter", handler, NULL);
        ss_emit_int(bus, "counter", 7);
        ss_bus_destroy(bus);
        return 0;
      }
    C
    system ENV.cc, "test_single.c", "-I#{include}", "-o", "test_single", "-pthread"
    assert_match "Value: 7", shell_output("./test_single")

    (testpath/"test_thread.c").write <<~C
      #include <ss_lib.h>
      #include <pthread.h>
      #include <stdint.h>
      #include <stdio.h>

      static ss_bus_t* bus = NULL;
      static int calls = 0;

      static void handler(const ss_data_t* data, void* user_data) {
        (void)data;
        (void)user_data;
        calls++;  /* slots run under the bus mutex */
      }

      static void* worker(void* arg) {
        int i;
        for (i = 0; i < 100; i++) ss_emit_int(bus, "tick", (int)(intptr_t)arg);
        return NULL;
      }

      int main(void) {
        pthread_t threads[4];
        int i;
        if (ss_bus_create(&bus, SS_BUS_THREAD_SAFE) != SS_OK) return 1;
        ss_signal_register(bus, "tick");
        ss_connect(bus, "tick", handler, NULL);
        for (i = 0; i < 4; i++) pthread_create(&threads[i], NULL, worker, (void*)(intptr_t)i);
        for (i = 0; i < 4; i++) pthread_join(threads[i], NULL);
        ss_bus_destroy(bus);
        printf("Calls: %d\\n", calls);
        return 0;
      }
    C
    system ENV.cc, "test_thread.c", "-o", "test_thread", *flags, "-pthread"
    assert_match "Calls: 400", shell_output("./test_thread")
  end
end
