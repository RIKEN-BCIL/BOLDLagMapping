function drDeperf( vols, Lag, TR, reso, range) 
% Removing BOLD perfusion structure by Toshihiko Aso
%	
%
%	function dir = drDeperf(  vols, Lag, TR, reso, range)
% 
%
%	vols: fMRI 4D file. Can be relative path assuming lag map folder is in the same folder.
%
%	Lag: Full path to the lag map. Typically
%	'/XXX/XXX/Lag_XXs_thrX_XX/LagMap.nii'. In case you had downsampled the
%	fMRI data to say 4 mm voxel size from 2 mm for example,  
%	for quick and safe lag mapping, 
%	the map must be upsampled (= resliced to the original space) beforehand. 
%	If it was done on SPM, it would be like: '/XXX/XXX/Lag_XXs_thrX_XX/rLagMap.nii'
%
%	TR: Repetition time in second.
%
%	Below are non-compulsory options
%	
%	reso: Lag resolution in second (set to 1 by default)
%
%	range: Specify fourth dimension (time) of the Seeds.mat data to be
%		used. This is only necessary when lag map was created using
%		concatenated runs, but the deperfusioning must be done for each
%		run. Causes	error or unfavorable phase shift depending on the combination of TR and reso.

setenv('FSLOUTPUTTYPE', 'NIFTI_GZ')
if exist( 'out.nii', 'file')
	!rm out.nii
end
cd( fileparts( Lag))

V = spm_vol( Lag);
Lag = spm_read_vols( V);
Lag = round( Lag/reso)*reso;

load Seeds.mat
MaxLag =  ( size( Seeds, 2)-1)*reso /2;

if nargin>4
	Seeds = Seeds( range, :);
end

if nargin<4
	reso = 1;
end


Motodata = [];
L = -MaxLag;
LL = ( -MaxLag:reso:MaxLag)/reso;
for p = 1:size( LL,2)
	temp = Seeds( :,1+size( Seeds, 2)-p);
	Motodata = [ Motodata [ zeros( MaxLag/reso,1); ...
		temp( MaxLag/reso+1+LL(p):end+LL(p)-MaxLag/reso); zeros( MaxLag/reso,1)]];
	L = [ L; max( L)+reso];
end

cd ..

% - - - - - - - - - - - - - - - - - - - - - - - - - 

V.fname = 'MaskDeperf.nii';
disp('Cleaning images...')


	for p =  1: size( Seeds, 2) % -4:.5:4
%		L = LL( p)/2;
		Mask = (Lag==L( p));
	
		if ~isempty( find( Mask(:)))
			spm_write_vol( V, Mask);
			
			Reg = resample(  Motodata( 1:end-1, p), reso*100,TR*100);
			save Reg.txt Reg -ascii
					
			S = system([ 'fsl_regfilt --in=' vols ...
				' --out=regout.nii --design=Reg.txt -f "1"' ]);
			if S, save all.mat, error, end
		
			S = system( [ 'fslmaths regout -mas MaskDeperf.nii rmasked' num2str( p)]); if S, error, end

		end
	end
disp('Merging images...')
	for p =  1: size( Seeds, 2)
		if exist( ['rmasked' num2str( p) '.nii.gz'], 'file')
			if exist( 'out.nii.gz', 'file')
				S = system( [ 'fslmaths out.nii -add rmasked' num2str( p) '.nii.gz out.nii.gz']); if S, error, end
			else
				S = system([ 'mv rmasked' num2str( p) '.nii.gz out.nii.gz']); if S, error, end
			end
		end
	end
newvols = drInsert( vols, 'dep_')

if system( [ 'mv out.nii.gz ' newvols '.gz']), error, end

!rm rmasked*
!rm regout.nii*

function out=drInsert( in, opt)

out = [];
for p=1:size(in,1)
	[P N E] = fileparts( in(p,:));
	if length( P)>0
		out = [ out; [ P '/' opt N E]];
	else
		out = [ out; [ opt N E]];
	end
		
end
