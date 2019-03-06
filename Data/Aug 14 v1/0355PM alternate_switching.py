# -*- coding: utf-8 -*-
"""
This script is the first to make use of alternateDecelerator.py.

It computes deceleration sequences for generalized charge configurations.

- Dave Reens, 8/6/18

"""
from yepy import instruments, yeutil, output, alternateDecelerator
from time import sleep
from nidaqmx import AnalogOutputTask
import copy


# Setup Timing Card
pb = instruments.PulseBlaster()
pb.add(5,[0],[22.6*pb.us]) # start the valve

# Setup the Analog Output Card for the PS voltage
task = AnalogOutputTask()
task.create_voltage_channel('Dev1/ao0', min_val=0.0, max_val=9)  #  5.3V corresponds to 8 kV
task.configure_timing_sample_clock(rate=100000)
task.write(100000*[12500/15000.0*10])

# Setup Decelerator
decelSeq = alternateDecelerator.delayMode

def decelProg(vi,vf,select):
    if select == 'SF':
        decelSeq = alternateDecelerator.delayMode
    elif select == 'S=1':
        decelSeq = alternateDecelerator.normalMode
    decelSeq.calcPhase(vi,vf,57)
    decelSeq.calcTime()

    offset = 0.186/810
    for i in xrange(1,5):
        pb.add(i,*decelSeq.splitTimes(i,offset))

    pb.build()
    print decelSeq.phase
    return offset

offset = decelProg(810,50,'SF')

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

def setdelay(delay):
    delay = laserfire - delay/pb.s # Convert to SI from PB units
    for d in ddgs:
        d.setDelay('A', 'T0', delay)

setdelay(decelSeq.off+offset + 0.008/decelSeq.fvel*pb.s)
pb.build()
print decelSeq.off+offset
# After this point, files are created and the script is saved.
raw_input('Final Check! Enter when done.')


# Final Speeds
vf = range(800,0,-50)

# Define output files, together with the tag that labels them.
files = {(v,'SF'):'SF Mode vf=%d' %(v) for v in vf}
files.update({(v,'S=1'):'S=1 Mode vf=%d' %(v) for v in vf})
o = output.output(files)    
f = yeutil.yeopen('Decel-offtimes')

# Saves a copy of the script to the Data folder
yeutil.saveScript()

# Loop through speeds and measure peak heights
for v in vf:
    for mode in ['S=1','SF']:
        decelProg(810,v,mode)
        f.write('vi=%d\tvf=%d\tmode=%s\tdelay=%f\n'\
                %(810,v,mode,decelSeq.off+offset))
        full = 8e-3/v
        delay = yeutil.frange(-full,full,full/7)
        for d in delay:
            peak = (decelSeq.off+offset + 0.008/decelSeq.fvel)*pb.s
            setdelay(peak + d*pb.s)
            for ii in xrange(1):
                o.take(counter,'%.2f' %(d*1e6),(v,mode))
f.close()
    
print 'DONE!\a'


