globals [
  dispersants-total
  dispersants-winner
  dispersants-loser
  who-a1
  who-a2
  width-HZ
  width-HZ-sum
  width-HZ-num
  width-HZ-mean
  relative-area-HZ
  ]

breed [fragments fragment]
breed [monkeys monkey]
breed [arrows arrow]

fragments-own [radius
              group
              population ;;trait to calculate the population in each fragment
              maximum_density  ;;the maximum density accepted for each fragment
              ]
monkeys-own [species  ;;Variable used to identify the two natural species and the hybrids. There are two species (1 and 0) in the model.
                      ;;When two monkeys reproduce the offspring receive the species number as an average of the species numbers of the parents
                      ;;Thus, if the species number is different of 0 or 1 the monkey is an hybrid
             sex
             age
             interbreeding   ;; Time between births for females
             mate            ;; Mate of the last breeding 
             my-group        ;; monkeys in the same fragment that the agent (female) use to choose a mate
             spfather        ;; number of mother's species
             spmother        ;; number of father's species
             father          ;; father's who
             mother          ;; mother's who
             my-fragment     ;; fragment in which the monkey is living
             who-frag
             AmI_dispersing?
             dispersion-dist
             old-fragment
             home-range
             affinity_sympatric
             radius
             new-fragment
             disperse-before?
             reproducing?
             ]

to setup
  clear-all
  reset-ticks
  ifelse n-fragments > (n-monkeys / 10)
  [create-turtles1]
  [create-turtles2]
  
  set dispersants-total 0
  set dispersants-winner 0
  set dispersants-loser 0
end

to go
  ask monkeys [
    check-time-to-die
    move ]
 
  ask monkeys with [(age >= start_disp_age) and (disperse-before? = false)] [check-dispersion]
    
  ask monkeys with [(sex = "female") and (age >= 7) and (interbreeding >= 2)] [if AmI_dispersing? = false [reproduce]]
  
  ask fragments with [population > maximum_density] [
    ask group [check-time-to-die]
    ]

  update-data
  cal-width-HZ

  if ticks >= 500 [
    export-view-end
    stop]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;  SUBMODELS  ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;; CREATE TURTLES 1 ;;;;;;;;;;;;;;;;
to create-turtles1
    let min_density abs (n-monkeys / 10)
    create-fragments min_density [
    set color green
    set size 1        ;; the biggest fragment knew for the species has 15Km2, thus I'm setting a random value for the area from 5Km2 to 15Km2 for each fragment 
    set shape "circle"
    set radius 1 + random 5
    setxy random-xcor random-ycor
    ask patches in-radius radius [set pcolor green]
    set maximum_density ((1 + (count (patches in-radius radius))) * (11 + random 22)) ;; calculating the maximum density for each fragment considering the min and max
                                                                                ;;density values reported for the species (11 and 33ind/Km2 respectivelly)
                                                                                ;;I'm adding 1 to count the patch where the fragment agent is in it
    if  maximum_density > 100 [set maximum_density 100]       ;; as the biggest population knowed for the species has 180 individuals I am limiting the maximum 
     ]                                                         ;;density according this value
    
    
create-monkeys-n
  
create-fragments (n-fragments - min_density) [
    set color green
    set size 1        ;; the biggest fragment knew for the species has 15Km2, thus I'm setting a random value for the area from 5Km2 to 15Km2 for each fragment 
    set shape "circle"
    set radius 1 + random 5
    setxy random-xcor random-ycor
    ask patches in-radius radius [set pcolor green]
    set maximum_density ((1 + (count (patches in-radius radius))) * (11 + random 22)) ;; calculating the maximum density for each patch considering the min and max
                                                                                ;;density values reported for the species (11 and 33ind/Km2 respectivelly)
                                                                                ;;I'm adding 1 to count the patch where the fragment agent is in it
    if  maximum_density > 100 [set maximum_density 100]
    ]
