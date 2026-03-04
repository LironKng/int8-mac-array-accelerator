# INT8 MAC Array Accelerator

A parameterizable INT8 Multiply–Accumulate (MAC) array accelerator designed as a structured hardware project following architecture-first development.

This project focuses on building a clean, scalable systolic-style MAC array suitable for matrix multiplication and neural network inference workloads.

---

## Objectives

- Define a stable architecture specification before RTL
- Implement a parameterizable 2D INT8 MAC array
- Provide deterministic verification with golden reference model
- Document architectural tradeoffs (area / throughput / scalability)

---

## High-Level Architecture

- Processing Element (PE): INT8 × INT8 → INT32 accumulate
- 2D systolic-style array (`ROWS × COLS`), parameterizable at compile time
- Inner dimension `DEPTH` (K) also a compile-time parameter
- Signed INT8 inputs, INT32 accumulation
- Tile-based matrix multiplication: C = A × B
- Per-cell `out_valid` pulse + sticky `done` output for result capture

---

## Design Philosophy

- Documentation first
- Interface freeze before implementation
- Clean branching workflow (`main` = stable, `dev` = active work)
- Parameterizable and scalable structure
- Deterministic simulation behavior

---

## Repository Structure

```
docs/       Architecture specification and figures
rtl/        SystemVerilog RTL
  mac_pe.sv         Processing Element (PE)
  mac_array.sv      2D parameterizable MAC array
tb/         Testbenches
  tb_mac_pe.sv              PE unit testbench
  tb_mac_array_2x2.sv       2×2 integration testbench
  tb_mac_array_param.sv     Parameterized randomized regression
scripts/    Simulation build scripts (Verilator)
```

---

## Current Status

- [x] Initial architecture specification
- [x] Interface freeze (port-level spec v1.0)
- [x] PE RTL (`mac_pe.sv`)
- [x] 2D MAC array RTL (`mac_array.sv`)
- [x] 2×2 integration testbench
- [x] Deterministic randomized regression (1000 cases, 8×8 array, K=16)
- [ ] Synthesis exploration

---

## Running Simulations

Requires [Verilator](https://verilator.org/).

```bash
# PE unit test
bash scripts/sim_mac_pe.sh

# 2×2 integration test
bash scripts/sim_mac_array_2x2.sh

# Parameterized regression (1000 random cases)
bash scripts/sim_mac_array_param.sh
```

---

## Planned Features (Future Extensions)

- Saturating arithmetic option
- Runtime configuration interface
- Performance counters
- Quantization support (scale / bias)
- Optional activation integration

---

## Target Use Cases

- Matrix multiplication (GEMM)
- CNN inner products
- Transformer attention blocks
- Embedded AI accelerators

---

## Development Model

All new work is performed on `dev` branch.
`main` contains only stable reviewed states.
