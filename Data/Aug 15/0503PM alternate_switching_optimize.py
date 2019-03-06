# -*- coding: utf-8 -*-
"""

This script seeks to find the optimum initial speed and offset for
working with the valve in its current position.

- Dave Reens, 8/9/18

"""
from yepy import instruments, yeutil, output, alternateDecelerator
from time import sleep
from nidaqmx import AnalogOutputTask
import copy
import matplotlib.pyplot as plt
import matplotlib
import random

# Setup Decelerator, Timing Card
pb = instruments.PulseBlaster()
pb.add(5,[0],[22.6*pb.us])

# Setup the Analog Output Card for the PS voltage
if False: # Change to true if the AO card needs setting
    task = AnalogOutputTask()
    task.create_voltage_channel('Dev1/ao0', min_val=0.0, max_val=9)  #  5.3V corresponds to 8 kV
    task.configure_timing_sample_clock(rate=100000)
    task.write(100000*[12500/15000.0*10])


def decelProg(vi,vf,offDist):
    decelSeq = alternateDecelerator.normalMode
    decelSeq.calcPhase(vi,vf,57)
    decelSeq.calcTime()

    offset = offDist/vi
    for i in xrange(1,5):
        pb.add(i,*decelSeq.splitTimes(i,offset))

    pb.build()
    print decelSeq.phase
    return decelSeq

offset = decelProg(820,200,0.195)
#pb.plot()
#raw_input('Pause')

# Instantiate the Photon Counter
counter = instruments.Sr400()
counter.setRecords(100)

# This sets the DDGs that control the YAG, the experiment, and its Qswitch
instruments.setMasterRate(10)   #Hz

# Control when the experiment ends via DDGs.
ddgs = (instruments.delayGenerator('valve'), \
        instruments.delayGenerator('master-pulse'), \
        instruments.delayGenerator('rf-delay'))

# Laserfire gives the delay between absolute zero and laserfire, as set on the
# master DDG. This value is 0.0901781 for a 178us Qswitch delay and 10hz expt.
laserfire = ddgs[1].getDelay('C')
laserfire = laserfire[1]
decelSeq = alternateDecelerator.normalMode
print decelSeq.off
print 
def setdelay(delay):
    delay = laserfire - delay/pb.s # Convert to SI from PB units
    for d in ddgs:
        d.setDelay('A', 'T0', delay)

#setdelay(decelSeq.off+offset + 0.01/decelSeq.fvel*pb.s)
pb.build()
print offset
# After this point, files are created and the script is saved.
raw_input('Final Check! Enter when done.')


# Parameters to Vary
vinit = [805,810,815]
#distances = [.186 + i*.001 for i in range(-12,13,3)]  #dave's original scan
distances = [.186 + i*.001 for i in range(-6,7,2)]  # denser and more focusing scan
# Define output files, together with the tag that labels them.
o = output.output({0:'optimizing2_denser_scan_strong_focusing'})    

# Saves a copy of the script to the Data folder
yeutil.saveScript()

# Initialize Plot Window to monitor results
plt.ion()
plt.show()
cmap = matplotlib.cm.get_cmap('jet')
# Loop through speeds and measure peak heights
for (i,v) in enumerate(vinit):
    plt.subplot(131+i)
    plt.xlabel('Time from decelerator turn-off (us)')
    if not i:
        plt.ylabel('Signal (arb)')
    plt.title('Optimizing Valve Distance for v=%d' %(v))
    plt.draw()
    plt.grid(True)
    plt.pause(2)
    for dd in distances:
        ci = 1.0*distances.index(dd)/len(distances)
        decelSeq = decelProg(v,200,dd)
        delay = range(-15,20,5)
        toplot = []
        for d in delay:
            peak = (decelSeq.off+dd/v + 0.01/decelSeq.fvel)*pb.s
            setdelay(peak + d*pb.us)
            toplot += [o.take(counter,'%d\t%d\t%d' %(d,v,int(dd*1e3)),0)]
            #toplot += [random.randint(1,5)]
        plt.plot([dl*1e6 for dl in delay],toplot,c=cmap(ci),label='%dmm' %(int(dd*1e3)))
        plt.draw()
        plt.pause(.1)
plt.legend(bbox_to_anchor=(1.05, 1), loc=2)
plt.draw()
plt.pause(.1)
    
print 'DONE!\a'