end 


;;;;;;;;;;;;;;;; CREATE TURTLES 2 ;;;;;;;;;;;;;;;;
to create-turtles2
    create-fragments n-fragments [
    set color green
    set size 1        ;; the biggest fragment knew for the species has 15Km2, thus I'm setting a random value for the area from 5Km2 to 15Km2 for each fragment 
    set shape "circle"
    set radius 1 + random 5
    setxy random-xcor random-ycor
    ask patches in-radius radius [set pcolor green]
    set maximum_density ((1 + (count (patches in-radius radius))) * (11 + random 22)) ;; calculating the maximum density for each patch considering the min and max
                                                                                ;;density values reported for the species (11 and 33ind/Km2 respectivelly)
                                                                                ;;I'm adding 1 to count the patch where the fragment agent is in it
    if  maximum_density > 100 [set maximum_density 100]
    ]
    
create-monkeys-n
end


;;;;;;;;;;;;;;;;;;; CREATE MONKEYS ;;;;;;;;;;;;;;;;;;
to create-monkeys-n
      create-monkeys n-monkeys [  
    set shape "monkey2"
    set size 2
    set AmI_dispersing? false
    set interbreeding 0
    set father "F1"
    set mother "F1"
    set mate nobody
    set new-fragment nobody
    set disperse-before? false
    move-to one-of fragments
while [any? monkeys in-radius 1 = false] [  ;;This code is to avoid create monkeys alone
  if (any? monkeys in-radius 1 = false) [
    move-to one-of fragments
    ]
  ]

while [(xcor < 116) and (xcor > 102)] [ ;;maintaining some fragments in the middle of the distribution of the two species without monkeys 
  if (xcor < 116) and (xcor > 102)
  [move-to one-of fragments with [any? monkeys = true] ]
]

ask fragments [
    set population count monkeys in-radius radius
    set group other monkeys in-radius radius  
  ]

  ask fragments [
    while [population > maximum_density] [
    set population count monkeys in-radius radius
    set group other monkeys in-radius radius
    if population > maximum_density [ask one-of monkeys in-radius radius [move-to one-of fragments with [(any? monkeys = true) and (population < maximum_density)]]]
     ] ]
        
    ifelse xcor >  114 [ ;; creating the two different species, with different color and separated vertically in the world
      set species 0
      set color yellow
      ] [
      set species 1
      set color brown
      ]
    let min_age 6
    ask fragments [  ;;creating groups of primates in each fragment
      ask monkeys in-radius radius [
        ifelse random-float 1.0 < 0.6  ;; creating adults and females in the proportion of 1:1.5
    [set sex "female"]
    [set sex "male" ]
    ifelse random-float 1.0 < 0.58 ;; creating adults and juveniles in the proportion of 1:1.4
    [set age random 6]
    [set age min_age + random 13 ]  ;; age of adults is created considering the estimated age of sexual maturity (7 years) and the last reprodutive age (20 years)
        ]
      ]
  ]
  ask fragments [
    set population count monkeys in-radius radius
    set group other monkeys in-radius radius
    ]
  ask monkeys [
    set my-fragment min-one-of fragments [distance myself]
    set my-group [group] of my-fragment
    set radius [radius] of my-fragment
    ]
  
  ask monkeys with [(sex = "female") and (age >= 7)] [set interbreeding random 2]
end


;;;;;;;;; DISPERSE ;;;;;;;;;;;;
to disperse
  set new-fragment nobody
  right random 360
  while [[pcolor] of patch-here = green] [
    ifelse (([pxcor] of patch-ahead 1 <= 0) or ([pxcor] of patch-ahead 1 >= 214) or ([pycor] of patch-ahead 1 <= 0) or ([pycor] of patch-ahead 1 >= 214))
    [set dispersants-loser dispersants-loser + 1
     die
     stop]
    [fd 1] ]
  ;pen-down
  
