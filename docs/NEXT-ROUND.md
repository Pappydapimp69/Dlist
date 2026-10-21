# Next round: skin test demo changes

Changes queued from playtest feedback.

**Status (2026-10-21): items 1 to 7 are built** in `demos/skin-test/index.html`. Each item
below ends with a **Built** note: what went in, the defaults chosen, and the measured check.
Nothing from this list is left open.

1. **Tail: stiffer, more lag on turns.**
   - Bend mostly near the hips and keep the back half straighter. Herrerasaurus's
     rear tail vertebrae had long interlocking processes that likely stiffened it,
     so it should act more like a rudder than a whip.
   - The demo currently bends the tip the most (tail bone weights rise toward the
     tip). Reverse that falloff.
   - DECIDED: the tail is actively used for balance and sits on the INSIDE of the
     turn (Brain lesson dlist/E7, tension resolved). In the sandbox, inside beat
     straight, outside and flick strategies on body roll at every speed (11% lower
     than straight at a sprint, 40% at a walk). Outside and flick cost 2–4x more leg
     torque. It must swing in with the body's yaw, not snap: a plain snap failed the
     sprint slalom test.
   - Controller:
     ```
     aC   = D.speed * Math.abs(D.yawRate)
     hold = Math.asin(Math.min(Math.sin(0.5), 0.49 * aC))   // rad toward the inside, cap ~29°
     // on turn start or when the turn direction flips: D.tailTurnYaw = D.yaw
     th   = turning ? Math.min(hold, Math.abs(wrapAngle(D.yaw - D.tailTurnYaw))) : hold
     cmd  = -Math.sign(D.yawRate) * th
     w = 2*Math.PI*3                                         // critically damped, 3 Hz
     D.tailYawV += (w*w*(cmd - D.tailYaw) - 2*w*D.tailYawV) * dt
     D.tailYaw  += D.tailYawV * dt
     ```
   - Spread `D.tailYaw` mostly at the base: ~0.65 across tail0+tail1, 0.15 tail2,
     0.10 tail3, 0.10 the rest.
   - Pair with body lean and foot placement (dlist/E4). The tail alone doesn't
     carry the roll load.
   - Stiffer rear joints (5x) shift bending to the base: the two base joints go from
     27% to 44% of the total bend. Tune damping on the whole tail, not per joint
     (per-joint critical damping still overshot 24%).
   - **Built.** The controller above, verbatim, as one critically damped 3 Hz filter on the
     whole tail. "Turning" means |yawRate| > 0.05 rad/s. Bend weights 0.33, 0.32, 0.15, 0.10,
     then 0.034, 0.033, 0.033 (base share measured 0.65). Gait wag and the rock counterbalance
     use the same weights. Checked: in a left turn the tip sits 0.8 to 1.1 m to the left (inside),
     in a right turn 0.9 to 1.1 m to the right.

2. **Walk-to-sprint posture change, made clearly visible.**
   - At a sprint, level the trunk and lean it forward. Straighten and extend the
     neck, lower the head, and hold the tail straight out, so head, back and tail
     line up roughly horizontally and balance over the hips.
   - Bend the legs a bit more with longer strides at speed.
   - At a walk, keep a relaxed S-curved neck, a higher head and a slight tail droop.
   - The demo only hints at this now (a small pelvis pitch and tail lift). Make it
     much stronger. Tune the numbers from the Brain movement training results.
   - Gait fixes from the Brain movement training (lessons dlist/E2–E6):
     - Walk-to-run switch by Froude number, not by a fraction of top speed:
       `duty = 0.5 + 0.14*tanh((0.5 - v*v/(9.81*1.15))/0.25)`. The switch moves from
       3.98 to 2.38 m/s, and the 3.4 m/s trot becomes a true run.
     - Stride from Alexander's relation: `stride = 2.3*1.18*(v*v/(9.81*1.18))^0.3`
       (sprint stride 4.33 m, cadence 1.71 Hz instead of 2.21 Hz).
     - Lift the heel through stance: rotate the metatarsus toward toe-off instead of
       holding the rest angle. Otherwise the longer stride leaves the leg 14.5 cm short.
     - Lean comes from the feet: shift the planted-foot window back by about
       0.11 m per 1 m/s² of acceleration. Cap acceleration at about 2.1 m/s²
       (2–5 m/s) and 1.2 m/s² near 7 m/s. Trunk pitch, neck and head lowering are
       style only (each moves the center of mass under 2 cm).
     - Foot planting in turns: predict the heading at touchdown, and freeze the speed
       in the centring term at lift-off. Without this the feet skid about 1 m/s in
       turns and 0.43 m/s when accelerating.
   - **Built.** Duty, stride and the 0.11 m/(m/s²) foot-window shift use the formulas above
     (hip 1.15 m, leg 1.18 m). Acceleration cap 2.1 m/s² easing to 1.2 m/s² between 5 and 7 m/s;
     braking 4 m/s² (default, keeps the forward shift within reach). Heel lift follows a schedule
     toward toe-off and is raised further whenever the hip would be out of reach. Swing feet
     predict heading and body position at touchdown; the centring term freezes at lift-off.
     Posture blends on speed 2.4 to 6.6 m/s: walk has the trunk slightly nose-up, an S-curved
     neck (44° at the base) and a drooping tail (-14°). Sprint has the trunk leaned 7° forward,
     the neck nearly straight (10°), the snout 0.8 m lower and the pelvis 0.19 m lower.
     Measured: sprint cadence 1.67 Hz (spec 1.71 at 7.4 m/s), walk 0.95 Hz; planted-foot
     lateral error in a sustained 1.37 rad/s sprint turn averages 0.067 m (max 0.079).

