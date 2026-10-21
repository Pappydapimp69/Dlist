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
