*! syndatakit v0.3.0  15 March 2026
*! Stata interface for the syndatakit Python package
*! Generates synthetic econometric and financial data
*! https://github.com/Nityahapani/syndatakit
*
* SYNTAX
* ------
*   syndatakit, profile(name) [n(#)] [scenario(name)] [intensity(#)]
*               [seed(#)] [dp] [epsilon(#)] [clear] [replace] [nogen]
*
* REQUIRED
*   profile(name)     one of: fred_macro bls hmda fdic edgar cftc
*                             equity_returns corporate_bonds
*                             central_bank_rates irs_soi census_acs
*                             insurance_claims life_insurance
*                             commercial_real_estate rental_market
*                             retail_transactions commodity_prices
*                             world_bank
*
* OPTIONS
*   n(#)              number of synthetic rows  [default: 1000]
*   scenario(str)     recession | severe | rate_shock | expansion
*   intensity(#)      scenario intensity 0.0 to 1.0  [default: 1.0]
*   seed(#)           random seed for reproducibility
*   dp                enable (epsilon,delta) differential privacy
*   epsilon(#)        privacy budget epsilon  [default: 1.0]
*   clear             clear existing data before loading
*   replace           replace existing file if saving
*   nogen             skip generation, just show profile metadata
*
* EXAMPLES
* --------
*   . syndatakit, profile(fred_macro) n(500) clear
*   . syndatakit, profile(hmda) n(10000) scenario(recession) intensity(0.7) clear
*   . syndatakit, profile(equity_returns) n(5000) dp epsilon(0.5) clear
*   . syndatakit, profile(bls) n(2000) seed(42) clear
*
* REQUIREMENTS
* ------------
*   Python 3.8+ with syndatakit installed:
*       pip install syndatakit
*
*   Stata 16+ with Python integration enabled.
*   Verify with:  python query
*
* INSTALLATION (SSC, once published)
* ------------------------------------
*   ssc install syndatakit
*
* MANUAL INSTALLATION
* -------------------
*   Copy syndatakit.ado to your personal ado directory:
*       Unix/Mac:  ~/ado/personal/
*       Windows:   C:\ado\personal\
*
*   Copy syndatakit.sthlp to the same directory.
*
* CITATION
* --------
*   Hapani, N. (2026). syndatakit: Production-grade synthetic data
*   generation for econometrics and finance. Journal of Open Source
*   Software. https://doi.org/10.XXXXX/joss.XXXXX

program define syndatakit
    version 16.0

    // ── Parse syntax ───────────────────────────────────────────
    syntax , Profile(string)          ///
             [N(integer 1000)]        ///
             [SCENario(string)]       ///
             [INTensity(real 1.0)]    ///
             [SEED(integer -1)]       ///
             [DP]                     ///
             [EPSilon(real 1.0)]      ///
             [CLEAR]                  ///
             [REPLACE]                ///
             [NOGEN]

    // ── Validate profile name ───────────────────────────────────
    local valid_profiles "fred_macro bls hmda fdic edgar cftc "    ///
        "equity_returns corporate_bonds central_bank_rates "        ///
        "irs_soi census_acs insurance_claims life_insurance "       ///
        "commercial_real_estate rental_market retail_transactions "  ///
        "commodity_prices world_bank"

    local found = 0
    foreach p of local valid_profiles {
        if "`profile'" == "`p'" local found = 1
    }
    if `found' == 0 {
        di as error "Unknown profile: `profile'"
        di as text  "Valid profiles: `valid_profiles'"
        exit 198
    }

    // ── Validate n ─────────────────────────────────────────────
    if `n' < 1 {
        di as error "n() must be a positive integer"
        exit 198
    }

    // ── Validate scenario ──────────────────────────────────────
    if "`scenario'" != "" {
        local valid_scenarios "recession severe rate_shock expansion none"
        local found_sc = 0
        foreach s of local valid_scenarios {
            if "`scenario'" == "`s'" local found_sc = 1
        }
        if `found_sc' == 0 {
            di as error "Unknown scenario: `scenario'"
            di as text  "Valid scenarios: recession severe rate_shock expansion"
            exit 198
        }
    }

    // ── Validate intensity ─────────────────────────────────────
    if `intensity' < 0 | `intensity' > 1 {
        di as error "intensity() must be between 0.0 and 1.0"
        exit 198
    }

    // ── Validate epsilon ───────────────────────────────────────
    if "`dp'" != "" {
        if `epsilon' <= 0 {
            di as error "epsilon() must be positive"
            exit 198
        }
        if `epsilon' > 10 {
            di as text "Warning: epsilon > 10 provides minimal privacy protection"
        }
    }

    // ── Check Python availability ──────────────────────────────
    capture python query
    if _rc != 0 {
        di as error "Python integration not available."
        di as text  "Enable Python in Stata 16+: see help python"
        exit 198
    }

    // ── Check syndatakit is installed ─────────────────────────
    python: _syndatakit_check()
    if `r(syndatakit_available)' == 0 {
        di as error "syndatakit Python package not found."
        di as text  "Install with: pip install syndatakit"
        exit 198
    }

    // ── Show profile info and exit if nogen ───────────────────
    if "`nogen'" != "" {
        python: _syndatakit_info("`profile'")
        exit 0
    }

    // ── Build generation kwargs ────────────────────────────────
    local kwargs ""
    if "`scenario'" != "" & "`scenario'" != "none" {
        local kwargs `"`kwargs' scenario="`scenario'""'
    }
    if `intensity' != 1.0 {
        local kwargs `"`kwargs' intensity=`intensity'"'
    }
    if `seed' != -1 {
        local kwargs `"`kwargs' seed=`seed'"'
    }
    if "`dp'" != "" {
        local kwargs `"`kwargs' dp=True epsilon=`epsilon'"'
    }

    // ── Clear if requested ─────────────────────────────────────
    if "`clear'" != "" {
        clear
    }

    // ── Run generation ─────────────────────────────────────────
    di as text " "
    di as text "{hline 60}"
    di as text " syndatakit v0.3.0 — generating synthetic data"
    di as text "{hline 60}"
    di as text " Profile  : `profile'"
    di as text " Rows     : `n'"
    if "`scenario'" != "" & "`scenario'" != "none" {
        di as text " Scenario : `scenario' (intensity `intensity')"
    }
    if `seed' != -1 {
        di as text " Seed     : `seed'"
    }
    if "`dp'" != "" {
        di as text " Privacy  : differential privacy (epsilon=`epsilon')"
    }
    di as text "{hline 60}"
    di as text " "

    python: _syndatakit_generate("`profile'", `n', "`scenario'",   ///
                                  `intensity', `seed',              ///
                                  "`dp'" != "", `epsilon')

    // ── Report ─────────────────────────────────────────────────
    di as text " "
    di as text "{hline 60}"
    di as result " Generation complete"
    di as text " Rows loaded    : " _N
    di as text " Variables      : " c(k)
    if "`r(fidelity_score)'" != "" {
        di as text " Est. fidelity  : `r(fidelity_score)'%"
    }
    di as text "{hline 60}"
    di as text " Cite: Hapani (2026) doi:10.XXXXX/joss.XXXXX"
    di as text " Validation: github.com/Nityahapani/syndatakit/validation/"
    di as text " "