3. **Rocks you can step on, instead of rocks that act as walls.**
   - Size tiers scale with the creature's leg length (hip height), not fixed
     heights. Starting numbers for tuning:
     - Pebble, under ~8% of hip height (~10 cm for an adult Herrerasaurus): no effect.
       The foot just lands on top.
     - Step-up, ~8% to ~42% of hip height (~10–50 cm adult): a foothold.
     - Boulder, above ~42%: solid. Go around it.
     The same rock can be a pebble to an adult, a step-up to a juvenile and a wall
     to a hatchling.
   - Rocks become part of the ground each foot samples. Feet stay independent, so
     one can be up on a rock while the other is on the ground, depending on the
     angle of approach.
   - The swing foot looks ahead and lifts higher to clear the rock. Stepping down
     takes a longer reach.
   - Each step up or down costs speed, scaled by step height relative to leg length.
   - Balance: the body rolls and pitches toward the lower foot, and the head and
     tail shift to counterbalance.
   - **Built.** Rock facets that face up are kept per rock for exact foot height, plus a dome
     summary (centre, footprint radius, top height, top slope) for the tier and stability
     logic. Tiers use 8% and 42% of hip height (9.2 cm, 48.3 cm). Of 48 rocks, 4 are boulders
     (only those are still pushed as obstacles, and not while the feet are above their top),
     1 is a pebble, the rest are step-ups. Defaults: rocks get a small seeded tilt, so tops
     vary in slope, and six low slabs sit between the start point and the middle of the map
     so step-ups are easy to find. The swing foot samples the ground ahead along its path
     (0.25 m + 0.06 s × speed) and lifts over it. Stepping down reaches up to 0.3 m further.
     Speed cost per step: 0.75 × rise / hip height going up, 0.4 × drop going down, capped at
     45%. Roll is 0.9 rad/m of foot height difference (capped 0.22 rad), pitch is from the
     fore-aft foot heights, and the head and tail swing toward the high side.

