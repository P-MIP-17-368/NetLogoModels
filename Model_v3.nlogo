;extensions [r csv]
extensions [csv]
turtles-own [culture creator-gene inactivity-gene cluster ll custom-location soc-capital last-random-event last-p-final last-peer-interacted last-peer-interaction-step last-peer-ineraction-results ]
;custom-location - each agent has location, that doesn't change
; last-random-event - just for testing purposes - stores last random generated number which is used to determine participation in event

globals [this-cluster max-cluster num-cluster num-cluster-bigger-than-x color-list g-fixed last-event-participants-count avg-last-p-final-peer avg-last-p-final-event o-file export-file interaction-discount-weights ]

;ask turtle 29 [ask max-n-of neighbours-to-choose-from other turtles [similarity [culture] of myself culture] [set color green ]]

to setup
  clear-all
  set export-file ( word "res-" behaviorspace-run-number ".csv" )
  if file-exists? export-file [ file-delete export-file]
  setup-patches
  setup-turtles
  reset-ticks
end

to go
  tick
  if recalc-world-interval > 0 and ticks mod recalc-world-interval = 0   [recalc-world]
  peers-interaction
  make-event
  if sample-interval > 0 and ticks mod sample-interval = 0 and length(export-file) > 3
  [
    world-to-file
    if save-world-png [export-view (word ticks ".png") ]
  ]
  strive-uniqueness
  if color-cap [set-color-on-cap]
end

to setup-patches
  ask patches [ set pcolor white ]
end

to setup-turtles
  create-turtles num-agents

  set interaction-discount-weights n-values history-size [ i -> interaction-history-discount ^ i]

  ask turtles [
   ; setxy random-xcor random-ycor
    set shape "dot"
    set creator-gene (random-float 1 < prob-creator-gene)
    set inactivity-gene (random-float 1 < prob-inactivity-gene)
    set ll false

  ;  set soc-capital-inner (random-float 2) - 1
    set last-peer-ineraction-results n-values history-size [ random-int-bool soc-capital-init ]
    set soc-capital weighted-average last-peer-ineraction-results interaction-discount-weights
    set culture []
    set custom-location list random custom-location-scale random custom-location-scale

    set culture []
    repeat num-features [
      set culture fput random 100 culture ]
    update-position-for-turtle
  ]
  reset-colors
end

to reset-colors
  ask turtles [
        ifelse creator-gene
      [set color green]
      [set color black]
    if inactivity-gene
    [set color red]
  ]
end
to set-color-on-cap
ask turtles
  [
    set color p-to-color5 soc-capital
  ]
end
to-report p-to-color5 [p]
  report ( ( round ( p * 10 ) * 10)  + 5 )
end

to-report random-int-bool [v]
  ifelse random-float 1 < v [ report 1] [report 0]
end

to recalc-world
  let i 0
   repeat 4
  [recal-dimension i
  set i i + 1]
  update-position-all
end

to recal-dimension [i]
  let min-v min [item i culture] of turtles
  let max-v max [item i culture] of turtles
  let world-d (max-v - min-v) + 2
  ask turtles [
    let new-v ( (item i culture) - min-v ) * 100 / world-d
    set culture ( replace-item i culture new-v )
  ]
end

to turtle-strive-uniqueness
 ; procedure for turtle
  output-print1 who

  let peers []

  ifelse random-float 1 < similar-over-neighbourhood [
    set peers max-n-of neighbours-to-choose-from other turtles [similarity [culture] of myself culture]
  ][
    set peers min-n-of neighbours-to-choose-from other turtles  [custom-distance custom-location [custom-location] of myself]
  ]
  output-print1 [who] of peers
  let ds map [x -> exp ((similarity culture x) - 1 ) ] ( [culture] of peers )
  output-print1 ds
  let d c-uniqueness * ( sum ds )  / neighbours-to-choose-from
  let dl max ( list 0 min ( list 1 d ) )
  output-print1 list d dl
  set culture mutate-random-culture-feature culture dl
  ;if random-float 1 < d
  ;[set culture new-culture-neg culture [culture] of one-of peers]
  output-print1 (list who culture d [culture] of peers)
  ;let ssl sum ( map [x -> exp ( - x )] sl )

end

to strive-uniqueness
  if uniqueness-seekers-per-tick > 0 [
    ask n-of uniqueness-seekers-per-tick turtles [
      turtle-strive-uniqueness
    ]
  ]
end



