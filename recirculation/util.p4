typedef bit<48> mac_addr_t;
typedef bit<16> eth_type_t;

header ethernet_h {
  mac_addr_t dst_addr;
  mac_addr_t src_addr;
  eth_type_t ether_type;
}

struct empty_header_t {}
struct empty_metadata_t {}

parser TofinoIngressParser( packet_in P,
                            out ingress_intrinsic_metadata_t IM) {
  state start {
    P.extract(IM);
    transition select(IM.resubmit_flag) {
      1 : parse_resubmit;
      0 : parse_port_metadata;
    }
  }
  state parse_resubmit { transition reject; }
  state parse_port_metadata {
    P.advance(PORT_METADATA_SIZE);
    transition accept;
  }
}

parser TofinoEgressParser( packet_in P,
                           out egress_intrinsic_metadata_t IM) {
  state start {
    P.extract(IM);
    transition accept;
  }
}

control EmptyEgress(inout empty_header_t H, inout empty_metadata_t M,
                    in egress_intrinsic_metadata_t IM,
                    in egress_intrinsic_metadata_from_parser_t PIM,
                    inout egress_intrinsic_metadata_for_deparser_t DIM,
                    inout egress_intrinsic_metadata_for_output_port_t OPIM) {
  apply {}
}
