const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const sdl = @cImport(
    @cInclude("SDL2/SDL.h"),
);
const time = @cImport(
    @cInclude("sys/time.h"),
);
const png = @cImport(
    @cInclude("png.h"),
);
const c = @cImport(
    @cInclude("setjmp.h"),
);

fn sdl_check_error(code: c_int) void {
    if (code != 0) {
        print("SDL Error: {}\n", .{sdl.SDL_GetError()});
    }
}

const WIDTH: usize = 10;
const HEIGHT: usize = 7;

const TILE_SIZE: u16 = 64;

fn read_img_from_file(file_name: []const u8) !void {
    var buffer = [_]u8{0} ** 200000;

    var slice = try std.fs.cwd().readFile(file_name, buffer[0..]);

    // TODO: read with libpng
    // TODO: return SDL_Surface

    print("{}\n", .{slice.len});
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

    try read_img_from_file("tileset.png");

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
