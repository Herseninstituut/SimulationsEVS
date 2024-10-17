%runBuildConnectivity	Creates .mat file containing synaptic connectivity
%						and simulation parameters. Uses subfunction
%						buildConnectivity()
%
%You can set the simulation parameters and model connectivity by editing
%the fields of the sConnParams structure in this file. See the function
%buildConnectivity() for more information. This function effectively
%creates the "anatomy" of your model network, which you can then use to run
%a simulation.  
%
%Version History:
%2019-02-12 Updated name and help description [by Jorrit Montijn]

boolUseSmallExample = true;

%% add paths
strHome = fileparts(mfilename('fullpath'));
addpath(fullfile(strHome,'classics'), fullfile(strHome,'subfunctions'), fullfile(strHome,'general'));

%% msg
fprintf('Starting offline construction of connectivity profile... [%s]\n\n',getTime);

%% set connectivity parameters
sConnParams = struct;

sConnParams.intCellsV1 = 1200;
sConnParams.vecSizeInput = [256 256];
sConnParams.dblVisSpacing = 6.4/sConnParams.vecSizeInput(1);

% set connectivity parameters; synaptic weights/RF location variation
sConnParams.boolUseWeights = true;
sConnParams.boolUseRFs = true;
sConnParams.boolUseSFs = true;

%connection definition LGN
sConnParams.vecConnsPerTypeON = [2880 1920]; %[pyramid interneuron]
sConnParams.vecConnsPerTypeOFF = [2880 1920]; %[pyramid interneuron]

if boolUseSmallExample
    % sConnParams.intCellsV1 = 1200;
    % sConnParams.vecSizeInput = [5 5];
    % sConnParams.boolUseSFs = false;
    sConnParams.vecConnsPerTypeON = [72 48]/12; %[pyramid interneuron]
    sConnParams.vecConnsPerTypeOFF = [72 48]/12; %[pyramid interneuron]
end

sConnParams.dblSigmaW = 0.8;%1.29; %width of gabor response
sConnParams.dblSigmaL = sConnParams.dblSigmaW/5;%1.29; %length of gabor response
sConnParams.vecConductance_FromLGN_ToCort = [6.9 8.15]*(10^-3);%[7.1 8.3]*(10^-3); %to [pyramid interneuron]
sConnParams.vecMeanSynDelayFromLGN_ToCort = [10 5]/1000; %to [pyramid interneuron]
sConnParams.vecSDSynDelayFromLGN_ToCort = [7 3]/1000; %to [pyramid interneuron]

%V1 def
if sConnParams.boolUseSFs
	sConnParams.vecDefinitionV1SpatFreq = 8*(2.^[-4 -3 -2 -1 0]);%2.^[-3:1:1];
else
	sConnParams.vecDefinitionV1SpatFreq = 8*(2.^-2);%2.^[-3:1:1];
end
sConnParams.vecDefinitionV1CellTypes = [1 1 1 1 2]; %[1=pyramid 2=interneuron]
sConnParams.intColumns = sConnParams.intCellsV1 / (numel(sConnParams.vecDefinitionV1SpatFreq) * numel(sConnParams.vecDefinitionV1CellTypes)); %48 / 252 / 120 / 600
if ~isint(sConnParams.intColumns),error([mfilename ':ColumnsNotInteger'],'Number of cells requested is not divisable by mumber of tuning property combinations');end
sConnParams.vecDefinitionV1PrefOri = 0:pi/sConnParams.intColumns:(pi-pi/sConnParams.intColumns);

%cortical connectivity
%number of connections
dblScalingFactor = 6; %4
sConnParams.matConnCortFromTo(1,:) = [40 40]*dblScalingFactor; %from pyramid to [pyr inter]
sConnParams.matConnCortFromTo(2,:) = [30 30]*dblScalingFactor; %from interneuron to [pyr inter]

