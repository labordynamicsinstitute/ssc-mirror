*! _rals_print_header 1.0.1  16may2026  Dr Merwan Roudane
*! Shared header printer for the rals test commands.
program define _rals_print_header
    args testname ref varname T lag ic model
    di as text ""
    di as text "{c TLC}{hline 78}{c TRC}"
    di as text "{c |}  " as result "`testname'" as text "{col 79}{c |}"
    di as text "{c |}  Reference : `ref'{col 79}{c |}"
    di as text "{c |}  Variable  : " as result "`varname'" as text "{col 79}{c |}"
    di as text "{c |}  Sample    : T = `T'   Lag selected = `lag'   IC = `ic'{col 79}{c |}"
    di as text "{c |}  Det. term : " as result cond(`model'==1,"constant","constant + trend") as text "{col 79}{c |}"
    di as text "{c BLC}{hline 78}{c BRC}"
end
