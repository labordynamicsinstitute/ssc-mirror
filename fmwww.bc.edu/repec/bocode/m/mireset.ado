*! version 1.1   Thursday, July 3, 2003 at 12:23      (SJ3-3: st0000)
* mireset erases the temporary datasets, mitemp1.dta, ..., _mitemp$nim.dta, created by miset
* (if they exist in the current working directory), as well as clearing the global macros created by miset.

program define mireset
version 7.0

    if "$mimps"~="" {  /* erase temporary datasets created by miset */
        cap for num 1/$mimps : erase _mitempX.dta
    }
    global mi_uf        /* erase all global macros created by miset */
    global mi_sf
    global mimps
    global mi_combine1
    global mi_combine2
    global mi_combine3
    global mi_mifit_combine
    global mi_mifit_nameb
    global mi_mifit_nameVc
    global mi_mifit_nameVr
    global mi_lincom_formula

    exit

end