%conductances
dblRescaleConductances = 0.45;
sConnParams.matConductancesFromTo(1,:) = dblRescaleConductances*((0.006*[0.96 1.28])/dblScalingFactor); %from pyramid to [pyr inter]
sConnParams.matConductancesFromTo(2,:) = dblRescaleConductances*((0.006*[3.00 1.50])/dblScalingFactor); %from inter to [pyr inter]

%synaptic delays
sConnParams.dblDelayMeanCortToCort = 3/1000; %in ms
sConnParams.dblDelaySDCortToCort = 1/1000; %in ms

% locality of connectivity;
%1=most local, 0=proportional to similarity, -1=equal probability for all
sConnParams.vecLocalityLambda = [0 -0.5]; %[pyramid interneuron]

%V2 params
sConnParams.dblSpatialDropoffV1V2 = 0.8; %normpdf(vecX,0,0.8); zandvakili&kohn, 2015
sConnParams.dblSpatialDropoffInterneuronsV2 = 3; %for interneurons
sConnParams.intCellsV2 = 0;%sConnParams.intCellsV1;%round(sConnParams.intCellsV1/2);

%create cell-based parameters
sConnParams.vecDefinitionV2CellTypes = [1 1 1 1 2];
sConnParams.vecCellTypesV2 = repmat(sConnParams.vecDefinitionV2CellTypes,[1 ceil(sConnParams.intCellsV2/numel(sConnParams.vecDefinitionV2CellTypes))]);
sConnParams.vecCellTypesV2(sConnParams.intCellsV2+1:end) = [];
sConnParams.vecCellFractionsV2 = [0.8 0.2]; %[pyramid interneuron]

%V1=>V2
dblInterArealFactor = 2.5; %used to be 2.6 (2.8)
sConnParams.vecConnsPerTypeV1V2 = [48 32];%[48 32]; %from pyr to pyr/int
sConnParams.matConductancesFromToV1V2(1,:) = [1.1 1.6]*dblInterArealFactor; %from pyramid to [pyr inter]
sConnParams.matConductancesFromToV1V2(2,:) = [1.5 1.0]*dblInterArealFactor; %from inter to [pyr inter]

%synaptic delays
sConnParams.dblDelayMeanV1ToV2 = 4/1000; %in ms
sConnParams.dblDelaySDV1ToV2 = 1/1000; %in ms

%% build connectivity
sConnectivity = buildConnectivity(sConnParams);

%% save

if sConnParams.boolUseRFs && sConnParams.boolUseSFs && ~sConnParams.boolUseWeights
	strConnFile = sprintf('sConnSimilX_Ret%dCol%dN%dS%d_%s.mat',...
		sConnParams.vecSizeInput(1),sConnParams.intColumns,sConnectivity.intCortexCells,...
		numel(sConnectivity.vecSynExcInh),getDate);
else
	strConnFile = sprintf('sConnSimil_Ret%dLP%.1fLI%.1fCol%dN%dS%dW%dRF%dSF%d_%s.mat',...
		sConnParams.vecSizeInput(1),sConnParams.vecLocalityLambda(1),sConnParams.vecLocalityLambda(2),...
		sConnParams.intColumns,sConnectivity.intCortexCells,numel(sConnectivity.vecSynExcInh),...
		sConnParams.boolUseWeights,sConnParams.boolUseRFs,sConnParams.boolUseSFs,getDate);
end
strConnFile = sprintf('Conn%dN%d_%s.mat',...
		sConnParams.vecSizeInput(1),sConnectivity.intCortexCells,getDate);
	
strConnDir = fullfile(strHome,'Connectivity');

fprintf('Saving file [%s] to [%s]... [%s]\n',strConnFile,strConnDir,getTime);
save(fullfile(strConnDir,strConnFile),'sConnParams','sConnectivity');
fprintf('Done! [%s]\n',getTime);

%%
%Conn256N1200_2020-10-07.mat:
%Elapsed: 1135.7s; now at t=0.202s; mean rate (Hz): 1.639 (V1 Pyr); 0.889 (V1 Int); NaN (V2 Pyr); NaN (V2 Int) [14:01:13]