to peers-interaction
  let var-avg-last-p-final-peer 0
  if interaction-neighbours-per-tick > 0
  [

  ask n-of interaction-neighbours-per-tick turtles
  [
    let culture-A []
    let turtle-A 0
    let location-A custom-location
    let culture-B []
    let turtle-B 0
    set last-p-final 0
    let d []
    set culture-A culture
   ; set color blue
    set turtle-A self
    ifelse random-float 1 < random-peer-interaction-prob
    [
      set turtle-B one-of other turtles
    ]
    [
      ; selecting one of neighbours-to-choose-from closest turtles to him without himself
      ifelse random-float 1 < similar-over-neighbourhood
      [ ;similar
        let peers max-n-of neighbours-to-choose-from other turtles [similarity culture-A culture]
        set turtle-B one-of peers
        ;ask peers [set color green]
      ]
      [;neighbours
        let peers min-n-of neighbours-to-choose-from other turtles  [custom-distance custom-location location-A ]
        set turtle-B one-of peers
        ; ask peers [set color yellow]
      ]
    ]
    ask turtle-B
    [
      set culture-B culture
      set last-peer-interacted turtle-A
      set last-peer-interaction-step ticks
    ]
    set last-peer-interacted turtle-B
    set last-peer-interaction-step ticks
    ;output-print4 "selected cultureA" culture-A "selected culture B" culture-B
    let similar ( similarity culture-A culture-B )
    ;set last-p-final peer-restric-filter * ( apply-soc-capital-effect similar (list soc-capital [soc-capital] of turtle-B ) )
    ;set last-p-final peer-restric-filter * ( apply-soc-capital-effect similar (list soc-capital ) ) ; jei tik inicijatoriaus soc kapitalas svarbu
    set last-p-final ( apply-soc-capital-effect similar (list soc-capital ) )
   ;set last-random-event random-float 1
    set last-random-event random-float 1
    set var-avg-last-p-final-peer var-avg-last-p-final-peer + last-p-final
    ;output-print2 "similarity between cultures" P
    if (last-p-final < 0 or last-p-final > 1) [error ( word "last-p-final out of bounds" last-p-final ) ]
    ifelse  last-random-event  < last-p-final [
      set culture new-culture culture-A culture-B
      turtle-update-interaction-results 1
      update-position-for-turtle
      if change-shape [ set shape "face happy"]
      ask turtle-B [
        turtle-update-interaction-results 1
        if change-shape [ set shape "face happy"]
        ]
    ] [
      ; additionaly check when distancing needs to applied and apply
      turtle-update-interaction-results 0
      if change-shape [ set shape "face neutral"]
      if ( negative-impact-prob > random-float 1 )  [
          set culture new-culture-neg culture-A culture-B
          update-position-for-turtle
          if change-shape [ set shape "face sad"]
        ]
      ask turtle-B [
        turtle-update-interaction-results 0
        if change-shape [ set shape "face neutral"]
        ]
    ]
  ]
  set avg-last-p-final-peer var-avg-last-p-final-peer / interaction-neighbours-per-tick
  ]
end

to turtle-update-interaction-results [res]
    set last-peer-ineraction-results fput res but-last last-peer-ineraction-results
    set soc-capital weighted-average last-peer-ineraction-results interaction-discount-weights
end


to-report apply-soc-capital-effect [p lst-soc-cap]
  report   p * ( 1 - social-capital-weight) +  social-capital-weight * ( mean lst-soc-cap )
end

to-report new-culture [c-obj c-trgt]
  let fixed fixed-features
  let l length c-obj
  report sentence ( sublist c-obj  0  fixed ) (move (sublist c-obj  fixed l) (sublist c-trgt fixed l) move-fraction)
end

; this makes distancing, by some fraction
to-report new-culture-neg [c-obj c-trgt]
  let fixed fixed-features
  let l length c-obj
  report sentence ( sublist c-obj  0  fixed ) (move (sublist c-obj  fixed l) (sublist c-trgt fixed l) ( - move-fraction) )
end

to-report mutate-random-culture-feature [c-obj vr]
  let fixed fixed-features
  let l length c-obj
  let i ( random l - fixed ) + fixed
  let oldval ( item i c-obj )
  let newval keep-in-bounds-pure ( oldval + random-normal 0 ( vr * 100) ) 0 100
  report replace-item i c-obj newval
end


