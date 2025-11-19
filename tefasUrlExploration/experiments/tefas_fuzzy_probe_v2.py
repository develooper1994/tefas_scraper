#!/usr/bin/env python3
"""
tefas_fuzzy_probe_v3.py

Güncelleme:
- error/None/404 cevaplarını otomatik eler.
- elenen kayıtlar rejected.json içine yazılır.
- --exclude-status ile ek statüleri dışlama listesine ekleyebilirsin.

Usage:
  python3 tefas_fuzzy_probe_v3.py --base https://www.tefas.gov.tr --wordlist words.txt --mode random
"""
import argparse, random, time, json, csv
from urllib.parse import urljoin
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from itertools import product

DEFAULT_WORDS = [
    "api","DB","BindFonKarsilastirma","BindHistoryAllocation","fon","fonlar",
    "get","list","search","detail","info","v1","v2","public","data"
]

def normalize_base(u: str) -> str:
    u = u.strip()
    if not u:
        return u
    if not u.startswith("http://") and not u.startswith("https://"):
        u = "https://" + u
    if not u.endswith("/"):
        u = u + "/"
    return u

def generate_combos(words, depth, mode, sample_limit=2000):
    if mode == "sequential":
        for d in range(1, depth+1):
            for tup in product(words, repeat=d):
                yield "/".join(tup)
    else:
        max_iters = sample_limit
        for _ in range(max_iters):
            d = random.randint(1, depth)
            yield "/".join(random.choice(words) for _ in range(d))

def slash_variants(base, combo, yield_set):
    cand = urljoin(base, combo)
    if cand not in yield_set:
        yield_set.add(cand); yield cand
    if not combo.endswith("/"):
        cand = urljoin(base, combo + "/")
        if cand not in yield_set:
            yield_set.add(cand); yield cand
    if not combo.startswith("/"):
        cand = urljoin(base, "/" + combo)
        if cand not in yield_set:
            yield_set.add(cand); yield cand
    parts = combo.split("/")
    for i in range(len(parts)):
        if random.random() < 0.25:
            parts_copy = list(parts)
            parts_copy.insert(i, "")
            variant = "/".join(parts_copy)
            cand = urljoin(base, variant)
            if cand not in yield_set:
                yield_set.add(cand); yield cand
    if random.random() < 0.05:
        cand = urljoin(base, "../" + combo)
        if cand not in yield_set:
            yield_set.add(cand); yield cand

def generate_urls(bases, words, max_depth, mode, cap):
    seen = set()
    produced = 0
    for base in bases:
        for combo in generate_combos(words, max_depth, mode):
            for url in slash_variants(base, combo, seen):
                yield url
                produced += 1
                if cap and produced >= cap:
                    return

def polite_probe(session, url, timeout=12, max_sample=20000):
    try:
        resp = session.get(url, timeout=timeout, allow_redirects=True,
                           headers={"User-Agent":"fuzzy-probe/3.0","Accept":"application/json,text/plain,*/*"})
    except Exception as e:
        return {"url": url, "error": str(e), "status": None}
    info = {"url": url, "status": resp.status_code, "content_type": resp.headers.get("Content-Type","")}
    try:
        if resp.status_code == 200 and ("json" in info["content_type"].lower() or "text" in info["content_type"].lower()):
            info["sample"] = resp.text[:max_sample]
        else:
            info["sample"] = None
    except Exception as e:
        info["sample_error"] = str(e)
    finally:
        try: resp.close()
        except: pass
    return info