;  let min-dispersion_power abs(dispersion_power / 2)                                 ;; use these three code lines to include a random variation in dispersion power
;  let dif-dispersion_power (dispersion_power - min-dispersion_power)
;  let random-dispersion_power (min-dispersion_power + random dif-dispersion_power)
   
   set dispersion-dist 0
   while [dispersion-dist <= dispersion_power] [
    ifelse (([pxcor] of patch-ahead 1 <= 0) or ([pxcor] of patch-ahead 1 >= 214) or ([pycor] of patch-ahead 1 <= 0) or ([pycor] of patch-ahead 1 >= 214))
    [set dispersants-loser dispersants-loser + 1
     die
     stop
      ]
    [fd 1]
    let w [who] of my-fragment
    set new-fragment one-of fragments with [who != w] in-radius dispersion-vision
    ifelse new-fragment != nobody
    [
    set my-fragment new-fragment
    set my-group [group] of my-fragment
    move-to my-fragment
    set disperse-before? true
    set AmI_dispersing? false
    ;set color blue             ;;It can be used to identify the dispersants
    set old-fragment w
    set new-fragment nobody
    set dispersants-winner dispersants-winner + 1
    ;pen-up
    stop
   ]
    [ifelse dispersion-dist = dispersion_power
      [set dispersants-loser dispersants-loser + 1
        die
        ]
      [set dispersion-dist dispersion-dist + 1]
          ] ]
end


;;;;;;;;; REPRODUCE ;;;;;;;;;;;;
to reproduce
   ifelse (([population] of my-fragment) < ([maximum_density] of my-fragment)) [ 
     if pref-same-sp = "Strictly" [reproduce-strictly]
     if  pref-same-sp = "Preference" [reproduce-preference]
     if pref-same-sp = "Any" [
      set mate one-of my-group with [(sex = "male") and (age >= 7)]
      breeding] ]
   [set interbreeding interbreeding + 1]
end


;;;;;;;; REPRODUCE-STRICTLY ;;;;;;;;
to reproduce-strictly
  set mate nobody
  ifelse species = 0 [
     let s one-of my-group with [(sex = "male") and (age >= 7) and (species = 0)]
       ifelse s !=  nobody [
       set mate one-of my-group with [(sex = "male") and (age >= 7) and (species = 0)]
       breeding
       ]
       [set interbreeding interbreeding + 1]
   ]
  [
     let s one-of my-group with [(sex = "male") and (age >= 7) and (species = 1)]
       ifelse s !=  nobody [
       set mate one-of my-group with [(sex = "male") and (age >= 7) and (species = 1)]
       breeding
       ]
       [set interbreeding interbreeding + 1]    
    ]
end 


;;;;;;;;; REPRODUCE-PREFERENCE ;;;;;;;;;;;;
to reproduce-preference
   set mate nobody
   if species = 0 [
     let p one-of my-group with [(sex = "male") and (age >= 7) and (species = 0)]
       ifelse p !=  nobody [
       set mate one-of my-group with [(sex = "male") and (age >= 7) and (species = 0)]
       breeding
       ]
       [reproduce-preference2]
     ]
   
   if species = 1 [
     let p one-of my-group with [(sex = "male") and (age >= 7) and (species = 1)]
       ifelse p !=  nobody [
       set mate one-of my-group with [(sex = "male") and (age >= 7) and (species = 1)]
       breeding
       ]
       [reproduce-preference2]     
     ]
   
   if (species != 0 and species != 1) [
     let p one-of my-group with [(sex = "male") and (age >= 7) and (species != 0) and (species != 1)]
       ifelse p !=  nobody [
       set mate one-of my-group with [(sex = "male") and (age >= 7) and (species != 0) and (species != 1)]
       breeding
       ]
       [reproduce-preference2]     
     ]
end


;;;;;;;;;;; REPRODUCE-PREFERENCE2 ;;;;;;;;;;;

