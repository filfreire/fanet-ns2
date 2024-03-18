#Copyright (c) 2024 Filipe Freire

# check if we have at least seven arguments
if {$argc < 7} {
    puts "Usage: ns <script.tcl> <routing_protocol> <num_nodes> <time_duration> <gridSize> <random_seed> <dist_between_nodes> <results_folder>"
	puts "Example: ns fanet-lab2-filfreire.tcl AODV 7 600 5000 1 100 /media/frodo/data"
	puts "Supported routing protocols: DSDV DSR AODV"
    exit
}

# input arguments
set routing_protocol [lindex $argv 0]
set trace_file_suffix [string tolower $routing_protocol]
set num_nodes [lindex $argv 1]
set time_duration [lindex $argv 2]
set gridSize [lindex $argv 3]
set random_seed [lindex $argv 4]
set dist_between_nodes [lindex $argv 5]
set results_folder [lindex $argv 6]
expr {srand($random_seed)}; # set random seed

# change Queue type depending on routing_protocol
if { $routing_protocol == "DSR" } {
    set queue_type "CMUPriQueue"
} elseif { $routing_protocol == "AODV" } {
    set queue_type "Queue/DropTail/PriQueue"
} elseif { $routing_protocol == "DSDV" } {
    set queue_type "Queue/DropTail/PriQueue"
} elseif { $routing_protocol == "OLSR" } {
    set queue_type "Queue/DropTail/PriQueue"
} else {
    puts "Error: Unsupported routing protocol $routing_protocol"
    exit
}

## ns specific args
set val(chan)           Channel/WirelessChannel    ;#Channel Type
set val(prop)           Propagation/FreeSpace      ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            ${queue_type}    		   ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             ${num_nodes}           	   ;# number of flying nodes
set val(rp)             ${routing_protocol}        ;# routing protocol
set val(stop)           ${time_duration}           ;# Simulation time (adjusted to 1500)
set val(x)				${gridSize}                ;
set val(y)				${gridSize}                ;
set val(z)				${gridSize}                ;

# custom fanet arguments
set grid_resolution     1       ;# topo grid resolution
set altitude			400.0   ;# altitude fixed at 400 units for now
set speed				2       ;# speed nodes can move when moving randomly
set node_size			1       ;# size of each node (e.g. small UAV measuring 1 unit)
set random_motion 		1       ;# random motion enabled
set max_move 			5       ;# max distance a node can move randomly
set time_step 			15      ;# time between set another random destination for a node
set cbr_packet_size 	512     ;# cbr packet size
set cbr_time_interval 	0.1     ;# time between cbr packet transmission

#helper functions ##########################################################
# Calculate a new position within the move range, ensuring it's within the grid
proc calculateNewRandomPosition {x_pos y_pos max_move gridSize buffer} {
    set move_x [expr {rand() * (2 * $max_move) - $max_move}]
    set move_y [expr {rand() * (2 * $max_move) - $max_move}]
    set new_x [expr {max($buffer, min($x_pos + $move_x, $gridSize - $buffer))}]
    set new_y [expr {max($buffer, min($y_pos + $move_y, $gridSize - $buffer))}]
    return [list $new_x $new_y]
}
#############################################################################

# Initialize ns-2 Global Variables
set ns_		[new Simulator]

if { $routing_protocol == "OLSR" } {
    Agent/OLSR set use_mac_ true
}

set tracefd     [open ${results_folder}/fanet_${trace_file_suffix}_nn${num_nodes}_t${time_duration}_seed${random_seed}.tr w]
$ns_ trace-all $tracefd

set namtrace [open ${results_folder}/fanet_${trace_file_suffix}_nn${num_nodes}_t${time_duration}_seed${random_seed}.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

set topo       [new Topography]
$topo load_cube $val(x) $val(y) $val(z) $grid_resolution

create-god $val(nn);

set chan_1_ [new $val(chan)]
set chan_2_ [new $val(chan)]

# Configure ns Nodes
$ns_ node-config -adhocRouting $val(rp) \
		-llType $val(ll) \
		-macType $val(mac) \
		-ifqType $val(ifq) \
		-ifqLen $val(ifqlen) \
		-antType $val(ant) \
		-propType $val(prop) \
		-phyType $val(netif) \
		-topoInstance $topo \
		-agentTrace ON \
		-routerTrace OFF \
		-macTrace OFF \
		-movementTrace OFF \
		-channel $chan_1_

# Set parameters
set max_distance ${dist_between_nodes}      ;# Maximum distance in x or y direction
set buffer 25              					;# Buffer from the edge of the grid

# Calculate the number of rows and columns for the nodes
set rows [expr {int(sqrt($num_nodes))}]
set cols [expr {int(ceil(double($num_nodes) / $rows))}]

# Calculate division size based on the constraints
set division_size_x $max_distance
set division_size_y $max_distance

# Calculate starting positions to center the grid
set start_x [expr {($gridSize - ($cols - 1) * $division_size_x) / 2.0}]
set start_y [expr {($gridSize - ($rows - 1) * $division_size_y) / 2.0}]

# Create nodes and position them in the grid
for {set i 0} {$i < $num_nodes} {incr i} {
    set node_($i) [$ns_ node]
	$node_($i) random-motion $random_motion
	$ns_ initial_node_pos $node_($i) $node_size

    # Calculate grid positions of i-th node
    set col [expr {$i % $cols}]
    set row [expr {$i / $cols}]

    set x_pos [expr {$start_x + $col * $division_size_x}]
    set y_pos [expr {$start_y + $row * $division_size_y}]

    # Set initial position at time 0
    $node_($i) set X_ $x_pos
    $node_($i) set Y_ $y_pos
    $node_($i) set Z_ $altitude
    $ns_ at 0.0 "$node_($i) setdest3d $x_pos $y_pos $altitude 0"

	# every time_step seconds set another random destination
	for {set t 0} {$t < $time_duration} {incr t $time_step} {
		# Calculate a new position within the grid for the node to move to
		set new_position [calculateNewRandomPosition $x_pos $y_pos $max_move $gridSize $buffer]
		set new_x [lindex $new_position 0]
		set new_y [lindex $new_position 1]
		# Schedule the node to move to the new position at next time step
		$ns_ at $t "$node_($i) setdest3d $new_x $new_y $altitude $speed"
	}
}

# Setup traffic flow from the first node to the last node
set udp [new Agent/UDP]
$ns_ attach-agent $node_(0) $udp
set null [new Agent/Null]
$ns_ attach-agent $node_([expr $val(nn) - 1]) $null
$ns_ connect $udp $null
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ $cbr_packet_size
$cbr set interval_ $cbr_time_interval
$cbr attach-agent $udp
$ns_ at 2.0 "$cbr start"
$ns_ at $val(stop) "$cbr stop"
$ns_ at $val(stop) "stop"
$ns_ at $val(stop).01 "puts \"NS EXITING...\" ; $ns_ halt"

proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    close $tracefd
}

puts "Starting Simulation..."
$ns_ run
puts "Done..."