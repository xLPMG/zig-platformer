const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const math = std.math;
const rand = std.rand;
//////////////////////////////////////////////////////////////
/// CONSTANTS
//////////////////////////////////////////////////////////////
const SCREEN_WIDTH = 1000;
const SCREEN_HEIGHT = 600;

const CASH_FONT_SIZE: i16 = 24;
const STATS_FONT_SIZE: i16 = 17;
const WAVE_FONT_SIZE: i16 = 32;

const statsUpgradeText = "^ %.2f -> $%.0f";
const statsNameX: u32 = 5;
const statsNumsX: u32 = 140;
const statsUpgradeX: u32 = 195;

const scaleHealth = [_]f32{ 10, 12 };
const scaleDamage = [_]f32{ 1, 2, 5, 8, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50 };
const scaleRotationalSpeed = [_]f32{ 10, 1.1, 1.2, 1.5, 1.7, 2, 2.2, 2.4, 2.6, 2.8, 3 };
const scaleProjectileSpeed = [_]f32{ 4, 5, 6, 7, 8, 9, 10 };
const scaleCooldown = [_]f32{ 0.5, 1.9, 1.8, 1.6, 1.4, 1.2, 1, 0.8, 0.6, 0.5, 0.4, 0.3, 0.2 };
const scaleCash = [_]f32{ 5, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 };

const enemyToughnessScalar: f32 = 1.2;
const enemyColors = [_]rl.Color{ rl.Color.green, rl.Color.dark_green, rl.Color.red, rl.Color.purple, rl.Color.dark_purple };
//////////////////////////////////////////////////////////////
/// VARIABLES
//////////////////////////////////////////////////////////////

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;
var dt: f32 = 1;
var timeSinceLastShot: f32 = 0;

//////////////////////////////////////////////////////////////
/// STRUCTS & CONTAINERS
//////////////////////////////////////////////////////////////
const State = struct {
    time: f32 = 0,
    cash: u32 = 200,
    wave: u32 = 1,
    levelHealth: u32 = 1,
    levelDamage: u32 = 1,
    levelRotationalSpeed: u32 = 1,
    levelProjectileSpeed: u32 = 1,
    levelCooldown: u32 = 1,
};
var state: State = undefined;

const Player = struct {
    pos: rl.Vector2,
    health: f32,
    turretSize: f32,
    gunSize: rl.Vector2,
    rot: f32,
    speed: f32,
    damage: f32,
    projectileSpeed: f32,
    cooldown: f32,
};
var player: Player = undefined;

const Enemy = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    rot: f32,
    size: f32,
    health: f32,
    level: u32,
};
var enemies: std.ArrayList(Enemy) = undefined;

const Projectile = struct {
    pos: rl.Vector2 = .{ .x = 0, .y = 0 },
    vel: rl.Vector2 = .{ .x = 0, .y = 0 },
    size: f32 = 5,
};
var projectiles: std.ArrayList(Projectile) = undefined;

//////////////////////////////////////////////////////////////
/// FUNCTIONS
//////////////////////////////////////////////////////////////

fn switchColor() !void {
    var oldBgColor = bgColor;
    bgColor = fgColor;
    fgColor = oldBgColor;
}

fn getValueForLevel(array: []const f32, level: u32) f32 {
    var index = level - 1;
    if (index >= array.len) {
        return array[array.len - 1];
    } else {
        return array[index];
    }
}

fn generateEnemies(amount: u32, wave: u32, seed: u64) !void {
    var prng = rand.Xoshiro256.init(seed);
    var rng = prng.random();

    for (0..amount) |_| {
        var level: u32 = wave;
        if (rng.float(f32) < 0.5) {
            level = level + 1;
        }
        const speed: f32 = @as(f32, @floatFromInt(level)) * enemyToughnessScalar * (rng.float(f32) * 0.2 + 0.9);

        //const offsetX: i32 = (-1 * @mod(rng.next(), 2)) * SCREEN_WIDTH;
        //const offsetY: i32 = (-1 * @mod(rng.next(), 2)) * SCREEN_HEIGHT;

        const position: rl.Vector2 = .{ .x = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_WIDTH)), .y = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_HEIGHT)) };

        const delta: rl.Vector2 = rlm.vector2Subtract(player.pos, position);
        const rotationAngle: f32 = std.math.atan2(f32, delta.y, delta.x);
        const rotationDegrees: f32 = rotationAngle * (180.0 / std.math.pi);
        const moveDir = rl.Vector2.init(math.cos(rotationAngle), math.sin(rotationAngle));

        std.log.info("{} {}", .{ moveDir.x, moveDir.y });
        const velocity: rl.Vector2 = rlm.vector2Scale(moveDir, speed);

        try enemies.append(.{
            .pos = position,
            .vel = velocity,
            .rot = rotationDegrees,
            .size = 10 / speed,
            .health = 10 * @as(f32, @floatFromInt(level)) * enemyToughnessScalar,
            .level = level,
        });
    }
}

