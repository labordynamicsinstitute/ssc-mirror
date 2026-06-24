*===============================================================================
* suso_examples.do  —  copy a block, edit the <...> bits, run it.
* (Nothing here deletes anything. Destructive commands are shown but commented.)
*===============================================================================

*--- 1) CONNECT (once per session) --------------------------------------------
suso config , server(https://decpm11-surveys.worldbank.org) ///
              workspace(srilankainf) user(DECEA_API) password(********)

* Set your questionnaire ONCE, then you never type the GUID again:
suso questionnaire list                         // <- read QuestionnaireId + Version
* suso config , guid(<GUID-from-the-list>) qver(<Version>)

suso ping                                       // "connection OK (HTTP 200)" = good
suso config , show

*--- 2) SEE DATA (loads into memory; preserve if you have data open) ----------
preserve
    suso interview list , status(Completed) all
    list InterviewId ResponsibleName Status in 1/10
restore

* suso assignment list , all
* suso interview list , all                       // uses your saved questionnaire
* suso interview stats   , id(<interview-uuid>)
* suso interview get     , id(<interview-uuid>)   // loads the answers
* suso interview history , id(<interview-uuid>)

*--- 3) REVIEW ----------------------------------------------------------------
* suso interview approve , id(<uuid>) comment("looks good")
* suso interview reject  , id(<uuid>) comment("please revisit the GPS point")
* suso interview commentbyvar , id(<uuid>) variable(d2_sales) comment("confirm units")

*--- 4) EXPORT + DOWNLOAD (best for large pulls) ------------------------------
suso export start , type(STATA) istatus(ApprovedBySupervisor)   // guid/qver from saved default
local job = r(jobid)

* poll until it's ready, then download:
forvalues i = 1/60 {
    suso export status , id(`job')
    if "`r(exportstatus)'" == "Completed" continue, break
    sleep 5000
}
suso export download , id(`job') saving("ises_data.zip") replace

*--- 5) TEAM ------------------------------------------------------------------
* suso supervisor list , all
* suso supervisor interviewers , id(<supervisor-uuid>)
* suso interviewer actionslog , id(<interviewer-uuid>) start(2026-06-01) end(2026-06-17)

*--- 6) DANGER (commented on purpose; add , confirm to run) -------------------
* suso interview delete , id(<uuid>) confirm
* suso export cancel    , id(<jobid>) confirm
* suso workspace status , name(<ws>)
* suso workspace delete , name(<ws>) iknowthis(<ws>)
