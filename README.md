# Graybox Analysis Toolkit - Script Flow Documentation

## Overview

This toolkit provides a comprehensive workflow for **parameter optimization** and **frequency-domain stability analysis** of grid-connected converters (Voltage Source Converters - VSCs). The analysis pipeline consists of three main scripts that work sequentially to optimize controller gains and assess system stability.

---

## Script Execution Flow

```
┌──────────────────────────┐
│ main_optimization.m      │  ← START: Parameter Optimization
│ (Time-Domain Analysis)   │
└────────────┬─────────────┘
             │
             ↓
┌──────────────────────────┐
│ main_scan_FD.m           │  ← Frequency-Domain Scanning
│ (Admittance Extraction)  │
└────────────┬─────────────┘
             │
             ↓
┌──────────────────────────┐
│ main_SVD.m               │  ← Stability Assessment
│ (Bode, Nyquist, SVD)     │
└──────────────────────────┘
```

---

## 1. Main Optimization (`main_optimization.m`)

### Purpose
Optimize 12 controller parameters to match a reference black-box system behavior in the time domain.

### Key Parameters Optimized
- **Outer Voltage Control**: `kp_outer_V_pu`, `ki_outer_V_pu`
- **Outer Power Control**: `kp_outer_P_pu`, `ki_outer_P_pu`
- **Inner Current Control (d-axis)**: `kp_inner_d_pu`, `ki_inner_d_pu`
- **Inner Current Control (q-axis)**: `kp_inner_q_pu`, `ki_inner_q_pu`
- **Phase-Locked Loop (PLL)**: `kp_pll`, `ki_pll`
- **Filter Time Constants**: `T1`, `T2`

### Workflow Steps

1. **Setup**: Load the white-box Simulink model (`white_box.slx`)
2. **Define Bounds**: Set lower and upper bounds for each parameter
   - Lower bounds (lb): Conservative minimum values
   - Upper bounds (ub): Exploration space limits
   - Initial guess (x0): Starting point for optimization
3. **Scale Parameters**: Normalize all parameters to [0, 1] for numerical stability
4. **Optimization**: Use FMINCON (interior-point algorithm)
   - Runs Simulink simulations iteratively
   - Computes cost function comparing simulation output with reference case
   - Adjusts parameters to minimize cost
   - 100,000 maximum function evaluations allowed
5. **Output**: 
   - Optimized parameter set
   - Final objective value
   - Updated Simulink workspace variables

### Configuration Options
- **Algorithm**: Interior-point (Trust-region based)
- **Display**: Detailed iteration-by-iteration output
- **Tolerances**: Relaxed (1e-3) for robust exploration
- **Finite Difference Step Size**: 1e-2 for gradient computation

### Expected Outputs
- Optimal parameter values in command window
- Time-domain comparison plots (optimized vs. reference)
- CSV file: `resultant_case.csv` (optimized response)

---

## 2. Frequency-Domain Scanning (`main_scan_FD.m`)

### Purpose
Perform frequency-domain analysis of the controller to extract admittance characteristics across a frequency range.

### Theoretical Background
- **Admittance Matrix (Y)**: Describes the converter's current response to voltage perturbations
- **dq-Frame**: Rotating reference frame synchronized with grid voltage
  - d-axis: aligned with voltage
  - q-axis: 90° behind voltage
- **Matrix Elements**: Y_dd, Y_dq, Y_qd, Y_qq describe coupling between axes

### Workflow Steps

1. **Initialize**: Load grey-box model parameters and simulation settings
2. **Define Frequency Points**: 
   - Logarithmic sweep: 100 points from 0 Hz to 600 Hz
   - Better resolution at lower frequencies (relevant for stability)
3. **Set Steady-State Conditions**:
   - Fundamental frequency: f₀ = 50 Hz
   - Base power: S_base = 14 MVA
   - Base voltage: V_base = 0.69 kV
   - Voltage perturbation: 2% of nominal
   - Current perturbation: 3% of nominal
4. **Execute Scanning**: 
   - Run `FDScanning.m` function (lib/Scanning)
   - Injects perturbations at each frequency point
   - Records converter's admittance response
