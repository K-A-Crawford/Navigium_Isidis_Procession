 extensions [ GIS CSV ]

globals [
  cityscape                       ;; parameter used to denote the extended cityscape. Imported as .shp from GIS
  streets                         ;; parameter used to denote streets. Imported as .shp from GIS
  street-network                  ;; parameter used to denote a center-line street network. Imported as .shp from GIS
  width                           ;; parameter used to denote a street over 7m in width. Imported as .shp from GIS
  portico                         ;; parameter used to denote the presence of a protico along a street. Imported as .shp from GIS
  commercial                      ;; parameter used to denote buildings defined as having a commercial function. Imported as .shp from GIS
  production                      ;; parameter used to denote buildings defined as having a production function. Imported as .shp from GIS
  domestic                        ;; parameter used to denote buildings defined as have a residential function. Imported as .shp from GIS
  religious                       ;; parameter used to denote buildings defined as having a religious function. Imported as .shp from GIS
  public                          ;; parameter used to denote buildings defined as having a public function. Imported as .shp from GIS
  coastline
  arrived-goal
  destination                    ;; final endpoint of the procession
  watch-location
  temp-tar                        ;; parameter that determines which patch the leader is moving towards
  target                          ;; parameter that sets a temporary target for the leader, but its visibility has to first be checked
  viewshed?
  vis?
  the-leader                      ;; parameter that designates one turtle within a procession as the leader.
  bldg-designation                ;; parameter that denotes if a patch is defined as any type of building
  bldg-list                       ;; used for determining which patches belong to a list of buildings
    ]

patches-own  [
   street?                        ;; true if patch is part of a street
   comm                           ;; patches defined as commercial
   prod                           ;; patches defined as production
   dom                            ;; patches defined as domestic
   rel                            ;; patches defined as religious
   pub                            ;; patches defined as public
   width_                         ;; patches of wide streets
   portico_                       ;; patches defined as proticoes
   scape                          ;; patches defined as belonging to the extended cityscape
   coast                          ;; patches defined as belonging to the coastline
   elevation                      ;; parameter to track that a building exists which affects visibility
   obstructed?                    ;; parameter that determines if a patch obstructs the leader's view
   street-nw                      ;; patches defiend as beloning to the center-line street network
   influence                      ;; influence value of each patch
   distance-goal                  ;; parameter that tracks distance of each patch from a specified goal. Used for processions going to the seafront and for reterning to a temple
   n-distance-goal                ;; parameter that normalizes all distance values to designated goal
   r-distance-goal                ;; parameter that reverses the normalized values so the highest values are now closest the the designated goal
   obs-inf                        ;; parameter that attracts observers to a location
   radius-range                   ;; parameter for determining where Observers begin
   export-results                 ;; parameter used to record patches that have been traversed
   visited?                       ;; leaders, designate if a patch has been previously visited
   ptype                          ;; parameter that differentiates between building and street patches associated with different buildings
   procession-route               ;; parameter that tracks every patch passed by the processional leader. Used to export run at end of simulation
      ]

breed [ leaders leader ]          ;; the agent in the model that is associated with a specified temple. They determine the route that the other processional participants should follow

breed [ observers observer ]      ;; the agents in the model that are Ostia city-dwellers. They are interested in watching the procession, but they will not follow or intentionally move towards the procession. They are positioned randomly along Ostia’s streets and can only move along streets

observers-own
    [ watching                    ;; parameter that determines if an observer is actively watching a procession
      nearest-group
      count-down]                 ;; reporter, parameter that tracks the number of ticks left before an observer can begin moving

leaders-own [
  traveled?                       ;; parameter to keep track of if a leader has traveled to a target yet or not
  visited-list                    ;; parameter that tracks which patches a leader has already travelled across so that they do not return to patches previously crossed
  viewshed-list
  home-xy                         ;; parameter that can be used to set the leader's start patch as the return destination
  moved?                          ;; parameter to track if the leader moved during the last tick, if not it will triger procedure to ensure agent does not get unecessarily stuck
     ]



;;;;;;;;; setup ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  create-environment          ;; this creates the model environemnt
  setup-edges                 ;; this creates a boarder around every building that connects to the street. These are the patches that can be called as a target by leaders
  diffuse-influence
  create-goal-gradient
  reverse-gradient
  update-influnce-with-goal
  setup-observer-influence
  display-agents
  observers-select-viewing-location
end

