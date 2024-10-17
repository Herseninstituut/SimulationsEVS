%runSimulationIndInp	Starts the actual simulation with independent retinal
%						input to remove shared fluctions. Use runSimulation() 
%						for shared input noise and faster performance.
%
%	[sData,sSimRun] = runSimulationIndInp(strInput)
%
%This function uses string-based inputs with parameter delimited by commas
%so compiled versions can also be started from the command line.
%
%Input syntax is a comma-delimited string of: [parameter=value,]
%Example: runSimulationIndInp time=0-12:00:00,conn=Connectivity.mat,... etc
%
%Inputs are 
%<param> (req/opt)	[Value-syntax]	Description:
%- time		(req)	[D-HH:MM:SS]	First format for requested running time
%									in days, hours, minutes, and seconds
%			(req)	[integer]		Second format for time, requesting
%									number of trial repetitions
%- conn		(req)	[string]		Filename of connectivity file to use
%- stim		(req)	[string]		Filename of stimulation file to load
%- idx		(opt)	[integer]		Index for worker process to ensure
%									unique random seeds per run
%- att		(opt)	[float]_[int]	Attentional strength (float) applied to
%									area (int) [currently not bioplausible]
%- tag		(opt)	[string]		Identification string to attach to
%									output so you can recognize the sim run
%- pixnoise	(opt)	[float]			Scalar to corrupt input with white noise
%- indret	(opt)	[integer]		Use independent retinas (1) or not (0)?
%- savelgn	(opt)	[integer]		Save LGN spiking data (1) or not (0)?
%
%NOTE: the function uses ispc() to check if the function is being run on a
%PC, and if so, it creates a larger "Master" file with all properties.
%Otherwise, it will only include the bare minimum as it assumes it's one of
%many worker processes and the output file size should be kept down.
%
%Version History:
%2019-02-12 Updated name and help description [by Jorrit Montijn]
%2020-07-06 Merged independent retinas into single executable [by JM]
%2020-07-20 Direct square-wave convolution, disabled LGN output save [by JM]

