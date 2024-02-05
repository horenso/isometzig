const std = @import("std");
const Game = @import("./game.zig").Game;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const TileMap = @import("./tile_map.zig").TileMap;

pub fn render_map(game: *Game, scroll_x: f64, scroll_y: f64, map: [5][5]u8) void {
    for (map, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            game.tile_map.render(game.renderer, cell, @intCast(i), @intCast(j), scroll_x, scroll_y);
        }
    }
}

pub fn main() !void {
    var game = try Game.init();
    defer game.deinit();

    const keyboard = c.SDL_GetKeyboardState(null);
    _ = keyboard;

    var quit = false;

    var scroll_x: f64 = 300;
    var scroll_y: f64 = 300;

    const map = [5][5]u8{
        [5]u8{ 4, 2, 0, 0, 0 },
        [5]u8{ 0, 0, 2, 0, 0 },
        [5]u8{ 0, 1, 1, 1, 1 },
        [5]u8{ 0, 0, 1, 1, 0 },
        [5]u8{ 0, 0, 0, 0, 1 },
    };

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => {
                        quit = true;
                    },
                    c.SDLK_LEFT => {
                        scroll_x -= 2;
                    },
                    c.SDLK_RIGHT => {
                        scroll_x += 2;
                    },
                    c.SDLK_UP => {
                        scroll_y -= 2;
                    },
                    c.SDLK_DOWN => {
                        scroll_y += 2;
                    },
                    else => {},
                },
                else => {},
            }
        }

        var mouse_x: c_int = undefined;
        var mouse_y: c_int = undefined;
        _ = c.SDL_GetMouseState(&mouse_x, &mouse_y);

        _ = c.SDL_SetRenderDrawColor(game.renderer, 0x20, 0x18, 0x18, 255);
        _ = c.SDL_RenderClear(game.renderer);

        render_map(&game, scroll_x, scroll_y, map);

        const mouse_x_float: f64 = @floatFromInt(mouse_x);
        const mouse_y_float: f64 = @floatFromInt(mouse_y);

        const grid_pos = TileMap.screen_to_grid_corrds(mouse_x_float - scroll_x, mouse_y_float - scroll_y);
        const x: c_int = @intFromFloat(std.math.round(grid_pos[0]));
        const y: c_int = @intFromFloat(std.math.round(grid_pos[1]));
        game.tile_map.render(
            game.renderer,
            3,
            x,
            y,
            scroll_x,
            scroll_y,
        );
        std.debug.print("{} {} => {}, {} => {} {} {} {} \n", .{
            mouse_x,
            mouse_y,
            grid_pos[0],
            grid_pos[1],
            x,
            y,
            mouse_x_float - scroll_x,
            mouse_y_float - scroll_y,
        });

        const rounded_scroll_x: c_int = @intFromFloat(std.math.round(scroll_x));
        const rounded_scroll_y: c_int = @intFromFloat(std.math.round(scroll_y));

        _ = c.SDL_SetRenderDrawColor(game.renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderDrawRect(game.renderer, &c.SDL_Rect{ .w = 200, .h = 200, .x = rounded_scroll_x, .y = rounded_scroll_y });

        c.SDL_RenderPresent(game.renderer);

        c.SDL_Delay(1000 / 60);
    }
}
