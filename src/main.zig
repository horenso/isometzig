const std = @import("std");
const Game = @import("./game.zig").Game;
const c = @import("./sdl.zig").SDL;
const TileMap = @import("./tile_map.zig").TileMap;
const point = @import("./point.zig");
const FPoint = point.FPoint;
const CIPoint = point.CIPoint;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;

const MIN_ZOOM = 1.0;
const MAX_ZOOM = std.math.pow(f64, 2.0, 3);

pub fn render_map(
    game: *Game,
    pan: FPoint,
    map: [5][5]u8,
) void {
    for (map, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            game.tile_map.render(game.renderer, cell, @intCast(i), @intCast(j), pan);
        }
    }
}

pub fn get_mouse_pos() CIPoint {
    var mouse_pos: CIPoint = undefined;
    _ = c.SDL_GetMouseState(&mouse_pos.x, &mouse_pos.y);
    return mouse_pos;
}

pub fn reset_panning(pan: *FPoint) void {
    pan.* = FPoint{ .x = WINDOW_WIDTH / 2, .y = WINDOW_HEIGHT / 2 };
}

pub fn set_zoom(renderer: *c.SDL_Renderer, pan: *FPoint, zoom: *f64, new_zoom: f64) void {
    const mouse_pos = FPoint.from_ci_point(get_mouse_pos());
    const mouse_old_screenspace = FPoint{
        .x = mouse_pos.x / zoom.* - pan.*.x,
        .y = mouse_pos.y / zoom.* - pan.*.y,
    };
    const mouse_new_screenspace = FPoint{
        .x = mouse_pos.x / new_zoom - pan.*.x,
        .y = mouse_pos.y / new_zoom - pan.*.y,
    };

    zoom.* = new_zoom;

    pan.*.x -= mouse_old_screenspace.x - mouse_new_screenspace.x;
    pan.*.y -= mouse_old_screenspace.y - mouse_new_screenspace.y;

    const zoom_f32: f32 = @floatCast(zoom.*);
    _ = c.SDL_RenderSetScale(renderer, zoom_f32, zoom_f32);
}

pub fn do_trap_mouse(game: *Game) void {
    const THRESHOLD = 3;
    const MIN_X = THRESHOLD;
    const MAX_X = WINDOW_WIDTH - THRESHOLD;
    const MIN_Y = THRESHOLD;
    const MAX_Y = WINDOW_HEIGHT - THRESHOLD;

    var mouse_pos = get_mouse_pos();
    var warp = false;

    if (mouse_pos.x < MIN_X) {
        mouse_pos.x = MAX_X - mouse_pos.x;
        warp = true;
    } else if (mouse_pos.x > MAX_X) {
        mouse_pos.x = THRESHOLD;
        warp = true;
    }

    if (mouse_pos.y < MIN_Y) {
        mouse_pos.y = MAX_Y - mouse_pos.y;
        warp = true;
    } else if (mouse_pos.y > MAX_Y) {
        mouse_pos.y = THRESHOLD;
        warp = true;
    }

    if (warp) {
        _ = c.SDL_WarpMouseInWindow(game.window, mouse_pos.x, mouse_pos.y);
    }
}

const PAN_SPEED: f64 = 10.0;