to reset-parameters           ;; this sets/resets the building influence values along the border patches (setup-edges) of all the buildings
  cd                          ;; clears drawing of processional route
  ct                          ;; clears turtels from previous runs
  reset-variables             ;; resets previous influence values
  diffuse-influence
  create-goal-gradient
  reverse-gradient
  update-influnce-with-goal
  setup-observer-influence
  display-agents
  observers-select-viewing-location
end

to display-agents             ;; separate setup procedure allows mutiple runs with different number of agents without resetting the environment
  reset-ticks                 ;; set ticks back to 0
  setup-processionals
  setup-observers
end

;;;;;;;;; to go  ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ifelse arrived-goal = true
  [stop]
  [process
   tick]
end


;;;;;;;;; setup procedures ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-environment
  ask patches [set pcolor white]    ;; sets background of model white

;;;;;;;;; import GIS shapefiles ;;;;;;;;;;
;; all of the relevant GIS shapefiles are loaded as well as the associated coordinate system ;;

  gis:load-coordinate-system "Ostia_cityscape.prj"
  set commercial gis:load-dataset "extCommercial.shp"                     ;; includes commercial bldgs idenfied by geophysical survey
  ;set commercial gis:load-dataset "commercial.shp"                       ;; inlcudes only excavated commercial bldgs
  set production gis:load-dataset "production.shp"
  set domestic gis:load-dataset "Final_domestic.shp"
  set religious gis:load-dataset "religious.shp"
  set public gis:load-dataset "public.shp"
  set cityscape gis:load-dataset "Ostia_cityscape.shp"
  set streets gis:load-dataset "Ostia_streets.shp"
  set coastline gis:load-dataset "Coastline.shp"
;;  set street-network gis:load-dataset "Ostia_centreline_nw.shp"          ;; full street network including non-through streets
  set street-network gis:load-dataset "Ostia_centreline_nw_shortened.shp"  ;; discounts dead-end streets around Serapeum to speed up simulation time
  set width gis:load-dataset "width.shp"
  set portico gis:load-dataset "porticoes.shp"

  resize-world -600 600 -400 400
  set-patch-size 0.7

  setup-world-envelope

;;;;;;;;;; PATCH procedures: display GIS cityscape and building classifications as patches  ;;;;;;;;;;;;
  ask patches
 [ ifelse gis:intersects? cityscape self [
      set scape true
    ]
  [
      set scape false
    ]
  ]
  ask patches with [ scape ]
  [ set pcolor grey + 4
    set ptype "building"
    set elevation 50]

 ask patches
   [ ifelse gis:intersects? commercial self [
      set comm true
    ]
  [
      set comm false
    ]
  ]
  ask patches with [ comm ]
  [ set pcolor green + 2
    set ptype "building"
    set elevation 50]

  ask patches
 [ ifelse gis:intersects? production self [
      set prod true
    ]
  [
      set prod false
    ]
  ]
  ask patches with [ prod ]
  [ set pcolor orange
    set ptype "building"
    set elevation 50]

   ask patches
 [ ifelse gis:intersects? domestic self [
      set dom true
    ]
  [
      set dom false
    ]
  ]
  ask patches with [ dom ]
  [ set pcolor yellow
    set ptype "building"
    set elevation 50]

    ask patches
 [ ifelse gis:intersects? religious self [
      set rel true
    ]
  [
      set rel false
    ]
  ]
  ask patches with [ rel ]
  [ set pcolor pink
    set ptype "building"
    set elevation 50]

    ask patches
 [ ifelse gis:intersects? public self [
      set pub true
    ]
  [
      set pub false
    ]
  ]
  ask patches with [ pub ]
  [ set pcolor blue
    set ptype "building"
    set elevation 50]


 ask patches
  [ ifelse gis:intersects? streets self [
    set street? true
    ]
    [
      set street? false
    ]
  ]
 ask patches with [ street? ]
  [ set pcolor black
    set ptype "street"
    set elevation 2]

  ask patches
  [ ifelse gis:intersects? coastline self [
      set coast true
    ]
  [
      set coast false
    ]
  ]
  ask patches with [ coast ]
      [ set pcolor 38 ]

  ask patches
  [ ifelse gis:intersects? street-network self [
    set street-nw true
    ]
    [
      set street-nw false
    ]
  ]
 ask patches with [ street-nw ]
  [ set pcolor black
    set ptype "street-nw"]

 ask patches
  [ ifelse gis:intersects? width self [
    set width_ true
    ]
    [
      set width_ false
    ]
  ]
