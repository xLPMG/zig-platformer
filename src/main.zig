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
const LEVEL_COMPLETED_FONT_SIZE: i16 = 64;

const statsUpgradeValue = "^ %.2f";
const statsUpgradeInstruction = "-> $%.0f | Press %i";
const statsNameX: u32 = 5;
const statsNumsX: u32 = 142;
const statsUpgradeValX: u32 = 195;
const statsUpgradeInsX: u32 = 255;

const scaleHealth = [_]f32{ 5, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30 };
const scaleDamage = [_]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
const scaleRotationalSpeed = [_]f32{ 10, 12, 14, 16, 18, 20 };
const scaleProjectileSpeed = [_]f32{ 4, 5, 6, 7, 8, 9, 10, 11, 12 };
const scaleProjectileSize = [_]f32{ 5, 6, 7, 8, 9, 10, 11, 12 };
const scaleCooldown = [_]f32{ 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.15 };
const scaleCash = [_]f32{ 5, 5, 10, 12.5, 15, 17.5, 20, 25, 30, 35, 40, 45, 50 };

const maxLevelHealth = scaleHealth.len;
const maxLevelDamage = scaleDamage.len;
const maxLevelRotationalSpeed = scaleRotationalSpeed.len;
const maxLevelProjectileSpeed = scaleProjectileSpeed.len;
const maxLevelProjectileSize = scaleProjectileSize.len;
const maxLevelCooldown = scaleCooldown.len;

const enemyColors = [_]rl.Color{
    rl.Color.green,
    rl.Color.green,
    rl.Color.dark_green,
    rl.Color.dark_green,
    rl.Color.yellow,
    rl.Color.yellow,
    rl.Color.orange,
    rl.Color.orange,
    rl.Color.red,
    rl.Color.red,
    rl.Color.purple,
    rl.Color.purple,
    rl.Color.dark_purple,
    rl.Color.dark_purple,
};
const enemyReward = [_]f32{ 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10, 15, 15, 20 };
const enemyDamage = [_]f32{ 1, 1, 2, 2, 3, 3, 4, 4, 6, 6, 8, 8, 10, 10, 12, 12, 14 };
const enemySides = [_]f32{ 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8 };
// max delay until enemies become visible
const MAX_ENEMY_DELAY = 4;
// delay for which enemies will wait when their path is blocked
const ENEMY_WAIT_DELAY = 2.5;

const ENEMY_HIT_PARTICLE_TTL = 0.4;
const ENEMY_DEATH_PARTICLE_TTL = 0.2;
const PLAYER_DEATH_PARTICLE_TTL = 2.5;

const KEY_UPGRADE_HEALTH: u32 = 1;
const KEY_UPGRADE_DAMAGE: u32 = 2;
const KEY_UPGRADE_ROT_SPEED: u32 = 3;
const KEY_UPGRADE_PRO_SPEED: u32 = 4;
const KEY_UPGRADE_PRO_SIZE: u32 = 5;
const KEY_UPGRADE_COOLDOWN: u32 = 6;

const LEVEL_DONE_DELAY: f32 = 5;

//////////////////////////////////////////////////////////////
/// VARIABLES
//////////////////////////////////////////////////////////////

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;
var highlightColor = rl.Color.red;
var dt: f32 = 1;
var timeSinceLastShot: f32 = 0;

var levelDone: bool = false;
var levelFailed: bool = false;
var levelDoneTimer: f32 = 0;

var scope: bool = false;
var autoShoot: bool = false;

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
    levelProjectileSize: u32 = 1,
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
    projectileSize: f32,
    cooldown: f32,
};
var player: Player = undefined;

const Enemy = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    rot: f32,
    size: f32,
    health: f32,
    damage: f32,
    level: u32,
    delay: f32,
    col: rl.Color,
    waitFor: f32 = 0,
};
var hiddenEnemies: std.ArrayList(Enemy) = undefined;
var visibleEnemies: std.ArrayList(Enemy) = undefined;

