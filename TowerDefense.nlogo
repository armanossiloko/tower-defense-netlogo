;; ============================================================================
;; TOWER DEFENSE - Complex Adaptive System Model
;; ============================================================================
;; A tower defense model where stationary towers defend against waves of
;; enemies approaching from all sides. The model demonstrates emergent
;; behavior arising from local agent interactions.

;; ============================================================================
;; BREED DEFINITIONS
;; ============================================================================

breed [ towers tower ]
breed [ enemies enemy ]
breed [ bullets bullet ]

;; ============================================================================
;; AGENT PROPERTIES
;; ============================================================================

towers-own [
  tower-type        ; type of tower (basic, fast, long-range)
  attack-range      ; how far tower can shoot
  fire-rate         ; shots per time period
  damage-per-shot   ; damage dealt per attack
  tower-health      ; health points
  max-health        ; maximum health
  cooldown          ; ticks until can fire again
  kills             ; enemies destroyed by this tower
]

enemies-own [
  enemy-type        ; type of enemy (fast, tough, balanced)
  enemy-health      ; health points
  max-enemy-health  ; maximum health
  enemy-speed       ; movement speed
  enemy-damage      ; damage dealt to towers
  target-tower      ; current target tower
  spawn-side        ; which side enemy spawned from
  attack-cooldown   ; ticks remaining before can attack again
]

bullets-own [
  bullet-damage     ; damage this bullet deals
  bullet-speed      ; movement speed
  target-enemy      ; enemy this bullet is targeting
  lifetime          ; ticks before bullet disappears
]

;; ============================================================================
;; GLOBAL VARIABLES
;; ============================================================================

globals [
  total-enemies-spawned
  total-enemies-destroyed
  total-towers-destroyed
  game-over?
  tick-counter
  
  ;; Stats by type
  fast-enemies-destroyed
  tough-enemies-destroyed
  balanced-enemies-destroyed
  
  ;; Tower type counts
  basic-tower-count
  fast-tower-count
  longrange-tower-count
]

;; ============================================================================
;; SETUP PROCEDURES
;; ============================================================================

to setup
  clear-all
  reset-ticks
  
  set total-enemies-spawned 0
  set total-enemies-destroyed 0
  set total-towers-destroyed 0
  set game-over? false
  set tick-counter 0
  set fast-enemies-destroyed 0
  set tough-enemies-destroyed 0
  set balanced-enemies-destroyed 0
  
  setup-patches
  setup-towers
  update-monitors
end

to setup-patches
  ask patches [
    set pcolor green + 2
  ]
end

to setup-towers
  let basic-count round (num-towers * basic-tower-percent / 100)
  let fast-count round (num-towers * fast-tower-percent / 100)
  let longrange-count num-towers - basic-count - fast-count
  
  if longrange-count < 0 [ set longrange-count 0 ]
  
  set basic-tower-count basic-count
  set fast-tower-count fast-count
  set longrange-tower-count longrange-count
  
  let tower-positions []
  
  if tower-placement-strategy = "defensive-ring" [
    set tower-positions get-ring-positions num-towers 8
  ]
  
  if tower-placement-strategy = "clustered-center" [
    set tower-positions get-clustered-positions num-towers
  ]
  
  if tower-placement-strategy = "grid" [
    set tower-positions get-grid-positions num-towers
  ]
  
  if tower-placement-strategy = "random" [
    set tower-positions get-random-positions num-towers
  ]
  
  let pos-index 0
  
  repeat basic-count [
    if pos-index < length tower-positions [
      let pos item pos-index tower-positions
      create-tower-at (item 0 pos) (item 1 pos) "basic"
      set pos-index pos-index + 1
    ]
  ]
  
  repeat fast-count [
    if pos-index < length tower-positions [
      let pos item pos-index tower-positions
      create-tower-at (item 0 pos) (item 1 pos) "fast"
      set pos-index pos-index + 1
    ]
  ]
  
  repeat longrange-count [
    if pos-index < length tower-positions [
      let pos item pos-index tower-positions
      create-tower-at (item 0 pos) (item 1 pos) "longrange"
      set pos-index pos-index + 1
    ]
  ]
end

