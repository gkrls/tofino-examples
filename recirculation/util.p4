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

control DefaultIngressDeparser( packet_out P,
                                inout header_t H, in empty_metadata_t M,
                                in ingress_intrinsic_metadata_for_deparser_t DIM) {
  apply { P.emit(H); }
}

parser DefaultEgressParser( packet_in P,
                            out empty_header_t H, out empty_metadata_t M,
                            out egress_intrinsic_metadata_t  IM) {
  state start {
    P.extract(IM);
    transition accept;
  }
}

control DefaultEgressDeparser( packet_out P,
                               inout empty_header_t H, in empty_metadata_t M,
                               in egress_intrinsic_metadata_for_deparser_t DIM) {
  apply { P.emit(H); }
}

control EmptyEgress(inout empty_header_t H, inout empty_metadata_t M,
                    in egress_intrinsic_metadata_t IM,
                    in egress_intrinsic_metadata_from_parser_t PIM,
                    inout egress_intrinsic_metadata_for_deparser_t DIM,
                    inout egress_intrinsic_metadata_for_output_port_t OPIM) {
  apply {}
}


