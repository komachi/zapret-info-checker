# zapret-info-checker.sh
Easy bash script which let you check status of site in [Federal Registy of Banned Websites](http://zapret-info.gov.ru).

Supports manualy entering captcha and antigate.com

## Depends
* curl
* coreutils
* xmlstarlet
* sed
* feh
* tidy

## Options
* -e                - enter captcha by hands
* -a <antigate_key> - with antigate.com account
* -h                - this help
* -s                - string to check

## Usage example
```bash
$ ./zapret-info-checker.sh -e -s google.com
Enter CAPTCHA
<captcha>
google.com is not in Federal Registry of Banned Websites
```
```bash
$ ./zapret-info-checker.sh -a "<antigate_id>" -s 199.27.76.194
Waiting for solution
Solution: <captcha>
199.27.76.194 is in Federal Registery of Banned Websites
Date of base for entering to registy: 03.11.2012
Number of base for entery to registry: 8
Public autority which add website to registry: Роспотребнадзор
Date of entering to registy: 08.11.2012
```
