; --- Déclaration des variables globales ---
extensions [sound]

globals [
  distribution-center  ; Position du centre de distribution
  number-of-packages   ; Nombre de colis à livrer
  traffic-density      ; Densité de trafic
  center-patch
]

breed [vehicles vehicle]    ; Les véhicules (voitures ou camions)
breed [drones drone]        ; Les drones
breed [clients client]      ; Les clients (zones de livraison)
breed [houses house]      ; Les clients (zones de livraison)

patches-own [
  terrain-type  ; Type de terrain : route, intersection, bâtiment, centre de distribution, client
  traffic-level ; Niveau de trafic (de 0 à 3)
]

; --- Déclaration des variables ---
vehicles-own [
  delivery-target  ; Cible actuelle du véhicule (patch client)
  delivering       ; Statut de livraison (true/false)
]


; --- Initialisation des propriétés des patches ---
to setup
  clear-all
  set number-of-packages 20  ; Nombre initial de colis
  set traffic-density 2     ; Densité de trafic initiale (sur une échelle de 0 à 3)
  setup-patches             ; Configurer les routes, intersections, bâtiments et clients
  setup-distribution-center ; Configurer le centre de distribution au centre
  setup-vehicles            ; Positionner les véhicules
  setup-drones              ; Positionner les drones
  setup-clients             ; Positionner les clients (zones de livraison)
  deliver-cars
  reset-ticks
end

; --- Configuration des patches (routes, intersections, bâtiments, clients) ---
to setup-patches
  ask patches [
    if pxcor mod 5 = 0 or pycor mod 5 = 0 [
      set pcolor white         ; Définir comme route
      set terrain-type "road"
    ]
    if (pxcor mod 10 = 0 and pycor mod 10 = 0) or (pxcor mod 5 = 0 and pycor mod 5 = 0) [
      set pcolor gray          ; Définir comme intersection
      set terrain-type "intersection"
    ]
    if terrain-type = "" [
      set pcolor black         ; Définir comme bâtiment
      set terrain-type "building"
    ]
    ; Assignation de la densité de trafic aléatoire entre 0 et 3
    set traffic-level random 4
  ]
end

; --- Configurer un centre de distribution central ---
to setup-distribution-center
  create-turtles 1 [
    setxy -3.5 -16.5                   ; Placer la tortue au centre de la grille
    set shape "building store"          ; Définir la forme en carré
    set color yellow           ; Colorer la tortue en jaune pour le centre de distribution
    set size 2             ; Agrandir la taille de la tortue
  ]

  ; Marquer le patch central comme un centre de distribution
  set center-patch patch -3.5 -16.5
  ask center-patch [
    set terrain-type "distribution-center"  ; Marquer ce patch comme un centre de distribution
    set pcolor green                     ; Colorier le patch en jaune
  ]
end

; --- Positionner les véhicules sur des routes ---
to setup-vehicles
  ; Create red cars at the distribution center
  create-vehicles 5 [
    set shape "car"
    set color red             ; Red for cars
      set size 0.2                ; Size of the car
    setxy -3.5 -16.5         ; Set to the distribution center
    set heading random 360    ; Random orientation
  ]

  ; Create red trucks at the distribution center
  create-vehicles 5 [
    set shape "truck"
    set color red             ; Red for trucks
    set size 0.2                ; Size of the truck
    setxy -3.5 -16.5         ; Set to the distribution center
    set heading random 360    ; Random orientation
  ]

  ; Create other vehicles at random positions on roads
  create-vehicles 250 [
    setxy random-xcor random-ycor    ; Position vehicles randomly
    while [terrain-type != "road"] [  ; Ensure they are on a road
      setxy random-xcor random-ycor
    ]

    ; Randomly assign other vehicle types (e.g., trucks and motorcycles)
    let vehicle-type random 5  ; Randomly choose 0, 1, or 2 for vehicle type
    if vehicle-type = 0 [
      set shape "car"            ; Car
      set color orange            ; Pink for cars
        set size 1.2               ; Size of the car
    ]
    if vehicle-type = 1 [
      set shape "truck"          ; Truck
      set color orange            ; Blue for trucks
       set size 1.5              ; Size of the truck
    ]
    if vehicle-type = 2 [
      set shape "car"     ; Motorcycle
      set color orange           ; Green for motorcycles
        set size 1.5                ; Size of the motorcycle
    ]
    if vehicle-type = 3 [
      set shape "truck"          ; Truck
      set color orange           ; Green for trucks
        set size 1.5               ; Size of the truck
    ]
    if vehicle-type = 4 [
      set shape "car"            ; Car
      set color orange          ; Orange for cars
        set size 1.5               ; Size of the car
    ]
    if vehicle-type = 5 [
      set shape "truck"         ; Truck
      set color orange            ; Gray for trucks
        set size 1.5              ; Size of the truck
    ]
  ]
end



; --- Positionner les drones sur des routes ---
; --- Positionner les drones sur le centre de distribution ---
to setup-drones
  create-drones nbrDrones [
    setxy -3.5 -16.5     ; Placer les drones au centre de distribution
    set size 1.5
    set shape "hawk"      ; Forme des drones en "circle"
    set color yellow        ; Couleur bleue pour les drones
    set heading random 360 ; Orientation aléatoire
  ]
end


; --- Positionner les clients (zones de livraison) ---
to setup-clients
 ; Placement de maisons (en bleu clair)
  ask patches [
    if (pxcor mod 5 != 0 and pycor mod 5 != 0) [
      ifelse random-float 1 < 0.6 [
        set pcolor black  ; Maisons (40% des patches non-routiers)
      ][
        set pcolor blue  ; Espaces vides (60% restant)
      ]
    ]

  ]
 ; Choisir aléatoirement 10 patches avec pcolor bleu et les changer en jaune