pub fn main() !void {
    var game = try Game.init();
    defer game.deinit();

    const allocator = std.heap.page_allocator;

    var map = [5][5]u8{
        [5]u8{ 0, 2, 0, 0, 0 },
        [5]u8{ 0, 0, 2, 0, 0 },
        [5]u8{ 0, 1, 1, 1, 1 },
        [5]u8{ 0, 0, 1, 1, 0 },
        [5]u8{ 0, 0, 0, 0, 1 },
    };

    const keyboard = c.SDL_GetKeyboardState(null);
    _ = keyboard;

    var quit = false;

    var pan = FPoint{ .x = 0, .y = 0 };
    reset_panning(&pan);
    var zoom: f64 = 1.0;

    var mouse_pressed = false;
    var mouse_pos = FPoint{ .x = 0, .y = 0 };
    var trap_mouse = false;

    while (!quit) {
        var event: c.SDL_Event = undefined;

        if (trap_mouse) {
            do_trap_mouse(&game);
        }

        mouse_pos = FPoint.from_ci_point(get_mouse_pos());
        mouse_pressed = false;

        trap_mouse = false;

        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => quit = true,
                    c.SDLK_LEFT => pan.x += PAN_SPEED,
                    c.SDLK_RIGHT => pan.x -= PAN_SPEED,
                    c.SDLK_UP => pan.y += PAN_SPEED,
                    c.SDLK_DOWN => pan.y -= PAN_SPEED,
                    c.SDLK_0 => reset_panning(&pan),
                    else => {},
                },
                c.SDL_MOUSEBUTTONUP => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => mouse_pressed = true,
                    else => {},
                },
                c.SDL_MOUSEMOTION => {
                    if (event.motion.state & c.SDL_BUTTON_MMASK != 0) {
                        pan.x += @floatFromInt(event.motion.xrel);
                        pan.y += @floatFromInt(event.motion.yrel);
                        trap_mouse = true;
                    }
                },
                c.SDL_MOUSEWHEEL => {
                    if (event.wheel.y != 0) {
                        const zoom_delta: f64 = if (event.wheel.y > 0) 2.0 else 0.5;
                        const new_zoom = std.math.clamp(zoom * zoom_delta, MIN_ZOOM, MAX_ZOOM);
                        set_zoom(
                            game.renderer,
                            &pan,
                            &zoom,
                            new_zoom,
                        );
                    }
                },
                else => {},
            }
        }

        _ = c.SDL_SetRenderDrawColor(game.renderer, 0x20, 0x18, 0x18, 255);
        _ = c.SDL_RenderClear(game.renderer);

        // Render code:

        render_map(&game, pan, map);

        const grid_pos = TileMap.grid_coords_from_screen(FPoint{ .x = (mouse_pos.x / zoom) - pan.x, .y = (mouse_pos.y / zoom) - pan.y });
        const x: c_int = @intFromFloat(std.math.round(grid_pos.x));
        const y: c_int = @intFromFloat(std.math.round(grid_pos.y));
        game.tile_map.render(game.renderer, 3, x, y, pan);
        if (mouse_pressed and x >= 0 and x < map.len and y >= 0 and y < map.len) {
            map[@intCast(x)][@intCast(y)] = (map[@intCast(x)][@intCast(y)] + 1) % 5;
        }

        const str: []const u8 = try std.fmt.allocPrint(
            allocator,
            "Pan: ({d}, {d}) MWS: ({d}, {d}) Zoom: {d}",
            .{
                pan.x,
                pan.y,
                mouse_pos.x / zoom - pan.x,
                mouse_pos.y / zoom - pan.y,
                zoom,
            },
        );
        const text_surface = c.TTF_RenderText_Solid(
            game.font,
            @as([*:0]const u8, @ptrCast(str)),
            c.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        ) orelse {
            return error.SDLError;
        };
        allocator.free(str);
        const text_texture = c.SDL_CreateTextureFromSurface(game.renderer, text_surface) orelse {
            return error.SDLError;
        };
        var text_w: c_int = 0;
        var text_h: c_int = 0;
        _ = c.SDL_QueryTexture(text_texture, null, null, &text_w, &text_h);
        _ = c.SDL_RenderCopy(game.renderer, text_texture, null, &c.SDL_Rect{
            .w = @intFromFloat(@as(f64, @floatFromInt(text_w)) / zoom),
            .h = @intFromFloat(@as(f64, @floatFromInt(text_h)) / zoom),
            .x = 0,
            .y = 0,
        });

        c.SDL_RenderPresent(game.renderer);

        c.SDL_Delay(1000 / 60);
    }
}
