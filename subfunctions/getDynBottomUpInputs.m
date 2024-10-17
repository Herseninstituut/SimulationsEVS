function sStimDrive = getDynBottomUpInputs(sStimParams,intStimType)
	
	%% check if we're on cluster
	global boolClust;
	if isempty(boolClust),boolClust=false;end
	
	%% get stimulus
	% drifting grating, 128 pixels * 0.2 degrees = 25.6 degrees, ON 1 second, OFF 1 second
	if isfield(sStimParams,'intFrameRate'),intFrameRate=sStimParams.intFrameRate;else intFrameRate = 100;end %Hz
	if isfield(sStimParams,'dblPixNoise'),dblPixNoise=sStimParams.dblPixNoise;else dblPixNoise = 0;end %fraction
	if isfield(sStimParams,'dblTF'),dblTF=sStimParams.dblTF;else dblTF = 0;end
	if isfield(sStimParams,'dblSF'),dblSF=sStimParams.dblSF;else dblSF = 0.5;end
	if isfield(sStimParams,'dblStimSizeRetDeg'),dblStimSizeRetDeg=sStimParams.dblStimSizeRetDeg;else dblStimSizeRetDeg = 16;end
	if isfield(sStimParams,'vecScrPixWidthHeight'),vecScrPixWidthHeight=sStimParams.vecScrPixWidthHeight;else vecScrPixWidthHeight = [128 128];end
	if isfield(sStimParams,'vecScrDegWidthHeight'),vecScrDegWidthHeight=sStimParams.vecScrDegWidthHeight;else vecScrDegWidthHeight = [25.6 25.6];end
	if isfield(sStimParams,'dblAngleInDeg'),dblAngleInDeg=sStimParams.dblAngleInDeg;else dblAngleInDeg = 45;end
	if isfield(sStimParams,'dblDeltaT'),dblDeltaT=sStimParams.dblDeltaT;else dblDeltaT = 0.5/1000;end
	if isfield(sStimParams,'dblStimDur'),dblStimDur=sStimParams.dblStimDur;else dblStimDur = 0.5;end %secs
	if isfield(sStimParams,'dblBlankDur'),dblBlankDur=sStimParams.dblBlankDur;else dblBlankDur = 0.5;end
	if isfield(sStimParams,'varDeltaSyn'),varDeltaSyn=sStimParams.varDeltaSyn;end
	if ~isfield(sStimParams,'strStimType'),sStimParams.strStimType = 'SquareGrating';end
	strStimType = sStimParams.strStimType;
	cellStimTypes = {'SquareGrating','SineGrating','Line','NatMov'};
	if ~exist('intStimType','var') || isempty(intStimType),intStimType = find(ismember(cellStimTypes,strStimType));end
	if isempty(intStimType),error([mfilename ':StimTypeError'],sprintf('Stimulus type "%s" is not recognized [%s]',strStimType,getTime));end %#ok<SPERR>
	if isfield(sStimParams,'dblContrast'),dblContrast=sStimParams.dblContrast;else dblContrast = 100;end
	if isfield(sStimParams,'dblLuminance'),dblLuminance=sStimParams.dblLuminance;else dblLuminance = 100;end
	if isfield(sStimParams,'dblPhase'),dblPhase=sStimParams.dblPhase;else dblPhase = 0;end
	if isfield(sStimParams,'dblGain'),dblGain=sStimParams.dblGain;else dblGain = 1;end
	
	%transform for backward compatibility
	if exist('varDeltaSyn','var') && (vecScrPixWidthHeight(1) / size(varDeltaSyn,1)) == 2
		vecScrPixWidthHeight = vecScrPixWidthHeight./2;
		vecScrDegWidthHeight = vecScrDegWidthHeight./2;
	end
	
	%transform format
	sParams.ST = intStimType;
	sParams.FR = intFrameRate;
	sParams.PN = dblPixNoise;
	sParams.TF = dblTF;
	sParams.SF = dblSF;
	sParams.SSRD = dblStimSizeRetDeg;
	sParams.PixWH = vecScrPixWidthHeight(1);
	sParams.DegWH = vecScrDegWidthHeight(1);
	sParams.Ori = dblAngleInDeg;
	sParams.Phase = dblPhase;
	sParams.Gain = dblGain;
	sParams.dT = dblDeltaT;
	sParams.SD = dblStimDur;
	sParams.BD = dblBlankDur;
	
	%stimulus properties
	sP = struct;
	sP.dblContrast = dblContrast;
	sP.dblLuminance = dblLuminance;
	sP.dblVisSpacingImage = (sParams.DegWH/sParams.PixWH);
	sP.vecArraySize = vecScrPixWidthHeight;
	sP.dblVisSpacingCells = (sParams.DegWH/sP.vecArraySize(1));
	
	%% build square-wave grating
	if intStimType == -1
		%build Acquivis stimulus
		error('this is not finished yet');
		% matImageRGB = buildGratingTexture(sGratingObject,matMapDegsXY)
		
		
	elseif intStimType == 1
		%build stimulus
		intTotFrames = round(intFrameRate*dblStimDur);
		dblFramesPerCycle = intFrameRate/dblTF;
		if dblTF == 0, intTotFrames = 1;end
		matStimPres = nan(vecScrPixWidthHeight(1),vecScrPixWidthHeight(2),intTotFrames);
		for intFrame=1:intTotFrames
			dblPhaseOffset = mod(((intFrame-1)/dblFramesPerCycle)*2*pi+dblPhase,2*pi);
			[matStim,matCircMask] = buildGrating(dblSF,dblStimSizeRetDeg,vecScrPixWidthHeight,vecScrDegWidthHeight,dblPhaseOffset);
			matStim = imnorm(matStim);
			matStimRot = imrotate(matStim,dblAngleInDeg,'bilinear','crop');
			matStimRot(matCircMask==0) = 0.5;
			
			%save stimulus
			matStimPres(:,:,intFrame) = matStimRot;
		end
		
		%% build sine-wave grating
	elseif intStimType == 2
		error
		%% build line stimulus
	elseif intStimType == 3
		error
		%% build natural movie stimulus
	elseif intStimType == 4
		error
		%build stimulus
		intTotFrames = round(intFrameRate*dblStimDur);
		dblFramesPerCycle = intFrameRate/dblTF;
		if dblTF == 0, intTotFrames = 1;end
		matStimPres = nan(vecScrPixWidthHeight(1),vecScrPixWidthHeight(2),intTotFrames);
		for intFrame=1:intTotFrames
			%get stimulus
			
			%rotate
			matStim = imnorm(matStim);
			matStimRot = imrotate(matStim,dblAngleInDeg,'bilinear','crop');
			%matStimRot(matCircMask==0) = 0.5;
			
			%save stimulus
			matStimPres(:,:,intFrame) = matStimRot;
		end
	end
	
	%% add pixel noise
	if dblPixNoise > 0
		matStimPres = matStimPres + dblPixNoise*max(matStimPres(:))*normrnd(0,1,size(matStimPres));
	end
	
	%% transform presentation time to simulation time
	if intStimType > 0
		%expand temporal structure of stimulus to simulation time
		intStimDurBins = round(dblStimDur/dblDeltaT);
		intTrialDur = round((dblStimDur+dblBlankDur)/dblDeltaT);
		intExpansionFactor = round(intStimDurBins/intTotFrames);
		intTotStimDur = intExpansionFactor*intTotFrames;
		intPreStimBlank = round((dblBlankDur/2)/dblDeltaT);
		intPostStimBlank = intTrialDur-intPreStimBlank-intTotStimDur;
		
		%expansion
		matImage = nan(vecScrPixWidthHeight(1),vecScrPixWidthHeight(2),intTotStimDur);
		for intFrame=1:intTotFrames
			intStart = ((intFrame-1)*intExpansionFactor+1);
			intStop = intFrame*intExpansionFactor;
			matImage(:,:,intStart:intStop) = repmat(matStimPres(:,:,intFrame),[1 1 intExpansionFactor]);
			
		end
		matImage = cat(3,repmat(0.5,[vecScrPixWidthHeight(1) vecScrPixWidthHeight(2) intPreStimBlank]),matImage,repmat(0.5,[vecScrPixWidthHeight(1) vecScrPixWidthHeight(2) intPostStimBlank]));
		
		%% build responses
		%build retinal responses
		[matR_ON,matR_OFF,dblVisSpacing,vecLuminance] = getDynRetinalDriveComplex(matImage,sP);
	else
		%peter's direct method
		[matR_ON,matR_OFF,dblVisSpacing,vecLuminance] = getDynRetinalDriveDirect(sParams,sP);
		matImage = [];
	end
	
	%LGN
	if exist('varDeltaSyn','var')
		sP.varDeltaSyn = varDeltaSyn;
		[matLGN_ON,matLGN_OFF] = getDynResponsesLGN(matR_ON,matR_OFF,sP);
	else
		[matLGN_ON,matLGN_OFF,varDeltaSyn] = getDynResponsesLGN(matR_ON,matR_OFF,sP);
	end
	
	%build output
	sStimDrive.sStimParams = sStimParams;
	sStimDrive.sParams = sParams;
	sStimDrive.sP = sP;
	sStimDrive.matImage = matImage;
	sStimDrive.matR_ON = matR_ON*dblGain;
	sStimDrive.matR_OFF = matR_OFF*dblGain;
	sStimDrive.matLGN_ON = matLGN_ON*dblGain;
	sStimDrive.matLGN_OFF = matLGN_OFF*dblGain;
	sStimDrive.varDeltaSyn = varDeltaSyn;
	sStimDrive.dblVisSpacing = dblVisSpacing;
	sStimDrive.vecContrast = dblContrast;
	sStimDrive.vecLuminance = dblLuminance;
end
