spex nomocc2
quietly mprobit occ white ed exper, nolog
levelsof ed, local(edlevels)
foreach l of local edlevels {
    quietly estadd prvalue, x(ed=`l' white=0) label(`l')
}
estadd prvalue post NonWhite
foreach l of local edlevels {
    quietly estadd prvalue, x(ed=`l' white=1) label(`l')
}
estadd prvalue post White
esttab NonWhite White, b(4) nostar not ///
    keep(Menial:) mtitles eqlabels(none) noobs
eststo clear
