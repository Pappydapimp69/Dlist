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

## 8. Stage 2 — jump and sniff

Appended after Rest. Teaches the two bound verbs Stage 1 never explains: jump and
sniff (Brain: assert every bound verb is explained).

### Decisions

| # | Decision | Why |
|---|---|---|
| TD11 | **Jump passes when the player crosses the fallen log**, any way across. | The log is too tall to step over, so crossing proves a jump. Ledge jumping now exists: they may land on the log and step off, and that still counts. (ZaneGPT.) |
| TD12 | **The scent trail is a fixed, authored path**, not deposits from a moving animal. | A scent source that isn't moving lays nothing under a travel-gated deposit (Brain: stationary-emitter lesson). The prey sleeps, so it can't lay its own trail. |
| TD13 | **Scent marks glow while sniffing and linger ~6 s after letting go.** | Holding B stops movement. Glow-only-while-held would make tracking stop-start. (ZaneGPT.) |
| TD14 | **The sleeping prey lies upwind** of the trail start (the wind blows from the southwest). | So "smell the air" points the right way. (ZaneGPT.) |
| TD15 | **Thicket around the prey, with a 6 m clearing at its bed.** | Ferns hide it until you've tracked it close; Stage 1 showed fern-hidden prey is otherwise invisible. |
| TD12b | **A moving prey lays its own scent**: one mark per 1.3 m travelled, fading over 2 min; the glow shows through foliage within 25 m. | The authored trail only reached the bed. Once the prey moved, sniffing led nowhere (owner playtest). Travel-gated deposit (Brain: pheromone lessons); a sleeper lays none, hence the authored trail to its bed. |
| TD16 | **The prey wakes on noise events:** a sprint, jump or roar within 12 m, or 3 s standing within 2.5 m. Awake, it flees like the first one. | Discrete noise events, not a continuous field (Brain: split events from fields). Roar waking it ties back to the Roar lesson. |

### Layout

| Place | Where |
|---|---|
| Fallen log | (8, -30), east-west, 16 m long, ~0.9 m tall, boulders at both ends |
| Trail start | just south of the log |
| Prey bed | about (-8, -42), upwind, in a fern thicket |

### Steps

| # | Step | Text | Passes when |
|---|---|---|---|
| 8 | Jump | A fallen log blocks the way. Run at it and press {jump} to leap over. | Crosses the log's line |
| 9 | Smell | Hold {drink} away from water to smell the air. Something's on the wind. | 2 s of air sniffing |
| 10 | Track | Put your nose down where the marks start and hold {drink} to follow the scent. The trail glows while you sniff. | Within 10 m of the sleeping prey |
| 11 | Sneak | It's asleep. Walk up slowly — sprinting, jumping or roaring wakes it — and press {bite}. | Bite connects with prey #2 |
| 12 | Done | — | — |

### Milestones

| # | Milestone |
|---|---|
| S1 | Log, boulders, thicket, scent trail in the map |
| S2 | Jump and Smell steps |
| S3 | Scent glow, Track step, sleeping prey, noise wake-ups, Sneak step |
| S4 | Bot walkthrough of both stages, screenshots, valley/course regression |

### Build log

| Milestone | Result |
|---|---|
| S1 | Done. 16 m log (0.9 m tall) at (8, -30) with four boulders; 120 extra ferns ring the bed; the trail corridor and bed stay open. |
| S2 | Done. **Found in testing:** with the trail laid at Smell, B by the log picked ground-sniffing over air, so Smell couldn't pass (the outranked-verb trap again). The trail now appears at Track. |
| S3 | Done. 18 scent marks glow while sniffing and fade over 6 s after. Prey #2 sleeps lying down; noise wakes it. |
| S4 | Done. Bot: Stage 1 into Jump 3/3, Stage 2 Jump through Done. **Also fixed:** a kill under the body couldn't be eaten (reach was measured only ahead of the snout, though the text says "stand over the kill"), and the Rest threshold dropped from 90% to 97% since the text only says "until it drops". |

## 9. Stage 3 — growth (with the predator heard, not seen)