to reproduce-preference2
  ifelse random-float 1.0 < prob-mate-diff-sp [
     set mate one-of my-group with [(sex = "male") and (age >= 7)]
     breeding
     ]
  [set interbreeding interbreeding + 1]
end
   

;;;;;;;;;;;;;;;; BREEDING ;;;;;;;;;;;;;;;;;;
to breeding
  ifelse mate != nobody [
   let m [who] of self                
   let f [who] of mate
   let spm [species] of monkey m 
   let spf [species] of monkey f
   
   hatch 1 [
    set age 0
    set AmI_dispersing? false
    set interbreeding 0
    set mate nobody
    set spfather spf   ;; species value of the father
    set spmother spm   ;; species value of the mother
    set father f       ;; who of the father
    set mother m       ;; who of the mother
    set species ((spf + spm) / 2)   
    set my-group [my-group] of monkey f
    set my-fragment [my-fragment] of monkey f
    set radius [radius] of my-fragment
    set disperse-before? false
    set xcor [xcor] of monkey f
    set ycor [ycor] of monkey f
    ifelse random-float 1.0 < 0.5
    [set sex "female"]
    [set sex "male"]
    
    ifelse species = 0
    [set color yellow]
    [ifelse species = 1
      [set color brown]
      [set color orange]
      ]
   ]
   set interbreeding 0 ] 
 [set interbreeding interbreeding + 1]
 
end


;;;;;;;;; MOVE ;;;;;;;;;;;;
to move
  ifelse any? patches in-radius radius with [(pcolor = green) and (pxcor != 0) and (pxcor != 214) and (pycor != 0) and (pycor != 214)]
  ;move-to one-of patches in-radius radius with [pcolor = green] ]
  [move-to one-of patches in-radius radius with [(pcolor = green) and (pxcor != 0) and (pxcor != 214) and (pycor != 0) and (pycor != 214)] ]
  [die]
end


;;;;;;;;;;;;;; CHECK TIME TO DIE ;;;;;;;;;;;;;;;;;;
to check-time-to-die     ;; Using annual mortality rates (Montenegro 2011)
  if (age >= 20) [die]             ;; individuals die in the last reproductive age estimated to the species 
 
  ifelse age <= 1        ;; Mortality rate for infants which have less than 1 year (20%)
  [if random-float 1.0 < 0.2 [die] ]
  [
    ifelse age <= 6      ;; Mortality rate for individuals which have more than 1 and less than 6 years (8%)
    [if random-float 1.0 < 0.08 [die] ]
    [if random-float 1.0 < 0.05  [die] ]  ;; Mortality rate for individuals which have more than 6 years (5%)
    ]
end

;;;;;;;;;;; CHECK-DISPERSION ;;;;;;;;;;;;;;;;;;;
to check-dispersion      ;;Target individuals as dispersing or not
  if random-float 1.0 < prob-dispersion [
    set AmI_dispersing? True
    set dispersants-total dispersants-total + 1
    disperse
    ]

;  ifelse ([population] of my-fragment) >= ([maximum_density] of my-fragment)  ;;The probability of dispersing is bigger when the population of the fragment reach the maximum-density
;  [if random-float 1.0 < (prob-dispersion * 2) [set AmI_dispersing? true]]
;  [if random-float 1.0 < prob-dispersion [set AmI_dispersing? true]]
  
;  ask fragments [
;  ifelse population >= maximum_density   ;;The probability of dispersing is bigger when the population of the fragment reach the maximum-density 
;   [
;      ask monkeys in-radius radius with [sex = "male" and age >= start_disp_age] [
;      if random-float 1.0 < (prob-dispersion * 2)
;      [set AmI_dispersing? true]
;      ]
;     ]
;   [
;     ask monkeys in-radius radius with [sex = "male" and age >= start_disp_age] [
;      if random-float 1.0 < prob-dispersion
;      [set AmI_dispersing? true]
;     ]
;    ]
;  ]
end