ask n-of nbrClientsInitial patches with [pcolor = blue] [
  set pcolor yellow
]

end



to deliver-cars
  create-vehicles 1 [
    setxy [pxcor] of center-patch [pycor] of center-patch  ; Position vehicles at the center patch
    set color yellow                                       ; Set delivery car color to yellow
    set size 1.5
    set shape "car"                                        ; Optional: Set the shape of the vehicle
  ]
end




to check-delivery
  ask vehicles with [color = yellow] [  ; Only yellow delivery vehicles perform the action
    let delivery-range patches in-radius 3  ; Adjust the range if necessary

    ifelse any? delivery-range with [pcolor = yellow] [
      ask delivery-range with [pcolor = yellow] [  ; Target only yellow patches (clients)
        set pcolor blue                            ; Mark the patch as delivered
        print ("Commande livrée au patch: ")       ; Optional log for debugging

        ; Play a beep sound for successful delivery
         sound:play-note "TRUMPET" 60 64 0.5
      ]
    ] [
      ; If no orders in range, check if any global orders remain
      if not any? patches with [pcolor = yellow] [
        print "Toutes les commandes ont été livrées. Retour au centre de distribution."
        move-to center-patch  ; Return the vehicle to the center
        set color red        ; Change the color to indicate inactivity
        set size 1.5
        ; Play a beep sound for returning to the center
        sound:play-note "TRUMPET" 60 64 0.5

        ; Generate new orders and a new delivery vehicle

      ]
    ]
  ]

  ; Check if all orders are delivered
  if not any? patches with [pcolor = yellow] [
    print "Toutes les commandes ont été livrées. Création de nouvelles commandes et d'une nouvelle voiture."
    ask vehicles with [color = yellow] [
     set color orange
      set size 1.5
    ]
    ; Play a beep sound for completing all orders
     sound:play-note "TRUMPET" 60 64 0.5
     create-new-orders-and-vehicle
   ; create-new-orders-and-vehicle  ; Call a procedure to handle new orders and vehicles
  ]
end








to go
  ; Make delivering cars move logically towards clients
ask vehicles with [color = yellow] [
  ; Only delivering vehicles
  ; Check if there are any remaining clients
  ifelse any? patches with [pcolor = yellow] [
    ; Find the nearest client (patch with pcolor = yellow)
    let target min-one-of patches with [pcolor = yellow] [distance myself]

    ; Calculate the direction to the target
    let dxx [pxcor] of target - pxcor
    let dyx [pycor] of target - pycor

    ; Determine the preferred direction (horizontal or vertical) to move closer
    ifelse abs dxx > abs dyx [
      if dxx > 0 [set heading 90]       ; Move east
      if dxx < 0 [set heading 270]      ; Move west
    ] [
      if dyx > 0 [set heading 0]        ; Move north
      if dyx < 0 [set heading 180]      ; Move south
    ]

    ; Ensure the vehicle stays on roads or intersections
    let attempts 0  ; Counter for attempts to find valid heading
    while [not can-move-on-road? 1 and attempts < 5] [
      rt random 45   ; Adjust direction slightly
      set attempts attempts + 1
    ]
    ifelse can-move-on-road? 1 [
      fd 1  ; Move forward if a valid road is found
    ] [
      ; Fallback mechanism if stuck
      rt random 360  ; Completely randomize direction
      fd 1           ; Force a move to get unstuck
      print (word "Vehicle at " self " was stuck and forced to move")
    ]
  ] [
    ; If no clients remain, return to the distribution center
    let center-patchs one-of patches with [terrain-type = "distribution-center"]
    ifelse center-patchs != nobody [
      move-to center-patchs
      set color red ; Mark the vehicle as inactive
    ] [
      print "No distribution center found!"
    ]
  ]
]


  ; Move other vehicles randomly
  ask vehicles with [color != yellow] [
    let speed 1
    ; Check the traffic level on the patch ahead
    if patch-ahead 1 != nobody [
      let current-traffic [traffic-level] of patch-ahead 1
      if current-traffic = 1 [set speed 3] ; Low traffic
      if current-traffic = 2 [set speed 2] ; Medium traffic
      if current-traffic = 3 [set speed 1] ; High traffic
    ]

    ; Ensure the vehicle stays on roads or intersections
    let attempts 0
    while [not can-move-on-road? speed and attempts < 5] [
      rt random 45  ; Slightly adjust direction
      set attempts attempts + 1
    ]

    ifelse attempts < 5 [
      fd speed
    ] [
      rt random 45  ; If no valid direction found, turn slightly
    ]
  ]

  check-delivery

  tick
end

; Helper function to check if the patch in the heading direction is valid
to-report can-move-on-road? [distancee]
  report [terrain-type] of patch-ahead distancee = "road" or
         [terrain-type] of patch-ahead distancee = "intersection"
end
@#$#@#$#@
GRAPHICS-WINDOW
350
10
1411
682
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
-40
40
-25
25
0
0
1
ticks
30.0

BUTTON
137
47
200
80
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

BUTTON
27
44
93
77
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
35
113
207
146
nbrClientsInitial
nbrClientsInitial
1
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
37
168
209
201
nbrDrones
nbrDrones
0
100
13.0
1
1
NIL
HORIZONTAL

SLIDER
42
223
214
256
nbrVehicules
nbrVehicules
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
55
292
214
337
Nombre de commandes
count( patches with [ pcolor = yellow ])
17
1
11

PLOT
32
353
232
503
Nombre de commandes livrées par le temps
temps
commandes livrées
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count( patches with [ pcolor = yellow ])"

PLOT
37
523
237
673
comparaison de temps de livraison drones/vehicules
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
"default" 1.0 0 -16777216 true "" "plot count turtles"

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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

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
