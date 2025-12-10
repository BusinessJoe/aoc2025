STAT p1(5*4) p2(5*4) dial dist scratch right_copy (line)
line is (cont right n d1 d2 d3 scratch)

skip over solution space = 40 cells
>>>>>>>>>>
>>>>>>>>>>
>>>>>>>>>>
>>>>>>>>>>

>+++++[<++++++++++>-]<
setup (sols) ^dial=50 (line)
>>>>   point at line
+   set cont
[   loop read line
=== BEGIN READ LINE ===

assumes pointing at cont

>[-]    reset right
>[-]    reset n
>,      read into d1 (scratch)
will either be L=76 or R=82 or EOF=0
<<<->>>   reset cont
[
  <<<+>>> set cont

  determine if L or R by subtracting 76=4*19
  >++++[<
  ----------
  ---------
  >-]<

  [
    if not zero then we had R
    <<+>>
    [-] clear d1 (scratch)
  ]

  === BEGIN READ DIGIT ===
  assumes pointing at d1
  
  ,     first digit always present
  >,    second char may be LF=10
  ----------
  [
    ++++++++++
    not LF read next
    >,  third char may be LF=10
    ----------
    [
      ++++++++++
      not LF next is guaranteed to be LF so read and clear
      >,[-]<

      <<    point at 100s digit
      subtract '0'=48=4*12 using scratch space beyond digits
      >>>++++[<<<------------>>>-]<<<
      
      add 100s digit to part2
      [-<<<<<<<<
=== BEGIN INCREMENT ===
+[
  -
  <<<<+
  >>+
  <<----------
  [
    >>-
    <<[>+<-]
  ]
  >[<+>-]
  <++++++++++>

  >[
    -
    <<---------->>
    >[<<<<<+>>>>>-]
    <<<<<
    +
    >+
    <<
  ]

  >>
]

<[
  [>>>>>+<<<<<-]
  >>>>>-
]

>
=== END INCREMENT ===  
      >>>>>>>>]

      move 10s digit left
      >[<+>-]

      move 1s digit left
      >[<+>-]
    ]

    handle 2 digit number by adding 10s digit to n
    <<   point at 10s digit
    subtract '0'=48=4*12 using scratch space beyond digits
    >>++++[<<------------>>-]<<

    [<++++++++++>-]

    move 1s digit left
    >[<+>-]
  ]
  
  handle 1 digit number by adding to n
  < point at 1s digit 
  subtract '0'=48=4*12 using scratch space beyond digits
  >>++++[<<------------>>-]<< 

  [<+>-]


  === END READ DIGITS ===
]

<<<  point back at cont

=== END READ LINE ===

=== BEGIN HANDLE LINE ===
assumes pointing at cont

<<<<  point at dial
[
  copies dial to dist without clearing dial
  [->>+<<]
  >>[-<+<+>>]<<
  
  >>>>>  point at right
  [
    -<<+>>  move value to right_copy
    right rotation so dist=100 minus dial
    <<<<     point to dist
    [-]
    >++++++++++[<++++++++++>-]< add 100 to dist
    <   point to dial
    [->-<]  subtract dial from dist
    >>>>>    point at right
  ]
  <<[>>+<<-]    move value from right_copy to right
  <<<    point at dial
  [-] clear dial
]


>>>>>>   point at n
[
  - decrement n
  <<<<< point at dist
  >+<   set iszero (scratch)
  [
    if not zero then reset iszero
    >-<
    [<+>-]  copy to dial
  ]
  <[>+<-]> copy back to dist
  >     point at iszero
  [
    -
    ++++++++++[<++++++++++>-] set dist to 100
  ]
  < point at dist
  - decrement dist
  >+<   set iszero (scratch)
  [
    if not zero then reset iszero
    >-<
    [<+>-]  copy to dial
  ]
  <[>+<-]> copy back to dist
  >     point at iszero
  [
    -
    <<< point at p2
=== BEGIN INCREMENT ===
+[
  -
  <<<<+
  >>+
  <<----------
  [
    >>-
    <<[>+<-]
  ]
  >[<+>-]
  <++++++++++>

  >[
    -
    <<---------->>
    >[<<<<<+>>>>>-]
    <<<<<
    +
    >+
    <<
  ]

  >>
]

<[
  [>>>>>+<<<<<-]
  >>>>>-
]

>
=== END INCREMENT ===  
    >>> point at iszero
  ]
  < point at dist
  >>>>> point at n
]


check if dist is zero and increment p1 if it is
<<<<< point at dist
>+<   set iszero (scratch)
[
  if not zero then reset iszero
  >-<
  [<+>-]  copy to dial
]
<[>+<-]> copy back to dist
>     point at iszero
[
  -
  <<<
  <<<<<<<<<<
  <<<<<<<<<<
=== BEGIN INCREMENT ===
+[
  -
  <<<<+
  >>+
  <<----------
  [
    >>-
    <<[>+<-]
  ]
  >[<+>-]
  <++++++++++>

  >[
    -
    <<---------->>
    >[<<<<<+>>>>>-]
    <<<<<
    +
    >+
    <<
  ]

  >>
]

<[
  [>>>>>+<<<<<-]
  >>>>>-
]

>
=== END INCREMENT ===  
  >>>>>>>>>>
  >>>>>>>>>>
  >>>
]


<   point at dist
[
  copies dist to dial without clearing dist
  [->+<]
  >[-<+<+>>]<
  
  >>>>  point at right
  [
    -<<+>>  move value to right_copy
    right rotation so dial=100 minus dist
    <<<<<     point to dial
    [-]
    >>++++++++++[<<++++++++++>>-]<< add 100 to dial
    >   point to dist
    [-<->]  subtract dist from dial
    >>>>    point at right
  ]
  <<[>>+<<-]    move value from right_copy to right
  <<    point at dist
  [-] clear dist
]


=== END HANDLE LINE ===

>>> point at cont

]


<<<<<
<<<<<<<<<<
<<<<<<<<<<  point at p1

<<<<<<<<<<<<<<< point at first digit of p1

=== print ===
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit

[-]++++++++++. print newline


=== print ===

<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
>>>>>>>>> next digit
<<< one right of acc
++++[<++++++++++++>-] add 48 to acc
<.  print acc
