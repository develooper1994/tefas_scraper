#!/usr/bin/env python3
import sys
import json
import traceback
import argparse
from fastapi import FastAPI, Query, HTTPException
from typing import Optional
from scraper import TefasScraper

# --- FastAPI App Definition ---
app = FastAPI(
    title="Tefas Scraper API",
    description="API for scraping financial data from TEFAS.",
    version="1.0.0",
)

scraper = TefasScraper()

@app.get("/")
async def read_root():
    return {"message": "Welcome to the Tefas Scraper API. Go to /docs for API documentation."}

@app.get("/analyze", summary="Get comprehensive fund analysis data")
async def get_all_fund_analyze_data(
    fund_type: str = Query(..., description="Fund type (e.g., YAT, EMK)"),
    fund_code: str = Query(..., description="Fund code (e.g., TLY, AFA)"),
    start_date: Optional[str] = Query(None, description="Start date (DD.MM.YYYY format)"),
    end_date: Optional[str] = Query(None, description="End date (DD.MM.YYYY format)"),
    price_range: Optional[str] = Query(None, description="Price range (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y)."),
):
    try:
        return scraper.get_fund_analysis(fund_type, fund_code, start_date, end_date, price_range)
    except (ValueError, Exception) as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history-info", summary="Get historical fund information")
async def get_fund_history_info(
    fund_code: str = Query(..., description="TEFAS fund code (e.g., 'AFA', 'TCD')"),
    start_date: str = Query(..., description="Start date in YYYY-MM-DD format (e.g., '2023-01-01')"),
    end_date: str = Query(..., description="End date in YYYY-MM-DD format (e.g., '2023-12-31')"),
    fund_type: str = Query("ALL", description="Fund type (e.g., 'DEBT', 'EQUITY'). Default is 'ALL'."),
):
    try:
        return scraper.get_history("BindHistoryInfo", fund_code, start_date, end_date, fund_type)
    except (ValueError, Exception) as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history-allocation", summary="Get fund portfolio allocation data")
async def get_fund_history_allocation(
    fund_code: str = Query(..., description="TEFAS fund code (e.g., 'AFA', 'TCD')"),
    start_date: str = Query(..., description="Start date in YYYY-MM-DD format (e.g., '2023-01-01')"),
    end_date: str = Query(..., description="End date in YYYY-MM-DD format (e.g., '2023-12-31')"),
    fund_type: str = Query("ALL", description="Fund type (e.g., 'DEBT', 'EQUITY'). Default is 'ALL'."),
):
    try:
        return scraper.get_history("BindHistoryAllocation", fund_code, start_date, end_date, fund_type)
    except (ValueError, Exception) as e:
        raise HTTPException(status_code=400, detail=str(e))


# --- Stdio JSON-RPC Server (for reference, will not be active in HTTP mode) ---

# Definition of the tools for the client
TEFAS_TOOLS = [
    {
        "name": "analyze",
        "description": "Fetches comprehensive fund analysis data.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "fund_type": {"type": "string", "description": "Fund type (e.g., YAT, EMK)."},
                "fund_code": {"type": "string", "description": "Fund code (e.g., TLY, AFA)."},
                "start_date": {"type": "string", "description": "Start date (DD.MM.YYYY format)."},
                "end_date": {"type": "string", "description": "End date (DD.MM.YYYY format)."},
                "price_range": {"type": "string", "description": "Price range (1H, 1M, 3M, 6M, YTD, 1Y, 3Y, 5Y)."}
            },
            "required": ["fund_type", "fund_code"]
        }
    },
    {
        "name": "history-info",
        "description": "Fetches historical binding information for a TEFAS fund.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "fund_code": {"type": "string", "description": "TEFAS fund code (e.g., 'AFA', 'TCD')."},
                "start_date": {"type": "string", "description": "Start date in YYYY-MM-DD format."},
                "end_date": {"type": "string", "description": "End date in YYYY-MM-DD format."},
                "fund_type": {"type": "string", "description": "Fund type (e.g., 'DEBT', 'EQUITY'). Default is 'ALL'."}
            },
            "required": ["fund_code", "start_date", "end_date"]
        }
    },
    {
        "name": "history-allocation",
        "description": "Fetches historical binding allocation information for a TEFAS fund.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "fund_code": {"type": "string", "description": "TEFAS fund code (e.g., 'AFA', 'TCD')."},
                "start_date": {"type": "string", "description": "Start date in YYYY-MM-DD format."},
                "end_date": {"type": "string", "description": "End date in YYYY-MM-DD format."},
                "fund_type": {"type": "string", "description": "Fund type (e.g., 'DEBT', 'EQUITY'). Default is 'ALL'."}
            },
            "required": ["fund_code", "start_date", "end_date"]
        }
    }
]

def initialize(**kwargs):
    return {
        "capabilities": {
            "toolsProvider": {
                "supportsToolDiscovery": True
            }
        },
        "serverInfo": {
            "name": "tefas-scraper",
            "version": "1.0.0"
        }
    }

def tools_list():
    return {"tools": TEFAS_TOOLS}


def handle_stdio():
    method_map = {
        "initialize": initialize,
        "tools/list": tools_list,
        "analyze": scraper.get_fund_analysis,
        "history-info": lambda **params: scraper.get_history("BindHistoryInfo", **params),
        "history-allocation": lambda **params: scraper.get_history("BindHistoryAllocation", **params)
    }

    while True:
        line = sys.stdin.readline()
        if not line:
            break

        try:
            request = json.loads(line)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params", {})

            if isinstance(params, list) and len(params) > 0 and isinstance(params[0], dict):
                 params = params[0]
            elif not isinstance(params, dict):
                params = {}
            
            if method in method_map:
                try:
                    result = method_map[method](**params)
                    response = {"jsonrpc": "2.0", "id": request_id, "result": result}
                except Exception as e:
                    response = {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32000, "message": str(e), "data": traceback.format_exc()}}
            else:
                response = {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32601, "message": f"Method not found: {method}"}}
        except json.JSONDecodeError:
            response = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}}
        except Exception as e:
            response = {"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": "Internal error", "data": str(e)}}
            
        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()


# --- Main Entry Point ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tefas Scraper server.")
    parser.add_argument(
        '--transport',
        type=str,
        default='http',
        choices=['http', 'stdio'],
        help='The transport protocol to use (http or stdio).'
    )
    args = parser.parse_args()

    if args.transport == 'http':
        import uvicorn
        uvicorn.run(app, host="0.0.0.0", port=8000)
    elif args.transport == 'stdio':
        handle_stdio()
    else:
        print(f"Unknown transport: {args.transport}", file=sys.stderr)
        sys.exit(1)