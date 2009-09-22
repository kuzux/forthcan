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

[ "Kernel" ruby "puts" rot 1 . drop ] "print" ;
[ "Kernel" ruby "exit" 0 . ] "exit" ;

[ stack print ] "show" ;