const Projectile = struct {
    pos: rl.Vector2 = .{ .x = 0, .y = 0 },
    vel: rl.Vector2 = .{ .x = 0, .y = 0 },
    size: f32 = 5,
};
var projectiles: std.ArrayList(Projectile) = undefined;

const Particle = struct {
    pos: rl.Vector2 = .{ .x = 0, .y = 0 },
    vel: rl.Vector2 = .{ .x = 0, .y = 0 },
    size: f32 = 1,
    ttl: f32 = 2,
    col: rl.Color,
};
var particles: std.ArrayList(Particle) = undefined;

const Sound = struct {
    laser1: rl.Sound,
    explosion1: rl.Sound,
    explosion2: rl.Sound,
    hit: rl.Sound,
    death: rl.Sound,
};
var sound: Sound = undefined;

//////////////////////////////////////////////////////////////
/// FUNCTIONS
//////////////////////////////////////////////////////////////

fn getTimeSeed() u64 {
    return @as(u64, @intCast(std.time.timestamp()));
}

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

fn getColorForLevel(array: []const rl.Color, level: u32) rl.Color {
    var index = level - 1;
    if (index >= array.len) {
        return array[array.len - 1];
    } else {
        return array[index];
    }
}

fn generateExplosion(position: rl.Vector2, amount: usize, ttl: f32, color: rl.Color) !void {
    var prng = rand.Xoshiro256.init(getTimeSeed());
    var rng = prng.random();

    for (0..amount) |_| {
        const angle = math.tau * rng.float(f32);
        try particles.append(.{
            .pos = rlm.vector2Add(
                position,
                rl.Vector2.init(rng.float(f32) * 3, rng.float(f32) * 3),
            ),
            .vel = rlm.vector2Scale(
                rl.Vector2.init(
                    math.cos(angle),
                    math.sin(angle),
                ),
                4.0 + 4.0 * rng.float(f32),
            ),
            .ttl = ttl + (ttl * rng.float(f32)),
            .col = color,
            .size = 0.4 + (0.5 * rng.float(f32)),
        });
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
        const speed: f32 = @as(f32, @floatFromInt(level)) * (rng.float(f32) * 0.3 + 0.8);

        var position: rl.Vector2 = undefined;
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
        const velocity: rl.Vector2 = rlm.vector2Scale(moveDir, speed);

        try hiddenEnemies.append(.{
            .pos = position,
            .vel = velocity,
            .rot = rotationDegrees,
            .size = 12 - (getValueForLevel(&enemySides, level)),
            .health = @as(f32, @floatFromInt(level)),
            .damage = getValueForLevel(&enemyDamage, level),
            .level = level,
            .delay = 2 + rng.float(f32) * MAX_ENEMY_DELAY * @as(f32, @floatFromInt(amount)),
            .col = getColorForLevel(&enemyColors, level),
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

fn initLevelLogic() !void {
    levelDone = false;

    // first mini wave
    for (0..5) |i| {
        const speed: f32 = 2;

        var position: rl.Vector2 = .{ .x = 0, .y = SCREEN_HEIGHT / 2 };
        const delta: rl.Vector2 = rlm.vector2Subtract(player.pos, position);
        const rotationAngle: f32 = std.math.atan2(f32, delta.y, delta.x);
        const rotationDegrees: f32 = rotationAngle * (180.0 / std.math.pi);
        const moveDir = rl.Vector2.init(math.cos(rotationAngle), math.sin(rotationAngle));
        const velocity: rl.Vector2 = rlm.vector2Scale(moveDir, speed);

        try hiddenEnemies.append(.{
            .pos = position,
            .vel = velocity,
            .rot = rotationDegrees,
            .size = 15,
            .health = 2,
            .damage = 1,
            .level = 1,
            .delay = 2.0 * @as(f32, @floatFromInt(i)),
            .col = rl.Color.green,
        });
    }

    // second mini wave
    for (0..5) |i| {
        const speed: f32 = 2;

        var position: rl.Vector2 = .{ .x = SCREEN_WIDTH, .y = SCREEN_HEIGHT / 2 };
        const delta: rl.Vector2 = rlm.vector2Subtract(player.pos, position);
        const rotationAngle: f32 = std.math.atan2(f32, delta.y, delta.x);
        const rotationDegrees: f32 = rotationAngle * (180.0 / std.math.pi);
        const moveDir = rl.Vector2.init(math.cos(rotationAngle), math.sin(rotationAngle));
        const velocity: rl.Vector2 = rlm.vector2Scale(moveDir, speed);

        try hiddenEnemies.append(.{
            .pos = position,
            .vel = velocity,
            .rot = rotationDegrees,
            .size = 15,
            .health = 2,
            .damage = 1,
            .level = 1,
            .delay = 25 + 2.0 * @as(f32, @floatFromInt(i)),
            .col = rl.Color.green,
        });
    }
}

fn updateLevelLogic() !void {
    if (levelDone) {
        if (levelDoneTimer > 0) {
            levelDoneTimer -= dt;
        } else {
            levelDoneTimer = 0;
            levelFailed = false;
            levelDone = false;

            // enter new level
            state.wave += 1;
            state.waveTime = 0;
            try generateEnemies(8 + state.wave * 4, state.wave, getTimeSeed());
        }
    }
}

fn update() !void {
    // TIME
    dt = rl.getFrameTime();
    state.time += dt;
    state.waveTime += dt;
    timeSinceLastShot += dt;

    try updateLevelLogic();

    //USEFUL VARIABLES
    const dirRadians = (player.rot + 90) * (math.pi / 180.0);
    const gunDir = rl.Vector2.init(math.cos(dirRadians), math.sin(dirRadians));

    // INPUTS
    if (!levelFailed) {
        if (rl.isKeyPressed(.key_h)) {
            scope = !scope;
        }

        if (rl.isKeyPressed(.key_j)) {
            try switchColor();
        }

        if (rl.isKeyPressed(.key_k)) {
            autoShoot = !autoShoot;
        }

        if (rl.isKeyDown(.key_a)) {
            player.rot -= player.rotationalSpeed * math.tau * dt;
        }

        if (rl.isKeyDown(.key_d)) {
            player.rot += player.rotationalSpeed * math.tau * dt;
        }

        if (rl.isKeyDown(.key_space) or autoShoot) {
            if (timeSinceLastShot > player.cooldown) {
                try projectiles.append(.{
                    .pos = rlm.vector2Add(player.pos, rlm.vector2Scale(gunDir, player.gunSize.y + 4)),
                    .vel = rlm.vector2Scale(gunDir, player.projectileSpeed),
                    .size = player.projectileSize,
                });
                timeSinceLastShot = 0.0;
                rl.playSound(sound.laser1);
            }
        }
    }
    //UPGRADES
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
    } else if (rl.isKeyPressed(.key_five) and state.levelProjectileSize != maxLevelProjectileSize) {
        // upgrade projectile size
        const cashNeededForUpgrade = getValueForLevel(&scaleCash, state.levelProjectileSize);
        if (state.cash >= cashNeededForUpgrade) {
            state.cash -= cashNeededForUpgrade;
            state.levelProjectileSize += 1;
            player.projectileSize = getValueForLevel(&scaleProjectileSize, state.levelProjectileSize);
        }
    } else if (rl.isKeyPressed(.key_six) and state.levelCooldown != maxLevelCooldown) {
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
        // check if enemy is currently waiting
        if (e.waitFor > 0) {
            e.waitFor -= dt;
            if (e.waitFor < 0) {
                e.waitFor = 0;
            }
            i += 1;
            continue;
        }
        // calculate movement
        var potentialPos: rl.Vector2 = rlm.vector2Add(e.pos, rlm.vector2Scale(e.vel, dt * 10));
        var doesCollide: bool = false;
        for (visibleEnemies.items) |*ve| {
            if (ve.pos.x != e.pos.x and ve.pos.y != e.pos.y) {
                if (rlm.vector2Distance(potentialPos, ve.pos) < (ve.size + e.size + 1)) {
                    doesCollide = true;
                    // addition: wait for each blocking enemy
                    e.waitFor += ENEMY_WAIT_DELAY;
                    break;
                }
            }
        }
        // prevent deadlocks -> force movement if waited too long
        if (e.waitFor >= ENEMY_WAIT_DELAY * 3) {
            doesCollide = false;
        }

        if (doesCollide) {
            i += 1;
            continue;
        }

        //move
        e.pos = potentialPos;

        var enemyDied: bool = false;
        //enemy hit player
        const offset: f32 = 15;
        if (rlm.vector2Distance(e.pos, player.pos) < player.turretSize + offset) {
            try generateExplosion(
                e.pos,
                25,
                ENEMY_HIT_PARTICLE_TTL,
                e.col,
            );
            rl.playSound(sound.explosion2);
            player.health -= e.damage;
            _ = visibleEnemies.swapRemove(i);
            enemyDied = true;
        } else {
            // enemy hit by projectile
            var ip: usize = 0;
            while (ip < projectiles.items.len) {
                var p = &projectiles.items[ip];
                if (rlm.vector2Distance(e.pos, p.pos) < e.size + p.size) {
                    e.health -= player.damage;

                    if (e.health <= 0) {
                        try generateExplosion(
                            e.pos,
                            @as(usize, @intCast((200 + @as(i32, @intFromFloat(e.size))))),
                            ENEMY_DEATH_PARTICLE_TTL,
                            e.col,
                        );
                        rl.playSound(sound.explosion1);
                        state.cash += getValueForLevel(&enemyReward, e.level);
                        _ = visibleEnemies.swapRemove(i);
                        enemyDied = true;
                    } else {
                        try generateExplosion(
                            p.pos,
                            @as(usize, @intCast((10 + @as(i32, @intFromFloat(e.size))))),
                            ENEMY_HIT_PARTICLE_TTL,
                            e.col,
                        );
                        rl.playSound(sound.hit);
                    }

                    _ = projectiles.swapRemove(ip);
                }
                ip += 1;
            }
        }

        if (enemyDied) {
            if (hiddenEnemies.items.len == 0 and visibleEnemies.items.len == 0) {
                levelDone = true;
                levelDoneTimer = LEVEL_DONE_DELAY;
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

    // PARTICLES
    i = 0;
    while (i < particles.items.len) {
        var p = &particles.items[i];
        p.pos = rlm.vector2Add(p.pos, rlm.vector2Scale(p.vel, dt * 10));
        p.ttl -= dt;
        if (p.ttl <= 0) {
            _ = particles.swapRemove(i);
        }

        i += 1;
    }

    // DIE
    if (player.health <= 0) {
        try die();
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
    // SCOPE
    if (scope) {
        const radians = (player.rot + 90) * (math.pi / 180.0);
        const endPos = rlm.vector2Add(player.pos, rl.Vector2.init(math.cos(radians) * 700, math.sin(radians) * 700));
        rl.drawLineV(player.pos, endPos, highlightColor);
    }

    // PARTICLES
    for (particles.items) |*p| {
        rl.drawCircleV(p.pos, p.size, p.col);
    }

    // PROJECTILES
    for (projectiles.items) |*p| {
        rl.drawCircleV(p.pos, p.size, fgColor);
    }

    // ENEMIES
    for (visibleEnemies.items) |*e| {
        rl.drawPoly(
            e.pos,
            @as(i32, @intFromFloat(getValueForLevel(&enemySides, e.level))),
            e.size,
            e.rot,
            e.col,
        );
    }

    if (!levelFailed) {
        try drawPlayer();
    }

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
    try drawStat(4, "Projectile size", player.projectileSize, state.levelProjectileSize, maxLevelProjectileSize, &scaleProjectileSize, KEY_UPGRADE_PRO_SIZE);
    try drawStat(5, "Gun cooldown", player.cooldown, state.levelCooldown, maxLevelCooldown, &scaleCooldown, KEY_UPGRADE_COOLDOWN);

    // LEVEL DONE
    if (levelDoneTimer > 0) {
        if (levelFailed) {
            const levelFailedString: [:0]const u8 = "LEVEL FAILED!";
            const levelFailedStringWidth = rl.measureText(levelFailedString, LEVEL_COMPLETED_FONT_SIZE);
            rl.drawText(
                levelFailedString,
                @divFloor(SCREEN_WIDTH, 2) - @divFloor(levelFailedStringWidth, 2),
                SCREEN_HEIGHT / 2 - LEVEL_COMPLETED_FONT_SIZE,
                LEVEL_COMPLETED_FONT_SIZE,
                highlightColor,
            );
        } else {
            const levelDoneString: [:0]const u8 = "LEVEL COMPLETED";
            const levelDoneStringWidth = rl.measureText(levelDoneString, LEVEL_COMPLETED_FONT_SIZE);
            rl.drawText(
                levelDoneString,
                @divFloor(SCREEN_WIDTH, 2) - @divFloor(levelDoneStringWidth, 2),
                SCREEN_HEIGHT / 2 - LEVEL_COMPLETED_FONT_SIZE,
                LEVEL_COMPLETED_FONT_SIZE,
                highlightColor,
            );
        }
    }

    // FPS
    //rl.drawFPS(5, SCREEN_HEIGHT - 25);
}

fn initState() !void {
    state = .{
        .time = 0,
        .cash = 0,
        .wave = 0,
        .waveTime = 0,
        .levelHealth = 1,
        .levelDamage = 1,
        .levelRotationalSpeed = 1,
        .levelProjectileSpeed = 1,
        .levelProjectileSize = 1,
        .levelCooldown = 1,
    };
}

fn initPlayer() !void {
    player = .{
        .pos = .{ .x = SCREEN_WIDTH / 2, .y = SCREEN_HEIGHT / 2 },
        .health = getValueForLevel(&scaleHealth, 1),
        .turretSize = 10,
        .gunSize = .{ .x = 10, .y = 20 },
        .rot = 0.0,
        .rotationalSpeed = getValueForLevel(&scaleRotationalSpeed, 1),
        .damage = getValueForLevel(&scaleDamage, 1),
        .projectileSpeed = getValueForLevel(&scaleProjectileSpeed, 1),
        .projectileSize = getValueForLevel(&scaleProjectileSize, 1),
        .cooldown = getValueForLevel(&scaleCooldown, 1),
    };
}

fn die() !void {
    rl.playSound(sound.death);
    try generateExplosion(
        player.pos,
        1000,
        PLAYER_DEATH_PARTICLE_TTL,
        fgColor,
    );

    try projectiles.resize(0);
    try hiddenEnemies.resize(0);
    try visibleEnemies.resize(0);

    try initState();
    try initPlayer();

    levelFailed = true;
    levelDone = true;
    levelDoneTimer = LEVEL_DONE_DELAY;
}

//////////////////////////////////////////////////////////////
/// MAIN
//////////////////////////////////////////////////////////////
pub fn main() anyerror!void {
    // INITIALIZATIONS
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "turret defense!");
    rl.setTargetFPS(60);

    rl.initAudioDevice();

    try initState();
    try initPlayer();

    // INIT CONTAINERS
    projectiles = std.ArrayList(Projectile).init(allocator);
    particles = std.ArrayList(Particle).init(allocator);
    hiddenEnemies = std.ArrayList(Enemy).init(allocator);
    visibleEnemies = std.ArrayList(Enemy).init(allocator);
    defer projectiles.deinit();
    defer particles.deinit();
    defer hiddenEnemies.deinit();
    defer visibleEnemies.deinit();

    // INIT SOUNDS
    sound = .{
        .laser1 = rl.loadSound("res/laser1.mp3"),
        .explosion1 = rl.loadSound("res/explosion1.mp3"),
        .explosion2 = rl.loadSound("res/explosion2.mp3"),
        .hit = rl.loadSound("res/hit.mp3"),
        .death = rl.loadSound("res/death.mp3"),
    };

    // GAME LOOP
    try initLevelLogic();
    while (!rl.windowShouldClose()) {
        try update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        try render();
    }

    rl.closeAudioDevice();
    rl.closeWindow();
}
