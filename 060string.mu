# Some useful helpers for dealing with strings.

recipe string-equal [
  local-scope
  a:address:array:character <- next-ingredient
  a-len:number <- length a:address:array:character/lookup
  b:address:array:character <- next-ingredient
  b-len:number <- length b:address:array:character/lookup
  # compare lengths
  {
    trace [string-equal], [comparing lengths]
    length-equal?:boolean <- equal a-len:number, b-len:number
    break-if length-equal?:boolean
    reply 0
  }
  # compare each corresponding character
  trace [string-equal], [comparing characters]
  i:number <- copy 0
  {
    done?:boolean <- greater-or-equal i:number, a-len:number
    break-if done?:boolean
    a2:character <- index a:address:array:character/lookup, i:number
    b2:character <- index b:address:array:character/lookup, i:number
    {
      chars-match?:boolean <- equal a2:character, b2:character
      break-if chars-match?:boolean
      reply 0
    }
    i:number <- add i:number, 1
    loop
  }
  reply 1
]

scenario string-equal-reflexive [
  run [
    default-space:address:array:location <- new location:type, 30
    x:address:array:character <- new [abc]
    3:boolean/raw <- string-equal x:address:array:character, x:address:array:character
  ]
  memory-should-contain [
    3 <- 1  # x == x for all x
  ]
]

scenario string-equal-identical [
  run [
    default-space:address:array:location <- new location:type, 30
    x:address:array:character <- new [abc]
    y:address:array:character <- new [abc]
    3:boolean/raw <- string-equal x:address:array:character, y:address:array:character
  ]
  memory-should-contain [
    3 <- 1  # abc == abc
  ]
]

scenario string-equal-distinct-lengths [
  run [
    default-space:address:array:location <- new location:type, 30
    x:address:array:character <- new [abc]
    y:address:array:character <- new [abcd]
    3:boolean/raw <- string-equal x:address:array:character, y:address:array:character
  ]
  memory-should-contain [
    3 <- 0  # abc != abcd
  ]
  trace-should-contain [
    string-equal: comparing lengths
  ]
  trace-should-not-contain [
    string-equal: comparing characters
  ]
]

scenario string-equal-with-empty [
  run [
    default-space:address:array:location <- new location:type, 30
    x:address:array:character <- new []
    y:address:array:character <- new [abcd]
    3:boolean/raw <- string-equal x:address:array:character, y:address:array:character
  ]
  memory-should-contain [
    3 <- 0  # "" != abcd
  ]
]

scenario string-equal-common-lengths-but-distinct [
  run [
    default-space:address:array:location <- new location:type, 30
    x:address:array:character <- new [abc]
    y:address:array:character <- new [abd]
    3:boolean/raw <- string-equal x:address:array:character, y:address:array:character
  ]
  memory-should-contain [
    3 <- 0  # abc != abd
  ]
]

# A new type to help incrementally construct strings.
container buffer [
  length:number
  data:address:array:character
]

recipe new-buffer [
  local-scope
#?   $print default-space:address:array:location, 10/newline
  result:address:buffer <- new buffer:type
  len:address:number <- get-address result:address:buffer/lookup, length:offset
  len:address:number/lookup <- copy 0
  s:address:address:array:character <- get-address result:address:buffer/lookup, data:offset
  capacity:number, found?:boolean <- next-ingredient
  assert found?:boolean, [new-buffer must get a capacity argument]
  s:address:address:array:character/lookup <- new character:type, capacity:number
#?   $print s:address:address:array:character/lookup, 10/newline
  reply result:address:buffer
]

recipe grow-buffer [
  local-scope
  in:address:buffer <- next-ingredient
  # double buffer size
  x:address:address:array:character <- get-address in:address:buffer/lookup, data:offset
  oldlen:number <- length x:address:address:array:character/lookup/lookup
  newlen:number <- multiply oldlen:number, 2
  olddata:address:array:character <- copy x:address:address:array:character/lookup
  x:address:address:array:character/lookup <- new character:type, newlen:number
  # copy old contents
  i:number <- copy 0
  {
    done?:boolean <- greater-or-equal i:number, oldlen:number
    break-if done?:boolean
    src:character <- index olddata:address:array:character/lookup, i:number
    dest:address:character <- index-address x:address:address:array:character/lookup/lookup, i:number
    dest:address:character/lookup <- copy src:character
    i:number <- add i:number, 1
    loop
  }
  reply in:address:buffer
]