4. **Stumbles and trips on rocks (lose time only, no damage for now).**
   - Every step on or off a rock runs a stability check combining:
     speed, body weight (momentum, so it scales with growth stage), approach angle
     against the rock edge, slope of the rock top and the ground, how close to the
     edge the foot lands, and grip (wet or muddy feet slip more).
   - Trip: the toe catches the edge mid-swing because the foot didn't clear it in
     time, mostly from speed versus step height.
   - Stumble: the foot lands but slips or rolls, mostly from slope, an edge landing
     or wet or muddy feet.
   - Graded outcome: a small miss is a quick stagger (head and tail flail, speed
     loss). A big miss is a full trip: down for about 1–2 s, then get back up.
   - Learnable, not a dice roll: the same approach gives the same result, with only
     slight seeded variation.
   - **Built.** Trip = (highest rise the toe had to clear / step-up max) × (speed / 4)^1.6 ×
     momentum × (0.75 + 0.5 × glance). Stumble = (0.9 × rock slope + 0.5 × ground slope +
     0.8 × edge + 0.9 × grip loss) × (0.3 + speed / 6) × momentum, plus a landing-impact term
     for jumps. Grip loss comes from the foot bands of `D.wet` and `D.mudCover` (dry crust slips
     less than wet mud). Momentum is (mass / 350 kg)^0.25, so it scales with growth stage.
     Variation is ±0.08 from a stream seeded by rock id and leg (not `Math.random`), so a repeat
     gives the same result. Score under 0.5: nothing. 0.5 to 1: stagger for 0.45 to 0.9 s with
     head, tail and arm flail and 20 to 45% speed loss. Over 1: down for 1 to 2 s, then up.
     Time loss only. Measured on three rocks (12, 26 and 38 cm): walking and running at 3.4 m/s
     never fail dry; sprinting gives a stagger on 12 cm, a fall on 26 cm (edge landing) and on
     38 cm (trip, toe caught). Wet feet turn a walk or run onto the 26 cm rock into a stagger.
     Repeating each approach gives an identical result in all 9 configurations.

5. **Herrerasaurus model accuracy pass.** Herrerasaurus was a ground-dwelling,
   bipedal predator, not a climber. Fixes:
   - **Lips:** cover the teeth when the mouth is closed, and show them only when it
     opens. Recent work suggests theropods had lizard-like lips.
   - **Flexible lower jaw:** Herrerasaurus had a joint partway along the lower jaw.
     Add a small flex there during bites (a mid-jaw bone).
   - **Skull shape:** deeper and boxier toward the back where the jaw muscles sat,
     with a visible opening in front of each eye (antorbital fenestra) and a nostril.
     Less tube-shaped.
   - **Hands:** bigger, more strongly curved claws on fingers I–III, plus two tiny
     vestigial fingers (IV, V).
   - **Feet:** add the small first toe (dewclaw) set higher on the foot, alongside
     the three main weight-bearing toes.
   - **Skin: try fuzz.** No Herrerasaurus skin has been found, so the covering is
     unknown. Try a light coat of simple filaments (shell or strand fuzz) over parts
     of the body, mainly the back, neck and upper tail, while keeping scales on the
     feet, snout and belly. Colors remain invented. Fuzz must interact with the
     wet and mud system: it should clump and darken when wet, and mat with mud.
   - **Built.** Lips: the upper jaw has a skin skirt hanging past the tooth tips, and a small
     lower lip; the upper lip edge is skinned to a `lipU` bone that pulls up as the jaw opens.
     Closed, the teeth are hidden from the side; opening shows the lower teeth, then the upper
     tips. A `jaw2` bone at the mid-jaw joint flexes the front of the lower jaw down 0.13 rad as
     it gapes and up 0.09 rad as it clamps in a bite. The skull is deeper and boxier behind the
     eyes (profile exponent up to 3.4). The antorbital fenestra and the nostril are shallow
     dents darkened in the skin shader. Hands: big curved claws on I to III (7 to 8.6 cm), with
     IV and V as tiny nubs. Feet: a dewclaw (digit I) set high on the inner metatarsus, and
     curved toe claws. Fuzz: 10 skinned shells (38k triangles, one draw call, no shadow pass)
     over the back, neck and upper tail. Coverage is per vertex, by normal and body position, so
     the snout, belly and limbs stay scaly, and the skin under the fuzz takes the root colour.
     Wet fuzz shortens, lies flatter, clumps toward clump centres and darkens; mud mats it
     harder and colours it wet-dark or crust-pale, and the fuzz flakes per plate with the same
     `D.mudFlake` band. All of it reads the same aliased band arrays as the skin.

