patches-own [culture walls cluster creator-gene prev-color]
globals [this-cluster max-cluster num-cluster last-click]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-patches
  setup-links
  setup-walls
  setup-turtles
  set last-click timer
end

to go
  tick
  set-creators-color
  update-patch
  make-event
  if ticks mod sample-interval = 0
    [
    update-plot
    if check-end? [stop]
    ]
end

to set-creators-color
    ask patches with [creator-gene]
    [ set pcolor 19]
end

to make-event
  let p-event prob-event
  let culture-Event []
  let culture-B []
  let patch-B 0
  let P-similar 0
  let n 0
  if (p-event > 0 and p-event < 1) and random-float 1 < p-event [
    ;output-print "event today!"
    ask one-of patches with [creator-gene]
    [
      set pcolor 17
      set culture-Event culture
    ]
   ; output-print "event today! by culture"
   ; output-print  culture-Event
    ask patches
    [
      set culture-B culture
      set patch-B self
      set P-similar similarity culture-Event culture-B
      if (P-similar > 0 and P-similar < 1) and random-float 1 < P-similar
      [
        set n any-changeable-different-item-index culture-B culture-Event
        ifelse n > -1 ;-1 if we nothing replace - this could happen since we have unchange able parts
        [
          ;output-print "updating patch! old culture:"
          ;output-print culture-B
          ;set culture replace-item n culture (item n culture-Event)
          set culture replace-item n culture updated-item-value (item n culture-B) (item n culture-Event)
          ;output-print "updating patch! new culture:"
          ;output-print culture
          update-walls
        ]
        [
         ; output-print "didnot changed since different is only fixed part"
        ]
      ]
    ]
 ]
end

to setup-patches
  let x 0
  let y 0
  set-default-shape turtles "square"
  repeat world-height
    [
    set x 0
    repeat world-height
      [
      ask patch x y
        [
        sprout 1 [setxy xcor ycor set color black set size 0.2]
        set pcolor white
        set culture []
        set creator-gene (random-float 1 < prob-creator-gene)
        repeat num-features
          [
          set culture fput random num-traits culture
          ]
        ]
      set x x + 1
      ]
    set y y + 1
    ]
  set-creators-color
end

to setup-links
  ask turtles
    [
    create-links-with turtles-on neighbors4
      [
      set color black
      set thickness 0.2
      ]
    ]
end

to setup-walls
  let a1 0     ; 1..2
  let a2 0     ; ....
  let a3 0     ; 4..3
  let a4 0
  ask patches
    [
    ask turtles-here [set a2 who]
    ask turtles-at -1 0 [set a1 who]
    ask turtles-at 0 -1 [set a3 who]
    ask turtles-at -1 -1 [set a4 who]
    set walls (list link a1 a2 link a2 a3 link a3 a4 link a4 a1)
    update-walls
    ]
end

to setup-turtles
  ask turtles [setxy xcor + 0.5 ycor + 0.5]
end

to update-patch
  let neighbor-positions [[0 1] [1 0] [0 -1] [-1 0]]
  let neighbor random 4
  let culture-A []
  let culture-B []
  let patch-A 0
  let patch-B 0
  let P 0
  let n 0
  ask one-of patches
    [
    set culture-A culture
    set patch-A self
    ask patch-at item 0 (item neighbor neighbor-positions) item 1 (item neighbor neighbor-positions)
      [
      set culture-B culture
      set patch-B self
      ]
    set P similarity culture-A culture-B
    if (P > 0 and P < 1) and random-float 1 < P
      [
      set n any-changeable-different-item-index culture-A culture-B
      if n > -1
      [
          ;output-print "updating patch! old culture:"
         ; output-print culture-B
          ;output-print "updating patch! own culture:"
          ;output-print culture-A
          set culture replace-item n culture updated-item-value (item n culture-A) (item n culture-B)
          ;output-print "updating patch! result culture:"
         ; output-print culture
          update-walls
        ]
      ]
    ]
end

to update-walls
  let neighbor-positions [[0 1] [1 0] [0 -1] [-1 0]]
  let culture-A culture
  let culture-B []
  let n 0
;;  output-print "updating walls for culture:"
;;  output-print culture-A
  repeat 4
    [
    ask patch-at item 0 (item n neighbor-positions) item 1 (item n neighbor-positions) [set culture-B culture]
    ask item n walls
      [
        set color 9.9 * ifelse-value ignore-fixed-features-in-similarity [similarity-wo-fixed culture-A culture-B] [similarity culture-A culture-B]
      ]
    set n n + 1
    ]
end

to-report calc-cluster
  find-clusters
  report num-cluster
end

to update-plot
  find-clusters
  set-current-plot "Connected Regions"
  set-plot-x-range 0 ticks
  set-plot-y-range 0 world-width * world-height
  set-current-plot-pen "Number"
  plotxy ticks num-cluster
  set-current-plot-pen "Largest"
  plotxy ticks max-cluster
end

