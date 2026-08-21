*! riskcalplot version 1.0.1 03aug2026
*! Suppachai Lawanaskol, MD
*! Jayanton Patumanond, MD, MPH, MSc, DSc

program define riskcalplot, rclass
    version 16.0

    syntax varlist(min=2 max=6 numeric) [if] [in], ///
        MODEL(string asis)                         ///
        [                                          ///
            MARKER(string)                         ///
            NOCI                                   ///
            LEVEL(cilevel)                         ///
            NOSTAT                                 ///
            STATOPTS(string asis)                  ///
            PLOT1OPTS(string asis)                 ///
            PLOT2OPTS(string asis)                 ///
            PLOT3OPTS(string asis)                 ///
            PLOT4OPTS(string asis)                 ///
            PLOT5OPTS(string asis)                 ///
            CI1OPTS(string asis)                   ///
            CI2OPTS(string asis)                   ///
            CI3OPTS(string asis)                   ///
            CI4OPTS(string asis)                   ///
            CI5OPTS(string asis)                   ///
            SCATTER1OPTS(string asis)              ///
            SCATTER2OPTS(string asis)              ///
            SCATTER3OPTS(string asis)              ///
            SCATTER4OPTS(string asis)              ///
            SCATTER5OPTS(string asis)              ///
            *                                      ///
        ]

    marksample touse

    **Set the default markers**
    local defaultmarkers Oh Dh Th Sh X

    **Identify the endpoint and scores**
    gettoken y scores : varlist

    local nscore : word count `scores'

    **Identify the model list**
    local models = lower(strtrim(`"`model'"'))

    local nmodel : word count `models'

    **Use the same model for all scores if only one model was specified**
    if `nmodel' == 1 {

        local onemodel : word 1 of `models'
        local models

        forvalues j = 1/`nscore' {
            local models `models' `onemodel'
        }
    }
    else if `nmodel' != `nscore' {

        display as error ///
            "The number of models must be one or equal to the number of scores"

        display as error ///
            "Number of scores: `nscore'"

        display as error ///
            "Number of models: `nmodel'"

        exit 198
    }

    **Check the binary endpoint**
    quietly count if `touse' & !inlist(`y', 0, 1)

    if r(N) > 0 {

        display as error ///
            "The endpoint `y' must be coded 0 and 1"

        exit 459
    }

    **Check the analysis sample**
    quietly summarize `y' if `touse', meanonly

    if r(N) == 0 {

        display as error ///
            "No observations are available for analysis"

        exit 2000
    }

    **Check the variation of the endpoint**
    if r(min) == r(max) {

        display as error ///
            "The endpoint must contain both 0 and 1"

        exit 2000
    }

    display as text ///
        _column(5) "Endpoint" ///
        _column(20) "`y'"

    display as text ///
        _column(5) "Scores" ///
        _column(20) "`scores'"

    display as text ///
        _column(5) "Models" ///
        _column(20) "`models'"

    **Create the statistics matrix**
    tempname statistics

    matrix `statistics' = J(`nscore', 6, .)

	matrix colnames `statistics' = E_O CITL Cal_slope Adj_R2 RMSE AUROC

    local rownames
    local plots
    local legorder
    local i = 0

    foreach score of local scores {

        local ++i

        **Call the default marker for each score**
        local markeri : word `i' of `defaultmarkers'

        **Use one marker for all scores if marker() was specified**
        if `"`marker'"' != "" {
            local markeri `"`marker'"'
        }

        **Call the model for each score**
        local modeli : word `i' of `models'

        **Check the model type**
        if !inlist("`modeli'", "logit", "log") {

            display as error ///
                "Invalid model for score `score': `modeli'"

            display as error ///
                "The available models are logit and log"

            exit 198
        }

        display as text ///
            _newline "Score `i': `score'"

        display as text ///
            "Model `i': `modeli'"

        local rownames `rownames' `score'

        **Create temporary variables**
        tempvar pred obsrisk size tag scoregroup cil ciu
		tempvar group_sqerror weighted_sqerror pclip linear_predictor

        **Generate the observed risk by score**
        quietly egen double `obsrisk' = ///
            mean(`y') if `touse', ///
            by(`score')

        **Generate the number of observations by score**
        quietly egen long `size' = ///
            count(`y') if `touse', ///
            by(`score')

        **Select one observation from each score value**
        quietly egen byte `tag' = ///
            tag(`score') if `touse'

        **Calculate the exact binomial confidence interval**
        if "`noci'" == "" {

            **Identify each score value**
            quietly egen long `scoregroup' = ///
                group(`score') if `touse'

            **Generate variables for the confidence limits**
            quietly generate double `cil' = .
            quietly generate double `ciu' = .

            **Identify the number of score values**
            quietly summarize `scoregroup' if `touse', meanonly
            local ngroup = r(max)

            forvalues g = 1/`ngroup' {

                **Count the observations at each score value**
                quietly count ///
                    if `touse' & `scoregroup' == `g'

                local n = r(N)

                **Count the events at each score value**
                quietly count ///
                    if `touse' & ///
                    `scoregroup' == `g' & ///
                    `y' == 1

                local event = r(N)

                **Calculate the Clopper-Pearson exact confidence interval**
                quietly cii proportions ///
                    `n' `event', ///
                    exact ///
                    level(`level')

                **Store the confidence limits**
                quietly replace `cil' = r(lb) ///
                    if `touse' & `scoregroup' == `g'

                quietly replace `ciu' = r(ub) ///
                    if `touse' & `scoregroup' == `g'
            }
        }

        **Fit the logistic model**
        if "`modeli'" == "logit" {

            capture quietly logistic ///
                `y' c.`score' if `touse'

            local modelrc = _rc

            if `modelrc' {

                display as error ///
                    "Logistic regression failed for score `score'"

                exit `modelrc'
            }

            quietly predict double `pred' ///
                if e(sample), pr
        }

        **Fit the modified Poisson model**
        if "`modeli'" == "log" {

            capture quietly glm ///
                `y' c.`score' if `touse', ///
                family(poisson) ///
                link(log) ///
                vce(robust)

            local modelrc = _rc

            if `modelrc' {

                display as error ///
                    "The modified Poisson model failed for score `score'"

                exit `modelrc'
            }

            quietly predict double `pred' ///
                if e(sample), mu

            **Confine the predicted risk between zero and one**
            quietly replace `pred' = 1 ///
                if `pred' > 1 & !missing(`pred')

            quietly replace `pred' = 0 ///
                if `pred' < 0 & !missing(`pred')
        }

        **Calculate the expected number of events**
        quietly summarize `pred' ///
            if `touse' & !missing(`pred'), ///
            meanonly

        local expected = r(sum)

        **Calculate the observed number of events**
        quietly summarize `y' ///
            if `touse' & !missing(`pred'), ///
            meanonly

        local observed = r(sum)
        local prevalence = r(mean)

        **Calculate the expected-to-observed ratio**
        local eo = .

        if `observed' > 0 {
            local eo = `expected' / `observed'
        }

 **Calculate the grouped squared prediction error**
