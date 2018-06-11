;extensions [r csv]
extensions [csv]
turtles-own [culture creator-gene inactivity-gene cluster ll custom-location]
globals [this-cluster max-cluster num-cluster num-cluster-bigger-than-x color-list g-fixed]

;ask turtle 29 [ask max-n-of neighbours-to-choose-from other turtles [similarity [culture] of myself culture] [set color green ]]

to setup
  clear-all
  setup-patches
  setup-turtles
  set g-fixed 1

  reset-ticks
end

to go
  tick
  peers-interaction
  make-event
 ; if ticks mod sample-interval = 0 [
 ;   update-plot
 ;   if auto-stop != "None"
 ;     [ifelse auto-stop = "Ticks"
 ;       [if ticks >= ticks-to-run [stop]]
 ;       [if ticks mod ( sample-interval * multiplier-for-stopping ) = 0 [if check-end? [stop]]]
 ;     ]
 ; ]
end

to setup-patches
  ask patches [ set pcolor white ]
end

to setup-turtles
  create-turtles num-agents
  ask turtles [
   ; setxy random-xcor random-ycor
    set shape "dot"
    set creator-gene (random-float 1 < prob-creator-gene)
    set inactivity-gene (random-float 1 < prob-inactivity-gene)
    set ll false
    ifelse creator-gene
      [set color green]
      [set color black]
    if inactivity-gene
    [set color red]
    set culture []
    set custom-location list random custom-location-scale random custom-location-scale

    set culture ( list ( rnd-culture-item distf meanf sdf )  ( rnd-culture-item dist1 mean1 sd1 ) ( rnd-culture-item dist2 mean2 sd2 ) ( rnd-culture-item dist3 mean3 sd3 ))
    update-position-for-turtle
  ]
end

to-report rnd-culture-item [dist m sd ]
  ifelse dist = "Uniform"
  [report random 100]
  [report random-normal-in-bounds m sd 0 100]
end

to-report random-normal-in-bounds [mid dev mmin mmax]
  let result random-normal mid dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds mid dev mmin mmax ]
  report result
end


to peers-interaction
  ask n-of interaction-neighbours-per-tick turtles
  [
    let culture-A []
    let turtle-A 0
    let location-A custom-location
    let culture-B []
    let turtle-B 0
    let P 0
    let d []
    set culture-A culture
   ; set color blue
    set turtle-A self
    ; selecting one of neighbours-to-choose-from closest turtles to him without himself
    ifelse random-float 1 < similar-over-neighbourhood
    [
      let peers max-n-of neighbours-to-choose-from other turtles [similarity culture-A culture]
      set turtle-B one-of peers
      ;ask peers [set color green]
    ]
    [
      let peers min-n-of neighbours-to-choose-from other turtles  [custom-distance custom-location location-A ]
      set turtle-B one-of peers
     ; ask peers [set color yellow]
    ]
    ask turtle-B
    [
      set culture-B culture
    ]
    ;output-print4 "selected cultureA" culture-A "selected culture B" culture-B
    set P similarity culture-A culture-B
    ;output-print2 "similarity between cultures" P
    if (P > 0 and P < 1) and random-float 1 < P [
      set culture new-culture culture-A culture-B 1
      update-position-for-turtle
    ]
  ]
end

to-report new-culture [c-obj c-trgt fixed]
  let l length c-obj
  report sentence ( sublist c-obj  0  fixed ) (move (sublist c-obj  fixed l) (sublist c-trgt fixed l) move-fraction)
end

to-report move [c-obj c-trg fraction]
  ;let dist custom-distance c-obj c-trg
  report ( map + ( map [ v -> v * fraction ] ( map - c-trg c-obj )) c-obj)
end

to make-event
  let p-event prob-event
  if (p-event > 0 and p-event <= 1) and random-float 1 < p-event  and prob-creator-gene > 0 [
    ;output-print "event today!"
    ask one-of turtles with [creator-gene]
    [
      let ev self
      let ev-location custom-location
      let culture-Event culture

      ask other turtles with [not inactivity-gene]
      [
        let P-similar 0
        let p-final 0

        set P-similar similarity culture-Event culture

        set p-final P-similar * ( distance-degrade-event custom-location ev-location )
        output-print4 "p-final" p-final "P-similar:" P-similar

        set p-final event-impact * p-final
        if (p-final > 0 and p-final < 1) and random-float 1 < p-final
        [
          set culture new-culture culture culture-Event 1
          update-position-for-turtle
        ]]]]
end


to-report similarity-wo-fixed [list-A list-B]
  let l (length list-A)
  report similarity (sublist list-A 1 l) (sublist list-B 1 l)
end

