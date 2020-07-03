# Covid preprint screening workflow 
This workflow integrates all necessary steps to generate weekly lists of biorxiv and medrxiv preprints and downloads PDFs & text for screening with different tools.

## Current workflow

- run_scripts.R creates folders for the weekly batch and results and runs all the necessary subscripts

### Generation of weekly list & download of preprints
1. download current JSON metadata file from biorxiv and generate weekly filtered list
2. download PDFs of preprints
3. download full text from HTML version for biorxiv preprints (forked from https://github.com/PeterEckmann1/biorxiv-extractor)

### Scripts that run the different tools

### ODDPub (https://github.com/quest-bih/oddpub)
4. Run ODDPub on preprint full texts
5. Retrieve data availibility statements (DAS) fields from medrxiv
6. Run ODDPub on the DAS and combine the results

### Barzooka
7. Run Barzooka - not yet fully integrated into the workflow, as it needs some additional components to run
