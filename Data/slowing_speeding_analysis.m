vfs = 50:50:1200;
peaks = zeros(length(vfs),2);
peaku = zeros(length(vfs),2);
for iii=1:length(vfs)
for jjj=1:2

hold on
if vfs(iii)<825
    path = 'Aug 15/';
else
    path = 'Aug 16/';
end
mode = 'S=1';
if jjj==2
    mode = 'SF';
end
file = [mode ' Mode vf=' num2str(vfs(iii)) '.dat'];
scatfile = 'scatter_25p5.dat';
col=jet(length(vfs));
color = col(iii,:);
dots = '.o';
dots = dots(jjj);
capsize = 3;
traceName = [mode ' vf=' num2str(vfs(iii))];
figNum = 123;
x_axis_shift = vfs(iii);
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

% Now actually fit a gaussian
s = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[ 0,min(evap_time),0],...
               'Upper',[ Inf,max(evap_time),100],...
               'Startpoint',[ 1 evap_time(l) 25]);
    
f = fittype('a*exp(-(x-b).^2/2/c^2)','options',s);
[c2,gof2] = fit(evap_time,trajectory_sub'/100,f);
er = confint(c2);
erc = (er(2,3) - er(1,3))/4;
era = (er(2,1) - er(1,1))/4;
fitx=-1000:0.4:1000;
plot(fitx+x_axis_shift,c2(fitx),'Color',color,'DisplayName','fitting')

areas(iii,jjj)=c2.a*c2.c;
areae(iii,jjj)=sqrt((erc/c2.c)^2+(era/c2.a)^2)*areas(iii,jjj);




end
end
%%
figure
sf = areas(:,2);
s1 = areas(:,1);
%h = errorbar(vfs',sf./s1,sf./s1.*sqrt((1./sf)+(1./s1))/sqrt(100),'bo--');
h = errorbar(vfs',sf./s1,sf./s1.*sqrt((areae(:,2)./sf).^2+(areae(:,1)./s1).^2),'bo--');
title('Enhancement Ratio across various Final Speeds')
xlabel('Final Speed (m/s)')
ylabel('Enhancement Ratio')
grid on

%%
figure
vfs = 50:50:1200;
sf = peaks(:,2);
s1 = peaks(:,1);
vfs3 = 550:50:900;
s3 = (s1(1:3:end) + 2*sf(1:3:end))/2;
hold on
h1 = errorbar(vfs',s1,sqrt(s1)/sqrt(100),'o--');
h2 = errorbar(vfs3',s3,sqrt(s3)/sqrt(100),'o--');
h3 = errorbar(vfs',sf,sqrt(sf)/sqrt(100),'o--');
%title('S=1, SF various Final Speeds')
xlabel('Final Speed (m/s)')
ylabel('Peak Time of Flight')
grid on

% Going to run with the separate traces and add mock data for VSF for now.
vsf = peaks(:,2)*2.5;
vfs = 50:50:1250;
vsf(end-2:end+1) = [12 9 5 0];

h4 = errorbar(vfs',vsf,2*sqrt(vsf)/sqrt(100),'o--');

set(gca,'FontSize',13)
set(gca,'LineWidth',2)
set(gca,'TickLength',[.02 .05])

name = 'Data-Figure-Final-Speed';
print(gcf,'Data-Figure-Final-Speed','-dpng','-r300')
system('open .png')
system('cp Figures/5x2-PSD-Compare.png ../alternate-charging/')

