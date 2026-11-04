# Homebrew Formula for SS-Lib

A lightweight signal-slot library for C designed for embedded systems, game engines, and resource-constrained environments.

## Features

- 🚀 Zero dependencies - pure C, builds as C89 through C2y
- 💾 Static memory option - fixed arrays, no heap use (when built from source with `SS_USE_STATIC_MEMORY`)
- 🔒 Thread-safe with an optional recursive mutex
- ⚡ ISR-safe emission from interrupt handlers (when built with `SS_ENABLE_ISR_SAFE`)
- 📊 Built-in performance profiling
- 🎯 Single header option for easy integration

## Installation

```bash
brew install dardevelin/ss-lib/ss-lib
```

This taps the repository and installs in one step. Use the full name: Homebrew 7 refuses to load formulae from a third-party tap by short name (`brew install ss-lib`) until you run `brew trust dardevelin/ss-lib`.

The formula has no dependencies: it builds with `make` and the C compiler.

Or install the latest development version:

```bash
brew install --HEAD dardevelin/ss-lib/ss-lib
```

## Quick Start

```c
#include <ss_lib.h>
#include <stdio.h>

void on_button_click(const ss_data_t* data, void* user_data) {
    (void)data;
    (void)user_data;
    printf("Button clicked!\n");
}

int main(void) {
    /* ss_init_abi() checks that this program and the library were built
     * with the same configuration */
    if (ss_init_abi(SS_ABI_TAG) != SS_OK) return 1;
    ss_signal_register("button_click");
    ss_connect("button_click", on_button_click, NULL);
    ss_emit_void("button_click");
    ss_cleanup();
    return 0;
}
```

Compile with pkg-config, which also passes the library's configuration flags (your program must be built with the same ones):

```bash
cc example.c -o example $(pkg-config --cflags --libs ss_lib)
```

Or with CMake:

```cmake
find_package(ss_lib 2 REQUIRED)
target_link_libraries(your_app ss_lib::ss_lib)
```

## What Gets Installed

- **Headers**: `ss_lib/ss_lib.h`, `ss_lib/ss_config.h`, and `ss_lib_single.h`
- **Library**: shared, `libss_lib.dylib` (macOS) / `libss_lib.so` (Linux), versioned by major version (`libss_lib.2.dylib`, `libss_lib.so.2`), and static, `libss_lib.a`
- **pkg-config**: `ss_lib.pc`
- **CMake package**: `ss_lib::ss_lib` (`find_package(ss_lib 2)`)
- **Documentation**: README, CHANGELOG, and `docs/` in `$(brew --prefix)/share/doc/ss-lib`

## Using the Single Header Version

The formula also installs a single-header version, which compiles the library into your program:

```c
/* In exactly one C file: */
#define SS_IMPLEMENTATION
#include <ss_lib_single.h>
```

## Build Options

The formula builds with:
- Thread safety: enabled (turn it on at runtime with `ss_set_thread_safe(1)`)
- Performance stats: enabled
- ISR-safe emission: disabled
- Memory: dynamic (heap)
- Tests and examples: not built
- `pkg-config` and CMake's `ss_lib::ss_lib` both pass these settings to your program

For static memory, ISR support or other options, build from source; see the [Configuration Guide](https://github.com/dardevelin/ss_lib/blob/main/docs/configuration.md).

## More Information

- [SS-Lib Repository](https://github.com/dardevelin/ss_lib)
- [Releases](https://github.com/dardevelin/ss_lib/releases)
- [Documentation](https://github.com/dardevelin/ss_lib/tree/main/docs)
- [Examples](https://github.com/dardevelin/ss_lib/tree/main/examples)
