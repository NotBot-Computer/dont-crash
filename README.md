# Don't Crash

A local split-screen party game about not crashing your car. Styled after retro top-down pixel art.

Built in **Godot 4**. It started life as one of the two modes of *Traffic Tower*; the other mode, the tower stacker **Pile Up**, now lives in its own repository (github.com/NotBot-Computer/pile-up, formerly `trafucker`).

## How it plays

**Don't Crash** — split-screen. Steer between lanes, avoid traffic, survive as long as possible. Speed ramps up over time. Three lives each: a crash costs one and knocks you down to a crawl, and you're only out once all three are gone. Whoever covers the most distance wins the round.

## Playing it

Launch the game and you'll get: the title screen → pick how many players → each player cycles and locks in a color → off you go.

That colour is your car and the three hearts trailing behind it, and each board always has 5 lanes, regardless of player count.

### Playing alone, or against the computer

Pick **1 PLAYER vs BOT** on the player-count screen and you'll race a computer-driven opponent.

More generally, **the 1-4 keys hand player 1-4's board to the AI, or take it back** — on the car-color screen or at any moment during a race. **5** cycles the AI between EASY, NORMAL and HARD. A board the AI is driving is labelled `BOT` under its boost bar. Hand over every board and the game plays itself, which is a handy way to watch a mode without playing it.

The AI drives the same car with the same physics you do — it steers, dashes, drifts, spends boost and picks up skills through exactly the same controls, it just doesn't need a keyboard. Difficulty is how far ahead it plans and how quickly it reacts, not what it's allowed to see.

## Controls

| Player | Left | Right | Boost / lock in | Skill: opponent / self |
| ------ | ---- | ----- | --------------- | ---------------------- |
| P1     | A    | D     | W               | Q / E                  |
| P2     | ←    | →     | ↑               | , / .                  |
| P3     | F    | H     | T               | R / Y                  |
| P4     | J    | L     | I               | U / O                  |

Double-tap left or right (quickly, twice back-to-back) to **dash** exactly one lane over — a fast eased snap with a fading afterimage trail, on a short per-player cooldown.

While already carrying real speed one way, press the opposite direction to start **drifting** — no separate gesture needed, just a genuine sudden reversal. The car's nose points wherever you're steering, but its actual momentum lags behind at reduced grip (not increased speed), so it visibly slides, leaving a twin skid-mark trail from the rear wheels. Keeps drifting as long as you keep steering in either direction; lets go of grip the instant you release both keys.

You have **three lives**, shown as three hearts in your own car's colour trailing along the road behind you. Hitting traffic wrecks the car you hit, costs a heart, and drops you to a crawl — you then blink for a couple of seconds, during which traffic passes straight through you while you get your speed back. Lose all three and you're out, and the round ends once nobody is left driving.

Every so often a glowing pickup appears in a lane. Drive over it and two icons come up either side of your car — the round never pauses for this. The **left** one (your "opponent" key) sends something nasty to every *other* player; the **right** one (your "self" key) helps you. Which skill each side is offering is rolled when the icons appear and shown on them, so what you see is what you get. There are nine:

| | Skill | What it does |
|---|---|---|
| self | **Tank Mode** | 6s as an invincible tank that crushes traffic; your boost key fires the cannon |
| self | **Nitro** | lifts off and rockets up the road at 2.85x, flying *over* the traffic |
| self | **Make Way** | 5s of siren — your car becomes a police cruiser and traffic ahead signals and pulls out of your lane |
| self | **Pit Stop** | instantly gives back a lost life; if you have all three, fills your boost bar instead |
| self | **Compact** | your car shrinks to two-thirds width for 7s, so tight gaps become gaps |
| opponent | **Taxi** | a reckless cab barges onto everyone else's board and runs riot for 11s |
| opponent | **Detour** | lines of roadworks barriers scroll down everyone else's road with one gap to find |
| opponent | **Oil Slick** | everyone else loses their grip for 5s — the car overshoots, fishtails and arrives late |
| opponent | **Smoke Screen** | a bank of smoke hides the top of everyone else's road for 5s, so traffic emerges late |

The six newer ones each live in their own file under `scripts/skills/`; their icons and Detour's barrier are placeholders drawn in code — `docs/SKILL_ART_BRIEF.md` is the brief for real art, which drops in by filename with no code change.

Press **Enter** to restart after a round ends. Press **Esc** during a round to return to the main menu. **1-4** toggle the AI for each player and **5** changes its difficulty (see above).

## Running it

Open the project folder in the Godot 4 editor (`godot --path .` from this directory, or `Import` from the project manager), then press **F5** / the Play button.

## Menu art

The menus — the title screen, the player count and the colour pick — are pixel art built from tetromino-style bricks (the pieces of Pile Up, the game this one was split from). The title screen and the player count are rows of big cards, picked with the **left/right arrow keys**, chosen with **Enter** and left with **Esc** (the mouse does nothing there). Each card is just a preview and a name; the selected one plays its preview and the rest hold still, dimmed: cars driving up the road on the title screen, and on the player count that many split-screen roads with a car each. The title is spelled in bricks: each letter is one brick-shaped piece, outlined and bevelled the way the bricks are, in the seven classic bricks' colours, and the letters drop in when the screen opens. Behind every menu the bricks rain down and pile up along the bottom; a full pile sinks away and a new one starts. Buttons and panels are chunky framed boxes with notched corners, and the keyboard's current button is lit in the O brick's yellow. Nothing here is new art: shapes come from `GameSettings.BRICKS` and colours are read off the brick sprites in `sprites/blocks/` (`scripts/PixelUI.gd`).

