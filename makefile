# replace this with the folder you want to store .tr and .nam results into:
RESULTS_FOLDER = /media/frodo/data
MIN_NODES = 20
MAX_NODES = 50
NODES_INCREMENT = 10
MAX_RANDOM_SEEDS = 30
TIME_DURATION = 600
GRID_SIZE = 5000
DIST_BETWEEN_NODES = 200

fanet-3d:
	@seq $(MIN_NODES) $(NODES_INCREMENT) $(MAX_NODES) | while read num; do \
		seq 1 $(MAX_RANDOM_SEEDS) | while read seed; do \
			echo AODV $$num $(TIME_DURATION) $(GRID_SIZE) $$seed $(DIST_BETWEEN_NODES) $(RESULTS_FOLDER); \
			echo DSDV $$num $(TIME_DURATION) $(GRID_SIZE) $$seed $(DIST_BETWEEN_NODES) $(RESULTS_FOLDER); \
			echo DSR $$num $(TIME_DURATION) $(GRID_SIZE) $$seed $(DIST_BETWEEN_NODES) $(RESULTS_FOLDER); \
		done; \
	done | xargs -P `nproc` -I {} bash -c 'ns fanet-lab2-filfreire-3d.tcl {} > /dev/null'

fanet-3d-csv:
	@seq $(MIN_NODES) $(NODES_INCREMENT) $(MAX_NODES) | while read num; do \
		seq 1 $(MAX_RANDOM_SEEDS) | while read seed; do \
			awk -v rp="AODV" -v nn=$${num} -v seed=$${seed} -v receiverNode="_$$(($$num-1))_" -f fanet-csv.awk $(RESULTS_FOLDER)/fanet_aodv_nn$${num}_t$(TIME_DURATION)_seed$${seed}.tr ; \
			awk -v rp="DSDV" -v nn=$${num} -v seed=$${seed} -v receiverNode="_$$(($$num-1))_" -f fanet-csv.awk $(RESULTS_FOLDER)/fanet_dsdv_nn$${num}_t$(TIME_DURATION)_seed$${seed}.tr ; \
			awk -v rp="DSR" -v nn=$${num} -v seed=$${seed} -v receiverNode="_$$(($$num-1))_" -f fanet-csv.awk $(RESULTS_FOLDER)/fanet_dsr_nn$${num}_t$(TIME_DURATION)_seed$${seed}.tr ; \
		done; \
	done

fanet-3d-olsr:
	@seq $(MIN_NODES) $(NODES_INCREMENT) $(MAX_NODES) | while read num; do \
		seq 1 $(MAX_RANDOM_SEEDS) | while read seed; do \
			echo OLSR $$num $(TIME_DURATION) $(GRID_SIZE) $$seed $(DIST_BETWEEN_NODES) $(RESULTS_FOLDER); \
		done; \
	done | xargs -P `nproc` -I {} bash -c 'ns fanet-lab2-filfreire-3d.tcl {} > /dev/null'

fanet-3d-csv-olsr:
	@seq $(MIN_NODES) $(NODES_INCREMENT) $(MAX_NODES) | while read num; do \
		seq 1 $(MAX_RANDOM_SEEDS) | while read seed; do \
			awk -v rp="OLSR" -v nn=$${num} -v seed=$${seed} -v receiverNode="_$$(($$num-1))_" -f fanet-csv.awk $(RESULTS_FOLDER)/fanet_olsr_nn$${num}_t$(TIME_DURATION)_seed$${seed}.tr ; \
		done; \
	done

clean:
	rm -rf *.nam *.tr
	rm -rf results/*.nam results/*.tr
	rm -rf $(RESULTS_FOLDER)/*.nam $(RESULTS_FOLDER)/*.tr