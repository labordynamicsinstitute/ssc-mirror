*! _mixi01_mata 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! _mixi01_mata.ado — loader for the Mata computational library
*! Component .ado files probe Mata for __mixi01_loaded() and call
*! _mixi01_mata if it is undefined.  The library is then sourced once
*! per session into Mata's global workspace.

program define _mixi01_mata
    version 17.0
    quietly findfile _mixi01_mata.mata
    quietly do `"`r(fn)'"'
end
