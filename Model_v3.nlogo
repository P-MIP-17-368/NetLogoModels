;extensions [r csv]
extensions [csv]
turtles-own [culture creator-gene inactivity-gene cluster ll custom-location soc-capital-inner soc-capital-inner-p last-random-event last-p-final last-peer-interacted last-peer-interaction-step last-peer-ineractokpijohtugn-result]
;custom-location - each agent has location, that doesn't change
; last-random-event - just for testing purposes - stores last random generated number which is used to determine participation in event

globals [this-cluster max-cluster num-cluster num-cluster-bigger-than-x color-list g-fixed last-event-participants-count avg-last-p-final-peer avg-last-p-final-event o-file last-peer-ineraction-result]

;ask turtle 29 [ask max-n-of neighbours-to-choose-from other turtles [similarity [culture] of myself culture] [set color green ]]

to setup
  clear-all
  if length(export-file) > 4
  [
    file-open(export-file)
  ]
  set g-fixed 1
  setup-patches
  setup-turtles
  reset-ticks
end

to go
  tick
  peers-interaction
  make-event
  if sample-interval > 0 and ticks mod sample-interval = 0 and length(export-file) > 3
  [
    world-to-file
  ]
 ; if ticks mod sample-interval = 0 [
 ;   update-plot
 ;   if auto-stop != "None"
 ;     [ifelse auto-stop = "Ticks"
 ;       [if ticks >= ticks-to-run [stop]]
 ;       [if ticks mod ( sample-interval * multiplier-for-stopping ) = 0 [if check-end? [stop]]]
 ;     ]
 ; ]
  if color-cap [set-color-on-cap]
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

    set soc-capital-inner soc-capital-inner-init

    ifelse soc-capital-inner-dist > 0 [ set soc-capital-inner  random-normal soc-capital-inner-init soc-capital-inner-dist  ] [ set soc-capital-inner soc-capital-inner-init ]

  ;  set soc-capital-inner (random-float 2) - 1
     set soc-capital-inner-p sigmoid soc-capital-inner
    set culture []
    set custom-location list random custom-location-scale random custom-location-scale

    set culture ( list ( rnd-culture-item distf meanf sdf )  ( rnd-culture-item dist1 mean1 sd1 ) ( rnd-culture-item dist2 mean2 sd2 ) ( rnd-culture-item dist3 mean3 sd3 ))
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
    let s sigmoid soc-capital-inner
    set color p-to-color5 s
  ]
