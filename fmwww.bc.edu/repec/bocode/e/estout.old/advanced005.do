sysuse auto
quietly regress price mpg foreign weight displ
esttab, labcol2(+ ? + -, title("" Hypothesis))
