const std = @import("std");
const math = std.math;
const c = @import("./sdl.zig").SDL;
const TileMap = @import("./tile_map.zig").TileMap;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;

pub const Game = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    tile_map: TileMap,

    pub fn init() !Game {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        errdefer c.SDL_Quit();

        if (c.IMG_Init(c.IMG_INIT_PNG) != c.IMG_INIT_PNG) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        errdefer c.IMG_Quit();

        const window = c.SDL_CreateWindow("Zigout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, 0) orelse {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyWindow(window);

        const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC) orelse {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyRenderer(renderer);

        const tile_map = try TileMap.init(renderer);
        errdefer tile_map.deinit();

        return Game{
            .window = window,
            .renderer = renderer,
            .tile_map = tile_map,
        };
    }

    pub fn deinit(self: *Game) void {
        self.tile_map.deinit();
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.IMG_Quit();
        c.SDL_Quit();
    }
};
