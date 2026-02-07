*! mktex.ado version 3.0
*! Authors:Wu Lianghai and Chen Liwen, Wu Hanyan,Wu Xinzhuo,Ma Defang
*! Date:05Feb2026
*! Convert Microsoft Word documents to complete LaTeX documents
*! This program only supports compiling DOCX files that contain no tables or mathematical formulas. Otherwise, execute the following command:
*! English: shell pandoc test-mktex.docx -o test-mktex.tex --standalone
*! Chinese: shell pandoc digital-transformation.docx -o digital-transformation.tex --standalone --pdf-engine=xelatex ///
*!	 -V lang=chinese -V documentclass=ctexart -M mainfont="Microsoft YaHei"
*! Optional fonts, e.g.: "Microsoft YaHei"，"SimHei"，"SimSun"。

program define mktex, rclass
    version 18.0
    
    * Handle different usage patterns
    if `"`0'"' == "" | `"`0'"' == "," {
        di as error "Syntax: mktex using filename.docx [, options]"
        di as error "        mktex, check"
        exit 198
    }
    
    * Check if 'check' is standalone
    if regexm(`"`0'"', "^check$") | regexm(`"`0'"', "^, check$") {
        syntax [, CHECK]
        * Run check function
        mktex_check
        exit 0
    }
    
    * Normal usage with 'using' required
    syntax using/ [, REPLace COMPile Language(str) r c NOCTex NOTOC SIMple]
    
    * Check for single-letter options and map to full names
    if "`r'" != "" {
        local replace "replace"
    }
    
    if "`c'" != "" {
        local compile "compile"
    }
    
    * Store original filename
    local original_filename `"`using'"'
    
    di as text "{hline 70}"
    di as text "mktex - Version 3.0"
    di as text "Convert Word (.docx) to complete LaTeX document"
    di as text "Authors: Wu Lianghai, Chen Liwen, Wu Hanyan, Wu Xinzhuo, Ma Defang"
    di as text "{hline 70}"
    di as text "{bf:Important:} For documents with tables or mathematical formulas, use direct pandoc commands:"
    di as text "  English: {stata shell pandoc `original_filename' -o output.tex --standalone}"
    di as text "  Chinese: {stata shell pandoc `original_filename' -o output.tex --standalone --pdf-engine=xelatex -V lang=chinese -V documentclass=ctexart}"
    di as text "{hline 70}"
    di as text "Converting: `original_filename'"
    
    * Step 0: Handle file path and name issues
    local filename `original_filename'
    
    * Check if file exists
    cap confirm file `"`filename'"'
    if _rc {
        di as error "File not found: `original_filename'"
        exit 601
    }
    
    * Basic validation: file must be .docx
    if !regexm(`"`filename'"', "\.docx$") {
        di as error "File must be a .docx file"
        exit 198
    }
    
    * Handle Unicode filenames by creating temporary ASCII-named copy
    local temp_copy_created = 0
    local temp_copy_name ""
    
    * Check if filename contains non-ASCII characters
    local has_unicode = 0
    if ustrlen(`"`filename'"') != strlen(`"`filename'"') {
        local has_unicode = 1
    }
    else {
        * Also check for non-ASCII characters in another way
        local test_str = ustrto(`"`filename'"', "ascii", 1)
        if "`test_str'" == "" {
            local has_unicode = 1
        }
    }
    
    if `has_unicode' {
        di as text "Note: Filename contains Unicode characters, creating temporary copy..."
        
        * Create temporary ASCII-named copy
        tempfile ascii_copy
        local temp_copy_name = "`ascii_copy'.docx"
        
        * Copy file with proper quoting
        cap copy `"`filename'"' `"`temp_copy_name'"', replace
        if _rc {
            di as error "Failed to create temporary copy of Unicode-named file"
            di as error "Please rename your file to use only ASCII characters"
            exit 603
        }
        
        * Use the temporary copy for conversion
        local original_for_conversion = "`filename'"
        local filename = "`temp_copy_name'"
        local temp_copy_created = 1
        
        di as text "✓ Created temporary ASCII-named copy"
    }
    
    * Extract filename and path for output
    local basefile = subinstr(`"`original_filename'"', ".docx", "", .)
    * Clean basefile name (remove path)
    local basefile_only = "`basefile'"
    if regexm("`basefile'", "[/\\]") {
        * Extract filename only (without path)
        if c(os) == "Windows" {
            local basefile_only = regexr("`basefile'", ".*[\\/]", "")
        }
        else {
            local basefile_only = regexr("`basefile'", ".*/", "")
        }
    }
    
    local texfile = "`basefile_only'.tex"
    local pdffile = "`basefile_only'.pdf"
    
    di as text "Output LaTeX file: `texfile'"
    
    * Check output file existence if replace option not specified
    if "`replace'" == "" {
        cap confirm file "`texfile'"
        if !_rc {
            di as error "File exists: `texfile'"
            di as text "Use the 'replace' option to overwrite"
            exit 602
        }
    }
    
    * Step 1: Convert to LaTeX using pandoc
    di as text "{hline 40}"
    di as text "Step 1: Converting with pandoc..."
    
    * Create temporary file for pandoc output
    local tempfile = "`basefile_only'_temp.tex"
    
    * Determine pandoc command based on OS and global variable
    local pandoc_cmd "pandoc"
    
    * Check if we're on MacOSX and if global pandoc is defined
    if c(os) == "MacOSX" & `"$pandoc"' != "" {
        local pandoc_cmd `"$pandoc"'
        di as text "Using pandoc from global path: `pandoc_cmd'"
    }
    else if c(os) == "MacOSX" {
        di as text "Note: For MacOSX, you can set pandoc path in profile.do:"
        di as text "     glo pandoc /path/to/pandoc"
        di as text "Using system pandoc command..."
    }
    
    * Use pandoc with proper command format - FIXED
    di as text "Running pandoc conversion..."
    
    * Clean paths for shell command
    local clean_filename = subinstr(`"`filename'"', `"""', "", .)
    local clean_tempfile = subinstr(`"`tempfile'"', `"""', "", .)
    
    if c(os) == "Windows" {
        * Windows: use direct shell command with quotes
        local win_filename = subinstr(`"`clean_filename'"', "/", "\", .)
        local win_tempfile = subinstr(`"`clean_tempfile'"', "/", "\", .)
        
        * FIXED: Use simpler display command
        di as text "Command: pandoc `win_filename' -f docx -t latex -o `win_tempfile'"
        shell pandoc "`win_filename'" -f docx -t latex -o "`win_tempfile'"
    }
    else {
        * Unix/Mac: use single quotes
        di as text "Command: pandoc '`clean_filename'' -f docx -t latex -o '`clean_tempfile''"
        shell `pandoc_cmd' '`clean_filename'' -f docx -t latex -o '`clean_tempfile''
    }
    
    local pandoc_rc = _rc
    
    * Check if conversion was successful
    cap confirm file "`tempfile'"
    if _rc {
        di as error "Pandoc conversion failed"
        di as text "Return code: `pandoc_rc'"
        
        * Check if pandoc is installed
        cap qui which pandoc
        if _rc {
            di as error "pandoc is not found in PATH"
            di as text "Please install pandoc from: https://pandoc.org/installing.html"
        }
        else {
            di as text "pandoc is installed but failed to convert the file"
            di as text "File: `filename'"
            di as text "Tried to create: `tempfile'"
        }
        
        * Clean up temporary file if created
        if `temp_copy_created' {
            cap erase `"`temp_copy_name'"'
        }
        
        exit 603
    }
    
    di as text "✓ Pandoc conversion completed"
    
    * Clean up temporary copy if created
    if `temp_copy_created' {
        cap erase `"`temp_copy_name'"'
        di as text "✓ Cleaned up temporary file"
    }
    
    * Step 2: Process temporary file
    di as text "{hline 40}"
    di as text "Step 2: Processing LaTeX content..."
    
    * Create a cleaned temporary file
    local cleaned_tempfile = "`basefile_only'_cleaned.tex"
    tempname fh_in fh_clean
    
    cap file open `fh_in' using `"`tempfile'"', read text
    if _rc {
        di as error "Cannot read temporary file"
        exit 605
    }
    
    cap file open `fh_clean' using `"`cleaned_tempfile'"', write text replace
    if _rc {
        di as error "Cannot create cleaned temporary file"
        exit 606
    }
    
    * Process the file
    local skipped_toc = 0
    local line_count = 0
    local ul_removed = 0
    
    file read `fh_in' line
    while r(eof) == 0 {
        local line_count = `line_count' + 1
        
        * Clean the line - remove problematic characters
        local clean_line = subinstr(`"`macval(line)'"', "`", "'", .)
        local clean_line = subinstr(`"`clean_line'"', "\'", "'", .)
        
        * Remove problematic \begin{document} and \end{document} from pandoc output
        if regexm(`"`clean_line'"', "^\\begin{document}") | regexm(`"`clean_line'"', "^\\end{document}") {
            * Skip these lines
        }
        * Detect and skip table of contents in the content
        else if regexm(`"`clean_line'"', "\\tableofcontents") | regexm(`"`clean_line'"', "\\contentsline") {
            local skipped_toc = `skipped_toc' + 1
        }
        * Detect and skip lists of figures/tables
        else if regexm(`"`clean_line'"', "\\listoffigures") | regexm(`"`clean_line'"', "\\listoftables") {
            local skipped_toc = `skipped_toc' + 1
        }
        * Write all other lines
        else {
            * Simple cleanup: remove \ul{} and \underline{} commands to prevent compilation errors
            if strpos(`"`clean_line'"', "\ul{") > 0 | strpos(`"`clean_line'"', "\underline{") > 0 {
                local clean_line = subinstr(`"`clean_line'"', "\ul{", "", .)
                local clean_line = subinstr(`"`clean_line'"', "\underline{", "", .)
                local clean_line = subinstr(`"`clean_line'"', "}", "", .)  * Remove closing braces
                local ul_removed = `ul_removed' + 1
            }
            
            file write `fh_clean' `"`clean_line'"' _n
        }
        
        file read `fh_in' line
    }
    
    file close `fh_in'
    file close `fh_clean'
    
    if `skipped_toc' > 0 {
        di as text "✓ Removed `skipped_toc' duplicate TOC/list elements"
    }
    
    if `ul_removed' > 0 {
        di as text "Note: Removed `ul_removed' underline commands to prevent compilation errors"
        di as text "      Underline formatting is lost. For underline support, use direct pandoc conversion"
    }
    
    * Step 3: Create final LaTeX document
    di as text "{hline 40}"
    di as text "Step 3: Creating final LaTeX document..."
    
    * Determine document class and language settings
    local doc_class = "article"
    local use_ctex = 0
    local encoding = "utf8"
    
    if "`language'" != "" {
        local lang_lower = lower("`language'")
        if regexm("`lang_lower'", "chinese|zh|cn") & "`nctex'" == "" {
            local use_ctex = 1
            local encoding = "UTF8"
        }
    } 
    else if "`nctex'" == "" {
        * Default to Chinese unless explicitly disabled
        local use_ctex = 1
        local encoding = "UTF8"
        local language = "chinese"
    }
    
    * Create final LaTeX file
    tempname fh_out fh_content
    cap file open `fh_out' using "`texfile'", write text replace
    if _rc {
        di as error "Cannot create output LaTeX file"
        exit 604
    }
    
    * Simple or full LaTeX document
    if "`simple'" != "" {
        * Simple LaTeX document - just the content with minimal preamble
        di as text "Creating simple LaTeX document..."
        
        * Add minimal LaTeX header for simple mode
        file write `fh_out' "% Simple LaTeX document generated by mktex" _n
        file write `fh_out' "% Use this for embedding in existing documents" _n
        file write `fh_out' "% or when having compilation issues" _n _n
        
        file write `fh_out' "\documentclass{article}" _n
        file write `fh_out' "\usepackage[utf8]{inputenc}" _n
        file write `fh_out' "\usepackage[T1]{fontenc}" _n _n
        
        if `use_ctex' == 1 {
            file write `fh_out' "\usepackage[UTF8]{ctex}" _n _n
        }
        
        file write `fh_out' "\begin{document}" _n _n
        
        * Copy content from cleaned temporary file
        cap file open `fh_content' using "`cleaned_tempfile'", read text
        if !_rc {
            local linenum = 0
            file read `fh_content' line
            while r(eof) == 0 {
                local linenum = `linenum' + 1
                * Clean the line
                local clean_line = subinstr(`"`macval(line)'"', "`", "'", .)
                local clean_line = subinstr(`"`clean_line'"', "\'", "'", .)
                file write `fh_out' `"`clean_line'"' _n
                file read `fh_content' line
            }
            file close `fh_content'
            di as text "✓ Copied `linenum' lines"
        }
        
        file write `fh_out' _n "\end{document}" _n
        file close `fh_out'
        di as text "✓ Simple LaTeX document created: `texfile'"
        
        * Save line count for return
        return scalar lines = `linenum'
    }
    else {
        * Full LaTeX document with complete structure
        
        * Write LaTeX document header
        file write `fh_out' "% Generated by mktex for Stata" _n
        file write `fh_out' "% Authors: Wu Lianghai, Chen Liwen, Wu Hanyan, Wu Xinzhuo, Ma Defang" _n
        file write `fh_out' "% Date: 05Feb2026" _n _n
        
        * Document class and encoding
        file write `fh_out' "\documentclass[12pt,a4paper]{`doc_class'}" _n
        file write `fh_out' "\usepackage[utf8]{inputenc}" _n
        file write `fh_out' "\usepackage[T1]{fontenc}" _n
        
        * Add ctex package for Chinese if needed and not disabled
        if `use_ctex' == 1 {
            file write `fh_out' "\usepackage[UTF8]{ctex}" _n _n
        }
        else {
            file write `fh_out' _n
        }
        
        * Essential packages
        file write `fh_out' "\usepackage{geometry}" _n
        file write `fh_out' "\geometry{a4paper,margin=2.5cm}" _n
        file write `fh_out' "\usepackage{hyperref}" _n
        file write `fh_out' "\usepackage{graphicx}" _n
        file write `fh_out' "\usepackage{amsmath}" _n
        file write `fh_out' "\usepackage{booktabs}" _n _n
        
        * Hyperref configuration
        file write `fh_out' "\hypersetup{" _n
        file write `fh_out' "    colorlinks=true," _n
        file write `fh_out' "    linkcolor=blue," _n
        file write `fh_out' "    citecolor=blue," _n
        file write `fh_out' "    urlcolor=blue," _n
        file write `fh_out' "    pdftitle={`original_filename'}," _n
        file write `fh_out' "    pdfauthor={mktex}" _n
        file write `fh_out' "}" _n _n
        
        * Title information
        local title = subinstr("`basefile_only'", "_", " ", .)
        local title = ustrtitle("`title'")
        
        file write `fh_out' "\title{`title'}" _n
        file write `fh_out' "\author{Converted from: `original_filename'}" _n
        file write `fh_out' "\date{\today}" _n _n
        
        * Begin document
        file write `fh_out' "\begin{document}" _n
        file write `fh_out' "\maketitle" _n
        
        * Add TOC only if not disabled
        if "`notoc'" == "" {
            file write `fh_out' "\tableofcontents" _n
            file write `fh_out' "\newpage" _n _n
        }
        
        * Step 4: Copy processed content from cleaned temporary file
        di as text "Step 4: Copying processed content..."
        
        cap file open `fh_content' using "`cleaned_tempfile'", read text
        if _rc {
            di as error "Cannot read cleaned temporary file"
            file close `fh_out'
            exit 607
        }
        
        local linenum = 0
        local charcount = 0
        
        * Read and copy content line by line
        file read `fh_content' line
        while r(eof) == 0 {
            local linenum = `linenum' + 1
            local charcount = `charcount' + length(`"`macval(line)'"')
            
            * Clean and write the line
            local clean_line = subinstr(`"`macval(line)'"', "`", "'", .)
            local clean_line = subinstr(`"`clean_line'"', "\'", "'", .)
            file write `fh_out' `"`clean_line'"' _n
            
            * Display progress every 200 lines
            if mod(`linenum', 200) == 0 {
                di as text "  Copied `linenum' lines..."
            }
            
            file read `fh_content' line
        }
        
        file close `fh_content'
        
        * End document
        file write `fh_out' _n "\end{document}" _n
        file close `fh_out'
        
        di as text "✓ Copied `linenum' lines, `charcount' characters"
        return scalar lines = `linenum'
        return scalar charcount = `charcount'
    }
    
    * Clean up temporary files
    cap erase "`tempfile'"
    cap erase "`cleaned_tempfile'"
    
    * Step 5: Post-processing and results display
    di as text "{hline 40}"
    
    * Verify final file was created
    cap confirm file "`texfile'"
    if _rc {
        di as error "Output LaTeX file not created!"
        exit 608
    }
    
    * Get file size information
    tempname fh_size
    cap file open `fh_size' using "`texfile'", read binary
    if !_rc {
        file seek `fh_size' eof
        local filesize = r(loc)
        file close `fh_size'
        di as text "✓ File size: `filesize' bytes"
        return scalar filesize = `filesize'
    }
    
    di as text "✓ LaTeX document created: `texfile'"
    if "`simple'" == "" & "`notoc'" == "" {
        di as text "✓ Table of contents included"
    }
    
    * Step 6: Compile to PDF if requested
    if "`compile'" != "" {
        di as text "{hline 40}"
        di as text "Step 5: Compiling to PDF..."
        
        * Check LaTeX installation
        mktex_check_latex
        if !`r(latex_available)' {
            di as error "No LaTeX engine found!"
            di as text "Please install LaTeX first (run: mktex, check for details)"
            di as text "Then try again with: mktex using ..., compile"
        }
        else {
            * Get available LaTeX engine
            local latex_engine `"`r(latex_engine)'"'
            di as text "Using LaTeX engine: `latex_engine'"
            
            * First compilation
            di as text "  First pass..."
            shell `latex_engine' -interaction=nonstopmode "`texfile'"
            
            * Check compilation result
            cap confirm file "`basefile_only'.aux"
            local compilation_ok = !_rc
            
            if `compilation_ok' {
                * Second compilation only if TOC is enabled
                if "`simple'" == "" & "`notoc'" == "" {
                    di as text "  Second pass (for TOC)..."
                    shell `latex_engine' -interaction=nonstopmode "`texfile'"
                }
                
                * Check if PDF was created
                cap confirm file "`pdffile'"
                if !_rc {
                    di as text "✓ PDF created: `pdffile'"
                    
                    * Clean up auxiliary files
                    local aux_extensions "aux log toc out lot lof"
                    foreach ext in `aux_extensions' {
                        cap erase "`basefile_only'.`ext'"
                    }
                }
                else {
                    di as text "Note: PDF file was not created"
                    di as text "Check `basefile_only'.log for error details"
                }
            }
            else {
                di as error "PDF compilation failed!"
                di as text "{hline 40}"
                di as text "Common reasons and solutions:"
                di as text ""
                di as text "1. Check the LaTeX log file for details:"
                di as text "   - Open `basefile_only'.log in a text editor"
                di as text "   - Look for error messages starting with '!'"
                di as text ""
                di as text "2. Common issues with Word to LaTeX conversion:"
                di as text "   - Complex tables may not convert correctly"
                di as text "   - Mathematical formulas may need manual adjustment"
                di as text "   - Special characters may cause compilation errors"
                di as text ""
                di as text "3. Recommended solutions:"
                di as text "   a) Simplify the Word document:"
                di as text "      - Remove complex formatting"
                di as text "      - Convert tables to plain text"
                di as text "      - Remove mathematical formulas"
                di as text ""
                di as text "   b) Use pandoc directly for better control:"
                if `use_ctex' == 0 {
                    di as text "      shell pandoc `original_filename' -o `texfile' --standalone"
                }
                else {
                    di as text "      shell pandoc `original_filename' -o `texfile' --standalone"
                    di as text "          --pdf-engine=xelatex -V lang=chinese"
                    di as text "          -V documentclass=ctexart"
                }
                di as text ""
                di as text "   c) Manual editing of the LaTeX file:"
                di as text "      - Open `texfile' in a LaTeX editor"
                di as text "      - Fix any LaTeX errors reported in the log"
                di as text "      - Recompile manually"
                di as text "{hline 40}"
                
                * Return error flag
                return scalar compilation_failed = 1
            }
        }
        
        di as text "{hline 40}"
    }
    
    * Final summary
    di as text "{hline 70}"
    di as text "✓ Conversion completed successfully!"
    di as text "Output LaTeX file: `texfile'"
    
    if "`simple'" != "" {
        di as text "Mode: Simple LaTeX (no document structure)"
    }
    else if "`notoc'" != "" {
        di as text "Mode: Full document (TOC disabled)"
    }
    else {
        di as text "Mode: Full document with table of contents"
    }
    
    if `ul_removed' > 0 {
        di as text "Note: Underline formatting removed for compatibility"
    }
    
    if "`compile'" != "" {
        cap confirm file "`pdffile'"
        if !_rc {
            di as text "Output PDF file: `pdffile'"
            return local pdffile "`pdffile'"
            return scalar compilation_success = 1
        }
        else {
            return scalar compilation_success = 0
        }
    }
    
    di as text "{hline 70}"
    
    * Return results
    return local texfile "`texfile'"
    return local original_file "`original_filename'"
    return scalar ul_removed = `ul_removed'
    return scalar success = 1
end

* Helper function to check LaTeX installation
program define mktex_check_latex, rclass
    version 18.0
    
    * Check for LaTeX engines
    local latex_available = 0
    local latex_engine ""
    
    * Try different ways to find LaTeX on Windows
    foreach engine in "pdflatex" "xelatex" "lualatex" "latex" {
        * Method 1: Try which command
        cap qui which `engine'
        if !_rc {
            local latex_available = 1
            local latex_engine "`engine'"
            continue, break
        }
        
        * Method 2: Try shell command (Windows)
        if c(os) == "Windows" {
            tempfile test_file
            cap qui shell `engine' --version > "`test_file'" 2>&1
            if !_rc {
                local latex_available = 1
                local latex_engine "`engine'"
                cap erase "`test_file'"
                continue, break
            }
            cap erase "`test_file'"
        }
    }
    
    return scalar latex_available = `latex_available'
    return local latex_engine = "`latex_engine'"
