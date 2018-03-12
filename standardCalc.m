function standardCalc
%To-do 1/25/2018: Define question how we want to relate the implant to 3d
%model. Talk to andrew about getting image of implant...
%This code actually changes the rescale slop and intercept for all slices.
%-- KV
clear global
close all
%Set all of your global variables. -- KV

global firstDir
firstDir = cd;

%RS and RI is the rescale slope and rescale intercept for the linear
%calibration. RS and RI are obtained from the totalAverage variable. -- KV
global RS_lin 
global RI_lin 
global RS_exp
global RI_exp

%Intial and final slice of region of interest -EL
global mark1
global mark2

%coeffa coeffb are the rescale slopes for the exponential calibration using
%the equation coeffa(exp(coeffb*PV)). coeffa and coeffb are
%obtained using the totalAverage variable.
global coeffa
global coeffb

%ginfo1 is used here to store the dicominfo information for each slice in
%the Generate3dMatrix -- KV
global ginfo1
global convertedMatrix

%Axis of view
global viewType
%Postion of slider viewer
global sliderPositon


mark1 = 1;
mark2 = 1;
RS_lin = [];
RI_lin = [];
RS_exp = [];
RI_exp = [];
coeffb = [];
coeffa = [];
n = 1;

convertedMatrix = 0;

radius = 10;
cordinates1 = 0;
cordinates3 = 0;

viewType = 1;
sliderPositon = 1;

%ginfo1 is used in regular generate3dMatrix, ginfo is used in
%Generate3dMatrixbrandon
%generate3dMatrix function is used for measurements, while
%Generate3dMatrixbrandon is written for calibrations.
%(Generate3dMatrixbrandon is name so because the code was written for
%Brandon W. project) -- KV
[dirname] = uigetdir('Please choose dicom directory');


calibratedInView = false;
uncalibratedDir = dirname;
waterAirCalibratedDir = '?';
standardCalibratedDir = '?';




matrix = Generate3dMatrixCBCT(dirname);

%% UI CALLBACKS %%%%%%%%%%
    %% This function dynamically switches to Axial view
    function switchViewAxialCallback(hObject,event)
        viewType = 1;
        updateImage()
       
    end
    
    %% This function dynamically switches to Sagittal view
    function switchViewSagittalCallback(hObject, event)
        viewType = 2;
        updateImage()
    end

    %% This function dynamically switches to Coronal view
    function switchViewCoronalCallback(hObject, event)
        viewType = 3;
        updateImage()
    end


%% This function is updating the image we see as we scroll through the z slices -- KV
    function updateImageCallback(hObject,event)
        sliderPositon = uint16(get(hObject,'Value'));
        
        updateImage();
    end

%%This function is the callback for running the "take measurement" routine.
    function takeMeasurementCallback(hObject, event)
        %takeMeasurement()
        takeMeasurementWithDist()
        
    end

%% 
    function initWaterAirCalibCallback(hObject,event)
        waterAirCalibration();
    end

%%

    function initStandardCalibrationCallback(hObject,event)
        standardCalibration();
    end

%% This function is indicating the Z slice we choose for Mark1 -- KV
    function setmark1(hObject,event)
        mark1 = sliderPositon;
        set(btn1, 'string', strcat('Mark1: ',num2str(sliderPositon)));
    end
%% This function is indicating the Z slice we choose for Mark2 -- KV
    function setmark2(hObject,event)
        mark2 = sliderPositon;
        set(btn2, 'string', strcat('Mark2: ',num2str(sliderPositon)));
    end

%% inserting the x and y cordinates for the first and second point we choose to indicate the radius
 %cordinates1 is the center of the of the standard at Mark1. cordinates2
 %is the outer border of the standard. cordinates3 below is the
 %center of the of the standard at Mark2. -- KV
    function getradiusCallback(hObject,event)
        radius_coordinates1 = ginput(1)
        radius_coordinates2 = ginput(1)
        X1 = radius_coordinates1(1);
        Y1 = radius_coordinates1(2);
       
        X2 = radius_coordinates2(1);
        Y2 = radius_coordinates2(2);
        radius = sqrt((X2-X1)^2 + (Y2-Y1)^2)
        set(getRadius, 'string', strcat('Radius: ',num2str(radius)));
        
    end

