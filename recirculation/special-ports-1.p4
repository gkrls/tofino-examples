#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<16> eth_type_t;

header ethernet_h {
  mac_addr_t dst_addr;
  mac_addr_t src_addr;
  eth_type_t ether_type;
}

header recirc_h {
  bit<32> steps; // recirculate steps - 1 times
  bit<16> pipe0;
  bit<16> pipe1;
  bit<16> pipe2;
  bit<16> pipe3;
}

// Internal header used
header bridge_h {
  bit<32> remaining;
  PortId_t initial_port;
  bit<7> _pad_1;
}

struct header_t {
  ethernet_h eth;
  recirc_h recirc;
  bridge_h bridge;
}

#include "util.p4"

//       0x000 &&& 0x180: accept; // all pipe 0 ports
parser IngressParser( packet_in P,
                      out header_t H, out empty_metadata_t M,
                      out ingress_intrinsic_metadata_t IM) {
  state start {
    TofinoIngressParser.apply(P, IM);
    P.extract(H.eth);
    P.extract(H.recirc);
    transition select(IM.ingress_port) {
             68 .. 71: parse_bridge;
           192 .. 199: parse_bridge;
           324 .. 437: parse_bridge;
           448 .. 455: parse_bridge;
              default: accept;
    }
  }
  state parse_bridge {
    P.extract(H.bridge);
    transition accept;
  }
}

control Ingress(inout header_t H, inout empty_metadata_t M,
                in ingress_intrinsic_metadata_t IM,
                in ingress_intrinsic_metadata_from_parser_t PIM,
                inout ingress_intrinsic_metadata_for_deparser_t DIM,
                inout ingress_intrinsic_metadata_for_tm_t TIM) {
  bit<2> pipe;

  action record_0() { H.recirc.pipe0 = H.recirc.pipe0 + 1; }
  action record_1() { H.recirc.pipe1 = H.recirc.pipe1 + 1; }
  action record_2() { H.recirc.pipe2 = H.recirc.pipe2 + 1; }
  action record_3() { H.recirc.pipe3 = H.recirc.pipe3 + 1; }

  table record {
    key = {pipe: exact;}
    actions = {record_0; record_1; record_2; record_3; NoAction;}
    const size = 4;
    const entries = {
      0 : record_0(); 1 : record_1(); 2 : record_2(); 3 : record_3();
    }
  }

  action reflect() {
    mac_addr_t tmp = H.eth.dst_addr;
    H.eth.dst_addr = H.eth.src_addr;
    H.eth.src_addr = tmp;
    TIM.ucast_egress_port = H.bridge.initial_port;
    // Make the bridge header invalid so that the
    // deparser does not emit it
    H.bridge.setInvalid();
  }

  action pipe0_to_pipe1() { TIM.ucast_egress_port = 196; }
  action pipe1_to_pipe2() { TIM.ucast_egress_port = 324; }
  action pipe2_to_pipe3() { TIM.ucast_egress_port = 452; }
  action pipe3_to_pipe0() { TIM.ucast_egress_port = 68;  }

  table forward {
    key = {pipe: ternary; H.bridge.remaining : ternary;}
    actions = {reflect;NoAction;
               pipe0_to_pipe1; pipe1_to_pipe2;
               pipe2_to_pipe3; pipe3_to_pipe0;}
    const size = 5;
    const default_action = NoAction;
    const entries = {
      (_, 0) : reflect();
      (0, _) : pipe0_to_pipe1();
      (1, _) : pipe1_to_pipe2();
      (2, _) : pipe2_to_pipe3();
      (3, _) : pipe3_to_pipe0();
    }
  }

  apply {
    pipe = IM.ingress_port[8:7];

    if (!H.bridge.isValid()) {
      H.bridge.setValid();
      H.bridge.initial_port = IM.ingress_port;
      H.bridge.remaining = H.recirc.steps - 1;
    } else {
      H.bridge.remaining = H.bridge.remaining - 1;
    }

    record.apply();
    forward.apply();
  }
}

Pipeline( IngressParser(), Ingress(), DefaultIngressDeparser(),
          DefaultEgressParser(), EmptyEgress(), DefaultEgressDeparser()) pipe;

Switch(pipe) main;