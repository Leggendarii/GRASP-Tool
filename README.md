# Systematic Gray-Box Identification Methodology for Voltage Source Converters

This repository accompanies the paper **“Systematic Gray-Box Identification Methodology for Voltage Source Converters”** and provides supporting material for the proposed gray-box identification framework for voltage source converter (VSC) models.

The goal of the project is to build a physically meaningful surrogate model from terminal measurements only, so that the identified model can reproduce the behavior of an EMT black-box model while remaining suitable for small-signal stability studies, interoperability analysis, and frequency-domain validation.

## Overview

The proposed methodology combines:

- a physically informed white-box model;
- iterative calibration in the time domain;
- frequency-domain validation;
- error metrics based on Nyquist analysis, singular value decomposition, and CMIF.

This approach is intended for cases where the internal structure of the converter is not fully accessible, for example because of intellectual property constraints or limited model transparency.

## Repository Purpose

This repository is organized to support:

- documentation of the methodology;
- reproducibility of the paper’s results;
- implementation of the identification workflow;
- validation of gray-box surrogate models;
- future extensions to new converter structures and test cases.

## Repository Structure

```text
.
├── README.md
├── CITATION.cff
├── LICENSE
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CHANGELOG.md
├── docs/
├── citation/
├── examples/
└── src/
```

### `docs/`
Contains supporting documentation, including:

- project description;
- repository roadmap;
- paper summary.

### `citation/`
Contains citation metadata, including:

- BibTeX reference for the paper;
- software citation metadata.

### `examples/`
Contains example templates and configuration files for test cases.

### `src/`
Contains the source code for the methodology, including:

- identification routines;
- parameter calibration;
- frequency-domain validation;
- plotting and post-processing scripts.

## Methodology

The workflow implemented in this project follows these steps:

1. Define the test grid and the measurable terminal variables.
2. Generate or collect time-series data from the black-box model.
3. Select the gray-box structure and its free parameters.
4. Perform iterative optimization in the time domain.
5. Compare the black-box and gray-box models in the frequency domain.
6. Assess model fidelity using divergence and consistency metrics.

## Expected Outcomes

The methodology shows that:

- when the internal structure is known, parameter recovery can be highly accurate;
- when the structure is only partially correct, the gray-box model can still provide a useful approximation;
- when the black-box model is much more complex, frequency-domain divergence can be quantified and used to assess confidence in the surrogate model.

## Requirements

The final implementation may require:

- MATLAB or Python for identification routines;
- EMT simulation tools;
- frequency-domain analysis tools;
- numerical optimization and plotting libraries.

## How to Use

After cloning the repository:

```bash
git clone <repository-url>
cd <repository-name>
```

Then consult the documentation in `docs/` and the examples in `examples/` to configure the test cases and reproduce the results.

## How to Cite

If you use this repository, please cite the associated paper using the metadata provided in `CITATION.cff` or `citation/paper.bib`.

## License

The code and documentation are released under the license specified in `LICENSE`.

## Contact

For scientific questions related to the paper, please contact the authors of the work.