6. **Jumping, with a controller layout change: A = jump, B = drink / sniff (hold).**
   - Modest jumps only. Herrerasaurus had long, strong legs, but at a few hundred kg,
     jump ability relative to size falls off.
   - Starting numbers for an adult: a standing hop of about 0.4 m clearance, and a
     running leap of up to about 1 m clearance covering 3–4 m.
   - Scale by size and weight: lighter species and younger growth stages jump
     relatively higher (Eodromaeus springy, hatchlings bouncy).
   - Costs stamina. Crouch wind-up, then airborne pose (legs tucked, tail as
     counterbalance), then a landing absorb.
   - Landing ties into the other systems: a bad landing on a rock runs the
     stumble check (item 4), landing in mud splashes, landing in water soaks.
   - Update the on-screen controls, the intro text and the menu hint for the
     new layout. The menu's "A to select" stays A.
   - **Built.** Crouch 0.14 to 0.24 s, then a ballistic arc with the takeoff speed corrected
     by half a step so the fixed-step peak matches the target. Clearance goes from 0.4 m
     standing to 1.0 m at a 4.2 m/s run-up, and tapers to 0.75 m at a full sprint (less stance
     time to push up); scaled by `JUMP_K` = (mass / 350)^(-1/6) × hip / 1.15. Measured: hop
     0.40 m; running leap 0.91 m over 3.2 m at 3.3 m/s; sprint leap 0.79 m over 6.2 m at 6.7 m/s.
     Default: the sprint leap is not capped to 3 to 4 m, so it doesn't brake mid-air. Stamina
     (new HUD row): hop costs 0.12, a leap up to 0.24; it regenerates 0.11/s and drains
     0.02/s while sprinting; a tired jump is lower. The airborne pose tucks the legs and lifts
     the tail. Landing absorbs with a pelvis dip, runs the stability check on rocks, soaks the
     body well above the waterline in the pond, and coats the legs and belly in the mud pit.
     Keyboard: Space jumps, G (hold) drinks or sniffs. The menu hint was already right
     ("A to select · B or Start to resume") and is unchanged.

7. **Drink and sniff on B (hold), context-sensitive.**
   - Water in range: within reach of the snout, about 2–3 m for an adult (scale with
     neck length and size).
   - In range and in front: start drinking right away.
   - In range but to the side or behind: the head turns toward the water for 2 s (it
     noticed it). If B is still held, the body turns in place to face it. The camera
     does not move. Then drinking starts.
   - In range but just out of reach after turning: shuffle a step or two closer
     automatically, then drink.
   - Drinking loop: lower the head, dip the snout and scoop with the jaw, then lift and
     tip the head back to swallow (visible throat gulp), and repeat while held. This
     is bird-style drinking, a reasonable guess for theropods.
   - No water in range: sniff instead, in one of two modes.
     - **Air sniff (default):** the head lifts, the snout turns into the wind, and it
       takes short sharp sniffs with small head turns. Later this picks up the
       direction of distant scents (prey, carcasses) carried on the wind.
     - **Ground sniff (only when standing on a scent trail):** the head drops and the
       nose works along the trail. Later this follows blood or tracks closely.
     - No tongue flicking: Herrerasaurus's closest living relatives, crocodiles and
       birds, don't taste the air that way. Its smelling ability is unknown, but
       other theropods' brain shapes suggest a good sense of smell.
   - Letting go of B at any point cancels and returns to normal posture.
   - **Built.** Water counts as in range within 2.8 m of the hips (36 directions searched).
     In front (within 0.45 rad): it turns the last bit and drinks. To the side or behind: the
     head turns toward the water for 2 s with the body still, then the body turns in place at
     1.4 rad/s with the camera target held still. If the water starts more than 1.8 m ahead
     (where the lowered snout dips), it shuffles up to 1.8 m closer. The drinking loop is
     lower, scoop (snout dips below the surface, ripple and lap sound), lift and tip back,
     then a gulp bulge travelling down the throat. It repeats every 2.3 s. A feedback term on
     the neck base keeps the snout at the water surface. Air sniff (default): head up, snout
     into a global wind (from the north-west, which also leans the plants); if the wind is
     more than 1 rad off, the body turns in place to face it. Sniffs come in bursts of three
     with small scanning turns. Ground sniff happens only on a scent trail. Wet or muddy feet
     leave fading three-toed tracks (wet 30 s, mud 90 s), and the tracks are the trail. No
     tongue flicking. Releasing B cancels at any stage.

## Playtest round 1 fixes (owner feedback)
- **Stumble before trip:** at 50% stamina or above, a failed rock check only staggers. Below half, the
  down threshold eases from unreachable at 50% to a score of 1.0 at 25% and lower. Measured on a sprint
  over step-up rocks: stamina 1.0, 0.6 and 0.4 gave staggers only; 0.2 went down on 5 of 8 approaches.
