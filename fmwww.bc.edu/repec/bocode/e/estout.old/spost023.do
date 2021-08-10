spex ordwarm2
quietly ologit warm yr89 male white age ed prst, nolog
estadd listcoef, std
eststo ologit
quietly oprobit warm yr89 male white age ed prst, nolog
estadd listcoef
eststo oprobit
esttab, aux(b_std) nopar wide eqlabels(none) mtitles
eststo clear
