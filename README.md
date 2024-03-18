# fanet

filfreire's FANET (Flying Ad-Hoc Network) experiment for ns2 network simulator.

Created in the context of laboratory coursework for UALG's Master in Informatics Wireless Networks course, March 2024.

Report can be found [here (PDF format)](/report.pdf).

## Prerequisites

- Install ns-2. Follow guide over at <https://filfreire.com/ns2>
  - Make sure `ns` is in your PATH
- Patch ns-2 installation to add M2ANET and UM-OLSR. Follow guide over at <https://filfreire.com/ns2-fanet>
- Clone this repository, e.g. `git clone https://github.com/filfreire/fanet.git` and switch to `fanet/` folder.

This repository was tested on Ubuntu 22.04 virtual machine, and requires ns-2.35 with the patches mentioned above.

## How to run

Open terminal and try to run the simulation script:

```bash
# ns <script.tcl> <routing_protocol> <num_nodes> <time_duration> <gridSize> <random_seed>
# example:
ns fanet-lab2-filfreire-3d.tcl DSR 20 600 5000 1
```

### Using makefile

To run multiple number of nodes, with multiple random seeds, you can use the [makefile](/makefile) present in this repository. Replace the config parameters according to your needs:

```make
RESULTS_FOLDER = /media/frodo/data
MIN_NODES = 20
MAX_NODES = 50
NODES_INCREMENT = 10
MAX_RANDOM_SEEDS = 30
TIME_DURATION = 600
GRID_SIZE = 5000
DIST_BETWEEN_NODES = 200
```

Then run the simulations either for AODV, DSDV and DSR:

```bash
make fanet-3d
```

Or run the simulations for OLSR (separate make ):

```bash
make fanet-3d-olsr
```

To place results into a CSV run:

```bash
# parse AODV, DSDV and DSR results
make fanet-3d-csv

# parse OLSR results
make fanet-3d-csv-olsr
```

> Tip: you can save these into a `.csv`/`.txt` file to perform statistical analysis on results.

```bash
make fanet-3d-csv > results.csv
```

## Data analysis

Example experiment data, used in the [report](/report.pdf) is available in [](/data-analysis/results-fanet-total.txt).

All data analysis was done in [Jupyter Notebooks](https://jupyter.org/) and is provided as-is in the [data-analysis/](/data-analysis/) folder.
