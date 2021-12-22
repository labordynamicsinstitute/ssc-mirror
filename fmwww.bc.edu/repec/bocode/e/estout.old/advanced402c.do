xtmixed weight week || id: week, covariance(unstructured)
esttab, se wide nostar ///
    transform(ln*: exp(@) exp(@) at*: tanh(@) (1-tanh(@)^2)) ///
    eqlabels("" "sd(week)" "sd(_cons)" "corr(week,_cons)" "sd(Residual)", ///
        none) ///
    varlabels(,elist(weight:_cons "{break}{hline @width}"))  ///
    varwidth(16)
