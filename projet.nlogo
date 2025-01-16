; --- Déclaration des variables globales ---
globals [
  distribution-center  ; Position du centre de distribution
  number-of-packages   ; Nombre de colis à livrer
  traffic-density      ; Densité de trafic
]

breed [vehicles vehicle]    ; Les véhicules (voitures ou camions)
breed [drones drone]        ; Les drones
breed [clients client]      ; Les clients (zones de livraison)
breed [houses house]      ; Les clients (zones de livraison)

patches-own [
  terrain-type  ; Type de terrain : route, intersection, bâtiment, centre de distribution, client
  traffic-level ; Niveau de trafic (de 0 à 3)
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
  let center-patch patch -3.5 -16.5
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
        set size 1.2                ; Size of the motorcycle
    ]
    if vehicle-type = 3 [
      set shape "truck"          ; Truck
      set color orange           ; Green for trucks
        set size 1.5               ; Size of the truck
    ]
    if vehicle-type = 4 [
      set shape "car"            ; Car
      set color orange          ; Orange for cars
        set size 1.2               ; Size of the car
    ]
    if vehicle-type = 5 [
      set shape "truck"         ; Truck
      set color orange            ; Gray for trucks
        set size 1.2               ; Size of the truck
    ]
  ]
end



; --- Positionner les drones sur des routes ---
; --- Positionner les drones sur le centre de distribution ---
to setup-drones
  create-drones nbrDrones [
    setxy -3.5 -16.5     ; Placer les drones au centre de distribution
    set size 2
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


; --- Exécution de la simulation ---
to go
  ; Faire avancer les véhicules en fonction de la densité du trafic
  ask vehicles [
    let speed 1
    ; Vérifier la densité de trafic sur le patch devant
    if patch-ahead 1 != nobody [
      let current-traffic [traffic-level] of patch-ahead 1
      if current-traffic = 1 [set speed 0.5] ; Trafic faible
      if current-traffic = 2 [set speed 0.3] ; Trafic moyen
      if current-traffic = 3 [set speed 0.1] ; Trafic élevé
    ]

    ; Vérifier si le patch devant est une route ou une intersection
    if [terrain-type] of patch-ahead 1 = "road" or [terrain-type] of patch-ahead 1 = "intersection" [
      ; Ajouter une chance aléatoire de faire marche arrière
      let move-backward? random 10 ; 10 chance to move backward (adjust the number for more or less probability)
      ifelse move-backward? < 1 [
        bk speed ; Faire marche arrière
      ]
      [
        fd speed ; Continuer en avant
      ]
    ]

    ; Si le patch devant est une intersection, tourner aléatoirement à gauche ou à droite
    if [terrain-type] of patch-ahead 1 = "intersection" [
      let turn-direction random 3  ; Choisir aléatoirement 0 ou 1
      if turn-direction = 0 [
        rt 90  ; Tourner à droite
      ]
      if turn-direction = 1 [
        lt 90  ; Tourner à gauche
      ]
      if turn-direction = 3 [
        fd speed  ; Continuer tout droit
      ]
    ]

    ; Si le terrain n'est ni une route ni une intersection, tourner aléatoirement
    if not( [terrain-type] of patch-ahead 1 = "road" or [terrain-type] of patch-ahead 1 = "intersection" ) [
      right random 90  ; Tourner à droite de façon aléatoire
      left random 90   ; Ou tourner à gauche de façon aléatoire
    ]
  ]

  ; Faire avancer les drones
  ask drones [
    fd 1  ; Les drones avancent d'un patch
  ]

  tick
end