; ask patches with [ width_ ]
;  [ set pcolor 2];obs-inf o-influence ]

  ask patches
  [ ifelse gis:intersects? portico self [
    set portico_ true
    ]
    [
      set portico_ false
    ]
  ]
end

;;;;;;;;;;; create border patches between buildings and streets;;;;;;;

;; Any streets directly boardering a building will be attributed with that building's influence value
;; This ensures that the influence value can be registered by the leader without requiring the agent to enter the different buildings.
;; This also ensures that the agent remains confined to traveling along the city's street network

to setup-edges
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = green + 2]
      [set ptype "commercial_street"
       set influence commercial-influence]
    ]
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = orange]
      [set ptype "production_street"
       set influence production-influence]
    ]
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = yellow]
      [set ptype "domestic_street"
       set influence domestic-influence]
    ]
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = blue]
      [set ptype "public_street"
       set influence public-influence]
    ]
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = pink]
      [set ptype "religious_street"
       set influence religious-influence]
    ]
  ask patches with [pcolor = black]
    [if any? neighbors with [pcolor = grey + 4]
      [set ptype "unexcavated_street"
       set influence un/exc-influence]                               ;; provides a low influence value to the unexcavate cityscape so movement in not completely discounted from this area of the city
    ]
  ask patches with [pcolor = 38]
    [if any? neighbors4 with [pcolor = black ]
      [set pcolor 38 - 2
       ]
     ]
  ask patches with [pcolor = 38]
    [if any? neighbors4 with [pcolor = grey + 4]
      [set pcolor 38 - 2
        ]
     ]

  repeat 3 [expand-influence]

  ;; some code to speed up model and skip excess viewshed models ;;
  ask patch -201 -159 [set influence influence + 2]     ;; slight issue with patch geometry/centre line at this point. This fix ensures the processional leader does not get stuck in endless movement loop
  ask patch -244 -254 [set influence influence + 3]

  ; diffuse-influence    ;; can alternatively use button on interface to run this procedure

  ask patches with [pcolor = 38]
    [if any? neighbors4 with [pcolor = black]
      [set ptype "street"
        ]
    ]
  ask patches with [pcolor = 84]
    [if any? neighbors4 with [pcolor = black]
      [set ptype "street"
        ]
    ]
 if extended-influence = true [
    ask patches with [pcolor = grey + 4]
      [if any? neighbors4 with [pcolor = black]
        [set pcolor grey
         set ptype "building"
        ]
       ]
    ]
  ask patches [set procession-route 0]          ;; initilize model to record the route of the procession

  setup-observer-influence                      ;; initilize and set up parameters for observers
end

to setup-observer-influence                     ;; colors can be used to check location of edge patches corresponding to wide streets and porticoes
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 57]
      [set obs-inf o-influence]]
       ; set pcolor red] ]
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 25]
     [set obs-inf o-influence]]
    ;  [set pcolor red] ]
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 45]
      [set obs-inf o-influence]]
     ; [set pcolor red] ]
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 105]
      [set obs-inf o-influence]]
     ; [set pcolor red] ]
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 135]
      [set obs-inf o-influence]]
     ; [set pcolor red] ]
  ask patches with [width_ or portico_]
    [if any? neighbors4 with [pcolor = 9]
      [set obs-inf o-influence]]
end


to setup-world-envelope                                                         ;; defines the limits of the world parameters of the interface
  gis:set-world-envelope gis:envelope-of cityscape
  let world gis:world-envelope
  gis:set-world-envelope world
end

to expand-influence                                                             ;; attribute the influence of each building to its corresponding street front
   ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "commercial_street"]
      [set ptype "commercial_street"
       set influence commercial-influence]
    ]
  ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "production_street"]
      [set ptype "production_street"
       set influence production-influence]
    ]
  ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "domestic_street"]
      [set ptype "domestic_street"
       set influence domestic-influence]
    ]
  ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "public_street"]
      [set ptype "public_street"
       set influence public-influence]
    ]
  ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "religious_street"]
      [set ptype "religious_street"
       set influence religious-influence]
    ]
  ask patches with [pcolor = black and influence = 0]
    [if any? neighbors with [ptype = "unexcavated_street"]
      [set ptype "unexcavated_street"
       set influence un/exc-influence]
   ]
end

