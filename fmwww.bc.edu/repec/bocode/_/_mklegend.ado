*! version 2.0.0  14jun2026  Ben Jann

program _mklegend, rclass
    version 14
    _on_colon_parse `0'
    local 0 `"`s(before)'"'
    
    // parse s(after)
    mata: keys_expand() // returns key_n, key_#
    
    // parse [graphname] [numlist]
    _parse comma subgr 0 : 0
    gettoken graph : subgr
    capt confirm name `graph'
    if _rc==0 gettoken graph subgr : subgr
    else local graph
    if `"`subgr'"'!="" {
        numlist `"`subgr'"', integer range(>=1)
        local subgr `r(numlist)'
    }
    
    // parse options
    syntax [, nodraw Margin(passthru) /*
        */ FRame FRame2(str) lskip(real 1.5)/*
        */ y(real 96) x(real 2) h(real 5) w(real 5)/*
        */ ty(real 0) tx(numlist max=1) tw(real 20) Text(str)/*
        */ PSTYle(passthru) * ]
    mata: extract_opts(("Y", "X", "H", "W", "TY", "TX", "TW"))
    foreach opt in Y X H W TY TX TW {
        if "``opt''"!="" numlist `"``opt''"', max(1)
    }
    foreach opt in Y X H W tx TY TX TW {
        if "``opt''"=="" local `opt' .
    }
    parse_topts, `text' // returns place, just, topts
    if `"`frame'`frame2'"'!="" {
        local frame frame
        parse_frame, `frame2'
    }
    
    // get limits of plotregion from graph
    parse_graph "`graph'" `subgr' // returns Ymin Ymax, Xmin, Xmax
    local Yr = (`Ymax' - `Ymin')
    local Xr = (`Xmax' - `Xmin')
    if `Y'>=.  local Y  = `Ymin' + `y' * `Yr' / 100
    else       local y  = (`Y' - `Ymin') * 100 / `Yr' 
    if `X'>=.  local X  = `Xmin' + `x' * `Xr' / 100
    else       local x  = (`X' - `Xmin') * 100 / `Xr' 
    if `H'>=.  local H  = `h' * `Yr' / 100
    else       local h  = `H' * 100 / `Yr'
    if `W'>=.  local W  = `w' * `Xr' / 100
    else       local w  = `W' * 100 / `Xr'
    if `TY'>=. local TY = `ty' * `Yr' / 100
    else       local ty = `TY' * 100 / `Yr'
    if `TX'>=. local TX = `tx' * `Xr' / 100
    else       local tx = `TY' * 100 / `Xr'
    if `TW'>=. local TW = `tw' * `Xr' / 100
    else       local tw = `TW' * 100 / `Xr'
    
    // global settings
    foreach opt in Xmax Xmin Ymax Ymin lskip TW TX TY W H X Y tw tx ty w h x y {
        return scalar `opt' = ``opt''
    }
    
    // create keys
    local minY `Y'
    local maxY `Y'
    local minX `X'
    local maxX `X'
    local p 0
    forv i=1/`key_n' {
        parse_key `minY' `maxY' `minX' `maxX'/*
            */ `p' `Ymin' `Yr' `Xmin' `Xr' `Y' `X' `H' `W' `"`pstyle'"'/*
            */`"`options'"' `TY' `TX' `TW' `"`place'"' `"`just'"' `"`topts'"'/*
            */ `key_`i'' // returns plots, p, Y, X, H, W, TY, ...
        local legend `legend' `plots'
        local Y = `Y' - `lskip' * `H'
    }
    
    // create frame
    if "`frame'"!="" {
        if `fr_YM'>=. local fr_YM = `fr_ym' * `Yr' / 100
        else          local fr_xm = `fr_YM' * 100 / `Yr'
        if `fr_XM'>=. local fr_XM = `fr_xm' * `Xr' / 100
        else          local fr_xm = `fr_XM' * 100 / `Xr'
        local fr_B = cond(`Yr'<0,`maxY',`minY') - `fr_YM'
        local fr_T = cond(`Yr'<0,`minY',`maxY') + `fr_YM'
        local fr_L = cond(`Xr'<0,`maxX',`minX') - `fr_XM'
        local fr_R = cond(`Xr'<0,`minX',`maxX') + `fr_XM'
        if `fr_Y'>=. {
            if `fr_y'<. local fr_Y = `Ymin' + `fr_y' * `Yr' / 100
            else            local fr_Y = `fr_T'
        }
        if `fr_y'>=. local fr_y = (`fr_Y' - `Ymin') / `Yr' * 100
        if `fr_H'>=. {
            if `fr_h'<. local fr_H = `fr_y' * `Yr' / 100
            else            local fr_H = `fr_Y' - `fr_B'
        }
        if `fr_h'>=. local fr_h = `fr_H' / `Yr' * 100
        if `fr_X'>=. {
            if `fr_x'<. local fr_X = `Xmin' + `fr_x' * `Xr' / 100
            else            local fr_X = `fr_L'
        }
        if `fr_x'>=. local fr_x = (`fr_X' - `Xmin') / `Xr' * 100
        if `fr_W'>=. {
            if `fr_w'<. local fr_W = `fr_w' * `Xr' / 100
            else            local fr_W = `fr_R' - `fr_X'
        }
        if `fr_w'>=. local fr_w = `fr_W' / `Xr' * 100
        local fr_B = `fr_Y' - `fr_H'
        local fr_R = `fr_X' + `fr_W'
        local legend (scatteri `fr_B' `fr_X' `fr_B' `fr_R' `fr_Y' `fr_R'/*
            */ `fr_Y' `fr_X', recast(area) nodropbase `fr_opts') `legend'
        foreach opt in XM YM W H X Y xm ym w h x y {
            return scalar fr_`opt' = `fr_`opt''
        }
    }
    
    // return result
    return local legend `"`legend'"'
