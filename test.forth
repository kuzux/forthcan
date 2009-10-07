[ "\n" print puts ] "section" ;

"simple equality tests" section
true true asserteq
true false assertneq
3 3 asserteq
3 5 assertneq

"sending methods" section
-3 "abs" 0 . 3 asserteq
3 "+" 5 1 . 8 asserteq

"arithmetic" section
3 5 + 8 asserteq
5 3 - 2 asserteq
3 5 * 15 asserteq
12 4 / 3 asserteq

"stack operations" section
3 5 drop 3 asserteq
5 dup 5 asserteq 5 asserteq
3 5 swap 3 asserteq 5 asserteq
3 5 7 rot 3 asserteq 7 asserteq drop

"\n" print
exit