%% getting the pixel value from the ginput -- KV
    function getpoint(hObject,event)
        cordinates3 = ginput(1);
        xvalue = cordinates3(1)
        yvalue = cordinates3(2)
        set(infobtn, 'string', strcat('X= ', num2str(xvalue), 'Y =',num2str(yvalue)))
        
    end

%% initiaizes 3d im view
    function threeDimensionalAnalysisCallback(hObject,event)
       
        cd(firstDir)
        %Defines the values in which model is viewable
        pixelRangeX = 40;
        pixexlRangeZ = 80;
        
        %Asks user to select point from image
        selectionPoint = ginput(1);
        
        %Sets limit for image subsetx`
        xvalue = selectionPoint(1);
        yvalue = selectionPoint(2);
   
        xmin = xvalue - pixelRangeX
        xmax = xvalue + pixelRangeX
        
        ymin = yvalue - pixelRangeX
        ymax = yvalue + pixelRangeX
        
        zmin = sliderPositon
        zmax = sliderPositon + pixexlRangeZ
        
        %Seperates out subset of image set
        reducedMatrix = matrix(xmin:xmax,ymin:ymax,zmin:zmax);
        modelView(reducedMatrix)
        
    end


%% Calculation and Calibration Functions
%% Calibrate using Water / Air Standards
    function waterAirCalibration()
        
            cd(firstDir);
            
            cordinates = cordinates1;
            
            locationX = round(cordinates(1));
            locationY = round(cordinates(2));
            
            set(initRun, 'string', strcat('Center: ',num2str(cordinates)));
            CenterM1 = cordinates1;
            CenterM2 = cordinates3;
            deltay = double(CenterM2(2))-double(CenterM1(2));
            deltaz = mark2 - mark1;
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            deltax = double(CenterM2(1))-double(CenterM1(1))
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)

            for calib = [1:2]
            
               %%Prompts users to select new region of interest for
               %%averaging standard information
               if calib == 2;
                   
                   viewMark1()
                   getradiusCallback(hObject,event)
                   viewMark2()
                   getpoint(hObject,event)
                   cordinates = cordinates1;
                   locationX = round(cordinates(1))
                   locationY = round(cordinates(2))
                   set(initRun, 'string', strcat('Center: ',num2str(cordinates)));
                   CenterM1 = cordinates1;
                   CenterM2 = cordinates3;
                   deltay = double(CenterM2(2))-double(CenterM1(2))
                   deltaz = mark2 - mark1
                   my = double(deltay)/double(deltaz)
                   by = double(CenterM1(2)) -double(my)*double(mark1)
                   deltax = double(CenterM2(1))-double(CenterM1(1))
                   mx = double(deltax)/double(deltaz)
                   bx = double(CenterM1(1))- double(mx)*double(mark1)
               end
               
               radius = input('Please specify what radius you want to start with\n');
               
               %ensures mark1 is less than mark2
               if(mark1>mark2)
                   tempVar = mark1;
                   mark1=mark2; 
                   mark2 = tempVar;
               end
               
               %%Generates an array with enough space to hold values for
               %%each slice
               count = int16(mark2-mark1);
               struct=[count];
               struct1=size(matrix);
               struct2 = [struct1(1), struct1(2)];
               
               %%For each slice within boundaries, code will
               %%iterate through every pixel, summing, averaginga and
               %%finding standard deviation within marked location. -EL
               for slicenumber = mark1:mark2
                   
                   locationX = (double(slicenumber)*double(mx))+bx;
                   locationY = (double(slicenumber)*double(my))+by;
                   Center = [double(locationX), double(locationY)];
                   
                   %%Adjusts measurement based on the view type 
                   if viewType == 1
                        tempStruct = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));
                   elseif viewType == 2
                        tempStruct = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1));
                   elseif viewType == 3
                        tempStruct = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1));   
                   end
                   
                   struct(slicenumber - mark1 + 1) = tempStruct;
               end
               
               totalAverage = mean2(struct)
               
               STD = std(double(struct))
               
               %%Stores values in air and water respectively
               if calib == 1;
                   PVa = totalAverage;
               elseif calib == 2;
                   PVw = totalAverage;
               end
               calib = calib +1;
           end
           
           close all
           
           HUa = -1000;
           HUw = 0;
           HounsfieldUnitmat = [HUa;HUw];
           Dmat = [PVa;PVw];
           rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
           RS_lin = rescale(1);
           RI_lin = rescale(2);
           choice = questdlg('Use this data for calibration?', 'Perform Linear Fit', 'Cancel');
            switch choice
            case 'Perform Linear Fit'
                calibratedDir = GenerateCalibratedDicoms(dirname,'WaterAir',RS_lin,RI_lin)
            case 'Cancel'
                
            end
           
    end
   
    %% Calibration using HA-HDPE Samples
    function standardCalibration()
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%Values of EXPECTED standard values %%%%%%%%%%%%%%%%%%%%%%%%%%
            HU1 = 2112;
            HU2 = 4301.6;
            HU3 = 6628.6;
            %HU4 = 12012;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %ensures mark1 is less than mark2
            choice = questdlg('Verify you have selected first and last slice.',' ', 'OK','Cancel');
            switch choice     
            case 'OK'
                
            case 'Cancel'
                return   
            end
            
            %Verifies correct order for first and second marks
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            %Switches between first and last slice, allowing using to
            %select center of stanadard ROI. Prompts user for center of ROI
            %after slice has been displayed.
            viewMark1();
            CenterM1 = ginput(1);
            viewMark2()
            CenterM2 = ginput(1);
            
            %Prompts user to enter radius to be used for RoI
            radius = input('Please specify what radius you would like to use\n');
            
            %Calculates center of RoI for each slice between first and last
            %slice based on simple y = mx+b formula.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            %Iterates through each of the four standards, allowing the user
            %to select which standard they are calibrating.
            for calib = [1:3]
                if calib > 1
                     
                    %msgbox(sprintf('Please indicate center of standard #%d',calib))
                    viewMark1()
                    CenterM1 = ginput(1);
                    viewMark2()
                    CenterM2 = ginput(1);
                    %set(initRun, 'string', strcat('Center: ',num2str(cordinates)));
                    
                    
                    deltay = double(CenterM2(2))-double(CenterM1(2))
                    deltaz = mark2 - mark1
                    my = double(deltay)/double(deltaz)
                    by = double(CenterM1(2)) -double(my)*double(mark1)
                    deltax = double(CenterM2(1))-double(CenterM1(1))
                    mx = double(deltax)/double(deltaz)
                    bx = double(CenterM1(1))- double(mx)*double(mark1)
                end
                

                cd(firstDir)

                count = int16(mark2-mark1);
                struct1 = size(matrix);
                
                %Creates appropriately sized array depending on the view of
                %user selected view.
                if viewType == 1
                    struct = zeros(count, struct1(1), struct1(2));
                elseif viewType == 2 
                    struct = zeros(count, struct1(1), struct1(3));   
                elseif viewType == 3
                    struct = zeros(count, struct1(2), struct1(3));
                end
                
                %Stores EVERY value calculated from standard.
                avgStruct = []
                
                %Iterates through each and calcuates the average GS values
                %over area of interest
                for slicenumber = mark1:mark2
                    
                    locationX = (double(slicenumber)*double(mx))+bx;
                    locationY = (double(slicenumber)*double(my))+by;
                    Center = [double(locationX), double(locationY)];
                  
                    %Chooses appropriate slice depending on user view. 
                    if viewType == 1
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    elseif viewType == 2
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1));
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;


                    elseif viewType == 3
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1));
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    end
                    
                    %Stores avg value calucalted from slice
                    struct(slicenumber - mark1 + 1,:,:) = tempStruct;
                    
                    
                end
                
                totalValue = avgStruct;
                totalAverage = mean2(struct);
                STD = std(double(struct));
              
                %Generates statistics for each standard.
                if calib == 1;
                    TV1 = totalValue;
                    PV1 = totalAverage;
                    PV1std = STD(1);
                elseif calib == 2;
                    TV2 = totalValue;
                    PV2 = totalAverage;
                    PV2std = STD(1);
                elseif calib == 3
                    TV3 = totalValue;
                    PV3 = totalAverage;
                    PV3std = STD(1);
                elseif calib == 4
                    TV4 = totalValue;
                    PV4= totalAverage;
                    PV4std = STD(1);
                end
            end

            HounsfieldUnitmat = [HU1;HU2;HU3;];
            Dmat = [PV1; PV2; PV3; ];
            
            plotfig = figure(3);
            
            %Here we are solving for the rescale coeff. using the average
            %PV. Below we will then use average PV values for each slice to
            %solve for the rescale coeff for each slice. 
            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            f1 = fit(Dmat, HounsfieldUnitmat, 'exp1');
            RS_lin = rescale(1);
            RI_lin = rescale(2);
            fixHU_lin = (Dmat*RS_lin) +RI_lin;

            figure(plotfig)
            subplot(4,1,1)
            plot(Dmat, fixHU_lin, 'r--')
            hold on
            plot(Dmat, HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
            hold off
            
            %Histogram Visualization for each standard
            subplot(4,1,2)
            s1Hist = histogram(TV1)
            s1Hist.BinEdges = [0:5500];
            
            title('Standard 1 Histogram')
            size(TV1)
            S1Data = [[PV1,PV1std],TV1];
            S1Data = S1Data.';
            
            subplot(4,1,3)
            s2Hist = histogram(TV2)
            s2Hist.BinEdges = [0:5500];
            title('Standard 2 Histogram')
            S2Data = [[PV2,PV2std],TV2];
            S2Data = S2Data.';
            
            subplot(4,1,4)
            s3Hist = histogram(TV3)
            s3Hist.BinEdges = [0:5500];
            title('Standard 3 Histogram')
            S3Data = [[PV3,PV3std],TV3];
            S3Data = S3Data.';
            
            
            choice = questdlg('Use the linear or exponential fit for calibration?',' ', 'Linear','Cancel','Cancel');
            
            switch choice     
            case 'Linear'
                
                %vol = DICOM2VolumeCBCT(dirname);
                cd(firstDir)
                %calibratedDir = GenerateCalibratedDicoms(dirname,vol,"standard",RS_lin,RI_lin)
                saveas(gcf,'CalibrationData.png')
                
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S1Data);
                stddev = std(S1Data);
                rmArray = [];
                for i = 1:length(S1Data)
                    
                    if S1Data(i) < mean - (2 * stddev)
                        rmArray=[rmArray,i];

                    elseif S1Data(i) > mean + (2 * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S1Data(rmVal) = [];
                end
                
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S2Data);
                stddev = std(S2Data);
                rmArray = [];
                for i = 1:length(S2Data)
                    
                    if S2Data(i) < mean - (2 * stddev)
                        rmArray=[rmArray,i];
                    elseif S2Data(i) > mean + (2 * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S2Data(rmVal) = [];
                end
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S3Data);
                stddev = std(S3Data);
                rmArray = [];
                for i = 1:length(S3Data)
                    
                    if S3Data(i) < mean - (2 * stddev)
                        rmArray=[rmArray,i];
                    elseif S3Data(i) > mean + (2 * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S3Data(rmVal) = [];
                end    
                %Ensures that each array has the same number of elements,
                %length is choosen as smallest length of th setl
                if length(S1Data) < length(S2Data)
                    dataCatIndex = length(S1Data);
                else
                    dataCatIndex = length(S2Data);
                end
                
                if length(S3Data) < dataCatIndex
                    dataCatIndex = length(S3Data);
                end
                
                %Array containing values for each standard in a different
                %column. 
                SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex), S3Data(1:dataCatIndex)];
                
                cd(dirname)
                %Writes raw standard data as .csv file
                dlmwrite("RawDataStandard.csv",SData,'roffset',1,'coffset',0,'-append')
                cd(firstDir)
                %Generates distribution of RS and RI values based on raw
                %standard data. 
                GenerateRescaleDist(SData,HU1,HU2,HU3,dirname)
              
            %Does nothing if calibration data is not sufficient.     
            case 'Cancel'
                
            end
            updateImage()
    end


%% Takes measurement based on current dataset
    function takeMeasurement()
            
            clear avgStruct
            
            cd(firstDir)
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            viewMark1();
            CenterM1 = ginput(1);
            viewMark2()
            CenterM2 = ginput(1);
            
            %radius = input('Please specify what radius you would like to use\n');
            radius = input('Please specify what radius you want to start with\n');
            
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = []    
            
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];

                    
                if viewType == 1
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));
                    
                   
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                    
                elseif viewType == 2
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1));
                    if isempty(avgStruct)
                        avgStruct = zeros(count,length(gsValues));
                    end
                    
                    avgStruct(slicenumber - mark1 + 1,:) = gsValues(1:lengthVar(2)-1);
                    tempStruct = avgValue;
                    
                    
                elseif viewType == 3
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1));
                    if isempty(avgStruct)
                        avgStruct = zeros(count,length(gsValues));
                    end
                    
                    avgStruct(slicenumber - mark1 + 1,:) = gsValues(1:lengthVar(2)-1);
                    tempStruct = avgValue;
                end
                
                struct(slicenumber - mark1 + 1) = tempStruct;
                
            end
            
            plotfig = figure(3);
            figure(plotfig)
            subplot(3,1,1)
            size(avgStruct)
            h = histogram(avgStruct)

            h.BinEdges = [0:5500];
            h.NumBins = 10;
            
            title('Dist. of Grayscale over Volume of Interest')
            subplot(3,1,2)
           
            HUstruct = [];
            
            for structnumber = 1:length(struct)
                rescaleint(structnumber)= ginfo1{structnumber-1+mark1}.RescaleIntercept;
                rescaleslope(structnumber)= ginfo1{structnumber-1+mark1}.RescaleSlope;
                struct = double(struct);
                HUstruct(structnumber) = (rescaleslope(structnumber)*struct(structnumber))+rescaleint(structnumber);


            end
            

           rangeofGSV = range(struct);
           rangeofHU = range(HUstruct);
           
           xaxis = mark2-mark1+2;


           if rangeofGSV>rangeofHU
               yaxismax = round(min(struct)+(rangeofGSV+(.5*rangeofGSV)));
               yaxismin = round(min(struct)-(.5*rangeofGSV));
               plotaxis = 1;
               axis([-1 150 yaxismin yaxismax])
           elseif rangeofGSV<rangeofHU
               plotaxis = 0;
               yaxismax = round(min(struct)+(rangeofHU+(.5*rangeofHU)));
               yaxismin = round(min(struct)-(.5*rangeofHU));
               axis([-1 150 yaxismin yaxismax])
           end 
           
           
           plot(HUstruct);
           title('Avg HU Units versus Slice Number')
           xlabel('Number of Slices')
           ylabel('PV in HU')

           sixstruct = int16(struct);
           sixstruct = sixstruct +32767;
           total(m) = mean2(sixstruct)
           totalAverage(m) = mean2(struct)
           STD(m) = std(HUstruct)
           HU(m) = mean2(HUstruct)
           
           
           avgStr = (strcat("Avg. HU: ", string(mean2(HUstruct))))
           stdStr = (strcat("Std. HU: ",string(std(double(struct)))))
           
           label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 100 100 32]);
           label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 50 100 32]);
          
    end
%% Takes measurement based on current dataset
    function takeMeasurementWithDist()
            
            clear avgStruct
            [dirname] = uigetdir('*.csv','Please choose CSV directory');
            cd(dirname)
            [filename] = uigetfile('*.csv','Please choose CSV directory');
            rs_ri_Vals = csvread(filename);
            
            RS_Vals = rs_ri_Vals(1:end,1);
            RI_Vals = rs_ri_Vals(1:end,2);
            
            cd(firstDir)
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            viewMark1();
            CenterM1 = ginput(1);
            viewMark2()
            CenterM2 = ginput(1);
            
            radius = input('Please specify what radius you want to start with\n');
            
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = []  
    
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];


                if viewType == 1
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));


                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;

                elseif viewType == 2
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1));
                    if isempty(avgStruct)
                        avgStruct = zeros(count,length(gsValues));
                    end

                    avgStruct(slicenumber - mark1 + 1,:) = gsValues(1:lengthVar(2)-1);
                    tempStruct = avgValue;


                elseif viewType == 3
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1));
                    if isempty(avgStruct)
                        avgStruct = zeros(count,length(gsValues));
                    end

                    avgStruct(slicenumber - mark1 + 1,:) = gsValues(1:lengthVar(2)-1);
                    tempStruct = avgValue;
                end

                struct(slicenumber - mark1 + 1) = tempStruct;

            end

            totalAvgValues = [length(RS_Vals)];
            

            parfor rs_value_index = 1:length(RS_Vals)
               HUstruct = [];
               
               for structnumber = 1:length(struct)
                   
                   HUstruct(structnumber) = (RS_Vals(rs_value_index)*struct(structnumber))+RI_Vals(rs_value_index);
                    
               end

               totalAvgValues(rs_value_index) = mean2(HUstruct);

            end
            plotfig = figure(3);
            figure(plotfig)
        

            totalAvgValues = totalAvgValues.';
            
            %dlmwrite("RawDataStandard.csv",["S1","S2","S3"])
            cd(dirname)
            
            dlmwrite("totalAvgValues.csv",totalAvgValues,'roffset',1,'coffset',0,'-append')


            h1 = histogram(totalAvgValues)

            
           title('Dist. of Grayscale over Volume of Interest')
           
           avgStr = (strcat("Avg. HU: ", string(mean2(totalAvgValues))))
           stdStr = (strcat("Std. HU: ",string(std(double(totalAvgValues)))))
           
           label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 100 100 32]);
           label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 50 100 32]);
          
    end
%% This function updates slice based on slider value
    function updateImage()
        
        figure(f)
        if viewType == 1
            imshow(squeeze(matrix(:,:,sliderPositon)),[]);
            drawnow;   
        elseif viewType == 2
            imshow(squeeze(matrix(:,sliderPositon,:)),[]);
            drawnow;
        elseif viewType == 3
            imshow(squeeze(matrix(sliderPositon,:,:)),[]);
            drawnow;
        else
        end
        
    end

%% This function is used to view mark 1 when specific radius in calibration -- EL
    function viewMark1()
        n = mark1;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        drawnow;
    end

%% This function is used to view mark 2 when specific radius in calibration -- EL
    function viewMark2()
        n = mark2;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        drawnow;
    end



%% This function allows the user to switch the view between the calibrated and uncalibrated set of Dicome Files
    function switchImageSetStandardCal()
        cd(firstDir)
        [dirname]=uigetdir('Please choose dicom directory');
        matrix = Generate3dMatrixCBCT(dirname);
        updateImage()
       
    end


%% UI Elements
f=figure(1);

%Slider to adjust view position.
slider = uicontrol('Parent',f,'Style','slider','Position',[81,152,420,23],'min',0, 'max',size(matrix,3));

btn1 = uicontrol('Style', 'pushbutton', 'String', 'Mark 1','Position', [81,34,210,20],'Callback', @(hObject, event) setmark1(hObject, event));
btn2 = uicontrol('Style', 'pushbutton', 'String', 'Mark 2','Position', [291,34,210,20],'Callback', @(hObject, event) setmark2(hObject, event));

%View Switcher Buttons
viewSwitchAxial = uicontrol('Style', 'pushbutton', 'String', 'Axial View','Position', [81,132,140,20], 'Callback', @(hObject, event) switchViewAxialCallback(hObject, event));
viewSwitchSagittal = uicontrol('Style', 'pushbutton', 'String', 'Sagittal View','Position', [221,132,140,20], 'Callback', @(hObject, event) switchViewSagittalCallback(hObject, event));
viewSwitchCoronal = uicontrol('Style', 'pushbutton', 'String', 'Coronal View','Position', [361,132,140,20], 'Callback', @(hObject, event) switchViewCoronalCallback(hObject, event));

%Calibration Buttons
calibrateUsingAirAndWater = uicontrol('Style', 'pushbutton', 'String', ' Calibrate using Air and Water','Position', [81,112,210,20], 'Callback', @(hObject, event) initWaterAirCalibCallback(hObject, event));
calibrateUsingStandards = uicontrol('Style', 'pushbutton', 'String', 'Calibrate using Standards','Position', [291,112,210,20], 'Callback', @(hObject, event) initStandardCalibrationCallback(hObject, event));


initRun = uicontrol('Style', 'pushbutton', 'String', 'Take Measurement','Position', [81,14,420,20],'Callback', @(hObject, event) takeMeasurementCallback(hObject, event));
switchView = uicontrol('Style', 'pushbutton', 'String', '3d View','Position', [81,54,420,20],'Callback', @(hObject, event) threeDimensionalAnalysisCallback(hObject, event));

imageSetChange = uicontrol('Style', 'pushbutton', 'String', 'Change Image Set','Position', [81,94,420,20],'Callback', @(hObject, event) switchImageSetStandardCal());
getRadius = uicontrol('Style', 'pushbutton', 'String', 'Radius','Position', [81,74,420,20],'Callback', @(hObject, event) getradiusCallback(hObject, event));

mTextBox = uicontrol('style','text','Position', [81,0,420,14])

addlistener(slider,'ContinuousValueChange',@(hObject, event) updateImageCallback(hObject, event));

%display%
ax1=axes('parent',f,'position',[0.13 0.39  0.77 0.54]);
imshow(squeeze(matrix(:,:,n)),[]);

end