- **Subtle rock slowdown:** the per-step cost applies only on or off a rock (never plain terrain), at about
  4% for a 0.3 m step-up and half that down, capped at 10%. The stagger speed cut is softened to ×0.94–0.8.
- **Hills:** the old step cost was also firing on every uphill terrain step, which was the real cause of the
  slowdown. There is now a grade model (work against gravity scales with rise per metre): target speed ×
  1/(1 + k·grade), with k from 1.2 at a walk to 2.5 at a sprint, floored at 0.6. Gentle downhill helps up to 3%;
  steep downhill brakes. Measured steady speeds: sprint 5.25 m/s at 10%, 4.76 at 20%, 4.38 at 30%;
  walk 1.35 / 1.22 / 1.09 m/s at 10 / 20 / 30% (flat 1.53).
- **Jump:** a readable wind-up of 0.22–0.3 s from the press to take-off, with a deeper crouch, the tail
  dropping and the head dipping. Legs stay extended through push-off, tuck at the top, and reach forward
  before touchdown. Descent runs at 1.4× gravity, so peaks are unchanged (hop 0.40 m) but airtime is
  shorter (hop 0.53 s). The landing is heavier: a 0.3 m absorb over 0.55 s, a neck whip, a tail dip, a
  dust puff, a stronger rumble, a camera jolt (reduced-motion aware), and 0.25 s of sluggish turning and
  acceleration after a big landing.
- **Sound on first press:** the first controller button now starts the audio, wherever the browser allows
  it. Some browsers only unlock sound from a key or click, and the chip says so when that happens. Sounds
  are skipped while audio is suspended rather than queued up.
- **Uneven-ground gait:** near step-up rocks, steps get shorter (stride down to 72%) and stance longer.
  At lift-off, each foot picks a foothold from 18 candidates (shorter, longer or shifted a little sideways),
  scoring rock-edge landings, tilted faces and toe-heel straddles as bad. Each leg's timing can drift up to
  ±0.1 of a cycle (a high step lands later), so the two legs take visibly different steps, then fall back
  into rhythm on flat ground.
- **Rarer, more forgiving trips:** a toe only catches the part of a rise that the swing lift didn't clear
  (about 60% of the lift height is free). Stumble scoring is gentler with speed and edge landings, the
  stagger threshold went from 0.5 to 0.6, and going down needs a score of 1.6–3.2 below half stamina (never
  at or above half). Measured on 129 sprint approaches straight at every step-up rock: no falls at full
  stamina, 1 at 40%, 9 at 20%, 12 at 5%. A run (3.4 m/s) over the same rocks: 2 staggers and no falls.
- **Risk follows actual speed:** the stability check now uses the body's measured ground speed (how far it
  really moved each step, after slowdowns and pushes), not the commanded speed, scored as kinetic energy
  ((v/4.5)² × mass factor). So risk rises smoothly with speed instead of flipping when sprint engages, and
  the analog trigger matters. Approaching every step-up rock from 3 angles (129 runs, full stamina): 1.5 m/s
  0% staggers, 3.2 m/s 1%, 4.2 m/s 16%, 4.7 m/s 32%, 5.6 m/s 46%, no falls. At 20% stamina, falls were 1 at
  4.7 m/s and 4 at 5.7 m/s.
- **Stumble physics instead of a score formula:** the old check was one formula, roughly speed × rock type
  with a ±0.08 jitter, so the same situation always gave the same result. It's replaced by three measured
  failure modes:
  - **Trip:** the swung toe (0.2 m ahead of the ball) actually strikes a rock face. Fresh legs look far
    enough ahead to clear it; tired legs look less far ahead (down to 18%) and lift lower, so toes catch.
  - **Slip:** friction demand at touchdown (leg angle from hip to foot, plus surface tilt along and across
    the foot) against grip. Grip μ is about 0.95 on dry sandstone and 1.05 on dirt, ×0.5 on wet stone and
    ×0.45–0.8 with mud on the feet.
  - **Roll:** fewer than 3 of 5 foot points are supported (landing half off an edge).
  Recovery capacity scales with stamina. Results now vary with real foot placement and gait phase.
  Full-sprint approaches straight at every step-up rock (129 runs): fresh 60 staggers (slip 36, roll 25,
  trip 0); 10% stamina 69 staggers and 5 falls, with trips appearing (5). A full walk: 6 staggers.
