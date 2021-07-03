; Alex Mead and Brendan ______'s banking networks term project



;; Implements Contagion in Financial Networks based on the article
;; by Gai and Kapadia. Version 1.2: one iteration only with banks of different sizes.

;; Based on code by:
;; Axel Szmulewiez, Blake LeBaron

;; Changes noted below

; Weight in links determines % of asset the link represents to each bank
links-own [ weight ]
; Banks have assets and liabilities (each sums up to 1)
turtles-own [
  interbank-assets
  illiquid-assets
  interbank-liabilities
  deposits
  bank-size
  liquidity-requirements ; Alex Mead added liquidity-requirements attribute which takes the value of the global parameter liquidity_coverage_ratio
  capital-requirements ; Alex Mead added capital-requirements attribute which takes the value of the global parameter capital_level_requirements
  default-closeness ;
]
; Keeps track of defaulted banks for while loop and adds buffer
globals [ defaulted-banks-0 defaulted-banks-1 buffer ]

; Sets up initial states: configures interface and bank financial
; states (with weighed links)
to setup

  clear-all
  reset-ticks
  ask patches [ set pcolor black ]
  setup-bank-structure

  ; Randomly link banks (ingoing and outgoing links)

  ; Alex Mead changed  the amount of banks that create links to other banks from a random amount of banks to amount specified by user
  let _p (%-of-banks-linked / 100) * banks
  let _q round (_p)
  ask n-of (_q) turtles [
    create-links-to n-of (random (banks - 1)) other turtles
  ]
  setup-financial-states

end

to updateGUI ;updateGUI stub created by Alex Mead
  initialize-bank-requirements
end

to startup
  set %-of-banks-linked 30
end

; Creates banks and aligns them in a circle, all blue since
; at t=0 all banks are solvent
to setup-bank-structure

  create-turtles banks
  layout-circle turtles (max-pxcor - 1)
  ask turtles [
    set color blue
    set size 2
    ; Banks have different sizes, based on random normal distribution
    ; with mean and standard deviation provided by the user
    let raw-number exp (random-normal mu sigma)
    ifelse raw-number < 1
    [ set bank-size 1 ]
    [ set bank-size round raw-number ]
    set label bank-size
  ]
  set-default-shape turtles "house"

end

; Sets up financial state of each bank. If bank has no links,
; then there are no interbank claims, and everything is
; determined by deposits and mortages (illiquid assets).
; Otherwise, make interbank assets 20% of total and distribute
; evenly among randomly generated links (interbank liabilities
; determined endogenously, one bank's asset is another's liability)
to setup-financial-states

  ask turtles [
    let number-of-ins count (my-in-links)
    ifelse number-of-ins = 0
      [ set illiquid-assets bank-size set interbank-assets 0 ]
      [ set illiquid-assets .8 * bank-size set interbank-assets .2 * bank-size
        let dummy interbank-assets   ; To use turtle attribute in a link
        ask my-in-links [ set weight dummy / number-of-ins ]
      ]

    let number-of-outs count (my-out-links)
    ifelse number-of-outs = 0
      [ set interbank-liabilities 0 set deposits bank-size]
      [ set interbank-liabilities sum [weight] of my-out-links
        set deposits bank-size - interbank-liabilities
      ]
  ]
  initialize-bank-requirements ; Calling procedure to initialize turtle attributes

end

to initialize-bank-requirements ; Procedure created by Alex Mead to initialize the liquidity and capital level requirements
  ask turtles[
  set liquidity-requirements liquidity_coverage_ratio
  set capital-requirements capital_level_requirements

  ; Mathematical calculation created by Gia and Kapeda below. I included it in here so that the user can inspect a turtle and visually see the change in
  ; the closeness to default (which is 0)
  let phi count(my-in-links with [ color = red ]) / count(my-in-links)
  set default-closeness (1 - phi) * interbank-assets + illiquid-assets + buffer - interbank-liabilities - deposits
  ]
end

to test-initialize-bank-requirements ; test procedure created by Alex Mead for initializing turtle attributes
  initialize-bank-requirements
  ask turtle 0 [
  ifelse [liquidity_coverage_ratio] of self != liquidity_coverage_ratio [ print "did not pass" ] [ print "passed" ]
  ifelse [capital_level_requirements] of self != capital_level_requirements [ print "did not pass" ] [ print "passed both" ]
  ifelse [default-closeness] of self < 0 and [color] of self != blue [ print "did not pass" ] [ print "passed three" ]
    ifelse [default-closeness] of self > 0 and [color] of self != red [ print "did not pass" ] [ print "passed all" ]
  ]
