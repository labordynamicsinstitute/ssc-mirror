xtmixed, variance
esttab, se wide nostar transform(ln*: exp(2*@) 2*exp(2*@))   ///
    eqlabels("" "var(week)" "var(_cons)" "var(Residual)", none) ///
    varlabels(,elist(weight:_cons "{break}{hline @width}")) ///
    varwidth(13)
