program define sdchronoplot
syntax varlist(min=2) [if] [in], [BY(string) LEGend(string) * PROPortional YDF(real 1.0)]

if "`by'" != "" local by "by(`by')"

sdplot `varlist' `if' `in', `proportional' `by' `options' plottype(chron) ydf(`ydf') legend(`legend')

end
