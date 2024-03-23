# zig-turret

... is a 2D turret defense game I made in order to learn ``zig``. For the graphics and audio I used raylib.
The goal is to shoot all enemies that come flying towards you. Once they manage to come close,
they will explode and inflict damage. You must try to survive as long as possible by killing them first.
Each kill will reward you with cash which you can use to become stronger by upgrading your skills.

<img width="500" alt="gameplay" src="https://github.com/xLPMG/zig-turret/assets/17238289/c1cb81db-d37a-4e41-9f01-7b77a08d6877">

# Controls

| Key(s) | Function |
| ------ | ------------- |
| ``A``  | rotates your turret counter-clockwise  |
| ``D``  | rotates your turret clockwise  |
| ``SPACE`` | shoots projectiles. You may keep it pressed for continuous shooting |
| ``1`` to ``5`` | can be used to upgrade skills. The GUI will show you which key corresponds to which stat |
| ``H``  | toggle scope: a red line will appear that predicts the path of your bullet. Use it if you need to practice hitting enemies |
| ``J``  | toggles color mode |
| ``K``  | toggles auto-fire |

## Demo

https://github.com/xLPMG/zig-turret/assets/17238289/4bafb6d2-18b7-4640-b2e4-f9c16c931da2

Make sure to check out the sound effects as well!


## Stats

![stats](https://github.com/xLPMG/zig-turret/assets/17238289/6c7c17b1-53c2-400f-905c-0338055f3394)

You may have noticed the stats system. Each time you kill an enemy, you will receive cash. 
If you have enough for an upgrade, the GUI will provide you with the option to upgrade a specific stat 
of your turret by pressing the respective key.

## Deployment

If you wish to build the binaries yourself, install zig and then run the build script using ``zig build run`` from within the top folder.