to create-tower-at [x y type-name]
  create-towers 1 [
    setxy x y
    set tower-type type-name
    set kills 0
    set cooldown 0
    
    if tower-type = "basic" [
      set shape "circle"
      set color blue
      set size 2
      set attack-range 8
      set fire-rate 30
      set damage-per-shot 15
      set tower-health 100
      set max-health 100
    ]
    
    if tower-type = "fast" [
      set shape "square"
      set color yellow
      set size 2
      set attack-range 6
      set fire-rate 15
      set damage-per-shot 8
      set tower-health 80
      set max-health 80
    ]
    
    if tower-type = "longrange" [
      set shape "house"
      set color red
      set size 2
      set attack-range 12
      set fire-rate 50
      set damage-per-shot 35
      set tower-health 120
      set max-health 120
    ]
  ]
end

;; ============================================================================
;; TOWER PLACEMENT STRATEGIES
;; ============================================================================

to-report get-ring-positions [n radius]
  let positions []
  let angle-step 360 / n
  repeat n [
    let angle length positions * angle-step
    let x radius * cos angle
    let y radius * sin angle
    if abs x < max-pxcor - 1 and abs y < max-pycor - 1 [
      set positions lput (list x y) positions
    ]
  ]
  report positions
end

to-report get-clustered-positions [n]
  let positions []
  repeat n [
    let x random-float 10 - 5
    let y random-float 10 - 5
    set positions lput (list x y) positions
  ]
  report positions
end

to-report get-grid-positions [n]
  let positions []
  let grid-size ceiling sqrt n
  let available-width (max-pxcor - 2) * 1.6
  let available-height (max-pycor - 2) * 1.6
  let spacing-x available-width / (grid-size + 1)
  let spacing-y available-height / (grid-size + 1)
  
  let num-placed 0
  let row 0
  let max-iterations n * 10
  let iterations 0
  
  while [num-placed < n and iterations < max-iterations] [
    let col 0
    while [col < grid-size and num-placed < n] [
      let x (col - (grid-size - 1) / 2) * spacing-x
      let y (row - (grid-size - 1) / 2) * spacing-y
      
      if abs x < max-pxcor - 2 and abs y < max-pycor - 2 [
        set positions lput (list x y) positions
        set num-placed num-placed + 1
      ]
      set col col + 1
      set iterations iterations + 1
    ]
    set row row + 1
    
    if row >= grid-size and num-placed < n [
      set row 0
      set grid-size grid-size + 1
      set spacing-x available-width / (grid-size + 1)
      set spacing-y available-height / (grid-size + 1)
    ]
  ]
  
  while [num-placed < n] [
    let x random-float (max-pxcor * 1.6) - max-pxcor * 0.8
    let y random-float (max-pycor * 1.6) - max-pycor * 0.8
    if abs x < max-pxcor - 2 and abs y < max-pycor - 2 [
      set positions lput (list x y) positions
      set num-placed num-placed + 1
    ]
  ]
  
  report positions
end

to-report get-random-positions [n]
  let positions []
  repeat n [
    let x random-float (max-pxcor * 1.6) - max-pxcor * 0.8
    let y random-float (max-pycor * 1.6) - max-pycor * 0.8
    if abs x < max-pxcor - 2 and abs y < max-pycor - 2 [
      set positions lput (list x y) positions
    ]
  ]
  report positions
end

;; ============================================================================
;; MAIN LOOP
;; ============================================================================

to go
  if game-over? [ stop ]
  
  ask patches [ set pcolor green + 2 ]
  
  spawn-enemies
  ask enemies [ enemy-behavior ]
  ask towers [ tower-behavior ]
  ask bullets [ bullet-behavior ]
  
  check-game-over
  update-monitors
  
  tick
  set tick-counter ticks
end

;; ============================================================================
;; ENEMY SPAWNING
;; ============================================================================

to spawn-enemies
  if max-enemies-spawn > 0 and total-enemies-spawned >= max-enemies-spawn [
    stop
  ]
  
  let spawn-chance enemy-spawn-rate
  
  if random 100 < spawn-chance [
    spawn-enemy
  ]
  
  if spawn-chance > 25 and random 100 < (spawn-chance - 25) [
    spawn-enemy
  ]
  
  if spawn-chance > 35 and random 100 < (spawn-chance - 35) [
    spawn-enemy
  ]