end

program parse_topts
    syntax [, PLACEment(str) Justification(str) * ]
    c_local place `"`placement'"'
    c_local just `"`justification'"'
    c_local topts `options'
end

program parse_graph
    gettoken name 0 : 0
    gettoken plot 0 : 0
    if `"`name'"'=="" {
        local name `"`._Gr_Global.current_graph'"'
        if `"`name'"'=="" { // no graph available
            di as txt "(no graph found; assuming range 0 to 100 for both axes)"
            c_local Ymin 0
            c_local Ymax 100
            c_local Xmin 0
            c_local Xmax 100
            exit
        }
    }
    // obtain defaults from graph
    capt classutil d `name'
    if _rc {
        di as err `"graph `name' not found"'
        exit 111
    }
    if "`plot'"!="" {
        capt classutil d `name'.graphs[`plot']
        if _rc {
            di as err `"subgraph `plot' not found"'
            exit 111
        }
        local grtype `"`.`name'.graphs[`plot'].graphfamily'"'
        if `"`grtype'"'!="twoway" {
            di as err `"subgraph `plot' not twoway"'
            exit 498
        }
    }
    else {
        local grtype `"`.`name'.graphfamily'"'
        if `"`grtype'"'!="twoway" {
            local plots
            local nplots `"`.`name'.n'"'
            capt confirm integer number `nplots'
            if _rc==0 {
                forv plot = 1/`nplots' {
                    if `"`.`name'.graphs[`plot'].graphfamily'"'=="twoway" {
                        local plots `plots' `plot'
                    }
                }
            }
            if "`plots'"=="" {
                di as err "no twoway subgraphs found in `name'"
                exit 111
            }
            gettoken plot : plots
        }
    }
    if "`plot'"=="" local Name `name'
    else            local Name `name'.graphs[`plot']
    foreach Z in Y X {
        local z = strlower("`Z'")
        local `z'rev `.`Name'.plotregion1.`z'scale.reverse.istrue'
        if `"``z'rev'"'=="1" {
            c_local `Z'min `.`Name'.plotregion1.`z'scale.curmax'
            c_local `Z'max `.`Name'.plotregion1.`z'scale.curmin'
        }
        else {
            c_local `Z'min `.`Name'.plotregion1.`z'scale.curmin'
            c_local `Z'max `.`Name'.plotregion1.`z'scale.curmax'
        }
    }
end

program parse_frame
    syntax [, y(numlist max=1) x(numlist max=1)/*
        */ h(numlist max=1) w(numlist max=1)/*
        */ ym(real 2.5) xm(real 2)/*
        */ LSTYle(passthru) FColor(passthru) * ]
    mata: extract_opts(("Y", "X", "H", "W", "YM", "XM"))
    foreach opt in Y X H W YM XM {
        if "``opt''"!="" numlist `"``opt''"', max(1)
    }
    foreach opt in y x h w Y X H W YM XM {
        if "``opt''"=="" local `opt' .
    }
    foreach opt in y x h w ym xm Y X H W YM XM {
        c_local fr_`opt' `"``opt''"'
    }
    if `"`lstyle'"'=="" local lstyle lstyle(foreground)
    if `"`fcolor'"'=="" local fcolor fcolor(white)
    c_local fr_opts `lstyle' `fcolor' `options'