to-report move [c-obj c-trg fraction]
  ;let dist custom-distance c-obj c-trg
  report ( map [ x ->  keep-in-bounds x 0 100 ]  ( map + ( map [ v ->  v * fraction  ] ( map - c-trg c-obj )) c-obj) )
end

to-report keep-in-bounds [val min-val max-val]
  ifelse recalc-world-interval > 0
  [report val]
  [report keep-in-bounds-pure val min-val max-val]
end

to-report keep-in-bounds-pure [val min-val max-val]
  report  max (list min-val  ( min (list max-val val) ))
end


to make-event
  let p-event prob-event
  let var-avg-last-p-final-event  0
  let participants-count 0
  if (p-event > 0 and p-event <= 1) and random-float 1 < p-event  and prob-creator-gene > 0 [
    ;output-print "event today!"
    ask one-of turtles with [creator-gene]
    [
      if change-shape [ set shape "star" ]
      ask other turtles with [not inactivity-gene]
      [
        let P-similar 0
        set last-p-final 0
        set P-similar similarity  ( [culture] of myself) culture
        let distance-effect  1
        ifelse cultural-distance
            [set distance-effect distance-degrade-event culture [culture] of myself]
            [set distance-effect distance-degrade-event custom-location [custom-location] of myself]
        ifelse distance-effect = 0
           [set last-p-final 0]
           [set last-p-final  ( event-impact * P-similar * distance-effect * (1 - social-capital-weight)  ) +  ( social-capital-weight * soc-capital )]
        output-print4 "p-final" last-p-final "P-similar:" P-similar

        set last-random-event random-float 1
        set var-avg-last-p-final-event var-avg-last-p-final-event + last-p-final
        if (last-p-final > 0 and last-p-final < 1) and last-random-event < last-p-final
        [
          if change-shape [ set shape "triangle" ]
          set culture new-culture culture ( [culture] of myself)
          update-position-for-turtle
          set participants-count participants-count + 1
        ]]]]

  set last-event-participants-count participants-count
  set avg-last-p-final-event var-avg-last-p-final-event / ( num-agents - 1)
end

to-report report-distance-effect [agent1 agent2]
  ifelse cultural-distance
    [report distance-degrade-event [culture] of agent1 [culture] of agent2]
  [report distance-degrade-event [custom-location] of agent1 [custom-location] of agent2]
end


to-report similarity-wo-fixed [list-A list-B]
  let l (length list-A)
  report similarity (sublist list-A 1 l) (sublist list-B 1 l)
end

to-report linear-world-distance-impact [loc-1 loc-2]
  let p-max-world-dist max-world-dist (list custom-location-scale custom-location-scale)
  if cultural-distance
    [set p-max-world-dist max-world-dist (list 100 100 100)]
  report  1 -  ( ( custom-distance loc-1 loc-2 ) / p-max-world-dist )
end

to-report distance-squared-impact [loc-1 loc-2]
  let p linear-world-distance-impact loc-1 loc-2
  ifelse ( 1 - p ) > event-impact-radius
  [report 0]
  [report  p  ^ 2]
end

to-report distance-exponential-impact[loc-1 loc-2]
  report  exponential-impact ( linear-world-distance-impact loc-1 loc-2 )
end

to-report exponential-impact[v]
  report  1 / (  exp  ( ( 1 -  v ) * event-exp-impact-scale ) )
end

