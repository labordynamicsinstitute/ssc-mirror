*! V1 This is my clone of margins to be used with f_able only. 
*     The Purpose is to keep infor for epilog and prolog. And in case earlier versions are not "fixed" retroactivly.
program fmargins
        version 11
        if replay() {
                if inlist("margins", "`e(cmd)'", "`e(cmd2)'") {
                        _marg_report `0'
                        exit
                }
        }
        local vv : display "version " string(_caller()) ":"

        tempname m t
        `vv' .`m' = ._marg_work.new `t'

nobreak {
		local margins_epilog `e(margins_epilog)'
		local nldepvar `e(nldepvar)'
        if `"`e(margins_prolog)'"' != "" {
                `e(margins_prolog)'
        }

capture noisily break {

        `vv' .`m'.parse `0'
        .`m'.estimate_and_report

} // capture noisily break
        local rc = c(rc)

        if `"`margins_epilog'"' != "" {
                `margins_epilog' `nldepvar'
        }


} // nobreak
        exit `rc'
end
