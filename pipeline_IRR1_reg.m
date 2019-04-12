function pipeline_IRR1_reg(opts)
%2D co-registration of IRSE images

mkdir(opts.niftiRegDir); delete([opts.niftiRegDir '/*.*']);

outputFiles={};
outputFiles{1}=[opts.niftiRegDir '/rSeries' num2str(opts.series(1),'%02d') '.nii'];
copyfile([opts.niftiDir '/series' num2str(opts.series(1),'%02d') '.nii'],outputFiles{1});

%% for each series convert dicoms and record acquisition parameters
for n=2:size(opts.series,2)
    refFile=['./' opts.niftiDir '/series' num2str(opts.series(1),'%02d') '.nii'];
    inputFile=['./' opts.niftiDir '/series' num2str(opts.series(n),'%02d') '.nii'];
    outputFiles{n}=['./' opts.niftiRegDir '/rSeries' num2str(opts.series(n),'%02d') '.nii'];
    matFile=['./' opts.niftiRegDir '/series' num2str(opts.series(n),'%02d') '.mat'];
    
    system([ 'flirt -in ' inputFile ' -ref ' refFile ' -out ' outputFiles{n} ' -omat ' matFile ' -2D -cost normmi' ]); %FLIRT
    system([ 'fslchfiletype NIFTI ' outputFiles{n}]); %change file type
end

%% make a 4D nifti containing all series
spm_file_merge(outputFiles.',[opts.niftiRegDir '/r4D.nii'],0);

end