[ "+" swap 1 . ] "+" ;
[ "-" swap 1 . ] "-" ;
[ "*" swap 1 . ] "*" ;
[ "/" swap 1 . ] "/" ;
[ "%" swap 1 . ] "%" ;

[ stack "pop" 0 . ] "drop" ;

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

[ "Kernel" ruby "puts" rot 1 . drop ] "print" ;
[ "Kernel" ruby "p" rot 1 . drop ] "p" ;
[ "Kernel" ruby "exit" 0 . ] "exit" ;

[ stack p ] "show" ;

