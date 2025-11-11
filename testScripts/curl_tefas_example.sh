#!/bin/bash

curl -X POST "https://www.tefas.gov.tr/api/DB/BindHistoryInfo" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "Origin: https://www.tefas.gov.tr" \
  -H "Referer: https://www.tefas.gov.tr/TarihselVeriler.aspx" \
  -H "X-Requested-With: XMLHttpRequest" \
  -d "fontip=YAT&bastarih=10.11.2025&bittarih=10.11.2025&fonkod="
