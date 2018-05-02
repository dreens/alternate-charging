%% Do calculations with the capacitance matrix for our decelerator.
% This is a function to be run with ODE45
%
% Q = CVc
% Vr/R = CdVc/dt
% Vc + Vr = Vo
% (Vo-Vc)/R = CdVc/dt
% Vo = Vc + RCdVc/dt
% dVc/dt = (Vo-Vc)/RC

function Vp = odeVRC(t,V)
    Vo = 25e3*(t>0)*[0 1 -1 0]';
    R = 1.6e3;
    C = [206 -56 -64.5 -62 -33;-56 208 -65 -63 -37;-64.5 -65 210 -57 -33.5;-62 -63 -57 206 -33.5; -33 -37 -33.5 -33.5 140];
    C = C*1e-12;
    Vp = (C(1:4,1:4)^-1)*(Vo-V)/R;
end