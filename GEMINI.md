# Project Overview

This project is a collection of scripts for scraping financial data from Turkish websites, primarily TEFAS (Turkey Electronic Fund Distribution Platform). The scripts are written in Bash and Python and are designed to discover and interact with the TEFAS API.

## Key Technologies

*   **Bash:** Used for the main data scraping scripts.
*   **Python:** Used for API endpoint discovery and probing.
*   **curl:** Used for making HTTP requests in the Bash scripts.
*   **jq:** Used for parsing JSON data in the Bash scripts.

## Project Structure

*   `README.md`: Provides an overview of the project and usage instructions for the main scraping scripts.
*   `tefasUrlExploration/`: Contains scripts for discovering and testing API endpoints.
    *   `testScripts/`: Contains the main data scraping scripts.
        *   `tefasBindHistoryInfo.sh`: Fetches general fund information.
        *   `tefasBindHistoryAllocation.sh`: Fetches fund portfolio allocation data.
        *   `tefasGetAllFundAnalyzeData.sh`: Fetches a comprehensive set of fund analysis data.
    *   `tefas_extractor.py`: A Python script for discovering API endpoints from JavaScript files.
    *   `tefas_fuzzy_probe.py` and `tefas_fuzzy_probe_v2.py`: Python scripts for finding hidden API endpoints by generating and testing URL combinations.
    *   `urlListesi.txt`: A text file containing a list of known API endpoints.

## Building and Running

The project does not have a formal build process. The scripts can be run directly from the command line.

### Running the Scraping Scripts

The main scraping scripts are located in the `tefasUrlExploration/testScripts/` directory. They can be run as follows:

```bash
./tefasUrlExploration/testScripts/tefasBindHistoryInfo.sh <fonTip> <basTarih> <bitTarih> <fonKod>
./tefasUrlExploration/testScripts/tefasBindHistoryAllocation.sh <fonTip> <basTarih> <bitTarih> <fonKod>
./tefasUrlExploration/testScripts/tefasGetAllFundAnalyzeData.sh <fonTip> <basTarih> <bitTarih> <fonKod>
```

For more detailed usage instructions, refer to the `README.md` file.

### Running the API Discovery Scripts

The API discovery scripts are located in the `tefasUrlExploration/` directory. They can be run as follows:

```bash
python3 tefasUrlExploration/tefas_extractor.py --base <base_url>
python3 tefasUrlExploration/tefas_fuzzy_probe_v2.py --base <base_url> --wordlist <wordlist_file>
```

## Development Conventions

*   The Bash scripts are well-structured and include error handling.
*   The Python scripts are used for more complex tasks like API discovery.
*   The project uses a combination of Bash and Python to achieve its goals.
