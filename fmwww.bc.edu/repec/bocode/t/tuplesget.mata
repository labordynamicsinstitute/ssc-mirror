*! version 1.0.0  25sep2025


version 10


mata :


mata set matastrict   on
mata set mataoptimize on


struct tuples__info
{
    // input
    
    pointer(transmorphic vector) scalar v
    real                         scalar n
    pointer(real vector)         scalar r
    real                         scalar nr
    
    // Algorithm AS 88 nCr (Gentleman, 1975)
    
    real                         scalar ri
    real                         scalar i
    real                         scalar kount
    real                         scalar nmr
    real                         vector j
    
    // ancillary
    
    real                         scalar kount_missing
    real                         scalar ncomb
    real                         scalar nmiss
    transmorphic                 matrix empty_tuple
    transmorphic                 matrix missing_tuple
}


    /*  _____________________________________________________________________
                                                            tuplessetup()  */

transmorphic scalar tuplessetup(
    
    transmorphic    vector v,
  | real            vector r
    
    )
{
    struct tuples__info scalar t
    
    
    t.v             = &v
    t.n             = length(*t.v)
    
    t.r             = length(r) ? &r : &(1..t.n)
    t.nr            = length(*t.r)
    
    t.ri            = 0
    t.i             = 0
    
    t.kount         = 0
    t.kount_missing = 0
    
    t.empty_tuple   = J((rows(*t.v)==1),(rows(*t.v)!=1),missingof(*t.v))
    t.missing_tuple = J(0,0,missingof(*t.v))
    
    return(t)
}

transmorphic scalar tuplesinit(transmorphic vector v, | real vector r)
{
    return(args()<2 ? tuplessetup(v) : tuplessetup(v,r))
}


    /*  _____________________________________________________________________
                                                              tuplesget()  */

transmorphic matrix tuplesget(struct tuples__info scalar t)
{
    transmorphic vector res
    
    
    if ( tuplesdone(t) )
        return(t.empty_tuple)
    
    if ( !t.i ) {
        
        (void) t.ri++
        
        if ( ((*t.r)[t.ri]<1) | ((*t.r)[t.ri]>t.n) ) {
            
            (void) t.kount_missing++
            
            return(t.missing_tuple)
            
        }
        
        t.nmr = t.n-(*t.r)[t.ri]
        t.j   = ((t.i=1)..(*t.r)[t.ri])
        
    }
    
    (void) t.kount++
    
    res = (*t.v)[t.j]
    
    t.i = (*t.r)[t.ri]
    
    while (t.j[t.i] >= t.nmr+t.i) if ( !(--t.i) ) break
    
    if ( t.i ) {
        
        t.j[t.i] = t.j[t.i] + 1
        
        while (t.i < (*t.r)[t.ri]) {
            
            t.j[t.i+1] = t.j[t.i] + 1
            (void) t.i++
            
        }
        
    }
    
    return(res)
}


   /*  _____________________________________________________________________
                                                            tuplesdone()  */


real scalar tuplesdone(struct tuples__info scalar t)
{
    if ( t.i )
        return(0)
    
    if (t.ri+1 > t.nr)
        return(1)
    
    return( !t.n )
}


   /*  _____________________________________________________________________
                                        tupleskount(), tupleskountrest()  */

real scalar tupleskount(
    
    struct tuples__info scalar t,
  | real                scalar all
    
    )
{
    return((all ? t.kount + t.kount_missing : t.kount))
}

real scalar tuplescount(struct tuples__info scalar t, | real scalar all)
{
    return(tupleskount(t,all))
}


real scalar tupleskountrest(
    
    struct tuples__info scalar t,
  | real                scalar all
    
    )
{
    if (t.ncomb == .)
        t.ncomb = rowsum(comb(t.n,editvalue(*t.r,0,.)))
     
     if ( !all )
        return(t.ncomb - t.kount)
     
     if (t.nmiss == .)
        t.nmiss = t.n ? rowsum((*t.r:<1):|(*t.r:>t.n)) : 0
     
     return((t.ncomb+t.nmiss) - (t.kount+t.kount_missing))
}

real scalar tuplescountrest(struct tuples__info scalar t, | real scalar all)
{
    return(tupleskountrest(t,all))
}


   /*  _____________________________________________________________________
                                    tuplessetempty(), tuplessetmissing()  */

transmorphic matrix tuplessetempty(
    
    struct tuples__info scalar t,
  | transmorphic        matrix value
    
    )
{
    if (args() > 1)
        t.empty_tuple = value
        
    return(t.empty_tuple)
}

transmorphic matrix tuplessetmissing(
    
    struct tuples__info scalar t,
  | transmorphic        matrix value
    
    )
{
    if (args() > 1)
        t.missing_tuple = value
    
    return(t.missing_tuple)
}


end
