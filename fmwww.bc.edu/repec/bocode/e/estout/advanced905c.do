mat rownames A = "eq1:row1" "eq1:row2" "eq2:row1" "eq2:row2"
esttab matrix(A)
esttab matrix(A), unstack compress
set seed 123
matrix A = matuniform(4,4)
mat coleq A = eq1 eq1 eq2 eq2
mat roweq A = eq1 eq1 eq2 eq2
esttab matrix(A), eqlabels(,merge)
