%% Solve Capacitance Matrix

V0 = 25e3*[-.5 -.5 .5 -.5];
R = 1.6e3;
times = linspace(0,2e-6,1e3);
[t, V] = ode45(@(t,V) oVRC(t,V,V0,R),times,[0 0 0 0]);

figure;
plot(t*1e6,(V0-V)/R)
xlabel('Time, (\mus)')
ylabel('Current (A)')
legend('Rod 1','Rod 2','Rod 3','Rod 4')
title('++gg to gg+-')
grid on

function Vp = oVRC(t,V,V0,R)
    Vo = V0'*(t>0);
    C = [206 -56 -64.5 -62 -33;-56 208 -65 -63 -37;-64.5 -65 210 -57 -33.5;-62 -63 -57 206 -33.5; -33 -37 -33.5 -33.5 140];
    C = C*1e-12;
    Vp = (C(1:4,1:4)^-1)*(Vo-V)/R;
end