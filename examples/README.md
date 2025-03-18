pugl.zig does not provide Zig bindings for its backends. In these examples we use [zigglgen](https://github.com/castholm/zigglgen) for OpenGL but here are some others to consider:
- [zgl](https://github.com/ziglibs/zgl)
- [zopengl](https://github.com/zig-gamedev/zopengl) (don't use this repo's loader, Pugl already does the context initialization)
- [vulkan-zig](https://github.com/Snektron/vulkan-zig)
