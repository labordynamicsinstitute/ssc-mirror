spex ordwarm2
quietly slogit warm yr89 male white age ed prst, nolog
estadd prchange male age prst
esttab, main(dc) unstack nostar not
