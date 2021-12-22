spex binlfp2
quietly logit lfp k5 k618 age wc hc lwg inc, nolog
estadd prchange
esttab, cells("dc[2] dc[3] dc[4] dc[5] dc[6]")
esttab, cells("dc[min->max] dc[0->1] dc[-+1/2] dc[-+sd/2] dc[MargEfct]")
