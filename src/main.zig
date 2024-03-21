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

const statsUpgradeValue = "^ %.2f";
const statsUpgradeInstruction = "-> $%.0f | Press %i";
const statsNameX: u32 = 5;
const statsNumsX: u32 = 142;
const statsUpgradeValX: u32 = 195;
const statsUpgradeInsX: u32 = 255;

const scaleHealth = [_]f32{ 10, 12 };
const scaleDamage = [_]f32{ 1, 2, 5, 8, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50 };
const scaleRotationalSpeed = [_]f32{ 10, 1.1, 1.2, 1.5, 1.7, 2, 2.2, 2.4, 2.6, 2.8, 3 };
const scaleProjectileSpeed = [_]f32{ 4, 5, 6, 7, 8, 9, 10 };
const scaleCooldown = [_]f32{ 0.1, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1 };
const scaleCash = [_]f32{ 5, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 };

const maxLevelHealth = scaleHealth.len;
const maxLevelDamage = scaleDamage.len;
const maxLevelRotationalSpeed = scaleRotationalSpeed.len;
const maxLevelProjectileSpeed = scaleProjectileSpeed.len;
const maxLevelCooldown = scaleCooldown.len;

const enemyToughnessScalar: f32 = 1.2;
const enemyColors = [_]rl.Color{ rl.Color.green, rl.Color.dark_green, rl.Color.red, rl.Color.purple, rl.Color.dark_purple };
const enemyReward = [_]f32{ 2, 4, 6, 8, 10, 15, 20 };
const MAX_ENEMY_DELAY = 30;

const KEY_UPGRADE_HEALTH: u32 = 1;
const KEY_UPGRADE_DAMAGE: u32 = 2;
const KEY_UPGRADE_ROT_SPEED: u32 = 3;
const KEY_UPGRADE_PRO_SPEED: u32 = 4;
const KEY_UPGRADE_COOLDOWN: u32 = 5;
//////////////////////////////////////////////////////////////
/// VARIABLES
//////////////////////////////////////////////////////////////

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;
var highlightColor = rl.Color.red;
var dt: f32 = 1;
var timeSinceLastShot: f32 = 0;