to-report distance-degrade-event [p-location event-location]
  let r 0
  if ( event-distance-impact = "None" )
  [
    set r 1
  ]
  if ( event-distance-impact = "Linear World Distance" )
  [
    set r  ( 1 -  ( ( custom-distance p-location event-location ) / (max-world-dist (list custom-location-scale custom-location-scale) ) ) )
  ]
  if ( event-distance-impact = "Distance squared" )
  [
    set r ( 1 / ( ( 1 +  ( custom-distance p-location event-location )  ) ^ 2 ) )
  ]
  if ( event-distance-impact = "Distance exponential" )
  [
    set r ( 1 / (  exp  ( custom-distance p-location event-location ) ) )
  ]
  output-print1 (list "dg" p-location event-location r)
  report r
end


to-report similarity [list-A list-B]
  let l length list-A
  report 1 - ( custom-distance list-A list-B )  / ( max-world-dist n-values l [100] )
end


; just helper to have less lines if we want check some value in output print
to output-print4 [par1 par2 par3 par4]
  if verbose
  [
    output-print2 par1 par2
    output-print2 par3 par4]
end
to output-print2 [par1 par2]
  if verbose [
  output-print par1
    output-print par2]
end
to output-print1 [par1]
  if verbose [
  output-print par1
  ]
end
to-report calc-cluster
  find-clusters
  report num-cluster
end

to update-plot
  find-clusters
  set-current-plot "Culture clustering"
  set-plot-x-range 0 ticks
  set-plot-y-range 0 num-agents
  set-current-plot-pen "Number"
  plotxy ticks num-cluster
  set-current-plot-pen "Largest"
  plotxy ticks max-cluster
  set-current-plot-pen ">xthr"
  plotxy ticks num-cluster-bigger-than-x

  ;set-color
end

to find-clusters
  set max-cluster 0
  set num-cluster 0
  set num-cluster-bigger-than-x 0
  let seed one-of turtles
  ask turtles [set cluster nobody]
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
    if this-cluster > xthr [set num-cluster-bigger-than-x num-cluster-bigger-than-x + 1]
    set seed one-of turtles with [cluster = nobody]
    ]
end

to grow-cluster
  ask other turtles with [(cluster = nobody) and (similar-cultures? culture [culture] of myself)]
    [
    set this-cluster this-cluster + 1
    set cluster [cluster] of myself
    ]
end

to-report similar-cultures? [list-A list-B]
  report (similarity-wo-fixed list-A list-B) = 1
end

to-report check-end?
  let end? true
  ifelse num-cluster = 1
   [ set end? true ]
   [ ask turtles [
      let turtle-A 0
      let culture-A []
      set turtle-A self
      set culture-A culture
      ask min-n-of neighbours-to-choose-from other turtles [distance turtle-A] [set ll true]
      let stopped false
      ifelse inactivity-gene = false
      [ask other turtles with [ (creator-gene or ll) and (cluster != [cluster] of turtle-A) ] [
       let P -1
       let d -1
       let culture-B []
       set culture-B culture
       set P similarity culture-A culture-B
       ;ifelse use-event-distance [
       ; set d P * ( rev-prob-linear-from-max (distance turtle-A) max-distance-in-world )
       ;] [
      ;  set d P
       ;]
       if ( P != 0 and creator-gene = false ) or ( d * event-impact != 0 and ll = false ) or ( ( P != 0 or d * event-impact != 0 ) and ( creator-gene = true and ll = true ) ) [
        set end? false
        set stopped true
        stop
       ]
      ]
     ]
     [ask other turtles with [ ll and (cluster != [cluster] of turtle-A) ] [
       let P -1
       let culture-B []
       set culture-B culture
       set P similarity culture-A culture-B
       if P != 0 [
        set end? false
        set stopped true
        stop
       ]
      ]
     ]
     ask other turtles with [ll] [set ll false]
     if stopped [stop]
    ]
   ]
  report end?
end

to update-position-all
  ask turtles
  [
    update-position-for-turtle
  ]
end

to update-possition-all2
  if (display-dimensions = "1-2")
  [
    set-x-vars [1 0 0]
    set-y-vars [0 1 0]
  ]
  if (display-dimensions = "1-3")
  [
    set-x-vars [1 0 0]
    set-y-vars [0 0 1]
  ]
  if (display-dimensions = "2-3")
  [
    set-x-vars [0 1 0]
    set-y-vars [0 0 1]
  ]

  update-position-all
end

to set-x-vars [l]
  set var1-x item 0 l
  set var2-x item 1 l
  set var3-x item 2 l
end


to set-y-vars [l]
  set var1-y item 0 l
  set var2-y item 1 l
  set var3-y item 2 l
end

