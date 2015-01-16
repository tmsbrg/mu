; open a viewport, print coordinates of mouse clicks
; currently need to ctrl-c to exit after closing the viewport
(function main [
  (window-on (("practice" literal)) 300:literal 300:literal)
  { begin
    (pos:integer-integer-pair click?:boolean <- mouse-position)
    (loop-unless click?:boolean)
    (x:integer <- get pos:integer-integer-pair 0:offset)
    (y:integer <- get pos:integer-integer-pair 1:offset)
    (print-primitive nil:literal/terminal x:integer)
    (print-primitive nil:literal/terminal ((", " literal)))
    (print-primitive nil:literal/terminal y:integer)
    (print-primitive nil:literal/terminal (("\n" literal)))
    (loop)
  }
  (window-off)
])