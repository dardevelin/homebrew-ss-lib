class SsLib < Formula
  desc "Lightweight signal-slot library for C with focus on embedded systems"
  homepage "https://github.com/dardevelin/ss_lib"
  url "https://github.com/dardevelin/ss_lib/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_UPDATE_AFTER_RELEASE"
  license "MIT"
  head "https://github.com/dardevelin/ss_lib.git", branch: "main"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DSS_BUILD_SHARED=OFF",
                    "-DSS_BUILD_TESTS=OFF",
                    "-DSS_BUILD_EXAMPLES=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    
    # Also install the single header version
    system "chmod", "+x", "create_single_header.sh"
    system "./create_single_header.sh"
    include.install "ss_lib_single.h"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <ss_lib/ss_lib_v2.h>
      #include <stdio.h>

      void handler(const ss_data_t* data, void* user_data) {
        printf("Signal received!\\n");
      }

      int main() {
        ss_init();
        ss_signal_register("test");
        ss_connect("test", handler, NULL);
        ss_emit_void("test");
        ss_cleanup();
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-L#{lib}", "-lss_lib", "-o", "test"
    assert_match "Signal received!", shell_output("./test")
  end
end