recipe buffer-full? [
  local-scope
  in:address:buffer <- next-ingredient
  len:number <- get in:address:buffer/lookup, length:offset
  s:address:array:character <- get in:address:buffer/lookup, data:offset
  capacity:number <- length s:address:array:character/lookup
  result:boolean <- greater-or-equal len:number, capacity:number
  reply result:boolean
]

# in:address:buffer <- buffer-append in:address:buffer, c:character
recipe buffer-append [
  local-scope
  in:address:buffer <- next-ingredient
  c:character <- next-ingredient
  len:address:number <- get-address in:address:buffer/lookup, length:offset
  {
    # backspace? just drop last character if it exists and return
    backspace?:boolean <- equal c:character, 8/backspace
    break-unless backspace?:boolean
    empty?:boolean <- lesser-or-equal len:address:number/lookup, 0
    reply-if empty?:boolean, in:address:buffer/same-as-ingredient:0
    len:address:number/lookup <- subtract len:address:number/lookup, 1
    reply in:address:buffer/same-as-ingredient:0
  }
  {
    # grow buffer if necessary
    full?:boolean <- buffer-full? in:address:buffer
    break-unless full?:boolean
    in:address:buffer <- grow-buffer in:address:buffer
  }
  s:address:array:character <- get in:address:buffer/lookup, data:offset
#?   $print [array underlying buf: ], s:address:array:character, 10/newline
#?   $print [index: ], len:address:number/lookup, 10/newline
  dest:address:character <- index-address s:address:array:character/lookup, len:address:number/lookup
#?   $print [storing ], c:character, [ in ], dest:address:character, 10/newline
  dest:address:character/lookup <- copy c:character
  len:address:number/lookup <- add len:address:number/lookup, 1
  reply in:address:buffer/same-as-ingredient:0
]

scenario buffer-append-works [
  run [
    local-scope
    x:address:buffer <- new-buffer 3
    s1:address:array:character <- get x:address:buffer/lookup, data:offset
    x:address:buffer <- buffer-append x:address:buffer, 97  # 'a'
    x:address:buffer <- buffer-append x:address:buffer, 98  # 'b'
    x:address:buffer <- buffer-append x:address:buffer, 99  # 'c'
    s2:address:array:character <- get x:address:buffer/lookup, data:offset
    1:boolean/raw <- equal s1:address:array:character, s2:address:array:character
    2:array:character/raw <- copy s2:address:array:character/lookup
    +buffer-filled
    x:address:buffer <- buffer-append x:address:buffer, 100  # 'd'
    s3:address:array:character <- get x:address:buffer/lookup, data:offset
    10:boolean/raw <- equal s1:address:array:character, s3:address:array:character
    11:number/raw <- get x:address:buffer/lookup, length:offset
    12:array:character/raw <- copy s3:address:array:character/lookup
  ]
  memory-should-contain [
    # before +buffer-filled
    1 <- 1   # no change in data pointer
    2 <- 3   # size of data
    3 <- 97  # data
    4 <- 98
    5 <- 99
    # in the end
    10 <- 0   # data pointer has grown
    11 <- 4   # final length
    12 <- 6   # but data's capacity has doubled
    13 <- 97  # data
    14 <- 98
    15 <- 99
    16 <- 100
    17 <- 0
    18 <- 0
  ]
]

scenario buffer-append-handles-backspace [
  run [
    local-scope
    x:address:buffer <- new-buffer 3
    x:address:buffer <- buffer-append x:address:buffer, 97  # 'a'
    x:address:buffer <- buffer-append x:address:buffer, 98  # 'b'
    x:address:buffer <- buffer-append x:address:buffer, 8/backspace
    s:address:array:character <- buffer-to-array x:address:buffer
    1:array:character/raw <- copy s:address:array:character/lookup
  ]
  memory-should-contain [
    1 <- 1   # length
    2 <- 97  # contents
    3 <- 0
  ]
]

