#!/bin/bash

html=$(curl -s \
-H 'DNT: 1' \
-H 'Accept-Encoding: gzip, deflate, sdch, br' \
-H 'Accept-Language: en-US,en;q=0.8,he;q=0.6' \
-H 'Upgrade-Insecure-Requests: 1' \
-H "User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.$RANDOM.$RANDOM Mobile Safari/537.36" \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Referer: https://google.com/' \
-H 'Connection: keep-alive' \
-H 'Cache-Control: max-age=0' \
--compressed \
-L "$1")

section_per_line_html=$(echo "$html" | \
tr -d '\n' | \
sed 's/<section/\n\<section/g' | \
grep '^<section')

end_date=$(echo "$section_per_line_html" | fgrep 'id="information"' | awk -F '[<>]' '{print $51}')

hosts=$(echo "$section_per_line_html" | \
grep '<section id="hosts">' | \
head -1 | \
sed 's/<td>/\n<td>/g' | \
awk -F '[<>]' '/^<td>/ {print $3}' | \
sort | \
uniq)

domains=$(echo "$section_per_line_html" | \
grep '<section id="domains">' | \
head -1 | \
sed 's/<tr>/\n<tr>/g' | \
awk -F '[<>]' '/<td>/ {print $5}' | \
sort | \
uniq)

files=$(echo "$section_per_line_html" | \
grep '<section id="summary">' | \
sed 's/<div class="well mono">/\n<div class="well mono">/g' | \
grep '^<div class="well mono">' | \
head -1 | \
sed 's/<br \/>/\n/g' | \
sed 's/<div class="well mono">//g' | \
grep -v '<div' | \
tr -s ' ' | \
sed 's/^ //g' | \
sort | \
uniq)

registry=$(echo "$section_per_line_html" | \
grep '<section id="summary">' | \
sed 's/<div class="well mono">/\n<div class="well mono">/g' | \
grep '^<div class="well mono">' | \
head -2 | \
tail -1 | \
sed 's/<br \/>/\n/g' | \
sed 's/<div class="well mono">//g' | \
grep -v '<div' | \
tr -s ' ' | \
sed 's/^ //g' | \
sort | \
uniq)

mutex=$(echo "$section_per_line_html" | \
grep '<section id="summary">' | \
sed 's/<div class="well mono">/\n<div class="well mono">/g' | \
grep '^<div class="well mono">' | \
tail -1 | \
sed 's/<br \/>/\n/g' | \
sed 's/<div class="well mono">//g' | \
grep -v '<div' | \
tr -s ' ' | \
sed 's/^ //g' | \
sort | \
uniq)

api=$(echo "$section_per_line_html" | \
sed 's/"api":/\n"api":/g' | \
awk -F '"' '/^"api"/ {print $4}' | \
sort | \
uniq)

virustotal=$(echo "$section_per_line_html" | \
grep '^<section id="static_antivirus">' | \
sed 's/<span/\n<span/g' | \
awk 'BEGIN {detected=0; clean=0;} '\
'/class="muted"/ {clean++} '\
'/class="text-error"/ {detected++} '\
'END {print detected "/" (detected+clean)}')

info=$(echo "$section_per_line_html" | \
grep 'id="file"' | \
sed 's/<tr>/\n<tr>/g' | \
grep -vi 'yara' | \
awk -F '[<>]' 'BEGIN {print "{"} '\
'/^<tr>.*<th>.*<td>[^<]/ {print "\"" $5 "\":\"" $9 "\","} '\
'END {print "}"}' | \
tr -d '\n' | \
sed 's/,}/}/g' | \
sed 's/\\/\\\\/g' | \
sed 's/",/",\n/g')

echo "$info" | jq \
--arg hosts "$hosts" \
--arg domains "$domains" \
--arg files "$files" \
--arg registry "$registry" \
--arg mutex "$mutex" \
--arg api "$api" \
--arg url "$1" \
--arg end_date "$end_date" \
--arg virustotal "$virustotal" \
'.VirusTotal = $virustotal | '\
'.URL = $url | '\
'.Date = $end_date | '\
'.Hosts = ($hosts | split("\n")) | '\
'.Domains = ($domains | split("\n")) | '\
'.Files = ($files | split("\n")) |'\
'.Registry = ($registry | split("\n")) | '\
'.Mutex = ($mutex | split("\n")) | '\
'.API = ($api | split("\n"))'