to diffuse-influence                                                            ;; PATCH procedure to even out the influence values along the street
  diffuse influence diffuse-rate
  ask patches with [pcolor != black]                                            ;; since diffusion will go over building patches as well, this reverts all buildings to having an influnce value of 0, ensuring that influence is restricted to street patches only
    [set influence 0]
  ask patches with [pcolor = black and not street-nw]
    [set influence 0]

end

to create-goal-gradient                                                        ;; setup procedure that creates gradeint from Serapeum to seafront
  if Seafront = true [
     let f-goal patch -252 -270                                                   ;; particular point on the seafront chosen as the ending destination. This can be adjusted
     ask patches with [street-nw]
      [set distance-goal distance f-goal ]
    set destination f-goal]
  if Harbour = true [
    let f-goal patch -568 -26                                                   ;; particular point on the seafront chosen as the ending destination. This can be adjusted
    ask patches with [street-nw]
      [set distance-goal distance f-goal]
    set destination f-goal]
end

to reverse-gradient                                                           ;;PATCH procedure that normalizes and reverses the distance gradient to the seafront
 if Seafront = true [
  ask patches with [street-nw]
    [
    set n-distance-goal  (distance-goal / 716.8)                             ;; value 716.8 represents the furthest value from the Serapeum to the edge of the simulation environment
    set r-distance-goal ((1 - n-distance-goal) * 100)
  ]]
  if Harbour = true [
  ask patches with [street-nw]
    [
    set n-distance-goal  (distance-goal / 699.7)                             ;; value 716.8 represents the furthest value from the Serapeum to the edge of the simulation environment
    set r-distance-goal ((1 - n-distance-goal) * 100)
  ]]
end

to update-influnce-with-goal                                                 ;;PATCH procedure, the reverse distance gradient is added to the centre-line street network values
   ask patches with [street-nw]
       [set influence (influence + r-distance-goal)]
end

to show-g-gradient
  ifelse g-gradient = true
   [ ask patches with [street-nw]
      [set pcolor scale-color green distance-goal 750 0]
  ]
   [ask patches with [street-nw]
    [set pcolor black]
   ]
end

to-report furthest-goal-distance
  report [distance-goal] of furthest-goal-patch
end

to-report furthest-goal-patch
  report max-one-of patches [distance-goal]
end

to-report closest-goal-distance
 report [distance-goal] of closest-goal-patch
end

to-report closest-goal-patch
    report min-one-of patches [distance-goal]
end

;;;;;;;;;;;next setup procedure;;;;;;;;;;;;;;;;;;;;;;;;;
to reset-variables            ;; PATCH procedure to reset the building influence values without re-loading the entire model environment
 ask patches [                ;; sets all patches that agents have walked across back to 0
    set visited? 0            ;; initialize the model by ensuring that none of the patches have been visited
    set procession-route 0    ;; removes the previous recorded processional route from the model and initializes it for the next simulation run
    set obs-inf 0
    set radius-range 0
    set export-results 0]
  ask patches with [street? or street-nw]
    [set pcolor black
     set distance-goal 0
     set n-distance-goal 0
     set r-distance-goal 0]
  ask patches with [pcolor = black]
    [set influence 0]
 set arrived-goal false

  setup-edges
  repeat 3 [expand-influence]

;; if this is switched “on” in the interface, then influence values will be attributed to the extended cityscape buildings plots of land
  if extended-influence = true [
   ask patches with [pcolor = grey]
   [
   ifelse random-inf = true
;; if the switch is on/true, influence values are randomly attributed to ‘buildings’ located within the street network of the extended cityscape
;; this enables the agents to move within the extended cityscape rather than being predominately confined to the excavated city
            [set influence random 5
             set ptype "building"]
            [set influence ext-influence
             set ptype "building"]
   ]
  ]
  set bldg-list [9 57 25 45 135 105 36 82]
  set bldg-designation bldg-list          ;; patch list inclusive of specific pcolors


end


;;;; check influence and diffusion commands ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to show-street-nw
  if nw? = true [
    ask patches with [street-nw] [set pcolor red]
    ]
  if nw? = false [
    ask patches with [street-nw] [set pcolor black]
    ]
end

to show-influence
  if show-influence? = true [
    ask patches with [pcolor = black] [set pcolor scale-color red influence 10 0 ]
    ]
  if show-influence? = false [
    ask patches with [street?] [set pcolor black]]
end

to show-obs-influence
  if show-obs-inf? = true [
    ask patches with [width_ or portico_] [set pcolor red]
    ]
  if show-obs-inf? = false [
    ask patches with [width_ or portico_] [set pcolor black]
    ]