# result:address:array:character <- integer-to-decimal-string n:number
recipe integer-to-decimal-string [
  local-scope
  n:number <- next-ingredient
  # is it zero?
  {
    break-if n:number
    result:address:array:character <- new [0]
    reply result:address:array:character
  }
  # save sign
  negate-result:boolean <- copy 0
  {
    negative?:boolean <- lesser-than n:number, 0
    break-unless negative?:boolean
    negate-result:boolean <- copy 1
    n:number <- multiply n:number, -1
  }
  # add digits from right to left into intermediate buffer
  tmp:address:buffer <- new-buffer 30
  digit-base:number <- copy 48  # '0'
  {
    done?:boolean <- equal n:number, 0
    break-if done?:boolean
    n:number, digit:number <- divide-with-remainder n:number, 10
    c:character <- add digit-base:number, digit:number
    tmp:address:buffer <- buffer-append tmp:address:buffer, c:character
    loop
  }
  # add sign
  {
    break-unless negate-result:boolean
    tmp:address:buffer <- buffer-append tmp:address:buffer, 45  # '-'
  }
  # reverse buffer into string result
  len:number <- get tmp:address:buffer/lookup, length:offset
  buf:address:array:character <- get tmp:address:buffer/lookup, data:offset
  result:address:array:character <- new character:type, len:number
  i:number <- subtract len:number, 1
  j:number <- copy 0
  {
    # while i >= 0
    done?:boolean <- lesser-than i:number, 0
    break-if done?:boolean
    # result[j] = tmp[i]
    src:character <- index buf:address:array:character/lookup, i:number
    dest:address:character <- index-address result:address:array:character/lookup, j:number
    dest:address:character/lookup <- copy src:character
    # ++i
    i:number <- subtract i:number, 1
    # --j
    j:number <- add j:number, 1
    loop
  }
  reply result:address:array:character
]

recipe buffer-to-array [
  local-scope
  in:address:buffer <- next-ingredient
  {
    # propagate null buffer
    break-if in:address:buffer
    reply 0
  }
  len:number <- get in:address:buffer/lookup, length:offset
#?   $print [size ], len:number, 10/newline
  s:address:array:character <- get in:address:buffer/lookup, data:offset
  # we can't just return s because it is usually the wrong length
  result:address:array:character <- new character:type, len:number
  i:number <- copy 0
  {
#?     $print i:number #? 1
    done?:boolean <- greater-or-equal i:number, len:number
    break-if done?:boolean
    src:character <- index s:address:array:character/lookup, i:number
    dest:address:character <- index-address result:address:array:character/lookup, i:number
    dest:address:character/lookup <- copy src:character
    i:number <- add i:number, 1
    loop
  }
  reply result:address:array:character
]

scenario integer-to-decimal-digit-zero [
  run [
    1:address:array:character/raw <- integer-to-decimal-string 0
    2:array:character/raw <- copy 1:address:array:character/lookup/raw
  ]
  memory-should-contain [
    2:string <- [0]
  ]
]

scenario integer-to-decimal-digit-positive [
  run [
    1:address:array:character/raw <- integer-to-decimal-string 234
    2:array:character/raw <- copy 1:address:array:character/lookup/raw
  ]
  memory-should-contain [
    2:string <- [234]
  ]
]

scenario integer-to-decimal-digit-negative [
  run [
    1:address:array:character/raw <- integer-to-decimal-string -1
    2:array:character/raw <- copy 1:address:array:character/lookup/raw
  ]
  memory-should-contain [
    2 <- 2
    3 <- 45  # '-'
    4 <- 49  # '1'
  ]
]

# result:address:array:character <- string-append a:address:array:character, b:address:array:character
recipe string-append [
  local-scope
  # result = new character[a.length + b.length]
  a:address:array:character <- next-ingredient
  a-len:number <- length a:address:array:character/lookup
  b:address:array:character <- next-ingredient
  b-len:number <- length b:address:array:character/lookup
  result-len:number <- add a-len:number, b-len:number
  result:address:array:character <- new character:type, result-len:number
  # copy a into result
  result-idx:number <- copy 0
  i:number <- copy 0
  {
    # while i < a.length
    a-done?:boolean <- greater-or-equal i:number, a-len:number
    break-if a-done?:boolean
    # result[result-idx] = a[i]
    out:address:character <- index-address result:address:array:character/lookup, result-idx:number
    in:character <- index a:address:array:character/lookup, i:number
    out:address:character/lookup <- copy in:character
    # ++i
    i:number <- add i:number, 1
    # ++result-idx
    result-idx:number <- add result-idx:number, 1
    loop
  }
  # copy b into result
  i:number <- copy 0
  {
    # while i < b.length
    b-done?:boolean <- greater-or-equal i:number, b-len:number
    break-if b-done?:boolean
    # result[result-idx] = a[i]
    out:address:character <- index-address result:address:array:character/lookup, result-idx:number
    in:character <- index b:address:array:character/lookup, i:number
    out:address:character/lookup <- copy in:character
    # ++i
    i:number <- add i:number, 1
    # ++result-idx
    result-idx:number <- add result-idx:number, 1
    loop
  }
  reply result:address:array:character
]

