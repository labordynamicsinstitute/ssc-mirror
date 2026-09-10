*! _emlink_split.ado  version 1.0.15
*! Internal subroutine for emlink: split "lhs=rhs" (or a bare
*! "name") into s(lhs) and s(rhs). Loaded automatically by emlink;
*! not intended to be called directly.
*! The : piece extended function splits by WIDTH, not by a
*! separator, so it cannot be used here.

program define _emlink_split, sclass
    version 17.0
    args spec
    sreturn clear
    local pos = strpos("`spec'", "=")
    if `pos' == 0 {
        sreturn local lhs = strtrim("`spec'")
        sreturn local rhs = strtrim("`spec'")
    }
    else {
        sreturn local lhs = strtrim(substr("`spec'", 1, `pos'-1))
        sreturn local rhs = strtrim(substr("`spec'", `pos'+1, .))
    }
end