;;;;;;;;;;;;;;;;; Update data ;;;;;;;;;;;;;;;

to update-data  ;; procedure to update informations for each fragment or monkey
   
  ask monkeys [set age age + 1]  ;; increasing age of monkeys
  
    ask fragments [
    set population count monkeys in-radius radius      ;; updating population size and group individuals, because new monkeys could be in the fragment due reproduction or migration
    set group other monkeys in-radius radius
    ]
  ask monkeys [
    set my-fragment min-one-of fragments [distance myself] ;; updating fragment and group individuals, because new monkeys could be in the fragment due reproduction or migration
    set my-group [group] of my-fragment
    set radius [radius] of my-fragment
    ]
  
    ask monkeys with [(sex = "female") and (age >= 5)]   ;; increasing the interbreeding from 5 years the females will start to reproduce in the mature age
    [set interbreeding interbreeding + 1]
    
    ask monkeys with [(sex = "female") and (age >= 6) and (interbreeding < 2)]  ;; increasing the interbreeding for females that give birth
    [set interbreeding interbreeding + 1]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; EXPORT VIEW ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to export-view-end
  if Export-view? [
    export-view Filename
    ]
end

to export-fragments-species
  file-open Filename
  file-type (word "Frag.xcor, Frag.ycor, Genotype")
  file-print ""

ifelse Export-all-frag? = true [
  let f 0
  while [f <= count turtles] [
    if (turtle f != nobody) [
      if ([breed] of turtle f = fragments) [
        ask fragment f [
          if population > 0 [
            file-type (word xcor "," ycor "," mean [species] of group)
            file-print ""
            ]
          ]
        ]
      ]
      set f f + 1
      ]
  ] [
  let i 1
  while [i <= 15] [
    ask one-of fragments with [xcor < 108 and ycor > 108 and population > 0] [
      file-type (word xcor "," ycor "," mean [species] of group)
      file-print ""]
    ask one-of fragments with [xcor < 108 and ycor < 108 and population > 0] [
      file-type (word xcor "," ycor "," mean [species] of group)
      file-print ""]
    ask one-of fragments with [xcor > 108 and ycor > 108 and population > 0] [
      file-type (word xcor "," ycor "," mean [species] of group)
      file-print ""]
    ask one-of fragments with [xcor > 108 and ycor < 108 and population > 0] [
      file-type (word xcor "," ycor "," mean [species] of group)
      file-print ""]
    set i i + 1
    ] ]
  
 file-close 
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; HYBRIDS DETAILS ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to Hybrid-zone-bold
  ask arrows [die]
  set width-HZ-sum 0
  set width-HZ-num 0
  
  if (any? monkeys with [species != 0 and species != 1]) [
    create-arrows 1 [
      set shape "arrow"
      set size 5
      set color 85
      set xcor min [xcor] of monkeys with [species != 0 and species != 1]
      set ycor min [ycor] of monkeys with [species != 0 and species != 1]
      set who-a1 who
      pen-down
      ]
    create-arrows 1 [
      set shape "arrow"
      set size 5
      set color 85
      set xcor max [xcor] of monkeys with [species != 0 and species != 1]
      set ycor min [ycor] of monkeys with [species != 0 and species != 1]
      set who-a2 who
      pen-down
      ]
    
    ifelse (([xcor] of turtle who-a2) != ([xcor] of turtle who-a1))
    [set width-HZ-sum width-HZ-sum + (([xcor] of turtle who-a2) - ([xcor] of turtle who-a1))]
    [set width-HZ-sum width-HZ-sum + 1]
    set width-HZ-num width-HZ-num + 1
     
    let y (min [ycor] of monkeys with [species != 0 and species != 1] + 1)
    while [y <= 214] [
      ifelse (any? monkeys with [species != 0 and species != 1 and ycor = y]) [
        let xa1 min [xcor] of monkeys with [species != 0 and species != 1 and ycor = y]
        ask arrow who-a1 [move-to one-of monkeys with [species != 0 and species != 1 and ycor = y and xcor = xa1]]
        let xa2 max [xcor] of monkeys with [species != 0 and species != 1 and ycor = y]
        ask arrow who-a2 [move-to one-of monkeys with [species != 0 and species != 1 and ycor = y and xcor = xa2]]
        ask patches with [pxcor >= xa1 and pxcor <= xa2 and pycor = y] [set pcolor 85]
        
        ifelse (([xcor] of turtle who-a2) != ([xcor] of turtle who-a1))
        [set width-HZ-sum width-HZ-sum + (([xcor] of turtle who-a2) - ([xcor] of turtle who-a1))]
        [set width-HZ-sum width-HZ-sum + 1]
        set width-HZ-num width-HZ-num + 1
      ]
      [
      let xa1 min [xcor] of arrows
      let xa2 max [xcor] of arrows
      ask arrows [
        pen-up
        move-to patch xcor y
        pen-down ]
      ;ask patches with [pxcor >= xa1 and pxcor <= xa2 and pycor = y] [set pcolor 85]
      ]
      set y y + 1
      ]
    set width-HZ-mean (width-HZ-sum / width-HZ-num)
    set relative-area-HZ (width-HZ-mean * width-HZ-num)
    ]
