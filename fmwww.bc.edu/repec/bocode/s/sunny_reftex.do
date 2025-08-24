cd "E:\益友学术\鼎园会计133期\data"
reftex using "cash_ch.txt", outfile("E:\益友学术\鼎园会计133期\report\bib_cn.tex")  replace lang(chn)
reftex using "cash_en.txt", outfile("E:\益友学术\鼎园会计133期\report\bib_en.tex") replace lang(eng)

* 处理混合文献
reftex using cash_mix.txt, outfile("E:\益友学术\鼎园会计133期\report\bib_mix.tex") lang(mix) replace
