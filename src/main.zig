const std = @import("std");
const print = std.debug.print;
const sdl = @cImport(
    @cInclude("SDL2/SDL.h"),
);

fn sdl_check_error(code: c_int) void {
    if (code != 0) {
        print("SDL Error: {}\n", .{sdl.SDL_GetError()});
    }
}

const WIDTH: usize = 10;
const HEIGHT: usize = 7;

const TILE_SIZE: u16 = 64;

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

pub fn main() !void {
    sdl_check_error(sdl.SDL_Init(sdl.SDL_INIT_VIDEO));

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

    sdl_check_error(sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255));
    sdl_check_error(sdl.SDL_RenderClear(renderer));
    render_grid(renderer, tiles);
    sdl.SDL_RenderPresent(renderer);
    sdl.SDL_Delay(3000);
}
