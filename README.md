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

On macOS 15 and 26 (Apple silicon) and on Linux (x86_64 and arm64) this pours a bottle, a prebuilt binary package, downloaded from this tap's [releases](https://github.com/dardevelin/homebrew-ss-lib/releases). Elsewhere, or with `--build-from-source`, Homebrew builds it with `make` and the C compiler; the formula has no dependencies:

```bash
brew install --build-from-source dardevelin/ss-lib/ss-lib
```

CI builds, tests and audits a bottle on each of those four platforms for every pull request that changes a formula. For every pull request, every change to main and every week, it also installs, tests and audits each formula built from source, and installs and tests SS-Lib's main branch (`--HEAD`).

Or install the latest development version:

```bash
brew install --HEAD dardevelin/ss-lib/ss-lib
```

### SS-Lib 2.x (`ss-lib@2`, deprecated)

`ss-lib@2` installs 2.2.5, the last 2.x release. 2.x is no longer maintained and the formula gets no further updates: migrate to SS-Lib 3.0 with the [migration guide](https://github.com/dardevelin/ss_lib/blob/main/docs/migration-3.0.md) and install `ss-lib`. Until then it is keg-only (it installs the same headers, `libss_lib` names and packages as `ss-lib`), so point pkg-config or CMake at it:

```bash
brew install dardevelin/ss-lib/ss-lib@2
export PKG_CONFIG_PATH="$(brew --prefix dardevelin/ss-lib/ss-lib@2)/lib/pkgconfig"
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix dardevelin/ss-lib/ss-lib@2)" ...   # find_package(ss_lib 2)
```

On Linux, a program linked against its shared library also needs `-Wl,-rpath,$(brew --prefix dardevelin/ss-lib/ss-lib@2)/lib` to find it at run time.

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
    ss_bus_t* bus = NULL;
    /* ss_bus_create() checks that this program and the library were built
     * with the same configuration */
    if (ss_bus_create(&bus, 0) != SS_OK) return 1;
    ss_signal_register(bus, "button_click");
    ss_connect(bus, "button_click", on_button_click, NULL);
    ss_emit_void(bus, "button_click");
    ss_bus_destroy(bus);
    return 0;
}
```

Compile with pkg-config, which also passes the library's configuration flags (your program must be built with the same ones):

```bash
cc example.c -o example $(pkg-config --cflags --libs ss_lib)
```

Or with CMake:

```cmake
find_package(ss_lib 3 REQUIRED)
target_link_libraries(your_app ss_lib::ss_lib)
```

## What Gets Installed

- **Headers**: `ss_lib/ss_lib.h`, `ss_lib/ss_config.h`, and `ss_lib_single.h`
- **Library**: shared, `libss_lib.dylib` (macOS) / `libss_lib.so` (Linux), versioned by major version (`libss_lib.3.dylib`, `libss_lib.so.3`), and static, `libss_lib.a`
- **pkg-config**: `ss_lib.pc`
- **CMake package**: `ss_lib::ss_lib` (`find_package(ss_lib 3)`)
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
- Thread safety: enabled (turn it on per bus with `ss_bus_create(&bus, SS_BUS_THREAD_SAFE)`)
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
