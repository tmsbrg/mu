## editing sandboxes after they've been created

scenario clicking-on-a-sandbox-moves-it-to-editor [
  trace-until 100/app  # trace too long
  assume-screen 40/width, 10/height
  # run something
  1:address:shared:array:character <- new [add 2, 2]
  assume-console [
    press F4
  ]
  2:address:shared:programming-environment-data <- new-programming-environment screen:address:shared:screen, 1:address:shared:array:character
  event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  screen-should-contain [
    .                     run (F4)           .
    .                                        .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .0                                      x.
    .add 2, 2                                .
    .4                                       .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                        .
    .                                        .
    .                                        .
  ]
  # click somewhere on the sandbox
  assume-console [
    left-click 3, 0
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  # it pops back into editor
  screen-should-contain [
    .                     run (F4)           .
    .add 2, 2                                .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
  ]
  # cursor should be in the right place
  assume-console [
    type [0]
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  screen-should-contain [
    .                     run (F4)           .
    .0add 2, 2                               .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
    .                                        .
  ]
]

after <global-touch> [
  # below editor? pop appropriate sandbox contents back into sandbox editor provided it's empty
  {
    sandbox-left-margin:number <- get *current-sandbox, left:offset
    click-column:number <- get *t, column:offset
    on-sandbox-side?:boolean <- greater-or-equal click-column, sandbox-left-margin
    break-unless on-sandbox-side?
    first-sandbox:address:shared:sandbox-data <- get *env, sandbox:offset
    break-unless first-sandbox
    first-sandbox-begins:number <- get *first-sandbox, starting-row-on-screen:offset
    click-row:number <- get *t, row:offset
    below-sandbox-editor?:boolean <- greater-or-equal click-row, first-sandbox-begins
    break-unless below-sandbox-editor?
    empty-sandbox-editor?:boolean <- empty-editor? current-sandbox
    break-unless empty-sandbox-editor?  # don't clobber existing contents
    # identify the sandbox to edit and remove it from the sandbox list
    sandbox:address:shared:sandbox-data <- extract-sandbox env, click-row
    break-unless sandbox
    text:address:shared:array:character <- get *sandbox, data:offset
    current-sandbox <- insert-text current-sandbox, text
    render-from:address:number <- get-address *env, render-from:offset
    *render-from <- copy -1
    hide-screen screen
    screen <- render-sandbox-side screen, env
    screen <- update-cursor screen, current-sandbox, env
    show-screen screen
    loop +next-event:label
  }
]

recipe empty-editor? editor:address:shared:editor-data -> result:boolean [
  local-scope
  load-ingredients
  head:address:shared:duplex-list:character <- get *editor, data:offset
  first:address:shared:duplex-list:character <- next head
  result <- not first
]

recipe extract-sandbox env:address:shared:programming-environment-data, click-row:number -> result:address:shared:sandbox-data, env:address:shared:programming-environment-data [
  local-scope
  load-ingredients
  sandbox:address:address:shared:sandbox-data <- get-address *env, sandbox:offset
  start:number <- get **sandbox, starting-row-on-screen:offset
  in-editor?:boolean <- lesser-than click-row, start
  reply-if in-editor?, 0
  {
    next-sandbox:address:shared:sandbox-data <- get **sandbox, next-sandbox:offset
    break-unless next-sandbox
    # if click-row < sandbox.next-sandbox.starting-row-on-screen, break
    next-start:number <- get *next-sandbox, starting-row-on-screen:offset
    found?:boolean <- lesser-than click-row, next-start
    break-if found?
    sandbox <- get-address **sandbox, next-sandbox:offset
    loop
  }
  # snip sandbox out of its list
  result <- copy *sandbox
  *sandbox <- copy next-sandbox
  # update sandbox count
  sandbox-count:address:number <- get-address *env, number-of-sandboxes:offset
  *sandbox-count <- subtract *sandbox-count, 1
]

scenario sandbox-with-print-can-be-edited [
  trace-until 100/app  # trace too long
  assume-screen 50/width, 20/height
  # run a print instruction
  1:address:shared:array:character <- new [print-integer screen, 4]
  2:address:shared:programming-environment-data <- new-programming-environment screen:address:shared:screen, 1:address:shared:array:character
  # run the sandbox
  assume-console [
    press F4
  ]
  event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  screen-should-contain [
    .                               run (F4)           .
    .                                                  .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .0                                                x.
    .print-integer screen, 4                           .
    .screen:                                           .
    .  .4                             .                .
    .  .                              .                .
    .  .                              .                .
    .  .                              .                .
    .  .                              .                .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                                  .
  ]
  # edit the sandbox
  assume-console [
    left-click 3, 70
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  screen-should-contain [
    .                               run (F4)           .
    .print-integer screen, 4                           .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                                  .
    .                                                  .
  ]
]

scenario editing-sandbox-after-scrolling-resets-scroll [
  trace-until 100/app  # trace too long
  assume-screen 50/width, 20/height
  # initialize environment
  1:address:shared:array:character <- new []
  2:address:shared:programming-environment-data <- new-programming-environment screen:address:shared:screen, 1:address:shared:array:character
  render-all screen, 2:address:shared:programming-environment-data
  # create 2 sandboxes and scroll to second
  assume-console [
    press ctrl-n
    type [add 2, 2]
    press F4
    type [add 1, 1]
    press F4
    press down-arrow
    press down-arrow
  ]
  event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  screen-should-contain [
    .                               run (F4)           .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .1                                                x.
    .add 2, 2                                          .
    .4                                                 .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                                  .
  ]
  # edit the second sandbox
  assume-console [
    left-click 2, 20
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  # second sandbox shows in editor; scroll resets to display first sandbox
  screen-should-contain [
    .                               run (F4)           .
    .add 2, 2                                          .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .0                                                x.
    .add 1, 1                                          .
    .2                                                 .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                                  .
  ]
]

scenario editing-sandbox-updates-sandbox-count [
  trace-until 100/app  # trace too long
  assume-screen 50/width, 20/height
  # initialize environment
  1:address:shared:array:character <- new []
  2:address:shared:programming-environment-data <- new-programming-environment screen:address:shared:screen, 1:address:shared:array:character
  render-all screen, 2:address:shared:programming-environment-data
  # create 2 sandboxes and scroll to second
  assume-console [
    press ctrl-n
    type [add 2, 2]
    press F4
    type [add 1, 1]
    press F4
  ]
  event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  screen-should-contain [
    .                               run (F4)           .
    .                                                  .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .0                                                x.
    .add 1, 1                                          .
    .2                                                 .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .1                                                x.
  ]
  # edit the second sandbox, then resave
  assume-console [
    left-click 3, 20
    press F4
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  # no change in contents
  screen-should-contain [
    .                               run (F4)           .
    .                                                  .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .0                                                x.
    .add 1, 1                                          .
    .2                                                 .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .1                                                x.
  ]
  # now try to scroll past end
  assume-console [
    press down-arrow
    press down-arrow
    press down-arrow
  ]
  run [
    event-loop screen:address:shared:screen, console:address:shared:console, 2:address:shared:programming-environment-data
  ]
  # screen should show just final sandbox
  screen-should-contain [
    .                               run (F4)           .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .1                                                x.
    .add 2, 2                                          .
    .4                                                 .
    .━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━.
    .                                                  .
  ]
]
