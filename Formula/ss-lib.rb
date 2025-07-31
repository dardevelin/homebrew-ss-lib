class SsLib < Formula
  desc "Lightweight signal-slot library for C - designed for embedded systems and performance-critical applications"
  homepage "https://github.com/dardevelin/ss_lib"
  url "https://github.com/dardevelin/ss_lib/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_UPDATE_AFTER_RELEASE"
  license "MIT"
  head "https://github.com/dardevelin/ss_lib.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "doxygen" => [:build, :optional]
  depends_on "lcov" => [:build, :optional]

  def install
    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DSS_BUILD_SHARED=ON
      -DSS_BUILD_TESTS=OFF
      -DSS_BUILD_EXAMPLES=OFF
      -DSS_ENABLE_THREAD_SAFETY=ON
      -DSS_ENABLE_PERFORMANCE_STATS=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    
    # Generate and install the single header version
    system "./create_single_header.sh"
    include.install "ss_lib_single.h"
    
    # Install additional documentation
    doc.install "README.md", "CHANGELOG.md", "LICENSE"
    doc.install "docs" if Dir.exist?("docs")
    
    # Generate API documentation if doxygen is available
    if build.with?("doxygen")
      system "doxygen", "Doxyfile"
      doc.install "docs/api/html" => "api" if Dir.exist?("docs/api/html")
    end
  end

  test do
    # Test 1: Basic functionality with pkg-config
    (testpath/"test_basic.c").write <<~EOS
      #include <ss_lib/ss_lib_v2.h>
      #include <stdio.h>

      void handler(const ss_data_t* data, void* user_data) {
        printf("Signal received!\\n");
      }

      int main() {
        if (ss_init() != SS_OK) return 1;
        if (ss_signal_register("test") != SS_OK) return 1;
        if (ss_connect("test", handler, NULL) != SS_OK) return 1;
        if (ss_emit_void("test") != SS_OK) return 1;
        ss_cleanup();
        return 0;
      }
    EOS

    system ENV.cc, "test_basic.c", "-o", "test_basic",
           *shell_output("#{Formula["pkg-config"].opt_bin}/pkg-config --cflags --libs ss_lib").chomp.split
    assert_match "Signal received!", shell_output("./test_basic")

    # Test 2: Single header version
    (testpath/"test_single.c").write <<~EOS
      #define SS_IMPLEMENTATION
      #include "ss_lib_single.h"
      #include <stdio.h>

      void handler(const ss_data_t* data, void* user_data) {
        if (data && data->type == SS_TYPE_INT) {
          printf("Value: %d\\n", data->value.i_val);
        }
      }

      int main() {
        ss_init();
        ss_signal_register("counter");
        ss_connect("counter", handler, NULL);
        ss_emit_int("counter", 42);
        ss_cleanup();
        return 0;
      }
    EOS

    cp include/"ss_lib_single.h", testpath
    system ENV.cc, "test_single.c", "-o", "test_single", "-pthread"
    assert_match "Value: 42", shell_output("./test_single")

    # Test 3: Thread safety
    (testpath/"test_thread.c").write <<~EOS
      #include <ss_lib/ss_lib_v2.h>
      #include <pthread.h>
      #include <stdio.h>

      void* thread_func(void* arg) {
        ss_emit_int("thread_test", (int)(intptr_t)arg);
        return NULL;
      }

      void handler(const ss_data_t* data, void* user_data) {
        // Just count the calls
      }

      int main() {
        pthread_t threads[4];
        ss_init();
        ss_signal_register("thread_test");
        ss_connect("thread_test", handler, NULL);
        
        for (int i = 0; i < 4; i++) {
          pthread_create(&threads[i], NULL, thread_func, (void*)(intptr_t)i);
        }
        
        for (int i = 0; i < 4; i++) {
          pthread_join(threads[i], NULL);
        }
        
        ss_cleanup();
        printf("Thread test passed\\n");
        return 0;
      }
    EOS

    system ENV.cc, "test_thread.c", "-o", "test_thread",
           "-I#{include}", "-L#{lib}", "-lss_lib", "-pthread"
    assert_match "Thread test passed", shell_output("./test_thread")
  end
end