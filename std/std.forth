[ "+" swap 1 . ] "+" ;
[ "-" swap 1 . ] "-" ;
[ "*" swap 1 . ] "*" ;
[ "/" swap 1 . ] "/" ;
[ "%" swap 1 . ] "%" ;

[ false true if ] "not" ;
[ swap dup rot [drop] [drop drop false] if ] "and" ;
[ swap dup rot [drop drop true] [drop] if ] "or" ;
[ "<" swap 1 . ] "<" ;
[ "==" swap 1 . ] "=" ;
[ "<=" swap 1 . ] "<=" ;
[ ">=" swap 1 . ] ">=" ;
[ = not ] "<>" ;

