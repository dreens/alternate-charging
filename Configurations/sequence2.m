function out=sequence2(ss,phi0,phif)
% 1st colume: x; 2nd colume: 3rd: z; 4th: domain; 5th: E-field (V/m)

all_n = load([ss '.mat']);
amp=all_n.aenergy;
L=5;

for phi=-90:1:0
z=phi/180*L;

energy(phi+91)=amp(phi);
end
phi_all=[0:1:360];

energy_all=[flip(energy) energy(2:end-1) flip(energy) energy(2:end)];
amp_z0=interp1(phi_all,energy_all,phi0:1:phif);

out=[(phi0:1:phif)*L/180;amp_z0];
                  