to-report distance-degrade-event [p-location event-location]
  let r 0
  if ( event-distance-impact = "None" )
  [
    set r 1
  ]
  if ( event-distance-impact = "Linear World Distance" )
  [
    set r linear-world-distance-impact p-location event-location
  ]
  if ( event-distance-impact = "Distance squared" )
  [
    set r distance-squared-impact p-location event-location
  ]
  if ( event-distance-impact = "Distance exponential" )
  [
    set r distance-exponential-impact p-location event-location
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



to update-position-all
  ask turtles
  [
    update-position-for-turtle
  ]
end



to update-position-for-turtle
    setxy ( calc-position-x item x-axis-feature culture ) ( calc-position-y item  y-axis-feature culture )
end



to-report calc-position-x
  [l]
  report ( ( world-width - 1 ) *  l / 100  )  - ( world-width - 1 ) / 2
end

to-report calc-position-y
  [l]
  report ( (world-height - 1 ) *  l / 100 )  - ( world-height - 1 ) / 2
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
  csv:to-file "result.csv" [sublist culture 1 4] of turtles
end


to world-to-file
  file-open export-file
  ask turtles [file-print csv:to-row ( sentence (list behaviorspace-run-number ticks who)   culture soc-capital ) ]
  close-file
end

to close-file
  file-flush
  file-close-all
end

to-report sigmoid [x]
  report 1 / (1 + exp ( - x) )
end

to-report weighted-average [vals weights]
  report (sum (map [ [ x d ] -> x * d] vals weights)) / (sum weights)
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
2000
92.0
10
1
NIL
HORIZONTAL

SLIDER
3
245
175
278
prob-creator-gene
prob-creator-gene
0
1
0.2
0.01
1
NIL
HORIZONTAL

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
447
452
674
485
interaction-neighbours-per-tick
interaction-neighbours-per-tick
0
30
5.0
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
3
319
175
352
prob-event
prob-event
0
1
1.0
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
0
10000
0.0
50
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
3
355
175
388
event-impact
event-impact
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
447
524
641
557
neighbours-to-choose-from
neighbours-to-choose-from
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
3
283
175
316
prob-inactivity-gene
prob-inactivity-gene
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
659
125
1062
251
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
226
452
431
485
similar-over-neighbourhood
similar-over-neighbourhood
0
1
0.85
0.01
1
NIL
HORIZONTAL

SLIDER
6
162
178
195
custom-location-scale
custom-location-scale
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
1146
20
1298
53
x-axis-feature
x-axis-feature
0
num-features
0.0
1
1
NIL
HORIZONTAL

SLIDER
1146
55
1297
88
y-axis-feature
y-axis-feature
0
num-features - 1
3.0
1
1
NIL
HORIZONTAL

BUTTON
1150
96
1284
129
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

SLIDER
6
196
178
229
move-fraction
move-fraction
0
1
0.05
0.05
1
NIL
HORIZONTAL

CHOOSER
5
391
174
436
event-distance-impact
event-distance-impact
"None" "Linear World Distance" "Distance squared" "Distance exponential"
3

BUTTON
340
653
437
686
NIL
reset-colors\n
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
443
653
566
686
NIL
set-color-on-cap
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
660
253
860
403
soc capital average
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [soc-capital] of turtles"

SWITCH
460
616
566
649
color-cap
color-cap
0
1
-1000

SWITCH
5
439
152
472
cultural-distance
cultural-distance
0
1
-1000

BUTTON
571
654
677
687
Reset shapes
ask turtles [set shape \"dot\"] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
573
617
707
650
change-shape
change-shape
1
1
-1000

SLIDER
4
476
184
509
event-exp-impact-scale
event-exp-impact-scale
1
100
8.0
1
1
NIL
HORIZONTAL

PLOT
870
253
1070
403
plot event participants count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot last-event-participants-count"

PLOT
1090
261
1393
423
soc capital distribution
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 0 -16777216 true "" "  plot-pen-reset\nhistogram [soc-capital] of turtles"

PLOT
1069
527
1348
721
avg-last-p-final-peer
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot avg-last-p-final-peer"

PLOT
1353
526
1617
722
avg-last-p-final-event
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot avg-last-p-final-event"

SLIDER
213
564
385
597
social-capital-weight
social-capital-weight
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
763
567
978
600
random-peer-interaction-prob
random-peer-interaction-prob
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
4
510
176
543
event-impact-radius
event-impact-radius
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
763
604
935
637
negative-impact-prob
negative-impact-prob
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
763
532
935
565
recalc-world-interval
recalc-world-interval
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
936
532
1034
565
NIL
recalc-world
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
90
179
123
num-features
num-features
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
127
178
160
fixed-features
fixed-features
0
num-features
0.0
1
1
NIL
HORIZONTAL

SLIDER
447
489
652
522
uniqueness-seekers-per-tick
uniqueness-seekers-per-tick
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
678
452
850
485
c-uniqueness
c-uniqueness
0
1
0.05
0.01
1
NIL
HORIZONTAL

OUTPUT
1400
45
1849
522
11

SLIDER
6
564
208
597
interaction-history-discount
interaction-history-discount
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
6
601
178
634
soc-capital-init
soc-capital-init
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
7
637
179
670
history-size
history-size
0
100
10.0
1
1
NIL
HORIZONTAL

SWITCH
662
49
804
82
save-world-png
save-world-png
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

Similar to axelrod model, however turtles are used instead of patches.

## HOW IT WORKS

During setup turtles are placed randomly and assigned random culture (array of features). During each step turtles interact (neighbors) and event potentialy generated by creator that affects all agents. Interaction and events changes culture similar way as in axelrod model

Each agent has static location. It is controlled by custom-location-scale. Agent is assigned to grid (2 axis). Each axis has as cells as custom-location-scale. When custom-location-scale = 1, then there is one big cell and all agent will be assigned to it. That means static location will be irrelavant. This static location will be used to determine effect of event.



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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-similar-over-neighbourhood" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>mean [soc-capital-inner-p] of turtles</metric>
    <enumeratedValueSet variable="auto-stop">
      <value value="&quot;Condition&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-inner-init">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist2">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="similar-over-neighbourhood">
      <value value="0.7"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-dimensions">
      <value value="&quot;1-2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-cap-increment">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-fraction">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-location-scale">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural-distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact-radius">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-file">
      <value value="&quot;result.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplier-for-stopping">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-shape">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-capital-weight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-y">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-to-run">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean3">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meanf">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-exp-impact-scale">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="402"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-cap">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-distance-impact">
      <value value="&quot;Distance squared&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-inner-dist">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist3">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distf">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-x">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd1">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean1">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd2">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-peer-interaction-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean2">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adjust-n-neighbours-choose-on-capital?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sdf">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist1">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd3">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-negavite-impact-prob-effect" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="6000"/>
    <metric>mean [soc-capital-inner-p] of turtles</metric>
    <enumeratedValueSet variable="dist1">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop">
      <value value="&quot;Condition&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist2">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-restric-filter">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="similar-over-neighbourhood">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-fraction">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-cap-increment">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-dimensions">
      <value value="&quot;2-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-location-scale">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact-radius">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural-distance">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-file">
      <value value="&quot;result.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplier-for-stopping">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-shape">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-capital-weight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-to-run">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean3">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-exp-impact-scale">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meanf">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="402"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-cap">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-distance-impact">
      <value value="&quot;Distance squared&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-inner-dist">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist3">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distf">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-y">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-impact-prob">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd1">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean1">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-x">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd2">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-peer-interaction-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean2">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd3">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adjust-n-neighbours-choose-on-capital?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sdf">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-inner-init">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-similar-over-neighbourhood-recalworld" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="soc-capital-inner-init">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist1">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist2">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-restric-filter">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="similar-over-neighbourhood">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.7"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-fraction">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-dimensions">
      <value value="&quot;1-2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-cap-increment">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-location-scale">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural-distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact-radius">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multiplier-for-stopping">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-shape">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-capital-weight">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-y">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-to-run">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean3">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meanf">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-exp-impact-scale">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="402"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-cap">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-distance-impact">
      <value value="&quot;Distance squared&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-inner-dist">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist3">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distf">
      <value value="&quot;Uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var3-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-x">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-impact-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var1-y">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd1">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean1">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var2-x">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd2">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-peer-interaction-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recalc-world-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean2">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adjust-n-neighbours-choose-on-capital?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sdf">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop">
      <value value="&quot;Condition&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd3">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="soc_cap_weight" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [soc-capital] of turtles</metric>
    <enumeratedValueSet variable="peer-restric-filter">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-uniqueness">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="similar-over-neighbourhood">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-fraction">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-location-scale">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact-radius">
      <value value="0.12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-history-discount">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural-distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-size">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-init">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-axis-feature">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-shape">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-capital-weight">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-features">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-to-run">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-exp-impact-scale">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-axis-feature">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-cap">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-distance-impact">
      <value value="&quot;Distance squared&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-impact-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="0.53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="uniqueness-seekers-per-tick">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-peer-interaction-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recalc-world-interval">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adjust-n-neighbours-choose-on-capital?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-features">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EUSoN" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <enumeratedValueSet variable="peer-restric-filter">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="xthr">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c-uniqueness">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="similar-over-neighbourhood">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.7"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-inactivity-gene">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-fraction">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sample-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-location-scale">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact-radius">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural-distance">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbours-to-choose-from">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-history-discount">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-size">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soc-capital-init">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-axis-feature">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-shape">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-capital-weight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-features">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-creator-gene">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-event">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-to-run">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-exp-impact-scale">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-axis-feature">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-cap">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-distance-impact">
      <value value="&quot;Distance squared&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-impact-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-impact">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="uniqueness-seekers-per-tick">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-peer-interaction-prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recalc-world-interval">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-neighbours-per-tick">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-features">
      <value value="0"/>
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
