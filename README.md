# Module System

## Installation

### 1. **Adding the Library URL**

The `zig fetch` command adds the URL and hash of the library to the `build.zig.zon` file:

```sh
zig fetch --save https://github.com/engusmaze/module-sys/archive/2693e53a64857fbadbd36fc10e8e7ead4942be21.tar.gz
```

Add an entry to the `build.zig.zon` file with the specified URL and the hash of the library at that URL. The hash is used for verification purposes to ensure the library hasn't changed since it was added.

### 2. **Adding the Dependency**

After adding the library URL to the `build.zig.zon` file, you need to add it as a dependency to your Zig project. This is done in the `build.zig` file:

```zig
const module_sys = b.dependency("module-sys", .{
    .target = target,
    .optimize = optimize,
});
```

This code creates a new dependency named `module-sys` and associates it with the library URL and hash specified in the `build.zig.zon` file. The `target` and `optimize` options are passed to specify the target architecture and optimization level for the dependency.

### 3. **Importing the Library**

Finally, you need to import the `module-sys` library into your Zig code so that you can use its functionality. This is done by adding an import statement to your root module:

```zig
exe.root_module.addImport("module-sys", module_sys.module("module-sys"));
```

This code adds an import statement to your root module, allowing you to access the `module-sys` library using the `@import("module-sys")` syntax in your Zig code.

During the build process, Zig will download the library code from the URL specified in the `build.zig.zon` file and verify its hash. If the hash matches, the library code will be used for the build; otherwise, an error will be raised.
