function pipeline_R1_create_map(opts)
%generate T1 map using IRSE data

load([opts.niftiDir '/acqPars'],'acqPars'); %load acquisition parameters

mkdir(opts.mapDir); delete([opts.mapDir '/*.*']); %create dir/delete contents

%% load 4D magnitude data
[signal,xyz]=spm_read_vols(spm_vol([opts.niftiRegDir '/r4D.nii'])); %load co-registered images
signal=abs(signal); % necessary to fit complex/real data using same code

%% initialise output arrays
volTemplate=spm_vol(['./' opts.niftiDir '/series' num2str(opts.series(1),'%02d') '.nii']); %use this header as template for 3D output files
T1=nan(volTemplate.dim); a=nan(volTemplate.dim); b=nan(volTemplate.dim); RSq=nan(volTemplate.dim); model=nan([volTemplate.dim acqPars.NSeries]);

%% do the fitting

    function s=calcSignal1(c,t)
        % c(1)=T1 c(2)=S0
        s=nan(1,opts.NSeries);
        for iSeries=1:opts.NSeries
            s(iSeries)=abs(c(2)*(1-2*exp(-acqPars.TI(iSeries)/c(1))+exp(-acqPars.TR(iSeries)/c(1))));
        end
    end

    function s=calcSignal2(c,t)
        % c(1)=T1 c(2)=a c(3)=b
        s=nan(1,opts.NSeries);
        for iSeries=1:opts.NSeries
            s(iSeries)=abs(c(2)+c(3)*exp(-acqPars.TI(iSeries)/c(1)));
        end
    end

%%loop through voxels and fit signal to model in 3-step process
for iDim=1:3
    if strcmp(opts.slices{iDim},'all'); slices{iDim}=1:size(signal,iDim); else slices{iDim}=opts.slices{iDim}; end %determine which indices to fit
end
for i1=slices{1}; for i2=slices{2}; for i3=slices{3}; % loop through voxels (only loop through indices to be fitted)
            
            if max(signal(i1,i2,i3,:))<opts.threshold; continue; end %skip low intensity voxels
            
            tic;
            
            y=squeeze(signal(i1,i2,i3,:)).'; %define dependent variable (signal)
            
            %% use minimum intensity to estimate T1 and max intensity to estimate S0 - for use a starting values in next step
            x0=nan(1,2);
            x0(2)=max(y); %crude estimate of S0
            [temp,nullIdx]=min(y);
            TI_null=acqPars.TI(nullIdx);
            x0(1)=TI_null/log(2); %crude estimate of T1
            
            %% fit to 2-parameter model and use results as initial estimates in 3-parameter model
            %x0=[1 2500];
            [x1,resnorm,residual,exitflag,output]=lsqcurvefit(@calcSignal1,x0,[],y...
                ,[0 0 ],[inf inf],optimset('Display','off','TypicalX',[1 x0(2)]));
            
            %% fit 3-parameter model
            x=nan(opts.NTry,3); RSqTry=nan(1,opts.NTry);
            x0_2=[x1(1) x1(2)*(1+exp(-acqPars.TR(1)/x1(1))) -2*x1(2)]; %use previous parameter estimates to generate starting values
            for iTry=1:opts.NTry
                if iTry>1; x0_2_final=x0_2.*(1.5*rand(1,3)+0.5); else x0_2_final=x0_2; end; %randomise starting values for 2nd, 3rd etc. fit attempts
                [x(iTry,:),resnorm,residual,exitflag,output]=lsqcurvefit(@calcSignal2,x0_2_final,[],y...
                    ,[0 -inf -inf ],[inf inf inf],optimset('Display','off','TypicalX',[1 x0(2) -2*x0(2)]));
                RSqTry(iTry)=1 - sum((y-squeeze(calcSignal2(x(iTry,:)))).^2) / (sum((y-mean(y)).^2)); %calculate RSq
            end
            [RSq(i1,i2,i3),bestIdx]=max(RSqTry); %choose best fit
            
            T1(i1,i2,i3)=x(bestIdx,1); a(i1,i2,i3)=x(bestIdx,2); b(i1,i2,i3)=x(bestIdx,3);
            model(i1,i2,i3,:)=calcSignal2(x(bestIdx,:));
            
            timeElapsed=toc;
            
            if rand<0.02 %randomly plot data to check it's working
                figure(1),plot(1:acqPars.NSeries,y,'ko',1:acqPars.NSeries,squeeze(model(i1,i2,i3,:)),'b-')
                title({['Initial coefficients: ' num2str(x0)] ...
                    ['2-par coefficients: ' num2str(x1)] ...
                    ['3-par initial coefficients: ' num2str(x0_2)] ...
                    ['3-par final coefficients: ' num2str(x(bestIdx,:))] ...
                    ['Time elapsed: ' num2str(timeElapsed)] ['Exit flag: ' num2str(exitflag) ' RSq: ' num2str(RSq(i1,i2,i3))]});
                pause(0.5);
                %if x0(1)>2; pause; end
            end
        end;
    end;
    disp([num2str(i1) '/' num2str(size(signal,1))]); %display progress
end;

%% write output images
for iEcho=1:opts.NSeries
    volModel=volTemplate; volModel.dt=[16 0]; volModel.fname=[opts.mapDir '/model_echo_' num2str(iEcho,'%02d') '.nii'];
    spm_write_vol(volModel,model(:,:,:,iEcho));
end
spm_file_merge(sort(getMultipleFilePaths([opts.mapDir '/model_echo_*.nii'])),[opts.mapDir '/model.nii'],0);
delete([opts.mapDir '/model_echo_*.nii']);

paramNames={'T1' 'a' 'b' 'RSq'};
outputs={T1 a b RSq};

for iOutput=1:size(outputs,2)
    volOutput=volTemplate;
    volOutput.fname=[opts.mapDir '/' paramNames{iOutput} '.nii'];
    volOutput.dt=[16 0];
    spm_write_vol(volOutput,outputs{iOutput});
end

end