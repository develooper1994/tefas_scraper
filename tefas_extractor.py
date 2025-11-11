#!/usr/bin/env python3
"""
tefas_extractor.py
JS-based endpoint discovery + lightweight probing and example-response extraction.

Usage:
    python3 tefas_extractor.py --base https://www.tefas.gov.tr --max-js 100 --wait 0.5

Produces: results.json and downloaded JS files under js_downloads/
"""
import re
import time
import json
import argparse
import urllib.parse
from pathlib import Path
from collections import OrderedDict

import requests
from requests.exceptions import RequestException

# ---------- Config ----------
DEFAULT_HEADERS = {"User-Agent": "tefas-extractor/1.0 (+https://example.invalid)"}
JS_DIR = Path("js_downloads")
RESULTS_FILE = Path("results.json")
MAX_SAMPLE_BYTES = 100 * 1024  # 100 KB
# --------------------------------

ENDPOINT_PATTERNS = [
    # absolute URLs
    r"https?://[A-Za-z0-9\-\._~:/?#\[\]@!$&'()*+,;=%]+",
    # common API-like relative paths
    r'["\'](/api/[A-Za-z0-9/_\-\.\{\}:]+)["\']',
    r'["\'](/v[0-9]+/[A-Za-z0-9/_\-\.\{\}:]+)["\']',
    r'["\'](/rest/[A-Za-z0-9/_\-\.\{\}:]+)["\']',
    # some servers use /services/... etc
    r'["\'](/(services|svc|ajax)/[A-Za-z0-9/_\-\.\{\}:]+)["\']',
]

PROBE_ACCEPT = {"Accept": "application/json, text/plain, */*"}


def fetch_text(session: requests.Session, url: str, timeout=15):
    r = session.get(url, timeout=timeout)
    r.raise_for_status()
    return r.text, r.headers


def normalize(base: str, url: str):
    return urllib.parse.urljoin(base, url)


def find_js_sources(html: str):
    # extract src attributes ending with .js
    found = re.findall(r'src=["\']([^"\']+\.js(?:\?[^"\']*)?)["\']', html, flags=re.IGNORECASE)
    # inline scripts might contain endpoints too; capture if necessary
    return found


def extract_endpoints_from_text(text: str):
    found = set()
    for pat in ENDPOINT_PATTERNS:
        for m in re.findall(pat, text):
            # if regex returns tuple (when groups), join
            if isinstance(m, tuple):
                m = "".join(m)
            found.add(m)
    # clean and filter obviously-bad matches
    cleaned = set()
    for u in found:
        # ignore data: or javascript: or too short tokens
        if u.startswith("data:") or u.startswith("javascript:") or len(u) < 5:
            continue
        # ignore strings with many { or template placeholders (may be param templates)
        cleaned.add(u)
    return sorted(cleaned)


