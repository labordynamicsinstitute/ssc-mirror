*! version 1.0.0  03apr2026
program define telegram, rclass
    version 17

    // Intercept the setup subcommand
    gettoken subcmd : 0, parse(" ,")
    if `"`subcmd'"' == "setup" {
        TelegramSetup
        exit
    }

    // Otherwise, route to the main message sender
    TelegramMain `0'
    return add
end

// ============================================================================
// MAIN MESSAGE PROGRAM
// ============================================================================
program define TelegramMain, rclass
    syntax [anything(name=message id="message text/caption")], ///
        [ TOKEN(string asis) CHATID(string asis) FIGURE(string asis) ///
          CONNECTTimeout(integer 10) MAXTime(integer 60) RETRY(integer 0) ///
          CURLCMD(string asis) NOTRIMPIPE DEBUG QUIET ]

    // ------------------------------------------------------------
    // Resolve Macros
    // ------------------------------------------------------------
    if `"`curlcmd'"' == "" local curlcmd "curl"

    local shell_rc 0
    local file_rc  0
    local curl_rc  0
    local dq `"""'

    // Strip outer quotes from TOKEN, CHATID, and curlcmd if supplied
    if usubstr(`"`token'"', 1, 1) == char(34) & usubstr(`"`token'"', -1, 1) == char(34) {
        local token = usubstr(`"`token'"', 2, ustrlen(`"`token'"') - 2)
    }
    if usubstr(`"`chatid'"', 1, 1) == char(34) & usubstr(`"`chatid'"', -1, 1) == char(34) {
        local chatid = usubstr(`"`chatid'"', 2, ustrlen(`"`chatid'"') - 2)
    }
    if usubstr(`"`curlcmd'"', 1, 1) == char(34) & usubstr(`"`curlcmd'"', -1, 1) == char(34) {
        local curlcmd = usubstr(`"`curlcmd'"', 2, ustrlen(`"`curlcmd'"') - 2)
    }

    local token  = strtrim(`"`token'"')
    local chatid = strtrim(`"`chatid'"')

    // ------------------------------------------------------------
    // Check Local Config File for Missing Credentials
    // ------------------------------------------------------------
    if `"`token'"' == "" | `"`chatid'"' == "" {
        capture confirm file "`c(sysdir_personal)'telegram_config.txt"
        if _rc == 0 {
            tempname fh_config
            file open `fh_config' using "`c(sysdir_personal)'telegram_config.txt", read
            
            // Read line 1 (Token)
            if `"`token'"' == "" {
                file read `fh_config' line1
                local token `"`line1'"'
            }
            else {
                file read `fh_config' trash_macro
            }
            
            // Read line 2 (Chat ID)
            if `"`chatid'"' == "" {
                file read `fh_config' line2
                local chatid `"`line2'"'
            }
            file close `fh_config'
        }
    }

    // ------------------------------------------------------------
    // Validate Settings
    // ------------------------------------------------------------
    if `"`token'"' == "" | `"`chatid'"' == "" {
        di as err `"{bf:telegram}: Telegram credentials not found."'
        di as err `"Please run {bf:telegram setup} to configure your bot, or provide token() and chatid() manually."'
        exit 198
    }

    if !ustrregexm(`"`token'"', "^[0-9]+:[a-zA-Z0-9_\-]+$") {
        di as err `"{bf:telegram}: token contains whitespace or invalid characters."'
        exit 198
    }

    if !ustrregexm(`"`chatid'"', "^-?[0-9]+$|^@[a-zA-Z0-9_]+$") {
        di as err `"{bf:telegram}: chat ID must be numeric or an @channel, with no whitespace."'
        exit 198
    }

    if `connecttimeout' < 0 | `maxtime' <= 0 | `retry' < 0 {
        di as err `"{bf:telegram}: invalid timeout or retry parameters."'
        exit 198
    }

    // Pre-flight check: verify curl is accessible
    capture quietly shell `dq'`curlcmd'`dq' --version
    if _rc != 0 {
        di as err `"{bf:telegram}: could not execute '{bf:`curlcmd'}'. Check your PATH or curlcmd() option."'
        exit 198
    }

    // ------------------------------------------------------------
    // Validate Figure (If Provided)
    // ------------------------------------------------------------
    if `"`figure'"' != "" {
        if usubstr(`"`figure'"', 1, 1) == char(34) & usubstr(`"`figure'"', -1, 1) == char(34) {
            local figure = usubstr(`"`figure'"', 2, ustrlen(`"`figure'"') - 2)
        }

        capture confirm file `"`figure'"'
        if _rc {
            di as err `"{bf:telegram}: figure file does not exist or is unreadable:"'
            di as err `"       `figure'"'
            exit 601
        }

        local ext = lower(usubstr(`"`figure'"', ustrrpos(`"`figure'"', ".") + 1, .))
        local valid_exts "jpg jpeg png gif bmp webp"
        if !ustrpos(" `valid_exts' ", " `ext' ") {
            di as err `"{bf:telegram}: invalid figure format '.`ext''. Telegram expects: `valid_exts'."'
            exit 198
        }
    }

    // ------------------------------------------------------------
    // Normalize Input Message / Caption
    // ------------------------------------------------------------
    local text `"`message'"'

    // Strip outer compound quotes or standard quotes safely
    if ustrlen(`"`text'"') >= 4 ///
        & usubstr(`"`text'"', 1, 2) == char(96) + char(34) ///
        & usubstr(`"`text'"', -2, 2) == char(34) + char(39) {
        local text = usubstr(`"`text'"', 3, ustrlen(`"`text'"') - 4)
    }
    else if ustrlen(`"`text'"') >= 2 ///
        & usubstr(`"`text'"', 1, 1) == char(34) ///
        & usubstr(`"`text'"', -1, 1) == char(34) {
        local text = usubstr(`"`text'"', 2, ustrlen(`"`text'"') - 2)
    }

    local orig_len = ustrlen(`"`text'"')

    // Convert || to line breaks
    if "`notrimpipe'" == "" local text = ustrregexra(`"`text'"', "[ \t]*\|\|[ \t]*", char(10))
    else                    local text = subinstr(`"`text'"', "||", char(10), .)

    if ustrtrim(`"`text'"') == "" & `"`figure'"' == "" {
        di as err `"{bf:telegram}: command contains no sendable text or image."'
        exit 198
    }

    // ------------------------------------------------------------
    // API Execution Branching
    // ------------------------------------------------------------
    tempname fh
    tempfile tgmsg tgresp
    local nchunks 0

    // [BRANCH A: SEND FIGURE]
    if `"`figure'"' != "" {
        local nchunks 1
        if ustrlen(`"`text'"') > 1024 {
            di as err `"{bf:telegram}: Telegram limits image captions to 1024 characters (yours: `=ustrlen(`"`text'"')')."'
            di as err `"       Please shorten your text or send the image and text as separate telegram commands."'
            exit 198
        }

        local caption_arg ""
        if `"`text'"' != "" {
            capture quietly file open `fh' using "`tgmsg'", write text replace
            if _rc exit _rc
            capture file write `fh' `"`text'"'
            capture file close `fh'
            local caption_arg `"-F "caption=<`tgmsg'""'
        }

        local url `"https://api.telegram.org/bot`token'/sendPhoto"'
        local cmd `"`dq'`curlcmd'`dq' -g --silent --show-error --connect-timeout `connecttimeout' --max-time `maxtime' --retry `retry' -X POST "`url'" -F "chat_id=`chatid'" -F "photo=@`figure'" `caption_arg' -o "`tgresp'""'

        capture erase "`tgresp'"
        if "`debug'" != "" capture noisily shell `cmd'
        else capture quietly shell `cmd'

        // Catch the 601 error if curl fails to generate the output file
        capture file open `fh' using "`tgresp'", read text
        if _rc {
            di as err `"{bf:telegram}: Could not read API response. Check your internet connection or {bf:curlcmd()} path."'
            exit 198
        }
        capture file read `fh' response
        capture file close `fh'

        if strpos(`"`response'"', `""ok":true"') == 0 {
            di as err `"{bf:telegram}: Telegram API rejected the figure request."'
            if ustrregexm(`"`response'"', `""description":"([^"]+)""') {
                di as err `"       Reason: {bf:`=ustrregexs(1)'}"'
            }
            else {
                di as err `"       Raw response: `response'"'
            }
            exit 22
        }
    }
    // [BRANCH B: SEND TEXT WITH CHUNKING]
    else {
        // Lowered to 4000 to safely bypass Telegram's UTF-16 code unit counting for emojis
        local maxchars 4000
        local remaining `"`text'"'

        while ustrlen(`"`remaining'"') > 0 {
            local ++nchunks
            local chunk     = usubstr(`"`remaining'"', 1, `maxchars')
            local remaining = usubstr(`"`remaining'"', `=`maxchars' + 1', .)

            capture quietly file open `fh' using "`tgmsg'", write text replace
            if _rc exit _rc
            capture file write `fh' `"`chunk'"'
            capture file close `fh'

            local url `"https://api.telegram.org/bot`token'/sendMessage"'
            local cmd `"`dq'`curlcmd'`dq' -g --silent --show-error --connect-timeout `connecttimeout' --max-time `maxtime' --retry `retry' -X POST "`url'" --data-urlencode "chat_id=`chatid'" --data-urlencode "text@`tgmsg'" -o "`tgresp'""'

            capture erase "`tgresp'"
            if "`debug'" != "" capture noisily shell `cmd'
            else capture quietly shell `cmd'

            // Catch the 601 error if curl fails to generate the output file
            capture file open `fh' using "`tgresp'", read text
            if _rc {
                di as err `"{bf:telegram}: Could not read API response for chunk `nchunks'. Check your internet connection or {bf:curlcmd()} path."'
                exit 198
            }
            capture file read `fh' response
            capture file close `fh'

            if strpos(`"`response'"', `""ok":true"') == 0 {
                di as err `"{bf:telegram}: Telegram API rejected chunk `nchunks'."'
                if ustrregexm(`"`response'"', `""description":"([^"]+)""') {
                    di as err `"       Reason: {bf:`=ustrregexs(1)'}"'
                }
                else {
                    di as err `"       Raw response: `response'"'
                }
                exit 22
            }
        }
    }

    if "`quiet'" == "" {
        if `"`figure'"' != "" di as txt `"{bf:telegram}: figure sent successfully."'
        else if `nchunks' == 1 di as txt `"{bf:telegram}: message sent successfully."'
        else di as txt `"{bf:telegram}: message sent successfully in `nchunks' chunks."'
    }

    return scalar orig_len  = `orig_len'
    return scalar split_msg = (`nchunks' > 1)
    return scalar chunks    = `nchunks'
    return scalar curl_rc   = `curl_rc'
    return local  type      `=cond(`"`figure'"' != "", "figure", "text")'
    return local  chatid    `"`chatid'"'
end

// ============================================================================
// SETUP SUBROUTINE (telegram setup)
// ============================================================================
program define TelegramSetup
    version 17
    
    di as txt "{hline}"
    di as res "Telegram Bot Setup for Stata"
    di as txt "{hline}"
    di as txt "To send messages from Stata, you need a Telegram Bot."
    di as txt "1. Open the {bf:Telegram App} on your phone or computer."
    di as txt "2. Click the {bf:New Message} icon (usually a pencil/notepad) or use the global search, and search for {bf:@BotFather}."
    di as txt "3. Send him the message {bf:/newbot} and follow the prompts to name your bot."
    di as txt "4. BotFather will give you an HTTP API Token (e.g., 123456:ABC-DEF1234...)."
    di as txt ""
    
    // Prompt the user for the token interactively
    display as txt "Please copy your Token and paste it here: " _request(TELEGRAM_SETUP_TOKEN)
    local token_val = `"$TELEGRAM_SETUP_TOKEN"'
    macro drop TELEGRAM_SETUP_TOKEN
    
    local token_val = strtrim(`"`token_val'"')
    if `"`token_val'"' == "" {
        di as err "No token provided. Setup aborted."
        exit 198
    }
    
    di as txt ""
    di as txt "Next, Stata needs to find your Chat ID."
    di as txt "1. Go back to the {bf:Telegram App}."
    di as txt "2. Click the {bf:t.me/<YourBotUsername>} link BotFather provided to open a chat with your new bot."
    di as txt "3. Click 'Start' at the bottom of the screen, or {bf:send it a normal message} (e.g., 'Hello')."
    di as txt "4. {bf:Wait a moment} (it can sometimes take up to a few minutes for the first message to register)."
    di as txt ""
    
    // Pause until the user is ready
    display as txt "Press {bf:Enter} once you have sent your bot a message..." _request(TELEGRAM_SETUP_PAUSE)
    macro drop TELEGRAM_SETUP_PAUSE
    
    local curlcmd "curl"
    local dq `"""'
    local upd_url `"https://api.telegram.org/bot`token_val'/getUpdates?offset=-1&limit=1&timeout=10"'
    
    local success 0
    
    // Polling loop: 10 attempts, 10 seconds apart
    forvalues i = 1/10 {
        di as txt ""
        di as txt "Checking for new messages (Attempt `i' of 10)..."
        
        tempname fh_upd
        tempfile f_upd
        capture quietly shell `dq'`curlcmd'`dq' -s "`upd_url'" -o "`f_upd'"
        
        local json ""
        capture file open `fh_upd' using "`f_upd'", read text
        if _rc == 0 {
            file read `fh_upd' line
            while r(eof)==0 {
                local json `"`json'`line'"'
                file read `fh_upd' line
            }
            file close `fh_upd'
        }
        
        // Check for success (Chat ID found)
        if ustrregexm(`"`json'"', `""chat":\{"id":(-?[0-9]+)"') {
            local chatid_val = ustrregexs(1)
            di as res "Success! Found Chat ID: `chatid_val'"
            
            // Save to PERSONAL config file securely
            tempname fh_save
            capture file open `fh_save' using "`c(sysdir_personal)'telegram_config.txt", write replace
            if _rc == 0 {
                file write `fh_save' `"`token_val'"' _n
                file write `fh_save' `"`chatid_val'"' _n
                file close `fh_save'
                
                di as txt "{hline}"
                di as res "Your Token and Chat ID have been securely saved to:"
                di as res "`c(sysdir_personal)'telegram_config.txt"
                di as txt "Setup is complete! You can now use the command directly:"
                di as res `"    telegram "Hello from Stata!"  (or: tg "Hello from Stata!")"'
                di as txt "{hline}"
            }
            else {
                di as err "Could not write to `c(sysdir_personal)'. Check your write permissions."
            }
            local success 1
            continue, break
        }
        // Check if API was reached but no message registered yet
        else if ustrpos(`"`json'"', `""ok":true,"result":[]"') {
            di as txt "Bot accessed successfully, but your message has not registered yet (it can sometimes take up to a few minutes for the first message to register)."
            di as txt "Make sure you sent the bot a message. Waiting 10 seconds " _c
        }
        // Check for other errors (e.g., invalid token, no internet)
        else {
            di as err "Unexpected API response or connection issue. Waiting 10 seconds " _c
        }
        
        // If we haven't succeeded and it's not the last attempt, run the progress bar
        if `i' < 10 {
            forvalues s = 1/10 {
                sleep 1000
                di as txt "." _c
            }
            di ""
        }
    }
    
    // If the loop finishes and success is still 0
    if !`success' {
        di as err ""
        di as err "Could not find a Chat ID after 10 attempts."
        di as err "Please check manually by opening this URL in your web browser:"
        di as res "    https://api.telegram.org/bot`token_val'/getUpdates"
        di as err ""
        di as err "If you see a Chat ID appear there later, you can run {bf:telegram setup} again,"
        di as err "or provide the chat ID directly using the chatid() option."
        exit 198
    }
end