end

to spawn-enemy
  if max-enemies-spawn > 0 and total-enemies-spawned >= max-enemies-spawn [
    stop
  ]
  
  let side one-of ["top" "bottom" "left" "right"]
  let spawn-x 0
  let spawn-y 0
  
  if side = "top" [
    set spawn-x random-xcor
    set spawn-y max-pycor - 1
  ]
  if side = "bottom" [
    set spawn-x random-xcor
    set spawn-y min-pycor + 1
  ]
  if side = "left" [
    set spawn-x min-pxcor + 1
    set spawn-y random-ycor
  ]
  if side = "right" [
    set spawn-x max-pxcor - 1
    set spawn-y random-ycor
  ]
  
  let rand random 100
  let type-name ""
  
  if rand < fast-enemy-percent [
    set type-name "fast"
  ]
  if rand >= fast-enemy-percent and rand < (fast-enemy-percent + tough-enemy-percent) [
    set type-name "tough"
  ]
  if type-name = "" [
    set type-name "balanced"
  ]
  
  create-enemies 1 [
    setxy spawn-x spawn-y
    set enemy-type type-name
    set spawn-side side
    set target-tower nobody
    
    if enemy-type = "fast" [
      set shape "person"
      set color red
      set size 1.5
      set enemy-speed 0.3
      set enemy-health 30 * enemy-health-multiplier
      set max-enemy-health enemy-health
      set enemy-damage 5
      set attack-cooldown 0
    ]
    
    if enemy-type = "tough" [
      set shape "person"
      set color orange
      set size 1.8
      set enemy-speed 0.15
      set enemy-health 120 * enemy-health-multiplier
      set max-enemy-health enemy-health
      set enemy-damage 15
      set attack-cooldown 0
    ]
    
    if enemy-type = "balanced" [
      set shape "person"
      set color yellow
      set size 1.5
      set enemy-speed 0.2
      set enemy-health 60 * enemy-health-multiplier
      set max-enemy-health enemy-health
      set enemy-damage 10
      set attack-cooldown 0
    ]
  ]
  
  set total-enemies-spawned total-enemies-spawned + 1
end

;; ============================================================================
;; ENEMY BEHAVIOR
;; ============================================================================

to enemy-behavior
  if attack-cooldown > 0 [
    set attack-cooldown attack-cooldown - 1
  ]
  
  if any? towers [
    set target-tower min-one-of towers [distance myself]
    
    if target-tower != nobody [
      face target-tower
      forward enemy-speed
      
      if distance target-tower < 2 and attack-cooldown = 0 [
        attack-tower
        set attack-cooldown 30
      ]
    ]
  ]
  
  update-enemy-color
end

to attack-tower
  if target-tower != nobody and member? target-tower towers [
    ask target-tower [
      set tower-health tower-health - [enemy-damage] of myself
      
      if tower-health <= 0 [
        set total-towers-destroyed total-towers-destroyed + 1
        die
      ]
    ]
  ]
end

to update-enemy-color
  if max-enemy-health > 0 [
    let health-percent enemy-health / max-enemy-health
    let in-danger? any? towers with [distance myself <= attack-range]
    
    if enemy-type = "fast" [
      ifelse in-danger? [
        set color scale-color red health-percent 0 1.2
      ] [
        set color scale-color red health-percent 0 1.5
      ]
    ]
    if enemy-type = "tough" [
      ifelse in-danger? [
        set color scale-color orange health-percent 0 1.2
      ] [
        set color scale-color orange health-percent 0 1.5
      ]
    ]
    if enemy-type = "balanced" [
      ifelse in-danger? [
        set color scale-color yellow health-percent 0 1.2
      ] [
        set color scale-color yellow health-percent 0 1.5
      ]
    ]
  ]
end

;; ============================================================================
;; TOWER BEHAVIOR
;; ============================================================================

to tower-behavior
  if cooldown > 0 [
    set cooldown cooldown - 1
  ]
  
  let under-attack? any? enemies in-radius 2
  let targets enemies in-radius attack-range
  
  if any? targets and cooldown = 0 [
    let target min-one-of targets [distance myself]
    
    if target != nobody [
      fire-at target
      set cooldown fire-rate
    ]
  ]
  
  update-tower-appearance under-attack?
