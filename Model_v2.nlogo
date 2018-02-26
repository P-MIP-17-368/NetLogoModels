turtles-own [culture creator-gene cluster]
globals [this-cluster max-cluster num-cluster num-cluster-bigger-than-x color-list]

to setup
  set-color-list
  clear-all
  setup-patches
  setup-turtles
  reset-ticks
end

to go
  tick
  neighbours-interaction
  make-event
  if ticks mod sample-interval = 0 [ update-plot ]
end

to setup-patches
  ask patches [ set pcolor white ]
end

to setup-turtles
  create-turtles num-agents
  ask turtles [
    setxy random-xcor random-ycor
    set shape "dot"

    set creator-gene (random-float 1 < prob-creator-gene)
    ifelse creator-gene
      [set color black]
      [set color black]
    set culture []
    repeat num-features
      [ set culture fput random num-traits culture ]
  ]
end

to neighbours-interaction
  ask n-of interaction-neighbours-per-tick turtles
  [
    let culture-A []
    let turtle-A 0
    let culture-B []
    let turtle-B 0
    let P 0
    let d []
    set culture-A culture
    ;set color blue
    set turtle-A self
    ; selecting one of 10 closest turtles to him without himself
    ask one-of min-n-of 10 other turtles [distance turtle-A]
    [
      set culture-B culture
      set turtle-B self
      ;set color green
    ]
    ;output-print4 "selected cultureA" culture-A "selected culture B" culture-B
    set P similarity culture-A culture-B
    ;output-print2 "similarity between cultures" P
    if (P > 0 and P < 1) and random-float 1 < P[

      ; get list with differences - indexes of items that don't match
      set d list-different-item-indexes culture-A culture-B
     ; output-print2 "diferences between cultures culture" culture-A
      if  length d > 0
      [
        let i one-of d
        set culture replace-item i culture updated-item-value (item i culture-A) (item i culture-B)
        if color-track [ update-clustering self ]
        output-print2 "updating culture" culture
    ]]
  ]
end

to make-event
  let p-event prob-event
  if (p-event > 0 and p-event <= 1) and random-float 1 < p-event  and prob-creator-gene > 0 [
    ;output-print "event today!"
    ask one-of turtles with [creator-gene]
    [
      let ev self
      let culture-Event []
      let culture-B []
      let turtle-B 0
      let d []
      set culture-Event culture
      ask other turtles
      [
        let P-similar 0
        let p-final 0
        set culture-B culture
        set turtle-B self
        set P-similar similarity culture-Event culture-B
        ifelse use-event-distance [
          output-print2 "distance" distance ev
          set p-final P-similar * ( rev-prob-linear-from-max (distance ev) max-distance-in-world )
          output-print4 "p-final" p-final "P-similar:" P-similar
        ][
          set p-final P-similar
        ]
        if (p-final > 0 and p-final < 1) and random-float 1 < p-final
        [
          set d list-different-item-indexes culture-B culture-Event
          if length d > 0
          [
            output-print2 "updating patch by event! old culture:" culture-B
            let i one-of d
            set culture replace-item i culture updated-item-value (item i culture-B) (item i culture-Event)
            if color-track [update-clustering self]
            output-print2 "updating patch by event! new culture:" culture
          ]
        ]
    ]
    ]

 ]
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

to-report list-different-item-indexes [list-A list-B]
  let n 0
  let differences []
  repeat length list-A
    [
    if (item n list-A != item n list-B) and (n >=  fixed-features)
      [set differences lput n differences]
    set n n + 1
    ]
  report differences
end