end

to Hybrid-zone-width
  ask arrows [die]
  if (any? monkeys with [species != 0 and species != 1]) [
      create-arrows 1 [
      set shape "arrow"
      set size 5
      set color red
      set xcor min [xcor] of monkeys with [species != 0 and species != 1]
      set ycor min [ycor] of monkeys with [species != 0 and species != 1]
      pen-down
      ]
    create-arrows 1 [
      set shape "arrow"
      set size 5
      set color red
      set xcor max [xcor] of monkeys with [species != 0 and species != 1]
      set ycor min [ycor] of monkeys with [species != 0 and species != 1]
      pen-down
      ]
    let y (min [ycor] of monkeys with [species != 0 and species != 1] + 1)
    while [y <= 214] [
      ask arrows [move-to patch xcor y]
      set y y + 1        
      ]    
    
    ]
end


to cal-width-HZ
  if any? monkeys with [species != 0 and species != 1] [
    let maxx (max [xcor] of monkeys with [species != 0 and species != 1])
    let minx (min [xcor] of monkeys with [species != 0 and species != 1])
    ifelse maxx != minx [
      set width-HZ maxx - minx
      ] [
      set width-HZ (maxx + 1) - minx
      ]
    ] 
end


to show-prop-hybrids
  if any? monkeys with [species != 0 and species != 1] [
      ask turtles [set color color + 1]
      ask patches with [pcolor = green] [set pcolor green + 1]
    ask fragments with [(count monkeys in-radius radius with [species != 0 and species != 1]) != 0] [
      ask patches in-radius radius [set pcolor brown - 1]
      ask turtles in-radius radius [hide-turtle]
      let total-patches count patches in-radius radius
      let genotype (1 - (mean [species] of group))
      let pop-g abs(genotype * total-patches)
      let i 1
      while [i <= pop-g] [
        ask one-of patches in-radius radius with [pcolor = brown - 1] [set pcolor yellow]
        set i i + 1
        ]
    ] ]
end 











@#$#@#$#@
GRAPHICS-WINDOW
403
10
1058
686
-1
-1
3.0
1
5
1
1
1
0
0
0
1
0
214
0
214
1
1
1
ticks
30.0

BUTTON
5
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

BUTTON
78
10
145
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

SLIDER
6
53
178
86
n-fragments
n-fragments
100
2000
500
100
1
NIL
HORIZONTAL

SLIDER
7
93
179
126
n-monkeys
n-monkeys
500
2000
1500
50
1
NIL
HORIZONTAL

