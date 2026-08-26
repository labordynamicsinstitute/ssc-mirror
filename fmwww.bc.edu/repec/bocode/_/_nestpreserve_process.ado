*! version 1.0.0 23aug2026
program define _nestpreserve_process, rclass
    version 16.0
    syntax , ACTION(string) [PID(string) START(string) HOST(string)]

    local action = lower(strtrim("`action'"))
    if "`action'" == "identity" {
        capture noisily javacall NestPreserveProcess identity, ///
            jars(nestpreserve-process.jar)
        if _rc {
            return local status "unknown"
            exit _rc
        }
        return local status "${NESTPRESERVE_probe_status}"
        return local pid "${NESTPRESERVE_owner_pid}"
        return local start "${NESTPRESERVE_owner_start}"
        return local host "${NESTPRESERVE_owner_host}"
        exit
    }

    if "`action'" == "check" {
        if "`pid'" == "" | "`start'" == "" | `"`host'"' == "" {
            di as error "process identity is incomplete"
            exit 198
        }
        capture noisily javacall NestPreserveProcess check, ///
            jars(nestpreserve-process.jar) args(`pid' `start' `host')
        if _rc {
            return local status "unknown"
            exit
        }
        return local status "${NESTPRESERVE_probe_status}"
        exit
    }

    di as error "invalid internal process action"
    exit 198
end
