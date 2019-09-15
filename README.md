# BOLDLagMapping

## Extraction of the time-lag structure within 4D blood oxygenation level dependent (BOLD) signal MRI data

### Dependencies
MATLAB scripts call [FSL][] commands

[FSL]: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki "FSL"

### Usage
function dir = drLag4D( name, TR, vols, PosiMax, THR, FIX, range)
name: string to be added to the result folder name
TR: repetition time in second
vols: specify single 4D BOLD data file to process
PosiMax: determines tracking range. Note this parameter affects the bandpass filter.
THR: minimum height of the valid cross-correlogram peak for lag mapping
FIX: Specify tracking method; 0 = recursive tracking, nonzero = fixed seed tracking
range: range of the fourth dimension (time) of the 4D data to be used

