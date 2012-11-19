#!/bin/bash
# Script for checking ban on website in Federal Registry of Banned Websites in Russia http://zapret-info.gov.ru
# Author: Komachi Onozuka, https://github.com/komachi
# Licence: CC0, https://creativecommons.org/publicdomain/zero/1.0/
# Depends: curl, tidy, xmlstarlet, feh, sed, coreutils
useragent=""
function get_captcha() {
    captchaid=$(curl --cookie-jar "/tmp/zapretcookie.txt" --silent -q --user-agent "$useragent" "http://zapret-info.gov.ru" | tidy -q -numeric -asxhtml --show-warnings no  | xmlstarlet  sel -N xhtml="http://www.w3.org/1999/xhtml"  -t -v "//xhtml:input[@name='secretcodeId']/@value[1]")
    curl --cookie "/tmp/zapretcookie.txt" --silent -q --user-agent "$useragent" -o "/tmp/$captchaid.png" "http://zapret-info.gov.ru/services/capcha/?i=$captchaid"
}
function enter_captcha() {
    echo "Enter CAPTCHA"
    feh "/tmp/$captchaid.png"&
    read captchaanswer
    kill -9 $!
    wait $! 2>/dev/null
}
function antigate() {
    local antigate=$(curl  --silent -q --user-agent "$useragent" -F "method=post" -F "key=$antigatekey" -F "numeric=1" -F "min_len=8" -F "max_len=8" -F "file=@/tmp/$captchaid.png;type=image/png" "http://antigate.com/in.php")
    if [[ $(echo "$antigate" | grep "ERROR") ]];then
        echo "Antigate error: $antigate"
        exit
    else
        antigatecaptchaid=$(echo "$antigate" | sed -e 's/OK|//g')
    fi
    echo "Waiting for solution"
    sleep 5
    while [[ ! $(echo "$captchastatus" | grep 'OK|') ]]; do
        sleep 2
        local captchastatus=$(curl  --silent -q --user-agent "$useragent" "http://antigate.com/res.php?key=$antigatekey&action=get&id=$antigatecaptchaid")
        if [[ $(echo "$captchastatus" | grep 'ERROR') ]]; then
            echo "Antigate error: $captchastatus"
            exit
        fi
    done
    captchaanswer=$(echo "$captchastatus" | sed -e 's/OK|//g')
    echo "Solution: $captchaanswer"
}
function zapret_check() {
    result="$(curl --cookie "/tmp/zapretcookie.txt" --silent -q --user-agent "$useragent" --data "act=search&secretcodeId=$captchaid&searchstring=$searchstring&secretcodestatus=$captchaanswer" "http://zapret-info.gov.ru" | iconv -f cp1251 -t utf-8)"
    if [[ $(echo "$result" | grep "Искомый адрес не значится в реестре") ]]; then
        echo "$searchstring is not in Federal Registry of Banned Websites"
    elif [[ $(echo "$result" | grep "Неверно указан защитный код") ]]; then
        echo "Wrong CAPTCHA"
        if [[ $("$antigatecaptchaid") ]]; then
            curl --silent -q --user-agent "$useragent" "http://antigate.com/res.php?key=$antigatekey&action=reportbad&id=$antigatecaptchaid"
        fi
    elif  [[ $(echo "$result" | grep "Дата внесения в реестр") ]]; then
        echo "$searchstring is in Federal Registery of Banned Websites"
        local resultdata=$(echo "$result" | tidy -q -numeric -asxhtml --show-warnings no --char-encoding utf8 | xmlstarlet  sel -N xhtml="http://www.w3.org/1999/xhtml"  -t -m "//xhtml:table[@class='TblGrid']/*/xhtml:td" -v . -n)
        echo -e "Date of base for entering to registy: $(echo "$resultdata" | sed -n '1p')\nNumber of base for entery to registry: $(echo "$resultdata" | sed -n '2p')\nPublic autority which add website to registry: $(echo "$resultdata" | sed -n '3p')\nDate of entering to registy: $(echo "$resultdata" | sed -n '4p')"
    else
        echo "Something wrong. Try again."
        exit
    fi
    rm "/tmp/$captchaid.png" "/tmp/zapretcookie.txt"
}
while getopts ":ea:s:h" opt ;
do
    case $opt in
        e)  get_captcha;
            enter_captcha;
            ;;
        a)  antigatekey=$OPTARG;
            get_captcha;
            antigate;
            ;;
        s)  searchstring=$OPTARG;
            zapret_check;
            ;;
        h)  echo -e 'zapret-info-checker.sh: checks strings to ban from Federal Registry of Banned Websites\nUsage: zapret-info-checker.sh [<options>] [<string to check>]\nwhere <command> is one of:\n  -e                - enter captcha by hands\n  -a <antigate_key> - with antigate.com account\n  -h                - this help\n  -s                - string to check';
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            exit 1
           ;;
        esac
done