end

to fire-at [target-enemy-agent]
  hatch-bullets 1 [
    set bullet-damage [damage-per-shot] of myself
    set bullet-speed 0.5
    set target-enemy target-enemy-agent
    set lifetime 100
    set shape "circle"
    set size 0.5
    
    let source-type [tower-type] of myself
    if source-type = "basic" [ set color cyan ]
    if source-type = "fast" [ set color yellow ]
    if source-type = "longrange" [ set color orange ]
    
    if target-enemy != nobody [
      face target-enemy
    ]
  ]
end

to update-tower-appearance [is-under-attack]
  if max-health > 0 [
    let health-percent tower-health / max-health
    
    if tower-type = "basic" [
      set color scale-color blue health-percent 0 1
    ]
    if tower-type = "fast" [
      set color scale-color yellow health-percent 0 1
    ]
    if tower-type = "longrange" [
      set color scale-color red health-percent 0 1
    ]
  ]
  
  ifelse is-under-attack [
    set size 2.5
  ] [
    set size 2
  ]
  
  if show-tower-range? [
    ask patches in-radius attack-range [
      if pcolor = green + 2 [
        set pcolor green + 1
      ]
    ]
  ]
end

;; ============================================================================
;; BULLET BEHAVIOR
;; ============================================================================

to bullet-behavior
  set lifetime lifetime - 1
  
  if lifetime <= 0 [
    die
  ]
  
  if target-enemy != nobody [
    if not member? target-enemy enemies [
      set target-enemy nobody
    ]
  ]
  
  if target-enemy != nobody [
    face target-enemy
  ]
  
  forward bullet-speed
  
  if abs xcor > max-pxcor or abs ycor > max-pycor [
    die
    stop
  ]
  
  let hit-enemies enemies-here
  if any? hit-enemies [
    let target-hit one-of hit-enemies
    ask target-hit [
      set enemy-health enemy-health - [bullet-damage] of myself
      
      if enemy-health <= 0 [
        set total-enemies-destroyed total-enemies-destroyed + 1
        
        if enemy-type = "fast" [
          set fast-enemies-destroyed fast-enemies-destroyed + 1
        ]
        if enemy-type = "tough" [
          set tough-enemies-destroyed tough-enemies-destroyed + 1
        ]
        if enemy-type = "balanced" [
          set balanced-enemies-destroyed balanced-enemies-destroyed + 1
        ]
        
        die
      ]
    ]
    die
  ]
end

;; ============================================================================
;; GAME STATE
;; ============================================================================

to check-game-over
  if not any? towers [
    set game-over? true
    user-message (word "DEFEAT! All towers destroyed.\n"
                       "Survived: " ticks " ticks\n"
                       "Enemies destroyed: " total-enemies-destroyed "\n"
                       "Enemies spawned: " total-enemies-spawned)
    stop
  ]
  
  if max-enemies-spawn > 0 and total-enemies-spawned >= max-enemies-spawn and not any? enemies [
    set game-over? true
    user-message (word "VICTORY! All enemies defeated!\n"
                       "Ticks: " ticks "\n"
                       "Enemies destroyed: " total-enemies-destroyed "\n"
                       "Towers remaining: " count towers "\n"
                       "Towers destroyed: " total-towers-destroyed)
    stop
  ]
  
  if ticks >= max-simulation-ticks [
    set game-over? true
    ifelse max-enemies-spawn > 0 and total-enemies-spawned >= max-enemies-spawn and not any? enemies [
      user-message (word "VICTORY! All enemies defeated!\n"
                         "Ticks: " ticks "\n"
                         "Enemies destroyed: " total-enemies-destroyed "\n"
                         "Towers remaining: " count towers "\n"
                         "Towers destroyed: " total-towers-destroyed)
    ] [
      user-message (word "TIME'S UP!\n"
                         "Ticks: " ticks "\n"
                         "Enemies destroyed: " total-enemies-destroyed " / " total-enemies-spawned "\n"
                         "Enemies remaining: " count enemies "\n"
                         "Towers remaining: " count towers)
    ]
    stop
  ]
