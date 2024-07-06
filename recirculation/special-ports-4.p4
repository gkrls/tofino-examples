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

// Internal header used to carry state between recirculations
// Must be padded for byte alignment
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

parser Pipe0_IngressParser( packet_in P,
                           out header_t H, out empty_metadata_t M,
                           out ingress_intrinsic_metadata_t IM) {
  state start {
    TofinoIngressParser.apply(P, IM);
    P.extract(H.eth);
    P.extract(H.recirc);
    transition select(IM.ingress_port) {
      68 .. 71: parse_bridge;
       default: accept;
    }
  }
  state parse_bridge { P.extract(H.bridge); transition accept; }
}

parser Pipe1_IngressParser( packet_in P,
                           out header_t H, out empty_metadata_t M,
                           out ingress_intrinsic_metadata_t IM) {
  state start {
    TofinoIngressParser.apply(P, IM);
    P.extract(H.eth);
    P.extract(H.recirc);
    transition select(IM.ingress_port) {
      192 .. 199: parse_bridge;
         default: accept;
    }
  }
  state parse_bridge { P.extract(H.bridge); transition accept; }
}

parser Pipe2_IngressParser( packet_in P,
                           out header_t H, out empty_metadata_t M,
                           out ingress_intrinsic_metadata_t IM) {
  state start {
    TofinoIngressParser.apply(P, IM);
    P.extract(H.eth);
    P.extract(H.recirc);
    transition select(IM.ingress_port) {
      324 .. 437: parse_bridge;
         default: accept;
    }
  }
  state parse_bridge { P.extract(H.bridge); transition accept; }
}

parser Pipe3_IngressParser( packet_in P,
                           out header_t H, out empty_metadata_t M,
                           out ingress_intrinsic_metadata_t IM) {
  state start {
    TofinoIngressParser.apply(P, IM);
    P.extract(H.eth);
    P.extract(H.recirc);
    transition select(IM.ingress_port) {
      448 .. 455: parse_bridge;
         default: accept;
    }
  }
  state parse_bridge { P.extract(H.bridge); transition accept; }
}

control State(inout header_t H, in ingress_intrinsic_metadata_t IM) {
  apply {
    if (!H.bridge.isValid()) {
      H.bridge.setValid();
      H.bridge.initial_port = IM.ingress_port;
      H.bridge.remaining = H.recirc.steps - 1;
    } else {
      H.bridge.remaining = H.bridge.remaining - 1;
    }
  }
}

control Reflect(inout header_t H, inout ingress_intrinsic_metadata_for_tm_t TIM) {
  apply {
    mac_addr_t tmp = H.eth.dst_addr;
    H.eth.dst_addr = H.eth.src_addr;
    H.eth.src_addr = tmp;
    TIM.ucast_egress_port = H.bridge.initial_port;
    H.bridge.setInvalid();
  }
}

control Recirculate(inout ingress_intrinsic_metadata_for_tm_t TIM, bit<2> pipe) {
  apply {
    TIM.ucast_egress_port = (PortId_t) (32w68 + (bit<32>) pipe * 32w128);
  }
}

control Pipe0_Ingress(inout header_t H, inout empty_metadata_t M,
                      in ingress_intrinsic_metadata_t IM,
                      in ingress_intrinsic_metadata_from_parser_t PIM,
                      inout ingress_intrinsic_metadata_for_deparser_t DIM,
                      inout ingress_intrinsic_metadata_for_tm_t TIM) {
  apply {
    State.apply(H, IM);
    H.recirc.pipe0 = H.recirc.pipe0 + 1;
    if ( H.bridge.remaining == 0)
      Reflect.apply(H, TIM);
    else
      Recirculate.apply(TIM, 1);
  }
}

control Pipe1_Ingress(inout header_t H, inout empty_metadata_t M,
                      in ingress_intrinsic_metadata_t IM,
                      in ingress_intrinsic_metadata_from_parser_t PIM,
                      inout ingress_intrinsic_metadata_for_deparser_t DIM,
                      inout ingress_intrinsic_metadata_for_tm_t TIM) {
  apply {
    State.apply(H, IM);
    H.recirc.pipe1 = H.recirc.pipe1 + 1;
    if ( H.bridge.remaining == 0)
      Reflect.apply(H, TIM);
    else
      Recirculate.apply(TIM, 2);
  }
}

control Pipe2_Ingress(inout header_t H, inout empty_metadata_t M,
                      in ingress_intrinsic_metadata_t IM,
                      in ingress_intrinsic_metadata_from_parser_t PIM,
                      inout ingress_intrinsic_metadata_for_deparser_t DIM,
                      inout ingress_intrinsic_metadata_for_tm_t TIM) {
  apply {
    State.apply(H, IM);
    H.recirc.pipe2 = H.recirc.pipe2 + 1;
    if ( H.bridge.remaining == 0)
      Reflect.apply(H, TIM);
    else
      Recirculate.apply(TIM, 3);
  }
}

control Pipe3_Ingress(inout header_t H, inout empty_metadata_t M,
                      in ingress_intrinsic_metadata_t IM,
                      in ingress_intrinsic_metadata_from_parser_t PIM,
                      inout ingress_intrinsic_metadata_for_deparser_t DIM,
                      inout ingress_intrinsic_metadata_for_tm_t TIM) {
  apply {
    State.apply(H, IM);
    H.recirc.pipe3 = H.recirc.pipe3 + 1;
    if ( H.bridge.remaining == 0)
      Reflect.apply(H, TIM);
    else
      Recirculate.apply(TIM, 0);
  }
}

Pipeline( Pipe0_IngressParser(), Pipe0_Ingress(), DefaultIngressDeparser(),
          DefaultEgressParser(), EmptyEgress(), DefaultEgressDeparser()) pipe0;
Pipeline( Pipe1_IngressParser(), Pipe1_Ingress(), DefaultIngressDeparser(),
          DefaultEgressParser(), EmptyEgress(), DefaultEgressDeparser()) pipe1;
Pipeline( Pipe2_IngressParser(), Pipe2_Ingress(), DefaultIngressDeparser(),
          DefaultEgressParser(), EmptyEgress(), DefaultEgressDeparser()) pipe2;
Pipeline( Pipe3_IngressParser(), Pipe3_Ingress(), DefaultIngressDeparser(),
          DefaultEgressParser(), EmptyEgress(), DefaultEgressDeparser()) pipe3;

Switch(pipe0, pipe1, pipe2, pipe3) main;