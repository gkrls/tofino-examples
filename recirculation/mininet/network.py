from p4utils.utils.compiler import BF_P4C
from p4utils.mininetlib.network_API import NetworkAPI

import argparse, os, sys

parser = argparse.ArgumentParser()
parser.add_argument('-sde', type=str, default=os.environ['SDE'] if 'SDE' in os.environ else "")
parser.add_argument('program', type=str, default=None)
args = parser.parse_args()

assert os.path.exists(args.sde) and os.path.isdir(args.sde), 'coult not find SDE'
assert os.path.exists(args.program) and os.path.isfile(args.program), 'could not file program'

SDE = os.path.abspath(args.sde)
SDE_INSTALL = os.path.join(SDE, "install")
PROG = os.path.abspath(args.program)


net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()

# Tofino compiler
net.setCompiler(compilerClass=BF_P4C, sde=SDE, sde_install=SDE_INSTALL)

# Network definition
net.addTofino('s1', sde=SDE, sde_install=SDE_INSTALL, mac="10:10:10:10:10:10", ip="10.10.10.10")
net.setP4Source('s1', PROG)
net.addHost('h1', ip="10.0.0.1")
net.addLink('h1', 's1', port2=1)
net.setIntfMac('h1', 's1', mac="00:00:00:00:00:01")

net.enableLogAll()

net.disableArpTables()

# Start the network
net.startNetwork()