end

program parse_key
    foreach arg in minY maxY minX maxX p Ymin Yr Xmin Xr _Y _X _H _W/*
        */ _pstyle _options _TY _TX _TW _place _just _topts {
        gettoken `arg' 0 : 0
    }
    _parse comma txt  0 : 0
    syntax [, /*
        */ y(numlist max=1) x(numlist max=1)/*
        */ h(numlist max=1) w(numlist max=1)/*
        */ ty(numlist max=1) tx(numlist max=1) tw(numlist max=1) Text(str)/*
        */ PSTYle(passthru) * ]
    if "`y'"!=""  local _Y  = `Ymin' + `y' * `Yr' / 100
    if "`x'"!=""  local _X  = `Xmin' + `x' * `Xr' / 100
    if "`h'"!=""  local _H  =          `h' * `Yr' / 100
    if "`w'"!=""  local _W  =          `w' * `Xr' / 100
    if "`ty'"!="" local _TY =         `ty' * `Yr' / 100
    if "`tx'"!="" local _TX =         `tx' * `Xr' / 100
    if "`tx'"!="" local _TW =         `tw' * `Xr' / 100
    mata: extract_opts(("Y", "X", "H", "W", "TY", "TX", "TW"))
    foreach opt in Y X H W TY TX TW {
        if "``opt''"!="" numlist `"``opt''"', max(1)
    }
    parse_topts, `text' // returns place, just, topts
    foreach opt in Y X H W TY TX TW pstyle place just {
        if "``opt''"!="" continue
        local `opt' `"`_`opt''"'
    }
    local options `_options' `options'
    local topts `_topts' `topts'
    
    // collect symbols
    gettoken next : txt
    if `"`next'"'=="-" {
        gettoken next txt : txt
        local sym_n  0
        local hassym 1
    }
    else {
        local i 0
        while (1) {
            gettoken next : txt, match(par)
            if `"`par'"'!="" {
                local ++i
                gettoken sym_`i' txt : txt, match(par)
                continue
            }
            continue, break
        }
        local sym_n `i'
        if `sym_n' {
            local hassym 1
            local p = mod(`++p'-1, 15) + 1
        }
        else local hassym 0
    }
    
    // plot symbols
    local plots
    forv i=1/`sym_n' {
        parse_sym `minY' `maxY' `minX' `maxX'/*
            */ `p' `Ymin' `Yr' `Xmin' `Xr' `Y' `X' `H' `W'/*
            */ `"`pstyle'"' `"`options'"' `sym_`i'' // return plot
        local plots `plots' `plot'
    }
    
    // collect label
    parse_txt `txt' // returns txt
    
    // plot label
    if `TX'>=. local tx = `W' + cond(`W'<0, -1, 1) * abs(`Xr') / 100
    else       local tx `TX'
    local y = `Y'
    local x = `X'
    if `hassym' {
        local y = `y' + `TY'
        local x = `x' + `tx'
    }
    if (sign(`tx')*sign(`Xr'))<0 {
        if `"`place'"'=="" local place left
        if `"`just'"'==""  local just  right
        local tdir -1
    }
    else {
        if `"`place'"'=="" local place right
        if `"`just'"'==""  local just  left
        local tdir 1
    }
    local topts place(`place') just(`just') `topts'
    local plots `plots' (scatteri `y' `x', ms(i) text(`y' `x' `txt', `topts'))
    local minY = min(`minY', `y' - 0.5 * `H', `y' + 0.5 * `H')
    local maxY = max(`maxY', `y' - 0.5 * `H', `y' + 0.5 * `H')
    local minX = min(`minX', `x', `x' + `tdir' * `TW')
    local maxX = max(`maxX', `x', `x' + `tdir' * `TW')
    
    // returns
    c_local minY `minY'
    c_local maxY `maxY'
    c_local minX `minX'
    c_local maxX `maxX'
    foreach opt in p Y X H W TY TX TW {
        c_local `opt' ``opt''
    }
    c_local plots `plots'
end

program parse_sym
    foreach arg in minY maxY minX maxX p Ymin Yr Xmin Xr _Y _X _H _W/*
        */ _pstyle _options {
        gettoken `arg' 0 : 0
    }
    _parse comma SYM 0 : 0
    if !`: list sizeof SYM' local SYM `""""'
    syntax [, y(numlist max=1) x(numlist max=1)/*
        */ h(numlist max=1) w(numlist max=1)/*
        */ PSTYle(passthru) * ]
    if "`y'"!="" local _Y  = `Ymin' + `y' * `Yr' / 100
    if "`x'"!="" local _X  = `Xmin' + `x' * `Xr' / 100
    if "`h'"!="" local _H  =          `h' * `Yr' / 100
    if "`w'"!="" local _W  =          `w' * `Xr' / 100
    mata: extract_opts(("Y", "X", "H", "W"))
    foreach opt in Y X H W {
        if "``opt''"!="" numlist `"``opt''"', max(1)
    }
    foreach opt in Y X H W pstyle {
        if "``opt''"!="" continue
        local `opt' `"`_`opt''"'
    }
    local options `_options' `options'
    local plots
    foreach sym of local SYM {
        if      `"`sym'"'=="rcap"    local sym "cap"
        else if `"`sym'"'=="rcapsym" local sym "capsym"
        else if `"`sym'"'=="spike"   local sym "line"
        local b = `Y' - 0.5 * `H'
        local t = `Y' + 0.5 * `H'
        local l = `X'
        local r = `X' + `W'
        local minY = min(`minY', `t', `b')
        local maxY = max(`maxY', `t', `b')
        local minX = min(`minX', `l', `r')
        local maxX = max(`maxX', `l', `r')
        local ptype ""
        if inlist(`"`sym'"',"line","cap","capsym") {
            if `"`sym'"'=="line"     local plot recast(line)
            else if `"`sym'"'=="cap" local plot recast(connect) ms(|)
            else                     local plot recast(connect)
            local plot scatteri `Y' `l' `Y' `r', `plot'
        }
        else if inlist(`"`sym'"',"area","bar","rline") {
            if `"`sym'"'=="rline" {
                local plot scatteri `t' `l' `t' `r' . . `b' `l' `b' `r',/*
                    */ recast(line) cmissing(n)
            }
            else {
                local ptype "`sym'"
                local plot scatteri `b' `l' `b' `r' `t' `r' `t' `l',/*
                    */ recast(area) nodropbase
            }
        }
        else {
            local c = `X' + 0.5 * `W'
            local plot ms(`sym')
            if `"`sym'"'=="" local plot
            local plot scatteri `Y' `c', `plot'
        }
        if `"`pstyle'"'=="" local PSTYLE pstyle(p`p'`ptype')
        else                local PSTYLE `pstyle'
        local OPTIONS `PSTYLE' `options'
        local plots `plots' (`plot' `OPTIONS')
    }
    c_local minY `minY'
    c_local maxY `maxY'
    c_local minX `minX'
    c_local maxX `maxX'
    c_local plot `plots'
end

program parse_txt
    c_local txt `"`0'"'
    while (`"`0'"'!="") {
        gettoken tok 0 : 0, qed(qed)
        if `qed' continue
        di as err `"{bf:`tok'} found where quoted text expected"'
        exit 198
    }
end

version 14
mata:
mata set matastrict on

void extract_opts(string rowvector O)
{
    string scalar    opt, arg, options
    transmorphic     t
    
    t = tokeninit(" ", "", "()")
    tokenset(t, st_local("options"))
    options = ""
    while ((opt = tokenget(t))!="") {
        arg = tokenpeek(t)
        if ((substr(arg,1,1)+substr(arg,-1,1))=="()") { // arg is "(...)"
            (void) tokenget(t)
            if (anyof(O,opt)) {
                st_local(opt, strtrim(substr(arg, 2, strlen(arg)-2)))
                continue
            }
            options = options + " " + opt + arg
            continue
        }
        options = options + " " + opt
    }
    st_local("options", substr(options, 2, .))
}

void keys_expand()
{
    real scalar   i, a, b
    string scalar s, tok
    transmorphic  t
    
    s = st_global("s(after)")
    t = tokeninit("", "||", (`""""', `"`""'"', "()"))
    tokenset(t, s)
    i = b = 0
    while ((tok = tokenget(t))!="") {
        if (tok=="||") {
            a = b + 1
            b = tokenoffset(t)
            tok = strtrim(substr(s, a, b-a-2))
            if (tok!="") {
                i++
                st_local("key_"+strofreal(i), tok)
            }
            continue
        }
    }
    a = b + 1
    tok = strtrim(substr(s, a, .))
    if (tok!="") {
        i++
        st_local("key_"+strofreal(i), tok)
    }
    st_local("key_n", strofreal(i))
}

end

