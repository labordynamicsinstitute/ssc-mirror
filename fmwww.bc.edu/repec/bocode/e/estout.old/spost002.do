spex binlfp2
quietly logit lfp k5 k618 age wc hc lwg inc, nolog
estadd listcoef, std
eststo logit
quietly probit lfp k5 k618 age wc hc lwg inc, nolog
estadd listcoef
eststo probit
esttab, aux(b_std) nopar wide mtitles
eststo clear
