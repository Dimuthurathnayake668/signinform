# PREDATOR 2026 — UNIFIED MASTER ENGINEERING PLAN v1.2A
### Single Source of Truth: DevOps · ML · Intelligence · Compliance · Security

---

**Document ID:** `PRED-2026-MASTER-v1.2A`
**Revision:** 1.2A — Full Intelligence Layer Integration + Advanced Audit Hardening
**Supersedes:** v1.1 (`PRED-2026-MASTER-DEVOPS-v1.1`) and Intelligence Addendum (`PRED-2026-INTELLIGENCE-v1.2`)
**Date:** 2026-04-10
**Classification:** INTERNAL — ENGINEERING USE ONLY
**Status:** ✅ Draft Ready — Awaiting Phase Gate Approval (ML Lead + CRO + Compliance Officer)
**Authors:** Systems Engineering, Quantitative Research, Platform Engineering, Compliance, Security

---

All components are designed for lawful trading only. No offensive or illegal network techniques are used.

---

## COMBINED CHANGE LOG

### v1.0 → v1.1 (All Critical, Major, and Minor audit findings resolved)

| Finding | Section(s) | Severity | Summary |
|---|---|---|---|
| C1 | 5.2 | Critical | EWMA decay is tick-based; fixed to time-based α = 1 − exp(−Δt/τ) |
| C2 | 5.3 | Critical | Realized volatility windows were in ticks; fixed to seconds |
| C3 | 8.3 | Critical | Stop-loss volatility window in ticks (0.03s); fixed to seconds |
| C4 | 7.4 | Critical | torch.autograd.grad called 20× on hot path; replaced with analytical gradient |
| C5 | 7.4, 8.1 | Critical | Stochastic SDE noise during live inference; fixed to deterministic mode live |
| C6 | 9.3 | Critical | Sample entropy on single latent dimension; fixed to PCA-reduced full vector |
| C7 | 3.1, 10.4, 11.1 | Critical | HSM 5μs ECDSA budget unrealistic; corrected to 50μs minimum; total budget revised |
| C8 | 9.1, 10.2, 10.3 | Critical | Python in PortfolioRiskManager / ManipulationGuard contradicts no-Python-on-hot-path; fixed with Rust rewrite |
| M1 | 11.1 | Major | No cancellation path in latency budget; added 30μs budget |
| M2 | 4.3 | Major | Rate limit exhaustion undefined; now forces HOLD action |
| M3 | 10 (new §10.6) | Major | No 64-bit monotonic order ID scheme; added specification |
| M4 | 5.1 | Major | No secondary feed failover on corrupted/gapped packets; added sequence-number check + failover |
| M5 | 21 (new §21.5) | Major | No graceful re-entry after halt; added cool-down + paper-trade validation |
| M6 | 21.1 | Major | Mass-cancel not validated under load; added per-order fallback loop |
| M7 | 19.4 | Major | IID bootstrap invalid for time series; replaced with block bootstrap |
| M8 | 20.2 | Major | Crash guard tracks only last crash time; fixed to deque-of-timestamps sliding window |
| M9 | 5.5 | Major | Gap token carries stale spread without age limit; capped at 60s |
| M10 | 9.1 | Major | VaR not explicitly correlation-aware; added joint portfolio VaR specification |
| M11 | 10.3 | Major | 15% surrogate disagreement = 15% non-compliant explanations; added per-order agreement flag |
| M12 | 19.2 | Major | "Not market hours" asserted for 24/7 crypto; replaced with low-liquidity UTC window |
| M13 | 12.3 | Major | Bit-identical claim requires deterministic CUDA; added use_deterministic_algorithms requirement |
| M14 | 18.1 | Major | feature_id FK join requires full table scan; added Bloom filter secondary index |
| Mi1 | 7.5 | Minor | Energy drift threshold static (30-day); changed to rolling 7-day adaptive |
| Mi2 | 10.3 | Minor | Surrogate string building in Python (≥5μs); pre-compiled reason code spec added |
| Mi3 | 18.1, 24.1 | Minor | ClickHouse 7-year/220B rows without partition plan; monthly partitions + warm/cold tiers added |
| Mi4 | 3.3 | Minor | GPU memory fragmented on model reload; fixed to in-place weight overwrite in fixed slots |
| Mi5 | Appendix D | Minor | HGRN-2 ArXiv citation corrected to 2311.04823 |
| Mi6 | 19.3 | Minor | "VIX-equivalent > 80" invalid for crypto; replaced with realized vol metric |
| Mi7 | 6.3 | Minor | NSR K-means regime recalculation frequency unspecified; added weekly recalibration |
| Mi8 | 6.2 | Minor | CoPE w_positional shape undefined; added explicit definition |
| Mi9 | 4.3 | Minor | Rate limiter comparison bug (0.80 * v_current_weight instead of cfg_max_weight) |
| Mi10 | 4.3 | Minor | Rate limiter window never resets; added window reset logic |

### v1.1 → v1.2 (Intelligence Layer Integration)

| Finding | Section | Type | Summary |
|---|---|---|---|
| I1 | 5A (new) | Feature | ARGOS Whale Intelligence Layer — 6 agent modules |
| I2 | 5B (new) | Feature | Mempool Intelligence Engine — low-latency tx surveillance |
| I3 | 5C (new) | Feature | Market Microstructure & Dark Pool Intelligence |
| I4 | 5D (new) | Feature | Cross-Instrument Derivative Signal Layer |
| I5 | 17A (new) | Security | Network Security Hardening — P2P defense layer |
| I6 | 8.2 | Enhancement | Kelly Fraction now modulated by Intelligence Multiplier |
| I7 | 9.1 | Enhancement | Risk thresholds conditionally tightened by ICC signals |
| I8 | 6.3 | Enhancement | NSR regime detector conditioned on Intelligence Context |
| I9 | 31 (new) | Process | 3-phase intelligence integration rollout plan |
| I10 | App-B | Config | All intelligence module configuration parameters added |
| I11 | App-E | ADR | ADR-017 through ADR-025 added |
| I12 | 18 | Schema | 4 new ClickHouse tables for intelligence audit trail |

### v1.2 → v1.2A (Advanced Audit Hardening)

| Finding | Section(s) | Severity | Summary |
|---|---|---|---|
| A1 | 4.3, 5.1 | Critical | Corrected Binance futures order-entry protocol mapping (REST/WebSocket trading path; FIX used only where exchange supports it) |
| A2 | 10.5, 21.1 | Critical | Added cancel race-condition handling + 5s global cancel deadline in kill-switch path |
| A3 | 12.3, 29 | Critical | Reproducibility protocol hardened: TF32 disabled; bit-identical claim scoped to same software/hardware stack |
| A4 | 18.1 | Major | Added replicated ClickHouse consistency guardrail (`insert_quorum`, `select_sequential_consistency`) for critical tables when replication is enabled |
| A5 | 16.1 | Major | HSM key type consistency fixed to Ed25519 across secrets and signing sections |
| A6 | 10.3, 20.1, 23.2 | Major | OOD explainability safeguards: detector, fallback explanation policy, compliance escalation |
| A7 | 19.1 | Major | Drift thresholds upgraded from fixed-only to fixed floor + rolling percentile band |
| A8 | 23.1 | Major | Regulatory mapping corrected (CFTC Reg AT removed; FATF role corrected to AML/CFT controls) |
| A9 | 20.4 | Minor | Added traceability and dependency-health observability requirements (trace_id + provider SLO dashboard) |
| A10 | 1.5 | Minor | Added module-by-module hardening matrix for Sections 1–31 |

---

## TABLE OF CONTENTS

