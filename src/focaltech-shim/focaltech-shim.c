/**
 * focaltech-shim.c - Compatibility shim for FocalTech FT9201/FT9536 fingerprint driver
 *
 * Ubuntu 24.04 / 26.04 migrated libgusb to 0.4.x+, promoting exported symbols to
 * LIBGUSB_0.2.8 and dropping the legacy LIBGUSB_0.1.0 version tag.
 *
 * This shim intercepts and re-exports the required symbols with LIBGUSB_0.1.0 versioning,
 * allowing legacy libfprint-2.so.2.0.0 binary builds to resolve symbols cleanly.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>

static void *gusb_handle = NULL;

static void* get_sym(const char *name) {
    if (!gusb_handle) {
        gusb_handle = dlopen("libgusb.so.2", RTLD_LAZY | RTLD_GLOBAL);
        if (!gusb_handle) {
            fprintf(stderr, "[focaltech-shim] Failed to dlopen libgusb.so.2: %s\n", dlerror());
            return NULL;
        }
    }
    return dlsym(gusb_handle, name);
}

void* g_usb_device_get_interfaces(void *device, void **error) {
    static void* (*real_func)(void*, void**) = NULL;
    if (!real_func) real_func = get_sym("g_usb_device_get_interfaces");
    return real_func ? real_func(device, error) : NULL;
}

uint8_t g_usb_interface_get_number(void *interface) {
    static uint8_t (*real_func)(void*) = NULL;
    if (!real_func) real_func = get_sym("g_usb_interface_get_number");
    return real_func ? real_func(interface) : 0;
}

uint16_t g_usb_device_get_release(void *device) {
    static uint16_t (*real_func)(void*) = NULL;
    if (!real_func) real_func = get_sym("g_usb_device_get_release");
    return real_func ? real_func(device) : 0;
}

uint8_t g_usb_interface_get_class(void *interface) {
    static uint8_t (*real_func)(void*) = NULL;
    if (!real_func) real_func = get_sym("g_usb_interface_get_class");
    return real_func ? real_func(interface) : 0;
}

uint8_t g_usb_interface_get_subclass(void *interface) {
    static uint8_t (*real_func)(void*) = NULL;
    if (!real_func) real_func = get_sym("g_usb_interface_get_subclass");
    return real_func ? real_func(interface) : 0;
}

uint8_t g_usb_interface_get_protocol(void *interface) {
    static uint8_t (*real_func)(void*) = NULL;
    if (!real_func) real_func = get_sym("g_usb_interface_get_protocol");
    return real_func ? real_func(interface) : 0;
}
