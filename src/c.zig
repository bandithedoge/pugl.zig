const options = @import("pugl_options");

pub usingnamespace @cImport({
    @cInclude("pugl/pugl.h");
    if (options.backend_opengl) {
        @cDefine("PUGL_NO_INCLUDE_GL_H", "1");
        @cInclude("pugl/gl.h");
    }
    if (options.backend_vulkan)
        @cInclude("pugl/vulkan.h");
    if (options.backend_cairo)
        @cInclude("pugl/cairo.h");
    if (options.backend_stub)
        @cInclude("pugl/stub.h");
});
