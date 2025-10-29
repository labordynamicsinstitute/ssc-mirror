capt prog drop _all
prog savestats, rclass
frame create ss
frame change ss
qui set obs 1
loc var `r(actual)'
g rmse = r(rmse)
g mae = r(mae)
g mape = r(mape)
g qlike = r(qlike)
g theilu = r(theilu)
g n = r(N)
g str act = r(actual)
g str fc = r(forecast)
g str model = "`1'"
save `var'_`1', replace
frame change default
frame drop ss
end
