spex binlfp2
quietly cloglog lfp k5 k618 age wc hc lwg inc, nolog
estadd fitstat
estadd listcoef
esttab, cell("b b_xs b_sdx") scalars(r2_mf r2_mfadj r2_ml r2_cu)
