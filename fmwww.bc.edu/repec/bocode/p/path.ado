*! version 2.2.0 19nov2020 daniel klein
program path // , sclass
    // no version on purpose
    capture noisily pathutil `0'
    if (_rc == 199) {
        display as err _col(3) "{bf:path} has been superseded by " _continue
        display as err "{bf:pathutil}; for more information, see {help path}"
    }
    exit _rc
end
exit

/* ---------------------------------------
see pathutil.ado for version history
