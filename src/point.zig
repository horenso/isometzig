pub const FPoint = struct {
    x: f64,
    y: f64,

    pub fn from_ci_point(ci_point: CIPoint) FPoint {
        return FPoint{ .x = @floatFromInt(ci_point.x), .y = @floatFromInt(ci_point.y) };
    }
};

pub const CIPoint = struct { x: c_int, y: c_int };