end

* Main check function
program define mktex_check
    version 18.0
    
    di as text "{hline 70}"
    di as text "Checking LaTeX and pandoc installation..."
    di as text "mktex - Version 3.0"
    di as text "{hline 40}"
    
    * Check pandoc
    di as text "Checking pandoc..."
    
    * Try multiple methods to find pandoc
    local pandoc_found = 0
    local pandoc_version = ""
    
    * Method 1: Try which
    cap qui which pandoc
    if !_rc {
        local pandoc_found = 1
    }
    
    * Method 2: Try shell command
    if !`pandoc_found' {
        tempfile pandoc_test
        cap qui shell pandoc --version > "`pandoc_test'" 2>&1
        if !_rc {
            local pandoc_found = 1
        }
        cap erase "`pandoc_test'"
    }
    
    if `pandoc_found' {
        di as text "✓ pandoc is installed"
        
        * Get version
        tempfile pandoc_ver
        qui shell pandoc --version > "`pandoc_ver'" 2>&1
        cap file open fh using "`pandoc_ver'", read text
        if !_rc {
            file read fh ver_line
            if `"`ver_line'"' != "" {
                di as text "  Version: `ver_line'"
            }
            file close fh
        }
        cap erase "`pandoc_ver'"
    }
    else {
        di as error "✗ pandoc not found!"
        di as text "  Install from: https://pandoc.org/installing.html"
    }
    
    di as text "{hline 40}"
    
    * Check LaTeX
    di as text "Checking LaTeX..."
    
    mktex_check_latex
    local latex_available = `r(latex_available)'
    local latex_engine = `"`r(latex_engine)'"'
    
    if `latex_available' {
        di as text "✓ LaTeX is installed"
        di as text "  Engine: `latex_engine'"
        
        * Get version
        tempfile latex_ver
        qui shell `latex_engine' --version > "`latex_ver'" 2>&1
        cap file open fh using "`latex_ver'", read text
        if !_rc {
            file read fh ver_line
            if `"`ver_line'"' != "" {
                di as text "  Version: `ver_line'"
            }
            file close fh
        }
        cap erase "`latex_ver'"
    }
    else {
        di as error "✗ LaTeX not found!"
        di as text "  Please install a LaTeX distribution:"
        di as text "    - Windows: MiKTeX (https://miktex.org/)" 
        di as text "    - macOS: MacTeX (https://tug.org/mactex/)"
        di as text "    - Linux: TeX Live (https://tug.org/texlive/)"
        di as text "  After installation, restart Stata and run: mktex, check"
    }
    
    di as text "{hline 40}"
    
    * System information
    di as text "System information:"
    di as text "  OS: `c(os)' `c(osdtl)'"
    di as text "  Stata version: `c(version)'"
    di as text "  Current directory: `c(pwd)'"
    
    di as text "{hline 40}"
    di as text "Summary:"
    
    if `pandoc_found' & `latex_available' {
        di as text "✓ Both pandoc and LaTeX are installed"
        di as text "  You can use all features of mktex"
        di as text "  Example: mktex using document.docx, compile"
    }
    else if `pandoc_found' & !`latex_available' {
        di as text "✓ pandoc is installed"
        di as text "✗ LaTeX is missing - PDF compilation will not work"
        di as text "  You can still convert to LaTeX: mktex using document.docx"
    }
    else if !`pandoc_found' & `latex_available' {
        di as text "✗ pandoc is missing - conversion will not work"
        di as text "✓ LaTeX is installed"
        di as text "  Install pandoc first: https://pandoc.org/installing.html"
    }
    else {
        di as error "✗ Both pandoc and LaTeX are missing"
        di as text "  Please install both to use mktex"
    }
    
    di as text "{hline 70}"
    
    * Display help message for MacOSX users if global not set
    if c(os) == "MacOSX" & `"$pandoc"' == "" {
        di as text _n "Note for MacOSX users:"
        di as text "To ensure pandoc works correctly, add this line to your profile.do:"
        di as text "    glo pandoc /path/to/pandoc"
        di as text "Common locations:"
        di as text "    /opt/homebrew/bin/pandoc  (Homebrew)"
        di as text "    /usr/local/bin/pandoc     (MacPorts)"
        di as text "    /Applications/pandoc/bin/pandoc (Direct install)"
    }
    
    * Add important usage notes
    di as text _n "{bf:Important Usage Notes:}"
    di as text "1. mktex is optimized for plain text Word documents"
    di as text "2. For documents with tables or mathematical formulas, use pandoc directly:"
    di as text "   - English: shell pandoc file.docx -o file.tex --standalone"
    di as text "   - Chinese: shell pandoc file.docx -o file.tex --standalone"
    di as text "               --pdf-engine=xelatex -V lang=chinese"
    di as text "               -V documentclass=ctexart"
    di as text "3. Complex formatting may be simplified or removed"
    di as text "4. Check the .log file if compilation fails"
end