scenario string-append-1 [
  run [
    1:address:array:character/raw <- new [hello,]
    2:address:array:character/raw <- new [ world!]
    3:address:array:character/raw <- string-append 1:address:array:character/raw, 2:address:array:character/raw
    4:array:character/raw <- copy 3:address:array:character/raw/lookup
  ]
  memory-should-contain [
    4:string <- [hello, world!]
  ]
]

# replace underscores in first with remaining args
# result:address:array:character <- interpolate template:address:array:character, ...
recipe interpolate [
  local-scope
  template:address:array:character <- next-ingredient
  # compute result-len, space to allocate for result
  tem-len:number <- length template:address:array:character/lookup
  result-len:number <- copy tem-len:number
  {
    # while arg received
    a:address:array:character, arg-received?:boolean <- next-ingredient
    break-unless arg-received?:boolean
    # result-len = result-len + arg.length - 1 for the 'underscore' being replaced
    a-len:number <- length a:address:array:character/lookup
    result-len:number <- add result-len:number, a-len:number
    result-len:number <- subtract result-len:number, 1
    loop
  }
#?   $print tem-len:number, [ ], $result-len:number, 10/newline
  rewind-ingredients
  _ <- next-ingredient  # skip template
  # result = new array:character[result-len]
  result:address:array:character <- new character:type, result-len:number
  # repeatedly copy sections of template and 'holes' into result
  result-idx:number <- copy 0
  i:number <- copy 0
  {
    # while arg received
    a:address:array:character, arg-received?:boolean <- next-ingredient
    break-unless arg-received?:boolean
    # copy template into result until '_'
    {
      # while i < template.length
      tem-done?:boolean <- greater-or-equal i:number, tem-len:number
      break-if tem-done?:boolean, +done:label
      # while template[i] != '_'
      in:character <- index template:address:array:character/lookup, i:number
      underscore?:boolean <- equal in:character, 95  # '_'
      break-if underscore?:boolean
      # result[result-idx] = template[i]
      out:address:character <- index-address result:address:array:character/lookup, result-idx:number
      out:address:character/lookup <- copy in:character
      # ++i
      i:number <- add i:number, 1
      # ++result-idx
      result-idx:number <- add result-idx:number, 1
      loop
    }
    # copy 'a' into result
    j:number <- copy 0
    {
      # while j < a.length
      arg-done?:boolean <- greater-or-equal j:number, a-len:number
      break-if arg-done?:boolean
      # result[result-idx] = a[j]
      in:character <- index a:address:array:character/lookup, j:number
      out:address:character <- index-address result:address:array:character/lookup, result-idx:number
      out:address:character/lookup <- copy in:character
      # ++j
      j:number <- add j:number, 1
      # ++result-idx
      result-idx:number <- add result-idx:number, 1
      loop
    }
    # skip '_' in template
    i:number <- add i:number, 1
    loop  # interpolate next arg
  }
  +done
  # done with holes; copy rest of template directly into result
  {
    # while i < template.length
    tem-done?:boolean <- greater-or-equal i:number, tem-len:number
    break-if tem-done?:boolean
    # result[result-idx] = template[i]
    in:character <- index template:address:array:character/lookup, i:number
    out:address:character <- index-address result:address:array:character/lookup, result-idx:number
    out:address:character/lookup <- copy in:character
    # ++i
    i:number <- add i:number, 1
    # ++result-idx
    result-idx:number <- add result-idx:number, 1
    loop
  }
  reply result:address:array:character
]

scenario interpolate-works [
#?   dump run #? 1
  run [
    1:address:array:character/raw <- new [abc _]
    2:address:array:character/raw <- new [def]
    3:address:array:character/raw <- interpolate 1:address:array:character/raw, 2:address:array:character/raw
    4:array:character/raw <- copy 3:address:array:character/raw/lookup
  ]
  memory-should-contain [
    4:string <- [abc def]
  ]
]

scenario interpolate-at-start [
  run [
    1:address:array:character/raw <- new [_, hello!]
    2:address:array:character/raw <- new [abc]
    3:address:array:character/raw <- interpolate 1:address:array:character/raw, 2:address:array:character/raw
    4:array:character/raw <- copy 3:address:array:character/raw/lookup
  ]
  memory-should-contain [
    4:string <- [abc, hello!]
    16 <- 0  # out of bounds
  ]
]