end

; Initial exogenous shock, one bank is chosen
; at random and defaults (turns red)
to exogenous-shock
  ask one-of turtles [
    set color red
    ask my-in-links [ set color red ]
    ask my-out-links [ set color red ]
  ]
end

; Starts contagion. If a bank is not solvent once an interbank asset defaults,
; then it defaults as well
to go

 set buffer .04
 ;let _p
 ask turtles with [ color = blue and count(my-in-links with [ color = red ]) > 0][
   let phi count(my-in-links with [ color = red ]) / count(my-in-links)
   if (1 - phi) * interbank-assets + illiquid-assets + buffer - interbank-liabilities - deposits < 0
     [ set color red ask my-out-links [ set color red ] ]
 ]
 updateGUI
 tick

end


;; New implementations

; Liquidity level and capital level requirements will determine how slow the bank's resources are depleated
; will act as a buffer in addition to the other buffer. We should also sever ties between networks after a contageon
; starts after several ticks.

to setup_other_network ; stub for creating secondary banking network
  ; setup-financial-states
end










@#$#@#$#@
GRAPHICS-WINDOW
407
10
870
474
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
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
43
127
218
160
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

MONITOR
276
307
365
352
NIL
count links
3
1
11

SLIDER
42
77
216
110
Banks
Banks
2
80
20.0
1
1
NIL
HORIZONTAL

BUTTON
42
173
217
206
Default Random Bank
exogenous-shock\n
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
42
217
218
250
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

MONITOR
276
363
367
408
Defaulted Banks
count turtles with [ color = red ]
17
1
11

PLOT
23
270
245
452
Defaulted Banks
t
Defaulted Banks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [ color = red ]"

INPUTBOX
256
146
306
206
mu
1.0
1
0
Number

INPUTBOX
318
146
368
207
sigma
0.5
1
0
Number

SLIDER
907
37
1109
70
liquidity_coverage_ratio
liquidity_coverage_ratio
0
1
0.28
0.01
1
NIL
HORIZONTAL

SLIDER
907
83
1110
116
capital_level_requirements
capital_level_requirements
0
10.5
5.5
0.1
1
NIL
HORIZONTAL

INPUTBOX
907
126
1016
186
%-of-banks-linked
50.0
1
0
Number

BUTTON
266
58
329
91
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

@#$#@#$#@
## WHAT IS IT?

The following program recreates the behavior of financial contagion described by Gai and Kapadia (2010). This model differs from the model described in the paper in that the user has the liberty to choose the number of banks in the network (in the original model, everything is randomly determined). This model assumes there are no fire sales (hence q = 1). Defaulted banks are represented by the color red, solvent banks are represented by the color blue.

This first version runs one round of default simulation only, with banks of different sizes. Note that the main findings of the paper are not affected by allowing bank sizes to vary.

## THINGS TO NOTICE

To run the model, first setup the world (choose number of desired banks in the network, anywhere between 2 and 200). Adjust for mean and standard deviation of bank size to set up random distribution of bank sizes. The number next to each bank indicates its relative size.

Then, default a single random bank by clicking on the button "Default Random Bank" only once. After this, hit the button "Go" to see the contagion chain effect. The model contains a graph that automatically plots the number of defaulted banks per time period. Hit "Go" again to stop the cycle once the plot shows that the number of defaults has come to an equilibrium.

## EXTENDING THE MODEL

Extensions of the model could include: sliders to choose the number of links (in order to adjust the parameter of interconnectedness "z"), making banks have different sizes, allow interbank assets not to be evenly distributed among incoming links. Please see other impemented versions.

## RELATED MODELS

-

## CREDITS AND REFERENCES

* Gai, Prasanna and Kapadia, Sujit, Contagion in Financial Networks (March 23, 2010). Bank of England Working Paper No. 383. Available at SSRN: http://ssrn.com/abstract=1577043 or http://dx.doi.org/10.2139/ssrn.1577043
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
NetLogo 6.0.4
@#$#@#$#@
setup-simple-random
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
