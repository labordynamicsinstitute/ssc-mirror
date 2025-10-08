* Query references from Google Scholar in BibTeX format:
cd "D:\益友学术\鼎园会计 202503\报告"
getref artificial intelligence, saving("ai_refs.bib") format(bib) replace language(english) source(google)

* Query references from CNKI in BibTeX format:
getref 人工智能 会计, saving("ai_accounting.bib") format(bib) replace language(chinese) source(cnki) apikey("your_cnki_api_key")

* Query references from CNKI in LaTeX format:
getref 数字化转型, saving("digital_refs.tex") format(tex) replace source(cnki) apikey("your_cnki_api_key")

* Query references from Google Scholar in text format:
getref corporate governance, saving("governance.txt") format(txt) replace language(english) source(google)