to find-clusters
  set max-cluster 0
  set num-cluster 0
  let seed patch 0 0
  ask patches [set cluster nobody]
  while [seed != nobody]
    [
    ask seed
      [
      set cluster self
      set this-cluster 1
      set num-cluster num-cluster + 1
      grow-cluster
      ]
    if this-cluster > max-cluster [set max-cluster this-cluster]
    set seed one-of patches with [cluster = nobody]
    ]
end

to grow-cluster
  ask neighbors4 with [(cluster = nobody) and (similar-cultures? culture [culture] of myself)]
    [
    if cluster = nobody [set this-cluster this-cluster + 1]
    set cluster [cluster] of myself
    grow-cluster
    ]
end

to-report distance-around [val1 val2 set-ln]
  ifelse val1 < val2
  [report (val1 - 0) + (set-ln - val2)]
  [report (val2 - 0) + (set-ln - val1)]
end

to-report add-around [o-v val-to set-ln]
  let incr round ( (distance-around o-v val-to set-ln) / 2 )
 ; output-print incr
  ifelse o-v < val-to
  [ifelse incr <= o-v
    [report o-v - incr ]
    [report set-ln - incr + o-v]]
  [ifelse incr + o-v < set-ln
    [report incr + o-v]
    [report incr - (set-ln - o-v)]]
end

to-report updated-item-value [obs-val source-val]
  ;output-print "updating item value observer, source"
  ;output-print obs-val
  ;output-print source-val
  ifelse gradual-trait-update
  [ifelse gradual-centered
    [report  round (obs-val + (( source-val - obs-val ) / 2) )]
    [report add-around obs-val source-val  num-features]]
  [report source-val]
end

to-report updated-item-value2 [obs-val source-val]
  ;output-print "updating item value observer, source"
  ;output-print obs-val
  ;output-print source-val
  ifelse gradual-trait-update
  [let dist-s source-val - obs-val
   ifelse gradual-centered
    [report  round (obs-val + ( dist-s / 2) )  ]
    [
      let dist-a distance-around source-val obs-val num-features
      ifelse abs( dist-s ) = dist-a
      [ifelse (random 2) = 0
        [report round (obs-val + ( dist-s / 2) )]
        []]
      [ifelse dist-s < dist-a
        []
        []]
    ]

  ]
  [report source-val]
end

to-report check-end?
  let end? true
  ask links
    [
    if color > 0 and color < 9.9 [set end? false]
    ]
  report end?
end

to-report similar-cultures? [list-A list-B]
  ifelse ignore-fixed-features-in-similarity
  [report (similarity-wo-fixed list-A list-B) = 1]
  [report (similarity list-A list-B) = 1]
end

to-report similarity-wo-fixed [list-A list-B]
  let n 0
  let l (length list-A)
  let similarities 0
  repeat l
    [
    if (item n list-A = item n list-B) and (n >=  fixed-features)
      [set similarities similarities + 1]
    set n n + 1
    ]
  report similarities / (l - fixed-features)
end

to-report similarity [list-A list-B]
  let n 0
  let l length list-A
  let similarities 0
  repeat l
    [
    if item n list-A = item n list-B [set similarities similarities + 1]
    set n n + 1
    ]
  report similarities / l
end

to-report any-changeable-different-item-index [list-A list-B]
  let n 0
  let differences []
  repeat length list-A
    [
    if (item n list-A != item n list-B) and (n >=  fixed-features)
      [set differences lput n differences]
    set n n + 1
    ]
  report ifelse-value (length differences > 0) [ item (random length differences) differences] [-1]
end

to-report any-different-item-index [list-A list-B]
  let n 0
  let differences []
  repeat length list-A
    [
    if item n list-A != item n list-B [set differences lput n differences]
    set n n + 1
    ]
  report item (random length differences) differences
end

to clean-green
  ask patches with [pcolor = green]
  [
    set pcolor prev-color
    set prev-color nobody]
end

to calc-distance
    if mouse-down? [
    let clicked timer
    ask patch round mouse-xcor round mouse-ycor [
      if (clicked - last-click) > 0.3
      [
        let culture-A culture
        let culture-B []
        if count patches with [pcolor = green] = 2 [clean-green]
        if count patches with [pcolor = green] = 1
        [ask one-of patches with [pcolor = green]
          [set culture-B culture]]
        output-print "selected"
        output-print culture
        if culture-B != []
        [
          output-print "similarity (simple)"
          output-print similarity culture-A culture-B
          output-print "similarity (w/o fixed)"
          output-print similarity-wo-fixed  culture-A culture-B]
        set prev-color pcolor
        set pcolor green
        set last-click timer
      ]
    ]
  ]
end

