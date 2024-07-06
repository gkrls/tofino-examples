import argparse
import os
import sys
import json
from scapy.all import IntField, ShortField, XByteField, FieldListField
from scapy.all import Packet, Ether, bind_layers, srp1
import pprint
import psutil

RECIRC_ETHERTYPE = 0x8888
SWITCH_MAC = "10:10:10:10:10:10"

class Recirc(Packet):
    name = "recirc"
    fields_desc = [
        IntField('steps', 0),
        FieldListField("pipes", [0,0,0,0], ShortField("p", 0), count_from=lambda p: 4),
    ]

bind_layers(Ether, Recirc, type=RECIRC_ETHERTYPE)



print("\nGive the number of steps or type 'q'/'quit' to quit...\n")

def path(pipes):
    res = []
    s = 0
    stop = False
    while True:
        for pipe in range(4):
            if pipes[pipe] == 0:
                stop = True
                break
            res.append(pipe)
            pipes[pipe] -= 1
        if stop:
            break
    return res

while(True):
    s = input("steps: ")
    if s in ['quit', 'q']:
        break
    try:
        steps = int(s)
    except:
        print("error: invalid input")
        continue

    if steps < 1:
        print("error: must be positive")
        continue

    p_out = Ether(dst=SWITCH_MAC, type=RECIRC_ETHERTYPE) / Recirc(steps=steps)
    p_in = srp1(p_out, iface='h1-eth0', verbose=False)

    if p_in:
        if p_in[Recirc]:
            # p_in[Recirc].show()
            p = path(p_in[Recirc].pipes)
            print('pipes:', " > ".join(map(str, p)), "-> EGRESS")
        else:
            print("Got response without recirc!!!!")
    else:
        print("Timeout...")