1. [Purpose, Scope & Reading Guide](#1)
2. [Master Architecture & Data Flow](#2)
3. [Infrastructure & Hardware Specification](#3)
4. [Network Topology & Time Synchronization](#4)
5. [Data Ingestion, Feature Engineering & Feature Store](#5)
   - [5A. Whale Intelligence Layer (ARGOS)](#5A)
   - [5B. Mempool Intelligence Engine](#5B)
   - [5C. Market Microstructure & Dark Pool Intelligence](#5C)
   - [5D. Cross-Instrument Derivative Signal Layer](#5D)
   - [5E. Intelligence Context Cache & Integration Bridge](#5E)
6. [ML Model Specifications](#6)
7. [Physics Engine — Neural SDE](#7)
8. [Execution Engine — Actor Network, Kelly Sizing, Stop-Loss](#8)
9. [Risk Management — Portfolio Risk Manager & Circuit Breakers](#9)
10. [Order Management System (OMS) & Manipulation Guard](#10)
11. [Latency Budget & Profiling Protocol](#11)
12. [Training Pipeline — Phased, Reproducible, No Lookahead Bias](#12)
13. [Simulation & Paper Trading Environment](#13)
14. [Shadow, Canary & Production Deployment](#14)
15. [CI/CD Pipeline — Code to Production](#15)
16. [Secrets Management & HSM Key Lifecycle](#16)
17. [Security Architecture & Penetration Testing](#17)
    - [17A. Network Security Hardening (P2P Defense Layer)](#17A)
18. [Audit Logging, Database Schema & White-Box Traceability](#18)
19. [Drift Detection, Retraining & Model Governance](#19)
20. [Health Monitoring, Alerting & Crash-Loop Prevention](#20)
21. [Kill Switch, Incident Response & Disaster Recovery](#21)
22. [Business Continuity & Exchange Redundancy](#22)
23. [Regulatory Compliance & Reporting Automation](#23)
24. [Data Retention, Backup & Archival](#24)
25. [Capital Allocation & Staged Rollout Framework](#25)
26. [Capacity Planning & Cost Modeling](#26)
27. [Team Structure, Runbooks & Onboarding](#27)
28. [Load Testing, Chaos Engineering & Pre-Production Drills](#28)
29. [Final Acceptance Gates — 100/100 per Phase + Intelligence Gates](#29)
30. [Appendices — Naming Conventions, Hyperparameters, Contacts](#30)
31. [Phased Intelligence Integration Rollout](#31)

---

## 1. Purpose, Scope & Reading Guide

### 1.1 Purpose

This document is the **single source of truth** for every engineering, science, operations, compliance,
and security decision in Predator 2026. It supersedes all prior drafts, audit reports, and partial
specifications. v1.1 additionally resolves all findings from a full dual-AI independent audit conducted
on 2026-04-08.

No developer should need any other document to implement a component. Every variable, tensor shape,
data type, threshold, timing constraint, and escalation path is defined here to letter precision.

### 1.2 Scope Boundaries

| In Scope | Out of Scope |
|---|---|
| All software, ML, infrastructure, data, and compliance components of Predator 2026 | Proprietary exchange API terms (read separately) |
| Crypto perpetual swaps (BTCUSDT, ETHUSDT, SOLUSDT) + one traditional asset (XAUUSD) | Equity / options markets (future phase) |
| Bare-metal colocation at Equinix NY4 / SG1 | Cloud-only deployments on hot path |
| Real-time HFT latency target p99 ≤ 500μs | Algorithmic strategies with >1-second decisions |

### 1.3 How to Read This Document

- **DevOps / Platform engineers:** Sections 3, 4, 14, 15, 16, 17, 21, 22, 24, 26, 28.
- **ML / Quant engineers:** Sections 5, 6, 7, 8, 12, 13, 19.
- **Risk / Trading:** Sections 9, 10, 25.
- **Compliance / Legal:** Sections 23, 24, 18.
- **On-call engineers:** Sections 20, 21, 22 plus all runbooks in Section 27.

### 1.4 Document Control

| Version | Date | Author | Change Summary |
|---|---|---|---|
| 0.1 | 2025-01-15 | Quant Team | Initial HFT spec |
| 0.2–0.4 | 2025-03-01 | All | Audit rounds 1–3 |
| 1.0 | 2026-04-08 | All | Full synthesis, net-new phases added |
| 1.1 | 2026-04-08 | All | Dual-AI audit: 10 Critical, 15 Major, 10 Minor findings resolved |
| 1.2 | 2026-04-10 | All | Intelligence layer integration |
| 1.2A | 2026-04-10 | All | Advanced systems audit hardening across Sections 1–31 |

**Change process:** All changes require a pull request reviewed by: ML Lead + Platform Lead +
Compliance Officer. Changes to Section 9 (Risk) also require CRO sign-off. No direct commits to
`main` branch.

### 1.5 Advanced Audit Hardening Matrix (Sections 1–31)

| Section | Hardening Focus |
|---|---|
| 1 | Add explicit assumptions register with owner and quarterly re-validation date |
| 2 | Define interface contracts (schema + SLA) for each stage boundary in the pipeline |
| 3 | Add microarchitectural contention monitors (cache/memory bandwidth interference alerts) |
| 4 | Centralize reconnect control with exponential backoff + jitter across all exchange sessions |
| 5 | Add provider SLO matrix, stale-signal policy, and warm-path backpressure limits |
| 6 | Add OOD confidence gate before surrogate explanations are treated as compliance-grade |
| 7 | Add latent/state magnitude guardrails and deterministic-vs-stochastic validation gates |
| 8 | Add liquidity-aware Kelly ceiling using spread/depth/funding stress |
| 9 | Add cross-venue risk reconciliation cadence and mismatch escalation |
| 10 | Add cancel-race handling and mandatory post-cancel reconciliation branch |
| 11 | Add p999/p9999 latency targets with stage-level tail attribution |
| 12 | Harden reproducibility by disabling TF32 and scoping bit-identical guarantees |
| 13 | Extend simulator with exchange-specific partial fills/reject/cancel-race behavior |
| 14 | Add canary auto-abort triggers for OOD surge, stale-intel saturation, and disagreement spikes |
| 15 | Add policy-as-code gate checks for risk/compliance invariants before promotion |
| 16 | Standardize Ed25519 signing key lifecycle and firmware-vulnerability review cadence |
| 17 | Add physical-access and side-channel controls to colo security runbook |
| 18 | Add replicated-storage consistency mode for critical audit tables when replication is enabled |
| 19 | Use fixed floor + rolling percentile drift thresholds (not fixed-only) |
| 20 | Add explicit degraded-mode state machine (Conservative / Monitor-only / Reduce-only / Halt) |
| 21 | Add global cancel deadline and forced safe-stop if cancellation cannot be verified |
| 22 | Add exchange capability matrix checks (protocol, precision, cancel semantics) |
| 23 | Correct regulation mappings and separate AML/CFT from market-abuse surveillance scope |
| 24 | Add jurisdiction-specific retention matrix and immutable-storage attestation cadence |
| 25 | Add capital scale-up gates on tail-risk and incident-free runtime, not Sharpe only |
| 26 | Add vendor/API tier overrun stress test and failover cost envelope |
| 27 | Add alert ownership SLAs and escalation response-time targets |
| 28 | Add compound-fault chaos scenarios (network + HSM + stale-intel combinations) |
| 29 | Align acceptance gates with current retention/protocol/signing realities |
| 30 | Keep appendices synchronized with active revision metadata and references |
| 31 | Add rollout false-positive-cost budget and per-module resource ceilings |

---

## 2. Master Architecture & Data Flow

### 2.1 Corrected End-to-End Pipeline

```
══════════════════════════════════════════════════════════════════════════════
HOT PATH (target p99 ≤ 500μs — measured end-to-end, exchange clock to order dispatch)
══════════════════════════════════════════════════════════════════════════════

[Exchange WebSocket / UDP]
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ INGESTION GATEWAY                                      │
│  • Solarflare X4 NIC (OpenOnload ef_vi)               │
│  • Dedicated CPU core 0–1 (isolated, no IRQ sharing)  │
│  • Deserialize → c_mkt_tick_raw / c_mkt_orderbook_snap│
│  • Circular buffer 10,000 ticks (pre-allocated, GPU)  │
│  • Seq-number check; on gap → switch to backup feed   │  ← [FIXED M4]
│  • Gap detection: inject gap_token if Δt > 1,000ms    │
│  Latency budget: 20μs                                 │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ NORMALIZATION ENGINE (fused CUDA kernel)               │
│  • Time-based EWMA price/volume (τ = 60s)             │  ← [FIXED C1]
│  • Clip to [-5, 5] (all tensors float32)              │
│  • Order book imbalance, spread_bps, trade direction  │
│  • Realized vol windows: 60s, 300s, 900s              │  ← [FIXED C2]
│  • Output: t_tick_features shape (64, 64, 128)        │
│  Latency budget: fused with Mamba-2 kernel = 0μs extra│
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ MAMBA-2 + CoPE + HGRN-2 (Perception) — RUST/C++ ONLY │  ← [FIXED C8]
│  • Input: (64, 64, 128) float32                       │
│  • CoPE: positional bias from real time deltas        │
│  • 4 × Mamba-2 blocks (selective scan, SiLU, LN)     │
│  • HGRN-2: hierarchical gate after each scan          │
│  • Output: t_latent_state (64, 256) float32           │
│    — first 128 dims = q (position in bps)             │
│    — last 128 dims = p (momentum, bps/s)              │
│  Latency budget: 60μs                                 │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ NEURAL SDE (Physics — Dissipative, DETERMINISTIC live) │  ← [FIXED C4,C5]
│  • dq = p dt                                          │
│  • dp = (−∇U(q) − γp) dt   [σ·dW = 0 in live mode]  │
│  • Analytical gradient ∇U via fused kernel (no autograd)│
│  • Fixed-step Störmer-Verlet, dt=0.001s, n_steps=10   │
│  • All float32. Outputs: t_q_final, t_p_final (64,128)│
│  • v_energy_drift: scalar, rolling 7-day 99th pct     │  ← [FIXED Mi1]
│  Latency budget: 80μs                                 │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ LEARNED ACTOR NETWORK (Single Forward Pass)            │
│  • Input: concat(t_q_final, t_p_final) → (64, 256)   │
│  • MLP: 256→512→512→8, tanh output                    │
│  • Output: t_raw_action (64, 8) ∈ [-1, 1]            │
│  • v_kelly_fraction (float32, continuous)             │
│  Latency budget: 5μs                                  │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ PORTFOLIO RISK MANAGER — RUST                          │  ← [FIXED C8]
│  • Net delta check: < 20% capital                     │
│  • Gross exposure check: < 50% capital                │
│  • Rolling 95% joint VaR check: < 5% capital         │  ← [FIXED M10]
│  • Rate-limit check → HOLD if insufficient weight     │  ← [FIXED M2]
│  • Outputs: b_risk_ok, v_adjusted_size                │
│  Latency budget: 10μs                                 │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│ ORDER MANAGEMENT SYSTEM (OMS) — RUST                  │  ← [FIXED C8]
│  • ManipulationGuard (self-trade, OTR, spoofing)      │
│  • Surrogate tree ex-ante reason_code (synchronous)   │
│  • Pre-allocated reason code buffer (no Python string)│  ← [FIXED Mi2]
│  • Order ID: 64-bit monotonic (node_id | counter)    │  ← [FIXED M3]
│  • HSM signing (Thales Luna, PCIe, on-prem)           │
│  • Dispatch via OpenOnload ef_vi                      │
│  New order latency budget: 80μs                       │  ← [FIXED C7]
│  Cancel order latency budget: 30μs                    │  ← [FIXED M1]
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
                  [Exchange API]

══════════════════════════════════════════════════════════════════════════════
TOTAL HOT PATH: 255μs nominal · 500μs p99 (245μs slack for kernel launches)
══════════════════════════════════════════════════════════════════════════════
```

### 2.2 Critical Architectural Corrections Carried Forward from v1.0

| Original Flaw | Status in This Plan |
|---|---|
| SymODEN / Hamiltonian — physically invalid for markets | ✅ Replaced with Neural SDE |
| "Mamba-3" — fictitious model | ✅ Replaced with Mamba-2 + CoPE + HGRN-2 |
| CEM-GD planning in 100μs — impossible live | ✅ Offline CEM-GD trains actor; live = single MLP pass |
| Lyapunov binary halt on λ > 0 | ✅ Continuous penalty |
| Energy drift threshold 1e-6 — unachievable in float32 | ✅ Empirical rolling 7-day 99th percentile calibration |
| SHAP KernelExplainer O(2¹²⁸) | ✅ TreeSHAP + GradientSHAP, async |
| No portfolio-level risk | ✅ Portfolio Risk Manager added |
| DPDK + Solarflare conflict | ✅ Solarflare OpenOnload only |
| AWS CloudHSM + latency conflict | ✅ On-prem Thales Luna PCIe |
| SHAP ex-post (non-compliant) | ✅ Surrogate tree logged synchronously per order |
| ε = 0.1 live exploration | ✅ ε = 0 live |
| float16 kills physics precision | ✅ float32 enforced |
| Python logger GIL bottleneck | ✅ Rust + Kafka + ClickHouse |
| Tick-based EWMA window | ✅ **[v1.1]** Time-based EWMA: α = 1 − exp(−Δt/τ) |
| Stop-loss in ticks | ✅ **[v1.1]** Stop-loss in seconds |
| Realized vol windows in ticks | ✅ **[v1.1]** Realized vol in seconds |
| autograd on hot path (SDE) | ✅ **[v1.1]** Analytical gradient, fused kernel |
| Stochastic SDE in live inference | ✅ **[v1.1]** Deterministic mode (σ·dW = 0) live |
| Sample entropy on 1 dimension | ✅ **[v1.1]** PCA-reduced full 256-dim vector |
| HSM 5μs unrealistic | ✅ **[v1.1]** 50μs budget; total SLA revised |
| Python on hot path (risk/OMS) | ✅ **[v1.1]** All hot-path logic rewritten in Rust |

---

## 3. Infrastructure & Hardware Specification

### 3.1 Production Hardware (Per Node)

| Component | Specification | Justification |
|---|---|---|
| GPU | NVIDIA H100 SXM5 80GB HBM3 | 3.35 TB/s memory bandwidth; **mandatory** for 500μs SLA — see note below |
| CPU | AMD EPYC 9654 (96 cores, 2P) or Intel Xeon Gold 6438N | Core isolation; NUMA-aware placement |
| RAM | 512GB DDR5 ECC 4800MHz (8 × 64GB) | In-memory circular buffers, replay cache |
| NIC | Solarflare X4 (25GbE, dual-port) | OpenOnload ef_vi kernel-bypass; tested compatible with Thales HSM |
| HSM | Thales Luna Network HSM 7 (PCIe card version) | On-prem PCIe; Ed25519 signing ≤5μs; ECDSA P-256 ≥50μs (see signing note); FIPS 140-2 Level 3 |
| Storage | 2× 4TB Samsung 990 Pro NVMe (RAID-1) | Replay buffer; audit logs; order ID counter persistence |
| Power | 2× Redundant PSU, UPS (APC Smart-UPS 3000VA) | N+1 power; auto-failover |
| Rack | Equinix NY4 (primary) | Primary hot-path node |

> **GPU — H100 is mandatory for the hot path.** The A10G (24 GB GDDR6, 600 GB/s bandwidth) is
> 5.6× slower in memory bandwidth than the H100 (3.35 TB/s). The Mamba-2 kernel (60μs budget)
> and Neural SDE (80μs budget) are both memory-bandwidth-bound at batch size 64. Benchmarks show
> the A10G would add 200–400μs to these stages alone, blowing the 500μs SLA. The A10G is
> acceptable **only** for development workstations and off-peak training nodes (cores 48–63),
> never for the production hot-path trading server.

> **HSM signing — switch to Ed25519 (cost + latency win).** Binance officially recommends Ed25519
> over ECDSA P-256 and has deprecated HMAC keys. Ed25519 on Thales Luna PCIe achieves ≤5μs
> (vs 50μs for ECDSA P-256), saving 45μs on the hot-path budget and recovering 18% of the
> current slack. Update `cfg_active_key_type` to Ed25519 in §10.4 and §16. The HSM hardware
> itself is retained — only the key algorithm changes. HMAC keys must NOT be used (Binance
> deprecated; symmetric secret less secure than asymmetric Ed25519).

> **SG1 bare-metal DR — deferral permitted for Stage 0–2.** Full SG1 bare-metal colocation
> ($1,500/month) can be replaced with a cloud warm-standby instance (e.g., AWS ap-southeast-1,
> c6i.8xlarge with A10G, ~$400/month) for Stages 0–2 (≤5% capital). SG1 champion weights
> sync hourly; RTO extends from 15 min to ~25 min in cloud-DR mode — acceptable at low capital.
> Procure SG1 bare metal before Stage 3 (5% → 20% capital ramp) when Asian-session latency
> and RTO matter materially. Monthly saving: ~$1,100/month for Stages 0–2.

> **[FIXED C7]** Hardware spec previously listed HSM signing latency as "< 5μs" for ECDSA P-256,
> which is physically impossible. Corrected to ≥50μs. Ed25519 achieves ≤5μs on the same hardware.

### 3.2 CPU Core Isolation Map

| Core Range | Process | IRQ Affinity | Priority |
|---|---|---|---|
| 0–1 | OpenOnload network poll (Solarflare ef_vi) | Isolated, no IRQ sharing | SCHED_FIFO 99 |
| 2–15 | Hot path pipeline (ingestion → OMS dispatch) | No IRQ | SCHED_FIFO 98 |
| 16–31 | Async path (SHAP, NSR, Lyapunov, drift monitor) | Default | SCHED_OTHER |
| 32–47 | Rust audit logger, Kafka producer | Default | SCHED_OTHER |
| 48–63 | Training jobs (when not in production hours) | Restricted via cgroups | SCHED_BATCH |
| 64+ | OS services, SSH, monitoring agents | Default | Default |

**Kernel parameters (set in `/etc/sysctl.conf`):**
```
kernel.sched_rt_runtime_us = -1
net.core.busy_read = 50
net.core.busy_poll = 50
vm.swappiness = 0
vm.hugetlb_shm_group = <gpu_group>
kernel.numa_balancing = 0
```

**Boot parameters (GRUB):**
```
isolcpus=0-15 nohz_full=0-15 rcu_nocbs=0-15 intel_pstate=disable
```

### 3.3 GPU Memory Pre-Allocation Layout

Pre-allocate all GPU buffers at startup. **Zero dynamic allocation on hot path.**

> **[FIXED Mi4]** Champion and challenger model weights now occupy FIXED, non-overlapping GPU address
> slots. Weights are OVERWRITTEN IN-PLACE during model reload — the old allocation is NEVER freed.
> This eliminates memory fragmentation when the challenger is promoted to champion.

| Buffer Name | Shape | dtype | Size | GPU Address Offset |
|---|---|---|---|---|
| `buf_ticks_raw` | (1024, 128) | float32 | 512 KB | 0x0000_0000 |
| `buf_features_norm` | (1024, 128) | float32 | 512 KB | 0x0008_0000 |
| `buf_latent` | (1024, 256) | float32 | 1 MB | 0x0010_0000 |
| `buf_qp` | (1024, 256) | float32 | 1 MB | 0x0020_0000 |
| `buf_trajectory` | (1000, 256) | float32 | 1 MB | 0x0030_0000 |
| `buf_actor_action` | (64, 8) | float32 | 2 KB | 0x0040_0000 |
| `buf_risk_metrics` | (64, 5) | float32 | 1.25 KB | 0x0041_0000 |
| `buf_gap_token` | (1, 128) | float32 | 512 B | 0x0042_0000 |
| `buf_kelly_fractions` | (64,) | float32 | 256 B | 0x0043_0000 |
| Model slot A — Champion weights | — | float32 | ~1.7 GB | 0x0100_0000 |
| Model slot B — Challenger weights | — | float32 | ~1.7 GB | 0x0800_0000 |
| **Total GPU reserved** | | | **~3.403 GB** | |

**Model slot protocol:** On promotion, challenger weights in slot B are memcpy'd to slot A
(`cudaMemcpy`, device-to-device, ~10ms for 1.7GB at 3.35TB/s HBM3). Slot B is then overwritten with
the next challenger. Never free → never fragment.

**Challenger activation condition:** `cudaMemGetInfo()` must report ≥ 30GB free after both slot
allocations.

### 3.4 Challenger GPU Stream Isolation

```python
champion_stream   = torch.cuda.Stream(device=0, priority=-1)  # high priority
challenger_stream = torch.cuda.Stream(device=0, priority=0)   # low priority
# Champion always runs first; challenger is pre-emptable
```

### 3.5 Network Hardware Topology

- All market data and order entry via OpenOnload `ef_vi` sockets
- No DPDK anywhere in the stack
- Separate physical NIC ports: market data (port 0), order entry (port 1), management (dedicated NIC)

---

## 4. Network Topology & Time Synchronization

### 4.1 Full Network Diagram

```
 ┌─────────────────── Equinix NY4 Cage ────────────────────────────┐
 │                                                                   │
 │  ┌──────────────┐   Cross-Connect    ┌──────────────────────┐   │
 │  │  Exchange    │◄──────────────────►│  Solarflare X4 NIC   │   │
 │  │  Match Engine│   (< 100ns, fiber) │  Port 0: Mkt Data   │   │
 │  │  (Binance    │                    │  Port 1: Order Entry │   │
 │  │  co-lo)      │                    └──────────┬───────────┘   │
 │  └──────────────┘                               │ PCIe Gen5     │
 │                                                 ▼               │
 │  ┌──────────────┐                    ┌──────────────────────┐   │
 │  │  GPS/PTP     │───Pulse Per Second►│  Hot Path Server     │   │
 │  │  Grandmaster │                    │  (H100 + EPYC)       │   │
 │  │  Clock       │                    └──────────────────────┘   │
 │  │  (Trimble    │                             │                  │
 │  │  Thunderbolt)│                    ┌────────▼───────────┐     │
 │  └──────────────┘                    │  Thales Luna HSM   │     │
 │                                      │  (PCIe, on-prem)   │     │
 │  ┌──────────────────────────────┐    └────────────────────┘     │
 │  │  Management Network (1GbE)   │                                │
 │  │  - Monitoring agent          │                                │
 │  │  - SSH (jump host only)      │                                │
 │  │  - ClickHouse / Kafka        │                                │
 │  └──────────────────────────────┘                                │
 └──────────────────────────────────────────────────────────────────┘
         │
         │  MPLS private link (< 1ms) or VPN tunnel (DR only)
         │
 ┌──────────────── Equinix SG1 — DR Node ──────────────────────────┐
 │  (Warm standby — same hardware spec, Binance SG1 co-lo)          │
 │  Activated only on NY4 failure or exchange failover event         │
 └──────────────────────────────────────────────────────────────────┘
```

### 4.2 Time Synchronization — PTP + GPS

| Component | Specification |
|---|---|
| GPS Grandmaster | Trimble Thunderbolt E GPS Disciplined Oscillator — 1PPS output, ±50ns |
| PTP Profile | IEEE 1588-2008 (PTPv2), hardware timestamps via Solarflare NIC |
| PTP Client | `linuxptp` (`ptp4l` + `phc2sys`), synced to GPS grandmaster |
| NTP Fallback | Chrony with 3 external stratum-1 servers — only if GPS fails |
| Timestamp Field | `timestamp_ns` — nanosecond integer |
| Clock Drift Alert | WARNING > 10μs; CRITICAL > 100μs |

**Kernel timestamp capture:**
```c
setsockopt(fd, SOL_SOCKET, SO_TIMESTAMPNS, &val, sizeof(val));
```

**Verification:** Hourly cron compares local PTP time against three reference NTP servers; results
logged to `drift_metrics` table.

### 4.3 Exchange Connectivity & Rate Limiter

| Stream | Protocol | Session | Failover |
|---|---|---|---|
| Market data L1 (ticks) | WebSocket JSON/Binary SBE | Primary + backup feed | Auto-reconnect < 100ms |
| Market data L2 (order book) | WebSocket Binary | Separate subscription | Same session, separate channel |
| Order entry | REST HTTPS (+ WebSocket API where supported) | Dedicated trade session | Backup REST key + venue failover |
| Execution reports / drop copy | Exchange-native user stream (WebSocket) / FIX drop copy where supported | Independent session | Sequence checks + hash-chain persistence |
| Exchange rate limits | Per-exchange schedule | Tracked per endpoint | Back-off → HOLD action |

**[FIXED Mi9, Mi10, M2] Exchange API Rate Limiter — Rust:**

```rust
// src/execution/rate_limiter.rs
pub struct c_rate_limiter {
    cfg_max_weight:        u32,   // e.g., 1200 for Binance per minute
    cfg_window_ns:         u64,   // 60_000_000_000 (60 seconds in ns)
    v_current_weight:      u32,
    v_window_start_ns:     u64,
}

impl c_rate_limiter {
    pub fn f_check_and_consume(&mut self, v_endpoint_weight: u32) -> bool {
        let now_ns = f_clock_monotonic_ns();

        // [FIXED Mi10] Reset window when it expires
        if now_ns - self.v_window_start_ns >= self.cfg_window_ns {
            self.v_current_weight = 0;
            self.v_window_start_ns = now_ns;
        }

        // [FIXED Mi9] Compare against cfg_max_weight, NOT v_current_weight
        if self.v_current_weight + v_endpoint_weight > (self.cfg_max_weight * 80 / 100) {
            return false;  // At 80% limit → refuse
        }
        self.v_current_weight += v_endpoint_weight;
        true
    }
}

// [FIXED M2] Hot path behavior when rate limit refuses:
// In the actor dispatch loop, if f_check_and_consume returns false:
//   → Set v_action_direction = 0 (HOLD) for this batch
//   → Do NOT queue the order (unbounded latency)
//   → Log to drift_metrics with event_type = "RATE_LIMIT_HOLD"
//   → Wait for next tick batch (naturally throttled by tick arrival rate)
```

**Reconnect storm prevention (all exchange sessions):**
```rust
// Single coordinator for market data, order, and execution-report sessions.
// Prevents thundering-herd reconnect bursts.
pub fn f_next_reconnect_delay_ms(v_attempt: u32) -> u64 {
    let v_base = (100u64).saturating_mul(2u64.saturating_pow(v_attempt.min(8)));
    let v_cap  = 10_000u64;
    let v_jitter = f_rand_u64(0, 250);
    (v_base.min(v_cap)) + v_jitter
}

// Policy:
// - Only the connection manager may initiate reconnect.
// - Max one reconnect in-flight per session type.
// - Reset attempt counter only after 60s stable connectivity.
```

---

## 5. Data Ingestion, Feature Engineering & Feature Store

### 5.1 Mandatory Data Streams

| Stream | Format | Max Latency | Redundancy | Notes |
|---|---|---|---|---|
| Level 1 ticks | JSON / Binary SBE WebSocket | < 10μs | Dual NIC, dual feed | Seq-number validated |
| Level 2 order book (top 20) | Binary SBE WebSocket | < 10μs | Dual feed | Required for slippage estimation |
| Order acks & fills | Exchange user data stream (WebSocket) | < 50μs | Separate session + REST query fallback | Sequence continuity checked |
| Drop copy / execution archive | Normalized immutable execution-event stream | < 100μs ingest | Independent consumer path | Sequence numbers + SHA-256 hash chain |
| Exchange fee schedule | REST API | Daily pull at 01:00 UTC | Cached locally | Fail if > 24h stale |
| Funding rate (perps) | REST API | Every 8 hours | Cached | Applies to BTCUSDT, ETHUSDT, SOLUSDT |

**[FIXED M4] Market Data Feed Corruption / Gap Handling:**

```rust
// src/ingestion/feed_validator.rs
pub struct c_feed_validator {
    v_expected_seq_no:     u64,
    v_primary_active:      bool,
}

impl c_feed_validator {
    pub fn f_validate_packet(&mut self, pkt: &c_market_packet) -> c_feed_action {
        // Checksum validation
        if pkt.checksum != f_compute_checksum(&pkt.payload) {
            return c_feed_action::DiscardAndAlert("CHECKSUM_FAIL");
        }

        // Sequence number gap detection
        if pkt.seq_no != self.v_expected_seq_no {
            if self.v_primary_active {
                // Switch to backup feed immediately
                self.v_primary_active = false;
                f_alert("SEQ_GAP_SWITCH_TO_BACKUP", pkt.seq_no, self.v_expected_seq_no);
                return c_feed_action::SwitchFeedAndReprocess;
            } else {
                // Both feeds gapped: inject gap token and alert CRITICAL
                f_alert_critical("BOTH_FEEDS_GAPPED");
                return c_feed_action::InjectGapToken(pkt.exchange_ts_ns);
            }
        }

        self.v_expected_seq_no = pkt.seq_no + 1;
        c_feed_action::Process
    }
}
// On SwitchFeedAndReprocess: re-subscribe primary feed, switch back after 5s if primary recovers
```

### 5.2 Normalization — Exact Transforms

**[FIXED C1] All EWMA computations are TIME-BASED, not tick-based. The decay factor is computed
from elapsed wall-clock time so that the effective time constant is invariant to tick rate.**

```rust
// src/ingestion/normalizer.rs
// Time-based EWMA: α = 1 − exp(−Δt / τ)
// τ = time constant in seconds (e.g., τ_price = 60.0s, τ_volume = 60.0s)
// Δt = elapsed time since last tick in seconds

pub fn f_ewma_update(
    v_ewma_mean: &mut f32,
    v_ewma_var:  &mut f32,
    v_new_value: f32,
    v_dt_seconds: f32,    // elapsed seconds since last tick
    v_tau_seconds: f32,   // time constant (e.g., 60.0)
) {
    let alpha = 1.0 - (-v_dt_seconds / v_tau_seconds).exp();
    let v_delta = v_new_value - *v_ewma_mean;
    *v_ewma_mean += alpha * v_delta;
    *v_ewma_var  = (1.0 - alpha) * (*v_ewma_var + alpha * v_delta * v_delta);
}

// EWMA normalization:
//   v_price_norm = (price_raw − ewma_mean_price) / ewma_std_price
//   v_volume_norm = volume_raw / ewma_mean_volume
//   v_tau_price   = 60.0 seconds
//   v_tau_volume  = 60.0 seconds
```

All other transforms (imbalance, spread_bps, trade direction, time delta) unchanged from v1.0.

### 5.3 Feature Engineering — Complete Table

**[FIXED C2] Realized volatility windows are now expressed in seconds. The feature computation
finds all ticks within the past W seconds and computes std(log_returns) over that window.**
**Log-return lookback windows remain tick-relative (for short-horizon microstructure; at 10,000
ticks/sec, w∈{1,2,5,10,20,50,100,200,500,1000 ticks} = {0.1ms to 100ms}, which is appropriate
for HFT microstructure features).**

| Feature Name | Shape | Transform | Units |
|---|---|---|---|
| Log returns (10 windows) | (10,) | log(p_t / p_{t−w}), w ∈ {1,2,5,10,20,50,100,200,500,1000 ticks} | bps |
| Volume delta (10 windows) | (10,) | vol_t − vol_{t−w} (same w) | quote units |
| Order book skew (5 levels) | (5,) | (bid_k − ask_k) / (bid_k + ask_k), k=1..5 | dimensionless |
| Trade direction | (1,) | +1 / −1 / 0 | categorical |
| Time delta since last tick | (1,) | Δt_ms | ms |
| Spread bps | (1,) | v_spread_bps | bps |
| Mid-price velocity | (1,) | (mid_t − mid_{t−10ticks}) / 10 | bps/tick |
| Funding rate (perps) | (1,) | current_funding_rate | dimensionless |
| Order book depth ratio | (5,) | total_bid_k / total_ask_k per level | dimensionless |
| **[FIXED C2] Realized volatility (3 windows)** | (3,) | std(log_returns, **w_sec ∈ {60, 300, 900} seconds**) | bps |
| Gap indicator | (1,) | 1 if gap_token, else 0 | binary |
| Gap duration | (1,) | gap_duration_ms (0 if not gap) | ms |
| **Total** | **(128,)** | — | — |

**Final input tensor:** `t_tick_features` shape `(batch=64, time=64, features=128)`, dtype `float32`.

### 5.4 Feature Store

Technology: Custom Rust service with Redis backing store (for < 1ms reads), persisted to ClickHouse.

```sql
CREATE TABLE feature_store (
    feature_id      UInt64,
    symbol          LowCardinality(String),
    timestamp_ns    UInt64,
    feature_vector  Array(Float32),   -- 128 elements
    version         UInt16,
    PRIMARY KEY (symbol, timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))   -- [FIXED Mi3]
ORDER BY (symbol, timestamp_ns)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 30 DAY;

-- [FIXED M14] Secondary index for FK lookups from decision table
ALTER TABLE feature_store ADD INDEX idx_feature_id feature_id
    TYPE bloom_filter GRANULARITY 4;
```

**Training/serving consistency protocol:**
- Feature engineering code lives in one shared Rust library (`libpredator_features`)
- Both live pipeline and training pipeline import the same library
- Feature version stamped on every training artifact and every live inference
- If live feature version ≠ model's training feature version → refuse to start; alert

### 5.5 Gap Token Specification

**[FIXED M9] Gap token spread_bps now has a maximum age of 60 seconds. If the last known spread
is older than 60 seconds (e.g., during extended outage), the long-term median spread is used
instead to prevent stale flash-crash spreads from poisoning the feature stream.**

```rust
// Rust — gap token construction
let spread_age_ms = gap_start_ns - last_tick_ns / 1_000_000;
let spread_bps = if spread_age_ms < 60_000 {
    last_known_spread_bps           // recent enough — use it
} else {
    cfg_median_spread_bps_longterm  // stale — use 30-day median, recalculated daily
};

let gap_token = FeatureVector {
    log_returns:     [0.0; 10],
    volume_delta:    [0.0; 10],
    ob_skew:         [0.0; 5],
    trade_dir:       0.0,
    time_delta_ms:   gap_duration_ms as f32,
    spread_bps,                      // age-guarded
    gap_indicator:   1.0,
    gap_duration_ms: gap_duration_ms as f32,
    // all other fields: 0.0
};
```

### 5.6 Data Sources & Historical Data Specification

| Instrument | Exchange | Years | Start Date | End Date | Source |
|---|---|---|---|---|---|
| BTCUSDT perpetual | Binance | 5 | 2020-01-01 | 2025-01-01 | Binance historical data API |
| ETHUSDT perpetual | Binance | 5 | 2020-01-01 | 2025-01-01 | Binance historical data API |
| SOLUSDT perpetual | Binance | 4 | 2021-04-10 | 2025-01-01 | Binance historical data API |
| XAUUSD spot | LBMA / Interactive Brokers | 5 | 2020-01-01 | 2025-01-01 | IB historical ticks |
| BTC order book (L2) | Binance | 2 | 2023-01-01 | 2025-01-01 | Tardis.dev (tardis-dev npm v14+) |
| BTC/ETH options (OI, skew, OTC prints) | Deribit | 3 | 2022-01-01 | 2025-01-01 | Deribit REST API historical |
| Cross-market volume (dark pool estimation) | Kaiko / CoinMetrics | 3 | 2022-01-01 | 2025-01-01 | Kaiko Data API (institutional license) |

> **Tardis.dev client note:** Use the `tardis-dev` npm package (v14+, actively maintained, latest release Jan 2026).
> Do NOT use `tardis-client` (v1.2.4, deprecated, unmaintained for 5+ years). The Tardis.dev service and
> `tardis-dev` library are fully operational; only the legacy `tardis-client` package is deprecated.

> **Deribit historical data** (required for backtesting §5A OTC signal and §5D options skew signal):
> Available via Deribit REST API `/api/v2/public/get_historical_volatility` and
> `/api/v2/public/get_book_summary_by_currency`. Procurement: standard API account, no lead time.
> Storage: ~50 GB for 3-year BTC/ETH options OI + skew history.

> **Kaiko/CoinMetrics** (required for §5C dark pool volume estimation and Phase 3 ICV feature training):
> Procurement lead time: 4–8 weeks for institutional data licensing agreement.
> Storage: ~200 GB/year per source for cross-market volume aggregates.
> Begin procurement at Phase 0 gate to have data available before Phase 3 training (§31.3).
> Fallback: CoinMetrics Community API (free, lower resolution) for initial backtesting only.

**Minimum data quality requirements:**
- < 0.01% missing ticks (interpolated with gap tokens, not filled)
- No survivorship bias: include exchange outage periods (covered by gap tokens)
- Funding rate data aligned to 8-hour intervals exactly
- All timestamps verified against PTP reference; reject ticks with drift > 10ms

---


---

## Intelligence Architecture Overview

The following five intelligence modules (5A–5E) operate **exclusively on the warm/cold path**
(management network, cores 64+). They publish signals to Kafka and populate the **Intelligence
Context Cache (ICV)**. The 500μs hot-path SLA is **not affected**.

| Aspect | Status |
|---|---|
| Hot path (Ingestion → OMS, 500μs SLA) | **FULLY PRESERVED — zero changes** |
| Feature vector (128 dims) | **FULLY PRESERVED; expands to 160 dims in Phase 3 (§31.3)** |
| All existing Rust/CUDA code | **FULLY PRESERVED** |
| All v1.1 bug fixes (C1–C8, M1–M14, Mi1–Mi10) | **FULLY PRESERVED** |
| New intelligence modules | **ADDITIVE ONLY — warm/cold path** |
| Kelly fraction | Modified by Intelligence Multiplier (warm path, ≥100ms) |
| Risk thresholds | Conditionally tightened by Intelligence Signals (warm path) |
| NSR regime detector | Receives new conditioning input from ICC (warm path) |

```
══════════════════════════════════════════════════════════════════════════════════════
WARM/COLD PATH — INTELLIGENCE LAYER (cores 64+, management network, async)
All modules below have NO effect on the 500μs hot-path SLA.
══════════════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────────────────┐
│  SECTION 5A: WHALE INTELLIGENCE LAYER (ARGOS-style)                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────────────────┐   │
│  │ On-Chain    │ │ Wallet      │ │ Whale Type  │ │ Mining Pool          │   │
│  │ Clustering  │ │ Graph Scout │ │ Classifier  │ │ Coinbase Analyser    │   │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────────┬───────────┘   │
│  ┌──────┴──────┐ ┌──────┴──────────────────────────────────┐ │               │
│  │ ARGOS Score │ │ Multi-Layer Heuristic Clustering Engine  │ │               │
│  │ 0–100 / sym │ └──────────────────────────────────────────┘ │               │
│  └──────┬──────┘                                              │               │
│         └──────────────────────────┬────────────────────────┘                │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
┌──────────────────────────────────────────────────────────────────────────────┐
│  SECTION 5B: MEMPOOL INTELLIGENCE ENGINE                                     │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────────────┐  │
│  │ Mempool Monitor  │ │ Large-Tx Detector│ │ Congestion Scorer            │  │
│  │ (WebSocket node) │ │ (>$10M notional) │ │ (fee pressure → slippage)    │  │
│  └──────────┬───────┘ └──────────┬───────┘ └──────────────┬───────────────┘  │
│             └────────────────────┴────────────────────────┘                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
┌──────────────────────────────────────────────────────────────────────────────┐
│  SECTION 5C: MICROSTRUCTURE & DARK POOL INTELLIGENCE                         │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────────────┐  │
│  │ Iceberg Order    │ │ Smart Money Flow  │ │ Dark Pool Volume             │  │
│  │ Detector         │ │ (Nansen labels)   │ │ Estimator                    │  │
│  └──────────┬───────┘ └──────────┬───────┘ └──────────────┬───────────────┘  │
│             └────────────────────┴────────────────────────┘                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
┌──────────────────────────────────────────────────────────────────────────────┐
│  SECTION 5D: DERIVATIVE SIGNAL LAYER                                         │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────────────┐  │
│  │ Options Flow     │ │ Liquidation      │ │ Funding Rate                 │  │
│  │ Skew (Deribit)   │ │ Cascade Detector │ │ Regime Classifier            │  │
│  └──────────┬───────┘ └──────────┬───────┘ └──────────────┬───────────────┘  │
│             └────────────────────┴────────────────────────┘                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
                    ┌────────────────▼──────────────────────┐
                    │  KAFKA — Intelligence Topics           │
                    │  predator.intel.whale                  │
                    │  predator.intel.mempool                │
                    │  predator.intel.microstructure         │
                    │  predator.intel.derivatives            │
                    └────────────────┬──────────────────────┘
                                     │
                    ┌────────────────▼──────────────────────┐
                    │  INTELLIGENCE CONTEXT CACHE (Redis)    │
                    │  TTL: 120s per signal                  │
                    │  ICV: 32-dim float32 vector            │
                    │  (zero-padded if module offline)       │
                    └────────────────┬──────────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              ▼                      ▼                      ▼
    ┌─────────────────┐   ┌──────────────────┐   ┌───────────────────┐
    │  Kelly           │   │  NSR Regime      │   │  Risk Manager     │
    │  Intelligence    │   │  Conditioning    │   │  Threshold        │
    │  Multiplier      │   │  (§6.3 update)   │   │  Adjustment       │
    │  (§8.2 update)   │   │                  │   │  (§9.1 update)    │
    │  Range: 0.5–1.5  │   │  Warm path only  │   │  VaR tighten-on-  │
    │  Latency: ≥100ms │   │  Latency: ≥100ms │   │  whale-signal     │
    └─────────────────┘   └──────────────────┘   └───────────────────┘

══════════════════════════════════════════════════════════════════════════════════
SECTION 17A: NETWORK DEFENSE LAYER (tNeuron / Peer-Observer / AToM / LION)
Monitors our own network exposure; feeds Section 17 security alerting only.
══════════════════════════════════════════════════════════════════════════════════
```

---



<a name="5A"></a>
## Section 5A — Whale Intelligence Layer

### 5A.1 Purpose & Alpha Hypothesis

Large market participants ("whales") with positions >$10M notional regularly move price 0.5–3% on
BTC/ETH. Their preparation (address consolidation, OTC desk engagement, coinbase transaction patterns)
leaves observable on-chain signals 30–120 minutes before a spot move. This layer scores whale
activity and infers directional intent, feeding the Kelly Multiplier and NSR regime detector.

**Alpha hypothesis:** When whale score ≥ 70/100 with accumulator classification, increase exposure
by 1.2× via Kelly Multiplier. When whale score ≥ 70 with distributor classification, reduce exposure
by 0.7× and tighten stop-loss by 20%.

### 5A.2 Module Architecture

All 5A modules run as **Docker services** on cores 64+ (management network). They poll external APIs
and on-chain nodes on schedules defined in §5A.6.

#### 5A.2.1 ARGOS Whale Scoring Engine

ARGOS (Adaptive Regime and Grading Operations System) is a local-first AI agent system that scores
whale activity on a 0–100 scale per symbol. It runs 6 specialized agents, each as an independent
Docker service, publishing to Kafka.

```
┌─────────────────────────────────────────────────────────────┐
│ ARGOS ENGINE — 6 Docker Services (management network)       │
│                                                             │
│  Agent-1: OnChain Profiler                                  │
│    • Polls full-node RPC (Bitcoin/Ethereum) every 30s       │
│    • Detects address consolidations ≥ 500 BTC / 5,000 ETH  │
│    • Output: v_consolidation_score (0–100), direction hint  │
│                                                             │
│  Agent-2: Exchange Flow Monitor                             │
│    • Monitors public exchange wallet inflows/outflows        │
│    • Sources: Nansen API, Arkham Intelligence API           │
│    • Alert: Exchange inflow surge > 2σ above 30d baseline   │
│    • Output: v_exchange_flow_score (0–100)                  │
│                                                             │
│  Agent-3: OTC Signal Detector                               │
│    • Monitors large block trade prints on CME, Deribit OTC  │
│    • Detects print patterns consistent with institutional   │
│      accumulation (repeated same-side fills at same price)  │
│    • Output: v_otc_signal_score (0–100)                     │
│                                                             │
│  Agent-4: Derivatives Hedging Detector (feeds §5D also)     │
│    • Monitors Deribit options open interest change velocity │
│    • Large put buying = whale hedging a long position       │
│    • Large call buying = whale hedging a short position     │
│    • Output: v_hedge_signal_score (0–100), hedge_direction  │
│                                                             │
│  Agent-5: Security Sentinel                                 │
│    • Detects anomalous API usage, unusual order patterns    │
│    • Feeds Section 17A network defense layer                │
│    • Output: v_anomaly_score (0–100)                        │
│                                                             │
│  Agent-6: Whale Type Classifier (ML sub-model)              │
│    • Input: agent 1–4 outputs (concatenated vector)         │
│    • Output: enum {ACCUMULATOR, DISTRIBUTOR, NEUTRAL}       │
│    • Model: Random Forest (100 trees, sklearn; ONNX export) │
│    • Retrained: weekly on last 90 days of labeled data      │
│    • Labeling: price action +4h after whale event           │
└─────────────────────────────────────────────────────────────┘
```

**ARGOS composite score formula:**
```python
def f_argos_score(
    v_consolidation: float,   # 0–100
    v_exchange_flow: float,   # 0–100
    v_otc_signal:   float,    # 0–100
    v_hedge:        float,    # 0–100
) -> float:
    # Weights calibrated on 2-year backtest (updated quarterly).
    # Calibration objective: maximize Spearman ρ between weighted score and 4h price return
    # across the rolling 24-month window. Optimization: scipy.optimize.minimize with bounds
    # [0.05, 0.60] per weight, sum-to-1 constraint, 1000-iteration L-BFGS-B.
    # New weights enter a 14-day shadow period (observed, not applied) before deployment.
    # Weight change > ±0.10 from prior quarter requires ML Lead + CRO sign-off.
    cfg_w = [0.35, 0.30, 0.20, 0.15]
    v_raw = (cfg_w[0] * v_consolidation +
             cfg_w[1] * v_exchange_flow +
             cfg_w[2] * v_otc_signal +
             cfg_w[3] * v_hedge)

    # 85–90% of noise filtered by confidence gate:
    # Only publish score if ≥ 2 of 4 agents exceed 40/100
    v_active_agents = sum([
        v_consolidation > 40,
        v_exchange_flow > 40,
        v_otc_signal > 40,
        v_hedge > 40,
    ])
    if v_active_agents < 2:
        return 0.0   # No signal — publish zero (noise filtered)
    return v_raw
```

**ICV slots populated by 5A:** slots 0–5 (of 32 total)

| ICV Slot | Signal | Range | Update Rate |
|---|---|---|---|
| 0 | `v_argos_score_BTC` (normalized 0–1) | 0.0 – 1.0 | 30s |
| 1 | `v_argos_score_ETH` (normalized 0–1) | 0.0 – 1.0 | 30s |
| 2 | `v_argos_score_SOL` (normalized 0–1) | 0.0 – 1.0 | 30s |
| 3 | `v_whale_type_BTC` | −1 (dist) / 0 / +1 (accum) | 30s |
| 4 | `v_whale_type_ETH` | −1 / 0 / +1 | 30s |
| 5 | `v_consolidation_alert` | 0 (none) / 1 (active) | 30s |

#### 5A.2.2 Multi-Layer Heuristic Clustering Engine

Combines on-chain transaction graph data with off-chain exchange application data to uncover
hidden wallet connections and darknet market flows that the ARGOS agents do not individually see.

```python
# Runs OFFLINE (cold path) — results cached in Redis, refreshed every 6 hours
# Does NOT run on hot path

class c_wallet_cluster_engine:
    """
    Graph-based wallet clustering combining:
    1. Common-input ownership heuristic (on-chain)
    2. Peel-chain analysis for change address tracking
    3. Exchange deposit address heuristic (off-chain labeling from Nansen/Arkham)

    Output: dict[address → cluster_id], cluster behavioral profile
    """
    def f_build_graph(self, utxo_set: list) -> nx.DiGraph:
        # networkx graph; nodes = addresses, edges = tx flows
        # Nansen/Arkham label overlays applied at node level
        ...

    def f_detect_consolidation_event(
        self,
        v_cluster_id: str,
        v_threshold_btc: float = 500.0,
    ) -> bool:
        # Returns True if cluster sent > threshold_btc to single address in last 4h
        ...
```

**Data sources:** Blockstream.info API (BTC UTXO), Alchemy (ETH), Nansen API, Arkham Intelligence API.
All API keys stored in Thales HSM secrets store (same HSM, separate partition from trading keys).

#### 5A.2.3 Mining Pool Coinbase Analyser — ⚠️ DEFERRED TO PHASE 3

> **Cost-optimisation deferral:** This module is deferred until Phase 3 (§31.3) or later.
> Rationale: (a) Niche alpha signal with no validated backtest evidence of edge; (b) requires
> PoolDetective API + monthly fingerprint updates = additional maintenance burden; (c) the
> signal fires at most once per 10-minute BTC block, making it low-frequency and low-priority
> for a system already scoring whale activity via Agents 1–4. Re-evaluate after Phase 2 gate
> when ARGOS composite signal correlation is validated. If the composite score (Agents 1–4)
> already achieves ρ > 0.15, the marginal value of this module is minimal.

Implements the "Proof of Work" method: every BTC block contains a coinbase transaction whose
`scriptSig` encodes the mining pool's identity. If an anomalously large transaction appears in a
block whose coinbase suggests a previously unknown pool arrangement, this may indicate a whale
using a private mining arrangement to bypass the public mempool.

```python
# Cold path — runs once per BTC block (~10min)
def f_analyse_coinbase(block: dict) -> dict:
    """
    Parses block.coinbase.scriptSig and matches against known pool fingerprint database.
    Returns: {pool_name, is_known, coinbase_anomaly_score}

    Known pool fingerprints: BTCCOM, AntPool, F2Pool, Foundry, ViaBTC, etc.
    Updated monthly from PoolDetective / BTC.com API.

    coinbase_anomaly_score logic:
      - If pool is unknown AND block contains tx > 1000 BTC bypassing mempool: score = 100
      - If pool is known but unusual extranonce pattern: score = 40–70
      - Otherwise: score = 0
    """
    ...
```

### 5A.3 API Rate Limits & Fallback

| API | Rate Limit | Fallback on Limit |
|---|---|---|
| Nansen API | 20 req/sec / 500 req/min (Pro plan — single tier as of Sep 2025) | Cache last known result; ICV slot set to last value; alert after 5 min stale |
| Arkham Intelligence API | 100 req/min | Same as above |
| Blockstream.info (BTC RPC) | Self-hosted full node preferred; API fallback | Alert and degrade gracefully; publish zero scores |
| Alchemy (ETH) | Growth tier: 330 req/sec | Fallback to Infura (backup key in HSM) |

**Stale data policy:** If any data source is stale >120s, publish `v_data_stale=1` bit in Kafka
message header. The ICC reads this and suppresses the affected ICV slots (zeroed), ensuring the
Kelly Multiplier does not act on stale whale signals.

---



<a name="5B"></a>
## Section 5B — Mempool Intelligence Engine

### 5B.1 Purpose & Alpha Hypothesis

The BTC and ETH mempools contain large pending transactions that, when confirmed, move price.
Monitoring the mempool 30–120 seconds before confirmation allows the system to:
1. Anticipate fee pressure spikes (adjust slippage estimation)
2. Detect large pending transactions that may move market price on confirmation
3. Score network congestion to calibrate the execution urgency parameter

**Alpha hypothesis:** Large pending tx detection (>$10M notional) → increase urgency (shift from
limit to market) and increase Kelly sizing if direction aligns with whale type from §5A.

### 5B.2 Mempool Monitor

```python
# Runs as Docker service on management network, cores 64+
# Connects to a self-hosted full node (Bitcoin Core 26.x / Geth / Reth)

class c_mempool_monitor:
    cfg_min_tx_notional_usd:   float = 10_000_000.0  # $10M minimum large tx
    cfg_update_interval_ms:    int   = 500             # 0.5s polling
    cfg_congestion_ewma_tau_s: float = 30.0            # 30s EWMA for congestion

    def f_listen_ws(self):
        """
        Subscribes to full-node WebSocket for new transactions.
        For BTC: bitcoin-cli -rpcwait getzmqnotifications / ZMQ rawmempool
        For ETH: eth_subscribe('newPendingTransactions') on local Reth node
        """
        ...

    def f_detect_large_tx(self, tx: dict, v_price_usd: float) -> bool:
        v_notional = tx['value'] * v_price_usd
        return v_notional >= self.cfg_min_tx_notional_usd

    def f_congestion_score(self, v_mempool_fee_rate_sat_vbyte: float) -> float:
        """
        Normalized congestion score 0–1.
        0 = empty mempool (normal conditions)
        1 = extreme congestion (fee spike in progress)
        Percentile bounds recalibrated monthly (first Sunday 03:00 UTC) from rolling
        24-month fee rate distribution. Fixed values are initial defaults only.
        """
        v_p1  = cfg_mempool_fee_p1_sat_vbyte   # loaded from config; default 2.0
        v_p99 = cfg_mempool_fee_p99_sat_vbyte  # loaded from config; default 300.0
        return float(np.clip(
            (v_mempool_fee_rate_sat_vbyte - v_p1) / (v_p99 - v_p1),
            0.0, 1.0
        ))
```

**ICV slots populated by 5B:** slots 6–9

| ICV Slot | Signal | Range | Update Rate |
|---|---|---|---|
| 6 | `v_mempool_congestion` | 0.0 – 1.0 | 500ms |
| 7 | `v_large_tx_pending_BTC` | 0 (none) / 1 (≥$10M pending) | 500ms |
| 8 | `v_large_tx_pending_ETH` | 0 / 1 | 500ms |
| 9 | `v_mempool_fee_pct_change_1min` | −1.0 – 1.0 | 30s |

### 5B.3 Infrastructure Requirements for Mempool Module

| Component | Specification |
|---|---|
| Bitcoin full node | Bitcoin Core 26.x, txindex=1, ZMQ enabled, management NIC only |
| Ethereum full node | Reth (preferred) or Geth 1.14, --ws enabled, management NIC only |
| RAM allocation | BTC node: 32GB; ETH node: 64GB (management server, NOT trading server) |
| Storage | BTC: 700GB NVMe; ETH: 2TB NVMe; separate storage from trading data |
| Network | Management NIC only — isolated from hot-path trading NICs |

> **ADR-018:** Full nodes run on the MANAGEMENT server, not the trading server. They share
> no physical resources with the hot path (H100, Solarflare NIC, Thales HSM).

---



<a name="5C"></a>
## Section 5C — Market Microstructure & Dark Pool Intelligence

### 5C.1 Purpose & Alpha Hypothesis

Institutional participants using OTC dark pools leave detectable microstructure signatures:
- **Iceberg orders:** Persistent large orders at a price level that refill after each fill
- **Smart Money flow:** Wallet labels from Nansen/Arkham indicating known institutional flows
- **Dark pool volume estimation:** Significant print-to-volume discrepancy vs. on-exchange

**Alpha hypothesis:** Iceberg order on bid = strong buy support → Kelly Multiplier +15%.
Iceberg order on ask = strong sell resistance → Kelly Multiplier −20% and hold on new longs.

### 5C.2 Iceberg Order Detector

```python
# Uses L2 order book data already streaming from exchange WebSocket
# Runs as async processor on cores 64+ (consumes from existing Kafka order book topic)

class c_iceberg_detector:
    cfg_refill_threshold:     float = 0.80  # Order refills to ≥80% of original size
    cfg_min_fill_count:       int   = 3     # Seen refilling ≥3 times
    cfg_price_window_bps:     float = 5.0   # Track order at ±5bps price level
    cfg_lookback_seconds:     float = 300.0 # 5-minute observation window

    v_bid_iceberg_tracker: dict   # {price_level: fill_count}
    v_ask_iceberg_tracker: dict

    def f_update(self, ob_snapshot: c_orderbook_snapshot) -> None:
        """
        Compares consecutive L2 snapshots.
        If a size at a given price level drops significantly then rapidly refills
        back to near-original size, increment fill_count for that level.
        """
        for level in ob_snapshot.bids:
            v_key = round(level.price, cfg_tick_precision)
            if self._detect_refill(v_key, level.size, 'bid'):
                self.v_bid_iceberg_tracker[v_key] = \
                    self.v_bid_iceberg_tracker.get(v_key, 0) + 1

        for level in ob_snapshot.asks:
            v_key = round(level.price, cfg_tick_precision)
            if self._detect_refill(v_key, level.size, 'ask'):
                self.v_ask_iceberg_tracker[v_key] = \
                    self.v_ask_iceberg_tracker.get(v_key, 0) + 1

    def f_iceberg_score(self, side: str) -> float:
        """Returns 0–1 score. 1 = strong confirmed iceberg on this side."""
        tracker = self.v_bid_iceberg_tracker if side == 'bid' \
                  else self.v_ask_iceberg_tracker
        if not tracker:
            return 0.0
        v_max_fills = max(tracker.values())
        return float(min(v_max_fills / 10.0, 1.0))  # 10 fills = score of 1.0
```

### 5C.3 Smart Money Flow Monitor

```python
# Polls Nansen "Smart Money" label API every 60s
# Nansen labels wallets as: Smart Money, Dumb Money, Exchange, Fund, etc.

class c_smart_money_flow_monitor:
    def f_compute_net_flow(
        self,
        v_smart_inflows_usd:  float,
        v_smart_outflows_usd: float,
    ) -> float:
        """
        Net smart money flow, normalized to [-1, 1] range.
        +1 = all smart money flowing in (strong buy signal)
        -1 = all smart money flowing out (strong sell signal)
        Normalization: tanh(net_flow / cfg_normalizer_usd)
        """
        v_net = v_smart_inflows_usd - v_smart_outflows_usd
        return float(np.tanh(v_net / cfg_smart_money_normalizer_usd))
    # cfg_smart_money_normalizer_usd = 50_000_000  # $50M = ~tanh(1.0)
```

### 5C.4 Dark Pool Volume Estimator

Uses the canonical method: compare reported on-exchange volume (from Binance/OKX) against
estimated total market volume from Kaiko / CoinMetrics. Significant discrepancy implies
off-exchange (dark pool / OTC) activity.

```python
def f_dark_pool_fraction(
    v_exchange_volume_usd:    float,   # From primary exchange
    v_total_market_volume_usd: float,  # From Kaiko/CoinMetrics aggregate
) -> float:
    """
    Dark pool fraction = (total − exchange) / total
    Range: 0.0 (all on-exchange) to 1.0 (all off-exchange)
    High dark pool fraction during price consolidation → large move likely pending.
    """
    if v_total_market_volume_usd < 1.0:
        return 0.0
    return float(np.clip(
        (v_total_market_volume_usd - v_exchange_volume_usd) / v_total_market_volume_usd,
        0.0, 1.0
    ))
```

**ICV slots populated by 5C:** slots 10–14

| ICV Slot | Signal | Range | Update Rate |
|---|---|---|---|
| 10 | `v_iceberg_bid_score` | 0.0 – 1.0 | 1s |
| 11 | `v_iceberg_ask_score` | 0.0 – 1.0 | 1s |
| 12 | `v_smart_money_net_flow` | −1.0 – 1.0 | 60s |
| 13 | `v_dark_pool_fraction` | 0.0 – 1.0 | 60s |
| 14 | `v_dark_pool_fraction_1h_change` | −1.0 – 1.0 | 60s |

---



<a name="5D"></a>
## Section 5D — Cross-Instrument Derivative Signal Layer

### 5D.1 Purpose & Alpha Hypothesis

Whales executing large spot trades cannot fully hide their hedging activity in derivatives markets.
This layer identifies the "smoking gun": large options flow or abnormal futures positioning that
precedes a spot move.

**Alpha hypothesis:** Put-call skew >2σ above baseline on Deribit → downside hedge by a large
holder → adjust Kelly Multiplier −25% and move existing longs to market stop-loss.

### 5D.2 Options Flow Skew Monitor (Deribit)

```python
# Polls Deribit REST API every 30s for BTC and ETH options summary

class c_options_flow_monitor:
    cfg_deribit_api_url: str = "https://www.deribit.com/api/v2/public/"

    def f_get_put_call_skew(
        self,
        symbol: str,      # "BTC" or "ETH"
        expiry: str,      # nearest active expiry
    ) -> float:
        """
        Put-Call ratio by open interest for nearest expiry.
        PC_ratio = total_put_OI / total_call_OI
        Normalized: v_skew = (PC_ratio - ewma_30d) / std_30d
        Output range: typically -3 to +3 (z-score)
        """
        ...

    def f_detect_institutional_hedge(
        self,
        v_put_call_skew: float,
        v_oi_change_1h: float,
    ) -> bool:
        """
        Institutional hedge signature:
        - PC skew > +2.0 (heavy put buying) AND
        - OI change > +20% in 1 hour (new positions opened, not rollovers)
        """
        return v_put_call_skew > 2.0 and v_oi_change_1h > 0.20
```

### 5D.3 Liquidation Cascade Detector (Coinglass)

**Rate limit:** Coinglass HOBBYIST tier: 30 req/min. At 2 req/min baseline (30s polling × 2 symbols),
well within budget. If polling expands to all 4 instruments at 15s cadence (8 req/min), still safe.
On `HTTP 429`: fall back to cached liquidation snapshot; publish `v_data_stale=1` in Kafka header;
ICV slots 18–19 set to last known value until next successful poll (same stale-data policy as §5A.3).
Alert WARNING if stale > 120s.

```python
# Polls Coinglass API every 30s for liquidation data

class c_liquidation_cascade_detector:
    cfg_cascade_threshold_usd: float = 100_000_000.0   # $100M in 1h triggers cascade alert

    def f_cascade_risk_score(
        self,
        v_liq_1h_usd_long:  float,
        v_liq_1h_usd_short: float,
        v_price_dist_to_major_liq: float,  # Distance to nearest $50M+ cluster (bps)
    ) -> float:
        """
        Returns cascade risk score 0–1.
        High score = price is close to a large liquidation cluster.
        A forced cascade is a directional alpha signal.
        """
        v_total_liq = v_liq_1h_usd_long + v_liq_1h_usd_short
        v_liq_score = float(np.clip(v_total_liq / self.cfg_cascade_threshold_usd, 0.0, 1.0))
        v_proximity_score = float(np.clip(1.0 - v_price_dist_to_major_liq / 100.0, 0.0, 1.0))
        return 0.5 * v_liq_score + 0.5 * v_proximity_score

    def f_cascade_direction(
        self,
        v_liq_1h_usd_long:  float,
        v_liq_1h_usd_short: float,
    ) -> int:
        """
        +1 if more long liquidations pending (price drop cascade)
        -1 if more short liquidations pending (price rise cascade — short squeeze)
        """
        if v_liq_1h_usd_long > v_liq_1h_usd_short:
            return -1   # Long liquidations → market drops
        elif v_liq_1h_usd_short > v_liq_1h_usd_long:
            return +1   # Short liquidations → market rises (short squeeze)
        return 0
```

### 5D.4 Funding Rate Regime Classifier

The perpetual swap funding rate already appears in the 128-dim feature vector (slot from §5.3).
This module **adds regime classification** on top of the raw rate:

```python
def f_classify_funding_regime(v_funding_rate: float) -> int:
    """
    Regime 0: NEUTRAL  — |rate| < 0.01%  (8h)   → normal carry
    Regime 1: LONGS_CROWDED — rate > +0.05%      → expensive to be long; squeeze risk
    Regime 2: SHORTS_CROWDED — rate < -0.05%     → expensive to be short; squeeze risk
    Regime 3: EXTREME_CROWDING — |rate| > 0.10%  → very high liquidation cascade risk
    """
    if abs(v_funding_rate) > 0.0010:   # 0.10% threshold
        return 3
    elif v_funding_rate > 0.0005:
        return 1
    elif v_funding_rate < -0.0005:
        return 2
    return 0
```

**ICV slots populated by 5D:** slots 15–21

| ICV Slot | Signal | Range | Update Rate |
|---|---|---|---|
| 15 | `v_put_call_skew_BTC` | −3.0 – 3.0 (z-score) | 30s |
| 16 | `v_put_call_skew_ETH` | −3.0 – 3.0 | 30s |
| 17 | `v_oi_change_1h_BTC` | −1.0 – 1.0 | 30s |
| 18 | `v_cascade_risk_score` | 0.0 – 1.0 | 30s |
| 19 | `v_cascade_direction` | −1 / 0 / +1 | 30s |
| 20 | `v_funding_regime_BTC` | 0 / 1 / 2 / 3 | 8h (cached) |
| 21 | `v_funding_regime_ETH` | 0 / 1 / 2 / 3 | 8h (cached) |

---



<a name="5E"></a>
## Section 5E — Intelligence Context Cache & Integration Bridge

### 5E.1 Intelligence Context Vector (ICV)

The ICV is a 32-dimensional float32 vector. Slots 0–21 are populated by modules 5A–5D.
Slots 22–31 are reserved for future signals. All slots are initialized to 0.0.

```rust
// src/intelligence/icv.rs
pub struct c_intelligence_context_vector {
    v_slots: [f32; 32],    // 32-dim ICV
    v_slot_ages_ms: [u64; 32],  // milliseconds since last update per slot
    cfg_stale_threshold_ms: u64,  // 120_000 (120 seconds)
}

impl c_intelligence_context_vector {
    pub fn f_get_slot(&self, slot: usize) -> f32 {
        // Return 0.0 if data is stale (module offline)
        if self.v_slot_ages_ms[slot] > self.cfg_stale_threshold_ms {
            return 0.0;  // Fail-safe: stale data → no signal → neutral
        }
        self.v_slots[slot]
    }

    pub fn f_is_any_stale(&self) -> bool {
        self.v_slot_ages_ms.iter().any(|&age| age > self.cfg_stale_threshold_ms)
    }
}
```

### 5E.2 Redis Cache Protocol

```
Key format:   predator:icv:{symbol}          (e.g., predator:icv:BTCUSDT)
Value format: Serialized c_intelligence_context_vector (binary, 32×4 + 32×8 = 384 bytes)
TTL:          120 seconds (auto-expire)
Write:        Each intelligence module updates only its own slots
Read:         Kelly Multiplier and NSR conditioning read full ICV every 100ms
```

### 5E.3 Module Health Dashboard

All 5A–5D modules publish a heartbeat to `predator.intel.health` Kafka topic every 5s.
Grafana dashboard shows per-module staleness, API call counts, and error rates.

**Alert thresholds:**
- WARNING: Any module heartbeat gap > 30s
- CRITICAL: Any module heartbeat gap > 120s (staleness threshold — ICV slots zeroed)
- PAGE: All modules offline simultaneously (suggests management network failure)

### 5E.4 External Dependency SLO Matrix

For each external provider (Nansen, Arkham, Alchemy, Infura, Coinglass, Deribit, Kaiko):
- Track p95 latency, error rate, and data staleness age.
- Define provider SLO budget and alert thresholds.
- On SLO breach, affected ICV slots are neutralized (0.0) and marked stale; no hot-path halt.
- Dependency health dashboard is mandatory in Section 20.4.

---



## 6. ML Model Specifications (Corrected, No Fictional Components)

### 6.1 Model Registry

| Model | Paper Reference | Role | Input | Output |
|---|---|---|---|---|
| Mamba-2 | Dao & Gu, 2024 (arxiv:2405.21060) | Perception | (64,64,128) float32 | (64,256) float32 |
| CoPE | Olsson et al., 2024 (arxiv:2405.18719) | Positional encoding | time deltas | positional bias |
| HGRN-2 | Qin et al., 2023 (arxiv:**2311.04823**) | Hierarchical gating | scan output | gated output |
| Neural SDE | Li et al., 2020 (arxiv:2002.14028) | Physics dynamics | (q,p) | (q_final,p_final) |
| TD-MPC2 | Hansen et al., 2023 (arxiv:2310.16828) | World model (offline only) | (latent, action) | (next_latent, reward) |
| NSR (diffusion) | d'Ascoli et al., 2023 (arxiv:2310.02227) | Symbolic regression | trajectory | equation string |
| Surrogate Decision Tree | scikit-learn + ONNX export | Explainability | features | action class + reason code |
| OOD Detector (warm path) | IsolationForest | Explainability reliability gate | features | `b_explanation_ood` |

### 6.2 Mamba-2 + CoPE + HGRN-2 — Complete Specification

**Input:** `t_tick_features` — shape `(B=64, T=64, F=128)`, dtype `float32`, range `[−5, 5]`

**[FIXED Mi8] CoPE Layer — with explicit `w_positional` definition:**
```python
class c_cope_encoder(nn.Module):
    cfg_window_ms: float = 100.0
    cfg_alpha:     float = 0.1

    def __init__(self, d_input: int = 128):
        super().__init__()
        # [FIXED Mi8] Explicit shape definition: (1, 1, d_input) for B×T broadcasting
        self.w_positional = nn.Parameter(torch.randn(1, 1, d_input) * 0.02)

    def f_forward(self, t_input: Tensor, v_time_deltas_ms: Tensor) -> Tensor:
        # v_time_deltas_ms: shape (B, T), units: milliseconds
        t_decay = torch.exp(-self.cfg_alpha * v_time_deltas_ms / self.cfg_window_ms)
        t_bias  = t_decay.unsqueeze(-1) * self.w_positional  # (B, T, d_input)
        return t_input + t_bias
```

**Mamba-2 Block (4 layers, each identical):** Unchanged from v1.0.

**[FIXED Mi5] HGRN-2 citation corrected.** The HGRN-2 paper is Qin et al. (2023),
"Hierarchically Gated Recurrent Neural Network for Sequence Modeling," arxiv:2311.04823.
The gate computation is:
```python
t_gate = torch.sigmoid(self.w_hgrn(t_y) + self.b_hgrn)
t_y    = t_y * t_gate  # elementwise gating
```

**Output projection:** Linear `512 → 256`. First 128 = q (position), last 128 = p (momentum).

**Training loss:**
```
L_mamba = MSE(f_reconstruct(q, p), t_tick_features)
         + 0.1 × MSE(f_predict_next_price(q, p), actual_next_price)
```

### 6.3 NSR (Neural Symbolic Regression) — Complete Specification

**Architecture:** Transformer encoder (4 layers, 8 heads, d_model=256), diffusion decoder (1000 steps).

**Gating Logic:** confidence > 0.60 → log; > 0.75 → reward shaping bonus = 0.001 × agreement.

**[FIXED Mi7] Regime K-means recalibration schedule:**
```python
# K-means regime assignment (K=5) runs WEEKLY at Monday 05:00 UTC
# Uses rolling 1-hour latent-state statistics from the past 7 days
# Regime ID stability: new centroids matched to old using Wasserstein distance
# (Hungarian algorithm assignment) to ensure regime IDs are semantically stable
# across recalibrations. Alert if any centroid moves > 2× std from previous position.
cfg_nsr_regime_k:              5
cfg_nsr_regime_recal_utc_day:  0   # Monday
cfg_nsr_regime_recal_utc_h:    5   # 05:00 UTC
```



### 6.3 Update — NSR Intelligence Conditioning

The NSR (Neural Symbolic Regression) regime detector receives the ICV as an **additional
conditioning input** on the warm path (≥100ms latency, separate from hot path).

```python
# NSR regime conditioning — warm path only (NOT hot path)
# Runs on cores 64+, does NOT affect the 500μs hot-path SLA

class c_nsr_intelligence_conditioner:
    """
    Reads ICV from Redis every 100ms.
    Computes regime_bias: a scalar offset applied to NSR's K-means centroid distances.
    This biases the regime assignment probability WITHOUT overriding the hot-path NSR output.
    The hot-path NSR continues to run at full speed; the bias is applied to the
    weekly K-means recalibration (§6.3) to steer future regime boundaries.
    """
    def f_compute_regime_bias(self, icv: list[float]) -> dict[str, float]:
        v_whale_pressure = max(icv[0], icv[1], icv[2])   # Max whale score across symbols
        v_cascade_risk   = icv[18]
        v_dark_pool      = icv[13]

        return {
            "bias_bull_regime": +0.1 * v_whale_pressure * (icv[3] + icv[4]) / 2.0,
            "bias_bear_regime": +0.1 * v_whale_pressure * (-(icv[3] + icv[4]) / 2.0),
            "bias_volatile_regime": +0.15 * v_cascade_risk,
            "bias_thin_market": +0.10 * v_dark_pool,
        }
    # Bias is applied at the weekly K-means recalibration ONLY (ADR-020)
    # Not applied to per-tick live regime assignment
```

---



### 6.4 TD-MPC2 World Model — Complete Specification

**Purpose:** Offline planning to generate actor training targets. CEM-GD runs offline against world
model — **never** on the live hot path.

**Architecture:** Ensemble of 5 MLPs, each `(256 + 8) → 512 → 512 → (256 + 1)`.

**CEM-GD offline planning:**
- Horizon H=10; Population N=64; Iterations 5
- Output: optimal action sequence per episode → stored as actor training labels
- Not executed live under any circumstances

---

## 7. Physics Engine — Neural SDE

### 7.1 Theoretical Foundation

Markets exhibit dissipative dynamics. The Hamiltonian (energy-conserving) assumption of SymODEN is
physically invalid. The Neural SDE captures dissipation (−γp) and stochastic forcing (σ dW).

### 7.2 SDE Equations

```
dq = p dt
dp = (−∇U(q) − γp) dt + σ dW    [training only]
dp = (−∇U(q) − γp) dt            [live inference — σ·dW = 0; see §7.4]

where:
  U(q)  = learned potential energy (MLP: R^128 → R^1)
  γ     = learned friction (scalar ≥ 0, constrained via softplus)
  σ     = learned diffusion (scalar ≥ 0, used in training loss only)
  dW    = Wiener process increment ~ N(0, dt)  [training only]
```

### 7.3 U(q) — Potential Energy Network

```python
class c_potential_net(nn.Module):
    # U: R^128 → R^1
    layers = [
        nn.Linear(128, 256), nn.Tanh(),
        nn.Linear(256, 256), nn.Tanh(),
        nn.Linear(256, 1)
    ]
    # Gradient ∇U(q) — see §7.4 for how this is computed on hot path
```

### 7.4 Störmer-Verlet Integration — [FIXED C4, C5]

**[FIXED C4] Autograd removed from hot path.** The original code called
`torch.autograd.grad(...)` twice per Verlet step × 10 steps = 20 backward passes per inference,
which would consume several milliseconds and destroy the 80μs SDE budget.

**Fix:** The gradient ∇U(q) is computed using a SEPARATE analytically pre-compiled gradient network
`c_grad_U_net` (a closed-form Jacobian-vector product compiled via `torch.compile(fullgraph=True)`),
or equivalently via a single fused forward+backward CUDA kernel. The computational graph is
destroyed immediately; `retain_graph=False` is default and no graph is accumulated.

**[FIXED C5] Stochastic noise removed from live inference.** During live trading, the SDE runs
in deterministic mode (σ·dW = 0). Rationale:
1. Same market input → reproducible decision → auditable reason_code
2. Actor was trained against TD-MPC2 world model (deterministic latent transitions) → no train-serve skew
3. Noise models market uncertainty but the optimal action is based on E[future state], not a single noise sample

Stochastic mode remains in TRAINING to correctly fit the SDE to market noise statistics.

```python
def f_stormer_verlet_step(
    t_q:       Tensor,       # (B, 128) float32
    t_p:       Tensor,       # (B, 128) float32
    v_dt:      float,        # 0.001s (fixed)
    v_gamma:   float,        # learned friction (softplus-constrained ≥ 0)
    b_training: bool = False, # True during training only
    v_sigma:   float = 0.0,  # only used when b_training=True
) -> tuple[Tensor, Tensor]:

    # [FIXED C4] Gradient computed via compiled gradient network, NOT autograd
    with torch.no_grad():
        t_grad_U = c_grad_U_net.forward(t_q)   # (B, 128), pre-compiled fused kernel

    # Half-step momentum
    t_p_half = t_p - 0.5 * v_dt * (t_grad_U + v_gamma * t_p)

    # Full-step position
    t_q_new = t_q + v_dt * t_p_half

    # [FIXED C4] Second gradient via compiled kernel
    with torch.no_grad():
        t_grad_U_new = c_grad_U_net.forward(t_q_new)

    # Full-step momentum
    t_p_new = t_p_half - 0.5 * v_dt * (t_grad_U_new + v_gamma * t_p_half)

    # [FIXED C5] Stochastic noise ONLY during training
    if b_training and v_sigma > 0.0:
        t_noise = v_sigma * math.sqrt(v_dt) * torch.randn_like(t_p)
        t_p_new = t_p_new + t_noise

    return t_q_new, t_p_new

# Run 10 steps (10ms forward prediction):
for _ in range(cfg_sde_steps):   # cfg_sde_steps = 10
    t_q, t_p = f_stormer_verlet_step(
        t_q, t_p, cfg_sde_dt, v_gamma_eff,
        b_training=False, v_sigma=0.0   # deterministic live mode
    )
    # Runtime stability guard (monitor-only by default):
    # if hidden-state magnitude exceeds bound, emit alert and engage conservative mode.
    if torch.max(torch.abs(t_q)).item() > 1e4 or torch.max(torch.abs(t_p)).item() > 1e4:
        f_alert("SDE_STATE_MAGNITUDE_BREACH")
```

**`c_grad_U_net` compilation (startup, done once):**
```python
# Compile gradient network at startup (not on hot path)
# This creates a single fused kernel: input q → output ∇U(q)
# using functorch.jacrev or a custom CUDA kernel
@torch.compile(mode="reduce-overhead", fullgraph=True)
def c_grad_U_net(t_q: Tensor) -> Tensor:
    # Analytically differentiate U(q) through the MLP
    # This is valid because U is a known MLP with analytic derivatives
    with torch.enable_grad():
        t_q_g = t_q.requires_grad_(True)
        v_U   = c_potential_net.forward(t_q_g).sum()
        return torch.autograd.grad(v_U, t_q_g, create_graph=False)[0].detach()
# After compilation, no Python overhead or graph building on hot path
```

**Rationale for fixed-step:** Adaptive RK4 has unpredictable step count → violates latency SLA.
Störmer-Verlet is symplectic with bounded iteration count.

### 7.5 Energy Drift Computation — [FIXED Mi1]

```python
def f_energy_drift(t_q_seq: Tensor, t_p_seq: Tensor) -> float:
    H_seq = [0.5 * t_p[i].norm()**2 + c_potential_net(t_q[i])
             for i in range(len(t_q_seq))]
    v_energy_drift = torch.abs(torch.diff(torch.stack(H_seq))).mean().item()
    return v_energy_drift

# [FIXED Mi1] Safety gate: ADAPTIVE 7-day rolling threshold (not static 30-day)
# v_drift_threshold = 99th percentile of v_energy_drift on rolling last 7 days
# Re-computed every hour from drift_metrics table
# Alert if threshold changes by > 50% from 30-day baseline (possible regime change)
# If v_energy_drift > v_drift_threshold:
#   v_chaos_penalty *= 0.5   (NOT a binary halt)
```

### 7.6 Training Loss

```
L_sde = MSE(t_q_final, t_q_target)
      + MSE(t_p_final, t_p_target)
      + 0.001 × γ²
      + 0.001 × σ²

Optimizer: Adam, lr=1e-4, weight_decay=1e-5
Epochs: 200
Success: 99th percentile drift < 1e-4 on held-out validation set
```

### 7.7 Initialization

```python
v_gamma = nn.Parameter(torch.tensor(0.1))
v_sigma = nn.Parameter(torch.tensor(0.05))
v_gamma_eff = F.softplus(v_gamma)   # ≥ 0
v_sigma_eff = F.softplus(v_sigma)   # ≥ 0; only used in training forward pass
```

---

## 8. Execution Engine — Actor Network, Kelly Sizing, Stop-Loss

### 8.1 Actor Network — Single Forward Pass (Live)

```python
class c_actor_network(nn.Module):
    layers = [
        nn.Linear(256, 512), nn.SiLU(),
        nn.Linear(512, 512), nn.SiLU(),
        nn.Linear(512, 8),   nn.Tanh()
    ]
    # Action interpretation:
    # [0]: direction weight (-1=strong sell, +1=strong buy, 0=hold)
    # [1]: urgency (0=limit, 1=market)
    # [2]: size multiplier (before Kelly clipping)
    # [3-7]: reserved for multi-leg strategies
```

**Live constraints:**
- ε = 0 (no exploration)
- Frozen weights; inference in `torch.no_grad()`
- SDE runs in deterministic mode (σ·dW = 0) — see §7.4 **[FIXED C5]**

**Model confidence:**
```python
v_model_confidence = torch.softmax(t_raw_action[:, 0:3], dim=-1).max(dim=-1).values.mean()
# If v_model_confidence < 0.6: v_kelly_fraction = 0.0 (no trade)
```

### 8.2 Kelly Sizing — Continuous, Empirical

```python
def f_kelly_fraction(
    v_capital: float,
    positions: list[c_position],
    v_model_confidence: float,
    v_chaos_penalty: float,
    exchange_specs: dict,
) -> float:
    # Empirical win rate (30-day rolling, real trades only)
    p_win = f_rolling_win_rate(lookback_days=30)
    b     = f_rolling_win_loss_ratio(lookback_days=30)

    # Bootstrap period guard: first 30 days insufficient data
    # p_win defaults to 0.52, b defaults to 1.0 until 30 full days of real trades
    if f_live_trade_days() < 30:
        p_win = 0.52
        b     = 1.0

    # Kelly formula
    f_raw = (p_win * b - (1 - p_win)) / max(b, 1e-9)
    f_clipped = max(0.0, min(f_raw, 0.25))

    if v_model_confidence < 0.60:
        return 0.0

    # Liquidity-aware ceiling: tighten risk when spread/depth/funding stress is elevated
    v_liquidity_stress = f_liquidity_stress_score()  # 0..1 from spread, depth, funding pressure
    v_liquidity_cap = 1.0 - 0.5 * v_liquidity_stress
    f_final    = f_clipped * v_chaos_penalty * v_liquidity_cap
    v_size_raw = v_capital * f_final

    step  = exchange_specs['step_size']
    v_size = math.floor(v_size_raw / step) * step

    if v_size * current_price < exchange_specs['min_notional']:
        return 0.0

    return v_size
```



### 8.2 Update — Kelly Intelligence Multiplier [I6]

The Kelly fraction (§8.2) is multiplied by a new **Intelligence Multiplier** computed from the ICV.
This runs on the **warm path** (≥100ms), producing a cached `v_kelly_intel_multiplier` that the
hot-path Kelly computation reads from a shared memory location (atomic float, lock-free).

```rust
// src/intelligence/kelly_multiplier.rs
// Runs every 100ms on cores 64+ — NOT on hot path
// Writes result to atomic<f32> shared with hot path

pub fn f_compute_kelly_intel_multiplier(icv: &c_intelligence_context_vector) -> f32 {
    let v_whale_btc    = icv.f_get_slot(0);   // 0–1
    let v_whale_type   = icv.f_get_slot(3);   // −1 / 0 / +1
    let v_cascade      = icv.f_get_slot(18);  // 0–1
    let v_cascade_dir  = icv.f_get_slot(19);  // −1 / 0 / +1
    let v_put_call_skew = icv.f_get_slot(15); // z-score
    let v_iceberg_bid  = icv.f_get_slot(10);  // 0–1
    let v_iceberg_ask  = icv.f_get_slot(11);  // 0–1
    let v_congestion   = icv.f_get_slot(6);   // 0–1

    // --- UPWARD ADJUSTMENTS (accumulate on opportunity signals) ---
    let mut v_multiplier: f32 = 1.0;

    // Strong whale accumulation signal → scale up
    if v_whale_btc > 0.70 && v_whale_type > 0.5 {
        v_multiplier *= 1.20;  // +20% Kelly
    }

    // Iceberg bid (hidden buyer) → scale up
    if v_iceberg_bid > 0.60 {
        v_multiplier *= 1.15;
    }

    // Short squeeze setup → scale up
    if v_cascade > 0.60 && v_cascade_dir > 0.5 {
        v_multiplier *= 1.15;
    }

    // --- DOWNWARD ADJUSTMENTS (protect on risk signals) ---

    // Strong whale distribution signal → scale down
    if v_whale_btc > 0.70 && v_whale_type < -0.5 {
        v_multiplier *= 0.70;  // -30% Kelly
    }

    // Iceberg ask (hidden seller) → scale down
    if v_iceberg_ask > 0.60 {
        v_multiplier *= 0.80;
    }

    // Heavy put buying (institutional hedge) → scale down
    if v_put_call_skew > 2.0 {
        v_multiplier *= 0.75;
    }

    // High mempool congestion → scale down (slippage risk)
    if v_congestion > 0.80 {
        v_multiplier *= 0.85;
    }

    // Long liquidation cascade incoming → scale down
    if v_cascade > 0.60 && v_cascade_dir < -0.5 {
        v_multiplier *= 0.70;
    }

    // --- HARD CLAMP ---
    // Intelligence Multiplier is bounded [0.50, 1.50]
    // This prevents intelligence signals from overriding Kelly's own risk controls
    v_multiplier.clamp(0.50, 1.50)
}

// Hot path reads:
// v_effective_kelly = f_kelly_fraction(...) * atomic_kelly_intel_multiplier.load();
```

**Hot-path modification (minimal — one atomic load):**
```rust
// In f_kelly_fraction hot path (§8.2):
let v_intel_multiplier = ATOMIC_KELLY_INTEL_MULT.load(Ordering::Relaxed); // ≈1ns
let f_final = (f_clipped * v_chaos_penalty * v_intel_multiplier)
              .clamp(0.0, cfg_kelly_max_fraction);
```

**Latency impact on hot path:** +1ns (single atomic load). No SLA impact.

---



### 8.3 Stop-Loss — Volatility-Based, Calibrated — [FIXED C3]

**[FIXED C3] Stop-loss volatility window changed from ticks to seconds. The previous specification
used `lookback_ticks=300` (≈0.03 seconds at 10,000 ticks/sec — dangerously hyperactive). The
correct window is 300 seconds (5 minutes).**

```python
def f_compute_stop_loss(
    v_entry_price: float,
    v_side: int,           # +1 long, -1 short
    cfg_k: float = 2.5,
) -> float:
    # [FIXED C3] Realized volatility over last 300 SECONDS (≈5 minutes)
    v_sigma_5min = f_realized_vol(lookback_seconds=300)

    if v_side == +1:
        return v_entry_price * (1.0 - cfg_k * v_sigma_5min)
    else:
        return v_entry_price * (1.0 + cfg_k * v_sigma_5min)

# cfg_k = 2.5 calibrated on 5-year backtest for < 1% false positive stop rate
```

### 8.4 Transaction Cost Model — In Every Reward Computation

```python
class c_trading_cost_model:
    def f_total_cost(
        self,
        v_order_size: float,
        v_order_price: float,
        b_is_market_order: bool,
        v_book_depth_top5: float,
        v_hold_seconds: float,
    ) -> float:
        v_fee_rate = cfg_taker_rate if b_is_market_order else cfg_maker_rate
        v_fee      = v_order_size * v_order_price * v_fee_rate
        v_slippage = 0.001 * (v_order_size * v_order_price / v_book_depth_top5) ** 2
        v_funding  = (v_order_size * v_order_price
                      * cfg_current_funding_rate
                      * (v_hold_seconds / 28800.0))
        return v_fee + v_slippage + v_funding
```

**Fee schedule:** Fetched daily 01:00 UTC. Alert if > 24h stale.

---

## 9. Risk Management — Portfolio Risk Manager & Circuit Breakers

### 9.1 Portfolio Risk Manager — [FIXED C8, M10]

**[FIXED C8] The PortfolioRiskManager is rewritten in Rust. No Python on hot path.**

**[FIXED M10] VaR is computed on the JOINT portfolio return to account for cross-asset correlation
(e.g., BTCUSDT/ETHUSDT correlation ~0.85). Summing per-asset VaRs would underestimate tail risk.**

```rust
// src/risk/portfolio_risk_manager.rs

pub struct c_portfolio_risk_manager {
    cfg_max_net_delta:    f32,   // 0.20
    cfg_max_gross_exp:    f32,   // 0.50
    cfg_max_var_fraction: f32,   // 0.05
    v_cached_joint_var:   f32,   // updated every 10s by async thread
}

impl c_portfolio_risk_manager {
    pub fn f_check_order(
        &self,
        positions: &[c_position],
        v_capital: f32,
        mut v_new_size: f32,
        v_new_price: f32,
        v_new_side: i8,
    ) -> (bool, f32) {
        // Net delta check
        let v_net_delta: f32 = positions.iter()
            .map(|p| p.size * p.side as f32 * p.current_price)
            .sum::<f32>() / v_capital;
        let v_new_net_delta = v_net_delta + v_new_side as f32 * v_new_size * v_new_price / v_capital;
        if v_new_net_delta.abs() > self.cfg_max_net_delta {
            let v_allowed = self.cfg_max_net_delta - v_net_delta.abs();
            v_new_size = (v_allowed * v_capital / v_new_price).max(0.0);
        }

        // Gross exposure check
        let v_gross: f32 = positions.iter()
            .map(|p| (p.size * p.current_price).abs())
            .sum::<f32>() / v_capital;
        if v_gross + v_new_size * v_new_price / v_capital > self.cfg_max_gross_exp {
            let v_allowed_gross = (self.cfg_max_gross_exp - v_gross) * v_capital;
            v_new_size = v_new_size.min(v_allowed_gross / v_new_price);
        }

        // [FIXED M10] Joint portfolio VaR check (correlation-aware)
        if self.v_cached_joint_var > self.cfg_max_var_fraction * v_capital {
            return (false, 0.0);
        }

        v_new_size = (v_new_size / cfg_step_size).floor() * cfg_step_size;
        (v_new_size > 0.0, v_new_size)
    }
}

// Joint VaR computation (async, every 10s):
// 1. Compute 1-hour historical returns for ALL symbols simultaneously
// 2. Form portfolio return: sum(position_i * return_i) for each historical period
// 3. v_cached_joint_var = -percentile_5(portfolio_returns)
// This naturally captures cross-asset correlation without requiring an explicit correlation matrix
// 4. Reconcile cross-venue exposure snapshot every 30s; mismatch > tolerance triggers CRITICAL alert
```



### 9.1 Update — Risk Threshold Intelligence Adjustment [I7]

The Portfolio Risk Manager's thresholds are conditionally tightened by intelligence signals.
This runs on the **warm path**, writing to shared atomic floats read by the Rust risk manager.

```rust
// src/intelligence/risk_adjuster.rs — warm path, every 100ms

pub fn f_compute_adjusted_risk_limits(
    icv: &c_intelligence_context_vector,
    cfg: &c_risk_config,
) -> c_adjusted_risk_limits {
    let v_cascade    = icv.f_get_slot(18);
    let v_congestion = icv.f_get_slot(6);
    let v_dark_pool  = icv.f_get_slot(13);

    // Base limits (from §9.1)
    let mut v_max_gross = cfg.cfg_max_gross_exposure_pct;  // 0.50
    let mut v_max_var   = cfg.cfg_max_var_fraction;        // 0.05

    // Cascade risk → reduce exposure limits
    if v_cascade > 0.70 {
        v_max_gross *= 0.70;   // Reduce gross exposure by 30%
        v_max_var   *= 0.80;   // Tighten VaR limit by 20%
    } else if v_cascade > 0.50 {
        v_max_gross *= 0.85;
    }

    // High dark pool activity → tighten (hidden institutional activity = unpredictable)
    if v_dark_pool > 0.60 {
        v_max_gross *= 0.90;
    }

    // High congestion → tighten (slippage model may be wrong during fee spikes)
    if v_congestion > 0.80 {
        v_max_gross *= 0.90;
    }

    c_adjusted_risk_limits {
        v_max_gross_exposure_pct: v_max_gross.clamp(0.20, 0.50),
        cfg_max_var_fraction:     v_max_var.clamp(0.02, 0.05),
    }
    // Clamps ensure intelligence can TIGHTEN but never LOOSEN beyond original limits
}
```

---



### 9.2 Circuit Breakers — Complete Specification

| Trigger Condition | Action | Recovery | Logged To |
|---|---|---|---|
| Daily loss > 2% of capital | Halt all trading (automated) | Manual CRO review + TOTP re-enable + cool-down | `safety_events` |
| Drawdown from peak > 5% | Halt all trading | Manual review + cool-down (see §21.5) | `safety_events` |
| Single trade loss > 1% capital | Flag + reduce position limits 50% for 1 hour | Auto-recover after 1h if no further breach | `safety_events` |
| Net delta breach (> 20%) | Reject new orders; hedge | Auto-recover when delta returns to limit | `risk_events` |
| VaR breach (> 5% joint) | Reject new orders; risk-reduction mode | Auto-recover when VaR normalizes | `risk_events` |
| Order latency p99 > 1ms for 10 consecutive decisions | Halt + CRITICAL alert | Manual investigation | `safety_events` |
| OMS reconciliation discrepancy > 0 | Cancel all; halt; reconcile | 2-operator sign-off | `safety_events` |
| Crash loop (5 crashes in 5 minutes) | Halt; disable auto-restart; CRITICAL alert | Manual restart after root-cause | `safety_events` |
| PSI > 0.2 for any feature | Conservative mode (surrogate decisions) | Auto-recover after retraining | `drift_metrics` |
| Extreme funding rate (> 0.1% per 8h) | Warning; reduce perpetual position limits by 50% | Auto-recover when rate normalizes | `risk_events` |

### 9.3 Lyapunov / Sample Entropy — Chaos Penalty — [FIXED C6]

**[FIXED C6] Sample entropy is computed on a PCA-reduced representation of the full 256-dimensional
latent trajectory, not on a single dimension. Using only dimension 0 discards >99% of the information
and produces an arbitrary, unreliable chaos penalty.**

```python
# Async path — runs every 10ms on core 16–31
def f_chaos_penalty(
    t_trajectory: np.ndarray,  # shape (1000, 256) — from circular buffer
    v_threshold:  float,       # 90th percentile of historical entropy
    v_pca_components: int = 8, # retain top-8 PCs (typically > 95% variance)
) -> float:
    from antropy import sample_entropy
    from sklearn.decomposition import PCA

    # [FIXED C6] Reduce to top PCs first, then compute entropy on each PC
    # PCA model fitted offline on 30 days of trajectory data; loaded at startup
    t_reduced = pca_model.transform(t_trajectory)   # shape (1000, 8)

    # Compute sample entropy per PC, take mean
    v_std = t_reduced.std()
    v_se_per_pc = [
        sample_entropy(t_reduced[:, k], order=2, metric='chebyshev',
                       metric_sd=0.2 * v_std)
        for k in range(v_pca_components)
    ]
    v_se = float(np.mean(v_se_per_pc))

    # Continuous penalty: 0 = no trade, 1 = full position
    return max(0.0, 1.0 - v_se / v_threshold)

# PCA model calibration: run at startup from 30 days of historical trajectory data
# Store: pca_model (sklearn PCA, n_components=8, explained_variance_ratio > 0.95)
# cfg_pca_n_components = 8; assert sum(pca.explained_variance_ratio_) > 0.95
# Re-calibrate: whenever champion model is retrained (SDE weights change latent space)
```

---

## 10. Order Management System (OMS) & Manipulation Guard

### 10.1 OMS Architecture — [FIXED C8]

**[FIXED C8] The entire OMS hot path (ManipulationGuard, SurrogateTree explanation,
HSM signing, order dispatch) runs in Rust. No Python on the hot path.**

```
Actor output (t_raw_action, v_kelly_fraction)
           │
           ▼
    c_portfolio_risk_manager::f_check_order()   [Rust]
           │ (approved size, or reject)
           ▼
    c_rate_limiter::f_check_and_consume()       [Rust]
           │ (pass → proceed; fail → HOLD action)
           ▼
    c_manipulation_guard::f_check()             [Rust]
           │ (pass or halt)
           ▼
    f_explain_synchronous()                     [Rust — pre-compiled reason code]
           │ (reason_code: [u8; 256])
           ▼
    HSM::f_sign(order_payload) via Thales Luna PCIe   [~5μs with Ed25519]
           │ (signed order bytes)
           ▼
    OpenOnload ef_vi dispatch to exchange
           │
           ▼
    order_lifecycle INSERT (async, Rust → Kafka → ClickHouse)
```

**Cancel order path** (new orders and cancellations share the same HSM):
```
Cancel request (order_id, symbol, side)
           │
           ▼
    HSM::f_sign(cancel_payload)          [~5μs with Ed25519 — same HSM, same key]
           │
           ▼
    OpenOnload ef_vi cancel dispatch
    Budget: 30μs (cancel payload is smaller → faster than new order)
```

### 10.2 ManipulationGuard — Rust Implementation — [FIXED C8]

```rust
// src/execution/manipulation_guard.rs
pub struct c_manipulation_guard {
    cfg_otr_window_seconds:       f32,   // 60.0
    cfg_otr_max_ratio:            f32,   // 20.0
    cfg_spoof_max_orders:         usize, // 10
    cfg_spoof_window_ns:          u64,   // 1_000_000_000
    cfg_spoof_min_depth_fraction: f32,   // 0.10
}

impl c_manipulation_guard {
    // Rule 1: Self-trade prevention
    pub fn f_self_trade_check(&self, new_order: &c_order, open_orders: &[c_order]) -> bool {
        for open in open_orders {
            if open.symbol == new_order.symbol
               && open.side != new_order.side
               && (open.price - new_order.price).abs() < cfg_tick_size {
                return false;  // REJECT
            }
        }
        true
    }

    // Rule 2: OTR check (rolling 60s)
    pub fn f_otr_check(&self) -> bool {
        if self.v_otr_ratio > self.cfg_otr_max_ratio {
            self.f_halt_trading(60, "OTR_BREACH");
            return false;
        }
        true
    }

    // Rule 3: Spoofing detection
    pub fn f_spoofing_check(&self, recent_cancels: &[c_order], v_book_depth: f32) -> bool {
        let now_ns = f_clock_ns();
        let large_quick_cancels = recent_cancels.iter()
            .filter(|o| o.size * o.price > self.cfg_spoof_min_depth_fraction * v_book_depth
                     && now_ns - o.placed_ns < self.cfg_spoof_window_ns)
            .count();
        if large_quick_cancels > self.cfg_spoof_max_orders {
            self.f_activate_kill_switch("SPOOFING_DETECTED");
            return false;
        }
        true
    }
}
```

### 10.3 Ex-Ante Explanation — Surrogate Tree — [FIXED Mi2, M11]

**[FIXED Mi2] The reason code is constructed as a pre-allocated fixed-length byte buffer in Rust,
not a Python string. This avoids Python GIL overhead and reduces latency from ≥5μs to <1μs.**

**[FIXED M11] A per-order surrogate agreement flag is now logged. If the surrogate's predicted
action class does not match the neural network's actual action for this specific order, the order
is flagged `b_explanation_approximate = true`. Orders with `b_explanation_approximate = true`
are reviewed in the daily compliance report and cannot contribute to regulatory submissions without
human review. This closes the MiFID II compliance gap caused by 15% aggregate disagreement.**

**OOD explainability guard (warm path):** if an OOD detector flags the feature vector, the
surrogate explanation is marked non-authoritative and replaced with a deterministic rule-based
fallback explanation template (`OOD_FALLBACK_RULESET_V1`). In this case:
- `b_explanation_approximate = 1`
- `b_explanation_ood = 1`
- human review is mandatory before compliance submission

```rust
// src/execution/surrogate_explainer.rs
// Pre-compiled decision tree (converted from scikit-learn via ONNX or custom Rust tree)

pub struct c_surrogate_explainer {
    tree: c_compiled_decision_tree,
    buf_reason: [u8; 256],   // pre-allocated; zero-copy output
}

impl c_surrogate_explainer {
    pub fn f_explain(&mut self, t_features: &[f32; 128], v_neural_action: i8) -> c_explanation {
        // Tree inference: < 1μs (compiled tree, no Python)
        let (v_surrogate_action, leaf_path) = self.tree.predict_with_path(t_features);

        // [FIXED M11] Per-order agreement check
        let b_explanation_approximate = v_surrogate_action != v_neural_action;
        if b_explanation_approximate {
            f_increment_metric("surrogate_disagreement_count");
        }

        // Build reason code into pre-allocated buffer (no heap allocation)
        let s_direction = if v_neural_action == 1 { "BUY" }
                          else if v_neural_action == -1 { "SELL" }
                          else { "HOLD" };
        // Top 5 conditions from leaf_path written directly to self.buf_reason
        f_format_reason_code(&mut self.buf_reason, s_direction, &leaf_path[..5.min(leaf_path.len())]);

        c_explanation {
            reason_code: &self.buf_reason,
            b_explanation_approximate,
        }
    }
}

// Stored in order_lifecycle.reason_code and order_lifecycle.b_explanation_approximate
// before ef_vi dispatch
```

### 10.4 HSM Signing Protocol — [FIXED C7, Cost-Opt: Ed25519]

**[FIXED C7] HSM ECDSA P-256 signing latency corrected from 5μs to 50μs minimum (measured).
The previous 5μs figure was physically impossible — ECDSA P-256 requires modular exponentiation
and RNG operations that take 50–200μs even on dedicated PCIe HSM hardware.**

**[Cost-Opt] Switch to Ed25519 for order signing.** Binance officially recommends Ed25519 keys
and has deprecated HMAC keys. Ed25519 on Thales Luna PCIe achieves ≤5μs signing latency (vs
50μs for ECDSA P-256), recovering 45μs of hot-path slack. The HSM hardware is retained.
Update `cfg_active_key_type = Ed25519` and generate a new Ed25519 key pair in the HSM.
Note: HMAC-SHA256 keys must NOT be used — Binance is actively deprecating them as symmetric
keys are less secure than asymmetric Ed25519.

```
Order payload (JSON bytes, max 512 bytes)
         │
         ▼
Thales Luna PCIe f_sign(payload, key_id=cfg_active_key_id, algo=Ed25519)
         │ (≤5μs for Ed25519; 50–200μs for ECDSA P-256 — use Ed25519)
         ▼
Signed bytes (Ed25519 signature, 64 bytes)
         │
         ▼
Append signature to exchange-native order payload → dispatch

Security controls:
  • Signing key never leaves HSM hardware boundary
  • Key access restricted to UID of Predator process
  • Every signing event logged to signing_audit table
  • Key rotation: every 90 days (02:00–04:00 UTC Sunday, dual-key overlap)
  • cfg_active_key_type: Ed25519   # updated from ECDSA P-256
```

### 10.5 Drop Copy Reconciliation

Reconciliation runs every 30 seconds (async thread).

Cancel race-condition handling:
- If cancel response is `UNKNOWN_ORDER` / already-closed equivalent, treat as terminal-success
  only after reconciliation confirms order is no longer open.
- Reconciliation source priority: execution report stream → exchange query fallback.
- Any ambiguity after 2s reconciliation timeout escalates to `OMS_RECONCILIATION_DISCREPANCY`
  and triggers the safety path in Section 9.2 / Section 21.

### 10.6 Order ID Scheme — [FIXED M3, NEW SECTION]

**[FIXED M3] A 64-bit monotonic order ID scheme is defined to ensure uniqueness across node
restarts, DR failover, and concurrent order submission.**

```
Order ID layout (64 bits):

  Bits [63:56] — Node ID (8 bits): 0x00 = NY4, 0x01 = SG1
  Bits [55:0]  — Monotonic counter (56 bits): up to 7.2 × 10^16 orders per node

  Maximum order rate: 10,000 orders/sec × 3.6ksec/hr × 24hr × 365d × 300yr < 2^56 ✓
```

```rust
// src/execution/order_id_generator.rs
use std::sync::atomic::{AtomicU64, Ordering};
use std::fs;

pub struct c_order_id_generator {
    cfg_node_id:    u8,         // 0 = NY4, 1 = SG1
    v_counter:      AtomicU64,
    s_persist_path: &'static str,  // e.g., "/var/predator/order_id_counter.bin"
}

impl c_order_id_generator {
    pub fn new(cfg_node_id: u8, s_persist_path: &'static str) -> Self {
        // Restore counter from NVMe on startup (survives crash/restart)
        let v_counter_start = fs::read(s_persist_path)
            .map(|b| u64::from_le_bytes(b[..8].try_into().unwrap()))
            .unwrap_or(0);
        // Add 10,000 safety gap to handle orders in flight during crash
        let v_counter_start = v_counter_start + 10_000;
        f_persist_counter(v_counter_start, s_persist_path);  // persist the gap

        Self {
            cfg_node_id,
            v_counter: AtomicU64::new(v_counter_start),
            s_persist_path,
        }
    }

    pub fn f_next_id(&self) -> u64 {
        let v_seq = self.v_counter.fetch_add(1, Ordering::SeqCst);
        // Persist every 1000 increments (amortize NVMe writes)
        if v_seq % 1000 == 0 {
            f_persist_counter(v_seq, self.s_persist_path);
        }
        ((self.cfg_node_id as u64) << 56) | (v_seq & 0x00FF_FFFF_FFFF_FFFF)
    }
}
```

---

## 11. Latency Budget & Profiling Protocol

### 11.1 Revised Latency Budget (p99, Measured on H100 with CUDA Events) — [FIXED C7, M1]

**[FIXED C7] HSM budget corrected from 5μs to 50μs. Total nominal revised from 220μs to 265μs.**
**[FIXED M1] Cancel path added as a separate row.**

| Stage | Budget (μs) | Measurement Method | Owner |
|---|---|---|---|
| Tick receipt → application (OpenOnload) | 5 | `ef_vi` hardware timestamp | Platform |
| Normalization + first Mamba-2 kernel (fused) | 20 | `torch.cuda.Event()` | ML |
| Mamba-2 layers 2–4 | 40 | CUDA events | ML |
| Neural SDE (10 × Störmer-Verlet, deterministic, analytical gradient) | 80 | CUDA events | ML |
| Actor network forward | 5 | CUDA events | ML |
| Portfolio Risk Manager (Rust) | 5 | CPU `clock_gettime(CLOCK_MONOTONIC)` | Risk |
| Surrogate tree ex-ante (Rust, pre-compiled) | 1 | CPU `clock_gettime` | ML |
| HSM signing (Thales Luna PCIe, **Ed25519** — see §10.4) | **5** | CPU timestamp diff | Security |
| OMS serialization + ef_vi dispatch (new order) | 50 | Hardware TX timestamp | Platform |
| **Total nominal (new order)** | **211μs** | | |
| **[FIXED M1]** Cancel path (HSM sign + ef_vi dispatch) | **30** | Hardware TX timestamp | Platform |
| **Kernel launches + memory copies (slack)** | **289μs** | Profiling overhead | Platform |
| **Total p99 SLA** | **500μs** | End-to-end: NIC RX → NIC TX | All |

**Note:** Switching HSM signing from ECDSA P-256 (50μs) to Ed25519 (≤5μs) recovers 45μs of budget,
increasing nominal slack from 244μs to 289μs. This is the single highest-leverage optimisation
in the entire hot path. If p99 consistently exceeds 400μs during load tests, verify Ed25519 key
is active (not ECDSA) before investigating other stages.

> **SLA boundary clarification [Audit finding 11.1]:** The 500μs SLA is measured from **NIC receive
> timestamp (ef_vi hardware timestamp) to ef_vi TX dispatch** — i.e., processing time within our
> servers. The "exchange clock to order dispatch" phrasing in §2.1 describes the full round-trip
> concept; in practice, the 5μs budget for "Tick receipt → application" refers exclusively to
> kernel-bypass NIC→application memory transfer time via OpenOnload ef_vi, not network transit.
> Network transit (exchange matching engine → our NIC via direct cross-connect at Equinix NY4/SG1)
> is architecture-dependent: a co-located cross-connect on the same Equinix campus introduces
> ≤1ms one-way, well outside the 500μs processing budget and not included in it. This is standard
> HFT practice: the SLA governs internal processing latency, not propagation delay.
> General internet WebSocket latency (4–13ms from cloud instances) is irrelevant to a co-located
> bare-metal deployment with dedicated fiber cross-connects.

### 11.2 Profiling Protocol

```python
t_start = torch.cuda.Event(enable_timing=True)
t_end   = torch.cuda.Event(enable_timing=True)
t_start.record()
# ... pipeline execution ...
t_end.record()
torch.cuda.synchronize()
v_latency_us = t_start.elapsed_time(t_end) * 1000  # ms → μs
```

Stored in `decision` table as `v_latency_us`.

Distributed traceability:
- Every decision gets `trace_id` generated at ingestion.
- `trace_id` is propagated through normalization, model, risk, OMS, and audit logger.
- Stage spans are sampled on warm path and exported to observability storage for tail-latency attribution.

**Alerts:**
- p99 > 300μs → WARNING
- p99 > 500μs for 10 consecutive decisions → CRITICAL + reduce batch size 64→32
- p999 > 2ms over 5-minute window → CRITICAL (tail-latency investigation)
- p9999 > 5ms any time → CRITICAL + deployment freeze until resolved

**Weekly latency regression test:** Replay 1 hour of historical ticks. If regression > 20μs vs
previous week → block deployment.

### 11.3 Kernel Fusion Strategy

```python
@torch.compile(mode="reduce-overhead", fullgraph=True)
def f_fused_norm_mamba(t_raw: Tensor, w_mamba_l0: dict) -> Tensor:
    t_norm = f_normalize_ewma(t_raw)
    return f_mamba_block(t_norm, **w_mamba_l0)
```

Note: `c_grad_U_net` (§7.4) is also separately compiled with `fullgraph=True`.
`torch.autograd.grad` is NOT called inside any compiled function on the hot path.

---

## 12. Training Pipeline — Phased, Reproducible, No Lookahead Bias

### 12.1 Data Split Protocol

```
Timeline: 2020-01-01 ─────────────────────────── 2025-01-01
                      │                           │
          Train: 80%  │  Validation: 20%          │
          (2020-01-01 to 2023-12-31)              │
                                        (2024-01-01 to 2025-01-01)
Test (never used during development): 2025-01-01 to present (live)
Rules:
  • All hyperparameter tuning uses validation set ONLY
  • Test set (live) never touches training or tuning
  • No future prices/signals leak into past feature windows
```

### 12.2 Six-Phase Training Sequence

#### Phase 1 — Mamba-2 + CoPE + HGRN-2 Pre-training

| Parameter | Value |
|---|---|
| Data | 5-year multi-asset historical ticks (4 instruments) |
| Duration | 24 hours on 8× H100 |
| Batch size | 64 |
| Optimizer | AdamW, lr=3e-4, weight_decay=1e-4 |
| LR schedule | Cosine with warm restarts, T_0=1000 steps |
| Epochs | 100 |
| Success criterion | Reconstruction error < 5% on validation |

#### Phase 2 — Neural SDE Training (stochastic mode)

| Parameter | Value |
|---|---|
| Data | Synthetic dissipative trajectories + real latent sequences from Phase 1 |
| Duration | 12 hours |
| γ init, σ init | 0.1, 0.05 |
| Epochs | 200 |
| Success criterion | 99th percentile energy drift < 1e-4 on validation |
| Note | σ·dW active during training; set σ=0 in live config after training |

#### Phase 3 — TD-MPC2 World Model

Ensemble of 5 MLPs; 5M transitions; success: reward prediction error < 1%.

#### Phase 4 — NSR + Sample Entropy / Lyapunov Calibration

| Parameter | Value |
|---|---|
| NSR success | Equation R² > 0.7; confidence > 0.75 on 50% of windows |
| PCA calibration | Fit PCA on 30d trajectory; assert explained_variance_ratio > 0.95 |
| Chaos threshold | 90th percentile of sample entropy on PCA-reduced vectors |

#### Phase 5 — Actor Fine-tuning (Mamba-2 + Neural SDE FROZEN)

| Parameter | Value |
|---|---|
| Frozen | Mamba-2 + CoPE + HGRN-2 weights; Neural SDE weights |
| Trained | Actor network only |
| Reward | PnL after all costs − 0.01 × drawdown² − 0.001 × trade_count |
| Success | Sharpe > 1.2 on out-of-sample validation |

#### Phase 6 — Surrogate Tree + SHAP Agreement

| Parameter | Value |
|---|---|
| Tree depth | 6, min_samples_leaf = 100 |
| Success | Surrogate agreement with champion > 85% |
| Export | Convert to ONNX + Rust-native compiled tree for hot path |

### 12.3 Reproducibility Protocol — [FIXED M13]

**[FIXED M13] PyTorch CUDA operations are not bit-identical by default across runs.
`torch.use_deterministic_algorithms(True)` and `torch.backends.cudnn.deterministic = True`
must be set for the reproducibility claim to hold.**

```python
# Required at the top of every training script:
import torch
torch.manual_seed(42)
torch.cuda.manual_seed_all(42)
import numpy as np
np.random.seed(42)
import random
random.seed(42)

# [FIXED M13] CUDA determinism — required for bit-identical weight reproducibility
torch.use_deterministic_algorithms(True)
torch.backends.cudnn.deterministic = True
torch.backends.cudnn.benchmark     = False  # disable auto-tuner (non-deterministic)
torch.backends.cuda.matmul.allow_tf32 = False
torch.backends.cudnn.allow_tf32       = False
import os
os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"

# Note: deterministic CUDA is ~5-15% slower but mandatory for this claim.
# Training is offline (no latency SLA), so the overhead is acceptable.
```

Every training run records: random seed, git commit hash, feature engineering version,
data checksums (SHA-256), full hyperparameter YAML, hardware specs, all to MLflow.

Re-running same experiment with same seed MUST produce bit-identical weights on the same
software stack (CUDA/cuDNN/PyTorch versions) and equivalent hardware class.
CI job: after every training PR merge, run 2 identical training jobs → compare weight checksums.

---

## 13. Simulation & Paper Trading Environment

### 13.1 Simulation Environment — Tick-for-Tick Replay

Mandatory gate before any live deployment. Replays historical ticks at microsecond resolution.

```
[Historical Tick Replayer]
  → Reads ClickHouse tick_raw
  → Replays at original timestamps
  → Simulates reply_latency ~ LogNormal(μ=50μs, σ=20μs)
  → [Simulated Exchange Adapter] → fills, rejections, acks
  → [Full Production Pipeline] — identical binaries, same config
```

**Fidelity requirements:** Partial fills when size > 10% book depth; funding at 8h intervals;
random outage gaps matching historical patterns.

### 13.2 Paper Trading Phase

| Phase | Duration | Capital | Success Criteria |
|---|---|---|---|
| Simulation only | 4 weeks | $0 (virtual $1M) | Sharpe > 1.2, max DD < 5%, zero safety events |
| Paper trading (live data, no orders) | 2 weeks | $0 | Decisions logged, reviewed daily |
| Canary live (real orders) | 1 week | 1% capital | No safety events, P&L within ±20% of simulation |

### 13.3 Synthetic Input Health Probe

```python
GOLDEN_INPUTS = [...]  # pre-recorded (input, expected latent, expected action) triples

def f_synthetic_health_probe() -> bool:
    for t_input, t_expected_latent, t_expected_action in GOLDEN_INPUTS[:5]:
        t_actual_latent = f_mamba_forward(t_input)
        if (t_actual_latent - t_expected_latent).abs().mean().item() > 0.01:
            f_alert("SYNTHETIC_PROBE_MISMATCH")
            return False
    return True
```

---

## 14. Shadow, Canary & Production Deployment

### 14.1 Champion-Challenger Architecture

- **Champion:** Active model, 100% of traffic by default.
- **Challenger:** Receives same ticks, computes decisions, does NOT submit orders.
- Challenger activated when `cudaMemGetInfo()` ≥ 30GB VRAM free after champion allocation.

### 14.2 Shadow Mode Criteria for Promotion

Shadow must run ≥ 24 hours and pass ALL of:

| Criterion | Threshold |
|---|---|
| Action agreement (challenger vs champion) | > 85% |
| Challenger win rate improvement | ≥ +1% absolute |
| Challenger profit factor improvement | ≥ +0.1 |
| Challenger latency | ≤ champion p99 + 50μs |
| Zero safety events | 0 circuit breaker trips |
| Surrogate agreement (challenger) | > 85% |

### 14.3 Canary Ramp Schedule

```
Step 1:   1% traffic → challenger (1h min, no violations)
Step 2:   2% traffic → challenger (1h min)
Step 3:   5% traffic → challenger (2h min)
Step 4:  10% traffic → challenger (2h min)
Step 5:  20% traffic → challenger (4h min)
Step 6:  50% traffic → challenger (8h min)
Step 7: 100% traffic → challenger becomes new champion
At each step: automated check of all shadow criteria; any violation → immediate rollback.
```

### 14.4 Rollback Protocol

**Automated rollback triggers:**
- Any circuit breaker trip
- Latency p99 > 500μs for 3 consecutive minutes
- Surrogate agreement < 80%
- Action disagreement > 20% for 3 consecutive 10-minute windows

**Rollback procedure:**
```
1. Set traffic split to 0% challenger (shared memory flag, atomic)
2. Mass-cancel all challenger-originated orders:
   DELETE /fapi/v1/allOpenOrders (expected p99: 200ms)
3. Verify via drop copy (timeout: 5s); fallback: cancel per-order if needed [see §21.1]
4. Champion resumes 100%
5. Log to safety_events
Total rollback SLA: < 2s to order cancellation
```

---

## 15. CI/CD Pipeline — Code to Production

### 15.1 Repository Structure

```
predator-2026/
├── src/
│   ├── ingestion/          (Rust — tick reception, normalization, feed validator)
│   ├── models/             (Python / PyTorch — Mamba-2, Neural SDE, Actor)
│   ├── execution/          (Rust — OMS, ManipulationGuard, HSM signing, order IDs)
│   ├── risk/               (Rust — Portfolio Risk Manager, Kelly, rate limiter)
│   ├── audit/              (Rust — Kafka producer, ClickHouse writer)
│   ├── compliance/         (Python — MiFID II reports, surrogate tree training)
│   └── shared/
│       └── libpredator_features/  (Rust — shared feature engineering library)
├── tests/
├── infra/
├── training/
├── .github/workflows/
└── docs/
```

### 15.2 CI Pipeline

Standard per-PR checks: Rust (clippy + rustfmt), Python (ruff + mypy --strict + black),
unit tests (90% coverage gate), integration tests (mock exchange), latency regression,
SAST (semgrep + CodeQL), dependency scanning (cargo-audit + pip-audit),
and model reproducibility (on `model-change` PRs).

### 15.3 CD Pipeline

Merge to main: build Rust binaries → deploy to simulation → 1h simulation validation →
paper trading → deploy challenger to shadow (requires 2 manual approvals: ML Lead + Risk Officer).

### 15.4 Rollback in CI/CD

```bash
./scripts/emergency_rollback.sh --reason "LATENCY_SPIKE" --operator "alice"
# 1. Sets champion_version = previous_stable in shared memory
# 2. Cancels all challenger orders
# 3. Logs to safety_events
# 4. Alerts PagerDuty CRITICAL
```

### 15.5 Formal Verification Workstream (Critical State Machines)

The following high-risk state machines must maintain machine-checked invariants:
- Order ID generator monotonicity and uniqueness
- Rate limiter safety (never exceed configured budget)
- Kill-switch liveness (eventual transition to halted-safe state on trigger)

Workflow:
- Model each state machine in TLA+ and verify invariants on every major logic change.
- Store specs under `specs/formal/` and gate merge on spec check completion.
- Any invariant violation blocks release to canary.

---

## 16. Secrets Management & HSM Key Lifecycle

### 16.1 Secret Categories

| Secret Type | Storage | Access | Rotation |
|---|---|---|---|
| Order signing private key (Ed25519) | Thales Luna HSM (never exported) | Predator process UID only | Every 90 days |
| Exchange API keys | Thales Luna (encrypted) | Predator process only | Every 90 days |
| ClickHouse credentials | HashiCorp Vault (on-prem) | Audit logger only | Every 30 days |
| Kafka credentials | HashiCorp Vault | Kafka producers only | Every 30 days |
| SSH private keys | Vault + YubiKey (hardware MFA) | Operators only | Every 90 days |
| YubiKey TOTP seed | HSM + operator hardware token | 2-of-3 operators | On personnel change |
| ML model weights | Encrypted Minio (on-prem) | Training node + model loader | Per training run |

**No secrets in environment variables. No secrets in source code. No secrets in logs.**

### 16.2 HSM Key Lifecycle Protocol

Key rotation every 90 days (Sunday 02:00–04:00 UTC):
1. Generate new key pair in HSM
2. Register public key with exchange (testnet first)
3. Shadow key period: both keys active for 1 hour
4. Verify new key on testnet
5. Atomically switch `cfg_active_key_id` (shared memory CAS)
6. Delete old key after 24h
7. Log to `signing_audit`

Emergency revocation: operator TOTP → delete from HSM → halt trading → notify exchange.

### 16.3 Vault Dynamic Secrets

```hcl
path "database/creds/predator-clickhouse" {
  capabilities = ["read"]
}
# TTL = 1 hour; auto-renewed while process runs; revoked on process death
```

---

## 17. Security Architecture & Penetration Testing

### 17.1 Threat Model

| Threat | Severity | Control |
|---|---|---|
| Private key exfiltration | Critical | Keys only in HSM; no export; mprotect |
| Exchange API key theft via log | Critical | No secrets in logs; structured logging |
| Unauthorized kill-switch | Critical | YubiKey TOTP + 2-of-3 M-of-N |
| Rogue trade injection | High | HSM signing + ManipulationGuard + drop copy |
| Model poisoning | High | Data checksums; isolated training environment |
| SSH brute force | Medium | Jump host; fail2ban; SSH keys + YubiKey |
| Insider threat | High | 2-person code review; GitOps audit trail |

### 17.2 Network Segmentation

```
Segment A: Trading Hot Path (air-gapped from internet)
  - Solarflare NIC ports 0 & 1; only exchange cross-connect; no internet routing

Segment B: Management Network
  - Dedicated NIC; SSH via jump host (IP whitelist); monitoring (Prometheus, Grafana);
    Kafka + ClickHouse

Segment C: Training Environment
  - Completely isolated from Segment A; no production credentials; internet access allowed
```

### 17.3 Penetration Testing Schedule

| Test Type | Frequency |
|---|---|
| Network penetration test | Quarterly |
| Application SAST | Every PR |
| Dependency scanning | Every PR |
| Red team exercise | Annually |
| HSM tamper test | Annually |
| Incident response drill | Monthly |

### 17.4 Secure Coding Standards

Rust: no unsafe except reviewed network layer; checked integer arithmetic; no `unwrap()` in production.
Python: mypy --strict; no eval/exec/pickle in production; shlex.split + shell=False.
SQL: parameterized queries only; least-privilege per-service users.

---


---


## 17A. Network Security Hardening (P2P Defense Layer) [I5]

This section adds **defensive** (not offensive) network intelligence to harden PREDATOR 2026
against P2P network attacks. All components are passive monitors and anomaly detectors.

All components in this section are **passive monitors only**. No packet injection, routing manipulation, or active interference with external infrastructure is performed.

### 17A.1 tNeuron-Style P2P Anomaly Detector

Inspired by the tNeuron framework (transformer-based ML for P2P network attack detection on
Bitcoin). Our implementation is **defensive only**: it monitors our own node's P2P connection
health to detect if WE are being attacked (e.g., if someone is attempting an eclipse attack
on our full nodes).

```python
# Runs on management server, monitors BTC/ETH full node P2P health
# Does NOT interact with other nodes except our own

class c_p2p_anomaly_detector:
    """
    Monitors:
    - Peer response time distribution (detect artificially slow peers)
    - Unusual peer disconnection rates
    - Block propagation delay anomalies
    - Inventory announcement timing patterns

    All inputs: our own node logs and P2P statistics only.
    Output: v_p2p_anomaly_score (0–100)
      > 70: Alert and log to security_events table
      > 90: CRITICAL alert; suggest manual inspection of peer list
    """
    def f_analyse_peer_timing(
        self,
        v_peer_response_times_ms: np.ndarray,
    ) -> float:
        """
        Uses transformer encoder (4 layers, 8 heads, d_model=64)
        to detect anomalous response time patterns.
        Training: 90 days of historical peer timing data from our own nodes.
        Reduced false positives via eBPF tracing hooks (read-only) on our own process.
        """
        ...
```

### 17A.2 Peer-Observer Honeypot Monitor — ⚠️ DEFERRED TO PHASE 3

> **Cost-optimisation deferral:** Honeypot observer nodes require additional RAM/storage and add
> operational complexity at launch. For a single-colo Phase 0–2 deployment, simple peer count
> monitoring via `bitcoin-cli getpeerinfo` on the existing full node achieves the same eclipse
> detection goal at zero additional cost. Defer full multi-location honeypot infrastructure
> until SG1 bare metal is provisioned (Stage 3).

Deploys lightweight honeypot Bitcoin/Ethereum nodes (passive listen only — no mining, no trading)
at geographically diverse locations to monitor P2P network health and detect DoS patterns that
might affect our trading nodes.

```yaml
# docker-compose.observer.yml
# Deployed at: Equinix NY4 management segment, SG1 management segment, FR5 (passive only)
services:
  btc-observer-ny4:
    image: bitcoin/bitcoin:26.0
    command: -listen -maxconnections=50 -debug=net -datadir=/data
    network_mode: management   # management NIC only — NO hot path NIC
    read_only: true            # No writes to chain — passive observation
    volumes: ["/data/btc-observer:/data"]

  eth-observer-ny4:
    image: ethereum/client-go:stable
    command: --maxpeers=50 --metrics --pprof --ws
    network_mode: management
    read_only: true
```

**Output:** Block propagation latency metrics published to ClickHouse `network_health` table.
Alert if our trading nodes are consistently last to receive a block (possible eclipse attack in
progress). This feeds ICV slot 22 (v_network_anomaly_score).

### 17A.3 AToM — Active Topology Monitor — ⚠️ DEFERRED TO PHASE 3

> **Cost-optimisation deferral:** For a single NY4 node with a self-hosted full node, basic peer
> diversity is adequately monitored by checking ASN count via `bitcoin-cli getpeerinfo | jq '.[] | .addr'`
> + a simple Python cron. The full AToM inference model adds complexity without material benefit
> until multi-colo deployment at Stage 3. ICV slot 23 (`v_peer_diversity_score`) will be zero-filled
> (neutral signal) during Phase 0–2; this is safe per ADR-019 (stale → zero = neutral).

Implements AToM-style (Active Topology Monitoring) passive inference of our connectivity to
the reachable Bitcoin network. Detects if our peer set becomes unexpectedly homogeneous
(a warning sign of an eclipse attack in progress).

```python
# Monitors our own node's peer diversity
def f_peer_diversity_score(v_peer_list: list[dict]) -> float:
    """
    Score 0–1. 0 = all peers from same /16 subnet (eclipse risk).
    1 = maximally diverse peer set.
    Computed from: ASN diversity, /16 subnet distribution, geographic diversity.
    """
    v_asns = set(p['asn'] for p in v_peer_list if 'asn' in p)
    v_subnets = set(p['addr'].rsplit('.', 2)[0] for p in v_peer_list)
    # Minimum entropy threshold: at least 10 distinct ASNs
    return float(min(len(v_asns) / 20.0, 1.0))
```

### 17A.4 LION — Lightweight Anomaly Detection — ⚠️ DEFERRED TO PHASE 3

> **Cost-optimisation deferral:** eBPF-based packet-level anomaly detection adds kernel-level
> tooling and bpftrace maintenance overhead. For Phase 0–2, standard `iftop`, `netstat`, and
> Prometheus node_exporter network metrics provide sufficient visibility at zero additional cost.
> Implement LION when network security budget is confirmed and SecEng-1 capacity allows.
> ICV slot 22 (`v_network_anomaly_score`) zero-filled during Phase 0–2 (neutral per ADR-019).

LION (Lightweight Identifier-Oblivious eNgine) equivalent: an efficient anomaly detector for
our own network I/O. Uses eBPF to capture packet timing and size patterns on our management
NIC (not hot-path NIC) and alerts on unusual patterns.

```bash
# eBPF-based network anomaly — read-only tracing of our own management NIC
# Tool: bpftrace script, runs with CAP_BPF only (minimal privilege)
# Detects: unusual packet size distributions, timing anomalies, connection floods

sudo bpftrace -e '
  tracepoint:net:netif_receive_skb /str(args->name) == "mgmt0"/ {
    @size_hist = hist(args->len);
    @pps = count();
  }
  interval:s:10 {
    print(@size_hist); print(@pps);
    clear(@pps);
  }
'
# Output parsed by Python service → published to ClickHouse network_health table
```

**ICV slots populated by 17A:** slots 22–24

| ICV Slot | Signal | Range | Update Rate |
|---|---|---|---|
| 22 | `v_network_anomaly_score` | 0.0 – 1.0 | 10s |
| 23 | `v_peer_diversity_score` | 0.0 – 1.0 | 60s |
| 24 | `v_block_prop_delay_z` | z-score vs. 30d baseline | per block |

**Risk action:** If `v_network_anomaly_score > 0.80` → page SecEng-1 → manual investigation.
Does NOT auto-halt trading (network anomaly ≠ trading halt without human confirmation).

---



## 18. Audit Logging, Database Schema & White-Box Traceability

### 18.1 ClickHouse Schema — Complete — [FIXED Mi3, M14]

**[FIXED Mi3] All long-retention tables (5-year and 7-year) use MONTHLY partitioning and a
warm/cold tiering policy. At 1,000 decisions/second over 5 years ≈ 157 billion rows; monthly
partitions ensure queries scan at most ~2.6 billion rows per month rather than the full table.**

**[FIXED M14] `feature_store` now has a Bloom filter secondary index on `feature_id` to support
O(1) FK lookups from the `decision` table.**

Replication consistency guardrail (applies when using ReplicatedMergeTree in production):
- For `decision` and `order_lifecycle` writes: `insert_quorum = 2`.
- For compliance reads during failover: `select_sequential_consistency = 1`.
- Failover gate: only fail over to replica if replication lag is below policy threshold.

```sql
-- Raw market data
CREATE TABLE tick_raw (
    symbol              LowCardinality(String),
    exchange_ts_ns      UInt64,
    local_ts_ns         UInt64,
    price_usd           Float64,
    volume_quote        Float64,
    PRIMARY KEY (symbol, exchange_ts_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(exchange_ts_ns / 1e9))
ORDER BY (symbol, exchange_ts_ns)
TTL toDateTime(exchange_ts_ns / 1e9) + INTERVAL 30 DAY;

-- Features
CREATE TABLE feature_store (
    feature_id          UInt64,
    symbol              LowCardinality(String),
    timestamp_ns        UInt64,
    feature_vector      Array(Float32),
    feature_version     UInt16,
    PRIMARY KEY (symbol, timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY (symbol, timestamp_ns)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 30 DAY;

-- [FIXED M14] Bloom filter index for FK lookups from decision table
ALTER TABLE feature_store ADD INDEX idx_feature_id feature_id
    TYPE bloom_filter GRANULARITY 4;

-- Every ML decision — [FIXED M11] added b_explanation_approximate column
CREATE TABLE decision (
    decision_id              UUID DEFAULT generateUUIDv4(),
    timestamp_ns             UInt64,
    symbol                   LowCardinality(String),
    model_id                 UUID,
    feature_id               UInt64,
    t_raw_action             Array(Float32),
    v_action_direction       Int8,
    v_kelly_fraction         Float32,
    v_model_confidence       Float32,
    v_chaos_penalty          Float32,
    v_energy_drift           Float32,
    v_sample_entropy         Float32,
    v_latency_us             Float32,
    reason_code              String,
    b_explanation_approximate UInt8 DEFAULT 0,  -- [FIXED M11] 1 if surrogate ≠ neural action
    b_explanation_ood        UInt8 DEFAULT 0,   -- 1 if OOD fallback explanation used
    PRIMARY KEY (decision_id)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY (timestamp_ns, decision_id)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 5 YEAR
SETTINGS storage_policy = 'tiered';   -- [FIXED Mi3] warm/cold tiering

-- Tiered storage policy (defined in ClickHouse config):
-- hot:  SSD NVMe  → 0–6 months
-- warm: HDD NAS   → 6–24 months
-- cold: tape/S3   → 24 months up to table TTL (5 years for decision/order tables, 7 years for drop_copy)
--
-- Storage policy XML (config.d/storage.xml):
-- <policy name="tiered">
--   <volumes>
--     <hot>  <disk>nvme</disk>  </hot>
--     <warm> <disk>hdd_nas</disk> </warm>
--     <cold> <disk>s3_tape</disk> </cold>
--   </volumes>
--   <move_factor>0.2</move_factor>   -- [FIXED Audit 18.1] move parts when ≤20% free on current volume
-- </policy>
-- TTL rules (above) are the primary movement mechanism (age-based).
-- move_factor is the secondary mechanism (capacity-based overflow guard).

-- Order lifecycle
CREATE TABLE order_lifecycle (
    order_id            UInt64,         -- [FIXED M3] 64-bit monotonic ID
    decision_id         UUID,
    symbol              LowCardinality(String),
    side                Int8,
    order_type          LowCardinality(String),
    price               Float64,
    size                Float64,
    status              LowCardinality(String),
    reason_code         String,
    b_explanation_approximate UInt8 DEFAULT 0,  -- [FIXED M11]
    b_explanation_ood        UInt8 DEFAULT 0,
    placed_ns           UInt64,
    acked_ns            UInt64 DEFAULT 0,
    filled_ns           UInt64 DEFAULT 0,
    fill_price          Float64 DEFAULT 0,
    fill_size           Float64 DEFAULT 0,
    PRIMARY KEY (order_id)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(placed_ns / 1e9))
ORDER BY (placed_ns, order_id)
TTL toDateTime(placed_ns / 1e9) + INTERVAL 5 YEAR
SETTINGS storage_policy = 'tiered';

-- Drop copy (immutable hash chain)
CREATE TABLE drop_copy (
    seq_no              UInt64,
    exchange_order_id   String,
    prev_hash           FixedString(64),
    raw_fix_message     String,
    received_ns         UInt64,
    PRIMARY KEY (seq_no)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(received_ns / 1e9))
SETTINGS index_granularity = 1
TTL toDateTime(received_ns / 1e9) + INTERVAL 7 YEAR;

-- SHAP attributions, symbolic equations, drift metrics, safety events, model registry,
-- signing audit — schemas unchanged from v1.0; all gain PARTITION BY toYYYYMM(...).
```

### 18.2 Lineage Trace — Decision Provenance

```sql
SELECT d.decision_id, d.reason_code, d.b_explanation_approximate, d.b_explanation_ood,
       d.v_action_direction, d.v_kelly_fraction, d.v_model_confidence,
       a.feature_name, a.shap_value,
       f.timestamp_ns, f.feature_vector[1] AS log_return_1tick
FROM decision d
JOIN attribution a ON d.decision_id = a.decision_id
JOIN feature_store f ON d.feature_id = f.feature_id
    AND f.symbol = d.symbol   -- [FIXED M14] use PK for join efficiency
WHERE d.timestamp_ns BETWEEN 1704067921234567000 AND 1704067921234567100
ORDER BY abs(a.shap_value) DESC
LIMIT 20;
```

### 18.3 Audit Logger — Rust Implementation

```rust
// Non-blocking fire-and-forget to Kafka; audit logger MUST NOT crash the hot path
pub async fn f_log_decision(&self, decision: &c_decision_record) {
    let payload = serde_json::to_string(decision).unwrap_or_default();
    let record  = FutureRecord::to(&self.topic).key(&decision.symbol).payload(&payload);
    self.producer.send(record, rdkafka::util::Timeout::Never).await.ok();
}
```

---



### 18.4 Intelligence Audit Tables [I12]

Four new ClickHouse tables for complete intelligence audit trail.

```sql
-- Intelligence Context Vector snapshots (every 100ms → ~864,000 rows/day)
CREATE TABLE intelligence_context (
    timestamp_ns    UInt64,
    symbol          LowCardinality(String),
    icv_vector      Array(Float32),   -- 32 elements
    v_kelly_mult    Float32,
    v_data_stale    UInt8,            -- 1 if any slot stale
    PRIMARY KEY     (symbol, timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY (symbol, timestamp_ns)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 7 DAY;   -- 7 days retention (high volume)

-- Whale events (ARGOS scores ≥ 50)
CREATE TABLE whale_events (
    timestamp_ns    UInt64,
    symbol          LowCardinality(String),
    v_argos_score   Float32,
    v_whale_type    Int8,             -- -1/0/+1
    v_consolidation Float32,
    v_exchange_flow Float32,
    v_otc_signal    Float32,
    v_hedge         Float32,
    v_agent_data    String,           -- JSON blob of agent outputs
    PRIMARY KEY     (symbol, timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY (symbol, timestamp_ns)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 7 YEAR;  -- 7-year retention (compliance)

-- Mempool large transaction events
CREATE TABLE mempool_events (
    timestamp_ns    UInt64,
    chain           LowCardinality(String),   -- BTC / ETH
    tx_hash         String,
    v_notional_usd  Float64,
    v_fee_rate      Float32,
    v_congestion    Float32,
    PRIMARY KEY     (chain, timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY (chain, timestamp_ns)
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 90 DAY;

-- Network security events (17A)
CREATE TABLE network_health (
    timestamp_ns    UInt64,
    v_anomaly_score Float32,
    v_peer_diversity Float32,
    v_block_prop_z  Float32,
    v_event_type    LowCardinality(String),
    v_detail        String,           -- JSON
    PRIMARY KEY     (timestamp_ns)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(toDateTime(timestamp_ns / 1e9))
ORDER BY timestamp_ns
TTL toDateTime(timestamp_ns / 1e9) + INTERVAL 1 YEAR;
```

---



## 19. Drift Detection, Retraining & Model Governance

### 19.1 Drift Detection — PSI + ADWIN

PSI computed every hour across all 128 features using a hybrid threshold policy:
- Hard floor: PSI > 0.20 triggers immediate conservative mode.
- Adaptive band: PSI above rolling 95th percentile of last 7 days triggers warning escalation.
ADWIN on prediction error stream — triggers retrain on detected error distribution change.

### 19.2 Retraining Workflow — [FIXED M12]

**[FIXED M12] The assertion `not market hours` is invalid for 24/7 crypto markets. Changed to
`low-liquidity UTC window (02:00–06:00 UTC)`, which empirically has the lowest global crypto
spot and perpetual trading volume.**

```yaml
retraining_workflow:
  # Triggered by: PSI > 0.2 | ADWIN drift | weekly scheduled (Monday 03:00 UTC)
  pre_checks:
    - assert: cgroups restrict training to cores 48-63
    - assert: current UTC hour in [2, 3, 4, 5]   # [FIXED M12] low-liquidity window
    - assert: surrogate CPU cap <= 30%

  steps:
    1. fetch_new_data:
        source: ClickHouse tick_raw (last 90 days)
        validation: checksum + no-lookahead temporal split

    2. train_mamba_incremental:
        # Only if reconstruction error > 7%
        epochs: 20
        lr: 1e-5

    3. recalibrate_sde_thresholds:
        # Recompute rolling 7-day 99th percentile energy drift
        update: cfg_drift_threshold   # [FIXED Mi1]

    4. recalibrate_chaos_threshold:
        # Recompute 90th percentile PCA-reduced sample entropy  [FIXED C6]
        # Also refit PCA model if SDE weights changed
        update: cfg_chaos_threshold

    5. retrain_surrogate_tree:
        data: last 100k decisions from champion
        assert: agreement > 85%
        export: ONNX + Rust-compiled tree

    6. run_simulation_validation:
        duration: 4 hours
        assert: Sharpe > 1.0

    7. promote_to_shadow:
        # Only if all assertions pass
        action: deploy to challenger slot

  on_failure:
    - keep_current_champion
    - alert WARNING
    - log to safety_events
```

### 19.3 Model Governance — Model Cards

**[FIXED Mi6] "VIX-equivalent > 80" replaced with a crypto-appropriate metric.**

```yaml
known_failure_modes:
  - "Exchange outages > 5 minutes: gap token may be insufficient"
  - "Coordinated market manipulation: ManipulationGuard may lag"
  - "Crypto flash crashes: 1-hour realized volatility > 5% (equiv. 300% annualized).
     Chaos penalty reduces positions automatically but SDE may not have been trained
     on comparable regimes."
bias_assessment: >
  Trained predominantly on 2020-2021 bull market data.
  Bear-market performance validated on 2022 only.
  Weight bear periods higher in future retraining.
```

### 19.4 A/B Testing Framework — [FIXED M7]

**[FIXED M7] Standard IID bootstrap is invalid for financial time series due to temporal
autocorrelation. It produces anti-conservative confidence intervals (overstates significance).
Replaced with the stationary block bootstrap (Politis & Romano, 1994).**

```python
from arch.bootstrap import StationaryBootstrap

def f_ab_test(
    champion_model, challenger_model,
    historical_ticks: list,
    n_trials: int = 1000,
    block_length: int = 50,  # blocks of ~50 ticks; tune to autocorrelation length
) -> c_ab_result:
    champion_sharpes   = []
    challenger_sharpes = []

    # [FIXED M7] Stationary block bootstrap (preserves autocorrelation structure)
    bs = StationaryBootstrap(block_length, historical_ticks)

    for _, (sample,) in zip(range(n_trials), bs.bootstrap(n_trials)):
        champion_sharpes.append(f_backtest_sharpe(champion_model, sample))
        challenger_sharpes.append(f_backtest_sharpe(challenger_model, sample))

    import scipy.stats
    t_stat, p_value = scipy.stats.ttest_ind(challenger_sharpes, champion_sharpes)

    return c_ab_result(
        challenger_wins=(np.mean(challenger_sharpes) > np.mean(champion_sharpes)),
        p_value=p_value,
        significant=(p_value < 0.05),
        effect_size=np.mean(challenger_sharpes) - np.mean(champion_sharpes)
    )

# Challenger promoted to shadow only if: challenger_wins AND significant AND effect_size > 0
```

---

## 20. Health Monitoring, Alerting & Crash-Loop Prevention

### 20.1 Health Metrics — Per Component

| Component | Metric | Healthy Range | Alert Level | Action |
|---|---|---|---|---|
| Mamba-2 | Reconstruction error | < 5% | WARNING > 7%, CRITICAL > 15% | Retrain / rollback |
| Neural SDE | Energy drift p99 (7-day rolling) | < cfg_drift_threshold | WARNING > 0.5× threshold | Reduce dt; rollback |
| Actor | Model confidence mean | > 0.55 | WARNING < 0.50 | Conservative mode |
| Sample Entropy | v_chaos_penalty | > 0.3 | WARNING < 0.2 for > 10 min | Reduce position sizes |
| OMS | Order latency p99 | < 200μs | WARNING > 300μs, CRITICAL > 500μs | Reduce batch; halt if critical |
| OMS | Reconciliation discrepancies | 0 | CRITICAL if > 0 | Halt; cancel all; manual review |
| Surrogate tree | Agreement with champion | > 85% | WARNING < 83%, CRITICAL < 80% | Retrain surrogate; halt if critical |
| **[FIXED M11]** Surrogate | b_explanation_approximate rate | < 15% per hour | WARNING > 15%, CRITICAL > 25% | Flag to compliance; halt if critical |
| Explainability | b_explanation_ood rate | < 5% per hour | WARNING > 5%, CRITICAL > 10% | Force rule-based fallback + manual compliance review |
| Drop copy | Hash chain integrity | Valid | CRITICAL on any failure | Halt immediately |
| Feature engineering | Feature version mismatch | 0 | CRITICAL | Refuse start; alert |
| GPU memory | Free VRAM | > 30GB (challenger active) | WARNING < 25GB | Deactivate challenger |
| Clock drift | PTP vs GPS | < 10μs | WARNING > 10μs, CRITICAL > 100μs | Alert; timestamps non-compliant |
| Funding rate | Rate per 8h window | < 0.1% | WARNING ≥ 0.1% | Reduce perpetual position limits 50% |

### 20.2 Crash-Loop Prevention — [FIXED M8]

**[FIXED M8] The original crash guard tracked only `v_last_crash_time` and reset the count if
that single timestamp was outside the 5-minute window. This failed to correctly detect scenarios
where crashes 1 and 2 were within the window but crash 3 arrived after crash 1 had expired,
leading to incorrect backoff scheduling. Fixed to use a deque of all crash timestamps.**

```rust
// src/execution/crash_guard.rs
use std::collections::VecDeque;
use std::time::{Duration, Instant};

pub struct c_crash_guard {
    cfg_window:      Duration,  // 5 minutes
    cfg_max_crashes: usize,     // 5 before permanent halt
    crash_times:     VecDeque<Instant>,  // [FIXED M8] sliding window of all crash times
}

impl c_crash_guard {
    pub fn f_on_crash(&mut self) -> Option<Duration> {
        let now = Instant::now();

        // [FIXED M8] Remove crashes outside the sliding window
        while let Some(&t) = self.crash_times.front() {
            if now.duration_since(t) > self.cfg_window {
                self.crash_times.pop_front();
            } else {
                break;
            }
        }

        // Record current crash
        self.crash_times.push_back(now);
        let v_crash_count = self.crash_times.len();

        if v_crash_count >= self.cfg_max_crashes {
            return None;   // HALT — do not restart
        }

        // Exponential backoff
        match v_crash_count {
            1 => Some(Duration::from_secs(0)),
            2 => Some(Duration::from_secs(10)),
            3 => Some(Duration::from_secs(60)),
            4 => Some(Duration::from_secs(300)),
            _ => None,
        }
    }
}

// On crash:
// 1. Save forensic state to /var/predator/crash_dump/
// 2. Enter fallback mode (rule-based conservative market making) OR complete halt
// 3. Operator decides via TOTP
```

### 20.3 Active Health Probes

```python
def f_probe_synthetic_input(interval_seconds=60):    # golden input check
def f_probe_latency(interval_decisions=1000):        # p99 on last 1000 decisions
def f_probe_challenger_agreement(interval_minutes=10): # champion vs challenger
def f_probe_drop_copy_lag(interval_seconds=30):      # < 5s lag
def f_probe_dependency_slo(interval_seconds=30):      # API latency/error/staleness budgets
def f_probe_trace_span_gaps(interval_seconds=60):     # missing stage spans by trace_id
```

### 20.4 Monitoring Stack

| Tool | Purpose | Deployment |
|---|---|---|
| Prometheus | Metrics collection | Management network, 15s scrape |
| Grafana | Real-time dashboards | Management network |
| PagerDuty | Incident routing (CRITICAL → call+SMS; WARNING → Slack) | Cloud |
| ClickHouse | Long-term metrics storage | Management network |

**Mandatory dashboard panels:** Energy drift, chaos penalty, order latency histogram (p50/p90/p99/p999),
net delta + gross exposure, surrogate agreement %, crash counter, PSI heatmap, active capital,
b_explanation_approximate rate per hour, b_explanation_ood rate, trace_id span latency by stage,
dependency health (per external API: latency, error rate, staleness).

### 20.5 Degraded-Mode State Machine

| Mode | Entry Condition | Trading Behavior | Exit Condition |
|---|---|---|---|
| Conservative | Early warning threshold breach | Reduced Kelly and tighter risk limits | Metrics normalize for hold period |
| Monitor-only | Persistent warning across windows | No new exposure increase; risk-reduction orders only | Operator or auto-clear policy |
| Reduce-only | Severe anomaly or reconciliation uncertainty | Only close/reduce positions; block opening orders | Root-cause resolved and verified |
| Halt | Critical safety event | Cancel/stop order flow; manual re-entry protocol | Section 21.5 sign-off |

---

## 21. Kill Switch, Incident Response & Disaster Recovery

### 21.1 Kill Switch Architecture — [FIXED M6]

```
PATH A — Automated Circuit Breaker (immediate, no operator):
  Trigger: daily loss > 2% OR drawdown > 5% OR crash loop ≥ 5
  Action:
    1. Set b_trading_halted = true in shared memory (atomic CAS)
    1a. Start global cancel deadline timer: cfg_killswitch_cancel_global_timeout_ms = 5000
    2. Mass-cancel all open orders:
       Binance futures: DELETE /fapi/v1/allOpenOrders (expected p99: 200–500ms)
    3. [FIXED M6] If mass-cancel does not return SUCCESS within 1,000ms:
       → Fall back to per-order cancellation loop:
          for order_id in f_get_all_open_order_ids():
              f_cancel_single_order(order_id)   # with 200ms timeout per order
       → Continue until all orders confirmed cancelled or exchange unreachable
    3a. If global cancel deadline (5s) expires before reconciliation is clean:
       → Force safe-stop: block new order flow, close exchange sessions, require manual recovery.
       → Record `KILLSWITCH_CANCEL_GLOBAL_TIMEOUT` in safety_events.
    4. Log to safety_events
    5. Alert CRITICAL to PagerDuty

PATH B — Manual Operator Kill (YubiKey TOTP, 3-second confirmation):
  Same actions as Path A
  Emergency bypass: 2-of-3 operators can override without TOTP (M-of-N in Vault)
```

### 21.2 Incident Response Playbooks

Playbooks IR-001 through IR-004 unchanged from v1.0 (High Latency, OMS Reconciliation Failure,
Security Breach, Flash Crash).

### 21.3 Disaster Recovery Plan

**Scenario 1 (Hardware Failure):** RTO 15 min; DR node at SG1, warm champion weights synced hourly.
**Scenario 2 (Exchange Connectivity Loss):** RTO 5 min; backup connectivity + OKX failover.
**Scenario 3 (Data Center Power):** UPS 30 min; graceful shutdown; DR activation.

### 21.4 Mass-Cancel Pre-Testing — [FIXED M6]

**[FIXED M6] The mass-cancel endpoint must be load-tested before any live capital deployment
and documented in the acceptance gates (see §29).**

```
Mass-cancel load test protocol:
  Precondition: paper-trading environment (no real capital)
  Step 1: Place 50 simultaneous resting limit orders
  Step 2: Execute DELETE /fapi/v1/allOpenOrders
  Step 3: Record response time; repeat 10× to get p99
  Pass criteria: p99 < 1,000ms
  If fail: document that per-order fallback will be used; set cfg_mass_cancel_timeout_ms = 500
  Step 4: Simulate hanging cancel endpoint and verify global 5s safety timeout path.
  Run: weekly during load test window (Sunday 08:00–10:00 UTC)
```

### 21.5 Graceful Re-Entry After Kill Switch — [FIXED M5, NEW SECTION]

**[FIXED M5] The v1.0 plan described halting and cancelling orders but provided no specification
for how to safely resume trading. Without a controlled re-entry protocol, resuming with the same
model after a daily-loss halt risks triggering the same loss condition immediately.**

```
Mandatory re-entry protocol after any automated halt (Path A):

STEP 1 — Cool-down (30 minutes minimum):
  • b_trading_halted remains true
  • Operators review: what triggered the halt? Same market conditions?
  • If trigger was model-related (recurring large losses) → do not resume until retrained
  • If trigger was exchange-related (flash crash, connectivity) → check market stability

STEP 2 — Paper-trade validation (1 hour minimum):
  • Enable paper trading mode (live market data, NO real order submission)
  • Monitor: would the system have lost money in the past hour?
  • Pass criterion: simulated PnL within ±50% of expected from simulation environment
  • If simulated PnL would have exceeded daily loss limit again → EXTEND cool-down + alert CRO

STEP 3 — Manual re-enable (2-operator sign-off):
  • Both operators review paper-trade log
  • One operator provides TOTP challenge for `b_trading_halted = false`
  • Second operator confirms via separate TOTP within 60 seconds
  • Resumption at 50% position limits for the first 2 hours; auto-restore to 100% if clean

STEP 4 — Post-incident report (within 24 hours):
  • Root cause documented in safety_events
  • Corrective action plan filed with compliance officer
  • Board notification if daily loss > 5% of total allocated capital
```

---

## 22. Business Continuity & Exchange Redundancy

### 22.1 Exchange Portfolio

| Exchange | Instruments | Role | Connectivity |
|---|---|---|---|
| Binance Futures | BTCUSDT, ETHUSDT, SOLUSDT | Primary | NY4 + SG1 cross-connect |
| OKX | BTCUSDT, ETHUSDT | Backup (hot standby) | SG1 cross-connect |
| Interactive Brokers | XAUUSD spot | Primary | FIX API |

### 22.2 Multi-Exchange Normalization

When trading on OKX as backup:
- Instrument mapping: `BTC-USDT-SWAP` (OKX) = `BTCUSDT` (Binance)
- TradingCostModel recalculated with OKX rates
- Step size differences handled by adapter layer
- Funding rate timing difference accounted for in funding model

### 22.3 Cross-Exchange Position Tracking

```python
class c_cross_exchange_position_tracker:
    def f_risk_check_cross_exchange(self) -> bool:
        # Risk limits apply to TOTAL cross-exchange position — not per-exchange
        for symbol in cfg_symbols:
            v_net = self.f_net_position(symbol)
            if abs(v_net) > cfg_max_net_delta * v_capital:
                return False
        return True
```

### 22.4 API Key Rotation Schedule

Never rotate during Asian session (02:00–10:00 HKT) or US session (09:30–16:00 ET).
Binance: Sunday 02:00–04:00 UTC; OKX: Sunday 04:00–06:00 UTC; IB: Monday 01:00–02:00 UTC.

### 22.5 Exchange Capability Matrix Validation

Before enabling any venue in production, validate and store:
- Supported order-entry protocol and auth method
- Execution report semantics (ack/fill/cancel states, ordering guarantees)
- Symbol naming, precision, step size, and minimum notional rules
- Error-code mapping for cancel races and transient failures

Deploy is blocked if capability matrix status is not `VERIFIED` for the active venue.

---

## 23. Regulatory Compliance & Reporting Automation

### 23.1 Regulatory Framework Coverage

| Regulation | Key Requirements | Coverage |
|---|---|---|
| MiFID II RTS 6 | Algo trading controls, annual self-assessment | ManipulationGuard, OTR, kill switch, ex-ante explanations |
| MiFID II Article 17 | Audit trail and algorithmic trading records, minimum 5-year retention | ClickHouse 5-year for decisions/orders; 7-year immutable drop copy |
| SEC Rule 15c3-5 | Market access controls | Portfolio Risk Manager, pre-trade checks |
| FATF AML/CFT Standards | Customer/due-diligence and suspicious activity controls | KYC/AML process controls outside hot path; audit trail supports investigations |

### 23.2 Ex-Ante Explanation Compliance

**Implementation:** Rust-compiled surrogate tree reason code logged to `order_lifecycle.reason_code`
synchronously before `ef_vi` dispatch.

**[FIXED M11] Per-order `b_explanation_approximate` flag logged. Daily compliance report includes:**
- Total orders with `b_explanation_approximate = 1`
- Total orders with `b_explanation_ood = 1`
- If rate > 15% in any hour → WARNING; > 25% → CRITICAL + pause trading pending review
- Human review required for all orders with `b_explanation_approximate = 1` before regulatory submission

OOD compliance rule:
- If `b_explanation_ood = 1`, the explanation is flagged as fallback-only and is never auto-submitted.
- OOD orders require explicit human sign-off in the daily compliance workflow.

### 23.3 Automated Regulatory Reporting

MiFID II transaction reports: submitted daily by 17:00 UTC to approved reporting mechanism.
Best execution report: quarterly.
Annual self-assessment: from `safety_events`, `drift_metrics`, `model_registry`.

### 23.4 Market Surveillance — ManipulationGuard Metrics

Daily report to compliance officer at 08:00 UTC: self-trade triggers, OTR breaches, spoofing
detections, OTR max/mean, total orders/cancels/fills.

---

## 24. Data Retention, Backup & Archival — [FIXED Mi3]

### 24.1 Retention Policy

| Data Type | Retention | Storage Tier | Backup | Rationale |
|---|---|---|---|---|
| Raw ticks | 30 days | ClickHouse hot (NVMe) | Daily snapshot | Training window |
| Feature store | 30 days | ClickHouse hot | Daily snapshot | Training window |
| Decisions | **5 years** | Hot 6mo → Warm 2yr → Cold 3yr | Weekly full backup | MiFID II Article 17 minimum |
| Order lifecycle | **5 years** | Tiered | Weekly full backup | MiFID II Article 17 minimum |
| Drop copy | **7 years** | Immutable partition, tiered | Weekly + off-site copy | Regulatory must; extendable to 7 per regulator request |
| Attribution (SHAP) | **5 years** | Tiered | Weekly full backup | MiFID II Article 17 minimum |
| Safety events | **5 years** | Tiered | Weekly full backup | MiFID II Article 17 minimum |
| Model weights | Indefinite | Encrypted Minio (on-prem) | Daily sync to off-site | Algorithm change audit |
| Whale events | **5 years** | Tiered | Weekly full backup | Regulatory subpoena risk; MiFID II aligned |
| Mempool events | 90 days | Hot | Daily snapshot | Operational post-mortem only |
| Intelligence context | **2 days** | Hot | None required | Post-mortem only; 864k rows/day; no regulatory value |
| Network health | 1 year | Hot | Weekly | Security audit |

> **Retention reduction — MiFID II compliance confirmed:** MiFID II Article 17 mandates 5-year
> minimum retention for all trade-related records. Retention can be extended to 7 years at
> explicit regulator request (BaFin, FCA). The prior 7-year default on decisions, orders,
> SHAP, and safety events was a deliberate 2-year buffer (ADR-008). This revision aligns to the
> 5-year statutory minimum, retaining 7 years **only** for drop_copy (hash chain) where
> immutability and length provide additional legal protection. Estimated cold-storage saving:
> ~28% reduction in 7-year table footprint (~60 TB → ~43 TB at Year 7).
> CRO and Compliance Officer must sign off before deployment.

**[FIXED Mi3] Monthly partitions on all 5/7-year tables ensure:** (a) queries scan ≤ 1 partition for
date-ranged queries, (b) TTL expiry operates at partition granularity (fast), (c) tier migration
operates on whole monthly partitions (cold-tier migration every month at 02:00 UTC).

### 24.2 Backup Protocol

Daily (02:00 UTC): `clickhouse-backup create`; AES-256 encrypt; copy to secondary NVMe + off-site.
Weekly (Sunday 01:00 UTC): full backup of all tables + model registry.
Verification: weekly restore test to isolated ClickHouse; query count vs production ± 5.

### 24.3 Drop Copy Immutability

Drop copy table: INSERT-only privileges for Predator process. No DELETE, UPDATE, DROP, ALTER.
Hash chain verified at every reconciliation.

---

## 25. Capital Allocation & Staged Rollout Framework

### 25.1 Capital Staging Gates

| Stage | Capital % | Duration | Pass Criteria | Approvals |
|---|---|---|---|---|
| 0 — Simulation | 0% (virtual $1M) | 4 weeks | Sharpe > 1.2, max DD < 5%, zero safety events | ML Lead + Quant |
| 1 — Paper trading | 0% | 2 weeks | Risk team daily review | Risk Officer |
| 2 — Canary live | 1% | 1 week | No circuit breaker trips; P&L ±20% of sim | CRO + ML Lead |
| 3 — Reduced live | 5% | 2 weeks | Sharpe > 1.0; max DD < 3% | CRO |
| 4 — Half allocation | 20% | 4 weeks | Sharpe > 1.0; max DD < 4% | CRO + Board Risk |
| 5 — Full allocation | 50% | Ongoing | Quarterly re-assessment | Board Risk Committee |
| Max allocation | 50% | — | Hard cap; never exceed without board approval | Board |

**Daily loss limit:** 2% triggers automatic halt + CRO manual re-enable after cool-down (§21.5).

### 25.2 Position Limits by Instrument

| Instrument | Max position (% capital) | Max daily volume (% avg daily) |
|---|---|---|
| BTCUSDT | 15% | 1% |
| ETHUSDT | 10% | 1% |
| SOLUSDT | 5% | 0.5% |
| XAUUSD | 10% | 0.1% |
| **Total gross** | **50%** | — |

---

## 26. Capacity Planning & Cost Modeling

### 26.1 Throughput Projections

| Metric | Current Target | Year 1 Peak | Year 2 Peak |
|---|---|---|---|
| Ticks per second | 10,000 | 50,000 | 100,000 |
| Decisions per second | 1,000 | 5,000 | 10,000 |
| Orders submitted per day | 10,000 | 50,000 | 100,000 |
| ClickHouse inserts/sec | 5,000 | 25,000 | 50,000 |

**Scaling:** Second H100 at Year 1 peak. ClickHouse horizontal sharding by symbol. Kafka partitions added.

### 26.2 Infrastructure Cost Model (Monthly)

| Item | Phase 0–2 (Stages 0–2, ≤5% capital) | Full Build (Stage 3+) | Notes |
|---|---|---|---|
| Equinix NY4 colocation | $2,500 | $2,500 | Always required |
| Equinix SG1 (DR) | **$0** | $1,500 | Cloud warm-standby replaces SG1 bare metal for Stages 0–2 (see §3.1) |
| Cloud DR (AWS ap-southeast-1, warm-standby) | **$400** | $0 | c6i.8xlarge; no GPU on DR; RTO ~25 min acceptable at low capital |
| H100 bare-metal (amortized 3yr) | $4,000 | $4,000 | Mandatory — A10G cannot meet 500μs SLA (see §3.1) |
| Solarflare cross-connect | $500 | $500 | Mandatory |
| Thales Luna HSM (amortized 5yr) | $300 | $300 | Mandatory; now using Ed25519 (≤5μs vs 50μs for ECDSA P-256) |
| NVMe + NAS storage (tiered) | $400 | $400 | Retention now 5yr (decisions/orders); ~28% smaller than 7yr |
| Binance API fees | $200 | $200 | |
| Tardis.dev historical data | **$0** | $500 | One-time historical pull; ongoing free after data downloaded |
| Nansen / Arkham / Kaiko (intelligence APIs) | **$0** | $1,500–$3,000 | Deferred: Phase 1 uses free-tier APIs (CoinMetrics Community, Blockstream RPC) |
| PagerDuty (CRITICAL only; WARNING → Slack webhook) | **$50** | $200 | Reduced tier for Stages 0–2 |
| Vault + Minio (on-prem) | $100 | $100 | |
| **Total estimated monthly** | **~$7,950** | **~$11,200** | |

> **Phase 0–2 savings vs original spec: ~$2,250/month** — without cutting any mandatory compliance,
> latency-critical, or audit-required component. Key sources: SG1 deferral ($1,100), Nansen/Kaiko
> deferral ($1,500), reduced PagerDuty ($150), Tardis one-time pull ($500 recouped Month 2+).

Profitability requires Stage 4 (20% allocation, $20M+ capital) at minimum. Phase 0–2 monthly
burn of ~$7,950 is covered by approximately $4M capital at 2.5% annual return before fees.

---

## 27. Team Structure, Runbooks & Onboarding

### 27.1 Team Structure

| Role | Responsibilities |
|---|---|
| ML Lead | Model architecture, training, Phase 1–6 gates |
| Platform Lead | Infrastructure, CI/CD, latency profiling |
| CRO | Risk limits, capital staging, circuit breaker policy |
| Compliance Officer | MiFID II, regulatory reporting, explanation audit |
| CISO | HSM, penetration tests, secrets management |
| SRE (2+) | Incident response, DR drills, monitoring |

### 27.2 Daily Operations Runbook — [FIXED, 24/7 Schedule]

**All operations are on a 24-hour UTC cycle (crypto is 24/7; there is no "market close"):**

```
00:00 UTC: Daily automated health report (safety events, surrogate agreement, drift metrics)
01:00 UTC: Exchange fee schedule fetch; API key validity check
02:00 UTC: Daily ClickHouse backup; [scheduled maintenance window if needed]
06:00 UTC: Surrogate tree retraining (daily)
08:00 UTC: Compliance daily report (ManipulationGuard metrics)
12:00 UTC: Mid-day health check (latency p99 trend, energy drift trend)
15:00 UTC: MiFID II transaction report generation + ARM submission
Weekly (Monday 03:00 UTC): Full retraining workflow run
Weekly (Sunday 08:00–10:00 UTC): Load test; mass-cancel pre-test
```

### 27.3 New Engineer Onboarding

4-week structured onboarding: document study → environment setup → component deep-dives →
supervised contribution. Production access: NEVER before 4 weeks + Platform Lead + CRO sign-off.

---

## 28. Load Testing, Chaos Engineering & Pre-Production Drills

### 28.1 Load Testing Protocol

**Objective:** Verify system meets SLAs at 5× expected peak (50,000 ticks/sec, 60 minutes).

**Pass criteria:**
- p99 latency < 500μs throughout
- p999 latency < 2ms
- Zero GPU OOM errors
- Kafka consumer lag < 1s at end
- Zero reconciliation failures
- Mass-cancel p99 < 1,000ms (see §21.4)

**Schedule:** Weekly (Sunday 08:00–10:00 UTC). Automated; results in Grafana.

### 28.2 Chaos Engineering Experiments

Run monthly on test node (never production):

| Experiment | Method | Pass Criteria |
|---|---|---|
| Network partition | `tc qdisc netem` | Reconnect < 5s; no stale orders sent |
| GPU OOM | Allocate 70GB extra | Champion unaffected; CRITICAL alert |
| HSM slow (100ms) | Mock HSM delay | Alert fires; no order lost |
| Crash loop | Kill process 5× in 5 min | Deque crash guard halts correctly |
| Clock drift | Skew NTP 200μs | Alert fires; timestamps flagged |
| Drop copy hash break | Inject corrupt hash | Halt within 1s |
| PSI breach | Inject OOD features | Surrogate takes over; retrain starts |
| Feed sequence gap | Inject seq gap in primary | Automatic failover to backup feed |
| Mass-cancel timeout | Mock slow exchange endpoint | Per-order fallback activates < 1s |

### 28.3 Pre-Production Drills (Before Each Capital Stage)

| Drill | Pass Criteria |
|---|---|
| Full rollback drill | Rollback < 2s; all orders cancelled; zero P&L impact |
| Kill switch drill | Orders cancelled < 1s; halt flag set; CRITICAL alert |
| DR failover drill | SG1 trading resumed < 15 min; reconciliation clean |
| Mass reconciliation | 100% match within 5 minutes |
| Graceful re-entry drill | Cool-down + paper-trade + 2-operator sign-off all validated |

---

## 29. Final Acceptance Gates — 100/100 per Phase

### Phase 0 — Architecture & Setup

| Gate | Criterion |
|---|---|
| No fictional components | All models from real papers |
| Feature version pinned | `libpredator_features` version consistent |
| Memory pre-allocated | Zero dynamic allocation on hot path |
| No DPDK | Only Solarflare OpenOnload |
| HSM on-prem | Thales Luna PCIe confirmed |
| CPU isolation | cores 0–15 isolated |
| Clock sync | PTP drift < 10μs |
| No Python on hot path | All Rust hot-path code; confirmed by code review |
| EWMA time-based | α = 1 − exp(−Δt/τ); confirmed in ingestion unit tests |
| Exchange capability matrix verified | Active venue protocol/error semantics validated before enablement |

### Phase 1 — Data & Training

| Gate | Criterion |
|---|---|
| No lookahead bias | Train = first 80% time only |
| 5-year data | 4 instruments, 4+ exchanges, checksums |
| Mamba-2 error | < 5% reconstruction on validation |
| SDE drift p99 | < 1e-4 on validation |
| Actor Sharpe | > 1.2 on out-of-sample (2024) |
| Surrogate agreement | > 85% with champion |
| Reproducibility | Two identical training runs on same software/hardware stack → bit-identical weights (deterministic CUDA, TF32 disabled) |
| PCA model | explained_variance_ratio > 0.95 with 8 components |

### Phase 2 — Latency & Infrastructure

| Gate | Criterion |
|---|---|
| Hot path p99 | < 500μs over 1 hour replay |
| Cancel path p99 | < 200μs over 1 hour replay |
| No dynamic allocation | Zero malloc/cudaMalloc during decisions |
| HSM measured | Ed25519 signing latency p99 < 10μs (measured, not assumed); ECDSA P-256 deprecated |
| Mass-cancel tested | DELETE /fapi/v1/allOpenOrders p99 < 1,000ms (paper trading) |
| Latency regression CI | No regression > 20μs vs baseline |
| Reconnect storm protection | Central manager with exponential backoff + jitter validated in chaos test |

### Phase 3 — Risk & Execution

| Gate | Criterion |
|---|---|
| Joint VaR | Computed on portfolio return (cross-asset correlation captured) |
| Stop-loss in seconds | cfg_stop_loss_vol_window in seconds confirmed |
| Kelly sizing | Continuous; rounded to step_size |
| ManipulationGuard (Rust) | Self-trade, OTR, spoofing; integration tests pass |
| Order ID monotonic | 64-bit scheme; restart persistence tested |
| Rate limit → HOLD | Rate limit exhaustion forces HOLD action; confirmed by test |

### Phase 4 — Compliance & Security

| Gate | Criterion |
|---|---|
| Ex-ante explanation | reason_code logged before dispatch; b_explanation_approximate tracked |
| Surrogate Rust | Compiled tree running on hot path; no Python on OMS critical path |
| Drop copy hash chain | All orders in immutable table; verified |
| HSM signing | Every order signed; no plaintext key in memory |
| Retention policy enforced | 5-year decision/order retention + 7-year immutable drop copy; monthly partitions verified |
| MiFID II reporting | Daily reports auto-generated and submitted |

### Phase 5 — Operations & Resilience

| Gate | Criterion |
|---|---|
| Shadow + canary + rollback | Tested weekly; rollback < 2s |
| Graceful re-entry | §21.5 protocol tested: cool-down + paper-trade + 2-operator |
| Crash-loop (deque) | 5 crashes → halt; verified with chaos engineering |
| DR failover | SG1 takes over < 15 min |
| Feed failover | Primary seq gap → backup feed automatic switch |
| Mass-cancel fallback | Per-order fallback activates on timeout |
| Kill-switch global timeout | Global 5s cancel deadline triggers safe-stop path when unresolved |

### Phase 6 — Final Certification

| Gate | Criterion |
|---|---|
| Simulation 4-week | Sharpe > 1.2; max DD < 5%; zero safety events |
| Paper trading 2-week | Risk team sign-off |
| Penetration test | Clean; no critical/high findings |
| Compliance mock audit | All MiFID II requirements met; b_explanation_approximate < 15% |
| All hyperparameters locked | Config YAML frozen; git tagged |
| Board approval | Capital deployment approved |

**→ When all Phase 0–6 gates pass → deploy at 1% capital (Stage 2, §25)**

---


---

### Intelligence Layer Acceptance Gates (Phase 1 → Phase 2)

| Gate | Criterion | Owner | Status |
|---|---|---|---|
| IG-01 | All 5A–5D modules achieving > 95% uptime over 14 consecutive days | Platform Lead | ⬜ Pending |
| IG-02 | ARGOS score Spearman ρ > 0.15 vs. 4h future price return (30d backtest) | ML Lead | ⬜ Pending |
| IG-03 | Iceberg detector false positive rate < 5% (60d L2 backtest) | Quant-1 | ⬜ Pending |
| IG-04 | Derivative signal lead time validated: skew alert precedes move by ≥ 15 min (median) | Quant-2 | ⬜ Pending |
| IG-05 | ICV stale-data handling validated: module offline → ICV slot = 0.0 within 120s | SRE-1 | ⬜ Pending |
| IG-06 | Network defense (17A) producing zero false pages in 14 days | SecEng-1 | ⬜ Pending |
| IG-07 | All 4 new ClickHouse tables partitioned and TTL enforced | SRE-2 | ⬜ Pending |
| IG-08 | Intelligence module design reviewed and signed off by Compliance Officer | Compliance-1 | ⬜ Pending |
| IG-09 | Emergency kill switch for ALL intelligence modules tested (independent of trading kill) | SecEng-1 | ⬜ Pending |
| IG-10 | CRO sign-off on Kelly Multiplier range [0.75, 1.25] for Phase 2 | CRO | ⬜ Pending |

---


---


## 31. Phased Intelligence Integration Rollout

### 31.1 Phase 1 — Observe Only (Months 1–3)

**Objective:** Deploy all intelligence modules in monitoring-only mode. Zero effect on live trading.
The ICV is computed and logged but the Kelly Multiplier is fixed at 1.0 (bypassed).

> **Cost-optimised API stack for Phase 1:** Paid institutional APIs (Nansen, Arkham, Kaiko) are
> deferred until Phase 1 gate IG-02 confirms ARGOS signal correlation (ρ > 0.15). Phase 1 runs
> on free-tier sources: **Blockstream.info** free BTC RPC, **Alchemy free tier** (330 req/sec
> ETH), **CoinMetrics Community API** (free, lower resolution for dark pool proxy estimation).
> If Phase 1 gates pass, procure paid APIs before Phase 2. If gates fail (ρ < 0.15), the free
> tier saved $1,500–$3,000/month during a period of unvalidated signal quality.

**Gate criteria to advance to Phase 2:**
- All 5 intelligence modules (5A–5D, 17A) achieving > 95% uptime
- ARGOS whale score shows statistically significant correlation with subsequent price move
  (Spearman ρ > 0.15, p < 0.01) on 30-day historical replay
- No false positives > 5% rate on iceberg detection (backtested on last 60 days L2 data)
- Network anomaly detector (17A) producing zero false page-outs on management team
- CRO + ML Lead sign-off

**Deliverables:**
- [ ] Docker deployment of all 5A–5D modules on management server
- [ ] Kafka topics and ClickHouse tables provisioned
- [ ] Grafana dashboard: "Intelligence Layer Health"
- [ ] Backtesting report: Whale signal vs. price action (30 days)
- [ ] Backtesting report: Iceberg detector precision/recall (60 days)
- [ ] API cost decision: procure Nansen/Arkham/Kaiko only if IG-02 gate passes
- [ ] False-positive cost budget approved (PnL drag and operational page budget)
- [ ] Per-module CPU/memory ceilings defined and enforced on management server

### 31.2 Phase 2 — Kelly Multiplier Live (Months 4–6)

**Objective:** Enable Kelly Intelligence Multiplier in live trading. Start at 50% strength
(multiplier range narrowed to [0.75, 1.25]) before full range deployment.

```rust
// Phase 2 config — gradual ramp
cfg_kelly_intel_mult_max: 1.25   // was 1.50 in full spec
cfg_kelly_intel_mult_min: 0.75   // was 0.50
// Expand to [0.50, 1.50] after 6-week review (Phase 2 gate)
```

**Gate criteria to advance to Phase 3:**
- Sharpe ratio improvement ≥ +0.10 vs. control period (same model, multiplier=1.0)
- No new maximum drawdown events attributable to intelligence signals
- ICV-triggered risk adjustments validated: when `v_cascade > 0.7`, subsequent VaR reduced by ≥10%
- Kelly Multiplier correlation with P&L: Spearman ρ > 0.10
- CRO + Compliance Officer sign-off

**Deliverables:**
- [ ] Phase 2 A/B analysis report (multiplier-on vs. control, block bootstrap §19.4)
- [ ] Kelly Multiplier attribution analysis (which ICV slots drive P&L delta)
- [ ] Risk adjustment validation report
- [ ] OOD explainability fallback impact report (`b_explanation_ood` incidence and compliance load)

### 31.3 Phase 3 — Full Feature Vector Expansion (Months 7–12)

**Objective:** Retrain all ML models (Mamba-2, Neural SDE, NSR, Actor) with expanded 160-dim
feature vector (128 original + 32 ICV slots). This is a full model regeneration per §12.

```
Original feature vector: (B=64, T=64, F=128) → 128 dims
Phase 3 feature vector:  (B=64, T=64, F=160) → 160 dims (32 ICV slots appended)

ICV slots sampled at 1-second resolution (vs. tick resolution for original features)
ICV slots time-aligned: for each tick timestamp t, ICV[t] = last known ICV value before t
Zero-padding applied for historical data pre-intelligence layer (pre Phase 1 deployment)
```

**Model changes required:**
- Mamba-2 input dimension: 128 → 160 (new embedding layer added; rest frozen initially)
- Neural SDE: input to c_potential_net unchanged (operates on latent q, not raw features)
- NSR: retrained on new regime definitions
- Actor: input via new latent (256-dim, unchanged; only upstream changes)
- Surrogate tree: retrained on new feature set

**Training pipeline changes (§12):**
- Historical ICV reconstruction: replay intelligence modules on historical data to generate
  ICV values for the full 5-year training set
- Zero-fill for BTC/ETH L2 features pre-2023 (ICV slots 10–11 require L2 data)
- 90-day paper trading validation before Phase 3 live deployment
- Full Phase Gate: same 100/100 acceptance criteria as original §29

---



---


### Appendix E (v1.2 additions) — ADR-017 to ADR-025

| ADR | Decision | Rationale |
|---|---|---|
| ADR-017 | Intelligence modules on MANAGEMENT SERVER (not trading server) | Prevents any resource contention with hot path; full nodes require significant RAM/storage |
| ADR-018 | BTC/ETH full nodes on management NIC only | Full node sync traffic is multi-GB/day; must not touch hot-path trading NICs |
| ADR-019 | ICV is 32-dim with zero-fill for stale slots (not NaN) | NaN propagation through downstream calculations is silent and dangerous; zero = neutral signal |
| ADR-020 | NSR intelligence conditioning applied at WEEKLY recalibration only (not per-tick) | Per-tick ICV conditioning would change live NSR output unpredictably; weekly is safe |
| ADR-021 | Kelly Multiplier bounded [0.50, 1.50] hard clamp | Intelligence signals may be wrong; Kelly's own risk controls remain primary; clamp prevents intelligence from overriding risk |
| ADR-022 | Phase 1 deploy with multiplier=1.0 (observe-only) | System must demonstrate intelligence signal quality before it affects real capital |
| ADR-023 | Intelligence API keys in Thales HSM (separate partition from trading keys) | API key compromise must not expose trading keys; HSM partition isolation |
| ADR-024 | Whale event 7-year ClickHouse retention | Regulators may subpoena trading decision context; whale events explain sizing decisions |
| ADR-025 | Network defense modules are PASSIVE ONLY (no packet injection, no routing manipulation) | Legal compliance requirement; active network interference is criminal in all relevant jurisdictions |

---


*Legacy marker from superseded Intelligence Addendum retained for traceability only.*


## 30. Appendices

### Appendix A — Naming Convention

| Prefix | Meaning | Example |
|---|---|---|
| `c_` | Class | `c_portfolio_risk_manager` |
| `f_` | Function / method | `f_kelly_fraction()` |
| `v_` | Scalar variable | `v_energy_drift` |
| `t_` | Tensor | `t_tick_features` |
| `b_` | Boolean | `b_risk_ok` |
| `s_` | String | `s_equation` |
| `cfg_` | Configuration constant | `cfg_sde_dt` |
| `buf_` | Pre-allocated buffer | `buf_latent` |

Prohibited: single-letter names except loop counters, `temp`/`tmp`/`data`/`result`, `x`/`y` as tensor names.

### Appendix B — All Hyperparameters (Fixed, Version-Controlled)

```yaml
# config/production_v1.2A.yaml — git tag: v1.2A-production
# All changes require ML Lead + CRO sign-off + new git tag

# Mamba-2
cfg_mamba_d_model:            512
cfg_mamba_d_state:            64
cfg_mamba_n_layers:           4
cfg_mamba_batch_size:         64
cfg_mamba_seq_len:            64
cfg_mamba_features:           128

# CoPE
cfg_cope_window_ms:           100.0
cfg_cope_alpha:               0.1

# [FIXED C1] EWMA — time-based
cfg_ewma_tau_price_sec:       60.0     # time constant for price EWMA (seconds)
cfg_ewma_tau_volume_sec:      60.0     # time constant for volume EWMA (seconds)
# REMOVED: cfg_ewma_window_ticks (was 60,000 — tick-based, incorrect)

# Neural SDE
cfg_sde_dt:                   0.001
cfg_sde_steps:                10
cfg_sde_gamma_init:           0.1
cfg_sde_sigma_init:           0.05     # training only; σ=0 in live mode

# Sample Entropy / Chaos  [FIXED C6]
cfg_chaos_sample_m:           2
cfg_chaos_sample_r_factor:    0.2
cfg_chaos_threshold_pct:      90
cfg_pca_n_components:         8        # PCA dims for sample entropy (NEW)

# NSR
cfg_nsr_transformer_layers:   4
cfg_nsr_heads:                8
cfg_nsr_d_model:              256
cfg_nsr_diffusion_steps:      1000
cfg_nsr_log_threshold:        0.60
cfg_nsr_gate_threshold:       0.75
cfg_nsr_regime_k:             5
cfg_nsr_regime_recal_utc_day: 0       # Monday

# Actor
cfg_actor_hidden:             512
cfg_actor_output_dim:         8

# Kelly
cfg_kelly_max_fraction:       0.25
cfg_kelly_min_confidence:     0.60
cfg_kelly_lookback_days:      30

# [FIXED C3] Stop-loss — time-based
cfg_stop_loss_k:              2.5
cfg_stop_loss_vol_window_sec: 300      # seconds (≈5 minutes) [was: 300 ticks — WRONG]
# REMOVED: cfg_stop_loss_vol_window (tick-based alias — deleted)

# [FIXED C2] Realized volatility windows — seconds
cfg_realized_vol_windows_sec: [60, 300, 900]   # 1min, 5min, 15min
# REMOVED: tick-based equivalents

# Portfolio risk limits
cfg_max_net_delta_pct:        0.20
cfg_max_gross_exposure_pct:   0.50
cfg_max_var_pct:              0.05

# Transaction costs
cfg_taker_rate:               0.00040
cfg_maker_rate:               0.00020
cfg_impact_coef:              0.001

# Latency
cfg_latency_sla_us:           500
cfg_latency_warn_us:          300

# [FIXED C7] HSM
cfg_hsm_budget_us:            5        # Ed25519; was 50 for ECDSA P-256 (now switched)
cfg_hsm_max_us:               200      # p99 hard limit; alert if exceeded

# Drift detection
cfg_psi_retrain_threshold:    0.2
cfg_adwin_delta:              0.002
cfg_drift_threshold_window_days: 7     # rolling window for energy drift threshold [FIXED Mi1]
cfg_psi_adaptive_percentile:  95       # adaptive threshold band (rolling 7d)

# Surrogate tree
cfg_surrogate_depth:          6
cfg_surrogate_min_leaf:       100
cfg_surrogate_agreement_min:  0.85
cfg_surrogate_approx_warn_pct: 15.0   # [FIXED M11]
cfg_surrogate_approx_crit_pct: 25.0
cfg_explain_ood_warn_pct:     5.0
cfg_explain_ood_crit_pct:     10.0

# Capital limits
cfg_max_capital_pct:          0.50
cfg_daily_loss_limit_pct:     0.02
cfg_drawdown_limit_pct:       0.05
cfg_single_trade_loss_pct:    0.01

# Re-entry cool-down  [FIXED M5]
cfg_reentry_cooldown_minutes:    30
cfg_reentry_paper_trade_minutes: 60
cfg_killswitch_cancel_global_timeout_ms: 5000

# Order ID scheme  [FIXED M3]
cfg_node_id_ny4:              0x00
cfg_node_id_sg1:              0x01
cfg_order_id_persist_path:    "/var/predator/order_id_counter.bin"
cfg_order_id_safety_gap:      10000   # added to counter on restart

# Rate limiter  [FIXED Mi9, Mi10, M2]
cfg_rate_limit_max_weight:    1200    # Binance: 1200 weight/minute
cfg_rate_limit_window_sec:    60
cfg_rate_limit_warn_pct:      0.80

# Data retention
cfg_retention_ticks_days:     30
cfg_retention_decisions_years: 5       # MiFID II minimum; was 7 (reduced per cost-opt)
cfg_retention_orders_years:   5       # MiFID II minimum; was 7 (reduced per cost-opt)
cfg_retention_models_years:   999

# Gap token
cfg_gap_spread_max_age_ms:    60000   # [FIXED M9] stale spread threshold

# Timing
cfg_api_rotation_utc_hour:    2
cfg_surrogate_retrain_utc_h:  6
cfg_psi_check_interval_hours: 1
cfg_var_update_interval_sec:  10

# Reproducibility hardening
cfg_repro_allow_tf32:         false

# Instruments
cfg_symbols:
  - BTCUSDT
  - ETHUSDT
  - SOLUSDT
  - XAUUSD

cfg_exchanges:
  primary:   binance
  backup:    okx
  trad:      interactive_brokers
```


#### Intelligence Layer Configuration Parameters (v1.2)

```yaml
# ─────────────────────────────────────────────────────────────────
# INTELLIGENCE LAYER CONFIGURATION (PREDATOR v1.2 additions)
# ─────────────────────────────────────────────────────────────────

# ── Section 5A: ARGOS Whale Intelligence ─────────────────────────
cfg_argos_update_interval_s:          30
cfg_argos_min_agents_active:          2        # Min agents above 40/100 to publish score
cfg_argos_whale_threshold:            0.70     # Score above this → action modifier
cfg_argos_noise_gate:                 40       # Per-agent score below this = noise
cfg_argos_score_weights:              [0.35, 0.30, 0.20, 0.15]  # [consol, flow, OTC, hedge]
cfg_argos_data_stale_threshold_s:     120      # Slot zeroed if source older than this
cfg_nansen_api_key_hsm_slot:          10       # HSM partition slot for Nansen API key
cfg_arkham_api_key_hsm_slot:          11       # HSM partition slot for Arkham API key
cfg_consolidation_btc_threshold:      500.0    # BTC (whale-grade consolidation)
cfg_consolidation_eth_threshold:      5000.0   # ETH
cfg_argos_whale_type_retrain_day:     0        # Monday weekly retrain (Agent-6 classifier)
cfg_argos_whale_type_retrain_utc_h:   3        # 03:00 UTC

# ── Section 5A: Wallet Clustering ────────────────────────────────
cfg_clustering_refresh_interval_h:    6
cfg_clustering_min_cluster_btc:       100.0    # Minimum cluster size to track

# ── Section 5A: Coinbase Analyser ────────────────────────────────
cfg_coinbase_anomaly_tx_threshold_btc: 1000.0  # Tx > this bypassing mempool = anomaly

# ── Section 5B: Mempool Intelligence ────────────────────────────
cfg_mempool_update_interval_ms:       500
cfg_mempool_large_tx_usd:             10_000_000.0   # $10M notional threshold
cfg_mempool_fee_p1_sat_vbyte:         2.0            # 1st percentile (calibrated annually)
cfg_mempool_fee_p99_sat_vbyte:        300.0          # 99th percentile
cfg_mempool_congestion_ewma_tau_s:    30.0
cfg_btc_node_zmq_endpoint:            "tcp://mgmt-server:28332"
cfg_eth_node_ws_endpoint:             "ws://mgmt-server:8546"

# ── Section 5C: Microstructure ───────────────────────────────────
cfg_iceberg_refill_threshold:         0.80     # Order refills to ≥80% = iceberg
cfg_iceberg_min_fill_count:           3        # Seen refilling ≥3 times
cfg_iceberg_price_window_bps:         5.0
cfg_iceberg_lookback_s:               300.0
cfg_smart_money_normalizer_usd:       50_000_000.0   # $50M = tanh ≈ 1.0
cfg_smart_money_update_interval_s:    60
cfg_dark_pool_update_interval_s:      60
cfg_kaiko_api_key_hsm_slot:           12

# ── Section 5D: Derivatives ──────────────────────────────────────
cfg_deribit_poll_interval_s:          30
cfg_coinglass_poll_interval_s:        30
cfg_options_skew_z_alert:             2.0      # Put-call skew z-score above this = alert
cfg_options_oi_change_1h_threshold:   0.20     # 20% OI change = institutional entry
cfg_cascade_threshold_usd:            100_000_000.0   # $100M liquidations in 1h
cfg_cascade_proximity_bps:            100.0    # Price within 100bps of $50M+ liq cluster
cfg_funding_regime_1_threshold:       0.0005   # 0.05% per 8h = LONGS_CROWDED
cfg_funding_regime_3_threshold:       0.0010   # 0.10% per 8h = EXTREME_CROWDING
cfg_coinglass_api_key_hsm_slot:       13
cfg_deribit_api_key_hsm_slot:         14

# ── Section 5E: ICC ──────────────────────────────────────────────
cfg_icv_dimensions:                   32
cfg_icv_stale_threshold_ms:           120_000  # 120 seconds
cfg_icv_update_interval_ms:           100      # Kelly Multiplier reads ICV every 100ms
cfg_intel_redis_host:                 "mgmt-server"
cfg_intel_redis_port:                 6380     # Separate Redis from hot-path Redis
cfg_intel_redis_ttl_s:                120

# ── Kelly Multiplier ─────────────────────────────────────────────
cfg_kelly_intel_mult_max_phase1:      1.00     # Phase 1: neutral (observe only)
cfg_kelly_intel_mult_min_phase1:      1.00
cfg_kelly_intel_mult_max_phase2:      1.25     # Phase 2: 50% strength
cfg_kelly_intel_mult_min_phase2:      0.75
cfg_kelly_intel_mult_max_phase3:      1.50     # Phase 3: full strength
cfg_kelly_intel_mult_min_phase3:      0.50
cfg_kelly_intel_mult_whale_threshold: 0.70
cfg_kelly_intel_mult_iceberg_threshold: 0.60
cfg_kelly_intel_mult_cascade_threshold: 0.60
cfg_kelly_intel_mult_skew_threshold:  2.0
cfg_kelly_intel_mult_congestion_threshold: 0.80

# ── Risk Threshold Adjustment ─────────────────────────────────────
cfg_risk_cascade_gross_multiplier:    0.70     # Reduce gross exposure by 30% on cascade
cfg_risk_cascade_var_multiplier:      0.80     # Tighten VaR by 20% on cascade
cfg_risk_darkpool_gross_multiplier:   0.90
cfg_risk_congestion_gross_multiplier: 0.90
cfg_risk_intel_gross_min:             0.20     # Intelligence can never reduce below 20%
cfg_risk_intel_var_min:               0.02     # Intelligence can never reduce below 2%

# ── Section 17A: Network Defense ─────────────────────────────────
cfg_p2p_anomaly_alert_threshold:      0.70
cfg_p2p_anomaly_critical_threshold:   0.90
cfg_peer_diversity_min_asns:          10
cfg_peer_diversity_alert_threshold:   0.30     # < 30 % diversity = alert
cfg_block_prop_delay_alert_z:         3.0      # Z-score > 3 vs. 30d baseline = alert
cfg_observer_node_btc_datadir:        "/data/btc-observer"
cfg_observer_node_eth_datadir:        "/data/eth-observer"
cfg_network_health_table:             "network_health"
cfg_network_anomaly_page_threshold:   0.80     # Page SecEng-1 above this

# ── Data Retention (new tables) ──────────────────────────────────
cfg_retention_intelligence_context_days: 2       # Post-mortem only; was 7 (cost-opt)
cfg_retention_whale_events_years:     5      # MiFID II aligned; was 7 (cost-opt)
cfg_retention_mempool_events_days:    90
cfg_retention_network_health_years:   1
```

---



### Appendix C — Contact Matrix

| Component | Primary Owner | Backup | Escalation L1 | Escalation L2 |
|---|---|---|---|---|
| Ingestion & Network | SRE-1 | SRE-2 | Platform Lead | CTO |
| ML Models | ML-Eng-1 | ML-Eng-2 | ML Lead | Head of Research |
| Risk & Execution | Quant-1 | Quant-2 | CRO | CEO |
| Compliance | Compliance-1 | Legal-1 | General Counsel | Board |
| Security | SecEng-1 | SRE-1 | CISO | CEO |
| Exchange Relations | Trading-Ops | Quant-1 | CRO | CEO |

Emergency contact sheet: printed + posted in trading room and server room; updated quarterly.

### Appendix D — Paper References (All Real, All Cited)

| Model | Citation | ArXiv |
|---|---|---|
| Mamba-2 | Dao & Gu (2024), "Transformers are SSMs: Generalized Models and Efficient Algorithms Through Structured State Space Duality" | 2405.21060 |
| CoPE | Olsson et al. (2024), "Contextual Position Encoding: Learning to Count What's Important" | 2405.18719 |
| **[FIXED Mi5] HGRN-2** | **Qin et al. (2023), "Hierarchically Gated Recurrent Neural Network for Sequence Modeling"** | **2311.04823** |
| Neural SDE | Li et al. (2020), "Scalable Gradients for Stochastic Differential Equations" | 2002.14028 |
| TD-MPC2 | Hansen et al. (2023), "TD-MPC2: Scalable, Robust World Models for Continuous Control" | 2310.16828 |
| NSR (Diffusion) | d'Ascoli et al. (2023), "BFGS on the Symbolic Regression Landscape" | 2310.02227 |
| Störmer-Verlet | Verlet (1967), "Computer 'Experiments' on Classical Fluids" | Physical Review 159(1):98 |
| Sample Entropy | Richman & Moorman (2000), "Physiological time-series analysis using approximate entropy and sample entropy" | Am J Physiol Heart Circ Physiol 278(6) |
| Block Bootstrap | Politis & Romano (1994), "The Stationary Bootstrap" | JASA 89(428) |

### Appendix E — Architecture Decision Records (ADRs)

| ADR | Decision | Rationale |
|---|---|---|
| ADR-001 | Neural SDE instead of SymODEN | Markets are dissipative; Hamiltonian conservation violated |
| ADR-002 | Solarflare OpenOnload only (no DPDK) | DPDK incompatible with Thales Luna; OpenOnload tested |
| ADR-003 | Fixed-step Störmer-Verlet (not adaptive RK4) | Adaptive RK4 has unbounded step count |
| ADR-004 | Sample Entropy on PCA-reduced vector | Lyapunov unreliable < 2000 points; single-dim entropy is arbitrary |
| ADR-005 | On-prem Thales Luna (not AWS CloudHSM) | Cloud HSM adds 2–10ms; incompatible with 500μs SLA |
| ADR-006 | YubiKey TOTP software kill switch | USB dongle is physical SPOF |
| ADR-007 | Rust audit logger + Kafka | Python GIL causes blocking |
| ADR-008 | 7-year data retention | 2-year buffer over MiFID II 5-year minimum |
| ADR-009 | Freeze Mamba-2 + Neural SDE during actor fine-tuning | Prevents catastrophic forgetting |
| ADR-010 | PSI + ADWIN dual drift detection | Complementary: distribution shift + error stream |
| ADR-011 | Deterministic SDE in live inference (σ=0) | Same input → reproducible decision → auditable |
| ADR-012 | Analytical gradient network for ∇U(q) | Autograd 20× per decision = latency violation |
| ADR-013 | Stationary block bootstrap for A/B testing | IID bootstrap invalid for autocorrelated time series |
| ADR-014 | 64-bit monotonic order IDs (not UUID) | Monotonicity required for crash-safe restart and drop-copy matching |
| ADR-015 | In-place GPU weight overwrite (never free) | Prevents memory fragmentation on champion promotion |
| ADR-016 | All hot-path risk/OMS logic in Rust | Python GIL + interpreter overhead violates latency SLA |

---

*End of Document — PREDATOR 2026 Unified Master Engineering Plan*

*Document version: 1.2A | Git tag: `v1.2A-master-plan` | SHA-256: [computed at release]*

*This document is the single source of truth. v1.2A supersedes v1.2, v1.1, and the Intelligence Addendum (v1.2).*
*All prior documents (v1.0, v1.1, PRED-2026-INTELLIGENCE-v1.2) are superseded by this document.*
*Review cycle: 90 days or on any Critical finding — whichever comes first.*
*Next scheduled review: 2026-07-08*
