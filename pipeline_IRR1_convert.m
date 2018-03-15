function pipeline_IRR1_convert(opts);
%convert DICOM to NIFTI and get acquisition parameters

mkdir(opts.niftiDir); delete([opts.niftiDir '/*.*']); %create dir/delete contents

%% initialise variables
acqPars.NSeries=size(opts.series,2);
acqPars.TR=nan(acqPars.NSeries,1);
acqPars.TE=nan(acqPars.NSeries,1);
acqPars.FA=nan(acqPars.NSeries,1);
acqPars.FADeg=nan(acqPars.NSeries,1);
acqPars.TI=nan(acqPars.NSeries,1);

%% for each series convert dicoms and record acquisition parameters
for iSeries=1:size(opts.series,2)
    temp2=dir(opts.dicomExamDir);
    temp3=~cellfun(@isempty,regexp({temp2.name},['^' num2str(opts.series(iSeries)) '_'])) | strcmp({temp2.name},num2str(opts.series(iSeries))); %look for directories names 'iSeries' or beginning with 'iSeries_'
    if sum(temp3)~=1; error('Cannot find single unique dicom directory for this series.'); end
    dicomDir=[opts.dicomExamDir '/' temp2(temp3).name];
    
    dicomPaths=getMultipleFilePaths([dicomDir '/*.dcm']); %look for dcm files, otherwise look for ima files
    if isempty(dicomPaths); dicomPaths=getMultipleFilePaths([dicomDir '/*.IMA']); end;
    if isempty(dicomPaths); error(['No dicoms found in ' dicomDir]); end;
    
    %% get acquisition parameters
    temp=dicominfo(dicomPaths{1});
    acqPars.TE(iSeries)=0.001*temp.EchoTime;
    acqPars.FADeg(iSeries)=temp.FlipAngle;
    acqPars.FA(iSeries)=((2*pi)/360)*temp.FlipAngle;
    acqPars.TI(iSeries)=0.001*temp.InversionTime;
    acqPars.TR(iSeries)=0.001*temp.RepetitionTime;
    
    %% convert dicoms to 3D niftis
    system(['dcm2niix -f series' num2str(opts.series(iSeries),'%02d') ' -o ' opts.niftiDir ' ' dicomDir]);
end

%% display acquisition parameters
disp(['TR: ' num2str(acqPars.TR.')]); disp(['TE: ' num2str(acqPars.TE.')]); disp(['FA (deg): ' num2str(acqPars.FADeg.')]); disp(['TI: ' num2str(acqPars.TI.')]);

%% make a 4D nifti containing all series
spm_file_merge(cellstr(strcat(['./' opts.niftiDir '/series'],num2str(opts.series.','%02d'),'.nii')),[opts.niftiDir '/4D.nii'],0);

save([opts.niftiDir '/acqPars'],'acqPars'); %save acquisition parameters
