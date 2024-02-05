const std = @import("std");
const Game = @import("./game.zig").Game;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const TileMap = @import("./tile_map.zig").TileMap;
const FPoint = @import("./point.zig").FPoint;

pub fn render_map(
    game: *Game,
    scroll: FPoint,
    map: [5][5]u8,
    zoom_factor: f64,
) void {
    for (map, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            game.tile_map.render(game.renderer, cell, @intCast(i), @intCast(j), scroll, zoom_factor);
        }
    }
}

const PAN_SPEED: f64 = 10.0;
const ZOOM: f64 = 2.0;

pub fn main() !void {
    var game = try Game.init();
    defer game.deinit();

    const keyboard = c.SDL_GetKeyboardState(null);
    _ = keyboard;

    var quit = false;

    var scroll = FPoint{ .x = 300, .y = 300 };
    var mouse_pressed = false;

    var map = [5][5]u8{
        [5]u8{ 0, 2, 0, 0, 0 },
        [5]u8{ 0, 0, 2, 0, 0 },
        [5]u8{ 0, 1, 1, 1, 1 },
        [5]u8{ 0, 0, 1, 1, 0 },
        [5]u8{ 0, 0, 0, 0, 1 },
    };

    while (!quit) {
        var event: c.SDL_Event = undefined;
        mouse_pressed = false;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => quit = true,
                    c.SDLK_LEFT => scroll.x -= PAN_SPEED,
                    c.SDLK_RIGHT => scroll.x += PAN_SPEED,
                    c.SDLK_UP => scroll.y -= PAN_SPEED,
                    c.SDLK_DOWN => scroll.y += PAN_SPEED,
                    else => {},
                },
                c.SDL_MOUSEBUTTONDOWN => mouse_pressed = true,
                else => {},
            }
        }

        var mouse_x: c_int = undefined;
        var mouse_y: c_int = undefined;
        _ = c.SDL_GetMouseState(&mouse_x, &mouse_y);

        _ = c.SDL_SetRenderDrawColor(game.renderer, 0x20, 0x18, 0x18, 255);
        _ = c.SDL_RenderClear(game.renderer);

        // Render code:

        render_map(&game, scroll, map, ZOOM);

        const mouse_x_float: f64 = @floatFromInt(mouse_x);
        const mouse_y_float: f64 = @floatFromInt(mouse_y);

        const grid_pos = TileMap.grid_coords_from_screen(FPoint{ .x = mouse_x_float - scroll.x, .y = mouse_y_float - scroll.y }, ZOOM);
        const x: c_int = @intFromFloat(std.math.round(grid_pos.x));
        const y: c_int = @intFromFloat(std.math.round(grid_pos.y));
        game.tile_map.render(game.renderer, 3, x, y, scroll, ZOOM);
        if (mouse_pressed and x >= 0 and x < map.len and y >= 0 and y < map.len) {
            map[@intCast(x)][@intCast(y)] = (map[@intCast(x)][@intCast(y)] + 1) % 5;
        }

        _ = c.SDL_SetRenderDrawColor(game.renderer, 255, 0, 255, 255);
        _ = c.SDL_RenderDrawRect(game.renderer, &c.SDL_Rect{
            .w = 1000,
            .h = 1000,
            .x = @intFromFloat(scroll.x),
            .y = @intFromFloat(scroll.y),
        });

        c.SDL_RenderPresent(game.renderer);

        c.SDL_Delay(1000 / 60);
    }
}
