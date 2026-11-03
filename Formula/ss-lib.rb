class SsLib < Formula
  desc "Signal-slot library for C, for embedded systems and games"
  homepage "https://github.com/dardevelin/ss_lib"
  url "https://github.com/dardevelin/ss_lib/releases/download/v2.2.0/ss_lib-v2.2.0.tar.gz"
  sha256 "b1568f1c51f7addf9fc8e888eeb8112268015e51fe15da7f7b0423bb644690a0"
  license "MIT"
  head "https://github.com/dardevelin/ss_lib.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test

  def install
    # The installed ss_lib.pc carries these feature definitions in its Cflags,
    # so programs built with `pkg-config --cflags` match the library.
    args = %w[
      -DSS_BUILD_SHARED=ON
      -DSS_BUILD_TESTS=OFF
      -DSS_BUILD_EXAMPLES=OFF
      -DSS_ENABLE_THREAD_SAFETY=ON
      -DSS_ENABLE_PERFORMANCE_STATS=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Pre-generated in the release; a HEAD build generates it
    system "./create_single_header.sh", "include/ss_lib_single.h" if build.head?
    include.install "include/ss_lib_single.h"

    doc.install "README.md", "CHANGELOG.md", "docs"
  end

  test do
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
    flags = shell_output("pkgconf --cflags --libs ss_lib").chomp.split
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
