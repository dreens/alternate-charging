# -*- coding: utf-8 -*-
"""
This script is the second to make use of alternateDecelerator.py.

Here we simulate a varying length decelerator by using bunching stages initially.

- Dave Reens, 8/9/18

"""
from yepy import instruments, yeutil, output, alternateDecelerator
from time import sleep
from nidaqmx import AnalogOutputTask
import copy

# Setup Pulseblaster
pb = instruments.PulseBlaster()
pb.add(5,[0],[22.6*pb.us]) # Valve Fire Pulse

# Setup the Analog Output Card
# channel 0 sets the HV PS Voltage
#task = AnalogOutputTask()
#task.create_voltage_channel('Dev1/ao0', min_val=0.0, max_val=9)
#task.configure_timing_sample_clock(rate=100000)
#task.write(100000*[12500/15000.0*10])
# Channel 1 sets the amplitude for the valve driving pulse
task2 = AnalogOutputTask()
task2.create_voltage_channel('Dev1/ao1', min_val=0.0, max_val=8.75)
task2.configure_timing_sample_clock(rate=100000)
task2.write(100000*[8.75])

# Setup Decelerator
offset = 0.186/810
def decelProg(num,select):
    n = num/4
    if select == 'SF':
        decelSeq = alternateDecelerator.bunchFirstSF
        decelSeq.labelArray = 'xyzw'*n+'As'+'bjarbias'*(83-n)
    elif select == 'S=1':
        decelSeq = alternateDecelerator.bunchFirstS1
        decelSeq.labelArray = 'xyzw'*n+'A' + 'baba'*(83-n)
    else:
        raise ValueError('Select argument to function ' +\
                'decelProg must be one of the strings "SF" or "S=1"')
    decelSeq.calcVel(810,55)
    decelSeq.calcTime()
    #decelSeq.plot()

    for i in xrange(1,5):
        pb.add(i,*decelSeq.splitTimes(i,offset))
    pb.build()
    return decelSeq

decelSeq = decelProg(16,'S=1')

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


# Bunching Stages
numbers = yeutil.frange(0,320,32)

# Define output files, together with the tag that labels them.
files = {(n,'SF'):'SF Mode l=%d' %(333-n) for n in numbers}
files.update({(n,'S=1'):'S=1 Mode l=%d' %(333-n) for n in numbers})
o = output.output(files)    
f = yeutil.yeopen('Decel-offtimes')

# Saves a copy of the script to the Data folder
yeutil.saveScript()

# Loop through speeds and measure peak heights
for n in numbers:
    for mode in ['S=1','SF']:
        print mode
        print n
        decelSeq = decelProg(n,mode)
                
        # Modify laser fire window based on final speed
        full = 8e-3/decelSeq.fvel
        delay = yeutil.frange(-full/3,full/3,full/18)
        
        # Guess peak arrival, modify slightly for S=1
        peak = (decelSeq.off+offset + 0.008/decelSeq.fvel)*pb.s
        if mode == 'S=1':
                peak += ((180 - 2*55)*5e-3/180/decelSeq.fvel*pb.s)

        # Save absolute offset info to a file
        f.write('vi=%d\tvf=%d\tn=%d\tmode=%s\tdelay=%f\n'\
                %(810,decelSeq.fvel,n,mode,decelSeq.off+offset))
        f.flush()

        for d in delay:
            setdelay(peak + d*pb.s)
            for iiii in xrange(1):
                outval = peak + d*pb.s - decelSeq.off - offset
                outval /= pb.us
                outval = int(outval + .5)
                o.take(counter,'%d' %(outval),(n,mode))
f.close()
    
print 'DONE!\a'


