const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const Allocator = std.heap.c_allocator;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const time = @cImport({
    @cInclude("sys/time.h");
});
const c = @cImport({
    @cInclude("png.h");
    @cInclude("setjmp.h");
});

fn sdl_check_error(code: c_int) void {
    if (code != 0) {
        print("SDL Error: {}\n", .{sdl.SDL_GetError()});
    }
}

const WIDTH: usize = 10;
const HEIGHT: usize = 7;

const TILE_SIZE: u16 = 64;

fn texture_from_file(renderer: ?*sdl.SDL_Renderer, file_name: [*:0]const u8) !*sdl.SDL_Texture {
    const fp = c.fopen(file_name, "rb") orelse std.os.abort();

    var header = [_]u8{0} ** 8;

    var header_slice: []u8 = header[0..];

    _ = c.fread(header_slice.ptr, 1, 8, fp);

    if (c.png_sig_cmp(header_slice.ptr, 0, 8) != 0) {
        std.os.abort();
    }

    const png_ptr: c.png_structp = c.png_create_read_struct(c.PNG_LIBPNG_VER_STRING, null, null, null) orelse std.os.abort();

    const info_ptr: c.png_infop = c.png_create_info_struct(png_ptr) orelse std.os.abort();

    const jmp_buf: []c.__jmp_buf_tag = c.png_jmpbuf(png_ptr)[0..];
    if (c.setjmp(jmp_buf.ptr) != 0) {
        std.os.abort();
    }

    c.png_init_io(png_ptr, fp);

    c.png_set_sig_bytes(png_ptr, 8);

    c.png_read_info(png_ptr, info_ptr);

    const width = c.png_get_image_width(png_ptr, info_ptr);
    const height = c.png_get_image_height(png_ptr, info_ptr);
    const color_type = c.png_get_color_type(png_ptr, info_ptr);
    const bit_depth = c.png_get_bit_depth(png_ptr, info_ptr);

    const number_of_passes = c.png_set_interlace_handling(png_ptr);
    c.png_read_update_info(png_ptr, info_ptr);

    var row_pointers = try Allocator.alloc(c.png_bytep, height);

    for (row_pointers) |*row| {
        row.* = (try Allocator.alloc(c.png_byte, c.png_get_rowbytes(png_ptr, info_ptr))).ptr;
    }

    c.png_read_image(png_ptr, row_pointers.ptr);

    var pixels = [_]c.png_byte{0} ** (512 * 512 * 4);

    for (pixels) |*byte, i| {
        byte.* = row_pointers[i / (512 * 4)][i % 512];
    }

    var pixels_slice: []u8 = pixels[0..];

    const surface = sdl.SDL_CreateRGBSurfaceFrom(
        pixels_slice.ptr,
        @intCast(c_int, width),
        @intCast(c_int, height),
        4 * bit_depth,
        @intCast(c_int, 4 * width),
        0x000000FF,
        0x0000FF00,
        0x00FF0000,
        0xFF000000,
    ) orelse std.os.abort();

    const texture = sdl.SDL_CreateTextureFromSurface(renderer, surface) orelse std.os.abort();

    return texture;
}

fn render_grid(renderer: ?*sdl.SDL_Renderer, tiles: [HEIGHT][WIDTH]u64) void {
    for (tiles) |col, j| {
        for (col) |_, i| {
            const rect = sdl.SDL_Rect{
                .x = @intCast(c_int, TILE_SIZE * i),
                .y = @intCast(c_int, TILE_SIZE * j),
                .w = TILE_SIZE,
                .h = TILE_SIZE,
            };

            sdl_check_error(sdl.SDL_SetRenderDrawColor(renderer, @intCast(u8, 255 * i / WIDTH), @intCast(u8, 255 * j / HEIGHT), 0, 255));
            sdl_check_error(sdl.SDL_RenderFillRect(renderer, &rect));
        }
    }
}

fn render_texture(renderer: ?*sdl.SDL_Renderer, texture: *sdl.SDL_Texture) void {
    const src = sdl.SDL_Rect{
        .x = 0,
        .y = 0,
        .w = 32 * 3,
        .h = 32 * 3,
    };

    const dest = sdl.SDL_Rect{
        .x = 0,
        .y = 0,
        .w = TILE_SIZE * 3,
        .h = TILE_SIZE * 3,
    };

    sdl_check_error(sdl.SDL_RenderCopy(renderer, texture, &src, &dest));
}

fn render_player(renderer: ?*sdl.SDL_Renderer, x: isize, y: isize, colour: bool) void {
    const rect = sdl.SDL_Rect{
        .x = @intCast(c_int, x),
        .y = @intCast(c_int, y),
        .w = TILE_SIZE,
        .h = TILE_SIZE,
    };

    if (colour) {
        sdl_check_error(sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255));
    } else {
        sdl_check_error(sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255));
    }

    sdl_check_error(sdl.SDL_RenderFillRect(renderer, &rect));
}

pub fn main() !void {
    sdl_check_error(sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS));

    const window: ?*sdl.SDL_Window = sdl.SDL_CreateWindow("zig_sdl2", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, 640, 448, sdl.SDL_WINDOW_SHOWN);

    const renderer: ?*sdl.SDL_Renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC);

    const tiles = [HEIGHT][WIDTH]u64{
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };

    const texture = try texture_from_file(renderer, "tileset.png");

    var quit = false;
    var start: time.timeval = undefined;
    var end: time.timeval = undefined;

    var x: isize = 0;
    var y: isize = 0;
    var colour: bool = false;

    var acc: u64 = 0;

    while (!quit) {
        _ = time.gettimeofday(&start, null);

        var event: sdl.SDL_Event = undefined;

        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_QUIT) {
                quit = true;
            }
        }

        const keyboard_state: [*c]const u8 = sdl.SDL_GetKeyboardState(null);

        if (keyboard_state[sdl.SDL_SCANCODE_W] != 0) {
            y -= 2;
        }
        if (keyboard_state[sdl.SDL_SCANCODE_S] != 0) {
            y += 2;
        }
        if (keyboard_state[sdl.SDL_SCANCODE_A] != 0) {
            x -= 2;
        }
        if (keyboard_state[sdl.SDL_SCANCODE_D] != 0) {
            x += 2;
        }

        sdl_check_error(sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255));
        sdl_check_error(sdl.SDL_RenderClear(renderer));
        render_grid(renderer, tiles);
        render_texture(renderer, texture);
        render_player(renderer, x, y, colour);
        sdl.SDL_RenderPresent(renderer);

        _ = time.gettimeofday(&end, null);

        var delta = (end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec - start.tv_usec;

        acc += @intCast(u64, delta);
        if (acc > 2_000_000) {
            colour = !colour;
            acc -= 2_000_000;
        }
    }

    sdl.SDL_Quit();
}
