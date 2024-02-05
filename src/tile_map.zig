const std = @import("std");
const math = std.math;
const Game = @import("./game.zig").Game;
const c = @import("./sdl.zig").SDL;
const FPoint = @import("./point.zig").FPoint;

const TILE_WIDTH = 64;
const TILE_HEIGHT = 32;

const MAT_A: f64 = TILE_WIDTH / 2;
const MAT_B: f64 = -TILE_WIDTH / 2;
const MAT_C: f64 = TILE_HEIGHT / 2;
const MAT_D: f64 = TILE_HEIGHT / 2;
const DETERMINANT: f64 = 1 / (MAT_A * MAT_D - MAT_B * MAT_C);

const TEXTURE_PATH = "./graphics/tiles.png";
const TILES_ON_TEXTURE_X = 8;
const TILES_ON_TEXTURE_Y = 16;

pub const TileMap = struct {
    sdl_texture: *c.SDL_Texture,

    pub fn init(
        renderer: *c.SDL_Renderer,
    ) !TileMap {
        const sdl_texture = c.IMG_LoadTexture(renderer, TEXTURE_PATH) orelse {
            c.SDL_Log("Failed to load resource: %s", c.SDL_GetError());
            return error.SDLResourceLoadingFailed;
        };

        _ = c.SDL_SetTextureBlendMode(sdl_texture, c.SDL_BLENDMODE_BLEND);

        return TileMap{
            .sdl_texture = sdl_texture,
        };
    }

    pub fn deinit(self: *TileMap) void {
        c.SDL_DestroyTexture(self.sdl_texture);
    }

    pub fn screen_to_grid_corrds(
        x_screen: f64,
        y_screen: f64,
    ) FPoint {
        return FPoint{
            ((y_screen + (x_screen / 2))) / TILE_WIDTH,
            ((y_screen - (x_screen / 2))) / TILE_HEIGHT,
        };
    }

    pub fn grid_to_screen_coords(
        x_grid: f64,
        y_grid: f64,
    ) FPoint {
        return FPoint{
            (x_grid - y_grid) * (TILE_WIDTH / 2) - (TILE_WIDTH / 2),
            (x_grid + y_grid) * (TILE_HEIGHT / 2) - (TILE_HEIGHT / 2),
        };
    }

    pub fn render(
        self: *TileMap,
        renderer: *c.SDL_Renderer,
        tile_id: u8,
        x_coord: c_int,
        y_coord: c_int,
        x_screen_scroll: f64,
        y_screen_scroll: f64,
    ) void {
        const tile_x: c_int = (tile_id / TILES_ON_TEXTURE_X) * TILE_WIDTH;
        const tile_y: c_int = (tile_id % TILES_ON_TEXTURE_Y) * TILE_HEIGHT;
        const source_rect = c.SDL_Rect{
            .w = TILE_WIDTH,
            .h = TILE_HEIGHT,
            .x = tile_x,
            .y = tile_y,
        };

        const screen = TileMap.grid_to_screen_coords(
            @floatFromInt(x_coord),
            @floatFromInt(y_coord),
        );
        const dest_rect = c.SDL_Rect{
            .w = TILE_WIDTH,
            .h = TILE_HEIGHT,
            .x = @intFromFloat(screen[0] + x_screen_scroll),
            .y = @intFromFloat(screen[1] + y_screen_scroll),
        };
        _ = c.SDL_RenderCopy(
            renderer,
            self.sdl_texture,
            &source_rect,
            &dest_rect,
        );
    }
};
