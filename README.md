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
- 2D systolic-style array (ROWS × COLS)
- Signed INT8 inputs
- INT32 accumulation
- Tile-based matrix multiplication model

---

## Design Philosophy

- Documentation first
- Interface freeze before implementation
- Clean branching workflow (`main` = stable, `dev` = active work)
- Parameterizable and scalable structure
- Deterministic simulation behavior

---

## Repository Structure

- docs/ → Architecture specifications
- rtl/ → SystemVerilog implementation (future)
- tb/ → Testbench and golden reference model (future)
- scripts/ → Build/simulation utilities (future)

---

## Current Status

- [x] Initial architecture specification
- [ ] Interface definition freeze
- [ ] PE RTL implementation
- [ ] Array RTL implementation
- [ ] Testbench + golden model
- [ ] Synthesis exploration

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