end

to show-influence-diffusion
  if show-diffusion? = true [
    ask patches with [pcolor = black] [set pcolor scale-color red influence 1 10 ]
     ]
  if show-diffusion? = false [
    ask patches with [street?] [set pcolor black]]
end

;;;;;;;;;;;Observer setup ;;;;;;;;;;


to setup-observers
  create-observers num-observers [
    set size 3
    set color blue + 2
    set shape "person"
    set watching false
    set count-down ticks-to-observe          ;; this specifies how long an observer will stay in place and watch a procession. Specificed by slider in the interface
     ]
 ask observers [
     move-to one-of patches with [radius-range = 1]
      ]
end


to setup-processionals
    ;; initialize all parameters. This makes sure the model knows that none of the agents have moved and that all parameters are set to 0
    create-leaders 1
   [
    setxy -296 -17          ;; coordinates for placement of processionals agents in front of the Serapeum on the street
   ; set home-xy patch-here  ;; parameter that set the start patch as the same patch that will be returned to
    ask patch -296 -17 [set ptype "destination"]
    set visited-list []     ;; creates a list of patches that are visited by the leader, this sets the number of patches as 0
    set viewshed-list []    ;; creates a list of patches that cannot be targets due to being opstructed by view by a building. This sets the number of patches as 0
    set size 3
    set color red
    set shape "person"
    set the-leader self
    set heading 90
    set traveled? false
    set moved? false
    if draw-route = true   ;; if true, a route will be traced following the leader
      [ pen-down ]
    ]
    ask leaders [
      define-target
       ]

  ask leaders [            ;; procedure of determining where observers can be created in-radius of the processional leader.
    ask patches in-radius observer-radius
    [ifelse pcolor = black
      [set radius-range 1]
      [set radius-range 0]
     ]
  ]
end


;;;;;;; target procedures ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;AGENT LEADER CALLED PROCEDURE
to define-target                       ;; this defines the initial destination of leaders
  if ticks <= procession-ticks         ;; procession-ticks can be used to limit the duration of the procession.
   [set temp-tar highest-influence
    ask temp-tar [set vis? false ] ;set pcolor red (can be used to check patch choice)
    face temp-tar
    check-viewshed
     ]
  if ticks = procession-ticks          ;; once ticks reach pre-defined value, the procession will call the return home calculation
        [stop]
end

to check-viewshed  ;; agent procedure
   ifelse distance temp-tar <= 1
    [ set vis? true
      set target temp-tar]
    [ mark-viewshed
      determine-target
     ]
end


to mark-viewshed  ;; agent procedure that checks if the selected tem-target is actually directly visible and not behind a building. This ensures that movement stays confined to the street network and does not travel through buildings
  let dist 1
  let a1 0
  let last-patch patch-here
  while [dist <= distance temp-tar]
    [ let p patch-ahead dist
      if p != last-patch [
        let a2 atan dist (elevation - [elevation] of p)
      ifelse a1 <= a2
          [ ask p [ set viewshed? true]; set pcolor blue + 2
            set a1 a2 ]
        [ set viewshed? false]
        set last-patch p
      ]
      set dist dist + 1
    ]
  ask temp-tar
    [if viewshed? = true
      [if any? neighbors with [viewshed? = true]
        [set vis? true ] ]] ;;;set pcolor yellow
 end

to determine-target  ;; agent procedure
  ask temp-tar
    [ifelse vis? = true
       [ask the-leader
          [set target temp-tar
           set viewshed-list [] ]
         ]
      [ask the-leader
         [set viewshed-list lput temp-tar viewshed-list
          set temp-tar highest-influence
          face temp-tar
          check-viewshed]]
    ]
end


;;;;;;;;;;;run-time procedure;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to process
  move-leaders
  check-leader-list
end


to check-leader-list
  ask leaders [
    if ticks >= 500 [set visited-list remove-item 0 visited-list] ] ;; speeds up calculation for determining the next target patch by only considering the most recent 500 patches traversed
end

;;;;;;;;;leader procedures;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-leaders
  ask leaders [
    ifelse target != nobody [
      ifelse target = destination;patch -568 -24;patch -252 -270 or patch -568 -24
        [set arrived-goal true]

     [ if distance target <= 0
        [define-target]

      ifelse distance target > 1
        [travel-leaders]

     ;; agent moves to the highest influence patch. This patch is then placed within the visited list so the agent cannot visit it again during this run of the simulation or until it is removed from the patch-list
        [move-to target
         set visited-list lput target visited-list
         ask patch-here [set export-results 1]
         ]
      ]
      ]
    [print "No target available"]
   ]