SLIDER
8
134
180
167
prob-dispersion
prob-dispersion
0
1
0.03
0.01
1
NIL
HORIZONTAL

CHOOSER
8
175
100
220
pref-same-sp
pref-same-sp
"Strictly" "Preference" "Any"
2

SLIDER
106
176
252
209
prob-mate-diff-sp
prob-mate-diff-sp
0
1
0.56
0.01
1
NIL
HORIZONTAL

PLOT
13
226
209
373
Population
Years
Total Population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -8431303 true "" "plot count monkeys with [species = 1]"
"pen-2" 1.0 0 -955883 true "" "plot count monkeys with [(species != 0) and (species != 1)]"
"pen-3" 1.0 0 -1184463 true "" "plot count monkeys with [species = 0]"

BUTTON
153
11
218
44
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

MONITOR
214
226
313
271
Frag. overpop.
count fragments with [population > maximum_density]
17
1
11

MONITOR
215
276
312
321
MaxPop / Fragm.
max [population] of fragments
17
1
11

MONITOR
318
276
393
321
Total Pop.
count monkeys
17
1
11

SLIDER
187
53
359
86
start_disp_age
start_disp_age
3
15
5
1
1
NIL
HORIZONTAL

SLIDER
186
93
358
126
dispersion_power
dispersion_power
1
20
20
1
1
NIL
HORIZONTAL

SLIDER
186
134
358
167
dispersion-vision
dispersion-vision
1
10
5
1
1
NIL
HORIZONTAL

MONITOR
318
226
392
271
Frag with pop
count fragments with [population != 0]
17
1
11

MONITOR
319
327
395
372
Hybrids
count monkeys with [species != 0 and species != 1]
17
1
11

MONITOR
215
327
313
372
Frag. with Hybrids
count fragments with [any? group with [species != 0 and species != 1]]
17
1
11

MONITOR
12
426
86
471
Disp. Loser
dispersants-loser
17
1
11

MONITOR
13
377
85
422
Dispersants
dispersants-total
17
1
11

PLOT
90
377
290
521
Dispersion
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
"default" 1.0 0 -2674135 true "" "plot dispersants-total"
"pen-1" 1.0 0 -13345367 true "" "plot dispersants-loser"
"pen-2" 1.0 0 -14439633 true "" "plot dispersants-winner"

MONITOR
13
477
87
522
Disp. Winner
dispersants-winner
17
1
11

SWITCH
1069
12
1197
45
Export-view?
Export-view?
1
1
-1000

INPUTBOX
1069
49
1335
164
Filename
C:\\Users\\Amely\\Documents\\Amely_UT\\Courses\\Spring_2014\\Agent_Based_Simulation_Modeling\\Project\\Control\\Analysis_Final\\HModel_ExpGenotypes8.csv
1
0
String

BUTTON
1070
210
1236
243
Export Frag./Genotypes
export-fragments-species
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
1070
171
1212
204
Export-all-frag?
Export-all-frag?
0
1
-1000

BUTTON
1071
249
1197
282
Hybrid-zone-bold
Hybrid-zone-bold
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
1072
287
1253
320
NIL
Hybrid-zone-width
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
296
377
394
422
Max. Width (HZ)
width-HZ
17
1
11

MONITOR
297
426
394
471
Mean Width HZ
width-HZ-mean
3
1
11

MONITOR
297
475
393
520
HZ area
relative-area-HZ
17
1
11

MONITOR
174
525
286
570
% world with hybrids
(100 * relative-area-HZ) / 46225
3
1
11

BUTTON
1075
335
1210
368
NIL
show-prop-hybrids
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

circle10
false
0
Circle -6459832 true false 0 0 300
Polygon -1184463 true false 60 30 135 150 105 15 60 30

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

