*! version 2.0.1  20jun2026  Ben Jann

program addlegend, rclass
    version 14
    local caller : di _caller()
    _on_colon_parse `0'
    local 0 `"`s(before)'"'
     _parse comma lhs 0 : 0
    syntax [, nodraw Margin(passthru) * ]
    if `"`margin'"'!="" local margin graphregion(`margin')
    _mklegend `lhs', `options' : `s(after)'
    local legend `"`r(legend)'"'
    local graph  `"`r(graphname)'"'
    local subgr  `"`r(subgraphs)'"'
    local grfam  `"`r(graphfamily)'"'
    return add
    if `"`grfam'"'=="by" { // suppress global legend
        capt .`graph'.legend.draw_view.setstyle, style(no)
    }
    version `caller': addplot `graph' `subgr', `draw':/*
        */ `legend', norescaling legend(off) `margin'
end
