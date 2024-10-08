# BOLDLagMapping

Please visit:
[https://github.com/aso-toshihiko/BOLDLagMapping_Deperfusioning](https://github.com/aso-toshihiko/BOLDLagMapping_Deperfusioning/releases/tag/rev8hcp)

For HCP-style fMRI data, use [BOLDLagMapping_Deperfusioning for HCP-style data](https://github.com/aso-toshihiko/BOLDLagMapping_Deperfusioning/releases/tag/rev8hcp)

contact: Toshihiko ASO aso.toshihiko@gmail.com / https://www.researchgate.net/profile/Toshihiko_Aso

Extraction and removal of the time-lag structure within 4D blood oxygenation level dependent (BOLD) signal MRI data

![lagmaps](https://github.com/RIKEN-BCIL/BOLDLagMapping/blob/master/LagMaps.jpg)
![lagmap_anim](https://github.com/RIKEN-BCIL/BOLDLagMapping/blob/master/lagmap_anim.gif)
![sLFO_anim](https://github.com/RIKEN-BCIL/BOLDLagMapping/blob/master/Lag_model_anim100.gif)

![smoothnoisestructure](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Hybrid_image_decomposition.jpg/256px-Hybrid_image_decomposition.jpg)

#### - BOLD deperfusioning is extracting Einstein (local neurovascular coupling) by removing smooth Marilyn Monroe (perfusion structure) from this image, so that the fMRI result becomes sharp and precise. 

### Dependencies
For Linux/Mac (Not tested on Mac anymore). MATLAB scripts call [FSL][] commands and [SPM12] functions. 
Install FSL & MATLAB then evoke MATLAB from the shell.

(fslmaths in FSL6 may cause errors with the option "-subsamp2offc".)

[FSL]: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki "FSL"
[SPM12]: https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

### Usage

**NEW!** HCP-style pipeline **Einsteining_v01.m** (Einsteining version 0.1) released
with
**drLag4Drev4_hcp.m** for tracking and **drDeperf_hcp_seed.m** for deperfusioning.

- **Einsteining** is a hard working process to remove the perfusion lag structure, a major component of physiological noise for fMRI. 
- Application **before** ICA-FIX is recommended (see Aso & Hayashi, ISMRM2022)
- Modify "Fdir" to point to your **FSL5** installation.

-~-~-~-~-~-~-~-~-~-~

Original version:

**drLag4D.m** for tracking and **drDeperf.m** for deperfusioning.


#### dir = drLag4D( name, TR, vols, PosiMax, THR, FIXED, range) ####

- A result directory will be created in the current directory
- Images are expected to have been slice-timing corrected, realigned, and spatially normalized to the MNI space. This normalization is required solely for masking out non-cerebral tissues when extracting the global signal. On computers with RAM < 16GB, reslice the images to 4 mm voxel size to safely run the script. The longer you scan, the better (>10 min). Avoid fast and large head motion that creates signal deflection.
- *NOTE THAT THE SMOOTHING DOES NOT AFFECT THE SMOOTHNESS OF THE fMRI DATA AFTER DEPERFUSIONING.* Spatial smoothing by 8 mm FWHM is applied in the script, under the assumption of smooth perfusion lag structure (in comparison to the neuronal activity confined to the gray matter; See Stelzer, 2014, Front Hum Neurosci). This parameter is subject to change if you assume otherwise, but can result in removal of neurovascular coupling during the "deperfusioning" treatment based on this procedure (Aso 2019; Erdoğan 2016 Front Human Neurosci).

- Options

	name: String to be added to the result directory name (dir)

	TR: Repetition time in second.

	vols: Specify single 4D BOLD data file to process.

	PosiMax: Determines tracking range -PosiMax - +PosiMax. 

		Note this parameter affects the bandpass filter. 

	THR: Minimum height of the valid cross-correlogram peak for lag mapping

	FIXED: Specify tracking method. 
	
		0 = recursive tracking, nonzero = fixed seed tracking

	range: Range of the fourth dimension (time) of the 4D data to be used.

		ex. 1:500 - use first 500 volumes

		ex. 1:2:500 - "decimate" to see the effect of sampling rate (see Aso 2017; double the TR for this)


#### drDeperf( vols, Lag, TR, reso, range) ####

	vols: fMRI 4D file. Can be relative path assuming lag map folder is in the same folder.

	Lag: Full path to the lag map. Typically
		'/XXX/XXX/Lag_XXs_thrX_XX/LagMap.nii'. In case you had downsampled the
		fMRI data to say 4 mm voxel size from 2 mm for example,  
		for quick and safe lag mapping, 
		the map must be upsampled (= resliced to the original space) beforehand. 
		If it was done on SPM, it would be like: '/XXX/XXX/Lag_XXs_thrX_XX/rLagMap.nii'

	TR: Repetition time in second.

	Below are non-compulsory options
	
	reso: Lag resolution in second (set to 1 by default)

	range: Specify fourth dimension (time) of the Seeds.mat data to be
		used. This is only necessary when lag map was created using
		concatenated runs, but the deperfusioning must be done for each
		run. Causes	error or unfavorable phase shift depending on the combination of TR and reso.

### References

Recursive tracking

[Aso, T., Urayama, S., Hidenao, F., & Murai, T. (2019). Axial variation of deoxyhemoglobin density as a source of the low-frequency time lag structure in blood oxygenation level-dependent signals. PLoS ONE.](https://doi.org/10.1371/journal.pone.0222787) [(Correction here)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0225489)

[Nishida, S., Aso, T., Takaya, S., Takahashi, Y., Kikuchi, T., Funaki, T., … Miyamoto, S. (2018). Resting-state Functional Magnetic Resonance Imaging Identifies Cerebrovascular Reactivity Impairment in Patients With Arterial Occlusive Diseases: A Pilot Study. Neurosurgery, 85(5), 680-688.](https://doi.org/10.1093/neuros/nyy434)

[Aso, T., Jiang, G., Urayama, S. I., & Fukuyama, H. (2017). A resilient, non-neuronal source of the spatiotemporal lag structure detected by bold signal-based blood flow tracking. Frontiers in Neuroscience, 11(MAY), 1-13.](https://doi.org/10.3389/fnins.2017.00256)

Fixed-seed tracking

[Aso, T., Sugihara, G., Murai, T., Ubukata, S., Urayama, S., Ueno, T., Fujimoto, G., Thuy, D., Fukuyama, H., & Ueda, K. (2020). A venous mechanism of ventriculomegaly shared between traumatic brain injury and normal ageing. Brain, 143(JUN)](https://doi.org/10.1093/brain/awaa125)

[Satow, T., Aso, T., Nishida, S., Komuro, T., Ueno, T., Oishi, N., … Fukuyama, H. (2017). Alteration of venous drainage route in idiopathic normal pressure hydrocephalus and normal aging. Frontiers in Aging Neuroscience, 9(NOV), 1–10.](https://doi.org/10.3389/fnagi.2017.00387)


