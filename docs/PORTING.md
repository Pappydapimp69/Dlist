# Porting the demo into Upstarts

The demo (`demos/skin-test/index.html`, one file) is where movement, sound and controls get tuned first.
Upstarts ports from it. This is the map: where each system lives in the demo, what it needs, the numbers that
were measured, and the traps already hit. `docs/NEXT-ROUND.md` has the full history with every test result.

Search the demo by the section banners (`/* ===== name ===== */`) and function names below; line numbers drift.

## Ground the movement stands on

- **`groundInfo(x, z)`**: terrain plus rocks and logs as real footing. Rocks keep their upward triangle facets for
  exact foot height; logs are analytic cylinders, and a foot landing off the crown rolls. It returns height, rock
  id, edge (0 at the centre, 1 at the rim) and the surface normal's y.
- **Rock tiers, as fractions of hip height**: pebble below 0.08, step-up below 0.55, above that a jump-up or a
  wall (`TIER`). Tier 2 rocks and logs become collision obstacles.
- **Body-part collision**: hips, chest, head and tail each have an underside height (0, 0.6, 0.8 and 0.6 × hip).
  A part higher than a rock passes over it, so the dino can walk up to a ledge with its chest over it. Deep
  overlaps are eased out at 0.12 m per step, never snapped.
- **Flat-topped blocks** (`mesaGeo`): the rock mesh with its top cut flat, for ledges you can stand on.

## Gait and body (sim side of `simStep`, `// ---- gait ----`)

- **Duty factor from the Froude number, stride from Alexander's relation** (Brain: dlist E2, E3).
- **Footholds on rough ground**: each lifting foot scores candidate landing spots (rock edge, tilt, toe-heel
  mismatch, how far it shifts) and takes the best one. The legs run slightly ahead of or behind each other on high
  steps.
- **Heading-predicted foot placement** (E6): a foot lands where the body will be when it touches down.
- **Lean from the feet** (E4), **active tail** held on the inside of turns, critically damped at about 3 Hz.
- **Speed is measured**, not taken from the input (`D.vMeas`); stumbles use the measured speed.
- **Hills**: the slowdown scales with grade (work against gravity); gentle downhill helps a little.

## Stability: slip, stumble, trip (`// ---- stumbles and trips ----`, `stability()`, `startFall()`)

- Three physical failure modes per risky footfall:
  - **Trip:** the swept toe strikes a rock face.
  - **Slip:** the friction demand (leg angle plus surface tilt) beats μ.
  - **Roll:** fewer than 3 of 5 foot points are supported.
- Recovery capacity scales with stamina.
- **Outcomes:** slip (score 0.55 to 0.9), stumble (above 0.9), trip (it goes down).
  - A trip only happens while sprinting below half stamina, and stays rare
    (`downAt = lerp(2.1, 3.5, smooth(0.1, 0.5, stamina))`).
  - Measured, 117 fresh full-sprint runs over every rock: 14 slips, 25 stumbles, 0 trips.
  - Tired sprinting gave 5 to 8 trips against 0 at a walk.
- **A trip falls on its side:** topple, lie there kicking, roll back and get up.
  - Timing scales with body size: `BODY.ts = sqrt(hip / 1.15) × (mass / 350)^0.1`.
  - Heavier bodies hit harder and lie longer: `BODY.mk = cbrt(mass / 350)`.

## Jumps and ledges (`// ---- jumping ----`)

- **Takeoff:** a crouch first (0.22 to 0.3 s), then the takeoff.
  - A running leap clears about 1 m × `JUMP_K`.
  - It falls 1.4× faster than it rises, so the landing feels heavy.
- **Ledge aim:** with a ledge ahead and within reach, the jump picks just enough height and forward push to land
  on top, so a standing jump onto a waist-high block works.
- **Scramble:** if the feet come up to 0.3 × hip short of the top, they catch the edge and the dino scrambles up.
  That costs speed and some stamina.
- **Stepping off:** pushing the stick over a drop larger than a step makes it fall off. With the stick let go, it
  stops at the edge. A foot never steps down a ledge by itself.
- **Body height on tall rocks:** rides on the feet (the `lift` term). The old ground-relative clamp left the body
  sunk into tall rocks.

## Sound (`/* ===== sound: sim events, AI hearing, procedural engine ===== */`)

- **Engine:** `pappydapimp69/sound-engine` `src/`, vendored at `demos/skin-test/vendor/sound-engine/`.
- **The sim emits sound events** (`emit()`): kind, who, position, and level in dB at 1 m. The audio layer
  (`createAudioLayer`) plays them; AI hearing reads the same events.
  - Audio has its own seeded RNG (`audioRng`), the sim has `simRng`.
  - Replay check passed: identical sim fingerprint with no audio, live audio, 4 voices and muted
    (Brain: sound-engine/E7).
