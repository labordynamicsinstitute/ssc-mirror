spex binlfp2
quietly logit lfp k5 k618 age wc hc lwg inc, nolog
estadd listcoef, quietly std
estadd listcoef, quietly fact nosd
estadd listcoef, quietly per nosd
esttab, cell("b_std b_facts b_pcts b_sdx")
