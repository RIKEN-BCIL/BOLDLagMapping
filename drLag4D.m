function dir = drLag4D( name, TR, vols, PosiMax, THR, FIXED, range)
%
%	Lag mapping of 4D BOLD data by Toshihiko Aso@RIKEN-BDR, Kobe, Japan
%
%	Images are expected to have been slice-timing corrected, realigned, and spatially normalized to the MNI space.Spatial smoothing by 8 mm FWHM is applied in the script, under the assumption of smooth perfusion lag structure (compared to the neuronal activity). This parameter is subject to change if you assume otherwise, but can result in removal of neurovascular coupling during the "deperfusioning" treatment based on this procedure (Aso 2019; Erdogan 2016 Front Human Neurosci).
%
%	function dir = drLag4D( name, TR, vols, PosiMax, THR, FIXED, range)
%	name: String to be added to the result folder name
%	TR: Repetition time in second.
%	vols: Specify single 4D BOLD data file to process.
%	PosiMax: Determines tracking range -PosiMax - +PosiMax 
%			Note this parameter affects the bandpass filter. 
%	THR: Minimum height of the valid cross-correlogram peak for lag mapping
%	FIXED: Specify tracking method. 
%			0 = recursive tracking, nonzero = fixed seed tracking
%	range: Specify fourth dimension (time) of the 4D data to be used.
%			ex. 1:500 - use first 300 volumes
%			ex.	1:2:500 - "decimate" to see the effect of sampling rate (see Aso 2017; don't forget to double the TR!)
%
%	References
%	Aso, T., Jiang, G., Urayama, S. I., & Fukuyama, H. (2017). A resilient, non-neuronal source of the spatiotemporal lag structure detected by bold signal-based blood flow tracking. Frontiers in Neuroscience, 11(MAY), 1-13. https://doi.org/10.3389/fnins.2017.00256
%	Satow, T., Aso, T., Nishida, S., Komuro, T., Ueno, T., Oishi, N., �c Fukuyama, H. (2017). Alteration of venous drainage route in idiopathic normal pressure hydrocephalus and normal aging. Frontiers in Aging Neuroscience, 9(NOV), 1-10. https://doi.org/10.3389/fnagi.2017.00387
%	Nishida, S., Aso, T., Takaya, S., Takahashi, Y., Kikuchi, T., Funaki, T., �c Miyamoto, S. (2018). Resting-state Functional Magnetic Resonance Imaging Identifies Cerebrovascular Reactivity Impairment in Patients With Arterial Occlusive Diseases: A Pilot Study. Neurosurgery, 0(0), 1-9. https://doi.org/10.1093/neuros/nyy434
%	(in press) Aso, T., Urayama, S., Hidenao, F., & Murai, T. (2019). Axial variation of deoxyhemoglobin density as a source of the low-frequency time lag structure in blood oxygenation level-dependent signals. BioRxiv, 658377. https://doi.org/10.1101/658377

setenv('FSLOUTPUTTYPE', 'NIFTI'); % this to tell what the output type would be

% default values

if nargin< 7
	range = [];
if nargin< 6
	FIXED = 0;
	if nargin< 5
		THR = 0.3;
		if nargin< 4
			PosiMax = 7;
			if nargin< 3
				error
			end
		end
	end
end
end

MaxLag = PosiMax*2;		% lag range
ULfreq = 1/MaxLag;		% upper limit of frequency for uniquely determining the peak

reso = 1; % Lag resolution: smaller the value, the more memory load
Nseeds = PosiMax*2/reso + 1;% number of regions/seed timeseries

Sm = 8 / sqrt( 8*log(2)); % 8-mm smoothing
limit = ceil( PosiMax/reso);
Cmap = jet( Nseeds);

if FIXED==0
	dir = [ pwd '/Lag_' num2str( MaxLag) 's_thr' num2str( round( 10*THR)) '_' name];
else
	dir = [ pwd '/Lag_fix_' num2str( MaxLag) 's_thr' num2str( round( 10*THR)) '_' name];
end


disp('Preparing the data...') %-------------------------------------------

S = system( [ 'fslmaths ' vols ' -Tstd SD.nii']); if S, return, end
S = system( [ 'fslmaths ' vols ' -Tmean Tmean']); if S, return, end
S = system( 'fslmaths Tmean -thrp 25 Mask'); % Mask 
	
%S = system( ['fslmaths ' vols ' -sub Tmean -mul 1000 -div SD Data']); if S, return, end
S = system( ['fslmaths ' vols ' -mul 100 -div Tmean Data' ]); if S, error, end

S = system( [ 'fslmaths Data -nan  -s ' num2str( Sm) ' Data']); if S, return, end
disp('Filtering...')
S = system( [ 'fslmaths Data -bptf ' ...
	num2str( 1/( ULfreq/2*2.35*TR)) ' ' num2str( 1/( ULfreq*2.35*TR)) ' ' pwd '/masked_' num2str( MaxLag) 's.nii']); 

% initial seed is from the global cerebral signal
[ P,~,~] = fileparts( mfilename('fullpath'));
ROIimage = spm_read_vols( spm_vol( drReslice( 'Mask.nii', [ P '/BrainMask_lag.nii'])));

V = spm_vol( ['masked_' num2str( MaxLag) 's.nii']);
Y = spm_read_vols( V);
system( [ 'rm masked_' num2str( MaxLag) 's.nii']);

if ~isempty( range)
	Y = Y(:,:,:, range);
end

MAX = max( abs( Y),[], 4); % excluding noisy voxels with large amplitude
Y = Y.* repmat( MAX<=4, [1 1 1 size( Y,4)]);

mkdir( dir)
cd( dir)

Ysize = size( Y);

ROIimage(  ROIimage < 0.5) = NaN;
sY = Y.* repmat( ROIimage, [1 1 1 Ysize(4)]);

% reshape to space x time
if TR~=reso
	Y = resample( reshape( Y, [ Ysize(1)*Ysize(2)*Ysize(3) Ysize(4)])', double( round( TR*100)), double( round( reso*100)));
	sY = resample( reshape( sY, [ Ysize(1)*Ysize(2)*Ysize(3) Ysize(4)])', double( round( TR*100)),  double( round( reso*100)));
else
	Y = reshape( Y, [ Ysize(1)*Ysize(2)*Ysize(3) Ysize(4)])';
	sY = reshape( sY, [ Ysize(1)*Ysize(2)*Ysize(3) Ysize(4)])';
end

Seed = nanmean( sY,2);
clear sY
save InitSeed.mat Seed

disp('Extracting sLFO...') %-------------------------------------------

Lag = NaN * ones( 1, Ysize(1)*Ysize(2)*Ysize(3));
D = zeros( 1, Ysize(1)*Ysize(2)*Ysize(3));

Lim = 2;
YY = [];
for Sft = Lim:-1:-Lim
	YY = cat( 3, YY, Y( Lim+Sft+1:end-Lim+Sft, :));
end

disp('Calculating correlation...')
XX = repmat( Seed( Lim+1:end-Lim), [ 1 size( YY,2) size( YY,3)]);
CC = sum( XX.*YY, 1)./( sum( XX.*XX, 1).^.5 .* sum( YY.*YY, 1).^.5);
[ R, I] = nanmax( CC, [], 3);
I( R<THR) = 0;
Lag( I==3) = 0; % cross-correlogram peaking at zero: lag=0

Seed0 = nanmean( Y( :, I==3),2);
Seeds = Seed0;
Lim = 1;

figure( 5), clf, hold on
set( gcf, 'position', [10 10 1600 400])
set( gca, 'Color', [.5 .5 .5])
plot( Seed0( 1+limit:end-limit), 'w-')
set( gca, 'Xlim', [ 0 length( Seed0( 1+limit:end-limit))])

% Downstream (I==1)
SeedU = Seed0;
SeedD = Seed0;
Downward = Y;
Upward = Y;

for p=1:limit

	YY = [];
	Downward = [ Downward( 2:end,:); nanmean( Downward,1)];
	for Sft = Lim:-1:-Lim
		YY = cat( 3, YY, Downward( Lim+Sft+1:end-Lim+Sft, :));
	end

	XX = repmat( SeedD( Lim+1:end-Lim), [ 1 size( YY,2) size( YY,3)]);
	CC = sum( XX.*YY, 1)./( sum( XX.*XX, 1).^.5 .* sum( YY.*YY, 1).^.5);

	[ R, I] = nanmax( CC, [], 3);
	I( R<THR) = 0;
    if FIXED==0
    	SeedD = mean( Downward( :,I==2),2); % recursive lag tracking
	end
	D( I==2) = D( I==2)+1;
	I( ~isnan( Lag)) = 0;
	Lag( I==2) = -p;
	Seeds = [ Seeds SeedD(:) ];
	disp( [ sprintf( '%+0.1f', -p*reso) ' sec'])

	plot( Seeds( limit+1-p:end-limit-p,end), 'Color',  Cmap( limit+1-p,:)), drawnow

	YY = [];
	Upward = [ nanmean( Upward,1); Upward( 1:end-1,:)];
	for Sft = Lim:-1:-Lim
		YY = cat( 3, YY, Upward( Lim+Sft+1:end-Lim+Sft, :));
	end

	XX = repmat( SeedU( Lim+1:end-Lim), [ 1 size( YY,2) size( YY,3)]);
	CC = sum( XX.*YY, 1)./( sum( XX.*XX, 1).^.5 .* sum( YY.*YY, 1).^.5);

	[ R, I] = nanmax( CC, [], 3);
	I( R<THR) = 0;
    if FIXED==0
		SeedU = mean( Upward( :,I==2),2);
	end
	D( I==2) = D( I==2)+1;
	I( ~isnan( Lag)) = 0;
	Lag( I==2) = p;

	Seeds = [ SeedU(:) Seeds ];
	disp( [ sprintf( '%+0.1f', p*reso) ' sec'])
	
	plot( Seeds( limit+1+p:end-limit+p,1), 'Color', Cmap( limit+p,:))
	drawnow
end
F = getframe( gca);
save Seeds.mat Seeds
imwrite( F.cdata, 'Temporal.png')

Lag1 = reshape( Lag, Ysize(1:3))*reso;
Vout = V(1); Vout.fname = [ 'LagOrig.nii'];
spm_write_vol( Vout, Lag1);

drErode_Lag( 'LagOrig.nii');
!mv eLagOrig.nii LagMap.nii

cd ..

return


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
return

function out = drNoComma( in)
temp = findstr( ',', in);
if isempty( temp)
	out = in;
else
	out = in( 1:temp(1)-1);
end
return

function out = drReslice( ref, source, INT)

if nargin<3
	INT = 0;
end
if isstruct( ref)
	ref = ref.fname;
end
if isstruct( source)
	source = source.fname;
end

[~,N,E] = fileparts( source);

v1 = spm_vol( ref);
v1 = v1(1);
v2 = spm_vol( source);
v2 = v2(1);

if isequal( v1.mat, v2.dim)==0

	in{1}.spm.spatial.coreg.write.ref = { ref};
	in{1}.spm.spatial.coreg.write.source = { source};
	in{1}.spm.spatial.coreg.write.roptions.interp = INT;
	in{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
	in{1}.spm.spatial.coreg.write.roptions.mask = 0;
	in{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
	matlabbatch = in;
	save Reslice.mat matlabbatch
	spm_jobman( 'run', in)
	name = drNoComma( drInsert( source, 'r'));

	try
		movefile( name, pwd);
	catch
		disp('Could not move file')
	end

	out = [ pwd '/r' N E];
else
	try
		copyfile( source, pwd);
	catch
	end
	out = [ pwd '/' N E];
end
	
return

function out = drErode_Lag( in, MaxLag, Mask)
if ~exist( in, 'file'), out = []; return, end
Pdev = fileparts( mfilename('fullpath'));

Brain = spm_read_vols( spm_vol( drReslice( in, [ Pdev '/BrainMask_L.nii'],0)));

V = spm_vol( in);
Y = spm_read_vols( V);

Y( Brain<.5) = NaN;

if nargin>1
	Y( abs( Y)>=MaxLag) = NaN;
end

while length( find( isnan( Y(:))))
	nanmask = isnan( Y);
	try
		newY = cat( 4,  circshift( Y, -1, 1), circshift( Y, 1, 1), ...
				circshift( Y, -1, 2), circshift( Y, 1, 2), ...
				circshift( Y, -1, 3), circshift( Y, 1, 3));
	catch
		newY = cat( 4,  circshift( Y, [-1 0 0]), circshift( Y, [ 1 0 0]), ...
				circshift( Y, [ 0 -1 0]), circshift( Y, [ 0  1 0]), ...
				circshift( Y, [ 0 0 -1]), circshift( Y, [ 0 0  1]));
	end
	newY = nanmean( newY, 4);
	Y( nanmask) = newY( nanmask);
end
Y( Brain<.5) = NaN;

if nargin>2
	Mask = spm_read_vols( spm_vol( Mask));
	Y( Mask == 0) = NaN;
	Y( isnan( Mask)) = NaN;
end
V.fname = drInsert( in, 'e');
spm_write_vol( V, Y);
out = V.fname;


