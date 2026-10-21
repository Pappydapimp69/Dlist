# Tutorial map — blueprint

Status: **T1–T7 built and verified headless**. Owner playtest is the remaining gate. Third map in the skin-test demo, opened with `#tutorial`
(also from the Start menu's Map entry).

The player hatches from an egg in a nest as a baby Herrerasaurus and learns the
basics in order: **walk, roar (call), drink, hunt (and eat), rest**.

---

## 1. Key decisions

| # | Decision | Why |
|---|---|---|
| TD1 | **The rig is not rescaled.** The tutorial world is built about 4x larger (ferns over its head, giant trees, a huge nest) so the adult-sized sim reads as a hatchling. | Every rig and sim constant is in adult metres (hip 1.15 m, IK lengths, collision radii, snout reach, speeds). Rescaling them is a deep refactor of code we can't eyeball-test. Relative scale is what the eye reads (Brain: scale creatures against an in-world reference). |
| TD2 | **Baby cues on the creature itself:** head bone scaled about 1.3x, a high-pitched chirp in place of the roar, lighter footsteps. Tutorial only. | A 4x world alone makes a *small adult*. Big head = baby. (ZaneGPT pressure test.) |
| TD3 | **Everything new is gated on `MAP === 'tutorial'`**, except the new Rest verb, which works on every map. | Valley and course must not change. One canonical verb, no tutorial-only copy of it (Brain: the-game-prologue E15). |
| TD4 | **The tutorial is a passive observer** over real events. Each step's pass test is pinned to a specific entity (the tutorial pond, prey #1, the carcass). | Generic triggers get satisfied by accident and mask input bugs (Brain: prologue E15, brainwork E177). |
| TD5 | **One step table** holds each step's text, marker position and pass test. | An arrow mapped apart from its test pointed at the wrong thing forever (Brain: demo-disc E51). |
| TD6 | **Key names are resolved at display time** from the same table as the controls panel, and repainted when the player switches device. | Brain: seven E18. |
| TD7 | **Eat outranks drink** on the B button when a carcass is in reach. | A single-action resolver silently starves a tutorial step when a higher-priority verb is valid at the same time (Brain: sandbox-resolver-starves-tutorial E1). |
| TD8 | **The prey doesn't exist until the Hunt step starts**, and respawns ahead of the player if it's lost. | Can't be soft-locked by anything done before the step (Brain: quest spawn-on-accept lesson). |
| TD9 | **Prey is slower than a sprint, faster than a walk.** Flee 5.4 m/s, tiring to 4.2 m/s; the player sprints at 7.4. | Equal speed never closes the gap (Brain: flee-AI speed parity). Forces a sprint, which drains stamina, which sets up the Rest lesson. |
| TD10 | **No saved "tutorial done" flag.** | A raw localStorage "seen once" bit leaks across save slots later (Brain: save lesson). |

## 2. Accuracy notes

- **Egg:** early dinosaur eggs were likely **soft, leathery shells** (Norell et
  al. 2020). The hatchling *tears* free; it doesn't crack a hard shell. Colour is
  a guess.
- **Prey:** a young *Exaeretodon*, a plant-eating cynodont on the NPC roster
  (§3 of the main blueprint). Juveniles are known from the formation.
- **Nest:** a scraped mound ringed with ferns and twigs. Nest form is unknown for
  Herrerasaurus; this is invented.
- **No grass, no flowers.** Same plant list as the valley.

## 3. Map layout

| Place | Where | Notes |
|---|---|---|
| Nest | spawn, (0, 34) | Raised rim about knee high. Egg in the middle. |
| First marker | (6, 16) | Walk lesson ends here. |
| Pond | (-2, -4), r 8 | The only water. Drink lesson. |
| Hunting ground | around (-20, -22) | Open clearing, 20 m with no ferns. Prey spawns here when the Hunt step starts. |
| Mud pit | (28, -26) | Kept small; the engine expects one. |

## 4. Steps

| # | Step | Text (keys resolved per device) | Passes when |
|---|---|---|---|
| 0 | Hatch | Press {jump} again and again to tear free of the egg | 4 presses while inside the egg |
| 1 | Walk | Push {move} to walk. Climb over the nest rim and follow the marker | Reaches marker 1 |
| 2 | Call | Hatchlings call out so the others know where they are. Press {roar} | A call starts during this step |
| 3 | Drink | Thirsty. Go to the pond and hold {drink} at the edge | Thirst bar full (from drinking at the tutorial pond) |
| 4 | Hunt | Hungry. A young Exaeretodon is grazing by the ferns. Hold {sprint} to run it down, then press {bite} | Bite connects with prey #1 |
| 5 | Eat | Hold {drink} over the kill to eat | Hunger bar full (from carcass #1) |
| 6 | Rest | The chase wore you out. Hold {rest} to lie down until your stamina is full | Stamina full while resting, having been below 70% this step |
| 7 | Done | Card: go to the valley, or stay | — |

New stats shown only in the tutorial: **Thirst** and **Hunger** bars.
Tutorial stamina: sprint drains about 9%/s (empty in ~11 s), standing
recovers 4%/s, resting 30%/s.

## 5. Milestones

Each one ends with something playable at `#tutorial`. Each milestone starts
with a `brain query` on its sub-problem and a ZaneGPT pressure test, and ends
with a Cognitive Update.

| # | Milestone | You can… |
|---|---|---|
| T1 | Map shell | Pick Tutorial from the menu; spawn in a nest in an oversized fern world with a pond and the first marker |
| T2 | Hatch | Start inside a leathery egg, press A to tear out, shell scraps fly, a hatchling chirp. Big-head baby look. |
| T3 | Step engine + walk + call | Step panel with device-correct key names, marker ring, walk and call lessons pass |
| T4 | Drink | Thirst bar; drinking fills it; lesson passes |
| T5 | Hunt + eat | Prey that grazes, flees and tires; bite hit detection; carcass; eat on B outranks drink; Hunger bar |
| T6 | Rest | New Rest verb on every map (left trigger / Z): lies down, faster stamina recovery; lesson passes; completion card |
| T7 | Verify | Automated walkthrough of every step through the real input path, screenshots checked by eye, valley and course unchanged |

## 6. Build log

| Milestone | Result |
|---|---|
| T1 | Done. Plants scaled 2.2–3.4x (ferns), 2.4x (conifers), 2.8x (Dicroidium), 2.6x (horsetails). |
| T2 | Done. Egg hides the rig until it tears; camera pulls back to 11 m to frame the egg, then closes to 6.6 m. Head bone 1.3x. Chirp f0/formants from an 8 cm tract (Brain dlist E8). |
| T3 | Done. Key names resolve from the controls table; the marker is a world-space light shaft (no screen projection, per Brain's waypoint-marker lesson). |
| T4 | Done. Only a swallow whose scoop reached water counts (+20% thirst). |
| T5 | Done. **Found in testing:** 3 m ferns hid the 0.9 m prey completely, so the hunting ground became a fern-free clearing and the marker stays on the prey until you're within 8 m. Bite connects when the snout is within ~1 m of the prey's body axis. Eat outranks drink on B. |
| T6 | Done. Rest works on every map (left trigger / Z). In the tutorial, low stamina caps the sprint (7.4 down to 4.2 m/s) so resting matters. |
| T7 | Done. A headless bot plays the whole tutorial through the real input path; 3 of 3 runs reach Done (prey AI is random). Valley and course checked unchanged. Screenshots checked by eye at 1280x720 and 390x844. |

## 7. Risks

| Risk | Mitigation |
|---|---|
| 4x world still reads as an adult | Head scale, chirp, tall ferns. Owner playtest is the visual gate (T11 in the tension ledger: automated checks can't judge looks). |
| Prey AI gets stuck on the world edge or in water | Steers along the edge and away from water; respawns if more than 40 m away. |
| Lying-down pose breaks leg IK | Pelvis drop capped so the knee solve stays in range; checked in screenshots. |
| A step can't be finished | Each step's pass test is reachable from any state of the previous step; the walkthrough test drives every one. |
