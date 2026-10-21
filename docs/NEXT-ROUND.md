# Next round: skin test demo changes

Changes queued from playtest feedback. Nothing here is built yet.

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
