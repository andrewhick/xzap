Xzap readme

This is an attempt to create components of Xzap, by Mark Wirt, to teach myself Godot.

C16 screen ratio is (40 x 25 blocks of 8x8 pixels, or 320 x 200 pixels)
with approx 4 blocks (32) left and right, and 6 blocks (48) top/bottom for border.
So: total is 384 x 296

With mini C16 border (just 8 pixels), the total size is 336 x 216.

Ship takes just under 10 seconds to go 114 tiles, so stick with 10/second for now.

Xzap game screen is (38, 23) with margins (top 2, bottom 0, left 1, right 1)

Things to create

Player
Shoot
Hearts
Blocks
Mines
UI
Font

Project
	Settings:
		scene resolution
		stretch mode = viewport
		stretch aspect = keep
		rendering quality - enable 2d pixel snap
Grid - use TileMap, not GridContainer (not sure why yet)
	Controls all movement
Ship
	up and right animations

TO DO NEXT:

Show number of enemies in UI
	Score container: within container: (48,0) -> (272, 8)
		Setting position and min size works best.
		Also set separation = 0
		Red bit: 0 -> 64
		Arrow: (64, 0) -> (72, 8)
		Mini-score: 72 -> 96
		Lives: 120 -> 144
		Blue Hi-Score: 160 -> 224
Win condition
Loss condition
Mine countdown - trigger signal on 0
Mine forcefield
More levels
3 lives - UI
Score
Other enemies
Refine kill animation - pause game until they disappear

Enemy data for each level:

Level
	enemy, x, y
	enemy, x, y

Try creating multiple hearts in random locations and directions
Investigate whether to use set_cellv or grid[][]=
Tie up enemy logic
Tidy up whether things (enemies, explosion, bullet, ship) use grid or world coordinates, and keep it consistent.

Level001:
Blocks: #868FF0
Score:  #7E453D
HiScore:#394bb5


Troubleshooting:

If sprites appear blurry, reimport without filter option: https://godotengine.org/qa/38477/sprites-animatedsprite-although-showing-correctly-editor 

set_pos and get_pos do not exist in Godot 3.1. Read and write to `position` instead.