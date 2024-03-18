const std = @import("std");
const rl = @import("raylib");

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 600;

    rl.initWindow(screenWidth, screenHeight, "Platformer");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        // UPDATES
        //----------------------------------------------------------------------------------

        if (rl.isKeyPressed(rl.KeyboardKey.key_j)) {
            switchColor();
        }

        // DRAWING
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        rl.drawLine(0, 0, 100, 100, fgColor);
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