to update-position-for-turtle
    let r calc-position-for-turtle self
    setxy item 0 r item 1 r
end

to-report calc-position-for-turtle [trtl]
  let c [sublist culture g-fixed (length culture) ] of trtl
  report list calc-position-x c  calc-position-y c
end


to-report calc-position-x
  [l]
  report ( world-width * ( (item 0 l / 100 ) *  var1-x +  (item 1 l / 100) * var2-x + (item 2 l / 100 ) * var3-x ) / ( var1-x +  var2-x +  var3-x  ) )  - world-width / 2
end

to-report calc-position-y
  [l]
  report ( world-height * ( (item 0 l / 100) * var1-y +  (item 1 l / 100) * var2-y + (item 2 l / 100) * var3-y ) / ( var1-y +  var2-y +  var3-y  ) ) - world-height / 2
end

to-report custom-distance
  ;custom euclidian distance
  [l1 l2]
  report (sqrt ( reduce + ( map [ i -> i ^ 2] ( map - l1 l2 ) ) ) )
end

to-report max-world-dist [l]
  ; param list with scale of each coordinate
  report (sqrt ( reduce + ( map [ i -> i ^ 2] l ) ) )
end

to export-csv
  let l (length [culture] of one-of turtles)
  csv:to-file "myfile.csv" [sublist culture 1 l] of turtles
end
@#$#@#$#@
GRAPHICS-WINDOW
213
10
650
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
12
14
75
47
NIL
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
53
179
86
num-agents
num-agents
2
1000
432.0
10
1
NIL
HORIZONTAL

SLIDER
201
462
373
495
prob-creator-gene
prob-creator-gene
0
1
0.15
0.01
1
NIL
HORIZONTAL

OUTPUT
1402
47
1777
502
11

BUTTON
79
13
142
46
NIL
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

SLIDER
390
455
617
488
interaction-neighbours-per-tick
interaction-neighbours-per-tick
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
145
13
208
46
step
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

SLIDER
200
534
372
567
prob-event
prob-event
0
1
0.98
0.01
1
NIL
HORIZONTAL

SLIDER
661
14
833
47
sample-interval
sample-interval
10
1000
660.0
10
1
NIL
HORIZONTAL

SWITCH
1397
10
1500
43
verbose
verbose
1
1
-1000

SLIDER
1087
12
1259
45
xthr
xthr
0
20
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
791
619
941
637
NIL
11
0.0
1

SLIDER
198
571
370
604
event-impact
event-impact
0
1
0.99
0.01
1
NIL
HORIZONTAL

SLIDER
390
494
584
527
neighbours-to-choose-from
neighbours-to-choose-from
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
200
498
372
531
prob-inactivity-gene
prob-inactivity-gene
0
1
0.11
0.01
1
NIL
HORIZONTAL

SLIDER
12
261
184
294
mean1
mean1
0
100
32.0
1
1
NIL
HORIZONTAL

SLIDER
12
295
184
328
sd1
sd1
0
100
15.5
0.5
1
NIL
HORIZONTAL

SLIDER
11
381
183
414
mean2
mean2
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
11
417
183
450
sd2
sd2
0
100
17.0
0.5
1
NIL
HORIZONTAL

SLIDER
10
506
182
539
mean3
mean3
0
100
54.0
1
1
NIL
HORIZONTAL

SLIDER
9
542
181
575
sd3
sd3
0
100
16.0
0.5
1
NIL
HORIZONTAL

SLIDER
851
14
1023
47
multiplier-for-stopping
multiplier-for-stopping
1
100
1.0
1
1
NIL
HORIZONTAL

CHOOSER
1088
66
1226
111
auto-stop
auto-stop
"None" "Ticks" "Condition"
2

SLIDER
852
63
1024
96
ticks-to-run
ticks-to-run
100
100000
2000.0
100
1
NIL
HORIZONTAL

PLOT
657
272
1225
655
plot traits
NIL
NIL
0.0
100.0
0.0
102.0
true
true
"" ""
PENS
"1st " 1.0 0 -16777216 true "" "  plot-pen-reset\n  histogram [item 1 culture] of turtles"
"2nd" 1.0 0 -7500403 true "" "  plot-pen-reset\n  histogram [item 2 culture] of turtles"
"3rd" 1.0 0 -2674135 true "" "  plot-pen-reset\n  histogram [item 3 culture] of turtles\n  "

SLIDER
434
581
639
614
similar-over-neighbourhood
similar-over-neighbourhood
0
1
0.94
0.01
1
NIL
HORIZONTAL

SLIDER
433
543
605
576
custom-location-scale
custom-location-scale
0
100
12.0
1
1
NIL
HORIZONTAL