Appended after Sneak. Teaches the core loop (eat and drink to grow) and plants the
sound of *Saurosuchus* so Stage 4 (danger) doesn't open with a surprise.

### Decisions

| # | Decision | Why |
|---|---|---|
| TD17 | **Growth fills only while Hunger and Thirst are both above 50%.** Both drain during the step (thirst faster), so the player has to cycle the pond and the kill. | Growing is the reward for the loop the earlier steps taught one verb at a time. |
| TD18 | **A stalled growth bar names its cause**: thirsty, hungry, or both. | Copy must assert the cause actually in effect (Brain: gate copy on the predicate). (ZaneGPT.) |
| TD19 | **"Growing up" shrinks the world**: tutorial plants scale to 72% over 3 s, tree collision radii with them; head bone 1.3x to 1.12x; the call deepens (vocal tract 8 to 14 cm); footsteps get heavier. | The rig can't be rescaled (TD1), so growth is the world shrinking. Shrinking colliders can only free the player, never trap them. |
| TD20 | **Distant *Saurosuchus* bellows during Growth**, every 30–40 s, from a fixed direction (east, past the hills; `PRED_FROM`). The hatchling turns its head to it. The panel says something big lives out there. | Plants the next stage's threat (a deliberate Chekhov setup that pays off in Stage 4). Text and head turn carry it when sound is off. |
| TD21 | **The bellow is a closed-mouth call** with f0 ≈ 70 Hz locked to the throat resonance (Brain dlist E16, scaled from a dove), slow infrasonic swell, **plus audible 150–400 Hz texture**; terrain-occlusion low-pass (Brain dlist E21); equal-power pan (dlist E26); controller rumble. | Phone and laptop speakers can't play 70 Hz. Without the upper texture, most players would hear nothing. (ZaneGPT.) |

**Accuracy:** no *Saurosuchus* call is known. A crocodilian-style closed-mouth
bellow is the extant-bracket guess and is labelled as one.

### Steps

| # | Step | Passes when |
|---|---|---|
| 12 | Grow: keep Hunger and Thirst above half; the bar fills over 90 s of fed-and-watered time; thirst drains 0.8%/s and hunger 0.6%/s, so it takes about one drink trip and one meal. Bellows start here. | Growth 100% |
| 13 | Juvenile: the world shrinks around you over 3 s. | Shrink finished |
| 14 | Done | — |

Food: the second kill (Stage 2) is there to eat; if no meat is left, a new
grazer spawns on the hunting ground.

### Milestones

| # | Milestone |
|---|---|
| G1 | Growth bar, drains, stall reasons, food respawn |
| G2 | Juvenile: world shrink, head, voice, footsteps |
| G3 | Saurosuchus bellow, head turn, panel line |
| G4 | Bot walkthrough, screenshots, regression, deploy |

### Build log

| Milestone | Result |
|---|---|
| G1 | Done. **Found in testing:** the first drain rates (1.6%/s, 1.2%/s, 60 s) took a bot ~12 round trips; rebalanced to one drink and one meal. |
| G2 | Done. Plants and tree colliders scale to 72%, head 1.12x, call and footsteps deepen. |
| G3 | Done. Bellows every 30–40 s from `PRED_FROM`; head turns to them; panel line for 7 s after each. After merging the new sim-driven sound engine, the bellow is that engine's *Saurosuchus* voice (closed mouth, `large` creature), silent until Grow; footstep mass grows 0.5 to 8 kg; the juvenile gets a 14 cm-tract voice. |
| G4 | Done. Bot: Jump through Done including Grow and Juvenile. Screenshots before and after the shrink. |

## 10. Risks

| Risk | Mitigation |
|---|---|
| 4x world still reads as an adult | Head scale, chirp, tall ferns. Owner playtest is the visual gate (T11 in the tension ledger: automated checks can't judge looks). |
| Prey AI gets stuck on the world edge or in water | Steers along the edge and away from water; respawns if more than 40 m away. |
| Lying-down pose breaks leg IK | Pelvis drop capped so the knee solve stays in range; checked in screenshots. |
| A step can't be finished | Each step's pass test is reachable from any state of the previous step; the walkthrough test drives every one. |