end


to travel-leaders
    move-towards-target
end

to move-towards-target
   ifelse [pcolor] of patch-ahead 1 != black
     [Avoid-Function]
     [Move-Function]

;  ]
end


;;;;;;

to Move-Function
 let t target
      if any? all-possible-moves
          [face min-one-of all-possible-moves [distance t]    ;; takes into account all the possible ways of reaching the target patch and choses the best next patch to face towards
           fd 1
           ask patch-here
             [set visited? 1
              set procession-route 1]
          ]
end


to Avoid-Function ;(original code )
 let t target
  if any? all-possible-moves
      [face min-one-of all-possible-moves [distance t] ]  ;;;; takes into account all the possible ways of reaching the target patch and choses the best next patch to move towards
end

to leave-a-trail
  ask patch-here [set visited? 1]   ;; if values are greater than 0, than the associated reporter will discount this patch from calculations to determine the next highest influence value and therefore possible target locations
end

to determine-destination
  ask leaders [
   define-target]
end

;;;;; code for visualizing the route taken by the processional leader each run ;;;;
to show-procession-route
  if show-procession? = true
    [ask patches with [procession-route] [set pcolor red]]
  if show-procession? = false
    [ask patches with [procession-route] [set pcolor black]]
end


;;;;;; building influence reporter calculations ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-target
   ask leaders [
    set target highest-influence
    check-viewshed
    if obstructed? = true
      [set target highest-influence2
       check-viewshed]
    ]
end


to-report location-leader
  report [patch-here] of the-leader
end


to-report highest-influence   ;; ensures that the most desirable patch to visit next has the highest influence value in relation to the agent’s current position
   let to-visit patches in-radius 200 with [                          ;; limits possible patches within a 200 degree radius, this greatly improves speed of influence calculation
      pcolor = black and                                              ;; Model only considers street patches
     self != location-leader and                                     ;; Model looks for a to-visit patch other than where the leader is currently positioned
     influence > 0 and                                               ;; Model only includes patches that compose the street network, which have an influence value > 0
     not member? self [visited-list] of myself and                   ;; Model does not include patches previously visited by the leader
     not member? self [viewshed-list] of myself]                     ;; Model does not include patches that are not visible, this is only included when called by teh viewshed test
    report max-one-of to-visit [ influence / ( distance myself ) ]     ;; Observer procedure to select one target
end

;; PATCH FUNCTION
;;checks that the chosen target is visually accessable and not behind a buildings. If it is, another accessible highest-influence target will be selected



to-report highest-influence2

  let to-visit patches in-radius 100 with [                        ;; only patches that are winin a 200 degree cone of 50 patches in front of the leader are considered - this greatly improves speed of the model by not considering all patches within the model's environment
     pcolor = black and                                              ;; Model only considers street patches
     self != location-leader and                                     ;; Model looks for a to-visit patch other than where the leader is currently positioned
     influence > 0 and                                               ;; Model only includes patches that compose the street network, which have an influence value > 0
     not member? self [visited-list] of myself and                   ;; Model does not include patches previously visited by the leader
     not member? self [viewshed-list] of myself]
 ; report max-one-of to-visit [ influence / ( distance myself ) ]     ;; Observer procedure to select one target
  let t max-one-of to-visit [ influence / ( distance myself ) ]     ;; Observer procedure to select one target

end


to-report return-influence ;; procedure to be used if using the A* pathfinding algorithm
   let to-visit patches with [
     influence = 50 and           ;; only patches with a value of 50 will be considered in order to follow the route returning to the temple start point
     not member? self [visited-list] of myself ]
  report max-one-of to-visit [ influence / ( distance myself ) ]
end

to-report all-possible-moves
 ;; report neighbors with [pcolor = black and visited? = 0 and distance myself  <= 1 or distance myself  > 0 ]
  report neighbors4 with [pcolor = black and distance myself <= 1 and distance myself  >= 0 ]
 end

;;;;;;;;;;;;;;;; to run urban agents procedures ;;;;;;;;;;;;;;;;;;;;;