end


// ── Python helper functions ────────────────────────────────────────────────

python:

def _syndatakit_check():
    """Check if syndatakit is installed and return result to Stata."""
    import stata_setup
    try:
        import syndatakit
        stata_setup.run('return scalar syndatakit_available = 1')
    except ImportError:
        stata_setup.run('return scalar syndatakit_available = 0')


def _syndatakit_info(profile):
    """Print profile metadata."""
    try:
        from syndatakit.catalog import get_profile_info
        info = get_profile_info(profile)
        print(f"  Profile    : {profile}")
        print(f"  Source     : {info.get('source', 'see documentation')}")
        print(f"  Variables  : {info.get('n_variables', '?')}")
        print(f"  Fidelity   : {info.get('fidelity', '?')}")
        print(f"  Description: {info.get('description', '')}")
    except Exception as e:
        print(f"  Profile: {profile}")
        print(f"  (metadata unavailable: {e})")


def _syndatakit_generate(profile, n, scenario, intensity, seed, use_dp, epsilon):
    """
    Call syndatakit, generate synthetic data, and load into Stata.

    This function:
    1. Imports the appropriate generator class
    2. Loads the profile's seed data
    3. Fits the generator
    4. Applies scenario and DP if requested
    5. Converts the output DataFrame to a Stata dataset
    """
    import pandas as pd
    import numpy as np

    # ── Import syndatakit components ───────────────────────────
    try:
        from syndatakit.generators import (
            GaussianCopulaGenerator,
            DPGaussianCopulaGenerator,
        )
        from syndatakit.catalog    import load_seed, get_profile_info
        from syndatakit.calibration import get_priors, apply_scenario
        from syndatakit.fidelity   import quick_fidelity_score
    except ImportError as e:
        raise RuntimeError(
            f"syndatakit import error: {e}\n"
            "Ensure syndatakit>=0.3.0 is installed: pip install syndatakit"
        )

    # ── Set seed ───────────────────────────────────────────────
    if seed >= 0:
        np.random.seed(seed)

    # ── Select generator ───────────────────────────────────────
    if use_dp:
        gen = DPGaussianCopulaGenerator(
            epsilon=epsilon,
            delta=1e-5,
            priors=get_priors(profile)
        )
    else:
        gen = GaussianCopulaGenerator(priors=get_priors(profile))

    # ── Fit and sample ─────────────────────────────────────────
    seed_data = load_seed(profile)
    gen.fit(seed_data)
    df = gen.sample(n)

    # ── Apply scenario ─────────────────────────────────────────
    if scenario and scenario not in ("", "none"):
        df = apply_scenario(df, scenario, intensity=intensity)

    # ── Compute quick fidelity estimate ────────────────────────
    try:
        fid_score = quick_fidelity_score(seed_data, df)
        fid_str   = f"{fid_score:.1f}"
    except Exception:
        fid_str = ""

    # ── Sanitise column names for Stata ────────────────────────
    # Stata variable names: max 32 chars, alphanumeric + underscore,
    # cannot start with a digit.
    rename_map = {}
    used_names = set()
    for col in df.columns:
        name = col.lower()
        name = "".join(c if c.isalnum() or c == "_" else "_" for c in name)
        name = name[:32]
        if name[0].isdigit():
            name = "v_" + name
        # deduplicate
        base = name
        i = 1
        while name in used_names:
            name = base[:30] + f"_{i}"
            i += 1
        used_names.add(name)
        if name != col:
            rename_map[col] = name
    if rename_map:
        df = df.rename(columns=rename_map)

    # ── Convert to Stata ───────────────────────────────────────
    # Stata's Python integration provides the sfi (Stata Function Interface)
    # module for loading data.
    try:
        from sfi import Data, SFIToolkit

        # Set observation count
        Data.setObsTotal(len(df))

        for col in df.columns:
            col_data = df[col]

            if pd.api.types.is_string_dtype(col_data):
                # String variable
                max_len = max((len(str(v)) for v in col_data if pd.notna(v)),
                              default=1)
                max_len = max(1, min(max_len, 2045))  # Stata str limit
                Data.addVarStr(col, max_len)
                for i, val in enumerate(col_data):
                    if pd.notna(val):
                        Data.storeStr(col, i, str(val))
                    else:
                        Data.storeStr(col, i, "")
            else:
                # Numeric variable — use double for maximum precision
                Data.addVarDouble(col)
                for i, val in enumerate(col_data):
                    if pd.notna(val):
                        Data.store(col, i, float(val))
                    else:
                        # Stata missing value
                        Data.store(col, i, float("nan"))

        # Return fidelity to Stata r()
        if fid_str:
            SFIToolkit.executeCommand(
                f'return local fidelity_score "{fid_str}"', False)

    except ImportError:
        # Fallback: write to a temp CSV and use Stata's -insheet-
        import tempfile, os
        tmpfile = tempfile.mktemp(suffix=".csv")
        df.to_csv(tmpfile, index=False)
        from sfi import SFIToolkit
        SFIToolkit.executeCommand(f'import delimited "{tmpfile}", clear', False)
        os.unlink(tmpfile)

