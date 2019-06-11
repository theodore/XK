#!/bin/bash

######################################################################
##    The Ultimate XK Script by the Mighty You                      ##
##------------------------------------------------------------------##
##                      XXX How to use XXX                          ##
## 1. Login with a browser, in English, copy its cookie to cjar.    ##
## 2. Edit the folowing two variables.                              ##
## 3. Fire this script up and enjoy the course.                     ##
######################################################################


## Configuration variables {{{
# Course number to check vacancy, don't use hot courses.
#COURSECHECK="FINE110017.01"
COURSECHECK="FINE110031.01"
# The course to select, only one is supported currently.
COURSESELECT="$COURSECHECK"
# }}}

SITE="http://xk.fudan.edu.cn/xk"
INPUT="input.jsp"
LANGUAGE="languageServlet?languager=isEn"
IMAGE="image.do"
SEEK="sekcoursepeos.jsp"
SELECT="doSelectServlet"
TMPFILES=""

## GOD BLESS CURL!!!
function CURL {
    # Fake firefox, load and save cookies, allow redirection.
    # Note the version number might need to be updated.
    curl -A "Mozilla/5.0 (X11; Linux i686; rv:10.0.12) Gecko/20100101 Firefox/10.0.12 Iceweasel/10.0.12" -b cjar -c cjar -L $@
}

## Usage: Verify [token]
##  token can be omitted, that is, when we are logging in.
function Verify {
    DOWN="$SITE/$IMAGE"
    test -z "$1" || DOWN="$DOWN?token=$1"
    CURL -o img.jpg "$DOWN"
    TMPFILES="$TMPFILES img.jpg"
    feh img.jpg
    read ver
    echo "$ver"
}

## Not used {{{
function CheckLogin {
    CHECK="check.html"
    rm -f "$CHECK"
    CURL -o "$CHECK" "$SITE/courseTableServlet"
    rm "$CHECK" || return 1
    return 0
}

function Login {
    CURL -o /dev/null "$SITE/$LANGUAGE"
    ver=`Verify`
    # FIXME Remeber to fill in the ID and password.
    CURL -d "studentId=" -d "password=" -d "rand=$ver" -d "Submit2=%E6%8F%90%E4%BA%A4" -o /dev/null "$SITE/loginServlet"
}
## }}}

## Usage: IsFreed CourseNumber
## FIXME  If someone gets the course before me, this function won't work.
function IsFreed {
    FILE="vacancycheck.html"
    CURL -s -d "xkh=$1" -d "submit=Inquiry" -d "model=%E8%A9%BA%E4%BD%99%E4%BA%BA%E6%95%B0%E6%9F%A5%E8%AF%A2" -o "$FILE" "$SITE/$SEEK"
    N="`grep -B4 "teach" "$FILE" | head -1 | sed 's/.*> \(.\).*/\1/'`"
    rm "$FILE"
    test "$N" == 0 || return 1
    return 0
}

## Saves the verification code in advance, so we can select the course once
## it's freed.
## Prints the token and verification code.
function PrepXK {
    CURL -o input.html "$SITE/$INPUT"
    TMPFILES="$TMPFILES input.html"
    TOKEN="`grep "token=" "input.html" | sed 's/.*token=\(....\).*/\1/'`"
    VER="`Verify "$TOKEN"`"
    echo -e "$TOKEN\n$VER"
}

## Usage: XK token VerCode CourseNumber
function XK {
    CURL -d "token=$1" -d "selectionId=$3" -d "xklb=ss" -d "rand=$2" -o "result.html" "$SITE/$SELECT"
    TMPFILES="$TMPFILES result.html"
}

#function CleanUp {
    #echo "TMPFILES = $TMPFILES"
    #rm -v $TMPFILES
#}


#CheckLogin || Login

## Let the user input the verification code VER for TOKEN, and keep it for
## later course selecting.
RET="`PrepXK`"
TOKEN="`echo "$RET" | head -1`"
VER="`echo "$RET" | tail -1`"

while true; do
    # Change to this, don't know if it works {{{
    # IsFreed "$COURSECHECK" && break
    # echo "false"
    # }}}
    if IsFreed "$COURSECHECK"; then
        break
    else
        echo 'false'
    fi
    # Sleep only when the connection is way very good.
    #sleep 0.1
done

XK "$TOKEN" "$VER" "$COURSESELECT"

## Print date to see if the school frees courses at the same time.
## Current guess: 12:33
date | tee -a xk.log

#CleanUp
