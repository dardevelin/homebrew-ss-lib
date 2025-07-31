# Homebrew Formula for SS-Lib

A lightweight, production-ready signal-slot library for C designed for embedded systems, game engines, and resource-constrained environments.

## Features

- 🚀 Zero dependencies - Pure ANSI C
- 💾 Static memory option - No malloc/free at runtime
- 🔒 Thread-safe with optional mutex protection
- ⚡ ISR-safe for interrupt handlers
- 📊 Built-in performance profiling
- 🎯 Single header option for easy integration

## Installation

```bash
brew tap dardevelin/ss-lib
brew install ss-lib
```

Or install the latest development version:

```bash
brew install dardevelin/ss-lib/ss-lib --HEAD
```

## Quick Start

After installation, you can use SS-Lib in your projects:

```c
#include <ss_lib/ss_lib_v2.h>
#include <stdio.h>

void on_button_click(const ss_data_t* data, void* user_data) {
    printf("Button clicked!\n");
}

int main() {
    ss_init();
    ss_signal_register("button_click");
    ss_connect("button_click", on_button_click, NULL);
    ss_emit_void("button_click");
    ss_cleanup();
    return 0;
}
```

Compile with:
```bash
gcc example.c -o example `pkg-config --cflags --libs ss_lib`
```

## What Gets Installed

- **Headers**: `ss_lib_v2.h`, `ss_config.h`, and `ss_lib_single.h`
- **Library**: `libss_lib.a` / `libss_lib.dylib`
- **Pkg-config**: `ss_lib.pc`
- **Documentation**: README, LICENSE, and API docs (if built with doxygen)

## Using the Single Header Version

The formula also installs a single-header version for easy integration:

```c
#define SS_IMPLEMENTATION
#include <ss_lib_single.h>

// Your code here...
```

## Build Options

The formula builds with these defaults:
- Thread safety: Enabled
- Performance stats: Enabled
- Shared library: Built
- Tests: Disabled (for faster installation)

## More Information

- [SS-Lib Repository](https://github.com/dardevelin/ss_lib)
- [Documentation](https://github.com/dardevelin/ss_lib/tree/main/docs)
- [Examples](https://github.com/dardevelin/ss_lib/tree/main/examples)