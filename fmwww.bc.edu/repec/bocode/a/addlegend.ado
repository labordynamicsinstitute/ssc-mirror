*! version 2.0.0  14jun2026  Ben Jann

program addlegend, rclass
    version 14
    _on_colon_parse `0'
    local 0 `"`s(before)'"'
     _parse comma lhs 0 : 0
    syntax [, nodraw Margin(passthru) * ]
    if `"`margin'"'!="" local margin graphregion(`margin')
    _mklegend `lhs', `options' : `s(after)'
    local legend `"`r(legend)'"'
    return add
    addplot `lhs', `draw': `legend', norescaling legend(off) `margin'
end
