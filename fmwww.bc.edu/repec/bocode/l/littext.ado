/*
    littext -- automated construct discovery and relationship inference from academic text
    Copyright (C) 2026  Nebojsa S. Davcik

    This program is free software: it can be redistributed and/or modified
    under the terms of the GNU General Public License as published by the Free
    Software Foundation, either version 3 of the License, or (at your option)
    any later version. See the LICENSE file or <https://www.gnu.org/licenses/>.

    littext extracts candidate construct relationships from corpora of academic
    text (titles, abstracts, full texts). It combines sentence-transformer
    embeddings, dependency parsing, and co-occurrence statistics to generate a
    register of candidate relationships of the form "X is associated with Y",
    "X moderates Z on Y", etc. See CHANGELOG.md for the full release history.
*/

*! version 1.0  17june2026  littext: automated construct discovery from academic text
*! Author: Nebojsa S. Davcik
*! License: GPL-3.0-or-later

program define littext, eclass
    version 19.0
    gettoken subcmd 0 : 0, parse(" ,")
    if `"`subcmd'"' == "" {
        di as err "littext: no subcommand specified"
        di as txt ""
        di as txt "Subcommands:"
        di as txt "  {bf:littext analyze}   run the construct/relationship pipeline on a corpus"
        di as txt "  {bf:littext graph}     produce a figure from the most recent analysis"
        di as txt "  {bf:littext export}    write the candidate relationships as a hypothesis register"
        di as txt "  {bf:littext example}   load the bundled synthetic corpus"
        di as txt "  {bf:littext install}   verify the Python environment"
        di as txt ""
        di as txt "See {bf:help littext} for details."
        exit 198
    }
    if "`subcmd'" == "analyze" {
        _littext_analyze `0'
    }
    else if "`subcmd'" == "graph" {
        _littext_graph `0'
    }
    else if "`subcmd'" == "export" {
        _littext_export `0'
    }
    else if "`subcmd'" == "example" {
        _littext_example `0'
    }
    else if "`subcmd'" == "install" {
        _littext_install `0'
    }
    else {
        di as err "littext: unknown subcommand '`subcmd''"
        di as txt "Valid subcommands: analyze, graph, export, example, install"
        exit 198
    }
end
