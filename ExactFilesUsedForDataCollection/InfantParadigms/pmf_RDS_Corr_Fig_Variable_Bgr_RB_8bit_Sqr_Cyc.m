function pmf_RDS_Corr_Fig_Variable_Bgr_RB_8bit_SquareOpt_Faster_Cycles( varargin )
%
%   Shows a correlated figure region which potentially modulates in depth
%   over a background whose correlation level can be any value from 0-1.
%
%	xDiva Matlab Function paradigm

%	"pmf_" prefix is not strictly necessary, but helps to identify
%	functions that are intended for this purpose.

%   Each Matlab Function paradigm will have its own version of this file

%	First argument is string for selecting which subfunction to use
%	Additional arguments as needed for each subfunction

%	Each subfunction must conclude with call to "assignin( 'base', 'output', ... )",
%	where value assigned to "output" is a variable or cell array containing variables
%	that xDiva needs to complete the desired task.

if nargin > 0, aSubFxnName = varargin{1}; else error( 'pmf_RDS_Corr_Fig_Variable_Bgr_RB_8bit_SquareOpt_Faster.m called with no arguments' ); end

% these next three are shared by nested functions below, so we create
% them in this outermost enclosing scope.
definitions = MakeDefinitions;
parameters = {};
timing = {};
videoMode = {};

% some useful functional closures...
CFOUF = @(varargin) cellfun( varargin{:}, 'uniformoutput', false );
AFOUF = @(varargin) arrayfun( varargin{:}, 'uniformoutput', false );
PVal = @( iPart, x ) ParamValue( num2str(iPart), x );
PVal_S = @(x) ParamValue( 'S', x );
% PVal_B = @(x) ParamValue( 'B', x );
% PVal_1 = @(x) ParamValue( 1, x );
% PVal_2 = @(x) ParamValue( 2, x );

aaFactor = 4; 
maxDispAmin = 70;

% ### TEMPORARY xDIVA WORKAROUND: ###HAMILTON
screenDimData = load('HG_VideoMeasures/SonyTV_PhysicalDimensions.txt');
screenRedGunData = load('HG_VideoMeasures/SonyTV_RedGunValues.txt');
% ### TEMPORARY xDIVA WORKAROUND ###

try
    switch aSubFxnName
        case 'GetDefinitions', GetDefinitions;
        case 'ValidateParameters', ValidateParameters;
        case 'MakeMovie', MakeMovie;
    end
catch tME
    save( 'ErrorFile.mat', 'tME', '-append' ); % save into current folder for subsequent debugging
    rethrow( tME ); % this will be caught by xDiva for runtime alert message
