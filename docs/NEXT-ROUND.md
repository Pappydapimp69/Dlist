# Next round: skin test demo changes

Changes queued from playtest feedback. Nothing here is built yet.

1. **Tail: stiffer, more lag on turns.**
   - Bend mostly near the hips and keep the back half straighter. Herrerasaurus's
     rear tail vertebrae had long interlocking processes that likely stiffened it,
     so it should act more like a rudder than a whip.
   - The demo currently bends the tip the most (tail bone weights rise toward the
     tip). Reverse that falloff.
   - Add a short lag on sharp turns, so the tail swings out briefly before it
     follows the curve of the body.

2. **Walk-to-sprint posture change, made clearly visible.**
   - At a sprint, level the trunk and lean it forward. Straighten and extend the
     neck, lower the head, and hold the tail straight out, so head, back and tail
     line up roughly horizontally and balance over the hips.
   - Bend the legs a bit more with longer strides at speed.
   - At a walk, keep a relaxed S-curved neck, a higher head and a slight tail droop.
   - The demo only hints at this now (a small pelvis pitch and tail lift). Make it
     much stronger. Tune the numbers from the Brain movement training results.

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