The font is **Press Start 2P** by CodeMan38 (`fonts/PressStart2P-Regular.ttf`), under the **SIL Open Font License 1.1** — the licence is committed beside it as `fonts/PressStart2P-OFL.txt`. It is imported with antialiasing, hinting and subpixel positioning off, and sized in multiples of 8 so its pixels stay square. Only the menus use it; the in-round HUDs still use Godot's default font.

## Car art

Cars are real sprites (`sprites/cars/*.png`) — top-down orthographic pixel art across 14 vehicle kinds: sedans (12 colors: 6 selectable player skins + 6 traffic-only), SUVs, pickups, vans, sports cars, semi trucks, pickups towing trailers, transit buses, coaches, ambulances, fire trucks, garbage trucks, box trucks, and motorcycles. All of it was cropped and cleaned up from hand-drawn vehicle reference sheets, except the motorcycles, which stayed on the original top-down art — the newer motorcycle sheet is drawn as a front elevation, which reads as riding toward you in a top-down game. `GameSettings.TRAFFIC_KINDS` holds each kind's textures, size ratios, and spawn weight — the weights total 100, so each reads directly as a percentage of traffic: sedans 26%, SUVs 15%, pickups 11%, vans 10%, sports cars 8%, semi trucks 7%, motorcycles 5%, trailers 4%, transit buses 3%, box trucks 3%, coaches 2%, ambulances 2%, fire trucks 2%, garbage trucks 2%. `PlayerBoard.gd` picks a weighted-random kind and texture for every spawned traffic `Car`.

The long kinds are the ones that change how a lane plays: at a 5-lane board's scale a **semi truck** is 130px of road, a **towed trailer** 124px, and the four **service vehicles** 110-120px, against a sedan's 56px — and all of them drive slowly enough that you close on them fast. The **garbage truck** is the slowest-driving thing in the table, one notch past the trailer. **Sports cars** sit at the other end — they nearly keep pace with you, so they hang alongside instead of rushing past. The **fire truck** is the widest vehicle in the game at 37px of a 53px lane, which is what its own reference art draws it as.

Every `Car` (`scenes/Car.tscn`) has an empty `Sprite2D` child, so you can swap in your own art any time: open it in the editor and drag a PNG onto the Sprite2D's **Texture** property in the Inspector, or call `set_texture()` from code (see `PlayerBoard.gd` for examples). The placeholder shape (a colored `Polygon2D`) automatically hides once a texture is assigned. `Car.gd` scales whatever texture is provided to the car's collision size.

## Road art

The road and median are real textures too (`sprites/road/*.png`), both cropped from the same hand-drawn source image so their grass/guardrail style matches exactly. `Road.gd` and `LaneDivider.gd` scroll them by drawing repeated tiles offset by accumulated distance, instead of procedurally drawing lanes/grass. `Road.SHOULDER_RATIO` is tuned to the texture's actual asphalt width so cars only ever drive on the gray part.

Traffic also moves at slightly different speeds per vehicle (`PlayerBoard._spawn_obstacle` assigns each one a random `speed_mult`) so gaps open and close between cars instead of the whole field scrolling in perfect lockstep.

## Project structure

```
project.godot
sprites/
  cars/               top-down vehicle PNGs (sedans, SUVs, pickups, vans, sports cars, semi trucks, trailers, buses, coaches, motorcycles)
  road/               road + median tile textures, cropped from one source image
  blocks/             the menu bricks (from Pile Up) — drawn by PixelUI, BrickRain and BrickTitle
  ui/                 countdown glyphs, and the life heart
  skills/             PLACEHOLDER choice-icon glyphs + Detour's barrier, generated by scripts/dev/make_placeholder_skill_icons.py
fonts/                Press Start 2P (the menus' pixel font) and its SIL OFL 1.1 licence
scenes/
  MainMenu.tscn       title screen
  PlayerSelect.tscn    choose how many players
  SkinSelect.tscn      each player picks + locks in a car sprite
  Main.tscn            N PlayerBoards side by side, round state, restart UI
  PlayerBoard.tscn     one player's road + car + obstacle spawner
  Car.tscn             sprite/placeholder + collision, reused for player and traffic
  LaneDivider.tscn     grass + trees median between adjacent player boards
scripts/
  GameSettings.gd      autoload: player count, chosen skins, sprite tables, key bindings
  MainMenu.gd
  PlayerSelect.gd
  PixelUI.gd           the menus' pixel look: font, framed buttons and panels, bricks redrawn as pixel art
  BrickRain.gd         bricks raining and piling up behind a menu
  BrickTitle.gd        a title spelled in brick-shaped letters that drop in
  ModeCard.gd          one menu card with its live preview
  CardRow.gd           a row of cards picked with the arrow keys, Enter and Esc
  SkinSelect.gd        dynamic per-player sprite-pick panels, duplicate-skin avoidance
  Main.gd              instantiates PlayerBoards + dividers for the chosen player count
  PlayerBoard.gd        steering physics, spawning, scoring, collision handling
  BotDriver.gd          the AI: reads the traffic, plans a lane, drives PlayerBoard's own controls
  Road.gd               lane math and scrolling road-texture rendering
  Car.gd                 swaps between placeholder shape and an assigned texture
  HeartPips.gd          the life pip, and its per-player recolour
  LaneDivider.gd         scrolling grass/tree median renderer
  skills/               the modular skills — one file each, plus the base class, the catalog and the overlay node
  dev/                  headless measurement harnesses, not part of the game
```

## Roadmap

- More skills, and real art for the placeholder icons (`docs/SKILL_ART_BRIEF.md`)
- Gamepad support
- Export to web (HTML5) and/or desktop builds
