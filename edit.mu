# Editor widget: takes a string and screen coordinates, and returns a new string.

recipe main [
  1:address:array:character <- new [abcdef]
  switch-to-display
  draw-box 0:literal/screen, 4:literal/top, 4:literal/left, 10:literal/bottom, 10:literal/right
  edit 1:address:array:character, 0:literal/screen, 5:literal/top, 5:literal/left, 10:literal/bottom, 10:literal/right, 0:literal/keyboard
  wait-for-key-from-keyboard
  return-to-console
]

scenario edit-prints-string-to-screen [
  assume-screen 10:literal/width, 5:literal/height
  assume-keyboard []
  run [
    s:address:array:character <- new [abc]
    s2:address:array:character, screen:address, keyboard:address <- edit s:address:array:character, screen:address, 0:literal/top, 0:literal/left, 10:literal/bottom, 5:literal/right, keyboard:address
  ]
  screen-should-contain [
    .abc       .
    .          .
  ]
]

recipe edit [
  default-space:address:array:location <- new location:type, 30:literal
  s:address:array:character <- next-ingredient
  screen:address <- next-ingredient
  # no clipping of bounds
  top:number <- next-ingredient
  left:number <- next-ingredient
  bottom:number <- next-ingredient
  bottom:number <- subtract bottom:number, 1:literal
  right:number <- next-ingredient
  right:number <- subtract right:number, 1:literal
  keyboard:address <- next-ingredient
  # traversing inside s
  len:number <- length s:address:array:character/deref
  i:number <- copy 0:literal
  # traversing inside screen
  row:number <- copy top:number
  column:number <- copy left:number
  move-cursor screen:address, row:number, column:number
  {
    +next-character
    done?:boolean <- greater-or-equal i:number, len:number
    break-if done?:boolean
    off-screen?:boolean <- greater-than row:number, bottom:number
    break-if off-screen?:boolean
    c:character <- index s:address:array:character/deref, i:number
    {
      # newline? move to left rather than 0
      newline?:boolean <- equal c:character, 10:literal/newline
      break-unless newline?:boolean
      row:number <- add row:number, 1:literal
      column:number <- copy left:number
      move-cursor screen:address, row:number, column:number
      i:number <- add i:number, 1:literal
      loop +next-character:label
    }
    {
      # at right? more than one letter left in the line? wrap
      at-right?:boolean <- equal column:number, right:number
      break-unless at-right?:boolean
      next-index:number <- add i:number, 1:literal
      next-at-end?:boolean <- greater-or-equal next-index:number, len:number
      break-if next-at-end?:boolean
      next:character <- index s:address:array:character/deref, next-index:number
      next-character-is-newline?:boolean <- equal next:character, 10:literal/newline
      break-if next-character-is-newline?:boolean
      # wrap
      print-character screen:address, 8617:literal/loop-back-to-left, 245:literal/grey
      column:number <- copy left:number
      row:number <- add row:number, 1:literal
      move-cursor screen:address, row:number, column:number
      # don't increment i
      loop +next-character:label
    }
    print-character screen:address, c:character
    i:number <- add i:number, 1:literal
    column:number <- add column:number, 1:literal
    loop
  }
]

scenario edit-prints-multiple-lines [
  assume-screen 5:literal/width, 3:literal/height
  assume-keyboard []
  run [
    s:address:array:character <- new [abc
def]
    s2:address:array:character, screen:address, keyboard:address <- edit s:address:array:character, screen:address, 0:literal/top, 0:literal/left, 10:literal/bottom, 5:literal/right, keyboard:address
  ]
  screen-should-contain [
    .abc  .
    .def  .
    .     .
  ]
]

scenario edit-handles-offsets [
  assume-screen 5:literal/width, 3:literal/height
  assume-keyboard []
  run [
    s:address:array:character <- new [abc]
    s2:address:array:character, screen:address, keyboard:address <- edit s:address:array:character, screen:address, 0:literal/top, 1:literal/left, 10:literal/bottom, 5:literal/right, keyboard:address
  ]
  screen-should-contain [
    . abc .
    .     .
    .     .
  ]
]

