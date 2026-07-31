*! googlechart_embedjs v0.1.1  2026-06-27
*! Inline-embed a JavaScript file as a <script>...</script> block in the
*! given HTML output.  Uses googlechart_appendfile to bypass Stata's
*! `file write' parser (so minified JS with embedded `"' sequences,
*! large lines, or unusual characters survive untouched).
*!
*! Forked from sparkta2_embedjs so the googlechart package has no
*! external dependency.  INTERNAL helper.

program define googlechart_embedjs
    version 17.0
    syntax , FH(name) PATH(string) OUTPATH(string)
    file write `fh' `"<script>"' _n
    googlechart_appendfile, fh(`fh') path("`path'") outpath(`"`outpath'"')
    file write `fh' _n `"</script>"' _n
end