scenario interpolate-at-end [
  run [
    1:address:array:character/raw <- new [hello, _]
    2:address:array:character/raw <- new [abc]
    3:address:array:character/raw <- interpolate 1:address:array:character/raw, 2:address:array:character/raw
    4:array:character/raw <- copy 3:address:array:character/raw/lookup
  ]
  memory-should-contain [
    4:string <- [hello, abc]
  ]
]

# result:boolean <- space? c:character
recipe space? [
  local-scope
  c:character <- next-ingredient
  # most common case first
  result:boolean <- equal c:character, 32/space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 10/newline
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 9/tab
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 13/carriage-return
  # remaining uncommon cases in sorted order
  # http://unicode.org code-points in unicode-set Z and Pattern_White_Space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 11/ctrl-k
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 12/ctrl-l
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 133/ctrl-0085
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 160/no-break-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 5760/ogham-space-mark
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8192/en-quad
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8193/em-quad
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8194/en-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8195/em-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8196/three-per-em-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8197/four-per-em-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8198/six-per-em-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8199/figure-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8200/punctuation-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8201/thin-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8202/hair-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8206/left-to-right
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8207/right-to-left
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8232/line-separator
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8233/paragraph-separator
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8239/narrow-no-break-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 8287/medium-mathematical-space
  jump-if result:boolean, +reply:label
  result:boolean <- equal c:character, 12288/ideographic-space
  jump-if result:boolean, +reply:label
  +reply
  reply result:boolean
]

# result:address:array:character <- trim s:address:array:character
recipe trim [
  local-scope
  s:address:array:character <- next-ingredient
  len:number <- length s:address:array:character/lookup
  # left trim: compute start
  start:number <- copy 0
  {
    {
      at-end?:boolean <- greater-or-equal start:number, len:number
      break-unless at-end?:boolean
      result:address:array:character <- new character:type, 0
      reply result:address:array:character
    }
    curr:character <- index s:address:array:character/lookup, start:number
    whitespace?:boolean <- space? curr:character
    break-unless whitespace?:boolean
    start:number <- add start:number, 1
    loop
  }
  # right trim: compute end
  end:number <- subtract len:number, 1
  {
    not-at-start?:boolean <- greater-than end:number, start:number
    assert not-at-start?:boolean [end ran up against start]
    curr:character <- index s:address:array:character/lookup, end:number
    whitespace?:boolean <- space? curr:character
    break-unless whitespace?:boolean
    end:number <- subtract end:number, 1
    loop
  }
  # result = new character[end+1 - start]
  new-len:number <- subtract end:number, start:number, -1
  result:address:array:character <- new character:type, new-len:number
  # i = start, j = 0
  i:number <- copy start:number
  j:number <- copy 0
  {
    # while i <= end
    done?:boolean <- greater-than i:number, end:number
    break-if done?:boolean
    # result[j] = s[i]
    src:character <- index s:address:array:character/lookup, i:number
    dest:address:character <- index-address result:address:array:character/lookup, j:number
    dest:address:character/lookup <- copy src:character
    # ++i, ++j
    i:number <- add i:number, 1
    j:number <- add j:number, 1
    loop
  }
  reply result:address:array:character
]

scenario trim-unmodified [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- trim 1:address:array:character
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [abc]
  ]
]

scenario trim-left [
  run [
    1:address:array:character <- new [  abc]
    2:address:array:character <- trim 1:address:array:character
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [abc]
  ]
]

scenario trim-right [
  run [
    1:address:array:character <- new [abc  ]
    2:address:array:character <- trim 1:address:array:character
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [abc]
  ]
]

scenario trim-left-right [
  run [
    1:address:array:character <- new [  abc   ]
    2:address:array:character <- trim 1:address:array:character
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [abc]
  ]
]

scenario trim-newline-tab [
  run [
    1:address:array:character <- new [	abc
]
    2:address:array:character <- trim 1:address:array:character
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [abc]
  ]
]

# next-index:number <- find-next text:address:array:character, pattern:character
recipe find-next [
  local-scope
  text:address:array:character <- next-ingredient
  pattern:character <- next-ingredient
  idx:number <- next-ingredient
  len:number <- length text:address:array:character/lookup
  {
    eof?:boolean <- greater-or-equal idx:number, len:number
    break-if eof?:boolean
    curr:character <- index text:address:array:character/lookup, idx:number
    found?:boolean <- equal curr:character, pattern:character
    break-if found?:boolean
    idx:number <- add idx:number, 1
    loop
  }
  reply idx:number
]

scenario string-find-next [
  run [
    1:address:array:character <- new [a/b]
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 1
  ]
]

