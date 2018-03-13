function GenerateRescaleDist(vol,HU1,HU2,HU3,HU4,dirname)


    S1 = vol(3:end,1);
    S2 = vol(3:end,2);
    S3 = vol(3:end,3);
    
    if ~isnan(HU4)
        S4 = vol(3:end,3);
    end
   

    S1Dist = fitdist(S1, 'Normal');
    S2Dist = fitdist(S2, 'Normal');
    S3Dist = fitdist(S3, 'Normal');
    
    if ~isnan(HU4)
        S4Dist = fitdist(S4, 'Normal');
    end

    count = 500000;
    rescaleSlopeValues = [count];
    rescaleInterceptValues = [count];
    
    if ~isnan(HU4)
        dmatValues = zeros(count,4);
    else
        dmatValues = zeros(count,3);
    end
    
    
    f = figure(4);
    loadingbar = waitbar(0,'Running Sim...');
    
    if ~isnan(HU4)
        parfor i = [1:count]
            waitbar(i / count)
            S1Rand = random(S1Dist);
            S2Rand = random(S2Dist);
            S3Rand = random(S3Dist);
            S4Rand = random(S4Dist);

            HounsfieldUnitmat = [HU1;HU2;HU3;HU4;];
            Dmat = [S1Rand; S2Rand; S3Rand; S4Rand;];

            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            RS_lin = rescale(1);
            RI_lin = rescale(2);

            rescaleSlopeValues(i) = RS_lin;
            rescaleInterceptValues(i) = RI_lin;
            dmatValues(i,:) = Dmat;
        end
    else
        parfor i = [1:count]
            waitbar(i / count)
            S1Rand = random(S1Dist);
            S2Rand = random(S2Dist);
            S3Rand = random(S3Dist);

            HounsfieldUnitmat = [HU1;HU2;HU3;];
            Dmat = [S1Rand; S2Rand; S3Rand;];

            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            RS_lin = rescale(1);
            RI_lin = rescale(2);

            rescaleSlopeValues(i) = RS_lin;
            rescaleInterceptValues(i) = RI_lin;
            dmatValues(i,:) = Dmat;
        end
    end
    "RS mean"
    mean(rescaleSlopeValues)
    "RS std"
    std(rescaleSlopeValues)
    "RI mean"
    mean(rescaleSlopeValues)
    "RI std"
    std(rescaleSlopeValues)
    
    cd(dirname)
    
    close(loadingbar)
    hold off
    subplot(2,1,1)
    histogram(rescaleSlopeValues)
    subplot(2,1,2)
    histogram(rescaleInterceptValues)
    rescaleSlopeValues = rescaleSlopeValues.';
    rescaleInterceptValues = rescaleInterceptValues.';
    
    dataWrite = [rescaleSlopeValues,rescaleInterceptValues]

    dlmwrite("RS_LIN_VALS_test.csv",dataWrite,'roffset',1,'coffset',0,'-append');



end