to observers-select-viewing-location
  repeat 40 [move-observers1]      ;; repeat value allows observers sufficent time to find a watch location before the start of the procession
  ask observers [add-to-influence] ;; each observer's influence is added to the street gradient
end

to move-observers1
  ask observers
    [find-watch-location]
end


to find-watch-location
  ifelse any? observers in-radius o-watching-radius with [watching = true]
    [;set color orange
      find-nearest-group]
    [set color white
     define-watching-location]
end

to find-nearest-group
  set nearest-group min-one-of observers with [watching = true] [distance myself]
  face nearest-group
  join-group
end

to join-group
  if distance nearest-group = 0
    [set watching true
     set color yellow
     stop]
  ifelse distance nearest-group < 1
    [move-to nearest-group set color pink]
    [ifelse [pcolor] of patch-ahead 1 != black and not any? other turtles-on patch-ahead 1
        [rt random 90]
        [fd 1]]
end

to add-to-influence
  ask patches in-radius 6 with [street-nw]
    [;set pcolor red  ;; check to visualise areas of added influence
     set influence influence + o-influence]
end

to define-watching-location
  set watch-location possible-watching-location
   ifelse watch-location != nobody [
   if distance watch-location = 0
    [set watching true
     set color pink
     stop]
    if distance watch-location <= 1
     [move-to watch-location
      set color magenta
      add-to-influence
      stop]
    if distance watch-location > 1
     [set color yellow
     ; fd 1]
      ifelse [pcolor] of patch-ahead 1 != black  and not any? other turtles-on patch-ahead 1
        [rt random 90]
        [fd 1]]
  ]
  [print "no watch location for observer"]
end


to-report all-possible-watch-moves
  report neighbors4 with [ pcolor = black and distance myself <= 1 and distance myself  >= 0 ]
 end

to-report possible-observer-group
  let group-options observers in-radius 10 with [watching = true]
  ifelse any? group-options
  [report max-one-of group-options [distance myself] ]
  [report watching = false]
end

to-report possible-watching-location
  let watch-patches patches with [  obs-inf >= o-influence];pcolor = black and
  report max-one-of watch-patches [obs-inf / (distance myself + 1 )]
end


;;;alternative observer code, can be used to limit the amount of time an observer stays to watch the procession in a particular location;;;
to stay
  set count-down count-down - 1   ;; determines the length of time an observer will stay in one position. This value is then subtracted by one each tick. Once 0 is reached, the agent can move
  if count-down = 0
    [;move-observers
     reset-count-down]
end

to reset-count-down
  set count-down ticks-to-observe
end