scenario edit-prints-multiple-lines-at-offset [
  assume-screen 5:literal/width, 3:literal/height
  assume-keyboard []
  run [
    s:address:array:character <- new [abc
def]
    s2:address:array:character, screen:address, keyboard:address <- edit s:address:array:character, screen:address, 0:literal/top, 1:literal/left, 10:literal/bottom, 5:literal/right, keyboard:address
  ]
  screen-should-contain [
    . abc .
    . def .
    .     .
  ]
]

scenario edit-wraps-long-lines [
  assume-screen 5:literal/width, 3:literal/height
  assume-keyboard []
  run [
    s:address:array:character <- new [abc def]
    s2:address:array:character, screen:address, keyboard:address <- edit s:address:array:character, screen:address, 0:literal/top, 0:literal/left, 10:literal/bottom, 5:literal/right, keyboard:address
  ]
  screen-should-contain [
    .abc ↩.
    .def  .
    .     .
  ]
  screen-should-contain-in-color, 245:literal/grey [
    .    ↩.
    .     .
    .     .
  ]
]

recipe draw-box [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  top:number <- next-ingredient
  left:number <- next-ingredient
  bottom:number <- next-ingredient
  right:number <- next-ingredient
  # top border
  draw-horizontal screen:address, top:number, left:number, right:number
  draw-horizontal screen:address, bottom:number, left:number, right:number
  draw-vertical screen:address, left:number, top:number, bottom:number
  draw-vertical screen:address, right:number, top:number, bottom:number
  draw-top-left screen:address, top:number, left:number
  draw-top-right screen:address, top:number, right:number
  draw-bottom-left screen:address, bottom:number, left:number
  draw-bottom-right screen:address, bottom:number, right:number
  # position cursor inside box
  move-cursor screen:address, top:number, left:number
  cursor-down screen:address
  cursor-right screen:address
]

recipe draw-horizontal [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  row:number <- next-ingredient
  x:number <- next-ingredient
  right:number <- next-ingredient
  move-cursor screen:address, row:number, x:number
  {
    continue?:boolean <- lesser-than x:number, right:number
    break-unless continue?:boolean
    print-character screen:address, 9472:literal/horizontal, 245:literal/grey
    x:number <- add x:number, 1:literal
    loop
  }
]

recipe draw-vertical [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  col:number <- next-ingredient
  x:number <- next-ingredient
  bottom:number <- next-ingredient
  {
    continue?:boolean <- lesser-than x:number, bottom:number
    break-unless continue?:boolean
    move-cursor screen:address, x:number, col:number
    print-character screen:address, 9474:literal/vertical, 245:literal/grey
    x:number <- add x:number, 1:literal
    loop
  }
]

recipe draw-top-left [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  top:number <- next-ingredient
  left:number <- next-ingredient
  move-cursor screen:address, top:number, left:number
  print-character screen:address, 9484:literal/down-right, 245:literal/grey
]

recipe draw-top-right [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  top:number <- next-ingredient
  right:number <- next-ingredient
  move-cursor screen:address, top:number, right:number
  print-character screen:address, 9488:literal/down-left, 245:literal/grey
]

recipe draw-bottom-left [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  bottom:number <- next-ingredient
  left:number <- next-ingredient
  move-cursor screen:address, bottom:number, left:number
  print-character screen:address, 9492:literal/up-right, 245:literal/grey
]

recipe draw-bottom-right [
  default-space:address:array:location <- new location:type, 30:literal
  screen:address <- next-ingredient
  bottom:number <- next-ingredient
  right:number <- next-ingredient
  move-cursor screen:address, bottom:number, right:number
  print-character screen:address, 9496:literal/up-left, 245:literal/grey
]
