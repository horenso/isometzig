const std = @import("std");
const math = std.math;
const Game = @import("./game.zig").Game;
const c = @import("./sdl.zig").SDL;
const FPoint = @import("./point.zig").FPoint;

const TILE_WIDTH = 64;
const TILE_HEIGHT = 32;

const TILE_WIDTH_HALF = TILE_WIDTH / 2;
const TILE_HEIGHT_HALF = TILE_HEIGHT / 2;

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

    pub fn grid_coords_from_screen(screen: FPoint, zoom_factor: f64) FPoint {
        return FPoint{
            .x = ((screen.x / TILE_WIDTH_HALF + screen.y / TILE_HEIGHT_HALF) / 2) * zoom_factor,
            .y = ((screen.y / TILE_HEIGHT_HALF - screen.x / TILE_WIDTH_HALF) / 2) * zoom_factor,
        };
    }

    pub fn screen_coords_from_grid(grid: FPoint, zoom_factor: f64) FPoint {
        return FPoint{
            .x = ((grid.x - grid.y) * TILE_WIDTH_HALF - TILE_WIDTH_HALF) * zoom_factor,
            .y = ((grid.x + grid.y) * TILE_HEIGHT_HALF - TILE_HEIGHT_HALF) * zoom_factor,
        };
    }

    pub fn render(
        self: *TileMap,
        renderer: *c.SDL_Renderer,
        tile_id: u8,
        x_coord: c_int,
        y_coord: c_int,
        scroll: FPoint,
        zoom_factor: f64,
    ) void {
        const texture_x: c_int = (tile_id / TILES_ON_TEXTURE_X) * TILE_WIDTH;
        const texture_y: c_int = (tile_id % TILES_ON_TEXTURE_Y) * TILE_HEIGHT;
        const source_rect = c.SDL_Rect{
            .w = TILE_WIDTH,
            .h = TILE_HEIGHT,
            .x = texture_x,
            .y = texture_y,
        };

        const screen = TileMap.screen_coords_from_grid(
            FPoint{ .x = @floatFromInt(x_coord), .y = @floatFromInt(y_coord) },
            zoom_factor,
        );

        const tile_width: c_int = @intFromFloat(TILE_WIDTH * zoom_factor);
        const tile_height: c_int = @intFromFloat(TILE_HEIGHT * zoom_factor);
        const x: c_int = @intFromFloat((screen.x + scroll.x) * zoom_factor);
        const y: c_int = @intFromFloat((screen.y + scroll.y) * zoom_factor);
        const dest_rect = c.SDL_Rect{
            .w = tile_width,
            .h = tile_height,
            .x = x,
            .y = y,
        };
        _ = c.SDL_RenderCopy(
            renderer,
            self.sdl_texture,
            &source_rect,
            &dest_rect,
        );
    }
};
