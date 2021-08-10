spex ordwarm2
quietly slogit warm yr89 male white age ed prst, nolog
estadd prchange age ed prst, outcome(2)
esttab, cell("dc[Min->Max] dc[-+1/2] dc[-+sd/2]") stats(predval outcome)
