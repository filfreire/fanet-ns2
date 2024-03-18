BEGIN {
	receivedFanet = 0
	sentFanet = 0
	ratioFanet = 0
	packetLoss = 0
}

{
	if($1 == "s" && $3 == "_0_" && $4 == "AGT") {
		sentFanet++
	}
	if($1 == "r" && $3 == receiverNode && $4 == "AGT") {
		receivedFanet++
	}
}

END {
	ratioFanet = ((sentFanet - receivedFanet) / sentFanet) * 100
	packetLoss = sentFanet - receivedFanet
	printf("\nrp %s, nn %d, random seed %d, Received: %d | Sent: %d | Dropped: %d, PLR: %f%", rp, nn, seed, receivedFanet, sentFanet, packetLoss, ratioFanet)
}