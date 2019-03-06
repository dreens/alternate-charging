nn=0;
for ii=[333:-32:45]
    nn=nn+1;

hold on
path = 'R:\Data\2018\Aug\Aug 15\';
% file = 'TrajectoryReduced.dat'; 
% file = 'slowing51 12kv with pin pair C4D5.dat'; 
% file = 'halfdensity.dat';
% file = '159mil_0G 12kV trajectory.dat';
file = ['SF Mode l=' num2str(ii) '.dat'];
scatfile = 'scatter_neoh.dat';
col=jet(10);
color = col(nn,:);
dots = 'o';
linestyle='none';
capsize = 10;
traceName = num2str(ii);
figNum = 105;
x_axis_shift = 0;
adjustlims = false;
plotTitle = 'phase angle 55 different effective length     08/15/2018';
yscale = 1;
pershot = true;
plotdavestyle = false;

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
    scatter=11;
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
    errorbardave((evap_time+x_axis_shift),yscale*trajectory_sub/(1+pershot*99),yscale*traj_sub_err/(1+pershot*99),'Color',color,'Marker',dots,'DisplayName',traceName,'CapSize',capsize);
else
    errorbar((evap_time+x_axis_shift),yscale*trajectory_sub/(1+pershot*99),yscale*traj_sub_err/(1+pershot*99),'Color',color,'DisplayName',traceName,'LineStyle',linestyle,'Marker',dots,'MarkerSize',10);
    xx=evap_time+x_axis_shift;
    yy=yscale*trajectory_sub/(1+pershot*99);
    %text(xx(find(yy==max(yy))),max(yy),num2str(ii),'fontsize',12,'Color',color)
end
if adjustlims
    l = min(evap_time);
    r = max(evap_time);
    xlim([1.1*l-.1*r 1.1*r-.1*l])
    ylim([0 max(max(yscale*trajectory_sub/(1+pershot*99)))*1.1])
end

grid on
    
xlabel('Time after decelerator off (us)','fontsize',12)
xlabel('Time after decelerator off (us)','fontsize',12)
ylabel('Population (Photons/Shot)','fontsize',12)
title(plotTitle,'fontsize',14)
legend('off');legend('toggle')

 s = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[ 0,-Inf,0, -0.1],...
               'Upper',[ Inf,Inf,50,0.1],...
               'Startpoint',[ 1 mean(evap_time) 25 0]);
    
    f = fittype('a*exp(-(x-b).^2/2/c^2)+d*0','options',s);
    [c2,gof2] = fit(evap_time,trajectory_sub'/100,f);
fitx=2000:0.1:5000;
plot(fitx,c2(fitx),'Color',color,'DisplayName','fitting')

area(2,nn)=c2.a*c2.c;


end