- **Three escalating outcomes: slip, then stumble, then trip.**
  - **Slip** (score 0.4–0.75): the foot skids out about 0.14 m, the body dips and twitches, and it carries on
    in about 0.35 s with a 3% speed loss.
  - **Stumble** (above 0.75): the big lurch and scramble.
  - **Trip** (goes down): only below half stamina, still rare.
  Full-sprint approaches at every step-up rock (129 runs): fresh 38 slips, 22 stumbles, 0 trips;
  30% stamina 28/39/0; 10% stamina 30/39/5. A full walk when fresh: 5 slips, 1 stumble.
- **Rarer slips, real boulders:** the event threshold rose from 0.4 to 0.55 (slip band 0.55–0.8). Full-sprint
  slips at every rock fell from 38 to 14 of 117 runs when fresh, and a full walk now gives 2 slips and 1
  stumble. The step-up limit rose to 55% of hip height (about 0.63 m, knee height). The old walls (0.59–0.67 m)
  were knee-high, so the big rocks were rebuilt as tall boulders, 1.3–2.3 m high and 2.2–3.3 m across. Those
  are the only walls.
- **Logs are hazards, and a second map: Obstacle course (`#course`).** Logs are now analytic cylinders in the
  ground model: their rounded tops are footing that rolls a foot landing off the crown. Thin logs are
  step-overs, and logs above knee height are walls (capsule collisions) that have to be jumped. The
  valley's 4 logs are now 0.39 m step-overs.
  The course is a 137 m track with gate posts, in six sections:
  1. Rocks and pebbles, with step-up rocks and low slabs.
  2. Fallen logs from 0.25 m up to a 0.79 m one that must be jumped.
  3. A stream crossing with stepping stones.
  4. A mud pit with a half-sunk log.
  5. A boulder slalom with tilted slabs.
  6. A 12 m log bridge over a pond.
  It has a timer, a section readout and a best time (kept in the browser). Switch maps from the Start menu.
  An automated run at a full walk finished in 39.8 s, jumped the big log, slipped and stumbled a few times,
  and came out wet and muddy.
- **Splash screen map picker:** pick Valley or Obstacle course with the D-pad or left stick and enter with A
  (or keys or a click). The loaded map starts at once. The other map reloads the page on that map and asks
  for one button press, because the browser only exposes a controller after a press.
- **Midday sun:** the sun is held near its highest point (about 80°, inside the requested ±15% of the
  apogee), with whiter light and a bluer sky, so shadows are short instead of sunset-long.
- **Clearer course boundaries:** edge stakes every 3 m down both sides of the track (none in the water or
  mud), a stronger worn-track tint, and a darker edge line.
- **Trips are real falls:** a trip (still only below 50% stamina) now topples the dino onto its side
  (the side it was leaning toward). It lies there kicking its legs and with its head up, then rolls
  back upright and stands. On impact there's a thud, a camera jolt and a line of dust along the side it
  fell on. The tail drops flat while it's lying down.
- **Size and weight shape every fall:** timing scales with the square root of hip height (a bigger animal
  falls slower), and heavier animals hit harder, lie longer and get up more slowly. Slip and stumble
  flailing slows down for big animals and gets smaller for heavy ones, while light ones like Eodromaeus
  scramble quicker and wider. Herrerasaurus (1.15 m hip, 350 kg) is the reference.
- **Trips only while sprinting:** a trip (falling down) now needs both a sprint (right trigger, above
  5 m/s) and stamina below half. Walking or jogging over rough ground can still slip or stumble, but it
  never goes down. A tired test run over every step-up rock gave 5 trips and 67 slips or stumbles when
  sprinting, and 0 trips and 17 slips or stumbles at a walk.
- **Jumping up onto rocks:** any rock or log too tall to step onto can be jumped onto if it's within reach.
  A running leap clears about 1 m, and if the feet come up to about 0.35 m short of the top (0.3 × hip
  height), they catch the edge and it scrambles up, with a claw scrape, some lost speed and a little stamina.
  A jump aimed at a ledge ahead sets itself: the dino crouches a bit deeper, jumps just high enough and pushes
  forward enough to land on top, so a standing jump from the foot of a waist-high ledge works too. Collisions
  now go by body part: the chest, head and tail pass over anything lower than they are, so the dino can walk
  right up to a ledge with its chest over it. Up on a big rock, the body rides on the feet instead of being
  capped near ground level.
