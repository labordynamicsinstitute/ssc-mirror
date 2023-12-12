*! version 0.1.0 04feb2019
program define check PATH
	version 11
	
	capture shell "reg query HKCU\\Environment /v PATH"
	if _rc == 0) {
        local user_path_old : display shell "reg query HKCU\\Environment /v PATH"
		di "`user_path_old'"
        user_path_old <- strsplit(trimws(gsub("(PATH|REG_SZ)", "", user_path_raw)), ";")[[1]]
    } else {
        user_path_old <- character(0)
    }

    to_add <- to_add[!sapply(to_add, `%in%`, user_path_old)]

    paths_to_add <- paste0(c(user_path_old, to_add), collapse = ";")

    system(paste0('setx PATH "', paths_to_add, '"'))
    message("You need to restart RStudio so that the changes take effect.")
end


local path : environment PATH
di "`path'"
tokenize "`path'", parse(";")

local gzip_available = 0
local i = 1
while gzip_available == 0 {
	local 
	local i = `i' + 1
}