scenario string-find-next-empty [
  run [
    1:address:array:character <- new []
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 0
  ]
]

scenario string-find-next-initial [
  run [
    1:address:array:character <- new [/abc]
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 0  # prefix match
  ]
]

scenario string-find-next-final [
  run [
    1:address:array:character <- new [abc/]
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 3  # suffix match
  ]
]

scenario string-find-next-missing [
  run [
    1:address:array:character <- new [abc]
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 3  # no match
  ]
]

scenario string-find-next-invalid-index [
  run [
    1:address:array:character <- new [abc]
    2:number <- find-next 1:address:array:character, 47/slash, 4/start-index
  ]
  memory-should-contain [
    2 <- 4  # no change
  ]
]

scenario string-find-next-first [
  run [
    1:address:array:character <- new [ab/c/]
    2:number <- find-next 1:address:array:character, 47/slash, 0/start-index
  ]
  memory-should-contain [
    2 <- 2  # first '/' of multiple
  ]
]

scenario string-find-next-second [
  run [
    1:address:array:character <- new [ab/c/]
    2:number <- find-next 1:address:array:character, 47/slash, 3/start-index
  ]
  memory-should-contain [
    2 <- 4  # second '/' of multiple
  ]
]

# like find-next, but searches for multiple characters
# fairly dumb algorithm
recipe find-substring [
  local-scope
  text:address:array:character <- next-ingredient
  pattern:address:array:character <- next-ingredient
  idx:number <- next-ingredient
  first:character <- index pattern:address:array:character/lookup, 0
  # repeatedly check for match at current idx
  len:number <- length text:address:array:character/lookup
  {
    # does some unnecessary work checking for substrings even when there isn't enough of text left
    done?:boolean <- greater-or-equal idx:number, len:number
    break-if done?:boolean
    found?:boolean <- match-at text:address:array:character pattern:address:array:character, idx:number
    break-if found?:boolean
    idx:number <- add idx:number, 1
    # optimization: skip past indices that definitely won't match
    idx:number <- find-next text:address:array:character, first:character, idx:number
    loop
  }
  reply idx:number
]

scenario find-substring-1 [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [bc]
    3:number <- find-substring 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 1
  ]
]

scenario find-substring-2 [
  run [
    1:address:array:character <- new [abcd]
    2:address:array:character <- new [bc]
    3:number <- find-substring 1:address:array:character, 2:address:array:character, 1
  ]
  memory-should-contain [
    3 <- 1
  ]
]

scenario find-substring-no-match [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [bd]
    3:number <- find-substring 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 3  # not found
  ]
]

scenario find-substring-suffix-match [
  run [
    1:address:array:character <- new [abcd]
    2:address:array:character <- new [cd]
    3:number <- find-substring 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 2
  ]
]

scenario find-substring-suffix-match-2 [
  run [
    1:address:array:character <- new [abcd]
    2:address:array:character <- new [cde]
    3:number <- find-substring 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 4  # not found
  ]
]

# result:boolean <- match-at text:address:array:character, pattern:address:array:character, idx:number
# checks if substring matches at index 'idx'
recipe match-at [
  local-scope
  text:address:array:character <- next-ingredient
  pattern:address:array:character <- next-ingredient
  idx:number <- next-ingredient
  pattern-len:number <- length pattern:address:array:character/lookup
  # check that there's space left for the pattern
  {
    x:number <- length text:address:array:character/lookup
    x:number <- subtract x:number, pattern-len:number
    enough-room?:boolean <- lesser-or-equal idx:number, x:number
    break-if enough-room?:boolean
    reply 0/not-found
  }
  # check each character of pattern
  pattern-idx:number <- copy 0
  {
    done?:boolean <- greater-or-equal pattern-idx:number, pattern-len:number
    break-if done?:boolean
    c:character <- index text:address:array:character/lookup, idx:number
    exp:character <- index pattern:address:array:character/lookup, pattern-idx:number
    {
      match?:boolean <- equal c:character, exp:character
      break-if match?:boolean
      reply 0/not-found
    }
    idx:number <- add idx:number, 1
    pattern-idx:number <- add pattern-idx:number, 1
    loop
  }
  reply 1/found
]

scenario match-at-checks-substring-at-index [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [ab]
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 1  # match found
  ]
]

scenario match-at-reflexive [
  run [
    1:address:array:character <- new [abc]
    3:boolean <- match-at 1:address:array:character, 1:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 1  # match found
  ]
]

scenario match-at-outside-bounds [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [a]
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 4
  ]
  memory-should-contain [
    3 <- 0  # never matches
  ]
]

