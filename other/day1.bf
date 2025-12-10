STAT p1(5*4) p2(5*4) dial (line)
line is (cont right n d1 d2 d3 scratch)

skip over solution space = 40 cells
>>>>>>>>>>
>>>>>>>>>>
>>>>>>>>>>
>>>>>>>>>>

>+++++[<++++++++++>-]<
setup (sols) ^dial=50 (line)
>   point at line
+   set cont
=== BEGIN READ LINE ===

assumes pointing at cont

>[-]    reset right
>[-]    reset n
,      read into n (scratch)
will either be L=76 or R=82 or EOF=0
<<->>   reset cont
[
  <<+>> set cont

  determine if L or R by subtracting 76=4*19
  >++++[<
  ----------
  ---------
  >-]<

  [
    if not zero then we had R
    <+>
    [-] clear n (scratch)
  ]

  > point at d1

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
      [-<<<<<
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
      >>>>>]

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

<<  point back at cont

=== END READ LINE ===