end

    function rV = ParamValue( aPartName, aParamName )
        % Get values for part,param name strings; e.g "myViewDist = ParamValue( 'S', 'View Dist (cm)' );"
        tPart = parameters{ ismember( { 'S' 'B' '1' '2' }, {aPartName} ) }; % determine susbscript to get {"Standard" "Base" "Part1" "Part2"} part cell from parameters
        rV = tPart{ ismember( tPart(:,1), { aParamName } ), 2 }; % from this part, find the row corresponding to aParamName, and get value from 2nd column
    end

    function rV = MakeDefinitions
        % for "ValidateDefinition"
        % - currently implementing 'integer', 'double', 'nominal'
        % - types of the cells in each parameter row
        % - only "standard" type names can be used in the "type" fields
        % - 'nominal' params should have
        %       (a) at least one item
        %		(b) value within the size of the array
        % - all other params (so far) should have empty arrays of items
        
        rV = { ...
            
        % - Parameters in part_S must use standard parameter names
        % - 'Sweep Type' : at least 'Fixed' sweep type must be defined as first item in list
        % - 'Modulation' : at least 'None' modulation type must be defined
        % - 'Step Type'  : at least 'Lin Stair' type must be defined,
        %                  first 4 step types are reserved, custom step types can only be added after them
        
        % "Standard" part parameters - common to all paradigms, do not modify names.
        {
        'View Dist (cm)'	100.0	'double' {}
        'Mean Lum (cd)'     1.0	'double' {} % under default calibration, this is (0,0,0)
        'Fix Point'         1.0	'double' {} % revisit: FixPnt nominal? we do not know yet
        'Sweep Type'        'Disparity'	'nominal' { 'Fixed', 'Disparity', 'Bgr Corr' }
        'Step Type'         'Lin Stair'	'nominal' { 'Lin Stair' 'Log Stair' }
        'Sweep Start'       0.0	'double' {}
        'Sweep End'         8.0 'double' {}
        'Modulation'        'ZeroNear' 'nominal' { 'None' 'ZeroNear' 'ZeroFar' 'FigReverse' }
        }
        
        % "Base" part parameters - paradigm specific parameters that apply to unmodulated parts of the stimulus
        {
        'ModInfo' 8.0 'double' {} % 'Disparity (amin)'
        'Bgr Corr (0-1)'   1.0 'double' {}
        'Dot diam. (amin)' 1.0 'double' {}
        'Dot density (per deg^2)' 5.0 'double' {}
        }
        
        % "Part1" - parameters that apply to part of stimulus that carries first frequency tag.
        % "Cycle Frames" must be first parameter
        {
        'Cycle Frames'   30.0 'integer' {}  % framerate(Hz)/stimFreq(Hz)
        'Contrast (pct)' 100.0 'double' {}
        %				'Disparity (amin)' 1.0 'double' {}
        'Geometry' 'Hbars' 'nominal' {'circle' '4circles' 'annulus' 'Hbars' 'Vbars' 'none'}
        'Disparity type' 'Horizontal' 'nominal' {'Horizontal' 'Vertical'}
        'Stimulus Extent' 'Fullscreen' 'nominal' {'Fullscreen' 'SquareOnly'} % 'SqrOnBlack' 'SqrOnMean' could be included as memory intense as 'Fullscreen'
        'Size Setting' 'default' 'nominal' {'default' 'Bars 5 cycles' 'Bars 10 cycles' 'Bars 15 cycles' 'Bars 20 cycles'}
        }
        
        % "Part2" - parameters that apply to part of stimulus that carries second frequency tag.
        {
        'Cycle Frames'   3.0 'integer' {} % framerate(Hz)/stimFreq(Hz)
        }
        
        % Sweepable parameters
        % The cell array must contain as many rows as there are supported Sweep Types
        % 1st column (Sweep Types) contains Sweep Type as string
        % 2nd column (Stimulus Visiblity) contains one of the following strings,
        % indicating how stimulus visibility changes when corresponding swept parameter value increases:
        %   'constant' - stimulus visibility stays constant
        %   'increasing' - stimulus visibility increases
        %   'decreasing' - stimulus visibility decreases
        % 3rd column contains a single-row cell array of pairs, where each pair is a single-row cell
        % array of 2 strings: { Part name, Parameter name }
        
        % If sweep affects only one part, then you only need one
        % {part,param} pair; if it affects both parts, then you need both
        % pairs, e.g. for "Contrast" and "Spat Freq" below
        
        {
        'Fixed'         'constant'   { }
        'Disparity'     'increasing' { { 'B' 'ModInfo' } } % 'Disparity (amin)';
        'Bgr Corr'      'increasing' { { 'B' 'Bgr Corr (0-1)' } }
        }
        
        % ModInfo information
        % The cell array must contain as many rows as there are supported Modulations
        % 1st column (Modulation) contains one of the supported Modulation typs as string
        % 2nd column contains the name of the ModInfo parameter as string
        % 3rd column (default value) contains default value of the ModInfo
        % parameter for this Modulation
        {
        
        'None'			'ModInfo'            0.0
        'ZeroNear'		'RelDispAmp (amin)'	20.0
        'ZeroFar'		'RelDispAmp (amin)' 20.0
        'FigReverse'    'RelDispAmp (amin)' 20.0
        }
        
        % Required by xDiva, but not by Matlab Function
        {
        'Version'					1
        'Adjustable'				true
        'Needs Unique Stimuli'		false % ###HAMILTON for generating new stimuli every time
        'Supports Interleaving'		false
        'Part Name'                 { 'Figure' 'Dots'}
        'Frame Rate Divisor'		{ 2 1 } % {even # frames/cycle only, allows for odd-- makes sense for dot update}
        'Max Cycle Frames'			{ 120 6 } % i.e. -> 0.5 Hz, 10 Hz
        'Allow Static Part'			{ true true }
        % 			'Supported Psy Procedures'	{}	% currently not used
        % 			'Supported Psy Nulls'		{}	% currently not used
        }
        };
    
    end

    function GetDefinitions
        assignin( 'base', 'output', MakeDefinitions );
    end

    function ValidateParameters
        % xDiva invokes Matlab Engine command:
        
        % pmf_<subParadigmName>( 'ValidateParameters', parameters, timing, videoMode );
        % "parameters" here is an input argument. Its cellarray hass the
        % same structure as "defaultParameters" but each parameter row has only first two
        % elements
        
        % The "timing" and "videoMode" cellarrays have the same row
        % structure with each row having a "name" and "value" elements.
        
        
        [ parameters, timing, videoMode ] = deal( varargin{2:4} );
        
        sweepType = PVal('S','Sweep Type');
        isSwept = ~strcmp(sweepType,'Fixed');
        
        VMVal = @(x) videoMode{ ismember( videoMode(:,1), {x} ), 2 };
        
        width_pix = VMVal('widthPix');
        width_cm = screenDimData(screenDimData(:,1)==width_pix,2); %VMVal('imageWidthCm');
        viewDistCm = PVal('S','View Dist (cm)');
        width_deg = 2 * atand( (width_cm/2)/viewDistCm );
        pix2arcmin = ( width_deg * 60 ) / width_pix;
        
        validationMessages = {};
        
        ValidateDotSize;
        ValidateDisparityParams;
        ValidateBgrCorr;
        ValidateContrast;
        ValidateModulation;
        ValidateSizeSettings;
        
        parametersValid = isempty( validationMessages );
        
        % _VV_ Note the standard 'output' variable name
        output = { parametersValid, parameters, validationMessages };
        assignin( 'base', 'output', output );
        
        function CorrectParam( aPart, aParam, aVal )
            tPartLSS = ismember( { 'S' 'B' '1' '2' }, {aPart} );
            tParamLSS = ismember( parameters{ tPartLSS }(:,1), {aParam} );
            parameters{ tPartLSS }{ tParamLSS, 2 } = aVal;
        end
        
        function AppendVMs(aStr), validationMessages = cat(1,validationMessages,{aStr}); end
        
        function ValidateSizeSettings
            sizeSetting = PVal(1,'Size Setting');
            stimGeom = PVal(1,'Geometry');
           
            if ~strcmp(stimGeom,'Hbars') && ~strcmp(stimGeom,'Vbars') && ~strcmp(sizeSetting,'default')
                CorrectParam( '1', 'Size Setting', 'default' );
                AppendVMs( sprintf('Invalid Size Setting. ''default'' is the only allowed setting for Geometry setting ''%s''',stimGeom) );                
            end
        end
        
        function ValidateModulation
            if strcmp(PVal('S','Modulation'),'None')
                CorrectParam('S','Modulation','ZeroNear');
                AppendVMs('Modulation choice ''None'' is not supported. Resetting to an allowed choice, ''ZeroNear''.');
            end
        end
        
        function ValidateDotSize
            % For PTB code to work properly, dot size must be a non-zero
            % integer number of pixels
            
            % convert dot diameter in amin into pixels:
            dotSizeAmin = PVal('B','Dot diam. (amin)');
            dotSizePix = dotSizeAmin/pix2arcmin;
            
            if mod(dotSizePix,1) %decimal
                dotSizePix = round(dotSizePix);
                if dotSizePix < 1
                    dotSizePix = 1;
                end
                dotSizeAmin = dotSizePix*pix2arcmin;
                CorrectParam('B','Dot diam. (amin)',dotSizeAmin);
                AppendVMs(sprintf(...
                    'Invalid Dot diam., which must be an integer number of pixels, corrected to nearest possible value: %3.4f amin.',...
                    dotSizeAmin));
            end
            if dotSizePix < 1
                dotSizePix = 1;
                dotSizeAmin = dotSizePix*pix2arcmin;
                CorrectParam('B','Dot diam. (amin)',dotSizeAmin);
                AppendVMs(sprintf(...
                    'Invalid Dot diam., which must be at least 1 pixel, corrected to nearest possible value: %3.4f amin.',...
                    dotSizeAmin));
            end
        end
        
        function ValidateDisparityParams
            % for now this function only checks if the disparity is too
            % large or too small
            
            minDisp = pix2arcmin/aaFactor;
            
            if isSwept && strcmp(sweepType,'Disparity')
                sweepStart = PVal('S','Sweep Start');
                if ~validDisparity(sweepStart)
                    correctDisp(sweepStart,'Sweep Start','S')
                end
                sweepEnd = PVal('S','Sweep End');
                if ~validDisparity(sweepEnd)
                    correctDisp(sweepEnd,'Sweep End','S')
                end
            else
                figDisp = PVal('B','ModInfo');
                if ~validDisparity(figDisp)
                    correctDisp(figDisp,'ModInfo','B')
                end
            end
            
            function isValid = validDisparity(dispIn)
                if dispIn < minDisp || dispIn > maxDispAmin
                    isValid = false;
                else
                    isValid = true;
                end
            end
            
            function correctDisp(valOld,valName,partName)
                if valOld < minDisp
                    CorrectParam(partName,valName,minDisp);
                    AppendVMs(sprintf('Invalid %s value, which must be at least %3.4f amin. Now corrected to this value.',valName,minDisp));
                elseif valOld > maxDispAmin
                    CorrectParam(partName,valName,maxDispAmin);
                    AppendVMs(sprintf('Invalid %s value, which can be at most %3.4f amin. Now corrected to this value.',valName,maxDispAmin));
                end
            end
            
        end
        
        function ValidateBgrCorr
            % background correlation levels must be on the interval [0,1]
            
            % get bgrCorr values
            if isSwept && strcmp(sweepType,'Bgr Corr')
                sweepStart = PVal('S','Sweep Start');
                if ~validCorr(sweepStart)
                    correctCorr(sweepStart,'Sweep Start','S');
                end
                sweepEnd = PVal('S','Sweep End');
                if ~validCorr(sweepEnd)
                    correctCorr(sweepEnd,'Sweep End','S')
                end
            else
                bgrCorr = PVal('B','Bgr Corr (0-1)');
                if ~validCorr(bgrCorr)
                    correctCorr(bgrCorr,'Bgr Corr (0-1)','B')
                end
            end
            
            function isValid = validCorr(corrIn)
                if corrIn<0 || corrIn>1
                    isValid = false;
                else
                    isValid = true;
                end
            end
            
            function correctCorr(valOld,valName,partName)
                if valOld < 0
                    CorrectParam(partName,valName,0);
                    AppendVMs(sprintf('Invalid %s value, which cannot be less than 0. Now corrected to 0.',valName));
                elseif valOld > 1
                    CorrectParam(partName,valName,1);
                    AppendVMs(sprintf('Invalid %s value, which cannot be more than 1. Now corrected to 1.',valName));
                end
            end
            
        end
        
        function ValidateContrast
            % should check if requested contrast is not available due to
            % number of color bits on the system. ###
            
            if PVal( 1, 'Contrast (pct)' ) > 100
                CorrectParam( '1', 'Contrast (pct)', 100 );
                AppendVMs( 'Invalid Part 1 Contrast (pct): too high, corrected to 100.' );
            end
            
            if PVal( 1, 'Contrast (pct)' ) < 0
                CorrectParam( '1', 'Contrast (pct)', 0 );
                AppendVMs( 'Invalid Part 1 Contrast (pct): too low, corrected to 0.' );
            end
            
        end
        
    end

    function MakeMovie
        
        mkdir('HG_Infofiles')
        fid = fopen(sprintf('HG_Infofiles/stiminfo_%s.txt',datestr(now,'yyyymmmdd_HHMMPM')),'w');
        fprintf(fid,'Calling MakeMovie...\n\n');
        
        % ---- GRAB & SET PARAMETERS ----
        [ parameters, timing, videoMode, trialNumber ] = deal( varargin{2:5} );
        
        needsUnique = definitions{end}{3,2};
        needsImFiles = true;
        if ~needsUnique
            tstartsearch = tic;
            fprintf(fid,'Unique stimulus not requested. Checking files on disk...\n');
            filesToCheck = dir('HG_Images/*.mat');
            if ~isempty(filesToCheck)
                for fnum = 1:length(filesToCheck)
                    prevVars = load(['HG_Images/',filesToCheck(fnum).name],'parameters','timing','videoMode');
                    if isequal(prevVars.parameters,parameters) && isequal(prevVars.timing,timing) && isequal(prevVars.videoMode,videoMode)
                        fprintf(fid,'Match found! Images stored in HG_Images/%s will be used as stimuli.\n',filesToCheck(fnum).name);
                        prevIms = load(['HG_Images/',filesToCheck(fnum).name],'rIms','rImSeq');
                        rIms = prevIms.rIms;
                        rImSeq = prevIms.rImSeq;
                        clear prevIms prevVars
                        isSuccess = true;
                        needsImFiles = false;
                        break;
                    end
                end
            else
                fprintf(fid,'No previous stimulus images on disk, proceeding with MakeMovie code...\n');
            end
            fprintf(fid,'Time elapsed for image search: %f seconds.\n\n',toc(tstartsearch));
        else
            fprintf(fid,'Unique stimulus requested, proceeding with MakeMovie code...\n');
        end
        
        if needsImFiles
            TRVal = @(x) timing{ ismember( timing(:,1), {x} ), 2 };
            VMVal = @(x) videoMode{ ismember( videoMode(:,1), {x} ), 2 };
            fprintf(fid,'Defining video, timing, stimulus parameters:\n\n');
            
            preludeNames = {'Dynamic' 'Blank' 'Static'}; % fixed within deeper xDiva code
            
            % timing/trial control vars
            numCoreSteps = TRVal('nmbCoreSteps');
            numCoreBins = TRVal('nmbCoreBins');
            numPreludeBins = TRVal('nmbPreludeBins');
            framesPerStep = TRVal('nmbFramesPerStep'); % difference between step/bin?
            framesPerBin = TRVal('nmbFramesPerBin');
            preludeType = TRVal('preludeType');
            isBlankPrelude = preludeType == 1;
            numCoreFrames = framesPerStep * numCoreSteps;
            numPreludeFrames = numPreludeBins * framesPerBin;
            numTotalFrames = 2 * numPreludeFrames + numCoreFrames;
            figFramesPerCycle = PVal(1,'Cycle Frames'); % part 1 = Figure
            dotFramesPerCycle = PVal(2,'Cycle Frames'); % part 2 = Dots
            minUpdate = min([figFramesPerCycle,dotFramesPerCycle]);
            fprintf(fid,'preludeType = %s\n',preludeNames{preludeType+1});
            fprintf(fid,'numPreludeBins: %d\n',numPreludeBins);
            fprintf(fid,'numCoreBins: %d\n',numCoreBins);
            fprintf(fid,'Total frames incl. pre-/post-ludes = %d\n',numTotalFrames);
            
            % screen vars
            width_pix = VMVal('widthPix');
            height_pix = VMVal('heightPix');
            % ### TEMPORARY xDIVA WORKAROUND: ###HAMILTON
            width_cm = screenDimData(screenDimData(:,1)==width_pix,2); %VMVal('imageWidthCm');
            height_cm = screenDimData(screenDimData(:,1)==width_pix,3);
            stimExtent = PVal(1,'Stimulus Extent');
            fprintf(fid,'Stimulus extent: %s\n',stimExtent);
            switch stimExtent
                case 'Fullscreen'
                    makeStimSquare = false;
                    makeStimFull = false;
                case {'SquareOnly', 'SqrOnBlack', 'SqrOnMean'}
                    makeStimSquare = true;
                    if strcmp(stimExtent,'SqrOnBlack')
                        makeStimFull = true;
                        backFill = 'black';
                    elseif strcmp(stimExtent,'SqrOnMean')
                        makeStimFull = true;
                        backFill = 'mean';
                    else
                        makeStimFull = false;
                    end
            end
            
            % ### TEMPORARY xDIVA WORKAROUND: ###
            frameRate = VMVal('nominalFrameRateHz');
            viewDistCm = PVal('S','View Dist (cm)');
            stimContrast = PVal(1,'Contrast (pct)')/100;
            % compute values needed:
            dotsOriginScreenCoord = [0 0]; %[width_pix/2  height_pix/2]; % only for Screen('DrawDots')
            cm2pix = width_pix/width_cm;
            width_deg = 2 * atand( (width_cm/2)/viewDistCm );
            pix2arcmin = ( width_deg * 60 ) / width_pix;
            width_dva = width_pix*(pix2arcmin/60);
            height_dva = height_pix*(pix2arcmin/60);
            fprintf(fid,'Stimulus Contrast = %3.2f%%\n',stimContrast*100);
            fprintf(fid,'Screen dimensions = %3.2f x %3.2f cm (%d x %d px) @ %d Hz\n',width_cm,height_cm, width_pix,height_pix,frameRate);
            fprintf(fid,'\nNOTE! Screen dimensions are hardcoded (temporary xDiva workaround).\n\n');
            fprintf(fid,'Screen dimensions = %3.2f x %3.2f DVA\n',width_dva,height_dva);
            fprintf(fid,'Viewing Dist = %3.2f cm\n',viewDistCm);
            fprintf(fid,'%3.3f pixels per cm\n',cm2pix);
            fprintf(fid,'1 pixel = %3.3f arcmin\n',pix2arcmin);
            fprintf(fid,'Anti-aliasing factor set to %d; smallest possible disparity = %f arcmin\n',aaFactor,pix2arcmin/aaFactor);
            if makeStimSquare
                fprintf(fid,'Stimulus displayable area is largest possible square (%f x %f DVA).\n',height_dva,height_dva);
            end
            
            % ### TEMPORARY xDIVA WORKAROUND: ###HAMILTON
            redMod = screenRedGunData(screenRedGunData(:,1)==width_pix,2)/255;
            % value of red gun intensity viewed through red lens (3.0186 cd/m2),
            % ~matched to max intensity blue through blue lens (3.03 cd/m2)
            fprintf(fid,'\nNOTE! Red values will be modulated by %3.4f (temporary xDiva workaround).\n\n',redMod);
            % ### TEMPORARY xDIVA WORKAROUND ###
            
            % stim vars
            sweepType = PVal('S','Sweep Type');
            isSwept = ~strcmp(sweepType,'Fixed');
            modType = PVal('S','Modulation');
            stimGeom = PVal(1,'Geometry');            
            sizeSetting = PVal(1,'Size Setting');
            dispType = PVal(1,'Disparity type');
            dotSizeAmin = PVal('B','Dot diam. (amin)');
            dotDensity = PVal('B','Dot density (per deg^2)');
            % convert dot density to number of dots for PTB:
            numDots = round( dotDensity*(  width_dva * height_dva ) );
            % convert dot diameter in amin into pixels for PTB:
            dotSizePix = dotSizeAmin/pix2arcmin;
            dotSizeAmin = dotSizePix*pix2arcmin;
            fprintf(fid,'dotDensity: %2.2f/deg^2, (~%d dots)\n',dotDensity,numDots);
            fprintf(fid,'dotSize: %3.3f amin (%2.4f px)\n',dotSizeAmin,dotSizePix);
            fprintf(fid,'stimGeom: %s, sizeSetting: %s\n',stimGeom,sizeSetting);
            
            bgrCorrSteps = GetParamArray('B','Bgr Corr (0-1)');
            figDispSteps = GetParamArray('B','ModInfo');
            
            if isSwept
                fprintf(fid,'\nSWEEP: %s\n',sweepType);
            end
            fprintf(fid,'Modulation type: %s\n',modType);
            fprintf(fid,'Disparity type: %s\n',dispType);
            
            fprintf(fid,'\nBin/Step Values\nDisp. (amin)\tBgr Corr\n');
            for t = 1:numCoreSteps, fprintf(fid,'%f\t%f\n',figDispSteps(t),bgrCorrSteps(t)); end
            
            % ---- SCHEDULE FRAMES ----
            
            figDispFrames = nan(1,numCoreFrames);
            bgdCorrFrames = nan(1,numCoreFrames);
            newDotPatternFrames = zeros(1,numCoreFrames);
            for t = 1:numCoreFrames/minUpdate
                newDotPatternFrames(((t-1)*minUpdate)+1) = 1;
            end
            figDispNumCyclesPerBin = framesPerBin/figFramesPerCycle;
            if isSwept
                % first set up foreground disparity modulation for any case
                % (figDispSteps already takes into account possible sweeping of disparity)
                halfCycLen = (figFramesPerCycle/2);
                for b = 1:numCoreBins
                    for cycl = 1:figDispNumCyclesPerBin
                        halfCycleIx = ( figFramesPerCycle*(cycl-1)+1 : figFramesPerCycle*(cycl-1)+ halfCycLen ) + framesPerBin*(b-1);
                        switch modType
                            case 'ZeroNear'
                                figDispFrames( halfCycleIx ) = figDispSteps(b);
                                figDispFrames( halfCycleIx + halfCycLen ) = 0;
                            case 'ZeroFar'
                                figDispFrames( halfCycleIx ) = -figDispSteps(b);
                                figDispFrames( halfCycleIx + halfCycLen ) = 0;
                            case {'FigReverse', 'BothReverse'}
                                figDispFrames( halfCycleIx ) = figDispSteps(b);
                                figDispFrames( halfCycleIx + halfCycLen ) = -figDispSteps(b);
                        end
                    end
                end
                % now take care of background correlation
                if strcmp(sweepType,'Bgr Corr')
                    for b = 1:numCoreBins
                        for cycl = 1:figDispNumCyclesPerBin
                            CycleIx = ( (figFramesPerCycle)*(cycl-1)+1:(figFramesPerCycle)*cycl ) + framesPerBin*(b-1);
                            bgdCorrFrames(CycleIx) = bgrCorrSteps(b);
                        end
                    end
                else
                    bgdCorrFrames = repmat(bgrCorrSteps,[1 framesPerBin]);
                end
            else
                bgdCorrFrames = repmat(bgrCorrSteps,[1 framesPerBin]);
                figDispFrames = repmat(figDispSteps,[1 framesPerBin]);
            end
            
            % initialize some outputs
            isSuccess = true;   % the type must be 'logical'
            if makeStimSquare
                if ~isBlankPrelude
                    rIms = zeros(height_pix,height_pix,2,numCoreFrames/minUpdate,'uint8');
                else
                    rIms = zeros(height_pix,height_pix,2,(numCoreFrames/minUpdate)+1,'uint8');
                end
            else
                if ~isBlankPrelude
                    rIms = zeros(height_pix,width_pix,2,numCoreFrames/minUpdate,'uint8');
                else
                    rIms = zeros(height_pix,width_pix,2,(numCoreFrames/minUpdate)+1,'uint8');
                end
            end
            rImSeq = zeros(numCoreFrames,1); % must be numTotalFrames long, but we'll concatenate w/pre- and post-ludes later
            for t = 1:numCoreFrames/minUpdate
                rImSeq(((t-1)*minUpdate)+1) = t;
            end
            if numPreludeBins >0
                switch preludeType
                    case 0 % dynamic
                        preludeVals = rImSeq(1:framesPerBin);
                        postludeVals = rImSeq(end-framesPerBin+1:end);
                    case 1 % blank
                        preludeVals = ones(framesPerBin,1).*size(rIms,4); % rIms(:,:,:,end) is the prelude image
                        postludeVals = preludeVals;
                    case 2 % static
                        preludeVals = ones(framesPerBin,1).*rImSeq(find(rImSeq>0,1,'first'));
                        postludeVals = ones(framesPerBin,1).*rImSeq(find(rImSeq>0,1,'last'));
                end
                rImSeq = [preludeVals; rImSeq; postludeVals];
            end
            fprintf(fid,'\nLength(rImSeq): %d\n',size(rImSeq,1));
            fprintf(fid,'All params defined.\n\n');
            
            % ---- PTB CODE ----
            usePTB = true; % ###HAMILTON ONLY for debugging/testing
            if usePTB
                tstart = tic;
                fprintf(fid,'\nReady to attempt PTB code...\n');
                try
                    Screen('Preference', 'SkipSyncTests', 2);
                    whichScreen = max(Screen('Screens')); % ###HAMILTON
                    myRect = [];
                    [window, windowRect] = Screen('OpenWindow', whichScreen, 0, myRect, 24, [], [], aaFactor); % 8-bit/channel precision
                    Screen(window,'BlendFunction',GL_ONE, GL_ONE); % allows overlapping dot regions to blend properly, GL_ONE = PTB default var
                    windowOffScreen = Screen(window,'OpenOffscreenWindow');
                    white = WhiteIndex(window);
                    black = BlackIndex(window);
                    if makeStimSquare
                        width_pix_PTB = height_pix;
                        height_pix_PTB = height_pix;
                    else
                        width_pix_PTB = windowRect(RectRight);
                        height_pix_PTB = windowRect(RectBottom);
                    end
                    fprintf(fid,'Color range of display: %d - %d\n',black,white);
                    fprintf(fid,'Size of stimulus display area: %d x %d\n',width_pix_PTB,height_pix_PTB);
                    w = window; % choose window or windowOffScreen, place to draw images
                    imcnt = 1;
                    stimFixedInfoPrinted = false;
                    fprintf(fid,'Looping over numCoreFrames (%d)\n',numCoreFrames);
                    for t = 1:numCoreFrames
                        if newDotPatternFrames(t)
                            figDispCrnt = figDispFrames(t);
                            bgrCorrCrnt = bgdCorrFrames(t);
                            
                            % ---- GENERATE IMAGE ----
                            dots = makeDotStim(bgrCorrCrnt, figDispCrnt/pix2arcmin);
                            
                            Screen('FillRect',w,0);
                            for dim = 1:2
                                Screen('DrawDots', w, dots(dim).xy, dots(dim).sz, dots(dim).color, dotsOriginScreenCoord, 2); % 2, blended circles
                            end
                            if w == window
                                Screen('Flip',w);
                            end
                            screenImage = Screen('GetImage', w); % default type of returned image is uint8
                            
                            % ---- SAVE IMAGE ----
                            %imwrite(screenImage,sprintf('HGImages/test%d.bmp',imcnt));
                            if makeStimSquare
                                rIms(:,:,:,imcnt) = screenImage(1:height_pix,1:height_pix,[1 3]);
                            else
                                rIms(:,:,:,imcnt) = screenImage(:,:,[1 3]);
                            end
                            imcnt = imcnt + 1;
                        end
                    end
                    % The next 2 calls can't be done in DrawDots because it messes up the OpenGL blending
                    % 1) fix for lack of separate RB gun calibration in xDiva
                    if redMod ~= 1
                        rIms(:,:,1,:) = redMod.*rIms(:,:,1,:);
                    end
                    % 2) scale by stimContrast
                    if stimContrast ~= 1
                        rIms = stimContrast.*rIms;
                    end
                    
                    if makeStimSquare && makeStimFull
                        tstartnow = tic;
                        fprintf(fid,'generating full size image array... ');
                        rImsFull = ones(height_pix,width_pix,2,size(rIms,4),'uint8');
                        if strcmp(backFill,'black')
                            rImsFull = black.*rImsFull;
                        elseif strcmp(backFill,'mean')
                            for imdim = 1:2
                                rImsFull(:,:,imdim,:) = mean(mean(mean(rIms(:,:,imdim,:)))).*rImsFull(:,:,imdim,:);
                            end
                        end
                        colIx = (width_pix/2)-(height_pix/2)+1:(width_pix/2)+(height_pix/2);
                        rImsFull(:,colIx,:,:) = rIms;
                        clear rIms
                        rIms = rImsFull;
                        clear rImsFull
                        fprintf(fid,'done in %f seconds\n',toc(tstartnow));
                    end
                    
                    fprintf(fid,'PTB success.\n');
                    Screen('CloseAll');
                    %save('HG_debugging/rIms.mat','rIms');
                catch
                    isSuccess = false;
                    Screen('CloseAll');
                end
                tToc = toc(tstart);
                fprintf(fid,'PTB loop elapsed time: %f sec.\n',tToc);
                % print out all variables and their sizes ###
            else
                % stand-in variable for rIms that will be the same size as
                % what's generated by the PTB code
                if makeStimSquare
                    rIms = uint8(255.*ones(height_pix,height_pix,2,numCoreFrames/minUpdate) );
                else
                    rIms = uint8(255.*ones(height_pix,width_pix,2,numCoreFrames/minUpdate) );
                end
                rIms(:,:,1,end-10:end) = 0;
            end
            save(sprintf('HG_Images/images_%s.mat',datestr(now,'yyyymmmdd_HHMMPM')),'rIms','rImSeq','parameters','timing','videoMode');
        end
        
        function [dots] = makeDotStim(bgdCorr,fgdDisparity)
            
            dispShift = abs(fgdDisparity/2); % half for each eye
            
            % first create the 4 random dot images
            % (2 Eyes x 2 depth planes, fore- and back- ground)
            % intialized at zero disparity:
            [figRE,marginVal] = getRandomDotPositions(numDots);
            figLE = figRE; % figure is always perfectly correlated in this paradigm
            
            if bgdCorr == 1
                backRE = getRandomDotPositions(numDots);
                backLE = backRE;
            else
                pUncorr = 1-bgdCorr;
                numUncorr = round(pUncorr*numDots);
                numCorr = numDots - numUncorr;
                
                corrDots = getRandomDotPositions(numCorr);
                
                uncorrR = getRandomDotPositions(numUncorr);
                uncorrL = getRandomDotPositions(numUncorr);
                
                backRE = [corrDots uncorrR];
                backLE = [corrDots uncorrL];
            end
            
            % modify disparity of dots in the figure (in this paradigm bgr always @ zero disparity):
            switch modType
                case 'ZeroNear'
                    figDir = 'near';
                case 'ZeroFar'
                    figDir = 'far';
                case 'FigReverse'
                    if fgdDisparity > 0
                        figDir = 'near';
                    else
                        figDir = 'far';
                    end
            end
            if fgdDisparity~=0
                [figRE,figLE] = shiftDots(figRE,figLE,dispShift,figDir,dispType);
            end
            
            % create mask to represent stimulus geometry:
            % (0=background, 1=foreground)
            maskDims = aaFactor.*[height_pix_PTB,width_pix_PTB];
            imMask = cell(2,1); % cell array so can index imMask using a 2D map
            imMask{1} = zeros(maskDims); imMask{2} = imMask{1};
            Lix = 1; Rix = 2;
            
            tic;
            switch stimGeom
                case 'none' % for debugging only
                    imMask{1} = ones(maskDims); imMask{2} = imMask{1};
                case 'circle'
                    circ_cen_orig = maskDims./2; circ_cen = repmat(circ_cen_orig,[2 1]);
                    if makeStimSquare
                        circ_rad = round((width_pix_PTB*aaFactor)/3); % fixed circle size
                    else
                        circ_rad = round((width_pix_PTB*aaFactor)/5); % fixed circle size
                    end
                    if ~stimFixedInfoPrinted
                        fprintf(fid,'Circle diameter = %f DVA (%f pix)\n',(circ_rad*2)*pix2arcmin/(60*aaFactor),(circ_rad*2)/aaFactor);
                        stimFixedInfoPrinted = true;
                    end
                    if fgdDisparity~=0
                        circ_cen(Lix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'L');
                        circ_cen(Rix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'R');
                    end
                    for imSide = [Lix Rix]
                        circVerts = getCircleVertices(circ_cen(imSide,1),circ_cen(imSide,2),circ_rad);
                        imMask{imSide} = roipoly(imMask{imSide},circVerts(1,:),circVerts(2,:));
                    end
                case '4circles'
                    if makeStimSquare
                        circ_rad = round((width_pix_PTB*aaFactor)/6); % fixed circle size
                    else
                        circ_rad = round((width_pix_PTB*aaFactor)/8); % fixed circle size
                    end
                    if ~stimFixedInfoPrinted
                        fprintf(fid,'Circle diameters = %f DVA (%f pix)\n',(circ_rad*2)*pix2arcmin/(60*aaFactor),(circ_rad*2)/aaFactor);
                        stimFixedInfoPrinted = true;
                    end
                    quarterDim = min(maskDims./4);
                    circIms = cell(4,2);
                    for imSide = [Lix Rix]
                        cnt = 1;
                        for rquad = [-1 1]
                            for cquad = [-1 1]
                                circ_cen_orig = [quarterDim*rquad, quarterDim*cquad]+maskDims./2; circ_cen = repmat(circ_cen_orig,[2 1]);
                                if fgdDisparity~=0
                                    circ_cen(Lix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'L');
                                    circ_cen(Rix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'R');
                                end
                                circVerts = getCircleVertices(circ_cen(imSide,1),circ_cen(imSide,2),circ_rad);
                                circIms{cnt,imSide} = roipoly(imMask{imSide},circVerts(1,:),circVerts(2,:));
                                cnt = cnt + 1;
                            end
                        end
                    end
                    for imSide = [Lix Rix]
                        myString = sprintf('imMask{imSide} = circIms{1,%d}',imSide);
                        for bn = 2:4
                            myString = [myString, sprintf('| circIms{%d,%d}',bn,imSide)];
                        end
                        eval([myString,';']);
                    end
                case 'annulus'
                    if makeStimSquare
                        outerRadius = round((width_pix_PTB*aaFactor)/3); % fixed outer radius
                        innerRadius = round((width_pix_PTB*aaFactor)/10); % fixed inner radius
                    else
                        outerRadius = round((width_pix_PTB*aaFactor)/5); % fixed outer radius
                        innerRadius = round((width_pix_PTB*aaFactor)/12); % fixed inner radius
                    end
                    if ~stimFixedInfoPrinted
                        fprintf(fid,'Outer diameter = %f DVA (%f pix)\n',(outerRadius*2)*pix2arcmin/(60*aaFactor),(outerRadius*2)/aaFactor);
                        fprintf(fid,'Inner diameter = %f DVA (%f pix)\n',(innerRadius*2)*pix2arcmin/(60*aaFactor),(innerRadius*2)/aaFactor);
                        stimFixedInfoPrinted = true;
                    end
                    circ_cen_orig = maskDims./2; circ_cen = repmat(circ_cen_orig,[2 1]);
                    if fgdDisparity~=0
                        circ_cen(Lix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'L');
                        circ_cen(Rix,:) = shiftMaskCoordinate(circ_cen_orig,dispShift,figDir,dispType,'R');
                    end
                    circIms = cell(2,2);
                    for imSide = [Lix Rix]
                        circVerts = getCircleVertices(circ_cen(imSide,1),circ_cen(imSide,2),outerRadius);
                        circIms{1,imSide} = roipoly(imMask{imSide},circVerts(1,:),circVerts(2,:));
                        
                        circVerts = getCircleVertices(circ_cen(imSide,1),circ_cen(imSide,2),innerRadius);
                        circIms{2,imSide} = roipoly(imMask{imSide},circVerts(1,:),circVerts(2,:));
                    end
                    for imSide = [Lix Rix]
                        myString = sprintf('imMask{imSide} = circIms{1,%d} & ~circIms{2,%d};',imSide,imSide);
                        eval(myString);
                    end
                case {'Hbars' 'Vbars'}
                    if strcmp(sizeSetting,'default') || strcmp(sizeSetting,'Bars 5 cycles')
                        nCycles = 5; % fixed number of cycles
                    else
                        switch sizeSetting
                            case 'Bars 10 cycles'
                                nCycles = 10;
                            case 'Bars 15 cycles'
                                nCycles = 15;
                            case 'Bars 20 cycles'
                                nCycles = 20;
                        end
                    end
                    nBars = nCycles*2;
                    barVerts = cell(nBars,1);
                    if strcmp(stimGeom,'Hbars')
                        c1 = 1+marginVal; c2 = maskDims(2)-marginVal;
                        barEdges = round(linspace(1+marginVal,aaFactor*height_pix_PTB-marginVal,nBars+1));
                        for barNum = 1:nBars
                            % c, r (x, y), ccw winding/order of vertices
                            r1 = barEdges(barNum); r2 = barEdges(barNum+1);
                            barVerts{barNum} = [c2 c1 c1 c2; r1 r1 r2 r2];
                        end
                        if ~stimFixedInfoPrinted
                            fprintf(fid,'%d cycles of a square wave grating shown (%f cpd)\n',nCycles,nCycles/((height_pix_PTB*pix2arcmin)/60));
                            stimFixedInfoPrinted = true;
                        end
                    elseif strcmp(stimGeom,'Vbars')
                        r1 = 1+marginVal; r2 = maskDims(1)-marginVal;
                        barEdges = round(linspace(1+marginVal,aaFactor*width_pix_PTB-marginVal,nBars+1));
                        for barNum = 1:nBars
                            % c, r (x, y)
                            c1 = barEdges(barNum); c2 = barEdges(barNum+1);
                            barVerts{barNum} = [c2 c1 c1 c2; r1 r1 r2 r2];
                        end
                        if ~stimFixedInfoPrinted
                            fprintf(fid,'%d cycles of a square wave grating shown (%f cpd)\n',nCycles,nCycles/((width_pix_PTB*pix2arcmin)/60));
                            stimFixedInfoPrinted = true;
                        end
                    end
                    if fgdDisparity~=0
                        shiftVal(Lix,:) = shiftMaskCoordinate([0 0],dispShift,figDir,dispType,'L');
                        shiftVal(Rix,:) = shiftMaskCoordinate([0 0],dispShift,figDir,dispType,'R');
                    else
                        shiftVal = [0 0];
                    end
                    barIms = cell(nBars/2,2);
                    for imSide = [Lix Rix]
                        cnt = 0;
                        for bn = 1:nBars
                            if mod(bn,2)
                                cnt = cnt + 1;
                                barsIms{cnt,imSide} = roipoly(imMask{imSide},barVerts{bn}(1,:)+shiftVal(2),barVerts{bn}(2,:)+shiftVal(1));
                            end
                        end
                    end
                    for imSide = [Lix Rix]
                        myString = sprintf('imMask{imSide} = barsIms{1,%d}',imSide);
                        for bn = 2:nBars/2
                            myString = [myString, sprintf('| barsIms{%d,%d}',bn,imSide)];
                        end
                        eval([myString,';']);
                    end
            end
            %tToc = toc;
            %fprintf(fid,'Left and right masks made, elapsed time = %f sec\n',tToc);
            
            % mask dots to create combined array of background and figure dots
            %tic;
            Ldots = applyMask(figLE,backLE,Lix);
            Rdots = applyMask(figRE,backRE,Rix);
            %tToc = toc;
            %fprintf(fid,'Dots masked, elapsed time = %f sec\n',tToc);
            
            dots(1).xy = Ldots;
            dots(2).xy = Rdots;
            dots(1).sz = dotSizePix;
            dots(2).sz = dots(1).sz;
            dots(1).color = [white black black];
            dots(2).color = [black black white];
            
            function [shiftedVal] = shiftMaskCoordinate(origVal,shiftMag,shiftDirection,disparityType,imSide)
                switch disparityType
                    case 'Horizontal'
                        shift = [ 0, shiftMag ]; % image indexing: (row/y,column/x)
                    case 'Vertical'
                        shift = [ shiftMag, 0 ]; % image indexing: (row/y,column/x)
                end
                shift = round(aaFactor.*shift);
                if (strcmp(shiftDirection,'near') && strcmp(imSide,'R')) || (strcmp(shiftDirection,'far') && strcmp(imSide,'L'))
                    shift = -shift;
                end
                shiftedVal = origVal + shift;
            end
            
            function [circleVerts] = getCircleVertices(circleCenterRow,circleCenterCol,circleRadius)
                % circleVerts = [column indices; row indices] for use with
                % roipoly.m which assumes origin is at the upper left corner of the mask image
                % accordingly circleCenter must be: [column/x; row/y]
                tix = -(pi/2):0.1:(3*pi/2);
                row = -circleRadius.*sin(tix);
                col = circleRadius.*cos(tix);
                circleCenter = [circleCenterCol; circleCenterRow];
                circleVerts = bsxfun(@plus,[col;row],circleCenter);
            end
            
            
            function [dotsMasked] = applyMask(figureDots,bgDots,imSide)
                % (1=foreground, 0=background, -1=neither)
                nFig = size(figureDots,2);
                inclDotFig = false(1,nFig);
                figureDotsTMP = round(figureDots.*aaFactor)+1;
                for dotnum = 1:nFig
                    if (figureDotsTMP(2,dotnum) > 0) && (figureDotsTMP(2,dotnum) < maskDims(1)) ...
                            && (figureDotsTMP(1,dotnum) > 0) && (figureDotsTMP(1,dotnum) < maskDims(2))
                        if imMask{imSide,1}(figureDotsTMP(2,dotnum),figureDotsTMP(1,dotnum)) == 1
                            inclDotFig(dotnum) = true;
                        end
                    end
                end
                nBg = size(bgDots,2);
                inclDotBg = false(1,nBg);
                bgDotsTMP = round(bgDots.*aaFactor)+1;
                for dotnum = 1:nBg
                    if (bgDotsTMP(2,dotnum) > 0) && (bgDotsTMP(2,dotnum) < maskDims(1)) ...
                            && (bgDotsTMP(1,dotnum) > 0) && (bgDotsTMP(1,dotnum) < maskDims(2))
                        if imMask{imSide,1}(bgDotsTMP(2,dotnum),bgDotsTMP(1,dotnum)) == 0
                            inclDotBg(dotnum) = true;
                        end
                    end
                end
                
                dotsMasked = [];
                if sum(inclDotFig)>0
                    dotsMasked = [dotsMasked,figureDots(:,inclDotFig)];
                end
                if sum(inclDotBg)>0
                    dotsMasked = [dotsMasked,bgDots(:,inclDotBg)];
                end
            end
            
            function [xyRshift,xyLshift] = shiftDots(xyR,xyL,shiftMag,shiftDirection,disparityType)
                switch disparityType
                    case 'Horizontal'
                        shiftR = [ repmat(shiftMag,1,size(xyR,2)) ; zeros(1,size(xyR,2)) ]; % dots: [x;y]
                        shiftL = [ repmat(shiftMag,1,size(xyL,2)) ; zeros(1,size(xyL,2)) ];
                    case 'Vertical'
                        shiftR = [ zeros(1,size(xyR,2)); repmat(shiftMag,1,size(xyR,2)) ];
                        shiftL = [ zeros(1,size(xyL,2)); repmat(shiftMag,1,size(xyL,2)) ];
                end
                switch shiftDirection
                    case 'near'
                        xyRshift = xyR - shiftR;
                        xyLshift = xyL + shiftL;
                    case 'far'
                        xyRshift = xyR + shiftR;
                        xyLshift = xyL - shiftL;
                end
            end
            
        end
        
        function [dots,marginVal] = getRandomDotPositions(dotsTotal)
            dots = zeros(2, dotsTotal);
            marginVal = ceil(maxDispAmin/pix2arcmin);
            dots(1,:) = (width_pix_PTB-marginVal)*rand(1,dotsTotal)+marginVal/2;
            dots(2,:) = (height_pix_PTB-marginVal)*rand(1,dotsTotal)+marginVal/2;
        end
        
        % final steps for MakeMovie to return proper variables:
        s = whos('rIms');
        fprintf(fid,'rIms size: [%d %d %d %d], %f GB.\n',size(rIms),s.bytes/(1024*1024*1024));
        output = { isSuccess, rIms, cast( rImSeq, 'int32') }; % "Images" (single) and "Image Sequence" (Int32)
        clear rIms
        assignin( 'base', 'output', output )
        if isSuccess
            fprintf(fid,'Success with MakeMovie!\n');
        else
            fprintf(fid,'isSuccess is false.\n');
        end
        fclose(fid);
    end

    function rV = GetParamArray( aPartName, aParamName )
        
        % For the given part and parameter name, return an array of values
        % corresponding to the steps in a sweep.  If the requested param is
        % not swept, the array will contain all the same values.
        
        % tSpatFreqSweepValues = GetParamArray( '1', 'Spat Freq (cpd)' );
        
        % Here's an example of sweep type specs...
        %
        % definitions{end-2} =
        % 	{
        % 		'Fixed'         'constant'   { }
        % 		'Contrast'      'increasing' { { '1' 'Contrast (pct)' } { '2' 'Contrast (pct)' } }
        % 		'Spat Freq'      'increasing' { { '1' 'Spat Freq (cpd)' } { '2' 'Spat Freq (cpd)' } }
        % 	}
        
        T_Val = @(x) timing{ ismember( timing(:,1), {x} ), 2 }; % get the value of timing parameter "x"
        tNCStps = T_Val('nmbCoreSteps');
        tSweepType = PVal_S('Sweep Type');
        
        % we need to construct a swept array if any of the {name,value} in definitions{5}{:,3}
        
        [ ~, tSS ] = ismember( tSweepType, definitions{end-2}(:,1) ); % the row subscript in definitions{5} corresponding to requested sweep type
        % determine if any definitions{5}{ tSS, { {part,param}... } } match arguments tPartName, tParamName
        IsPartAndParamMatch = @(x) all( ismember( { aPartName, aParamName }, x ) );
        tIsSwept = any( cellfun( IsPartAndParamMatch, definitions{end-2}{tSS,3} ) ); % will be false for "'Fixed' 'constant' { }"
        
        if ~tIsSwept
            rV = ones( tNCStps, 1 ) * ParamValue(  aPartName, aParamName );
        else
            tStepType = PVal_S('Step Type');
            tIsStepLin = strcmpi( tStepType, 'Lin Stair' );
            tSweepStart = PVal_S('Sweep Start');
            tSweepEnd = PVal_S('Sweep End');
            if tIsStepLin
                rV = linspace( tSweepStart, tSweepEnd, tNCStps )';
            else
                rV = logspace( log10(tSweepStart), log10(tSweepEnd), tNCStps )';
            end
        end
        
    end


end


