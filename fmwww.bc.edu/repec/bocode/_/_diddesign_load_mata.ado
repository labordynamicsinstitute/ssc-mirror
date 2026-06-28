*! _diddesign_load_mata.ado
*! Wrapper: locates and loads the DIDdesign Mata library.
*! Called from test files to avoid bare 'do' at top level.

version 16.0

program define _diddesign_load_mata
    qui findfile diddesign_mata.do
    local matalib "`r(fn)'"
    // Resolve the directory containing the .mata source files
    local matadir = reverse(substr(reverse("`matalib'"), ///
        strpos(reverse("`matalib'"), "/") + 1, .))
    // Remove trailing /ado component if file was found in the ado directory;
    // the actual .mata source files live one level up in mata/.
    local mata_src "`matadir'/../mata"
    capture confirm file "`mata_src'/did_utils.mata"
    if _rc != 0 {
        // Fallback: same directory (package installed flat)
        local mata_src "`matadir'"
    }
    quietly do "`matalib'" "`mata_src'"
end