scenario match-at-empty-pattern [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new []
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 1  # always matches empty pattern given a valid index
  ]
]

scenario match-at-empty-pattern-outside-bound [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new []
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 4
  ]
  memory-should-contain [
    3 <- 0  # no match
  ]
]

scenario match-at-empty-text [
  run [
    1:address:array:character <- new []
    2:address:array:character <- new [abc]
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 0  # no match
  ]
]

scenario match-at-empty-against-empty [
  run [
    1:address:array:character <- new []
    3:boolean <- match-at 1:address:array:character, 1:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 1  # matches because pattern is also empty
  ]
]

scenario match-at-inside-bounds [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [bc]
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 1
  ]
  memory-should-contain [
    3 <- 1  # matches inner substring
  ]
]

scenario match-at-inside-bounds-2 [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- new [bc]
    3:boolean <- match-at 1:address:array:character, 2:address:array:character, 0
  ]
  memory-should-contain [
    3 <- 0  # no match
  ]
]

# result:address:array:address:array:character <- split s:address:array:character, delim:character
recipe split [
  local-scope
  s:address:array:character <- next-ingredient
  delim:character <- next-ingredient
  # empty string? return empty array
  len:number <- length s:address:array:character/lookup
  {
    empty?:boolean <- equal len:number, 0
    break-unless empty?:boolean
    result:address:array:address:array:character <- new location:type, 0
    reply result:address:array:address:array:character
  }
  # count #pieces we need room for
  count:number <- copy 1  # n delimiters = n+1 pieces
  idx:number <- copy 0
  {
    idx:number <- find-next s:address:array:character, delim:character, idx:number
    done?:boolean <- greater-or-equal idx:number, len:number
    break-if done?:boolean
    idx:number <- add idx:number, 1
    count:number <- add count:number, 1
    loop
  }
  # allocate space
  result:address:array:address:array:character <- new location:type, count:number
  # repeatedly copy slices start..end until delimiter into result[curr-result]
  curr-result:number <- copy 0
  start:number <- copy 0
  {
    # while next delim exists
    done?:boolean <- greater-or-equal start:number, len:number
    break-if done?:boolean
    end:number <- find-next s:address:array:character, delim:character, start:number
    # copy start..end into result[curr-result]
    dest:address:address:array:character <- index-address result:address:array:address:array:character/lookup, curr-result:number
    dest:address:address:array:character/lookup <- string-copy s:address:array:character, start:number, end:number
    # slide over to next slice
    start:number <- add end:number, 1
    curr-result:number <- add curr-result:number, 1
    loop
  }
  reply result:address:array:address:array:character
]

scenario string-split-1 [
  run [
    1:address:array:character <- new [a/b]
    2:address:array:address:array:character <- split 1:address:array:character, 47/slash
    3:number <- length 2:address:array:address:array:character/lookup
    4:address:array:character <- index 2:address:array:address:array:character/lookup, 0
    5:address:array:character <- index 2:address:array:address:array:character/lookup, 1
    10:array:character <- copy 4:address:array:character/lookup
    20:array:character <- copy 5:address:array:character/lookup
  ]
  memory-should-contain [
    3 <- 2  # length of result
    10:string <- [a]
    20:string <- [b]
  ]
]

scenario string-split-2 [
  run [
    1:address:array:character <- new [a/b/c]
    2:address:array:address:array:character <- split 1:address:array:character, 47/slash
    3:number <- length 2:address:array:address:array:character/lookup
    4:address:array:character <- index 2:address:array:address:array:character/lookup, 0
    5:address:array:character <- index 2:address:array:address:array:character/lookup, 1
    6:address:array:character <- index 2:address:array:address:array:character/lookup, 2
    10:array:character <- copy 4:address:array:character/lookup
    20:array:character <- copy 5:address:array:character/lookup
    30:array:character <- copy 6:address:array:character/lookup
  ]
  memory-should-contain [
    3 <- 3  # length of result
    10:string <- [a]
    20:string <- [b]
    30:string <- [c]
  ]
]

scenario string-split-missing [
  run [
    1:address:array:character <- new [abc]
    2:address:array:address:array:character <- split 1:address:array:character, 47/slash
    3:number <- length 2:address:array:address:array:character/lookup
    4:address:array:character <- index 2:address:array:address:array:character/lookup, 0
    10:array:character <- copy 4:address:array:character/lookup
  ]
  memory-should-contain [
    3 <- 1  # length of result
    10:string <- [abc]
  ]
]

