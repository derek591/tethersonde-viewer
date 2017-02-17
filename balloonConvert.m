% Balloon Convert
clc; clear all; close all;

% initialize balloon data
playaBalloonSpring = struct('t',[],'P',[],'T',[],'RH',[],'Alt',[],'Spd',[],'Dir',[],'Batt',[],'theta',[],'dewPnt',[],'q',[],'MR',[],'Et',[]);

% location of data folders
%dataLocation = 'E:\MATERHORN_Raw\Other\Sage_Balloon_Fall\TMTArchive';
dataLocation = 'E:\MATERHORN_Raw\Other\Spring Playa Sonde\Spring Playa Sonde\Playa_sonde';

% find all folders that start with 201
folders = dir([dataLocation, '\201*']);

% iterate through all folders, load and vertically concatnate any available data
for ii = 1:numel(folders)
    ii/numel(folders)*100
    % find current folder
    currentFolder = [dataLocation, '\',folders(ii).name];
    
    % check for any available .dat files
    currentDataTable = dir([currentFolder,'\*.DAT']);
    
    % if no .dat files exist, continue
    if isempty(currentDataTable)
        continue
    end
    
    % find current file name
    currentFile = [currentFolder,'\',currentDataTable.name];
    
    % load local data
    [Time,P,T,RH,Alt,Spd,Dir,Batt,theta,dewPnt,q,MR,Et] = importfile(currentFile);
    
    % extract serial day number from the current folder
    dayNum = datenum(folders(ii).name(1:8),'yyyymmdd');
    
    % remove ':' from Time Strings, conver to numbers
    Time = str2num(char(regexprep(Time,':','')));
    
    % store hh, mm, ss
    hh = floor(Time./10000);
    mm = floor(Time./100)-hh*100;
    ss = Time - hh*10000 - mm*100;
    
    % find serial time
    serial_t = repmat(dayNum,numel(hh),1) + hh./24 + mm./1440 + ss./86400;
   
    % append data to structure
    playaBalloonSpring.t = [playaBalloonSpring.t; serial_t];
    playaBalloonSpring.P = [playaBalloonSpring.P; P];
    playaBalloonSpring.T = [playaBalloonSpring.T; T];
    playaBalloonSpring.RH = [playaBalloonSpring.RH; RH];
    playaBalloonSpring.Alt = [playaBalloonSpring.Alt; Alt];
    playaBalloonSpring.Spd = [playaBalloonSpring.Spd; Spd];
    playaBalloonSpring.Dir = [playaBalloonSpring.Dir; Dir];
    playaBalloonSpring.Batt = [playaBalloonSpring.Batt; Batt];
    playaBalloonSpring.theta = [playaBalloonSpring.theta; theta];
    playaBalloonSpring.dewPnt = [playaBalloonSpring.dewPnt; dewPnt];
    playaBalloonSpring.q = [playaBalloonSpring.q; q];
    playaBalloonSpring.MR = [playaBalloonSpring.MR; MR];
    playaBalloonSpring.Et = [playaBalloonSpring.Et; Et];
end