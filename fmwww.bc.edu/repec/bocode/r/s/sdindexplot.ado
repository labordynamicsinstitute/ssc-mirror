program define sdindexplot
syntax varlist(min=2) [if] [in], [ORDer(string) BY(string) *]

if "`order'" != "" local order "order(`order')"
if "`by'" != "" local by "by(`by')"


sdplot `varlist' `if' `in', `order' `by' `options' plottype(index)

end