fn drawPlayer() !void {
    //turret
    rl.drawCircleV(player.pos, player.turretSize, fgColor);

    // gun
    var rec: rl.Rectangle = .{
        .x = player.pos.x,
        .y = player.pos.y,
        .width = player.gunSize.x,
        .height = player.gunSize.y,
    };
    rl.drawRectanglePro(rec, .{ .x = player.gunSize.x / 2, .y = 0 }, player.rot, fgColor);
}

fn update() !void {
    // TIME
    dt = rl.getFrameTime();
    state.time += dt;
    timeSinceLastShot += dt;

    //USEFUL VARIABLES
    const dirRadians = (player.rot + 90) * (math.pi / 180.0);
    const gunDir = rl.Vector2.init(math.cos(dirRadians), math.sin(dirRadians));

    // INPUTS
    if (rl.isKeyPressed(.key_j)) {
        try switchColor();
    }

    if (rl.isKeyDown(.key_a)) {
        player.rot -= player.speed * math.tau * dt;
    }

    if (rl.isKeyDown(.key_d)) {
        player.rot += player.speed * math.tau * dt;
    }

    if (rl.isKeyDown(.key_space)) {
        if (timeSinceLastShot > player.cooldown) {
            try projectiles.append(.{
                .pos = rlm.vector2Add(player.pos, rlm.vector2Scale(gunDir, player.gunSize.y + 4)),
                .vel = rlm.vector2Scale(gunDir, player.projectileSpeed),
            });
            timeSinceLastShot = 0.0;
        }
    }

    // ENEMIES
    var i: usize = 0;
    while (i < enemies.items.len) {
        var e = &enemies.items[i];
        e.pos = rlm.vector2Add(e.pos, rlm.vector2Scale(e.vel, dt * 10));
        //enemy hit player
        if ((e.pos.x < player.pos.x + 5) and (e.pos.x > player.pos.x - 5) and (e.pos.y < player.pos.y + 5) and (e.pos.y > player.pos.y - 5)) {
            _ = enemies.swapRemove(i);
            //player.health = player.health - e.health;
        }
        i += 1;
    }

    //PROJECTILES
    i = 0;
    while (i < projectiles.items.len) {
        var p = &projectiles.items[i];
        p.pos = rlm.vector2Add(p.pos, rlm.vector2Scale(p.vel, dt * 10));
        //projectile left the screen
        if ((p.pos.x < 0) or (p.pos.y < 0) or (p.pos.x > SCREEN_WIDTH) or (p.pos.y > SCREEN_HEIGHT)) {
            _ = projectiles.swapRemove(i);
        }
        i += 1;
    }
}