end

to update-monitors
end

;; ============================================================================
;; ANALYSIS HELPERS
;; ============================================================================

to-report towers-alive
  report count towers
end

to-report enemies-alive
  report count enemies
end

to-report average-tower-health
  ifelse any? towers [
    report mean [tower-health] of towers
  ] [
    report 0
  ]
end

to-report kill-rate
  ifelse total-enemies-spawned > 0 [
    report (total-enemies-destroyed / total-enemies-spawned) * 100
  ] [
    report 0
  ]
end

to-report enemies-remaining
  ifelse max-enemies-spawn > 0 [
    let remaining (max-enemies-spawn - total-enemies-spawned)
    report ifelse-value (remaining > 0) [remaining] [0]
  ] [
    report 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
20
975
455
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-25
24
-14
13
1
1
1
ticks
30.0

TEXTBOX
20
5
170
23
Controls
12
0.0
1

BUTTON
15
20
88
53
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
20
168
53
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
20
55
170
73
Tower Settings
11
0.0
1

SLIDER
15
75
187
108
num-towers
num-towers
3
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
15
115
187
148
basic-tower-percent
basic-tower-percent
0
100
30.0
5
1
%
HORIZONTAL

SLIDER
15
155
187
188
fast-tower-percent
fast-tower-percent
0
100
20.0
5
1
%
HORIZONTAL

CHOOSER
15
195
187
240
tower-placement-strategy
tower-placement-strategy
"defensive-ring" "clustered-center" "grid" "random"
1

TEXTBOX
20
250
170
268
Enemy Settings
11
0.0
1

SLIDER
15
270
187
303
enemy-spawn-rate
enemy-spawn-rate
5
50
5.0
1
1
%
HORIZONTAL

SLIDER
15
310
187
343
enemy-health-multiplier
enemy-health-multiplier
0.5
3.0
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
15
350
187
383
fast-enemy-percent
fast-enemy-percent
0
100
40.0
5
1
%
HORIZONTAL

SLIDER
15
390
187
423
tough-enemy-percent
tough-enemy-percent
0
100
20.0
5
1
%
HORIZONTAL

SLIDER
15
430
187
463
max-enemies-spawn
max-enemies-spawn
0
500
120.0
10
1
NIL
HORIZONTAL

TEXTBOX
20
473
170
491
Other Settings
11
0.0
1

SLIDER
15
493
187
526
max-simulation-ticks
max-simulation-ticks
500
5000
2000.0
100
1
NIL
HORIZONTAL

SWITCH
15
533
187
566
show-tower-range?
show-tower-range?
1
1
-1000

TEXTBOX
995
5
1145
23
Game Statistics
12
0.0
1

MONITOR
990
20
1085
65
Towers Alive
count towers
0
1
11

MONITOR
990
75
1085
120
Enemies Alive
count enemies
0
1
11

MONITOR
990
130
1085
175
Total Spawned
total-enemies-spawned
0
1
11

MONITOR
990
185
1085
230
Remaining to Spawn
enemies-remaining
0
1
11

MONITOR
990
240
1085
285
Total Destroyed
total-enemies-destroyed
0
1
11

MONITOR
990
295
1085
340
Ticks
ticks
0
1
11

MONITOR
990
350
1085
395
Kill Rate %
precision kill-rate 1
1
1
11

MONITOR
1100
20
1215
65
Avg Tower Health
precision average-tower-health 1
1
1
11

MONITOR
1100
75
1215
120
Fast Destroyed
fast-enemies-destroyed
0
1
11

MONITOR
1100
130
1215
175
Tough Destroyed
tough-enemies-destroyed
0
1
11

MONITOR
1100
185
1215
230
Balanced Destroyed
balanced-enemies-destroyed
0
1
11

MONITOR
1100
240
1215
285
Towers Destroyed
total-towers-destroyed
0
1
11

PLOT
990
405
1295
585
Population Over Time
Time
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Towers" 1.0 0 -13345367 true "" "plot count towers"
"Enemies" 1.0 0 -2674135 true "" "plot count enemies"

PLOT
210
485
625
635
Enemies Destroyed by Type
Enemy Type
Count
0.0
3.0
0.0
10.0
true
false
"" ""
PENS
"Fast" 1.0 1 -2674135 true "" "plot-pen-reset\nset-plot-pen-color red\nplotxy 0 fast-enemies-destroyed"
"Tough" 1.0 1 -955883 true "" "plot-pen-reset\nset-plot-pen-color orange\nplotxy 1 tough-enemies-destroyed"
"Balanced" 1.0 1 -1184463 true "" "plot-pen-reset\nset-plot-pen-color yellow\nplotxy 2 balanced-enemies-destroyed"

PLOT
645
485
945
635
Cumulative Kills
Time
Total Kills
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-enemies-destroyed"

TEXTBOX
210
650
380
678
Tower Configuration
14
0.0
1

TEXTBOX
210
670
390
710
Basic (Blue Circle): Balanced\nFast (Yellow Square): Quick fire\nLong-range (Red House): Sniper
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a **Tower Defense** model that demonstrates a complex adaptive system where defensive towers must protect against waves of enemies approaching from all sides of the battlefield. The model explores how local interactions between individual agents (towers attacking enemies, enemies targeting towers) lead to emergent global patterns of defense success or failure.

## THE QUESTION

**How do different tower configurations and parameters affect the system's ability to defend against waves of enemies?**

Specifically:
- What mix of tower types is most effective for a given number of towers?
- How does enemy spawn rate affect survival time?
- What emergent patterns arise from the local interactions between towers and enemies?
- Are there threshold effects or phase transitions between successful defense and rapid collapse?

## AGENTS

### Towers (Stationary Defenders)
There are three types of towers:

1. **Basic Towers** (Blue Circles)
   - Range: 8 units
   - Fire Rate: 30 ticks between shots
   - Damage: 15 per shot
   - Health: 100
   - Role: Balanced all-around defense

2. **Fast Towers** (Yellow Squares)
   - Range: 6 units
   - Fire Rate: 15 ticks between shots (fastest)
   - Damage: 8 per shot
   - Health: 80
   - Role: Rapid fire for multiple weak enemies

3. **Long-Range Towers** (Red Houses)
   - Range: 12 units
   - Fire Rate: 50 ticks between shots (slowest)
   - Damage: 35 per shot
   - Health: 120
   - Role: Sniper-style long-range interception

### Enemies (Mobile Attackers)
Enemies appear as person-shaped zombies:

1. **Fast Enemies** (Red Person)
   - Speed: 0.3 units/tick
   - Health: 30 (× multiplier)
   - Damage: 5
   - Strategy: Rush towers quickly
   - Visual: Bright red when in tower range, darker when safe

2. **Tough Enemies** (Orange Person)
   - Speed: 0.15 units/tick
   - Health: 120 (× multiplier)
   - Damage: 15
   - Strategy: Tank damage, deal heavy blows
   - Visual: Orange color scales with health

3. **Balanced Enemies** (Yellow Person)
   - Speed: 0.2 units/tick
   - Health: 60 (× multiplier)
   - Damage: 10
   - Strategy: Middle ground approach
   - Visual: Yellow color scales with health

### Projectiles (Bullets)
- Created by towers to deliver damage
- Travel at speed 0.5 units/tick
- Home in on target enemies
- Color matches firing tower: Cyan (basic), Yellow (fast), Orange (long-range)
- Disappear on impact or after 100 ticks

## HOW IT WORKS

### Initialization
1. The battlefield is set up with a flat green background
2. Towers are placed according to the selected strategy (ring, clustered, grid, or random)
3. Tower types are distributed based on the percentage sliders

### Main Loop (Each Tick)
1. **Enemy Spawning**: New enemies spawn from random sides based on spawn rate
2. **Enemy Behavior**: Each enemy identifies the nearest tower and moves toward it; upon reaching a tower, it attacks
3. **Tower Behavior**: Each tower scans for enemies within range; if found and weapon is off cooldown, it fires a bullet
4. **Bullet Behavior**: Bullets track their targets and deal damage on collision
5. **Destruction**: Enemies die when health reaches 0; towers die when health reaches 0
6. **Game Over**: Simulation ends when all towers are destroyed or max ticks reached

## HOW TO USE IT

### Basic Controls
1. **Setup**: Initialize the model with your chosen parameters
2. **Go**: Run the simulation continuously
3. Adjust the speed slider to control simulation speed

### Key Parameters

**Tower Configuration:**
- `num-towers`: Total number of towers (3-20)
- `basic-tower-percent`: Percentage of basic towers (0-100%)
- `fast-tower-percent`: Percentage of fast towers (0-100%)
- Remaining towers become long-range towers
- `tower-placement-strategy`: How towers are arranged
  - Defensive Ring: Towers form a perimeter
  - Clustered Center: Towers group near center
  - Grid: Evenly spaced grid pattern
  - Random: Random positions

**Enemy Configuration:**
- `enemy-spawn-rate`: Probability of enemy spawning each tick (5-50%)
  - Higher values spawn multiple enemies per tick
  - Recommended: 20-30% for balanced gameplay
- `enemy-health-multiplier`: Scales all enemy health (0.5-3.0×)
- `fast-enemy-percent`: Percentage of fast enemies (0-100%)
- `tough-enemy-percent`: Percentage of tough enemies (0-100%)
- Remaining enemies are balanced type
- `max-enemies-spawn`: Maximum total enemies to spawn (0-500)
  - Set to 0 for unlimited spawning (continuous waves)
  - Set to positive number for finite wave mode with victory condition
  - Victory achieved when all spawned enemies are destroyed

**Other:**
- `max-simulation-ticks`: Maximum simulation duration (500-5000)
- `show-tower-range?`: Toggle to visualize tower attack ranges (darkens patches within range)

### Monitors
- **Towers Alive**: Current number of active towers
- **Enemies Alive**: Current number of enemies on the field
- **Total Spawned**: Cumulative enemies spawned
- **Total Destroyed**: Cumulative enemies killed
- **Kill Rate %**: Percentage of spawned enemies destroyed
- **Avg Tower Health**: Average health of remaining towers
- **Type-specific Destroys**: Kills by enemy type
- **Towers Destroyed**: Towers lost

### Plots
1. **Population Over Time**: Shows tower and enemy counts over time
2. **Enemies Destroyed by Type**: Bar chart of kills by enemy type
3. **Cumulative Kills**: Total enemies destroyed over time

## THINGS TO TRY

1. **Balanced Defense**: Try 40% basic, 30% fast, 30% long-range with medium spawn rate (15%)

2. **Range vs. Rate**: Compare:
   - All long-range towers (slow, powerful, far-reaching)
   - All fast towers (quick, weak, close-range)
   - Mixed strategy

3. **Placement Strategy**: Test each placement strategy with the same parameters. Does clustering help or hurt?

4. **Difficulty Scaling**: Gradually increase spawn rate and health multiplier. At what point does defense collapse?

5. **Extreme Scenarios**:
   - Very few towers (3-5) with maximum range
   - Many towers (15-20) with poor placement
   - All tough enemies vs. all fast enemies

6. **Phase Transitions**: Find the critical spawn rate where the system transitions from successful defense to rapid failure

7. **Finite Wave Mode**: Set max-enemies-spawn to 100-200 for a defined challenge:
   - Can you achieve victory with minimal tower losses?
   - What's the minimum number of towers needed to win?
   - Test different tower mixes for wave completion efficiency

## THINGS TO NOTICE

### Visual Feedback

1. **Tower Colors**: Towers darken as they take damage, providing instant health feedback
2. **Tower Pulsing**: Towers grow larger (pulse) when enemies are within 2 units - visual "under attack" indicator
3. **Enemy Color Changes**: Enemies appear brighter when within tower range (danger) and darker when safe
4. **Projectile Colors**: Bullet colors match their source tower type (cyan, yellow, or orange)
5. **Health Scaling**: Both towers and enemies use color intensity to show current health percentage

### Emergent Patterns

1. **Dynamic Front Lines**: Enemies naturally form "fronts" where they engage tower fire, creating emergent battle lines

2. **Focus Fire**: Multiple towers targeting the same enemy can lead to overkill, wasting damage

3. **Bottlenecks**: Enemy waves from different sides can converge, creating high-density attack zones

4. **Tower Vulnerability**: Once one tower falls, enemies can penetrate deeper, accelerating collapse

5. **Type Effectiveness**: Fast enemies may slip through slow-firing tower defenses; tough enemies may absorb too much firepower

6. **Placement Sensitivity**: Small changes in tower position can significantly affect coverage and survival time

### System Behavior

- The system exhibits **threshold effects**: small parameter changes can cause dramatic shifts in outcome
- **Local interactions** (individual tower-enemy engagements) produce **global outcomes** (defense success/failure)
- **Path dependence**: early enemy waves can weaken towers, making later waves more dangerous
- **Resource allocation**: distributing tower types is a constrained optimization problem

## EXTENDING THE MODEL

Possible extensions:
1. Add tower upgrade mechanics (cost/benefit tradeoffs)
2. Implement enemy pathfinding (smart routing around towers)
3. Add special abilities (slow effects, area damage, shields)
4. Create wave-based spawning with difficulty progression
5. Add terrain features (obstacles, chokepoints)
6. Implement tower targeting strategies (nearest, weakest, strongest)
7. Add resource collection and tower building during simulation
8. Create multiple "bases" to defend

## NETLOGO FEATURES

This model demonstrates:
- **Breeds**: Multiple agent types (towers, enemies, bullets)
- **Agent properties**: Individual attributes for each agent
- **Local sensing**: Agents detect nearby agents using `in-radius`
- **Agent creation**: Dynamic creation of enemies and bullets
- **Targeted movement**: Bullets home in on enemies
- **Conditional behavior**: Different actions based on agent state
- **Aggregation**: Global statistics from individual actions
- **Visualization**: Color coding to show health status

## COMPLEX ADAPTIVE SYSTEM ASPECTS

This model exemplifies a **Complex Adaptive System** because:

1. **Multiple Interacting Agents**: Towers, enemies, and bullets all interact based on proximity and state

2. **Simple Local Rules**: 
   - Enemies: "Move toward nearest tower and attack"
   - Towers: "Shoot nearest enemy in range"
   - Bullets: "Track target and damage on collision"

3. **Emergent Global Behavior**: 
   - Defense patterns emerge from individual decisions
   - Survival time is not predetermined but emerges from interactions
   - "Front lines" form naturally where enemies meet tower fire

4. **Adaptation**: 
   - Enemies continuously retarget as towers are destroyed
   - System responds to parameter changes in non-obvious ways

5. **Non-linearity**: 
   - Small changes in spawn rate or tower count can cause dramatic outcome shifts
   - Losing one tower can cascade into rapid total collapse

6. **Self-organization**: 
   - Enemy distribution patterns self-organize based on spawn locations and tower placement
   - Bullet density naturally increases in threatened areas

## CREDITS AND REFERENCES

This model was created as a demonstration of complex adaptive systems in the context of tower defense mechanics, a popular game genre that naturally exhibits emergent behavior from simple rules.

**Model created**: 2025
**Platform**: NetLogo
**Purpose**: Educational exploration of complex adaptive systems

### Student Team

This project was developed by:

- **Arman Ossi Loko**
  - Email: arman.ossiloko@edu.fit.ba, armanossiloko@gmail.com
  - GitHub: https://github.com/armanossiloko/

- **Azemina Magrdžija**
  - Email: azemina.magrdzija@edu.fit.ba

- **Almer Hodžić**
  - Email: almer.hodzic@edu.fit.ba

- **Edin Šehović**
  - Email: edin.sehovic@edu.fit.ba
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="tower-mix-experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>total-enemies-destroyed</metric>
    <metric>total-towers-destroyed</metric>
    <metric>kill-rate</metric>
    <enumeratedValueSet variable="num-towers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-tower-percent">
      <value value="0"/>
      <value value="33"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fast-tower-percent">
      <value value="0"/>
      <value value="33"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enemy-spawn-rate">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tower-placement-strategy">
      <value value="&quot;defensive-ring&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="spawn-rate-experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>total-enemies-destroyed</metric>
    <metric>kill-rate</metric>
    <enumeratedValueSet variable="enemy-spawn-rate">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-towers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-tower-percent">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fast-tower-percent">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
