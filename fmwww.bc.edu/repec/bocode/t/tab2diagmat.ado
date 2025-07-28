*! version 1.0.0  30apr2025
program tab2diagmat
    
    version 11.2
    
    syntax anything(id="matname") [ , * ]
    
    tempname matname
    matrix `matname' = `anything'
    
    if ( (rowsof(`matname')!=2) | (colsof(`matname')!=2) ) {
        
        display as err "matrix not 2 x 2"
        exit 503
        
    }
    
    local a = `matname'[1,1]
    local b = `matname'[1,2]
    local c = `matname'[2,1]
    local d = `matname'[2,2]
    
    version `=_caller()' : tab2diagi `a' `b' `c' `d' , `options'
    
end


exit


/*  _________________________________________________________________________
                                                              Version history

1.0.0   30apr2025
