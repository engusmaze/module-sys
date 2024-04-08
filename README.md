# Module System

## Installation Steps:

### 1. Adding the Library URL:

Use `zig fetch` command to save the library's URL and its hash to a file called `build.zig.zon`.

```sh
zig fetch --save https://github.com/engusmaze/module-sys/archive/27752846a0f28c776d4568b99e22fef6c4f2fe89.tar.gz
```

### 2. Adding the Dependency:

After saving the library's URL, you need to make it importable by your code in the build.zig file. This involves specifying the dependency and adding it to an executable or library.

```zig
pub fn build(b: *std.Build) void {
    // ...
    const module_sys = b.dependency("module-sys", .{
        .target = target,
        .optimize = optimize,
    });

    // Add the module to an executable or library
    exe.root_module.addImport("module-sys", module_sys.module("module-sys"));
}
```

### 3. Importing the Library:

Once the dependency is specified in the `build.zig` file, you can import the library into your Zig code using the `@import` directive.

```zig
const module_sys = @import("module-sys");
```