5. **Save Results**: Store frequency-domain data in CSV format
   - Columns: `f, Ydd_c, Ydq_c, Yqd_c, Yqq_c, Ydd_g, Ydq_g, Yqd_g, Yqq_g`
   - Subscripts: `_c` = controller, `_g` = grid

### Key Parameters
| Parameter | Value | Purpose |
|-----------|-------|---------|
| `Tinit` | 5 s | Settling time before measurement |
| `fs` | 1 Hz | Scanner sampling frequency |
| `delta_t` | 10 μs | Simulation time step |
| `V_perturbation` | 0.02 pu | Voltage injection magnitude |
| `I_perturbation` | 0.03 pu | Current injection magnitude |

### Expected Outputs
- CSV file with frequency-domain admittance data
- Can be analyzed in `main_SVD.m`

---

## 3. Stability Analysis using SVD (`main_SVD.m`)

### Purpose
Perform small-signal stability assessment using frequency-domain data through multiple analysis methods.

### Workflow Steps

#### 3.1 Load Measurement Data
- Read two CSV files:
  - `SGRE_scan.csv`: Reference system data (Black case)
  - `grey_scan.csv`: Grey-box or test case data

#### 3.2 Compute Closed-Loop Matrices
- **Function**: `compute()` (lib/Post_Process/compute.m)
- **Outputs**:
  - `E, L`: Closed-loop transfer matrices
  - `Y_c_dq, Y_g_dq`: Controller and grid admittances in dq-frame
  - `Y_c_pn, Y_g_pn`: Controller and grid admittances in positive/negative-sequence frame
- **Note**: Corrects for element ordering differences (dq vs. qd notation)

#### 3.3 Bode Plot Analysis
- **Function**: `bode_plot_full()`
- **Visualization**: Magnitude and phase response of admittance matrices
- **Interpretation**:
  - Reveals resonance frequencies
  - Shows coupling between d and q axes
  - Identifies frequency bands with weak/strong damping

#### 3.4 MIMO Nyquist Analysis
- **Function**: `MIMO_Nyquist()`
- **Purpose**: Assess closed-loop stability using generalized Nyquist criterion
- **Interpretation**:
  - Encirclements of (-1, 0) point indicate instability
  - Distance from (-1, 0) indicates stability margin
  - Multi-input, multi-output analysis captures full 2×2 dynamics

#### 3.5 Singular Value Decomposition (SVD)
- **Function**: `SVD_Calc()`
- **Computation**: For each frequency, computes singular values of closed-loop matrix
  - $$T(j\omega) = (I + L(j\omega))^{-1} L(j\omega)$$
  - Maximum singular value σ_max: Indicates peak response/worst-case gain
  - Minimum singular value σ_min: Indicates minimum response direction
- **Plotting**: 
  - Magnitude vs. frequency (log-log scale)
  - Identifies frequency bands prone to oscillations
  - Compares multiple cases simultaneously

### Key Analysis Outputs

1. **Bode Plots**: Frequency response of individual admittance elements
   - Y_dd (d-to-d coupling)
   - Y_dq (d-to-q coupling)
   - Y_qd (q-to-d coupling)
   - Y_qq (q-to-q coupling)

2. **MIMO Nyquist Diagram**: Closed-loop stability assessment
   - Multiple curves (one per transfer function element)
   - Solid/dashed styles for visual distinction

3. **SVD Magnitude Plot**: 
   - Peak singular value σ_max (upper curve)
   - Minimum singular value σ_min (lower curve)
   - Normalized to ±1 dB reference lines

---

## Data Flow and File Organization

### Input Files
```
data/
├── parameters_original.csv          # Base case parameters
├── reference_case_original.csv      # Reference system response
└── Initial_Conditions/              # IC for simulations
```

### Generated Files
```
data/
├── resultant_case.csv               # Output from main_optimization.m
├── SGRE_scan.csv                    # Output from main_scan_FD.m (Black)
└── grey_scan.csv                    # Output from main_scan_FD.m (Grey)
```

### Simulink Models
```
├── white_box.slx                    # White-box model (for optimization)
├── grey_box.slx                     # Grey-box model (for validation)
└── black_box.slx                    # Reference/benchmark model
```

