lengths = 333:-32:45;
peaks = zeros(length(lengths),2);
peaku = zeros(length(lengths),2);
areas = zeros(size(peaks));
areae = zeros(size(peaks));

for iii=1:length(lengths)
for jjj=1:2

hold on
path = 'Aug 15/';
mode = 'S=1';
if jjj==2
    mode = 'SF';
end
file = [mode ' Mode l=' num2str(lengths(iii)) '.dat'];
scatfile = 'scatter_neoh.dat';
col=jet(length(lengths)+1);
color = col(iii,:);
dots = '.o';
dots = dots(jjj);
capsize = 3;
traceName = [mode ' l=' num2str(lengths(iii))];
figNum = 1234;
x_axis_shift = 800-lengths(iii);
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

if lengths(iii)==max(lengths)
    trajectory_sub = trajectory_sub(11:end);
    traj_sub_err = traj_sub_err(11:end);
    evap_time = evap_time(11:end);
end


% First just nab the peak
[m,l] = max(trajectory_sub/100);
peaks(iii,jjj) = m;
peaku(iii,jjj) = traj_sub_err(l)/100;


% Now actually fit a gaussian
s = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[ 0,-Inf,0],...
               'Upper',[ Inf,Inf,50],...
               'Startpoint',[ 1 evap_time(l) 25]);
    
f = fittype('a*exp(-(x-b).^2/2/c^2)','options',s);
[c2,gof2] = fit(evap_time,trajectory_sub'/100,f);
er = confint(c2);
erc = (er(2,3) - er(1,3))/4;
era = (er(2,1) - er(1,1))/4;
fitx=2000:0.1:5000;
plot(fitx+x_axis_shift,c2(fitx),'Color',color,'DisplayName','fitting')

areas(iii,jjj)=c2.a*c2.c;
areae(iii,jjj)=sqrt((erc/c2.c)^2+(era/c2.a)^2)*areas(iii,jjj);



end
end
%%

% convert to "trap-time"
a = 197000; %m/s^2
vi = 810; %m/s
times = (vi-sqrt(vi^2-2*lengths*5e-3*a))/a;

%if false
figure
sf = areas(:,2);
s1 = areas(:,1);
h = errorbar(times'*1e3,sf./s1,sf./s1.*sqrt((areae(:,2)./sf).^2+(areae(:,1)./s1).^2),'bo--');
title('Enhancement Ratio for different Hold Times')
xlabel('Time in Eff. Trap (ms)')
ylabel('Enhancement Ratio')
grid on
%end

figure
sf = areas(:,2);
s1 = areas(:,1);
hold on
h1 = errorbar(times'*1e3,sf,areae(:,2),'bo--');
h2 = errorbar(times'*1e3,s1,areae(:,1),'ro--');
title('S=1, SF various Final Speeds')
xlabel('Time in Eff. Trap (ms)')
ylabel('Gaussian Fitted Area during Time of Flight')
grid on

