capt prog drop appendmodels
*! version 1.0.0  14aug2007  Ben Jann
program appendmodels, eclass
    // using first equation of model
    version 8
    syntax namelist
    tempname b V tmp
    foreach name of local namelist {
        qui est restore `name'
        mat `tmp' = e(b)
        local eq1: coleq `tmp'
        gettoken eq1 : eq1
        mat `tmp' = `tmp'[1,"`eq1':"]
        local cons = colnumb(`tmp',"_cons")
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1,1..`cons'-1]
        }
        mat `b' = nullmat(`b') , `tmp'
        mat `tmp' = e(V)
        mat `tmp' = `tmp'["`eq1':","`eq1':"]
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
        }
        capt confirm matrix `V'
        if _rc {
            mat `V' = `tmp'
        }
        else {
            mat `V' = ///
            ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
            ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
        }
    }
    local names: colfullnames `b'
    mat coln `V' = `names'
    mat rown `V' = `names'
    eret post `b' `V'
    eret local cmd "whatever"
end
sysuse auto
eststo b1: quietly regress price weight
eststo b2: quietly regress price mpg
eststo b3: quietly regress price foreign
eststo bivar: appendmodels b1 b2 b3
eststo multi: quietly regress price weight mpg foreign
esttab b1 b2 b3 bivar, mtitles
esttab multi bivar, mtitles
eststo clear