- **Upstarts' herbivores and Saurosuchus hear a "noise radius"** (`noiseOf` in `world.ts`). Moving them to events
  is the point of E7: hearing from events stays exact whatever the audio does.
- **Coordinates trap (Brain lesson):** Three.js seen from above is a mirror of the engine's plane.
  - With world x to engine x and world z to engine y, every pan comes out reversed, and no listener yaw can fix it.
  - The demo swaps the left and right output channels once after the engine's limiter.
  - Mapping z to -y is the equivalent fix.
  - Test it with a source at screen right. After the fix, right was +4.1 dB on the right.
- **Start audio inside the user gesture.** Make the AudioContext and resume it synchronously in the first
  tap, click or button press, then pass it as `context` to `SoundEngine.create`. Safari and iOS need this.
- **Event levels:** `STEP_DB` = 62 dB for an adult walking at 3.4 m/s, +10 per tenfold mass, +4.5 per doubling
  of impact speed. On top of that come stealth-style noise ratings:
  - sprint footfalls +10 dB
  - jump landings +14 dB
  - A physical step can't separate a small animal's walk from its sprint (they're 7 dB apart).
  - With a 30 dB wake threshold, a walk never wakes the sleeper, a sprint does within about 3.5 m, and a roar
    always does.
- **What each sound is made of** (all synthesized, no tones):
  - **Footsteps:** from the surface under the foot (dirt, sandstone, wood, mud, water).
  - **Skid on a slip, stumble or trip:** stick-slip, about 55 tiny contacts a second, fading.
  - **Fall:** a heavy impact, then a growl.
  - **Bite:** a damped teeth click, 7 modes, ring about 10 ms.
  - **Drinking:**
    - scoop: a bubble burst
    - jaw drips: rising-pitch bubbles
    - swallow: low bubbles, muffled by occlusion
  - **Tearing meat:** wet suction with crackle.
  - **Sniff:** unvoiced breath through a 6 cm tube.
- **Calls (`CALLS`):**
  - Pitch is a fraction of the tract's highest clean open-mouth pitch (0.3 F1), so one table scales from adult to
    hatchling.
  - Y plays by condition: winded (stamina under 0.3), then parched, then hungry, otherwise the full roar.
  - The wheel offers roar, bellow, growl, boom, hiss and chuff.
  - The rival answers challenge calls only.
  - The roar is mixed about 10 dB over a footstep.

## Fights (`// ---- fights: hit points and damage ----`, `onBiteSnap()`, bite animation in `// ---- actions ----`)

- Damage share per bite is `0.2 r^1.5 x quality`, capped at 1, with `r = (Ma / Mt)^(2/3) x bite / hide`.
  Measured: hatchling against Exaeretodon 3 bites, juvenile 1, a sleeping ambush 1.
- The strike: wind-up, lunge (root motion, about 0.5 m), a 70 ms hit-stop on contact (the bite animation only,
  never the whole sim), and a head shake on a hit.
- Prey on a hit: knockback, flinch, slower and tiring sooner when wounded, a blood trail, and a 45% chance to bite
  back below 60% hit points.
- Player hit: flinch away, a yelp, a speed loss and a limp below 30% health.

## Controls (`/* ===== input ===== */`, touch block, `/* ===== call wheel ===== */`)

- **Xbox pad:**
  - A jump, hold B drink or sniff, X bite, Y roar, RT sprint, LT rest, Start menu.
  - Click the right stick for the call wheel: tilt to a call, click again or press A to call it, B to close.
  - Click the left stick to put the camera behind.
- **Touch:**
  - A floating stick on the left; past the dashed ring it sprints.
  - Drag on the right to look.
  - A, B, X, Y buttons, plus rest, camera and menu.
  - Hold Y for the wheel.
  - Tapping the screen switches into touch mode.
- **Keyboard:** WASD, Shift sprint, Space jump, G drink, F bite, R roar (hold R or press 1 to 6 for calls), Z rest.
- **Buttons held across the menu are swallowed** until released, so a held trigger or stick doesn't freeze the
  controls.

## How the demo is tested

Headless Chromium with Playwright, driving the sim through `window.__demo`:
- `step(n)`, `teleport()`, `override` input.
- `fall('slip' | 'stumble' | 'trip')` forces a fall.
- `resetSimForReplay()` starts a replay from the same seed and clock.

Offline renders replay recorded sim events through `loadEngine(new OfflineAudioContext(...))`, so sounds can be
measured: level, spectral centroid and flatness, left/right balance.