;;;;; OBSERVER procedure that exports the path taken by the processional leader;;;;;;;
to export-processional-route
  if jpg = true [
  ask patches with [export-results = 1]
    [set pcolor red]
    export-view (word "results" random-float 1.0 ".jpg") ]
  if GIS = true [
    let route nobody
    ask one-of patches
      [set route gis:patch-dataset export-results]
    gis:store-dataset route (word "CommRoute Obvs" random-float 1.0 ".asc")
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
490
50
1691
860
-1
-1
0.7
1
10
1
1
1
0
1
1
1
-600
600
-400
400
1
1
1
ticks
30.0

BUTTON
83
31
149
64
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
34
502
222
535
commercial-influence
commercial-influence
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
34
538
222
571
production-influence
production-influence
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
33
610
221
643
religious-influence
religious-influence
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
33
646
220
679
public-influence
public-influence
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
33
574
221
607
domestic-influence
domestic-influence
0
20
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
64
479
214
497
Ostia Building Parameters
11
0.0
1

SLIDER
276
502
459
535
num-observers
num-observers
0
500
150.0
1
1
NIL
HORIZONTAL

BUTTON
59
127
114
160
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
122
127
177
160
Go
Go
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
55
349
203
382
procession-ticks
procession-ticks
0
2500
2500.0
10
1
NIL
HORIZONTAL

SWITCH
55
193
175
226
draw-route
draw-route
0
1
-1000

SWITCH
28
786
214
819
extended-influence
extended-influence
1
1
-1000

SWITCH
8
823
126
856
random-inf
random-inf
1
1
-1000

SLIDER
128
823
238
856
ext-influence
ext-influence
0
5
0.0
1
1
NIL
HORIZONTAL

BUTTON
46
79
186
112
NIL
reset-parameters
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
28
752
229
794
Extended Cityscape Parameters if not using un/exc-influence parameter
11
0.0
1

SLIDER
271
684
454
717
ticks-to-observe
ticks-to-observe
0
30
0.0
.5
1
ticks
HORIZONTAL

SLIDER
271
721
454
754
viewing-radius
viewing-radius
0
30
0.0
1
1
patches
HORIZONTAL

MONITOR
1318
955
1439
1000
leader patch
location-leader
17
1
11

TEXTBOX
67
255
199
283
Procession Destination
11
0.0
1

SLIDER
56
406
203
439
diffuse-rate
diffuse-rate
0
1
0.2
.1
1
NIL
HORIZONTAL

SWITCH
819
918
957
951
show-diffusion?
show-diffusion?
1
1
-1000

BUTTON
973
918
1128
954
NIL
show-influence-diffusion
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
489
988
625
1021
show-influence?
show-influence?
1
1
-1000

BUTTON
642
989
797
1022
NIL
show-influence
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
281
929
434
962
show-procession?
show-procession?
0
1
-1000

BUTTON
279
965
434
998
NIL
show-procession-route
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
250
905
463
925
visualize completed processional route
11
0.0
1

BUTTON
272
107
436
140
NIL
export-processional-route\n
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
237
48
366
81
route-output?
route-output?
0
1
-1000

SWITCH
489
900
625
933
nw?
nw?
1
1
-1000

BUTTON
642
902
797
935
NIL
show-street-nw
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
1160
898
1299
943
NIL
furthest-goal-distance
17
1
11

MONITOR
1316
898
1455
943
NIL
furthest-goal-patch
17
1
11

MONITOR
1161
954
1293
999
NIL
closest-goal-distance
17
1
11

SWITCH
489
942
625
975
g-gradient
g-gradient
1
1
-1000

BUTTON
642
943
797
976
NIL
show-g-gradient
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
275
538
459
571
observer-radius
observer-radius
0
500
250.0
10
1
NIL
HORIZONTAL

SLIDER
274
614
458
647
o-influence
o-influence
0
100
30.0
1
1
NIL
HORIZONTAL

SWITCH
818
963
957
996
show-obs-inf?
show-obs-inf?
1
1
-1000

BUTTON
973
965
1130
998
NIL
show-obs-influence
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
275
576
458
609
o-watching-radius
o-watching-radius
0
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
33
681
219
714
un/exc-influence
un/exc-influence
0
20
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
225
417
435
445
**0.2 is used as the standard**
11
0.0
1

TEXTBOX
222
358
444
376
**to not limit time, set ticks at 2500**
11
0.0
1

TEXTBOX
312
477
462
495
Observer Parameters
11
0.0
1

TEXTBOX
703
874
945
902
Visulaize various enviornment settings
11
0.0
1

TEXTBOX
306
664
456
682
Additional parameters 
11
0.0
1

SWITCH
16
284
125
317
Seafront
Seafront
1
1
-1000

SWITCH
134
284
243
317
Harbour
Harbour
0
1
-1000

SWITCH
383
29
473
62
jpg
jpg
1
1
-1000

SWITCH
383
63
473
96
GIS
GIS
0
1
-1000

TEXTBOX
190
202
340
220
**Follow procession route
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates the navigium Isidis procession from the Serapeum to either the seafront or river harbour at Ostia. The movememnt of the processional leader is informed by passing buildings with different influence values and spectators that 'watch' the procession along the street. The processional leader determines a route following the highest influence values for a defined number of ticks or until the selected destination in reached. A second group of agents are observers. Observers, at the beginning of the model, if within a certain radius of the processional start point will aim to find an ideal 'watch' location.  

## HOW IT WORKS

Procession leader: at each time step calculates the next highest influence patch based on the aggregation of weighted building influence values and the weight given by nearby Observer agents.

Observers: select a watch location based on their proximity to either other observers or areas with increased street width or porticoes. 

## HOW TO USE IT

** Make sure that the model is in the same folder as the GIS files ** 

Select model parameters:
 - select procession desitation as either river harbour or sea front
 - set building influence value parameters with sliders
 - set observer parameters with sliders

Press the setup button, this loads the GIS datasets

Press the reset-paramaters button, this associates the influence values with specific buildings

Press Go to run the model. 


## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

- Traffic Grid model – Netlogo Library


- Lukas, Jiri (2014) Town - Traffic and Crowd simulation.
http://ccl.northwestern.edu/netlogo/models/community/Town%20-%20Traffic%20&%20Crowd%20simulation 




	
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
NetLogo 6.2.2
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
