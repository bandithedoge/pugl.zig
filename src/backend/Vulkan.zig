//! Vulkan graphics support.
//!
//! Vulkan support differs from OpenGL because almost all most configuration is done using the Vulkan API itself,
//! rather than by setting view hints to configure the context.
//! Pugl only provides a minimal loader for loading the Vulkan library,
//! and a portable function to create a Vulkan surface for a view, which hides the platform-specific implementation details.

const pugl = @import("../pugl.zig");
const pugl_c = @import("c");
const c = @cImport(@cInclude("pugl/vulkan.h"));

const errFromStatus = @import("../utils.zig").errFromStatus;

const Vulkan = @This();

parent_view: *const pugl.View,
backend: *const pugl_c.PuglBackend,
vulkan_loader: *c.PuglVulkanLoader,

/// This dynamically loads the Vulkan library and gets the load functions from it.
///
/// `library_name` is the name of the Vulkan library to load, or null.
/// Typically, this is left unset, which will load the standard Vulkan library for the current platform.
/// It can be set to an alternative name, or an absolute path,
/// to support special packaging scenarios or unusual system configurations.
/// This name is passed directly to the underlying platform library loading function (`dlopen` or `LoadLibrary`).
pub fn new(view: *const pugl.View, library_name: ?[:0]const u8) error{Failure}!Vulkan {
    return .{
        .parent_view = view,
        .backend = @ptrCast(c.puglVulkanBackend().?),
        .vulkan_loader = c.puglNewVulkanLoader(
            view.getWorld().world,
            if (library_name) |name| name.ptr else null,
        ) orelse return error.Failure,
    };
}

/// Free the Vulkan loader created with `.new()`.
///
/// Note that this closes the Vulkan library, so no Vulkan objects or API may be used after this is called.
pub fn free(self: *const Vulkan) void {
    return c.puglFreeVulkanLoader(self.vulkan_loader);
}

/// Return the `vkGetInstanceProcAddr` function.
///
/// Returns null if the Vulkan library does not contain this function (which is unlikely and indicates a broken system).
pub fn getInstanceProcAddrFunc(self: *const Vulkan) c.PFN_vkGetInstanceProcAddr {
    return c.puglGetInstanceProcAddrFunc(self.vulkan_loader).?;
}

// TODO: return an error instead of null
/// Return the `vkGetDeviceProcAddr` function.
///
/// Returns null if the Vulkan library does not contain this function (which is unlikely and indicates a broken system).
pub fn getDeviceProcAddrFunc(self: *const Vulkan) ?c.PFN_vkGetDeviceProcAddr {
    return c.puglGetDeviceProcAddrFunc(self.vulkan_loader) orelse null;
}

/// Return the Vulkan instance extensions required to draw to a `View`.
///
/// This simply returns static strings, it does not access Vulkan or the window system.
/// The returned array always contains at least "VK_KHR_surface".
pub fn getInstanceExtensions() []const [*c]const u8 {
    var count: u32 = undefined;
    return c.puglGetInstanceExtensions(&count)[0..count];
}

/// Create a Vulkan surface for a Pugl view.
///
/// Returns `VK_SUCCESS` on success, or a Vulkan error code.
pub fn createSurface(
    self: *const Vulkan,
    get_instance_proc_addr_func: c.PFN_vkGetInstanceProcAddr,
    instance: c.VkInstance,
    vulkan_allocator: ?*const c.VkAllocationCallbacks,
    surface: *c.VkSurfaceKHR,
) c.VkResult {
    return c.puglCreateSurface(
        get_instance_proc_addr_func,
        self.parent_view.view,
        instance,
        vulkan_allocator,
        surface,
    );
}