- **Ledges in the valley:** two flat-topped sandstone blocks beside the start. The 0.9 m one can be jumped
  onto from the ground. The 1.5 m one is out of reach from the ground but can be reached from the lower one.
  The 1.4–2.2 m boulders stay out of reach. On the course, the slalom boulders (0.8–0.94 m) and stream
  stones can now be climbed too.
- **Stepping off:** pushing the stick over an edge higher than a step makes it drop off as a fall, landing
  heavily. With the stick let go, it pulls up at the edge instead. A foot never steps down a ledge by itself.
  Test runs: a standing jump and running jumps from 4.0–4.4 m out landed on the 0.9 m block, and from 4.8 m
  out fell short. Ledge to tall block worked, and walking off the tall block dropped it with a hard landing.
  The obstacle course still finishes (38.7 s), and trips are still sprint-only.
- **Touch controls for phones and tablets:** a tap on a touch screen switches to touch mode (a controller or
  keyboard switches back). The left side is a floating thumbstick that appears under the thumb; pushing past
  its ring sprints, and the ring glows. Dragging on the right side turns the camera (about 0.3° per pixel).
  Xbox-coloured A (jump), B (hold to drink or sniff), X (bite) and Y (roar) buttons sit bottom right, with
  camera-behind and menu buttons above them. The splash says "Tap a map to enter", the menu is tapped, and
  the HUD gets compact in touch mode. Tested with emulated touch on an 844 × 390 landscape phone: walking,
  sprinting, a two-finger stick plus camera drag, a jump and the menu all worked.
- **Procedural sound engine integrated:** `pappydapimp69/sound-engine` `src/` is vendored at
  `demos/skin-test/vendor/sound-engine/` (zero dependencies, AudioWorklet DSP). The AudioContext is made and
  resumed inside the first user gesture (Safari and iOS insist), then passed to `SoundEngine.create({ context,
  zone: 'openPlain', device })`. Device defaults to headphones on desktop and "unknown" on touch screens, and the
  pause menu has a "Sound output" setting.
  - **Sim events:** the sim emits sound events (kind, who, position, level in dB at 1 m). Footsteps come from
    foot planting (`feet.step({ mass, speed, surface, claws })`), with the surface read from the ground:
    packed dirt, sandstone rocks, wooden logs, mud, water. The roar is the player's `voice.call({ mode: 'open' })`.
    Bite is a jaw modal strike, laps are bubble splashes, gulps are short closed-mouth calls, sniffs are
    unvoiced breath through a short nasal tube, and scuffs, scrambles and thuds are footstep impacts.
    `engine.update()` runs once per rendered frame. The Web Audio one-shots are gone; the wind bed stays as a
    plain filtered-noise loop.
  - **AI you can hear:** a rival Herrerasaurus (open calls) and a Saurosuchus (closed-mouth booms) roam
    beyond the trees on the sim's own seeded RNG. The rival answers your roar, and the Saurosuchus goes quiet
    for 25 s after hearing you (8 s for footsteps). Hearing is computed from the sim events (level minus
    spherical spreading and a little air loss, heard above 38 dB), never from what the engine played. A HUD
    chip says what the dino heard, the direction and the distance, and it works with the sound off.
  - **Determinism (sound-engine/E7):** audio variation comes from its own seeded RNG. A replay of the same
    inputs gave the same sim fingerprint, position and AI state with no audio, live audio, 4 voices and muted.
  - **Coordinates:** world x -> engine x, world z -> engine y, height -> engine z, listener at the camera with
    yaw = atan2(forward.x, forward.z). Three.js seen from above is mirrored against the engine plane, so that
    mapping reverses every pan; the left and right channels are swapped once at the output. Measured after
    the fix: a call at screen right comes out 4.1 dB louder on the right, and at screen left 3.9 dB louder on
    the left.
  - **Old vs new render (same 59.5 s recorded scene, same events):** overall level matched (-27.7 vs
    -26.5 dBFS RMS). Dirt steps went from a 330 Hz centroid thump to 1440 Hz with grit, and step levels vary
    naturally (2.8 dB spread). The roar was mixed to about 10 dB over a step. The two creature calls are new;
    the old build had no AI.
  - **Tutorial map on the engine too (merged from the tutorial work):** the hatchling's chirp is an open call
    from an 8 cm tract (two notes when it roars), its footsteps use a 0.5 kg hatchling mass, egg and meat tearing
    is a debris crunch at the mouth, and the Exaeretodon's alarm squeak is a two-note call from a 5 cm tract at
    the prey's position. Sound positions in the tutorial are divided by its 4x world scale. The prey's wandering
    now draws from the sim RNG instead of Math.random, so tutorial replays match too. The distant rival and
    Saurosuchus stay out of the tutorial.
  - **Sleeping prey hears events (merged from tutorial stage 2):** the sleeper's "noisy" check now reads the
    sim's sound events: the loudest player sound at its bed, wake at 30 dB. A physical footstep can't separate
    a hatchling's walk from its sprint (only about 7 dB apart), so events carry stealth-style noise ratings:
    sprint footfalls +10 dB, jump landings +14 dB. Measured: a walk never wakes it, a sprint does within about
    3.5 m, a standing jump within 3 m, and a roar always does. A full walk straight up to it and a bite caught
    it asleep. The tutorial's step-passed chirp is marked as UI, so the world doesn't hear it.
