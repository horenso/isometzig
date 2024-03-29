const std = @import("std");
const math = std.math;
const Game = @import("./game.zig").Game;
const c = @import("./sdl.zig").SDL;
const point = @import("./point.zig");
const FPoint = point.FPoint;
const CIPoint = point.CIPoint;

const TILE_WIDTH = 64;
const TILE_HEIGHT = 32;

const TILE_WIDTH_HALF = TILE_WIDTH / 2;
const TILE_HEIGHT_HALF = TILE_HEIGHT / 2;

const TEXTURE_PATH = "./graphics/tiles.png";
const TILES_ON_TEXTURE_X = 8;
const TILES_ON_TEXTURE_Y = 16;

const TileMapError = error{SDLResourceLoadingFailed};

pub const Character = struct {
    facing_left: bool,
    start_id: u8,
    frames: u8,
    grid_pos: CIPoint,
    animation_time: f64,
    elapsed_time_since_animated: f64 = 0,
    current_animation_frame: u8 = 0,
    grid_delta: FPoint = FPoint{ .x = 0.0, .y = 0.0 },
    play_animation: bool = false,

    pub fn advance_animation(self: *Character) void {
        self.*.current_animation_frame = (self.*.current_animation_frame + 1) % self.frames;
    }

    pub fn animate(self: *Character, delta_time: f64) void {
        self.elapsed_time_since_animated += delta_time;
        if (self.elapsed_time_since_animated >= self.animation_time) {
            self.advance_animation();
            self.elapsed_time_since_animated = 0.0;
        }
    }
};

pub const TileMap = struct {
    renderer: *c.SDL_Renderer, // weak
    sdl_texture: *c.SDL_Texture,

    pub fn init(
        renderer: *c.SDL_Renderer,
    ) TileMapError!TileMap {
        const sdl_texture = c.IMG_LoadTexture(renderer, TEXTURE_PATH) orelse {
            c.SDL_Log("Failed to load resource: %s", c.SDL_GetError());
            return TileMapError.SDLResourceLoadingFailed;
        };

        _ = c.SDL_SetTextureBlendMode(sdl_texture, c.SDL_BLENDMODE_BLEND);

        return TileMap{
            .renderer = renderer,
            .sdl_texture = sdl_texture,
        };
    }

    pub fn deinit(self: *TileMap) void {
        c.SDL_DestroyTexture(self.sdl_texture);
    }

    pub fn grid_coords_from_screen(screen: FPoint) FPoint {
        return FPoint{
            .x = ((screen.x / TILE_WIDTH_HALF + screen.y / TILE_HEIGHT_HALF) / 2),
            .y = ((screen.y / TILE_HEIGHT_HALF - screen.x / TILE_WIDTH_HALF) / 2),
        };
    }

    pub fn screen_coords_from_grid(grid: FPoint) FPoint {
        return FPoint{
            .x = ((grid.x - grid.y) * TILE_WIDTH_HALF - TILE_WIDTH_HALF),
            .y = ((grid.x + grid.y) * TILE_HEIGHT_HALF - TILE_HEIGHT_HALF),
        };
    }

    pub fn render_character(
        self: *TileMap,
        character: *Character,
        pan: FPoint,
        flipped: bool,
    ) void {
        self.render(
            character.current_animation_frame,
            character.start_id,
            flipped,
            character.grid_pos.x,
            character.grid_pos.y,
            pan,
        );
    }

    pub fn render(
        self: *TileMap,
        tile_x: u8,
        tile_y: u8,
        mirrored: bool,
        x_coord: c_int,
        y_coord: c_int,
        pan: FPoint,
    ) void {
        var screen_pos = TileMap.screen_coords_from_grid(FPoint{
            .x = @as(f64, @floatFromInt(x_coord)),
            .y = @as(f64, @floatFromInt(y_coord)),
        });
        screen_pos.x += pan.x;
        screen_pos.y += pan.y;
        self.render_from_screenspace(tile_x, tile_y, mirrored, screen_pos);
    }

    fn render_from_screenspace(
        self: *TileMap,
        tile_x: u8,
        tile_y: u8,
        mirrored: bool,
        screen_pos: FPoint,
    ) void {
        const source_rect = c.SDL_Rect{
            .w = TILE_WIDTH,
            .h = TILE_HEIGHT,
            .x = tile_x * TILE_WIDTH,
            .y = tile_y * TILE_HEIGHT,
        };
        const dest_rect = c.SDL_Rect{
            .w = @intFromFloat(TILE_WIDTH),
            .h = @intFromFloat(TILE_HEIGHT),
            .x = @intFromFloat(screen_pos.x),
            .y = @intFromFloat(screen_pos.y),
        };
        _ = c.SDL_RenderCopyEx(
            self.renderer,
            self.sdl_texture,
            &source_rect,
            &dest_rect,
            0,
            null,
            if (mirrored) c.SDL_TRUE else c.SDL_FALSE,
        );
    }
};