SLIDER
1234
116
1386
149
var1-x
var1-x
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1235
156
1386
189
var2-x
var2-x
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1235
196
1388
229
var3-x
var3-x
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1238
250
1389
283
var1-y
var1-y
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1238
290
1390
323
var2-y
var2-y
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1239
330
1390
363
var3-y
var3-y
0
1
0.0
0.01
1
NIL
HORIZONTAL

BUTTON
1240
377
1374
410
NIL
update-position-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
11
213
184
258
dist1
dist1
"Uniform" "Normal"
0

CHOOSER
11
334
183
379
dist2
dist2
"Uniform" "Normal"
0

CHOOSER
11
458
184
503
dist3
dist3
"Uniform" "Normal"
0

PLOT
677
101
1081
268
Culture clustering
Time
Value
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Number" 1.0 0 -16777216 true "" ""
"Largest" 1.0 0 -2674135 true "" ""
">xthr" 1.0 0 -15040220 true "" ""

CHOOSER
10
90
148
135
distf
distf
"Uniform" "Normal"
0

SLIDER
10
136
182
169
meanf
meanf
0
100
54.0
1
1
NIL
HORIZONTAL

SLIDER
10
173
182
206
sdf
sdf
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
9
616
181
649
move-fraction
move-fraction
0
1
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
199
608
368
653
event-distance-impact
event-distance-impact
"None" "Linear World Distance" "Distance squared" "Distance exponential"
3

BUTTON
1264
568
1356
601
NIL
export-csv
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1242
421
1380
466
display-dimensions
display-dimensions
"1-2" "1-3" "2-3"
0

BUTTON
1244
477
1391
510
NIL
update-possition-all2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

Similar to axelrod model, however turtles are used instead of patches.

## HOW IT WORKS

During setup turtles are placed randomly and assigned random culture (array of features). During each step turtles interact (neighbors) and event potentialy generated by creator that affects all agents. Interaction and events changes culture similar way as in axelrod model

## HOW TO USE IT

First configure parameters and then press Setup. Setup assigns the patches random culture based on the num-features, fixed-features and num-traits sliders, and updates the walls between them.
prob-creator-gene, prob-inactivity-gene also are needed to be configured for correct value before Setup. It is a probabilities of turtle to be a creator (percentage of creators in population) and ignorant for any culture events.


By pressing "Step" you progress in one step. This allows to examine model values each step. 
Press "Go" button for continuous run (to stop press Go while it is marked/pressed state).
Model run until there exists only same culture or set of imcompatible culture (no borders and strong borders denoting clusters). The stronger color of boder the more imcompatible patches are. You can notice (usually using single Step) and patch that is an creator in particular step - it will have stronger red color (after step will change to previuos one).

Parameters:
num-agents  - number of agents that will be created
num-features - number of features each agent will have (features have values and define culture)
fixed-features - number of features is given initially and won't change during simulation
num-traits - traits define how how many different values each feature can have
prob-creator-gene - probability that agent is creator. Only creators create culture events
prob-inactivity-gene - probability that agent is iqnorant to any cultural events
prob-event - probability of event in each step. When creator is selected, whether it emit an event depends on this value
event-impact - allows lower impact of event. Probability of agent to participate in cultural event is based on many factors (ex. cultural similarity) and finally it will be additionaly multiplied by this value
gradual-trait-update - when on agent update its trait not by changing value, but by incrementing toward "leader"
use-event-distance - to take into account distance from event
color-track - whether track color - don't works well.
reset-color - when pressed colors in different colors clusters with same culture that are size bigger than xthr. Color application to cluster is random each time, doesn't keeps previous color of cluster
interaction-neighbours-per-tick - how many agents will interact per step (as neighbors) 
neighbours-to-choose-from - how many neighbors are candidates for interaction. Each step chosen agents looks among closest neighbors (number is set by this value) for interaction and each will select only one.
turtle-size - size of turtle on model
update-size - to update model according turtle-size  value

check-incompatible-cultures - prints incompatible cultures, if there are such cultures. Print in ouptut field
sample-interval - how often to check for clusters and for model termination. It slows model there and is tradeoff: should be big enough for performance, but low enough to have accurate data in plot
xthr - threshlod to calculate clusters bigger that this value. Used in plot and colouring. If changed during run, affects line in plot.
verbose - whether additional info is printed in output field. For debug purposes. Normally should be off.

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>max-cluster</metric>
    <metric>num-cluster</metric>
    <metric>num-cluster-bigger-than-x</metric>
    <enumeratedValueSet variable="prob-event">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-features">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gradual-trait-update">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turtle-size">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-event-distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-traits">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-track">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-features">
      <value value="1"/>
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
