%% Solve Capacitance Matrix

V0 = 25e3*[-1 -1 2 0]/2;
R = 1.6e3;
Rb = 100;
times = linspace(0,2e-6,1e3);
[t, V] = ode45(@(t,V) oVRC(t,V,V0,R),times,[0 0 0 0]);

figure;
Pb = ((V0-V)/R).^2*Rb;
Eb = trapz(t,Pb);
plot(t*1e6,Pb*1e-3,'LineWidth',2)
xlabel('Time, (\mus)','FontSize',16)
ylabel('Power (kW)','FontSize',16)
r = {};
for i=1:4
    r{i} = sprintf('Rod %d, E = %1.1f mJ',i,1e3*Eb(i));
end
a = legend(r{1},r{2},r{3},r{4});
set(a,'FontSize',16);
set(gca,'FontSize',16);
title('++-- to gg+-','FontSize',16)
grid on

function Vp = oVRC(t,V,V0,R)
    Vo = V0'*(t>0);
    C = [206 -56 -64.5 -62 -33;-56 208 -65 -63 -37;-64.5 -65 210 -57 -33.5;-62 -63 -57 206 -33.5; -33 -37 -33.5 -33.5 140];
    C = C*1e-12;
    Vp = (C(1:4,1:4)^-1)*(Vo-V)/R;
end