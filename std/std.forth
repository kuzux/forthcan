[ "+" swap 1 . ] "+" ;
[ "-" swap 1 . ] "-" ;
[ "*" swap 1 . ] "*" ;
[ "/" swap 1 . ] "/" ;
[ "%" swap 1 . ] "%" ;

[ stack "popn" 0 . ] "drop" ;

[ false true if ] "not" ;
[ swap dup rot [drop] [drop drop false] if ] "and" ;
[ swap dup rot [drop drop true] [drop] if ] "or" ;
[ "<" swap 1 . ] "<" ;
[ "==" swap 1 . ] "=" ;
[ "<=" swap 1 . ] "<=" ;
[ ">=" swap 1 . ] ">=" ;
[ = not ] "<>" ;

[ stack "[]" rot -1 * 1 . ] "nth";
[ callstack "[]" -2 1 . "clone" 0 . ] "pushcc" ;
[ callstack "pushn" rot 1 . ] "call" ;

[ vars "[]" rot 1 . ] "@" ;
[ vars rot rot "[]=" rot rot 2 . ] "!";

[ "Kernel" ruby "print" rot 1 . ] "print" ;
[ "Kernel" ruby "puts" rot 1 . ] "puts" ;
[ "Kernel" ruby "p" rot 1 . drop ] "p" ;
[ "Kernel" ruby "exit" 0 . ] "exit" ;

[["."] ["F"] if print] "assert" ;
[["F"] ["."] if print] "assertf" ;
[ = assert] "asserteq" ;
[ <> assert] "assertneq" ;

[ stack p ] "show" ;