to print-patch
  let current-point nobody
  if mouse-down? [
    let clicked timer
    ask patch round mouse-xcor round mouse-ycor [
      if (clicked - last-click) > 0.3
      [output-print "clicked on"
        output-print culture
        set prev-color pcolor
        set pcolor green
        set last-click timer
        ;lset plabel culture
      ]
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
204
10
444
251
-1
-1
23.2
1
10
1
1
1
0
1
1
1
0
9
0
9
0
0
1
ticks
30.0

BUTTON
7
10
69
43
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

SLIDER
7
46
201
79
num-features
num-features
1
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
4
118
198
151
num-traits
num-traits
1
20
7.0
1
1
NIL
HORIZONTAL

BUTTON
138
10
201
43
Step
go
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
72
10
135
43
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
1

PLOT
449
46
765
273
Connected Regions
Time
Value
0.0
10.0
0.0
1.0
false
true
"" ""
PENS
"Number" 1.0 0 -16777216 true "" ""
"Largest" 1.0 0 -2674135 true "" ""

SLIDER
449
10
621
43
sample-interval
sample-interval
10
1000
370.0
10
1
NIL
HORIZONTAL

SLIDER
4
155
198
188
prob-event
prob-event
0
1
0.084
0.001
1
NIL
HORIZONTAL

SLIDER
5
192
198
225
prob-creator-gene
prob-creator-gene
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
6
82
199
115
fixed-features
fixed-features
0
num-features
0.0
1
1
NIL
HORIZONTAL

SWITCH
10
234
179
267
gradual-trait-update
gradual-trait-update
0
1
-1000

SWITCH
11
316
251
349
ignore-fixed-features-in-similarity
ignore-fixed-features-in-similarity
0
1
-1000

BUTTON
323
293
416
326
NIL
print-patch
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
417
347
520
380
NIL
calc-distance
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
530
347
627
380
NIL
clean-green
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
778
10
1045
552
11

SWITCH
11
274
162
307
gradual-centered
gradual-centered
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

Arunas. 2018-02-12
This is based on Robert Axelrod's model of cultural dissemination, as presented in "The Dissemination of Culture: A Model with Local Convergence and Global Polarization".


## HOW IT WORKS

Patches (here I use a concept "patch" instead of agent since it was in original description) are assigned a list of num-features integers which can each take on one of num-traits values. Each tag is called a feature, while it's value is called the trait. Some features may be fixed (like gender in real world). Fixed features configured using fixed-features

The links in the view represent walls between patches where solid black walls mean there is no cultural similarity, and white walls mean the neighbors have the same culture.

The order of actions is as follows:  
1) At random, pick a site to be active, and pick one of it's neighbors  
2) With probability equal to their cultural similarity, these sites interact. If interacting sites differ, active site changes it feature to be more compatible with selected neighbour. If gradual-trait-update is "On", the new feature value will change by half of distance (for this feature) between acting parties towards selected neighour. gradual-centered "On" means new value will be simple average of selected feature traits. When gradual-centered "Off" 0 and 7 in 8 trait setting have distance 1 (not 7)
3) At same step one of patches, that has creator gene (managed by prob-creator-gene) is asked to create an event (with probability prob-event). If it creates an event, the event will have same features/traits as creator. Every patch sees this event and decides to participate (based on same similarity measure as in 2 between neighbours). If, based on similarity, patch participates in event, it changes his traits to be more similar with creator (same logic as in 2)

The model ends when no further interactions can take place.

## HOW TO USE IT

First configure parameters and then press Setup. Setup assigns the patches random culture based on the num-features, fixed-features and num-traits sliders, and updates the walls between them.
prob-creator-gene is also needed to be setup for correct value before Setup. It is a probability of patch to be a creator (percentage of creators in population). Currently creators marked with light/soft red color.

By pressing "Step" you progress in one step. This allows to examine model values each step. 
Press "Go" button for continuous run (to stop press Go while it is marked/pressed state).
Model run until there exists only same culture or set of imcompatible culture (no borders and strong borders denoting clusters). The stronger color of boder the more imcompatible patches are. You can notice (usually using single Step) and patch that is an creator in particular step - it will have stronger red color (after step will change to previuos one).

You can inspect patches by pressing "Print patch", and while it is pressed state, clicking on patches in grid. The clicked patch becomes green and in right side in output, it features are printed (to clear selections in grin click - clean-greeen)
Calc-distance allows to examine distance between patch, click 2 patches (one by one) and there values and distance is provided in right output.

ignore-fixed-features-in-similarity - is used when fixed-features>0. When it is set to "On", borders in grid and cluster calculation ("Connected regions") will ignore fixed features. If it is off and fixed-features>0 then model usually never stops.

The plot "Connected Regions" has 2 pens. The black pen tracks the number of clusters of culturally identical patches, while the red pen tracks the size of the largest cluster. This is a time consuming algorithm for larger scale models, so the interval between updates is controlled by the sample-interval slider.

## MULTIPLE RUNS

Tools -> Behaviours space - there already set up experiment run. It takes more time since it runs simulations many times, varies combinations of parameters and results are outputed in csv file. Currently it outputs time steps until model converged to final state and how many clusters (connected reqions) there are in final state.

## CREDITS AND REFERENCES

Original paper
Robert Axelrod, "The Dissemination of Culture: A Model with Local Convergence and Global Polarization"  
Philip Ball - "Critical Mass"

Any suggestions or questions? e-mail: isw3@le.ac.uk
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
setup-square
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>calc-cluster</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="ignore-fixed-features-in-similarity">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-features">
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gradual-trait-update">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.28"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="0"/>
      <value value="0.6"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="370"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-features">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-traits">
      <value value="5"/>
      <value value="7"/>
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
