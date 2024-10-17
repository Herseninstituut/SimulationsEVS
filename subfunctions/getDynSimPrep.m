function sData = getDynSimPrep(sParams,dblMaxRunningTime,intWorker)

%% prepare stimulus list
hTic = tic;
sStimParams = sParams.sStimParams;
sStimInputs = sParams.sStimInputs;
boolIndRet = sParams.boolIndRet;

%% build connectivity
sData = sParams.sConnectivity;

%% prepare variables for simulation
% run stitched together trials
intCortexCells = sData.intCortexCells;
vecThisV = randn([intCortexCells,1]) -55.6;
	
intLGN_CellsPerStream = size(sStimInputs.matBlankLGN_ON,1)*size(sStimInputs.matBlankLGN_ON,2);
cellSpikeTimesLGN_ON = cell(intLGN_CellsPerStream,1);
cellSpikeTimesLGN_OFF = cell(intLGN_CellsPerStream,1);
cellSpikeTimesCortex = cell(intCortexCells,1);

vecSpikeCounterLGN_ON = zeros(intLGN_CellsPerStream,1);
vecSpikeCounterLGN_OFF = zeros(intLGN_CellsPerStream,1);
vecSpikeCounterCortex = zeros(intCortexCells,1);

intPreAllocationSize = 1000;

%% assign to structure
%assign attention & pixel noise
sData.dblAttention = sParams.dblAttention;
sData.intAttArea = sParams.intAttArea;
sData.dblPixNoise = sParams.dblPixNoise;

%simulation run parameters
sData.dblDeltaT = sStimParams.dblDeltaT;
sData.dblSynSpikeMem = sParams.dblSynSpikeMem;

sData.vecThisV = vecThisV;
sData.boolStimPresent = 0;
sData.intPrevTrial = 0;
sData.intTrialT = 0;
sData.intIter = 0;
sData.cellSpikeTimesLGN_ON = cellSpikeTimesLGN_ON;
sData.cellSpikeTimesLGN_OFF = cellSpikeTimesLGN_OFF;
sData.cellSpikeTimesCortex = cellSpikeTimesCortex;
sData.vecSpikeCounterLGN_ON = vecSpikeCounterLGN_ON;
sData.vecSpikeCounterLGN_OFF = vecSpikeCounterLGN_OFF;
sData.vecSpikeCounterCortex = vecSpikeCounterCortex;
sData.intPreAllocationSize = intPreAllocationSize;

%stim params
sData.matBlankLGN_ON = sStimInputs.matBlankLGN_ON;
sData.matBlankLGN_OFF = sStimInputs.matBlankLGN_OFF;

sData.sStimParams = sStimParams;
sData.dblStimDur = sStimParams.dblStimDur;

sData.dblTrialDur = sStimInputs.dblTrialDur;
sData.varDeltaSyn = sStimInputs.varDeltaSyn;
sData.dblVisSpacing = sStimInputs.dblVisSpacing;

%trial timing
sData.vecTrialStartSecs = sStimInputs.vecTrialStartSecs;
sData.vecTrialEndSecs = sStimInputs.vecTrialEndSecs;
sData.vecStimStartSecs = sStimInputs.vecStimStartSecs;
sData.vecStimStopSecs = sStimInputs.vecStimStopSecs;

%stim type props
sData.matStimTypeCombos = sStimInputs.matStimTypeCombos;

%trial + time vars
cellFields = fieldnames(sStimInputs);
for intField=1:numel(cellFields)
	strField = cellFields{intField};
	if ~isempty(strfind(strField,'vecTrial')) || ~isempty(strfind(strField,'vecStim'))
		sData.(strField) = sStimInputs.(strField);
	end
end


%% run simulation
if ~isa(dblMaxRunningTime,'uint64'),dblMaxRunningTime=dblMaxRunningTime-toc(hTic);end
if boolIndRet
	sData = getDynSimRunIndInp(sData,dblMaxRunningTime,intWorker);
else
	sData = getDynSimRun(sData,dblMaxRunningTime,intWorker);
end

%% remove placeholder spike entries
cellSpikeTimesTemp = sData.cellSpikeTimesCortex;
for intN=1:numel(cellSpikeTimesTemp)
	if numel(cellSpikeTimesTemp{intN}) > 1
		cellSpikeTimesTemp{intN} = cellSpikeTimesTemp{intN}(~isnan(cellSpikeTimesTemp{intN}));
	else
		cellSpikeTimesTemp{intN} = [];
	end
end
sData.cellSpikeTimesCortex = cellSpikeTimesTemp;

cellSpikeTimesTemp = sData.cellSpikeTimesLGN_ON;
for intN=1:numel(cellSpikeTimesTemp)
	if numel(cellSpikeTimesTemp{intN}) > 1
		cellSpikeTimesTemp{intN} = cellSpikeTimesTemp{intN}(~isnan(cellSpikeTimesTemp{intN}));
	else
		cellSpikeTimesTemp{intN} = [];
	end
end
sData.cellSpikeTimesLGN_ON = cellSpikeTimesTemp;

cellSpikeTimesTemp = sData.cellSpikeTimesLGN_OFF;
for intN=1:numel(cellSpikeTimesTemp)
	if numel(cellSpikeTimesTemp{intN}) > 1
		cellSpikeTimesTemp{intN} = cellSpikeTimesTemp{intN}(~isnan(cellSpikeTimesTemp{intN}));
	else
		cellSpikeTimesTemp{intN} = [];
	end
end
sData.cellSpikeTimesLGN_OFF = cellSpikeTimesTemp;

%% save data
if nargout == 0
    strHome = mfilename('fullpath');
    strHome = strHome(1:(end-length(mfilename)));
    strOutputDir = [strHome 'SimResults' filesep];
    strDataFile = [strOutputDir 'Simulation_'  getFlankedBy(mfilename,'_',[]) sStimParams.strStimType sprintf('%s.mat',getDate)];
	printf(' .. Saving data to <%s>... [%s]\n',strDataFile,getTime);
	save(strDataFile,'sData','sStimInputs','sStimParams');
	printf(' .. Data saved! [%s]\n',getTime);
end

%end
%{
%plot spike times
figure
hold on
for intN=1:intCortexCells
	if numel(cellSpikeTimesCortex{intN}) > 0
		line([cellSpikeTimesCortex{intN};cellSpikeTimesCortex{intN}],repmat([intN-0.5;intN+0.5],[1 numel(cellSpikeTimesCortex{intN})]),'Color','k')
	end
end
%}
