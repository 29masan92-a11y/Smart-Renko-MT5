# Smart-Renko-MT5

Smart Renko for MT5 is a modular, pluggable, restart-safe Expert Advisor framework focused on Renko continuation trading, basket lifecycle orchestration, and shared-core deployment for both desktop EA and VPS EA.

## Project Structure

```
SmartRenkoMT5/
├── SmartRenko.mq5                  # EA entry point (thin orchestration shell)
└── Core/
    ├── Types.mqh                   # Enums, structs, and shared type definitions
    ├── Interfaces.mqh              # Pure abstract interfaces for all modules
    ├── CoreModules.mqh             # Interface declarations + CoreOrchestrator
    └── ModuleImplementations.mqh   # Concrete placeholder implementations
```

## Module Overview

| Module | Role |
|--------|------|
| **CoreOrchestrator** | Top-level lifecycle and event routing |
| **IRenkoDataProvider** | Renko brick abstraction (swappable source) |
| **IEntryStrategy** | Pluggable entry signal generation |
| **IExitStrategy** | Pluggable exit/close recommendations |
| **ISignalManager** | Aggregates and normalizes signals |
| **IBasketManager** | Basket lifecycle and state transitions |
| **IPositionManager** | Position tracking per basket |
| **IRiskManager** | Pre-execution risk validation |
| **IMoneyManager** | Lot sizing policies |
| **ITrailingManager** | Basket-wide trailing stop logic |
| **IExecutionAdapter** | Single broker-facing adapter layer |
| **IPersistenceLayer** | Restart-safe state serialization |
| **INotificationManager** | Alerts and notifications |
| **IReportingEngine** | HTML, CSV, JSON export |
| **IGuiLayer** | Display-only UI layer |
| **IPresetProfileManager** | Named profiles and import/export |
| **IVpsRunner** | Lightweight VPS shell |

## Phase Status

- **Phase 1: Architecture Skeleton** — In Progress

## Constraints

- No direct trading outside `IExecutionAdapter`.
- No strategy logic in `IGuiLayer`.
- No broker calls from strategy modules.
- All modules are header-only (`.mqh`) with the EA as the sole `.mq5` entry point.
