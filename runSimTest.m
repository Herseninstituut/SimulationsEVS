%% load data
strConnNew = 'Conn256N1200.mat'; 
strStimNew = 'Ret256Noise1.0Ori160_x9R1.mat'; 
load(fullfile('Connectivity', strConnNew ));
load(fullfile('Stimulation', strStimNew));

%% plot response of example cell
intNeuron=320;
dblPrefSF = sConnectivity.vecPrefSF(intNeuron);
matGrid = zeros(sConnParams.vecSizeInput);
%add off
indSyn = sConnectivity.matSynConnOFF_to_Cort(:,2)==intNeuron;
vecSourceOff = sConnectivity.matSynConnOFF_to_Cort(indSyn,1);
vecW = sConnectivity.vecSynWeightOFF_to_Cort(indSyn);
vecC = sConnectivity.vecSynConductanceOFF_to_Cort(indSyn);
[vecRow,vecCol]=ind2sub(sConnParams.vecSizeInput,vecSourceOff);
matGridOff = getFillGrid(matGrid,vecRow,vecCol,vecC);
%add on
indSyn = sConnectivity.matSynConnON_to_Cort(:,2)==intNeuron;
vecSourceON = sConnectivity.matSynConnON_to_Cort(indSyn,1);
vecW = sConnectivity.vecSynWeightON_to_Cort(indSyn);
vecC = sConnectivity.vecSynConductanceON_to_Cort(indSyn);
[vecRow,vecCol]=ind2sub(sConnParams.vecSizeInput,vecSourceON);
matGridOn = getFillGrid(matGrid,vecRow,vecCol,-vecC);

%% plot
intImX = sConnParams.vecSizeInput(1);
intImY = sConnParams.vecSizeInput(2);
dblVisSpacing = sConnParams.dblVisSpacing;
vecSpaceX = dblVisSpacing*((-(intImX - 1)/2):(intImX - 1)/2);
vecSpaceY = dblVisSpacing*((-(intImY - 1)/2):(intImY - 1)/2);
	
figure
imagesc(vecSpaceX,vecSpaceY,(matGridOn + matGridOff))
axis xy
daspect([1 1 1])
colorbar
dblPrefOri = sConnectivity.vecPrefOri(intNeuron);
dblPrefSF = sConnectivity.vecPrefSF(intNeuron);
dblPrefRF_X = sConnectivity.vecPrefRF_X(intNeuron);
dblPrefRF_Y = sConnectivity.vecPrefRF_Y(intNeuron);
dblPrefPsi = sConnectivity.vecPrefPsi(intNeuron);

title(sprintf('N%d: %s=%d; %s=%.3f; x=%.3f; y=%.3f, %s=%.3f',intNeuron,...
	getGreek('theta'),rad2deg(dblPrefOri),...
	getGreek('xi'),dblPrefSF,...
	dblPrefRF_X,...
	dblPrefRF_Y,...
	getGreek('psi'),dblPrefPsi));
xlabel('Azimuth visual space (degs)');
ylabel('Elevation visual space (degs)');
fixfig;
grid off;

return
%% export
export_fig(sprintf('C%s_ExampleN%d.tif',strConnNew(14:(end-4)),intNeuron));
export_fig(sprintf('C%s_ExampleN%d.pdf',strConnNew(14:(end-4)),intNeuron));

%% test

tic
sStimDriveOld = getDynBottomUpInputs(sStimParams,1);
toc

%%
tic
sStimDrivePeter = getDynBottomUpInputs(sStimParams,0);
toc
%%
figure
%for t=190:size(sStimDriveOld.matLGN_ON,3)
vecT = (sStimParams.dblDeltaT:sStimParams.dblDeltaT:(sStimParams.dblStimDur*2))-(sStimParams.dblStimDur/2);
vecIntT = [210 400 500 600 700];
for intPlot=1:5
	t = vecIntT(intPlot);
	
	subplot(3,5,intPlot)
imagesc(sStimDriveOld.matImage(:,:,t));colorbar
title(sprintf('Image; old;t=%.3fs',vecT(t)))

subplot(3,5,intPlot+5)
imagesc(sStimDriveOld.matLGN_ON(:,:,t));colorbar
title(sprintf('ON; old;t=%.3fs',vecT(t)))

subplot(3,5,intPlot+10)
imagesc(sStimDrivePeter.matLGN_ON(:,:,t));colorbar
title(sprintf('ON; Peter;t=%.3fs',vecT(t)))
drawnow
end

%%
figure
subplot(2,1,1)
plot(squeeze(sStimDriveOld.matLGN_ON(round(end/2),round(end/2),:)))

subplot(2,1,2)
plot(squeeze(sStimDrivePeter.matLGN_ON(round(end/2),round(end/2),:)))
sprintf('done')
