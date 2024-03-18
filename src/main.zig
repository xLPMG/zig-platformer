const std = @import("std");
const rl = @import("raylib");

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;

const Player = struct { pos: rl.Vector2, turretSize: f32, gunSize: rl.Vector2, rot: f32, speed: f32, damage: f32 };
var player: Player = undefined;

pub fn drawPlayer() void {
    //turret
    rl.drawCircleV(player.pos, player.turretSize, fgColor);

    // gun
    var rec: rl.Rectangle = .{ .x = player.pos.x, .y = player.pos.y, .width = player.gunSize.x, .height = player.gunSize.y };
    rl.drawRectanglePro(rec, .{ .x = player.gunSize.x / 2, .y = 0 }, player.rot, fgColor);
}

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 600;
    var dt: f32 = 1;

    player = .{ .pos = .{ .x = screenWidth / 2, .y = screenHeight / 2 }, .turretSize = 10, .gunSize = .{ .x = 10, .y = 20 }, .rot = 0.0, .speed = 40, .damage = 1 };

    rl.initWindow(screenWidth, screenHeight, "turret defense!");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        // UPDATES
        //----------------------------------------------------------------------------------
        dt = rl.getFrameTime();
        if (rl.isKeyPressed(rl.KeyboardKey.key_j)) {
            switchColor();
        }

        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            player.rot -= player.speed * dt;
        }

        if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
            player.rot += player.speed * dt;
        }

        // DRAWING
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        drawPlayer();
    }
}

pub fn switchColor() void {
    if (std.meta.eql(bgColor, rl.Color.white)) {
        bgColor = rl.Color.black;
        fgColor = rl.Color.white;
    } else {
        bgColor = rl.Color.white;
        fgColor = rl.Color.black;
    }
}