scenario string-split-empty [
  run [
    1:address:array:character <- new []
    2:address:array:address:array:character <- split 1:address:array:character, 47/slash
    3:number <- length 2:address:array:address:array:character/lookup
  ]
  memory-should-contain [
    3 <- 0  # empty result
  ]
]

scenario string-split-empty-piece [
  run [
    1:address:array:character <- new [a/b//c]
    2:address:array:address:array:character <- split 1:address:array:character, 47/slash
    3:number <- length 2:address:array:address:array:character/lookup
    4:address:array:character <- index 2:address:array:address:array:character/lookup, 0
    5:address:array:character <- index 2:address:array:address:array:character/lookup, 1
    6:address:array:character <- index 2:address:array:address:array:character/lookup, 2
    7:address:array:character <- index 2:address:array:address:array:character/lookup, 3
    10:array:character <- copy 4:address:array:character/lookup
    20:array:character <- copy 5:address:array:character/lookup
    30:array:character <- copy 6:address:array:character/lookup
    40:array:character <- copy 7:address:array:character/lookup
  ]
  memory-should-contain [
    3 <- 4  # length of result
    10:string <- [a]
    20:string <- [b]
    30:string <- []
    40:string <- [c]
  ]
]

# x:address:array:character, y:address:array:character <- split-first text:address:array:character, delim:character
recipe split-first [
  local-scope
  text:address:array:character <- next-ingredient
  delim:character <- next-ingredient
  # empty string? return empty strings
  len:number <- length text:address:array:character/lookup
  {
    empty?:boolean <- equal len:number, 0
    break-unless empty?:boolean
    x:address:array:character <- new []
    y:address:array:character <- new []
    reply x:address:array:character, y:address:array:character
  }
  idx:number <- find-next text:address:array:character, delim:character, 0
  x:address:array:character <- string-copy text:address:array:character, 0, idx:number
  idx:number <- add idx:number, 1
  y:address:array:character <- string-copy text:address:array:character, idx:number, len:number
  reply x:address:array:character, y:address:array:character
]

scenario string-split-first [
  run [
    1:address:array:character <- new [a/b]
    2:address:array:character, 3:address:array:character <- split-first 1:address:array:character, 47/slash
    10:array:character <- copy 2:address:array:character/lookup
    20:array:character <- copy 3:address:array:character/lookup
  ]
  memory-should-contain [
    10:string <- [a]
    20:string <- [b]
  ]
]

# result:address:array:character <- string-copy buf:address:array:character, start:number, end:number
# todo: make this generic
recipe string-copy [
  local-scope
  buf:address:array:character <- next-ingredient
  start:number <- next-ingredient
  end:number <- next-ingredient
  # if end is out of bounds, trim it
  len:number <- length buf:address:array:character/lookup
  end:number <- min len:number, end:number
  # allocate space for result
  len:number <- subtract end:number, start:number
  result:address:array:character <- new character:type, len:number
  # copy start..end into result[curr-result]
  src-idx:number <- copy start:number
  dest-idx:number <- copy 0
  {
    done?:boolean <- greater-or-equal src-idx:number, end:number
    break-if done?:boolean
    src:character <- index buf:address:array:character/lookup, src-idx:number
    dest:address:character <- index-address result:address:array:character/lookup, dest-idx:number
    dest:address:character/lookup <- copy src:character
    src-idx:number <- add src-idx:number, 1
    dest-idx:number <- add dest-idx:number, 1
    loop
  }
  reply result:address:array:character
]

scenario string-copy-copies-substring [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- string-copy 1:address:array:character, 1, 3
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [bc]
  ]
]

scenario string-copy-out-of-bounds [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- string-copy 1:address:array:character, 2, 4
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- [c]
  ]
]

scenario string-copy-out-of-bounds-2 [
  run [
    1:address:array:character <- new [abc]
    2:address:array:character <- string-copy 1:address:array:character, 3, 3
    3:array:character <- copy 2:address:array:character/lookup
  ]
  memory-should-contain [
    3:string <- []
  ]
]

recipe min [
  local-scope
  x:number <- next-ingredient
  y:number <- next-ingredient
  {
    return-x?:boolean <- lesser-than x:number, y:number
    break-if return-x?:boolean
    reply y:number
  }
  reply x:number
]

recipe max [
  local-scope
  x:number <- next-ingredient
  y:number <- next-ingredient
  {
    return-x?:boolean <- greater-than x:number, y:number
    break-if return-x?:boolean
    reply y:number
  }
  reply x:number
]
