*! version 4.2.2 09jul2021 daniel klein
program elabel
    version 11.2
    version `= _caller()' : mata : elabel()
end

version 11.2

mata : st_local("fn", findfile("elabel.mata"))
if (`"`fn'"' != "") include `"`fn'"'

exit

/* ---------------------------------------
see elabel.mata for version history
