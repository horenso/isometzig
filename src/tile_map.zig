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
    pos: CIPoint,
    animation: u8,

    pub fn advance_animation(self: *Character) void {
        self.*.animation = (self.animation + 1) % self.frames;
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
    ) void {
        self.render(character.animation, character.start_id, character.pos.x, character.pos.y, pan);
    }

    pub fn render(
        self: *TileMap,
        tile_x: u8,
        tile_y: u8,
        x_coord: c_int,
        y_coord: c_int,
        pan: FPoint,
    ) void {
        const source_rect = c.SDL_Rect{
            .w = TILE_WIDTH,
            .h = TILE_HEIGHT,
            .x = tile_x * TILE_WIDTH,
            .y = tile_y * TILE_HEIGHT,
        };

        const screen = TileMap.screen_coords_from_grid(
            FPoint{ .x = @floatFromInt(x_coord), .y = @floatFromInt(y_coord) },
        );

        const tile_width: c_int = @intFromFloat(TILE_WIDTH);
        const tile_height: c_int = @intFromFloat(TILE_HEIGHT);
        const x: c_int = @intFromFloat((screen.x + pan.x));
        const y: c_int = @intFromFloat((screen.y + pan.y));
        const dest_rect = c.SDL_Rect{
            .w = tile_width,
            .h = tile_height,
            .x = x,
            .y = y,
        };
        _ = c.SDL_RenderCopy(
            self.renderer,
            self.sdl_texture,
            &source_rect,
            &dest_rect,
        );
    }
};