quietly generate double `group_sqerror' = (`obsrisk' - `pred')^2 if `tag' == 1 & !missing(`obsrisk', `pred', `size')

**Weight the squared error by the group size**
quietly generate double `weighted_sqerror' = `size' * `group_sqerror' if `tag' == 1 & !missing(`group_sqerror')

**Calculate the weighted sum of squared errors**
quietly summarize `weighted_sqerror' if `tag' == 1, meanonly
local weighted_sse = r(sum)

**Calculate the total number of observations across score groups**
quietly summarize `size' if `tag' == 1 & !missing(`group_sqerror'), meanonly
local total_weight = r(sum)

**Calculate the grouped weighted RMSE**
local rmse = .

if `total_weight' > 0 {
    local rmse = sqrt(`weighted_sse' / `total_weight')
}

**Calculate the weighted adjusted R-squared**
local adjr2 = .

quietly count if `tag' == 1 & !missing(`obsrisk', `pred', `size')
local ngroupfit = r(N)

if `ngroupfit' >= 3 {

    capture quietly regress `obsrisk' `pred' if `tag' == 1 & !missing(`obsrisk', `pred', `size') [aw = `size']

    if !_rc {
        local adjr2 = e(r2_a)
    }
}

        **Confine the predicted risk before logit transformation**
        quietly generate double `pclip' = ///
            min(max(`pred', 1e-8), 1 - 1e-8) ///
            if `touse' & !missing(`pred')

        **Generate the linear predictor**
        quietly generate double `linear_predictor' = ///
            ln(`pclip' / (1 - `pclip')) ///
            if `touse' & !missing(`pclip')

        **Calculate the calibration-in-the-large**
        local citl = .

        capture quietly logit `y' ///
            if `touse' & !missing(`linear_predictor'), ///
            offset(`linear_predictor')

        if !_rc {
            local citl = _b[_cons]
        }

        **Calculate the calibration slope**
        local slope = .

        capture quietly logit ///
            `y' c.`linear_predictor' ///
            if `touse' & !missing(`linear_predictor')

        if !_rc {
            local slope = _b[`linear_predictor']
        }

        **Calculate the area under the receiver operating characteristic curve**
        local auc = .

        capture quietly roctab ///
            `y' `pred' ///
            if `touse' & !missing(`pred')

        if !_rc {
            local auc = r(area)
        }

        **Store the statistics**
        matrix `statistics'[`i', 1] = `eo'
        matrix `statistics'[`i', 2] = `citl'
        matrix `statistics'[`i', 3] = `slope'
		matrix `statistics'[`i', 4] = `adjr2'
        matrix `statistics'[`i', 5] = `rmse'
        matrix `statistics'[`i', 6] = `auc'

        **Call the options from the corresponding plots**
        local lineopts ``plot`i'opts''
        local ciopts ``ci`i'opts''
        local scatteropts ``scatter`i'opts''

        **Add the fitted line**
        local plots `plots' ///
            (line `pred' `score' ///
                if `tag' == 1, ///
                sort ///
                pstyle(p`i') ///
                `lineopts')

        **Add the exact confidence interval**
        if "`noci'" == "" {

            local plots `plots' ///
                (rcap `cil' `ciu' `score' ///
                    if `tag' == 1, ///
                    pstyle(p`i') ///
                    lwidth(thin) ///
                    `ciopts')
        }

        **Add the observed risk**
        local plots `plots' ///
            (scatter `obsrisk' `score' ///
                if `tag' == 1 ///
                [fweight = `size'], ///
                pstyle(p`i') ///
                msymbol(`markeri') ///
                `scatteropts')

**Identify the plot positions in the legend**
if "`noci'" == "" {

    local lineindex = 3 * `i' - 2
    local ciindex = 3 * `i' - 1
    local scatterindex = 3 * `i'

    **Add scatter, confidence interval, and fitted line to the legend**
    if `nscore' == 1 {
        local legorder `legorder' `scatterindex' "Observed risk" `ciindex' "`level'% CI" `lineindex' "Fitted risk"
    }
    else {
        local legorder `legorder' `scatterindex' "`score': observed risk" `ciindex' "`score': `level'% CI" `lineindex' "`score': fitted risk"
    }
}
else {

    local lineindex = 2 * `i' - 1
    local scatterindex = 2 * `i'

    **Add scatter and fitted line to the legend**
    if `nscore' == 1 {
        local legorder `legorder' `scatterindex' "Observed risk" `lineindex' "Fitted risk"
    }
    else {
        local legorder `legorder' `scatterindex' "`score': observed risk" `lineindex' "`score': fitted risk"
    }
}

        **Format the statistics**
        local seo = ///
            strtrim(string(`eo', "%6.3f"))

        local scitl = ///
            strtrim(string(`citl', "%6.3f"))

        local sslope = ///
            strtrim(string(`slope', "%6.3f"))

        local sr2 = ///
			strtrim(string(`adjr2', "%6.3f"))

        local srmse = ///
            strtrim(string(`rmse', "%6.3f"))

        local sauc = ///
            strtrim(string(`auc', "%6.3f"))

        **Store the statistics of the first score**
        if `i' == 1 {
            local stat_auc "`sauc'"
            local stat_slope "`sslope'"
            local stat_citl "`scitl'"
            local stat_eo "`seo'"
            local stat_adjr2 "`sr2'"
            local stat_rmse "`srmse'"
        }
    }

    **Name the rows of the statistics matrix**
    matrix rownames `statistics' = ///
        `rownames'

    **Prepare the statistics note**
    local statgraph

    if "`nostat'" == "" {

        **Display the statistics in the Results window**
        display as text ///
            _newline "Apparent performance statistics"

        matrix list `statistics', ///
            format(%9.3f)

        **Add the statistics of the first score to the graph note**
        local statgraph ///
            `"note("AuROC `stat_auc'" "C-slope `stat_slope'" "CITL `stat_citl'" "E:O `stat_eo'" "Adj-R2 `stat_adjr2'" "RMSE `stat_rmse'", size(small) justification(left) ring(0) position(11) margin(t=20 l=5) linegap(2))"'
    }

**Plot the risk calibration graph**
twoway `plots', legend(order(`legorder') cols(1) position(11) ring(0)) `statgraph' `options'

    **Store the results**
    return matrix stats = `statistics'
    return local endpoint "`y'"
    return local scores "`scores'"
    return local models "`models'"
end