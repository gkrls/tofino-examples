There are two recirculation mechanisms on Tofino switches:

1. Any normal port can be configured in loopback mode and used for recirculation
2. Each pipe contains a nubmer of special ports to be used for recirculation

### Tofino 1 recirculation ports

Tofino 1 offers the following special recirculation ports:

|            |      Quad 16       |      Quad 17       |
| ---------  | ------------------ | ------------------ |
| **Pipe 0** |                    |     **68**, 69, 70, 71 |
| **Pipe 1** | 192, 193, 194, 195 | **196**, 197, 198, 199 |
| **Pipe 2** |                    | **324**, 325, 326, 327 |
| **Pipe 3** | 448, 449, 450, 451 | **452**, 453, 454, 455 |

Quad 16 ports do not have access to the packet generators. In general, it is recommended to just use the quad 17 ports.

One may use the formula `r = 68 + p * 128` to find the first recirculation port for each pipe `p`.
For each pipe, `r` can be used as a single `100G` port, or split into 4x `25G` ports. By default:

|            | C onfiguration  |
| ---------  | ------------------ |
| **ASIC**  | `r` in `100G` mode (`r+1, r+2, r+3` are not available) |
| **Model** | `r` split to `r, r+1, r+2, r+3` (as if in 4x`25G` mode) |