def probe_endpoint(session: requests.Session, url: str, wait: float = 0.3):
    """
    Make a polite GET probe. Return dict with status, content-type, truncated body (for JSON/text).
    """
    time.sleep(wait)
    try:
        resp = session.get(url, headers={**PROBE_ACCEPT}, timeout=12, allow_redirects=True, stream=True)
    except RequestException as e:
        return {"url": url, "error": str(e)}
    info = {
        "url": url,
        "status_code": resp.status_code,
        "headers": {k: v for k, v in resp.headers.items()},
    }
    ctype = resp.headers.get("Content-Type", "")
    info["content_type"] = ctype
    # if likely JSON or text and small, read up to MAX_SAMPLE_BYTES
    if resp.status_code == 200 and ("application/json" in ctype or ctype.startswith("text") or "json" in ctype):
        try:
            chunk = resp.raw.read(MAX_SAMPLE_BYTES)
            # try decode as text
            try:
                text = chunk.decode(resp.encoding or "utf-8", errors="replace")
            except Exception:
                text = chunk.decode("utf-8", errors="replace")
            # try to parse json if possible to pretty print
            if "json" in ctype:
                try:
                    j = json.loads(text)
                    # pretty but possibly large objects trimmed
                    info["sample_json"] = j
                except Exception:
                    info["sample_text"] = text[: MAX_SAMPLE_BYTES]
            else:
                info["sample_text"] = text[: MAX_SAMPLE_BYTES]
        except Exception as e:
            info["read_error"] = str(e)
    else:
        # not JSON or not 200: do not download body; maybe record length
        info["note"] = "not-downloaded"
    try:
        resp.close()
    except Exception:
        pass
    return info


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--base", required=True, help="Base URL to scan (e.g. https://www.tefas.gov.tr)")
    p.add_argument("--max-js", type=int, default=200, help="Max number of JS files to download")
    p.add_argument("--wait", type=float, default=0.4, help="Seconds to wait between probes (rate-limit)")
    p.add_argument("--only-relative", action="store_true", help="Only keep relative endpoints (optional)")
    args = p.parse_args()

    base = args.base.rstrip("/")
    session = requests.Session()
    session.headers.update(DEFAULT_HEADERS)

    JS_DIR.mkdir(exist_ok=True)

    print("[*] Fetching base page:", base)
    try:
        html, _ = fetch_text(session, base)
    except Exception as e:
        print("ERROR fetching base page:", e)
        return

    js_files = find_js_sources(html)
    print(f"[*] Found {len(js_files)} JS references on page")
    js_files = js_files[: args.max_js]

    # download js files
    downloaded_texts = []
    for j in js_files:
        js_url = normalize(base, j)
        fname = JS_DIR / Path(urllib.parse.urlparse(js_url).path).name
        try:
            txt, _ = fetch_text(session, js_url)
            downloaded_texts.append((js_url, txt))
            with open(fname, "w", encoding="utf-8", errors="replace") as f:
                f.write(txt)
            print(" + downloaded", js_url)
        except Exception as e:
            print(" - failed to download", js_url, e)

    # also scan inline scripts in HTML (in case)
    inline_scripts = re.findall(r'<script[^>]*>(.*?)</script>', html, flags=re.S | re.M | re.I)
    for idx, s in enumerate(inline_scripts[:20]):
        downloaded_texts.append((f"{base}#inline-{idx}", s))

    # extract endpoints
    endpoints = OrderedDict()
    for src, text in downloaded_texts:
        for e in extract_endpoints_from_text(text):
            # normalize relative endpoints
            if e.startswith("http://") or e.startswith("https://"):
                full = e
            else:
                full = normalize(base, e)
            # optional: skip extremely long or obviously template-like URLs
            if "{" in full or "%" in full and len(full) > 500:
                continue
            endpoints[full] = {"discovered_in": src}

    print(f"[*] Discovered {len(endpoints)} candidate endpoints (deduped)")

    # optionally filter only relative ones
    if args.only_relative:
        endpoints = OrderedDict((k, v) for k, v in endpoints.items() if urllib.parse.urlparse(k).netloc == urllib.parse.urlparse(base).netloc)
        print(f"[*] Filtered to {len(endpoints)} endpoints within base domain")

    # probe each endpoint politely
    results = []
    for i, (url, meta) in enumerate(list(endpoints.items())):
        print(f"[{i+1}/{len(endpoints)}] Probing {url}")
        info = probe_endpoint(session, url, wait=args.wait)
        info["discovered_in"] = meta.get("discovered_in")
        results.append(info)

    # write results
    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        json.dump({"base": base, "timestamp": int(time.time()), "results": results}, f, ensure_ascii=False, indent=2)

    print("[*] Done. Results written to", RESULTS_FILE)
    print("Summary:")
    ok = sum(1 for r in results if r.get("status_code") == 200)
    unauthorized = sum(1 for r in results if r.get("status_code") in (401, 403))
    errors = sum(1 for r in results if "error" in r or r.get("status_code") is None)
    print(f"  200 OK: {ok}, 401/403: {unauthorized}, errors: {errors}, total probed: {len(results)}")


if __name__ == "__main__":
    main()