def should_reject(record, exclude_statuses):
    # Reject if probe returned 'error' key or status is None or in exclude list (e.g., 404)
    if record is None:
        return True
    if record.get("error"):
        return True
    st = record.get("status")
    if st is None:
        return True
    if st in exclude_statuses:
        return True
    return False

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--base", help="Single base URL (e.g. https://www.tefas.gov.tr/)")
    p.add_argument("--bases", help="File with base URLs, one per line")
    p.add_argument("--wordlist", help="File with wordlist, one per line")
    p.add_argument("--mode", choices=("sequential","random"), default="random", help="Try order for words")
    p.add_argument("--max-depth", type=int, default=2)
    p.add_argument("--max-requests", type=int, default=300)
    p.add_argument("--threads", type=int, default=6)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--out-json", default="results.json")
    p.add_argument("--out-csv", default="results.csv")
    p.add_argument("--rejected-json", default="rejected.json")
    p.add_argument("--exclude-status", help="Comma-separated statuses to exclude (default: 404). Example: --exclude-status 404,410", default="404")
    args = p.parse_args()

    bases = []
    if args.base:
        bases.append(normalize_base(args.base))
    if args.bases:
        txt = Path(args.bases).read_text(encoding="utf-8")
        for line in txt.splitlines():
            line=line.strip()
            if line:
                bases.append(normalize_base(line))
    if not bases:
        print("No base provided. Use --base or --bases"); return

    if args.wordlist:
        words = [l.strip() for l in Path(args.wordlist).read_text(encoding="utf-8").splitlines() if l.strip()]
    else:
        words = DEFAULT_WORDS[:]

    if args.mode == "random":
        random.shuffle(words)

    exclude_statuses = set()
    for s in (args.exclude_status or "").split(","):
        s = s.strip()
        if not s:
            continue
        try:
            exclude_statuses.add(int(s))
        except:
            pass
    # always exclude None and treat 'error' as excluded implicitly

    print(f"[+] Bases: {bases}")
    print(f"[+] Words count: {len(words)}, mode: {args.mode}, max_depth: {args.max_depth}")
    print(f"[+] Max requests: {args.max_requests}, threads: {args.threads}")
    print(f"[+] Excluding statuses: {sorted(list(exclude_statuses))} plus errors/None (implicit)")

    if args.dry_run:
        i = 0
        for u in generate_urls(bases, words, args.max_depth, args.mode, args.max_requests):
            print(u)
            i += 1
            if i >= args.max_requests: break
        print(f"Dry-run produced {i} URLs."); return

    session = requests.Session()
    session.headers.update({"User-Agent":"fuzzy-probe/3.0"})

    results = []
    rejected = []
    tot = 0
    with ThreadPoolExecutor(max_workers=args.threads) as ex:
        futures = {}
        for url in generate_urls(bases, words, args.max_depth, args.mode, args.max_requests):
            if tot >= args.max_requests:
                break
            time.sleep(random.uniform(0.02, 0.25))
            fut = ex.submit(polite_probe, session, url)
            futures[fut] = url
            tot += 1

        for f in as_completed(list(futures.keys())):
            try:
                info = f.result()
            except Exception as e:
                info = {"url": futures.get(f, "unknown"), "error": str(e), "status": None}
            # decide accept/reject
            if should_reject(info, exclude_statuses):
                rejected.append(info)
            else:
                results.append(info)
            time.sleep(random.uniform(0.01, 0.12))

    # write accepted results
    with open(args.out_json, "w", encoding="utf-8") as jf:
        json.dump({"meta": {"bases": bases, "words": len(words), "mode": args.mode, "scanned": len(results)}, "results": results}, jf, ensure_ascii=False, indent=2)

    # CSV summary for accepted
    with open(args.out_csv, "w", encoding="utf-8", newline='') as cf:
        w = csv.writer(cf)
        w.writerow(["url","status","content_type","snippet"])
        for r in results:
            url = r.get("url","")
            status = r.get("status","")
            ct = r.get("content_type","")
            snip = ""
            if r.get("sample"):
                snip = r.get("sample")[:200].replace("\n"," ")
            w.writerow([url,status,ct,snip])

    # write rejected list for review
    with open(args.rejected_json, "w", encoding="utf-8") as rf:
        json.dump({"meta": {"total_rejected": len(rejected)}, "rejected": rejected}, rf, ensure_ascii=False, indent=2)

    print(f"Done. Accepted: {len(results)} saved to {args.out_json}, Rejected: {len(rejected)} saved to {args.rejected_json}")

if __name__ == "__main__":
    main()
