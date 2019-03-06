# -*- coding: utf-8 -*-
"""
This script studies phi2, the second phase that alternate sequences make 
available for tuning.

- Dave Reens, 8/16/18

"""
from yepy import instruments, yeutil, output
from yepy import alternateDecelerator as ad
from nidaqmx import AnalogOutputTask


# Setup Timing Card
pb = instruments.PulseBlaster()
pb.add(5,[0],[22.6*pb.us]) # start the valve
#pb.build()
# Setup the Analog Output Card for the PS voltage
#task = AnalogOutputTask()
#task.create_voltage_channel('Dev1/ao0', min_val=0.0, max_val=9)  #  5.3V corresponds to 8 kV
#task.configure_timing_sample_clock(rate=100000)
#task.write(100000*[12500/15000.0*10])

task2 = AnalogOutputTask()
task2.create_voltage_channel('Dev1/ao1', min_val=0.0, max_val=8.75)  #  5.3V corresponds to 8 kV
task2.configure_timing_sample_clock(rate=100000)
task2.write(100000*[8.75])



# Setup Decelerator
delayPhi2 = {\
    'i':('+ggg','p-180','180-2*p+q'),\
    'j':('g-gg','p-180','180-2*p+q'),\
    'a':('+-gg','-p+q','2*p-q'),\
    'A':('+-gg','-90','90+p'),\
    'r':('gg+g','p','180-2*p+q'),\
    's':('ggg-','p','180-2*p+q'),\
    'b':('gg+-','180-p+q','2*p-q')}
decelSeq = ad.Sequence('As'+'bjarbias'*83,delayPhi2,ad.D333)
offset = 0.186/810
def decelProg(phi2):
    decelSeq.phi2 = phi2
    decelSeq.calcPhase(810,100)
    decelSeq.calcTime()
    #decelSeq.plot()

    for i in xrange(1,5):
        pb.add(i,*decelSeq.splitTimes(i,offset))

    pb.build()
    #pb.plot()
    print decelSeq.phase

decelProg(10)


# Instantiate the Photon Counter
counter = instruments.Sr400()
counter.setRecords(100)
counter.setRate(10)

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


# Phase Angles
p2 = range(-20,21,5)
p2 *= 5

# Define output files, together with the tag that labels them.
files = {i:'SF Mode vf=100, p2=%d' %(i) for i in p2}
#files.update({(v,'S=1'):'S=1 Mode vf=%d' %(v) for v in vf})
o = output.output(files)    
f = yeutil.yeopen('Decel-offtimes')

# Saves a copy of the script to the Data folder
yeutil.saveScript()

# Loop through speeds and measure peak heights
for p in p2:
    decelProg(p)
    f.write('vi=%d\tvf=%d\tmode=%s\tdelay=%f\n'\
            %(810,100,'SFq',decelSeq.off+offset))
    f.flush()
    
    full = 6e-3/100.0
    delay = yeutil.frange(-full,full,full/7)

    for d in delay:
        
        dist = 11e-3 - decelSeq.offPhi*5e-3/180
        peak = (decelSeq.off+offset + dist/decelSeq.fvel)*pb.s
        #print peak

        setdelay(peak + d*pb.s)
        for ii in xrange(1):
            o.take(counter,'%.2f' %(d*1e6),p)
f.close()
    
print 'DONE!\a'


