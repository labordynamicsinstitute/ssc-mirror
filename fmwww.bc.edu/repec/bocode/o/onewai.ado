program define onewai
    version 12
    return clear
    _onewai `0'
    matprint r(table), decimals((0,3)) title(Summary table of data)
    matprint r(anova), decimals((2,0,2)) title(Analysis of Variance)
    matprint r(bartletts), decimals((3,0,2)) title(Bartlett's test of equal variances)
    matprint r(icc), decimals(3) title(ICC and asymptotic confidence interval)
end

program define _onewai, rclass
    syntax , [N(numlist) Means(numlist) Sds(numlist) NMSmatrix(string) Transpose]

    mata: _onewai = nhb_mt_onewai()
    
    if `"`nmsmatrix'"' != `""' {
        tempname tmp
        matrix `tmp' = `nmsmatrix'
        mata: _onewai.nmsmatrix(`"`tmp'"', `"`transpose'"' != `""')        
    }
    else {
    	syntax , N(numlist) Means(numlist) Sds(numlist)
        mata: _onewai.counts(strtoreal(tokens(`"`n'"')))
        mata: _onewai.means(strtoreal(tokens(`"`means'"')))
        mata: _onewai.sds(strtoreal(tokens(`"`sds'"')))
    }
    
    mata: _onewai.do_anova()
    mata: _onewai.totalmean().to_matrix("r(total)")
    mata: _onewai.icc().to_matrix("r(icc)")
    mata: _onewai.table().to_matrix("r(table)")
    mata: _onewai.bartletts().to_matrix("r(bartletts)")
    mata: _onewai.anova().to_matrix("r(anova)")
    return add
end
