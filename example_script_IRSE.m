clear; close all;

%% set up paths
rawDataRoot='/ISIS/procB/BRIC2_dicom/MR';
procRoot='/ISIS/proc5/mthripp1';
addpath('/usr/local/spm/spm8');
addpath([procRoot '/software/relaxometry/IRSE_3a']);
addpath([procRoot '/software/UTILITIES']);


%% set parameters
opts.dicomExamDir='/ISIS/proc5/iSVD/DEVELOPMENT/PHANTOM_DATA/CRIC_20141210'; %dicom exam dir
opts.series=[22:25]; %series numbers
opts.niftiDir='./nifti_IRT1'; %dir for nifti images
opts.niftiRegDir='./nifti_reg_IRT1'; %dir for co-registered nifti images
opts.mapDir='./maps_IRT1'; %dir for T1 maps
opts.threshold=200; %only process voxels where max signal is at least this value
opts.NSeries=size(opts.series,2);
opts.NTry=20; %number of fitting attempts (1 is usually sufficient for data with a good range of TIs)
%opts.slices={50:67 40:55 1}; %indicate which voxels to fit (useful for testing)
opts.slices={'all' 'all' 'all'}; %indicate which voxels to fit (useful for testing)

save('./options','opts');

%% run pipeline steps

%pipeline_IRR1_convert(opts); %convert dicoms, get acquisition parameters
%pipeline_IRR1_reg(opts); %co-register images
pipeline_IRR1_create_map_3par(opts); %create T1 maps