- **Touch sprint made visible:** sprint on touch was already "push the stick past its ring", but nothing showed
  the edge. A dashed ochre ring now always marks the sprint boundary (about 1.25× the stick's travel) with a
  "Sprint" label under it, and it turns solid while sprinting. Emulated phone check: sprint reached 7.1 m/s.
- **Slips, stumbles and trips sound like a skidding foot:** a skid is stick-slip, so it plays as a dense run of
  tiny foot contacts (about 55 a second) that slows and fades as the foot catches. That gives grit on dirt, claw
  scrapes on rock, suction in mud and bubbles in water. Slip 0.22 s, stumble 0.38 s, trip 0.55 s, scaled by body
  size. The old two-thump scuff is gone.
- **A fall growls:** when a trip puts it on the ground, the impact thud is followed by a growl.
- **Calls are emotes now:**
  - **Y** plays a roar that depends on the dino's condition: winded below 30% stamina (short and breathy),
    parched when thirsty (raspy), hungry when starving (low and long), otherwise the full roar. Thirst and
    hunger only exist in the tutorial so far; the valley joins in when survival stats arrive (M2).
  - **The call wheel** has six calls: roar, bellow, growl, boom (closed mouth), hiss, chuff. Controller: hold the
    right stick, point it at a call, let go (a tap still puts the camera behind). Keyboard: hold R, or press 1 to 6.
    Touch: hold Y, slide onto a call, lift.
  - Pitch is set relative to the vocal tract, so the same call scales from adult to hatchling.
  - The rival answers challenge calls (roars, bellow, growl) but not a boom, hiss or chuff.
  - The jaw and roar animation follow each call's length and mouth opening.
- **Controller call wheel is click, not hold:** click the right stick to open the wheel, tilt the right stick to a
  call, then click it again (or press A) to call it; B closes it without calling. While it's open, A and B belong
  to the wheel, so the A that confirms doesn't jump and the B that cancels doesn't drink. Camera behind moved to
  the left stick click. Tested with an emulated controller: opened, picked bellow (up-right) and boom (down),
  confirmed with a second click and with A, cancelled with B, Y still roars, left stick click recentres.
- **Realistic drinking and mouth sounds (no tones):** the old swallow was a closed-mouth voice, a pure 106 Hz
  "bloop" 29 dB above its own spectrum. Now:
  - The scoop is a burst of small bubbles where the snout breaks the surface.
  - As the head comes up, a few drops fall off the jaws back into the pond, each a single bubble rising in pitch.
  - The swallow is two low bubble gurgles of water going down the throat, muffled by the neck. Its centroid is
    near 400 Hz, it peaks only 22 dB over its spectrum, and it sits under the scoop.
  - The bite was a ringing three-mode block; now it's a hard, heavily damped teeth click (7 inharmonic modes,
    about 10 ms ring; spectral flatness 0.47 against 0.01).
  - Tearing meat is wet suction with gristle crackle.
  - Sniffs breathe through a short nasal tube (resonances from 1.4 kHz up) and are about 12 dB louder.
  - Measured old against new with the wind muted, the same events through each version's audio layer.
