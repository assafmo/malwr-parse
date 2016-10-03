#!/bin/bash

html=$(curl "$1" --compressed)

section_per_line_html=$(echo "$html" | \
tr -d '\n' | \
sed 's/<section/\n\<section/g' | \
grep '^<section')

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

info=$(echo "$section_per_line_html" | \
grep 'id="file"' | \
sed 's/<tr>/\n<tr>/g' | \
grep -vi 'yara' | \
awk -F '[<>]' 'BEGIN {print "{"} /^<tr>.*<th>.*<td>[^<]/ {print "\"" $5 "\":\"" $9 "\","} END {print "}"}' | \
tr -d '\n' | \
sed 's/,}/}/g' | \
sed 's/,/,\n/g')

echo "$info" | jq \
--arg hosts "$hosts" \
--arg domains "$domains" \
--arg files "$files" \
--arg registry "$registry" \
--arg mutex "$mutex" \
--arg api "$api" \
'.Hosts = ($hosts | split("\n")) | .Domains = ($domains | split("\n")) | .Files = ($files | split("\n")) | .Registry = ($registry | split("\n")) | .Mutex = ($mutex | split("\n")) | .API = ($api | split("\n"))'
