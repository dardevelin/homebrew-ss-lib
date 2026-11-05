# Bottles: tests.yml (`brew test-bot`) builds them for each pull request that
# changes this file, and publish.yml (`brew pr-pull`) uploads them to the
# tap's GitHub Releases and commits the `bottle do` block: don't edit that
# block by hand.
class SsLib < Formula
  desc "Signal-slot library for C, for embedded systems and games"
  homepage "https://github.com/dardevelin/ss_lib"
  url "https://github.com/dardevelin/ss_lib/releases/download/v2.2.4/ss_lib-v2.2.4.tar.gz"
  sha256 "e69d4dc152869312e845d21ccc9df064563e911a067ce58cefbf3cd5d7bbadda"
  license "MIT"
  head "https://github.com/dardevelin/ss_lib.git", branch: "main"

  bottle do
    root_url "https://github.com/dardevelin/homebrew-ss-lib/releases/download/ss-lib-2.2.4"
    sha256 cellar: :any, arm64_tahoe:   "976c75f52b4bef32a2986fa01c3a9d0d5492d5283bc43bbacc33ac6ac6712d91"
    sha256 cellar: :any, arm64_sequoia: "17657ea0e6e0f3d0c40649679a7326544ec74e6b27e60c5ec17bc0d1cc0fffb4"
    sha256 cellar: :any, arm64_linux:   "a785f1ae0fa0b82d9bb495075290fa1b8cfbb623466a3e809d83d40b4f13cce2"
    sha256 cellar: :any, x86_64_linux:  "2e6100ed803d3ee57a467842694f7bc9813dbddf7c0bc452df9c22a6f67f9b1f"
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
    # find_package(ss_lib 2) works from either install; make writes these
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
        if (ss_init_abi(SS_ABI_TAG) != SS_OK) return 1;
        if (ss_signal_register("test") != SS_OK) return 1;
        if (ss_connect("test", handler, NULL) != SS_OK) return 1;
        if (ss_emit_int("test", 42) != SS_OK) return 1;
        printf("Version: %s\\n", ss_version());
        ss_cleanup();
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
        if (ss_init() != SS_OK) return 1;
        ss_signal_register("counter");
        ss_connect("counter", handler, NULL);
        ss_emit_int("counter", 7);
        ss_cleanup();
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

      static int calls = 0;

      static void handler(const ss_data_t* data, void* user_data) {
        (void)data;
        (void)user_data;
        calls++;  /* slots run under the library mutex */
      }

      static void* worker(void* arg) {
        int i;
        for (i = 0; i < 100; i++) ss_emit_int("tick", (int)(intptr_t)arg);
        return NULL;
      }

      int main(void) {
        pthread_t threads[4];
        int i;
        if (ss_init() != SS_OK) return 1;
        ss_set_thread_safe(1);
        ss_signal_register("tick");
        ss_connect("tick", handler, NULL);
        for (i = 0; i < 4; i++) pthread_create(&threads[i], NULL, worker, (void*)(intptr_t)i);
        for (i = 0; i < 4; i++) pthread_join(threads[i], NULL);
        ss_cleanup();
        printf("Calls: %d\\n", calls);
        return 0;
      }
    C
    system ENV.cc, "test_thread.c", "-o", "test_thread", *flags, "-pthread"
    assert_match "Calls: 400", shell_output("./test_thread")
  end
end