end
to-report p-to-color5 [p]
  report ( ( round ( p * 10 ) * 10)  + 5 )
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
  let var-avg-last-p-final-peer 0
  if interaction-neighbours-per-tick > 0
  [

  ask n-of interaction-neighbours-per-tick turtles
  [
    let culture-A []
    let neighbours-to-choose-from-adjusted neighbours-to-choose-from
    if adjust-n-neighbours-choose-on-capital? [set neighbours-to-choose-from-adjusted ceiling ( neighbours-to-choose-from * soc-capital-inner-p ) ]

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
        let peers max-n-of neighbours-to-choose-from-adjusted other turtles [similarity culture-A culture]
        set turtle-B one-of peers
        ;ask peers [set color green]
      ]
      [;neighbours
        let peers min-n-of neighbours-to-choose-from-adjusted other turtles  [custom-distance custom-location location-A ]
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
    set last-p-final ( ( similarity culture-A culture-B ) * ( 1 - social-capital-weight)) +  social-capital-weight * ( sigmoid soc-capital-inner-p + ( [soc-capital-inner-p] of turtle-B ) ) / 2
    set last-random-event random-float 1
    set var-avg-last-p-final-peer var-avg-last-p-final-peer + last-p-final
    ;output-print2 "similarity between cultures" P
    ifelse (last-p-final > 0 and last-p-final < 1) and last-random-event  < last-p-final [
      set culture new-culture culture-A culture-B 1
      update-position-for-turtle
      set soc-capital-inner  soc-capital-inner + soc-cap-increment
      set soc-capital-inner-p sigmoid soc-capital-inner
      if change-shape [ set shape "face happy"]
      set last-peer-ineraction-result true
    ;  output-print ( list "+soc-self:" soc-capital-inner [who] of self )
      ask turtle-B [
        set last-peer-ineraction-result true
        set soc-capital-inner  soc-capital-inner + soc-cap-increment
        set soc-capital-inner-p sigmoid soc-capital-inner
       ; output-print ( list "+soc-peer:" soc-capital-inner  [who] of self )
        if change-shape [ set shape "face happy"]
        ]
    ] [
      set last-peer-ineraction-result false
      set soc-capital-inner  soc-capital-inner - soc-cap-increment
      set soc-capital-inner-p sigmoid soc-capital-inner
      if change-shape [ set shape "face sad"]
      ask turtle-B [
        set last-peer-ineraction-result false
        set soc-capital-inner  soc-capital-inner - soc-cap-increment
        set soc-capital-inner-p sigmoid soc-capital-inner
        if change-shape [ set shape "face sad"]
        ]
    ]
  ]
  set avg-last-p-final-peer var-avg-last-p-final-peer / interaction-neighbours-per-tick
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
           [set last-p-final  ( event-impact * P-similar * distance-effect * (1 - social-capital-weight)  ) +  ( social-capital-weight * soc-capital-inner-p )]
        output-print4 "p-final" last-p-final "P-similar:" P-similar

        set last-random-event random-float 1
        set var-avg-last-p-final-event var-avg-last-p-final-event + last-p-final
        if (last-p-final > 0 and last-p-final < 1) and last-random-event < last-p-final
        [
          if change-shape [ set shape "triangle" ]
          set culture new-culture culture ( [culture] of myself) 1
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

to update-plot
  ;find-clusters
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
  ;file-open file-name
  ;ask turtles [ file-print reduce [ [ x y ] -> ( word  x ","  y )   ] ( fput ticks ( sublist culture 1 4 ) ) ]
  ;let l (length [culture] of one-of turtles)
  csv:to-file export-file [sublist culture 1 4] of turtles
end


to world-to-file
  file-open ( word "res-" behaviorspace-run-number ".csv" )
  ask turtles [file-print csv:to-row ( fput behaviorspace-run-number ( fput ticks ( sublist culture 1 4 ) ) ) ]
  close-file
  ;;csv:to-file ( word "res-" behaviorspace-run-number "-" ticks ".csv" )  [sublist culture 1 4] of turtles
end

to close-file
  file-flush
  file-close-all
end

to-report sigmoid [x]
  report 1 / (1 + exp ( - x) )
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
402.0
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
0.2
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
10.0
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
1000
100.0
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
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
389
489
583
522
neighbours-to-choose-from
neighbours-to-choose-from
1
100
11.0
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
0.0
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
33.0
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
17.0
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
55.0
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
653
112
1072
372
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
390
598
595
631
similar-over-neighbourhood
similar-over-neighbourhood
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
389
560
561
593
custom-location-scale
custom-location-scale
0
100
10.0
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
1083
280
1217
313
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
34.0
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
8.0
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
0.05
0.05
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
2

BUTTON
1264
568
1356
601
export-csv
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
1089
226
1227
271
display-dimensions
display-dimensions
"1-2" "1-3" "2-3"
0

BUTTON
1081
323
1228
356
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

SLIDER
9
665
181
698
soc-cap-increment
soc-cap-increment
0
0.5
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
10
703
182
736
soc-capital-inner-init
soc-capital-inner-init
-5
5
0.0
0.5
1
NIL
HORIZONTAL

PLOT
506
639
694
830
soc capital raw inner distribution
NIL
NIL
-20.0
20.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [soc-capital-inner] of turtles"

BUTTON
85
803
182
836
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
194
802
317
835
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
670
390
870
540
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
"default" 1.0 0 -16777216 true "" "plot mean [soc-capital-inner-p] of turtles"

SWITCH
200
763
306
796
color-cap
color-cap
0
1
-1000

SWITCH
200
657
347
690
cultural-distance
cultural-distance
0
1
-1000

BUTTON
349
800
455
833
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
333
762
467
795
change-shape
change-shape
1
1
-1000

SLIDER
200
692
380
725
event-exp-impact-scale
event-exp-impact-scale
1
100
9.0
1
1
NIL
HORIZONTAL

PLOT
874
390
1074
540
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
704
638
1023
833
soc capital p distribution
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
"default" 0.05 0 -16777216 true "" "  plot-pen-reset\nhistogram [soc-capital-inner-p] of turtles"

SWITCH
391
525
667
558
adjust-n-neighbours-choose-on-capital?
adjust-n-neighbours-choose-on-capital?
1
1
-1000

PLOT
1028
636
1307
830
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
1079
388
1279
538
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
616
600
788
633
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
11
740
183
773
soc-capital-inner-dist
soc-capital-inner-dist
0
10
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
697
555
912
588
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
200
727
372
760
event-impact-radius
event-impact-radius
0
1
0.16
0.01
1
NIL
HORIZONTAL

INPUTBOX
660
48
834
108
export-file
result.csv
1
0
String

BUTTON
1378
554
1458
587
NIL
close-file\n
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
  <experiment name="experiment" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
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
