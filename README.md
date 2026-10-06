# cystometry_matlabscripts
MATLAB scripts used to analyze cystometry time series data collected from anesthetized mice

## Table of Contents
- [Analysis Pipeline Workflow](#workflow)
- [System Requirements & Installation](#install)
- [Usage Guide](#usage)
- [Known Issues & Bugs](#issues-bugs)
- [Authors, Acknowledgements, & Contact Information](#authors)
- [License](#license)

## Analysis Pipeline Workflow <a name="workflow"></a>
The custom cystometry analysis scripts 1-4 work in series to isolate pressure peak events during micturition cycles recorded using the AcqKnowledge software (v4.4.2, BIOPAC). Users have precise control over which micturition cycles and which peak events are analyzed in depending on how the time series data are indexed via the MATLAB scripts. Please refer to the workflow diagram for a visual summary.

<p align="center">
     <img width="1120" height="630" alt="Workflow_Diagram" src="Cystometry_Pipeline_Workflow.png" />
</p>

## System Requirements & Installation<a name="install"></a>
- The code was written and tested on a Windows 11 64-bit OS laptop running MATLAB v.2019B/2025B with 32 GB of RAM, AMD Ryzen 7 5800H 8 core CPU, and NVIDIA GeForce RTX 3070 GPU with 8 GB of VRAM
- Required MATLAB Products/Packages: Signal Processing Toolbox
- Follow standard MATLAB program installation instructions, install the Signal Processing Toolbox, and place the cystometry analysis scripts 1-4 in your root folder of choice

## Usage Guide <a name="usage"></a>
Before you begin, make sure to adjust any global variables to best fit your data parameters (e.g., SampleRate). These variables can be found within the first 30 lines of each script. Also, make sure to update the path variable and filetype filters in each script to match your folder destination of choice.
- Script 1: Lines 8 and 20
- Script 2: Lines 7 and 18
- Script 3: Lines 7, 20, and 27
- Script 4: Lines 7 and 33

### Script 1
1. Load the MATLAB-converted AcqkKnowledge data (.mat filetype)
   - Assumes pressure time series data are stored in column 1 (see line 37)
   - Assumes corresponding electromyography time series data are stored in column 2 (see line 38)
3. You will be presented with the pressure time series, but inverted, to facilitate isolating local micturition cycle minima
   - Select the pressure threshold used to detect local micturition cycle minima (enter a negative pressure value)
   - Select the minimal time interval between local micturition cycle minima (enter a time in seconds)
   - Select the minimum pressure amplitude for local micturition cycle minima (enter a positive pressure value)
4. You will be shown the results of MATLAB's findpeaks function
   - Select 1 to accept (proceed to step 4)
   - Select 0 to not accept (step 2 will repeat)
5. You will be presented with the pressure time series to facilitate isolating peak pressure events
   - Select the pressure threshold used to detect peak pressure events (enter a positive pressure value)
   - Select the minimal time interval between peak pressure events (enter a time in seconds)
   - Select the minimum pressure amplitude for peak pressure events (enter a positive pressure value)
6. You will be shown the results of MATLAB's findpeaks function
   - Select 1 to accept (proceed to step 6)
   - Select 0 to not accept (step 4 will repeat)
7. Script will run to completion

### Script 2

### Script 3

### Script 4


## Known Issues & Bugs <a name="issues-bugs"></a>
- **PLACEHOLDER BULLET LIST**
- **PLACEHOLDER BULLET LIST**

## Authors, Acknowledgements, & Contact Information <a name="authors"></a>
The cystometry analysis scripts were written by Max Odem; legacy version of script 1 was written by Jason Keller, Kara Marshall, and Max Odem. All source code, documentation, and assets in this repository were created manually. No generative artificial intelligence tools were used to design, write, modify, or debug the code.

This work was made possible through the following funding sources:
- Howard Hughes Medical Institute Freeman Hrabowski Scholars Program (KLM)
- National Institutes of Health R00DK128621 (KLM) and R01DK142807-01 (KLM)
- McNair Medical Foundation (KLM)
- Pew Charitable Trusts (KLM)
- Rita Allen Foundation (KLM)

For technical support please contact [Max (BCM)](mailto:max.odem@bcm.edu)/[Max (private)](mailto:max.neuro.odem@gmail.com). For all other inquires please contact [Kara Marshall (BCM)](mailto:kara.marshall@bcm.edu).

## License <a name="license"></a>
Copyright 2026 Baylor College of Medicine

The cystometry analysis code is licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
