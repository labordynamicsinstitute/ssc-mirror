*! _asycaus_header v1.0.0  24may2026
*! Prints a boxed header. Internal helper for the asycaus suite.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _asycaus_header
    args title
    di as txt _n "{hline 78}"
    di as txt _col(2) "{bf:`title'}"
    di as txt "{hline 78}"
end