monkey
false
4
Circle -6459832 true false 30 91 58
Polygon -6459832 true false 45 150 15 225 60 180 45 240 90 180 165 180 165 240 195 180 210 240 225 180 240 135 255 105 270 90 285 75 270 75 255 90 240 105 225 135 90 135

monkey2
false
4
Circle -1184463 true true 30 91 58
Polygon -1184463 true true 45 150 15 225 60 180 45 240 90 180 165 180 165 240 195 180 210 240 225 180 240 135 255 105 270 90 285 75 270 75 255 90 240 105 225 135 90 135

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
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Population_dynamics" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count monkeys with [specie = 0]</metric>
    <metric>count monkeys with [specie = 1]</metric>
    <metric>count monkeys with [(specie != 0) and (specie != 1)]</metric>
    <metric>count fragments with [population &gt; maximum_density]</metric>
    <metric>max [population] of fragments</metric>
    <metric>count monkeys</metric>
    <enumeratedValueSet variable="n-monkeys">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-fragments">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-dispersion">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mate-diff-sp">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pref-same-sp">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Population_dynamics2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count monkeys with [specie = 0]</metric>
    <metric>count monkeys with [specie = 1]</metric>
    <metric>count monkeys with [(specie != 0) and (specie != 1)]</metric>
    <metric>count fragments with [population &gt; maximum_density]</metric>
    <metric>max [population] of fragments</metric>
    <metric>count monkeys</metric>
    <enumeratedValueSet variable="n-monkeys">
      <value value="500"/>
      <value value="1000"/>
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-fragments">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-dispersion">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mate-diff-sp">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pref-same-sp">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Population_dynamics_HybridCheck" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count monkeys with [specie = 0]</metric>
    <metric>count monkeys with [specie = 1]</metric>
    <metric>count monkeys with [(specie != 0) and (specie != 1)]</metric>
    <metric>count fragments with [population &gt; maximum_density]</metric>
    <metric>max [population] of fragments</metric>
    <metric>count monkeys</metric>
    <enumeratedValueSet variable="n-monkeys">
      <value value="1500"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-fragments">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-dispersion">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mate-diff-sp">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pref-same-sp">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Population_dynamics2" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count monkeys with [specie = 0]</metric>
    <metric>count monkeys with [specie = 1]</metric>
    <metric>count monkeys with [(specie != 0) and (specie != 1)]</metric>
    <metric>count fragments with [population != 0]</metric>
    <metric>count fragments with [population &gt; maximum_density]</metric>
    <metric>max [population] of fragments</metric>
    <metric>count monkeys</metric>
    <enumeratedValueSet variable="n-monkeys">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-fragments">
      <value value="100"/>
      <value value="300"/>
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-dispersion">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mate-diff-sp">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pref-same-sp">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Final_analysis1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count fragments with [population != 0]</metric>
    <metric>count fragments with [population &gt; maximum_density]</metric>
    <metric>max [population] of fragments</metric>
    <metric>count monkeys</metric>
    <metric>count fragments with [any? group with [species != 0 and species != 1]]</metric>
    <metric>count monkeys with [species != 0 and species != 1]</metric>
    <metric>dispersants-total</metric>
    <metric>dispersants-loser</metric>
    <metric>dispersants-winner</metric>
    <enumeratedValueSet variable="Filename">
      <value value="&quot;C:\\Users\\Amely\\Documents\\Amely_UT\\Courses\\Spring_2014\\Agent_Based_Simulation_Modeling\\Project\\Images\\Hibridization50_expview4.png&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-fragments">
      <value value="200"/>
      <value value="500"/>
      <value value="1000"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mate-diff-sp">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-monkeys">
      <value value="500"/>
      <value value="1000"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start_disp_age">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-dispersion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion_power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pref-same-sp">
      <value value="&quot;Strictly&quot;"/>
      <value value="&quot;Preference&quot;"/>
      <value value="&quot;Any&quot;"/>
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