---

## Library Functions Used

### Conversion Functions (`lib/Conversion/`)
- `read_data.m`: Load CSV parameters and measurement data
- `save_PSCAD_scan.m`: Export results for external software

### Optimization Functions (`lib/Optimization/`)
- `run_simulink_and_compute_cost.m`: Execute simulation and compute error metric
- `scale_bounds.m`: Normalize parameters to [0, 1] range
- `test_and_fix_x0.m`: Validate initial guess feasibility

### Post-Processing Functions (`lib/Post_Process/`)
- `compute.m`: Closed-loop matrix computation from admittance data
- `bode_plot_full.m`: Multi-case Bode plot visualization
- `MIMO_Nyquist.m`: Nyquist diagram for 2×2 MIMO systems
- `SVD_Calc.m`: Singular value computation and plotting
- `visualizza_bene.m`: Apply publication-quality formatting

### Scanning Functions (`lib/Scanning/`)
- `FDScanning.m`: Frequency-domain measurement engine

### Setup Functions (`lib/Setup/`)
- `base_setup.m`: Initialize nominal parameters
- `Parameters_Setup_grey_box.m`: Load grey-box specific parameters
- `base_case_black.m`: Run reference benchmark

---

## Typical Workflow Example

### Step 1: Initial Optimization
```matlab
% Run parameter optimization
main_optimization

% Review output
% - Check if optimal parameters are within expected bounds
% - Compare time-domain response plot
% - Save optimized parameters if satisfied
```

### Step 2: Frequency-Domain Characterization
```matlab
% After optimization, perform frequency scan
% Update 'params_command' in main_scan_FD.m if needed
main_scan_FD

% When prompted: Enter filename → "grey_scan"
% This creates: data/grey_scan.csv
```

### Step 3: Stability Analysis
```matlab
% Analyze frequency-domain results
main_SVD

% Review multiple plots:
% - Bode diagrams: identify resonances
% - Nyquist diagram: verify stability margins
% - SVD plot: assess peak gain and worst-case response
```

---

## Parameter Interpretation Guide

### Control Loop Gains
| Parameter | Control Loop | Role |
|-----------|--------------|------|
| `kp/ki_outer_V_pu` | Voltage Control | Regulates grid-side voltage |
| `kp/ki_outer_P_pu` | Power Control | Tracks active/reactive power |
| `kp/ki_inner_d_pu` | d-axis Current | Direct-axis current tracking |
| `kp/ki_inner_q_pu` | q-axis Current | Quadrature-axis current tracking |
| `kp/ki_pll` | Phase-Locked Loop | Grid synchronization |

### Filter Time Constants
- `T1`: First filter stage (typically 1-10 ms range)
- `T2`: Second filter stage (typically 1-10 ms range)
- Affects bandwidth and phase lag of control loop

---

## Troubleshooting

### Issue: Optimization Diverges or Gets Stuck
- **Solution**: Adjust bounds in `main_optimization.m`
- Relax initial guess: `x0` closer to midpoint of bounds
- Increase `MaxFunctionEvaluations` if budget exhausted

### Issue: Frequency Scan Takes Too Long
- **Solution**: Reduce frequency points in `main_scan_FD.m`
- Change: `fd0 = unique(round(logspace(0,log10(600),50)));` (50 points instead of 100)

### Issue: SVD Plot Shows Unexpected Peaks
- **Solution**: 
  - Check for numerical issues in `compute.m`
  - Verify input CSV data consistency
  - Inspect matrix conditioning (near-singular matrices amplify noise)

---

## References

- **Small-Signal Stability**: IEEE Power & Energy Society standards on grid-connected converter modeling
- **Bode Analysis**: Classical frequency response techniques for control systems
- **MIMO Nyquist**: Generalized stability criterion for multi-input multi-output systems
- **SVD**: Singular Value Decomposition for robust control analysis

---

## Authors & Support
Based on research from the **Centre of Technological Innovation in Static Converters and Drives (CITCEA)** at the Technical University of Catalonia (UPC).

For specific technical questions, refer to the header comments in each script file.
