*! version 2.1  Thursday, July 3, 2003 at 12:23   (SJ3-3: st0000)

program define misave
    version 7.0
    cap assert "$mimps"!=""&"$mi_sf"=="_mitemp"
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

/* Argument parsing*/
    /* get filename with quotes */
    gettoken filenm optn: 0, parse(",") quotes

    /* check to see if filename is enclosed in quotes, if it contains spaces - exit 198 if not */
    gettoken first rest: filenm, parse(`"" "')  quotes
    if `"`first'"' != `"`filenm'"' {
        local rest = trim(`"`rest'"')
        display as error "invalid '`rest''"
        exit 198
    }

    /* now strip quotes from filename and check to see if empty*/
    gettoken filenm optn: 0, parse(",")

    if `"`filenm'"'=="" | trim(`"`filenm'"')=="," {
        display as error "invalid file specification"
        exit 198
    }

    /* syntax for option*/
    if "`optn'"!="" {
            local 0  `optn'
            syntax [, REPLACE]
    }
/* End argument parsing*/

    forvalues i=1/$mimps{
            cap confirm f "_mitemp`i'.dta"
            if _rc {exit _rc}
    }

    nobreak {

          forvalues i=1/$mimps {
                local filename "`filenm'`i'.dta"
                qui use "$mi_sf`i'.dta", clear
                save `"`filename'"' `optn'
          }

          qui use `"`filenm'1.dta"', clear
    }
end


/*
   Syntax :
       misave <filename prefix> [,replace]

       All files have extension .dta.

   eg. miset using test
       mido egen x=fill(123)
       misave a:/dir/subdir/fileprefix
       miset using a:/dir/subdir/fileprefix
       mido sort id wave
       misave a:/dir/subdir/fileprefix, replace
*/
