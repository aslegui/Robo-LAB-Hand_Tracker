extends Node

@export var port := 9005
@export var debug_print_packets := true

var udp := PacketPeerUDP.new()
var latest: Dictionary = {}

func _ready():
	# Bind sin IP => escucha en todas las interfaces (más robusto)
	var err = udp.bind(port)
	if err != OK:
		push_error("UDP bind error: %s" % err)
		return

	print("Listening UDP on *:%d" % port)

func _process(_dt):
	while udp.get_available_packet_count() > 0:
		var pkt: PackedByteArray = udp.get_packet()

		if udp.get_packet_error() != OK:
			push_warning("UDP packet error: %s" % udp.get_packet_error())
			continue

		#if debug_print_packets:
		#	print("UDP got bytes:", pkt.size())

		var txt := pkt.get_string_from_utf8()
		var data = JSON.parse_string(txt)

		if typeof(data) == TYPE_DICTIONARY:
			latest = data
		else:
			if debug_print_packets:
				push_warning("UDP: JSON inválido o no Dictionary")