//////////////////////////////////////////////////////////////
/// STRUCTS & CONTAINERS
//////////////////////////////////////////////////////////////
const State = struct {
    time: f32 = 0,
    cash: f32 = 0,
    wave: u32 = 1,
    waveTime: f32 = 0,
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
    rotationalSpeed: f32,
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
    delay: f32,
};
var hiddenEnemies: std.ArrayList(Enemy) = undefined;
var visibleEnemies: std.ArrayList(Enemy) = undefined;

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
            level += 1;
        }
        const speed: f32 = @as(f32, @floatFromInt(level)) * enemyToughnessScalar * (rng.float(f32) * 0.2 + 0.9);

        var position: rl.Vector2 = .{ .x = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_WIDTH)), .y = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_HEIGHT)) };
        var side = @mod(rng.int(i32), 4);
        if (side == 0) {
            position = .{ .x = 0, .y = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_HEIGHT)) };
        } else if (side == 1) {
            position = .{ .x = SCREEN_WIDTH, .y = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_HEIGHT)) };
        } else if (side == 2) {
            position = .{ .x = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_WIDTH)), .y = 0 };
        } else if (side == 3) {
            position = .{ .x = rng.float(f32) * @as(f32, @floatFromInt(SCREEN_WIDTH)), .y = SCREEN_HEIGHT };
        }
        const delta: rl.Vector2 = rlm.vector2Subtract(player.pos, position);
        const rotationAngle: f32 = std.math.atan2(f32, delta.y, delta.x);
        const rotationDegrees: f32 = rotationAngle * (180.0 / std.math.pi);
        const moveDir = rl.Vector2.init(math.cos(rotationAngle), math.sin(rotationAngle));

        std.log.info("{} {}", .{ moveDir.x, moveDir.y });
        const velocity: rl.Vector2 = rlm.vector2Scale(moveDir, speed);

        try hiddenEnemies.append(.{
            .pos = position,
            .vel = velocity,
            .rot = rotationDegrees,
            .size = 10 / speed,
            .health = 10 * @as(f32, @floatFromInt(level)) * enemyToughnessScalar,
            .level = level,
            .delay = rng.float(f32) * MAX_ENEMY_DELAY,
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
    state.waveTime += dt;
    timeSinceLastShot += dt;

    //USEFUL VARIABLES
    const dirRadians = (player.rot + 90) * (math.pi / 180.0);
    const gunDir = rl.Vector2.init(math.cos(dirRadians), math.sin(dirRadians));

    // INPUTS
    if (rl.isKeyPressed(.key_j)) {
        try switchColor();
    }

    if (rl.isKeyDown(.key_a)) {
        player.rot -= player.rotationalSpeed * math.tau * dt;
    }

    if (rl.isKeyDown(.key_d)) {
        player.rot += player.rotationalSpeed * math.tau * dt;
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

    if (rl.isKeyPressed(.key_one) and state.levelHealth != maxLevelHealth) {
        // upgrade health
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelHealth);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelHealth += 1;
            player.health = getValueForLevel(&scaleHealth, state.levelHealth);
        }
    } else if (rl.isKeyPressed(.key_two) and state.levelDamage != maxLevelDamage) {
        // upgrade damage
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelDamage);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelDamage += 1;
            player.damage = getValueForLevel(&scaleDamage, state.levelDamage);
        }
    } else if (rl.isKeyPressed(.key_three) and state.levelRotationalSpeed != maxLevelRotationalSpeed) {
        // upgrade rotational speed
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelRotationalSpeed);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelRotationalSpeed += 1;
            player.rotationalSpeed = getValueForLevel(&scaleRotationalSpeed, state.levelRotationalSpeed);
        }
    } else if (rl.isKeyPressed(.key_four) and state.levelProjectileSpeed != maxLevelProjectileSpeed) {
        // upgrade projectile speed
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelProjectileSpeed);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelProjectileSpeed += 1;
            player.projectileSpeed = getValueForLevel(&scaleProjectileSpeed, state.levelProjectileSpeed);
        }
    } else if (rl.isKeyPressed(.key_five) and state.levelCooldown != maxLevelCooldown) {
        // upgrade cooldown
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelCooldown);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelCooldown += 1;
            player.cooldown = getValueForLevel(&scaleCooldown, state.levelCooldown);
        }
    }

    // ENEMIES
    var i: usize = 0;

    // spawn in hidden enemies
    while (i < hiddenEnemies.items.len) {
        var e = &hiddenEnemies.items[i];
        if (e.delay <= state.waveTime) {
            try visibleEnemies.append(hiddenEnemies.swapRemove(i));
        }
        i += 1;
    }

    // move visible enemies
    i = 0;
    while (i < visibleEnemies.items.len) {
        var e = &visibleEnemies.items[i];
        var potentialPos: rl.Vector2 = rlm.vector2Add(e.pos, rlm.vector2Scale(e.vel, dt * 10));
        var doesCollide: bool = false;
        for (visibleEnemies.items) |*ve| {
            if (ve.pos.x != e.pos.x and ve.pos.y != e.pos.y) {
                if (rlm.vector2Distance(potentialPos, ve.pos) < (ve.size + e.size + 5)) {
                    doesCollide = true;
                }
            }
        }

        if (!doesCollide) {
            //move
            e.pos = potentialPos;
        }
        //enemy hit player
        const offset: f32 = 5;
        if (rlm.vector2Distance(e.pos, player.pos) < player.turretSize + offset) {
            _ = visibleEnemies.swapRemove(i);
            //player.health = player.health - e.health;
        } else {
            // enemy hit by projectile
            var ip: usize = 0;
            while (ip < projectiles.items.len) {
                var p = &projectiles.items[ip];
                if (rlm.vector2Distance(e.pos, p.pos) < e.size + p.size) {
                    state.cash += getValueForLevel(&enemyReward, e.level);
                    _ = visibleEnemies.swapRemove(i);
                    _ = projectiles.swapRemove(ip);
                }
                ip += 1;
            }
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

fn drawStat(
    rowNum: i32,
    name: [:0]const u8,
    currentValue: f32,
    currentLevel: u32,
    maxLevel: u32,
    scale: []const f32,
    upgradeKey: u32,
) !void {
    const textHeight: i32 = STATS_FONT_SIZE * rowNum + 5;
    rl.drawText(name, statsNameX, textHeight, STATS_FONT_SIZE, fgColor);
    rl.drawText(rl.textFormat(": %.2f", .{currentValue}), statsNumsX, textHeight, STATS_FONT_SIZE, fgColor);

    if (currentLevel == maxLevel) {
        rl.drawText(
            "MAX",
            statsUpgradeValX,
            textHeight,
            STATS_FONT_SIZE,
            highlightColor,
        );
    } else {
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, currentLevel);
        if (state.cash >= cashNeededForUpgrade) {
            rl.drawText(
                rl.textFormat(statsUpgradeValue, .{getValueForLevel(scale, currentLevel + 1)}),
                statsUpgradeValX,
                textHeight,
                STATS_FONT_SIZE,
                highlightColor,
            );
            rl.drawText(
                rl.textFormat(statsUpgradeInstruction, .{ getValueForLevel(&scaleCash, currentLevel), upgradeKey }),
                statsUpgradeInsX,
                textHeight,
                STATS_FONT_SIZE,
                highlightColor,
            );
        }
    }
}

fn render() !void {
    // PROJECTILES
    for (projectiles.items) |*p| {
        rl.drawCircleV(p.pos, p.size, fgColor);
    }
    // ENEMIES
    for (visibleEnemies.items) |*e| {
        rl.drawCircleV(e.pos, e.size, enemyColors[0]);
    }

    try drawPlayer();

    // WAVE
    const waveString: [:0]const u8 = rl.textFormat("WAVE %02i", .{state.wave});
    const waveStringWidth = rl.measureText(waveString, WAVE_FONT_SIZE);
    const waveStringX = @divFloor(SCREEN_WIDTH, 2) - @divFloor(waveStringWidth, 2);
    rl.drawText(waveString, waveStringX, 5, WAVE_FONT_SIZE, fgColor);

    // STATS
    const cashString: [:0]const u8 = rl.textFormat("$%.2f", .{state.cash});
    const cashStringWidth = rl.measureText(cashString, CASH_FONT_SIZE);
    rl.drawText(cashString, SCREEN_WIDTH - cashStringWidth - 5, 5, CASH_FONT_SIZE, fgColor);

    try drawStat(0, "Turret health", player.health, state.levelHealth, maxLevelHealth, &scaleHealth, KEY_UPGRADE_HEALTH);
    try drawStat(1, "Damage", player.damage, state.levelDamage, maxLevelDamage, &scaleDamage, KEY_UPGRADE_DAMAGE);
    try drawStat(2, "Rotational speed", player.rotationalSpeed, state.levelRotationalSpeed, maxLevelRotationalSpeed, &scaleRotationalSpeed, KEY_UPGRADE_ROT_SPEED);
    try drawStat(3, "Projectile speed", player.projectileSpeed, state.levelProjectileSpeed, maxLevelProjectileSpeed, &scaleProjectileSpeed, KEY_UPGRADE_PRO_SPEED);
    try drawStat(4, "Gun cooldown", player.cooldown, state.levelCooldown, maxLevelCooldown, &scaleCooldown, KEY_UPGRADE_COOLDOWN);
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
        .rotationalSpeed = getValueForLevel(&scaleRotationalSpeed, 1),
        .damage = getValueForLevel(&scaleDamage, 1),
        .projectileSpeed = getValueForLevel(&scaleProjectileSpeed, 1),
        .cooldown = getValueForLevel(&scaleCooldown, 1),
    };

    projectiles = std.ArrayList(Projectile).init(allocator);
    hiddenEnemies = std.ArrayList(Enemy).init(allocator);
    visibleEnemies = std.ArrayList(Enemy).init(allocator);

    defer projectiles.deinit();
    defer hiddenEnemies.deinit();
    defer visibleEnemies.deinit();

    // WINDOW & GAME LOOP
    try generateEnemies(50, state.wave, 21413134);

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
