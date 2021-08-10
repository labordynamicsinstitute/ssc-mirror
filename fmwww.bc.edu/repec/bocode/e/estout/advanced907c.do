sysuse auto
eststo model1: quietly reg price weight
eststo model2: quietly reg price weight mpg
esttab, se nostar r2
matrix C = r(coefs)
matrix S = r(stats)
eststo clear
local rnames : rownames C
local models : coleq C
local models : list uniq models
local i 0
foreach name of local rnames {
    local ++i
    local j 0
    capture matrix drop b
    capture matrix drop se
    foreach model of local models {
        local ++j
        matrix tmp = C[`i', 2*`j'-1]
        if tmp[1,1]<. {
            matrix colnames tmp = `model'
            matrix b = nullmat(b), tmp
            matrix tmp[1,1] = C[`i', 2*`j']
            matrix se = nullmat(se), tmp
        }
    }
    ereturn post b
    quietly estadd matrix se
    eststo `name'
}
local snames : rownames S
local i 0
foreach name of local snames {
    local ++i
    local j 0
    capture matrix drop b
    foreach model of local models {
        local ++j
        matrix tmp = S[`i', `j']
        matrix colnames tmp = `model'
        matrix b = nullmat(b), tmp
    }
    ereturn post b
    eststo `name'
}
esttab, se mtitle noobs compress nonumb
eststo clear
