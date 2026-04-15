# Fish Out of Water — Game Design Spec

## Premise

Top-down 2D dodge/survive game built in Godot 4.6.2 (GDScript). You are a goldfish that flopped out of its bowl onto the living room floor. Survive 60 seconds dodging hazards until the kid comes home from school and rescues you.

## Controls

- WASD or arrow keys for 8-directional movement
- Tight, responsive feel (no momentum/sliding)
- Movement speed: ~300 px/s (tunable constant)

## Player (Goldfish)

- 3 hit points
- Visual: orange ellipse with a tail (Polygon2D)
- On hit: brief invincibility (1.5s), flash effect, screen shake
- Visual degradation: at 3 HP fish is shiny, at 2 HP slightly pale, at 1 HP visibly distressed
- Collision shape: small circle (forgiving hitbox)

## Hazards

All hazards spawn from off-screen edges and move across the play area.

| Hazard | Appears at | Behavior | Size | Speed |
|--------|-----------|----------|------|-------|
| Cat | 0s | Walks across floor, occasionally changes direction. Swats (lunges) if within ~120px of player | Large | 150 px/s, lunge 400 px/s |
| Shoe | 15s | Launched from random edge, travels in a straight line, despawns off-screen | Medium | 350 px/s |
| Furniture (chair) | 30s | Slides from one edge to the opposite, large hitbox, slow | Very large | 80 px/s |
| Roomba | 45s | Spawns once, slowly tracks toward the goldfish, never despawns | Medium | 100 px/s |

Spawn rates increase over time (details tuned during implementation).

## Win/Lose Conditions

- **Win:** Timer reaches 0. Display win screen with "YOU SURVIVED!" and a hand-scooping animation (simple tween).
- **Lose:** HP reaches 0. Display lose screen: "You became a cat snack." Restart button.

## UI / HUD

- Top-left: HP indicator (3 fish icons or hearts)
- Top-center: Countdown timer (large text)
- Timer flavor text at milestones:
  - 45s remaining: "HANG IN THERE!"
  - 15s remaining: "ALMOST!"
  - 5s remaining: "THE BUS IS HERE!"
- Win screen: centered text + restart button
- Lose screen: centered text + restart button

## Visual Style

- No external assets. All visuals built from Godot primitives (Polygon2D, ColorRect, circles).
- Living room floor: tan/brown background with subtle grid lines suggesting tile or wood.
- Hazards are color-coded shapes:
  - Cat: dark gray rounded shape with triangle ears
  - Shoe: brown rectangle
  - Furniture: large dark rectangle
  - Roomba: dark circle with a small green dot

## Audio

- No audio files required. If time permits, placeholder beeps via AudioStreamGenerator or skip audio entirely.

## Screen

- Viewport: 1280x720, stretch mode `canvas_items`
- Single scene architecture: one main scene containing player, spawner logic, HUD, and game state

## Architecture

```
project.godot
scenes/
  main.tscn          — root scene (floor background + spawners + HUD)
scripts/
  main.gd            — game state, timer, spawner logic
  player.gd           — goldfish movement, HP, invincibility
  hazards/
    cat.gd            — cat behavior (wander + lunge)
    shoe.gd           — straight-line projectile
    furniture.gd      — slow slide across screen
    roomba.gd         — tracking toward player
  hud.gd              — timer display, HP, flavor text, win/lose screens
```

## Scope Boundaries

- Single level only (one 60-second round)
- No sound effects (visual feedback only)
- No menus beyond win/lose restart
- No save/load, no settings
- No score system beyond win/lose
