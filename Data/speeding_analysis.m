vfs = 850:50:1200;
peaks = zeros(length(vfs),2);
peaku = zeros(length(vfs),2);
for iii=1:length(vfs)
for jjj=1:2

hold on
path = 'Aug 16/';
mode = 'S=1';
if jjj==2
    mode = 'SF';
end
file = [mode ' Mode vf=' num2str(vfs(iii)) '.dat'];
scatfile = 'scatter_25p5.dat';
col=jet(18);
color = col(iii,:);
dots = '.o';
dots = dots(jjj);
capsize = 3;
traceName = [mode ' vf=' num2str(vfs(iii))];
figNum = 123;
x_axis_shift = 800-vfs(iii);
adjustlims = false;
plotTitle = 'Denser Scan in vf, volcano skimmer, 8/15/18';
yscale = 1;
pershot = true;
plotdavestyle = true;

fulldata = importdata([path file],'\t',0);
%fulldata = fulldata.data;
fulldata = fulldata(1:end,:);

%photon counter glitched on first point only.
%fulldata = fulldata([1:99 101:end],:);

%pull scatter from separate file
try
    scatdata = importdata([path scatfile],'\t');
catch
    scatdata = [];
end
if isempty(scatdata)
    scatter=10;
    scat_err=0.;
else
   scatdata = scatdata(:,2);
   scatter =  mean(scatdata);
   scat_err =std(scatdata)./sqrt(size(scatdata,1));
end


%total lines in the file
total_num = size(fulldata,1);
fulldata = fulldata(1:total_num,:);

%the x and y colums from the file- delay and number
alldelay = fulldata(:,1);
allcounts = fulldata(:,2);

%delay contains all the delays at which data was taken.
delay = unique(alldelay);
num_delays = size(delay,1);
    
%Here we again utilize boolean indexing to average all measurements of a
%given frequency together and also get their deviation.
trajectory = zeros(1,num_delays);
traj_err = zeros(1,num_delays);
for i=1:num_delays
    tempcounts = allcounts(alldelay==delay(i));
    trajectory(i) = mean(tempcounts);
    traj_err(i) = std(tempcounts)./sqrt(size(tempcounts,1));
end


%Express in the length (ms) that evaporation had progressed before count
%we shouldn't start from .1901781 because that is before the molecules are
%even in the trap. Evap trajectories should start from the time of
%trapping.
%laser_fire=0.1901781;  %unit second
%OH_loading_time=3.807*1e-3;  %unit second
%evap_time = (laser_fire-OH_loading_time-delay);
%evap_time = delay*1e-6-100;
evap_time=delay;
%speed = 11300/(-103+400+3457-3437)

trajectory_sub = trajectory - scatter;
traj_sub_err = sqrt(traj_err.^2 + scat_err^2);

scale = trajectory_sub(end);

if figNum==0
    figuredave
else
    figure(figNum)
end

n=size(trajectory_sub,2);
hold on
%plot((evap_time+x_axis_shift),trajectory_sub/100,'Color',color,'Marker',dots,'DisplayName',traceName)
if plotdavestyle
    errorbar((evap_time+x_axis_shift),yscale*trajectory_sub/(1+pershot*99),yscale*traj_sub_err/(1+pershot*99),'Color',color,'Marker',dots,'DisplayName',traceName,'CapSize',capsize);
else
    errorbar((evap_time+x_axis_shift),yscale*trajectory_sub/(1+pershot*99),yscale*traj_sub_err/(1+pershot*99),'Color',color','Marker',dots,'DisplayName',traceName);
end
if adjustlims
    l = min(evap_time);
    r = max(evap_time);
    xlim([1.1*l-.1*r 1.1*r-.1*l])
    ylim([0 max(max(yscale*trajectory_sub/(1+pershot*99)))*1.1])
end

grid on
    
xlabel('Time after valve fire (us)','fontsize',12)
xlabel('Time after valve fire (us)','fontsize',12)
ylabel('Population (Photons/Shot)','fontsize',12)
title(plotTitle,'fontsize',14)
legend('off');legend('toggle')

[m,l] = max(trajectory_sub/100);
peaks(iii,jjj) = m;
peaku(iii,jjj) = traj_sub_err(l)/100;

end
end
%%
%if false
figure
sf = peaks(:,2);
s1 = peaks(:,1);
h = errorbar(vfs',sf./s1,sf./s1.*sqrt((1./sf)+(1./s1))/sqrt(100),'bo--');
title('Enhancement Ratio across various Final Speeds')
xlabel('Final Speed (m/s)')
ylabel('Enhancement Ratio')
grid on
%end

figure
sf = peaks(:,2);
s1 = peaks(:,1);
hold on
h1 = errorbar(vfs',sf,sqrt(sf)/sqrt(100),'bo--');
h2 = errorbar(vfs',s1,sqrt(s1)/sqrt(100),'ro--');
title('S=1, SF various Final Speeds')
xlabel('Final Speed (m/s)')
ylabel('Peak Time of Flight')
grid on