fn render() !void {
    try drawPlayer();

    // PROJECTILES
    for (projectiles.items) |p| {
        rl.drawCircleV(p.pos, p.size, fgColor);
    }
    // ENEMIES
    for (enemies.items) |e| {
        rl.drawCircleV(e.pos, e.size, enemyColors[0]);
    }

    // WAVE
    const waveString: [:0]const u8 = rl.textFormat("WAVE %02i", .{state.wave});
    const waveStringWidth = rl.measureText(waveString, WAVE_FONT_SIZE);
    const waveStringX = @divFloor(SCREEN_WIDTH, 2) - @divFloor(waveStringWidth, 2);
    rl.drawText(waveString, waveStringX, 5, WAVE_FONT_SIZE, fgColor);

    // STATS
    const cashString: [:0]const u8 = rl.textFormat("$%02i", .{state.cash});
    const cashStringWidth = rl.measureText(cashString, CASH_FONT_SIZE);
    rl.drawText(cashString, SCREEN_WIDTH - cashStringWidth - 5, 5, CASH_FONT_SIZE, fgColor);

    const y1 = STATS_FONT_SIZE * 0 + 5;
    rl.drawText("Turret health", statsNameX, y1, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2f", .{player.health}), statsNumsX, y1, STATS_FONT_SIZE, fgColor);
    if (@as(f32, @floatFromInt(state.cash)) >= @as(f32, @floatFromInt(state.levelHealth)) * getValueForLevel(&scaleCash, state.levelHealth)) {
        rl.drawText(rl.textFormat(statsUpgradeText, .{ getValueForLevel(&scaleHealth, state.levelHealth + 1), getValueForLevel(&scaleCash, state.levelHealth) }), statsUpgradeX, y1, STATS_FONT_SIZE, fgColor);
    }

    const y2 = STATS_FONT_SIZE * 1 + 5;
    rl.drawText("Damage", statsNameX, y2, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2f", .{player.damage}), statsNumsX, y2, STATS_FONT_SIZE, fgColor);
    if (@as(f32, @floatFromInt(state.cash)) >= @as(f32, @floatFromInt(state.levelDamage)) * getValueForLevel(&scaleCash, state.levelDamage)) {
        rl.drawText(rl.textFormat(statsUpgradeText, .{ getValueForLevel(&scaleDamage, state.levelDamage + 1), getValueForLevel(&scaleCash, state.levelDamage) }), statsUpgradeX, y2, STATS_FONT_SIZE, fgColor);
    }

    const y3 = STATS_FONT_SIZE * 2 + 5;
    rl.drawText("Turret speed", statsNameX, y3, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2f", .{player.speed}), statsNumsX, y3, STATS_FONT_SIZE, fgColor);
    if (@as(f32, @floatFromInt(state.cash)) >= @as(f32, @floatFromInt(state.levelRotationalSpeed)) * getValueForLevel(&scaleCash, state.levelRotationalSpeed)) {
        rl.drawText(rl.textFormat(statsUpgradeText, .{ getValueForLevel(&scaleRotationalSpeed, state.levelRotationalSpeed + 1), getValueForLevel(&scaleCash, state.levelRotationalSpeed) }), statsUpgradeX, y3, STATS_FONT_SIZE, fgColor);
    }

    const y4 = STATS_FONT_SIZE * 3 + 5;
    rl.drawText("Projectile speed", statsNameX, y4, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2f", .{player.projectileSpeed}), statsNumsX, y4, STATS_FONT_SIZE, fgColor);
    if (@as(f32, @floatFromInt(state.cash)) >= @as(f32, @floatFromInt(state.levelProjectileSpeed)) * getValueForLevel(&scaleCash, state.levelProjectileSpeed)) {
        rl.drawText(rl.textFormat(statsUpgradeText, .{ getValueForLevel(&scaleProjectileSpeed, state.levelProjectileSpeed + 1), getValueForLevel(&scaleCash, state.levelProjectileSpeed) }), statsUpgradeX, y4, STATS_FONT_SIZE, fgColor);
    }

    const y5 = STATS_FONT_SIZE * 4 + 5;
    rl.drawText("Gun cooldown", statsNameX, y5, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2fs", .{player.cooldown}), statsNumsX, y5, STATS_FONT_SIZE, fgColor);
    if (@as(f32, @floatFromInt(state.cash)) >= @as(f32, @floatFromInt(state.levelCooldown)) * getValueForLevel(&scaleCash, state.levelCooldown)) {
        rl.drawText(rl.textFormat(statsUpgradeText, .{ getValueForLevel(&scaleCooldown, state.levelCooldown + 1), getValueForLevel(&scaleCash, state.levelCooldown) }), statsUpgradeX, y5, STATS_FONT_SIZE, fgColor);
    }
}

//////////////////////////////////////////////////////////////
/// MAIN
//////////////////////////////////////////////////////////////
pub fn main() anyerror!void {
    // INITIALIZATIONS
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    state = .{};
    player = .{
        .pos = .{ .x = SCREEN_WIDTH / 2, .y = SCREEN_HEIGHT / 2 },
        .health = getValueForLevel(&scaleHealth, 1),
        .turretSize = 10,
        .gunSize = .{ .x = 10, .y = 20 },
        .rot = 0.0,
        .speed = getValueForLevel(&scaleRotationalSpeed, 1),
        .damage = getValueForLevel(&scaleDamage, 1),
        .projectileSpeed = getValueForLevel(&scaleProjectileSpeed, 1),
        .cooldown = getValueForLevel(&scaleCooldown, 1),
    };

    projectiles = std.ArrayList(Projectile).init(allocator);
    defer projectiles.deinit();

    enemies = std.ArrayList(Enemy).init(allocator);
    defer enemies.deinit();

    // WINDOW & GAME LOOP
    try generateEnemies(100, state.wave, 21413134);

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "turret defense!");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        try update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        try render();
    }
}
