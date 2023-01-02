#!/bin/sh

if [ "${os}" != "Windows" ]; then

  echo "this is a POSIX-compatible shell script meant to accompany the Stata package -inshell-"
  echo "var1 is equal to ${var1}"
  echo "var2 is equal to ${var2}"
  echo "var1 multiplied by var2 is equal to $((var1 * var2))"
  echo "var3 is equal to ${var3}"
  echo "your operating system is ${os}"
  echo "you are using the $(echo "${flavor}" | tr '[:lower:]' '[:upper:]') flavor of Stata"

  date="$(date +%s)"
  [ ! "${date}" -lt $((200 * 200 * 200 * 200)) ] && echo "this moment in time is after $(date -r $((200 * 200 * 200 * 200)))"
  [ -n "$TMPDIR" ] && export tempdir="$TMPDIR"
  [ -n "$STATATMP" ] && export tempdir="$STATATMP"

  echo "about" > "${tempdir}/about.do"

  if [ -f "$(which stata-"${flavor}")" ]; then
    if [ -f "${tempdir}/about.do" ]; then
      $(which stata-"${flavor}") -q do "${tempdir}/about.do" > "${tempdir}/inshell_demo_log_${date}.txt"
      cat "${tempdir}/inshell_demo_log_${date}.txt"
      rm "${tempdir}/inshell_demo_log_${date}.txt"
      pwd
      echo
      echo "\n this script with exit with a return code of 99. This is not an error."
      (exit 99)
    fi
  elif [ -f "/usr/local/bin/stata-${flavor}" ]; then
    if [ -f "${tempdir}/about.do" ]; then
      /usr/local/bin/stata-"${flavor}" -q do "${tempdir}/about.do" > "${tempdir}/inshell_demo_log_${date}.txt"
      cat "${tempdir}/inshell_demo_log_${date}.txt"
      rm "${tempdir}/inshell_demo_log_${date}.txt"
      pwd
      echo "\n this script with exit with a return code of 99. This is not an error."
      (exit 99)
    fi
  elif [ ! -f "/usr/local/bin/stata-${flavor}" ] && [ ! -f "$(which stata-"${flavor}")" ]; then
    echo "a command line instance of Stata was not found on this system"
    (exit 1)
  fi

fi
