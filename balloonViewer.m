%% Balloon Data Viewer
% Fall 2012 - MATERHORN
clc; clear all; close all;
load playaBalloonFall.mat
load sageBalloonFall.mat
figure
plot(playaBalloonFall.t-7/24,ones(size(playaBalloonFall.t)),'k.',sageBalloonFall.t-7/24,2*ones(size(sageBalloonFall.t)),'b.')
ylim([0.99 2.01])
set(gca,'xtick',datenum(2012,9,24):datenum(2012,10,23),'ytick',[])
title('Available Periods')
legend('Playa','Sage')
changeFig(12,2)
datetick('keepticks')
display('Possible Variables')
display(fields(playaBalloonFall))
%% User Inputs
site = 'playa'; % 'playa' or 'sage'
startTime = datenum(2013,05,1,16,00,00);  % LST
duration = 300;  % number of minutes to plot
variable = 'theta'; % variable of interest.  Run Code Block 1 (lines 1:15) for available dates and variables.  Input exact string! 
binSize = 20; % vertical binning size in meters
%% analysis
if strcmp(site,'playa')
    data = playaBalloonFall;
else
    data = sageBalloonFall;
end

% put data in LST
data.t = data.t - 7/24;

% find closest time stamp
[minStartVal, startIndex] = min(abs(startTime-data.t));

% find closest time stamp to period + duration
[minEndVal, endIndex] = min(abs(startTime+duration/1440-data.t));

% check to make sure that the minEndVal is smaller than the minStartVal
if minStartVal > 3/24 || minEndVal > 3/24 || startIndex == endIndex
    error('No data exists for this period!')
end

% store local data
local_z = data.Alt(startIndex:endIndex);
local_variable = data.(variable)(startIndex:endIndex);
local_t = data.t(startIndex:endIndex);

% plot local_z
figure
subplot(2,1,1)
title('Unsmoothed Data')
plot(local_z)

% QC local_z
local_z(local_z > 1900 | local_z < 1250) = nan;
slopeFlag = false(size(local_z));
% iterate through local_z, nan outliers and flag weak slopes
for jj = 20:20:numel(local_z)
    
    % eliminate outliers
    % z
    z_values = local_z(jj-19:jj);
    z_stndDev = nanstd(z_values);
    z_values(abs(z_values - nanmean(z_values))>2*z_stndDev) = nan;
    z_polyX = 1:numel(z_values);
    z_temp = polyfit(z_polyX(~isnan(z_values)),z_values(~isnan(z_values))',1);
    % variable of interest
    var_values = local_variable(jj-19:jj);
    var_stndDev = nanstd(var_values);
    var_values(abs(var_values - nanmean(var_values))>3*var_stndDev) = nan;
    var_polyX = 1:numel(var_values);
    var_temp = polyfit(var_polyX(~isnan(var_values)),var_values(~isnan(var_values))',1);
    
    % find ascent/descent slope and flag if too small
    slope = abs(z_temp(1));
    if slope < .15 && nanmean(z_values) < 1330
        slopeFlag(jj-19:jj) = true;
    end
    
    % place corrected data back into local_z
    local_z(jj-19:jj) = z_values;
    local_variable(jj-19:jj) = var_values;
end

% remove low slope data
local_z(slopeFlag) = [];
local_variable(slopeFlag) = [];
local_t(slopeFlag) = [];

% initialize smooth variables
smooth_z = nan(numel(local_z)-10,1);
smooth_theta = smooth_z;
smooth_t = smooth_z;

% use running average to smooth data
for jj = 6:numel(local_z)-5
    smooth_z(jj-5) = nanmean(local_z(jj-5:jj+5));
    smooth_var(jj-5) = nanmean(local_variable(jj-5:jj+5));
    smooth_t(jj-5) = nanmean(local_t(jj-5:jj+5));
end

[pksLocs, pks] = peakfinder(smooth_z,50);
[vllysLocs, vllys] = peakfinder(-smooth_z);
% plot QC'd data
subplot(2,1,2)
plot(smooth_z)
title('Smoothed Data - Verify Peaks and Valleys!')
xlabel('n')
hold all
plot(pksLocs,pks,'k^','markerfacecolor',[1 0 0])
plot(vllysLocs,-vllys,'k^','markerfacecolor',[0 0 1])
changeFig(18,2)

% sort valleys and peaks into 1 array
peaksAndValleys = [pks; vllys;];
peaksAndValleysLocs = [pksLocs; vllysLocs];
[peaksAndValleysLocs, index] = sort(peaksAndValleysLocs);
peaksAndValleys = abs(peaksAndValleys(index));

% iterate through valleys and peaks
colors = flipud(jet(numel(peaksAndValleys)-1));
figure
for jj = 1:numel(peaksAndValleys)-1
    profStartIndex = peaksAndValleysLocs(jj);
    profEndIndex = peaksAndValleysLocs(jj+1);
    
    % find jjth profiles
    varProfile = local_variable(profStartIndex:profEndIndex);
    zProfile = local_z(profStartIndex:profEndIndex);
    
    % use -- linestyle for balloon descents
    if zProfile(1) > zProfile(end)
        lineStyl = '--';
    else
        lineStyl = '-';
    end
    
    binnedVar = [];
    binned_z = [];
    
    % bin over usere slected bin increments
    for kk = min(zProfile):binSize:max(zProfile)
        binRows = find(zProfile>=kk & zProfile<kk+binSize);
        binnedVar(end+1) = nanmean(varProfile(binRows));
        binned_z(end+1) = nanmean(zProfile(binRows));
    end
    
    % assign legend time stamp
    M{jj} = [datestr(local_t(profStartIndex+5),'HH:MM'),' - ',datestr(local_t(profEndIndex-5),'HH:MM')];
    plot(binnedVar,binned_z,'color',colors(jj,:),'linestyle',lineStyl)
    hold on
end
title([site,':  ',datestr(local_t(1),'dd-mmm-yy'),'  LST   ''--''=Descent'])
legend(M)
xlabel(variable)
changeFig(18,2)
hold off