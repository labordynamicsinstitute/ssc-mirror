/*!
_littext_example: load the bundled synthetic example corpus.

littext ships a single synthetic corpus, themed on the resource-based
view (RBV) of the firm:

  littext_example.dta        300 abstracts (1994-2025), 18 synthetic
                             journals, 17 RBV sub-territories

Syntax:
  littext example                  /* load the 300-abstract corpus       */
  littext example, clear           /* replace data in memory             */

The corpus is SYNTHETIC. It embeds known constructs and relationships
drawn from RBV terminology, but the abstracts are not real publications
and must not be cited as bibliometric data.
*/

program define _littext_example
    version 19.0
    syntax [, Clear]
    _littext_resolve, subdir(data) name("littext_example.dta")
    
    capture frame change default
    use `"`r(path)'"', `clear'
    di as txt "littext: loaded synthetic RBV corpus (300 abstracts; demonstration only)."
    di as txt "         Variables: article_id, year, journal, title, authors, method, sub_territory, abstract"
    di as txt "         Synthetic corpus; not for substantive citation. Analyze with, e.g.:"
    di as txt "           littext analyze, text(abstract) id(article_id) year(year) journal(journal)"
end