to-report updated-item-value [obs-val source-val]
  ifelse gradual-trait-update = "Centered"
  [report  round (obs-val + (( source-val - obs-val ) / 2) )] ; "Centered" option
  [ifelse gradual-trait-update = "Wrapped"
    [report add-around obs-val source-val  num-features]  ; "Continous" option
    [report source-val] ; else "None" also
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

to-report rev-prob-linear-from-max [val max-val]
  report 1 - val / max-val
end
; calculare max posiible ditance in this world
to-report max-distance-in-world
  report sqrt ( ( world-width / 2) ^ 2 + ( world-height / 2 ) ^ 2 )
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
  ifelse ignore-fixed-features-in-similarity
  [report (similarity-wo-fixed list-A list-B) = 1]
  [report (similarity list-A list-B) = 1]
end

; calculation - how many incompatible cultures in model (not used in simulation - maybe invoked from command center)
; return list of 2 elements: first how many culturally incompatible (similarity = 0) clusters, seconds the lowest cultural similarity among agent
to-report incompatible-cultures
  find-clusters
  let inc 0
  let m 1
  ask one-of turtles [
    let c culture
    let clst cluster
    if any? other turtles with [cluster != clst and (similarity-wo-fixed c culture) = 0] [set inc inc + 1]
    ask other turtles with [cluster != clst]
    [
      let s similarity-wo-fixed c culture
      if s < m [set m s]
    ]
  ]
  report list inc m
end

to check-incompatible-cultures
  let r incompatible-cultures
  output-print "count of incompatible cultures:"
  output-print first r
  output-print "lowest compatibility"
  output-print last r
end

to color-cluster [clstr c]
  ask turtles with [cluster = clstr]
  [set color c]
end

;remove-duplicates [cluster-who cluster] of turtles



to-report cluster-who [c]
  report [who] of [cluster] of c
end

to-report culture-flex [c]
  report sublist c fixed-features num-features
end

to dos
  find-clusters
  foreach filter-occurs-lessthan 10 [cluster-who cluster] of turtles
  [x ->
    show culture-flex turtle x
  ]
end

to-report filter-occurs-lessthan [x lst]
  let i 0
  let c nobody
  let res []
  foreach sort lst
  [
    v ->
    ;show v
      ifelse c = v [
        set i i + 1
    ][
      if i >= x and c != nobody [
          set res lput c res
      ]
      set c v
      set i 1
    ]
  ]
  if i >= x [
    set res lput c res
  ]
  report res
end

to-report gen-color-list
  let il (range 1 14)
  report sentence (shuffle  map [x -> x * 10 + 5] il)  shuffle (sentence map [x -> x * 10 + 1] il   (map [x -> x * 10 + 8] il))
end

to set-color-list
  set color-list gen-color-list
end

to-report filter-list-by-second [list1 list2]
  report filter [x -> not member? x list2 ] list1
end

to-report take-color-from-list

  if empty? color-list [
    set color-list filter-list-by-second gen-color-list remove-duplicates [color] of turtles
    output-print2 "color list updated" color-list
  ]
  let c first color-list
  set color-list but-first color-list
  output-print2 "taken color form list" c
  report c
end

to update-clustering [t]
  ask t [
    output-print2 "update-clustering 4 turtle" t
    let v-color black
    let v-culture culture
    let v-cluster cluster
  ;  if culture-flex v-culture != culture-flex [culture] of v-cluster [

    ; first need to update cluster agent was a member before
    ifelse v-cluster = self
    ; need update whole cluster when it points to himself
    [
      output-print2 "cluster - himself" v-cluster
      ; get agents that are pointing to this cluster
      let agent-set other turtles with [cluster = v-cluster]
      ifelse not any? agent-set  [
        output-print2 "no more with cluster, setting black" v-cluster
        set color black
      ][
        ; there more agents - update them.
      ; check whether they need to be coloured
      ifelse count agent-set > xthr [
      ; if among them exists any not black
        ifelse any? agent-set with [color != black] [
          set v-color [color] of one-of agent-set with [color != black]
          output-print2 "taking from agent color" v-color
        ][;if all are black then take new color
          set v-color take-color-from-list
          output-print2 "all black. take color" v-color
      ]][
        output-print2 "setting black" v-cluster
        ask agent-set [set color black]
      ]
    ]
      ask agent-set [
        set color v-color
        set cluster one-of agent-set
    ]][
      ;if cluster point elsewhere then need check whether old cluster is not to small to be coloured. If so color to black
      output-print2 "cluster - other" v-cluster
    if any? other turtles with [cluster = v-cluster and color != black] [
      let agent-set-other other turtles with [cluster = v-cluster]
      if count agent-set-other <= xthr  [ask agent-set-other [set color black]]
    ]]

    ; then we update our new cluster. find new cluster by culture
      ifelse any? other turtles with [culture-flex culture = culture-flex v-culture] [
        set v-cluster [cluster] of one-of turtles with [culture-flex culture = culture-flex v-culture]
        set cluster v-cluster
        set color [color] of v-cluster
      output-print4 "taken from" v-cluster "color" color
      if color = black        [ let agent-set other turtles with [cluster = v-cluster]
        if  any? agent-set and count agent-set  > xthr [
          set v-color take-color-from-list
          output-print4 "lengt agent set > x" count agent-set "taking color" v-color
          ask agent-set [ set color v-color ]
    ]]]
      [ ; if nothing we it is own cluster
        set v-cluster self
        set cluster v-cluster
        set color black]

  ]
  ;]
end

to set-color
  find-clusters
  let cluster-list []
  set cluster-list filter-occurs-lessthan xthr [cluster-who cluster] of turtles
  if length color-list < 40
  [set color-list sentence color-list gen-color-list]
  if num-cluster-bigger-than-x < 50
  [
    foreach cluster-list
      [x ->
        let c nobody
        ifelse any? turtles with [cluster = turtle x and color != black]
        [set c [color] of one-of turtles with [cluster = turtle x and color != black]
        output-print2 "found color from cluster" c ][
          set c take-color-from-list
        ]
        ask turtles with [cluster = turtle x] [
        set color c
      ]
   ]]
end

to reset-color
  set color-list []
  ask turtles [set color black]
  set-color
end

to update-size
  ask turtles [set size  turtle-size]
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
1
1
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
13
75
46
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
12
63
184
96
num-agents
num-agents
2
1000
882.0
10
1
NIL
HORIZONTAL

SLIDER
12
103
184
136
num-features
num-features
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
11
181
183
214
num-traits
num-traits
1
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
10
220
182
253
prob-creator-gene
prob-creator-gene
0
1
0.22
0.01
1
NIL
HORIZONTAL

SLIDER
12
142
184
175
fixed-features
fixed-features
0
num-features
0.0
1
1
NIL
HORIZONTAL

CHOOSER
13
306
151
351
gradual-trait-update
gradual-trait-update
"None" "Centered" "Wrapped"
0

OUTPUT
1269
45
1644
500
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
266
451
493
484
interaction-neighbours-per-tick
interaction-neighbours-per-tick
0
100
62.0
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
9
257
181
290
prob-event
prob-event
0
1
0.22
0.01
1
NIL
HORIZONTAL

SWITCH
7
451
247
484
ignore-fixed-features-in-similarity
ignore-fixed-features-in-similarity
0
1
-1000

SLIDER
661
14
833
47
sample-interval
sample-interval
10
1000
90.0
10
1
NIL
HORIZONTAL

PLOT
661
62
1263
515
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

SWITCH
1326
10
1429
43
verbose
verbose
1
1
-1000

MONITOR
837
12
915
57
NIL
num-cluster
17
1
11

SLIDER
928
15
1100
48
xthr
xthr
0
20
14.0
1
1
NIL
HORIZONTAL

SWITCH
14
361
177
394
use-event-distance
use-event-distance
0
1
-1000

SWITCH
13
493
127
526
color-track
color-track
1
1
-1000

BUTTON
12
532
104
565
NIL
reset-color
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
133
531
305
564
turtle-size
turtle-size
0.4
2
0.6
0.1
1
NIL
HORIZONTAL

BUTTON
314
533
410
566
NIL
update-size
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
450
530
634
563
NIL
check-incompatible-cultures
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

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

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
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