function [sData,sSimRun] = runSimulation(strInput)
	%strInput = 'indret=0,time=1,conn=sConnSimil2_Ret32Col180N4800S1397760_2018-04-09.mat,stim=sStim2_SquareGratingExpRet32Noise0Ori5Drift2_x2R1_2018-07-16.mat,idx=1,att=0_2,tag=C2IndepRetOri2Noise0';
    %strInput = 'indret=0,time=0:0:25,conn=Conn256N1200_2024-10-16.mat,stim=Ret256Noise0.0Ori160_x9R1_2024-10-16.mat,idx=1,att=0_2,tag=Alex20241016';
	
	hTic = tic;
	%% set log path
	global strLogDir;
	global boolClust;
	global boolSaveVm;
	boolSaveVm = false;
	
	%% running on cluster?
	boolClust = false;
	if ~boolClust && ispc
		%add directories to paths
		strHome = mfilename('fullpath');
        strHome = strHome(1:(end-length(mfilename)));
		strLogDir = [strHome 'logs' filesep];
		strOutputDir = [strHome 'SimResults' filesep];
		strStimDir = [strHome 'Stimulation' filesep];
		strConnDir = [strHome 'Connectivity' filesep];
		boolClust = false;
	else
		%add directories to paths
        strHome = mfilename('fullpath');
        strHome = strHome(1:(end-length(mfilename)));
		strLogDir = [strHome 'logs' filesep];
		strOutputDir = [strHome 'SimResults' filesep];
		strStimDir = [strHome 'Stimulation' filesep];
		strConnDir = [strHome 'Connectivity' filesep];
		boolSaveVm = false; %always disable Vm saving on cluster
		boolClust = true;
	end
	
	%% split input
	cellIn = strsplit(strInput,',');
	
	%% msg
	printf('Starting simulation; input was <%s> (%d args); [%s]\n',strInput,numel(cellIn),getTime);
	
	%% set defaults
	intWorker=1;
	dblAttention=0;
	strTag='';
	dblPixNoise=0;
	intAttArea=0;
	boolIndRet = 0;
	intSaveLGN = 0;
	
	%% parse
	for intInput=1:numel(cellIn)
		strInput = cellIn{intInput};
		cellStr = strsplit(strInput,'=');
		strParam = cellStr{1};
		strValue= cellStr{2};
		
		if strcmpi(strParam,'time') %required
			strRunningTime = strValue;
		elseif strcmpi(strParam,'conn') %required
			strConnFile = strValue;
		elseif strcmpi(strParam,'stim') %required
			strStimFile = strValue;
		elseif strcmpi(strParam,'indret') %optional
			boolIndRet = str2double(strValue);
		elseif strcmpi(strParam,'idx') %optional
			intWorker = str2double(strValue);
		elseif strcmpi(strParam,'att') %optional
			cellAttSub = strsplit(strValue,'_');
			dblAttention = str2double(cellAttSub{1});intAttArea=[];
			if numel(cellAttSub)>1;intAttArea=str2double(cellAttSub{2});end
			if isempty(intAttArea) || ~(intAttArea > 0),intAttArea=0;end
		elseif strcmpi(strParam,'tag') %optional
			strTag = strValue;
		elseif strcmpi(strParam,'pixnoise') %optional
			dblPixNoise = str2double(strValue);
		elseif strcmpi(strParam,'saveLGN') %optional
			intSaveLGN = str2double(strValue);
		else
			printf('<!> Argument not recognised, param: "%s", value: "%s" [%s] (input: %s)\n',strParam,strValue,getTime,strInput);
		end
	end
	
	
	
	%% transform running time to double
	if isnumeric(str2double(strRunningTime)) && ~isnan(str2double(strRunningTime))
		dblMaxRunningTime = uint64(str2double(strRunningTime));
		
		%% start msg
		printf('Running time requested is number of repetitions: %d; [%s]\n',dblMaxRunningTime,getTime);
	else
		if ~ismember('-',strRunningTime),strRunningTime=['0-' strRunningTime];end
		dblDays = str2double(getFlankedBy(strRunningTime,'','-'));
		dblHours = str2double(getFlankedBy(strRunningTime,'-',':'));
		dblMins = str2double(getFlankedBy(strRunningTime,':',':'));
		dblSecs = str2double(getFlankedBy(getFlankedBy(strRunningTime,':',''),':',''));
		vecV = [24*60*60*dblDays 60*60*dblHours 60*dblMins dblSecs];
		vecV(isnan(vecV)) = 0;
		dblRunningTimeInput = sum(vecV);
		dblMaxRunningTime = dblRunningTimeInput - 60*5; %stop 5 minutes before requested end
		
		%% start msg
		printf('Running time requested: %.3fs; so we will be running for %.3fs [%s]\n',dblRunningTimeInput,dblMaxRunningTime,getTime);
	end
	
	%% set parameters
	sParams = struct;
	sParams.strHome = strHome;
	sParams.strOutputDir = strOutputDir;
	sParams.strStimDir = strStimDir;
	sParams.dblDeltaT = 0.5/1000; %seconds
	sParams.dblSynSpikeMem = 0.2; %synaptic spike memory in seconds; older spikes are ignored when calculating PSPs
	sParams.intWorker = intWorker; %worker number
	sParams.dblAttention = dblAttention;
	sParams.intAttArea = intAttArea;
	sParams.dblPixNoise = dblPixNoise;
	sParams.boolIndRet = boolIndRet;
	sParams.intSaveLGN = intSaveLGN;
	
	%% load stimulus list
	[sStimParams,sStimInputs] = loadStimulation(strStimDir,strStimFile);
	
	%assign
	sParams.sStimParams = sStimParams;
	sParams.sStimInputs = sStimInputs;
	
	%msg
	printf('Loaded stimulation file <%s> [%s]\n',strStimFile,getTime);
	
	%% load connectivity
	[sConnParams,sConnectivity] = loadConnectivity_xArea(strConnDir,strConnFile);
	
	%assign
	sParams.sConnParams = sConnParams;
	sParams.sConnectivity = sConnectivity;
	sParams.strConnFile = strConnFile;
	
	% msg
	printf('Preparations complete; will be using connectivity matrix <%s> [%s]\n',strConnFile,getTime);
	
	%% seed random number generator
	rng('shuffle');
	intRandVals = randi(10^6);
	rng(intWorker);
	vecDummyVals = rand(1,intRandVals);clear vecDummyVals; %#ok<NASGU>
	sOut=rng;
	intSeed = sOut.Seed;
	intState = sOut.State(1);
	sParams.intSeed = intSeed;
	sParams.intState = intState;
	
	%% run simulation
	printf('Starting distributed run on compiled worker %d with random seed/state <%d/%d> [%s]\n',intWorker,intSeed,intState,getTime);
	
	%run
	if ~isa(dblMaxRunningTime,'uint64'),dblMaxRunningTime=dblMaxRunningTime-toc(hTic);end
	sData = getDynSimPrep(sParams,dblMaxRunningTime,intWorker);
	
	%trial + time vars
	sSimRun = struct;
	sSimRun.vecOverallT = sData.vecOverallT;
	cellFields = fieldnames(sData);
	for intField=1:numel(cellFields)
		strField = cellFields{intField};
		if ~isempty(strfind(strField,'vecTrial')) || ~isempty(strfind(strField,'vecStim'))
			sSimRun.(strField) = sData.(strField);
		end
	end
	
	%spiking
	sSimRun.cellSpikeTimesLGN_ON = sData.cellSpikeTimesLGN_ON;
	sSimRun.cellSpikeTimesLGN_OFF = sData.cellSpikeTimesLGN_OFF;
	sSimRun.cellSpikeTimesCortex = sData.cellSpikeTimesCortex;
	
	%save data
	if ispc
		strDataFile = [strOutputDir 'xMaster_'  strTag sStimParams.strStimType sprintf('_%03d_%d_%s.mat',intSeed,intState,getDate)];
		printf(' .. Saving data to <%s>... [%s]\n',strDataFile,getTime);
		%sParams = rmfield(sParams,{'sConnectivity'});
		save(strDataFile,'sSimRun','sParams','-v7.3');
	else
		strDataFile = [strOutputDir 'Simulation_' strTag sStimParams.strStimType sprintf('_%03d_%d_%s.mat',intSeed,intState,getDate)];
		printf(' .. Saving data to <%s>... [%s]\n',strDataFile,getTime);
		sParams = rmfield(sParams,{'sConnParams','sConnectivity','sStimParams','sStimInputs'});
		if ~intSaveLGN
			sSimRun = rmfield(sSimRun,{'cellSpikeTimesLGN_ON','cellSpikeTimesLGN_OFF'});
		end
		save(strDataFile,'sSimRun','sParams','-v7');
	end
	printf(' .. Data saved! [%s]\n',getTime);
	
	%catch ME
	%	printf('Error; ID: %s; msg: %s [%s]\n',ME.identifier,ME.message,getTime);
	%	fprintf('Error; ID: %s; msg: %s [%s]\n',ME.identifier,ME.message,getTime);
	%end
