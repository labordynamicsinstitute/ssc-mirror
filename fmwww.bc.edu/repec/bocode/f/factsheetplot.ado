*! factsheetplot 0.1.0 24aug2026
*! Author: Samuel Sturm
*! Support: ssturm@jhu.edu
*! License: MIT

program define factsheetplot
    version 17

    syntax [using/] [, GRAPH(name) SET WIDTH(integer 1600) REPLACE]

    capture findfile scheme-factsheetplot.scheme
    if _rc {
        display as error "The factsheetplot graph scheme is not installed."
        display as error "Reinstall factsheetplot and try again."
        exit 601
    }

    if `width' <= 0 {
        display as error "width() must be a positive integer."
        exit 198
    }

    if "`set'" != "" {
        set scheme factsheetplot
        display as result "Factsheet graph style is active for this session."

        if `"`using'"' == "" & "`graph'" == "" {
            exit
        }
    }

    if "`graph'" == "" {
        capture graph display, scheme(factsheetplot) xsize(8) ysize(5)
    }
    else {
        capture graph display `graph', ///
            scheme(factsheetplot) xsize(8) ysize(5)
    }

    local display_rc = _rc
    if `display_rc' {
        if "`graph'" == "" {
            display as error "No current graph was found."
        }
        else {
            display as error "Graph `graph' was not found."
        }
        display as error "Create the graph first, then run factsheetplot."
        exit `display_rc'
    }

    display as result "Current graph converted to the factsheet style."

    if `"`using'"' != "" {
        local export_options "width(`width')"
        if "`replace'" != "" {
            local export_options "`export_options' replace"
        }

        graph export `"`using'"', `export_options'
        display as result `"Factsheet graph exported: `using'"'
    }
end