end


// ── Companion command: sdkprofiles ────────────────────────────────────────
// Lists all available profiles with their fidelity scores and sources.

program define sdkprofiles
    version 16.0

    di as text " "
    di as text "{hline 72}"
    di as text "  syndatakit v0.3.0 — available dataset profiles"
    di as text "{hline 72}"
    di as text "  {col 5}Profile{col 32}Source{col 54}Fidelity{col 64}Variables"
    di as text "  {hline 68}"

    local profiles ///
        "cftc|CFTC COT 2022|95.0%|10"                   ///
        "fdic|FDIC SDI 2023|95.0%|6"                    ///
        "bls|BLS QCEW 2022|94.5%|6"                     ///
        "commodity_prices|EIA/USDA/LME 2022|94.4%|13"   ///
        "rental_market|HUD FMR/Zillow 2022|94.1%|13"    ///
        "census_acs|ACS 5-Year 2022|93.4%|11"           ///
        "central_bank_rates|BIS/IMF IFS 2022|92.0%|10"  ///
        "commercial_real_estate|NCREIF/CoStar 2022|92.3%|15" ///
        "hmda|CFPB LAR 2022|91.8%|7"                    ///
        "retail_transactions|Fed Payments 2022|91.1%|12" ///
        "insurance_claims|NAIC Sched P 2022|91.0%|13"   ///
        "equity_returns|CRSP/FF 1990-2023|90.9%|11"     ///
        "corporate_bonds|TRACE/FINRA 2020-23|90.8%|12"  ///
        "edgar|SEC XBRL 2023 Q4|90.4%|7"                ///
        "life_insurance|SOA/LIMRA 2022|88.9%|12"        ///
        "fred_macro|FRED 1960-2023|88.6%|8"             ///
        "world_bank|WDI 2022|87.8%|6"                   ///
        "irs_soi|IRS SOI 2021|81.7%|11"

    foreach entry of local profiles {
        local profile  = substr("`entry'", 1, strpos("`entry'", "|") - 1)
        local rest     = substr("`entry'", strpos("`entry'", "|") + 1, .)
        local source   = substr("`rest'",  1, strpos("`rest'",  "|") - 1)
        local rest2    = substr("`rest'",  strpos("`rest'",  "|") + 1, .)
        local fid      = substr("`rest2'", 1, strpos("`rest2'", "|") - 1)
        local nvars    = substr("`rest2'", strpos("`rest2'", "|") + 1, .)
        di as text "  {col 5}`profile'{col 32}`source'{col 54}`fid'{col 64}`nvars'"
    }

    di as text "  {hline 68}"
    di as text "  Fidelity = 0.45*marginal + 0.30*KS + 0.25*Spearman-correlation"
    di as text "  N=50,000 synthetic rows vs published aggregate statistics"
    di as text "  Reproduce: python validation/fidelity_engine.py"
    di as text " "
    di as text "  Usage: syndatakit, profile(fred_macro) n(1000) clear"
    di as text " "

end
