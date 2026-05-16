*! _rals_print_two_row 1.0.0  13may2026  Dr Merwan Roudane
*! Shared 2-row test-result table for the rals package.
*!   row 1 = stage-1 test (no rho^2)
*!   row 2 = stage-2 RALS test (with rho^2)
*! All numeric columns use a fixed _col() layout so headers and values line up.
*------------------------------------------------------------------------------
program define _rals_print_two_row
    args r1 r2 stat1 stat2 rho2 cv1_1 cv1_5 cv1_10 cv2_1 cv2_5 cv2_10
    di as text ""
    di as text "{hline 80}"
    di as text   _col(3) "Test"                                               ///
                 _col(31) "Statistic"                                         ///
                 _col(45) "rho^2"                                             ///
                 _col(58) "1%"                                                ///
                 _col(68) "5%"                                                ///
                 _col(78) "10%"
    di as text "{hline 80}"
    di as text   _col(3) "`r1'"                                               ///
       as result _col(29) %11.4f `stat1'                                      ///
       as text   _col(48) "."                                                 ///
       as result _col(50) %9.3f `cv1_1'                                       ///
                 _col(60) %9.3f `cv1_5'                                       ///
                 _col(70) %9.3f `cv1_10'
    di as text   _col(3) "`r2'"                                               ///
       as result _col(29) %11.4f `stat2'                                      ///
                 _col(40) %10.4f `rho2'                                       ///
                 _col(50) %9.3f `cv2_1'                                       ///
                 _col(60) %9.3f `cv2_5'                                       ///
                 _col(70) %9.3f `cv2_10'
    di as text "{hline 80}"
end
