# -*- coding: utf-8 -*-
"""
Created on Tue Jul 24 18:09:26 2018

@author: Cold_OH
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Apr 23 15:49:09 2018

@author: Cold_OH
"""
# The code is used to toggle between 6kV and 0kV
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 08 09:58:42 2018

@author: Cold_OH
"""
from yepy import instruments, yeutil, output
from time import sleep
from nidaqmx import AnalogOutputTask
from numpy import *
import time, copy
pb = instruments.PulseBlaster()
scope=instruments.Tds7154()

scope.single_mode()
scope.average_mode(840)  # 1400 records for 600/600
#scope.trigger()
# Instantiate the Photon Counter


task = AnalogOutputTask()
task.create_voltage_channel('Dev1/ao0', min_val=0.0, max_val=8)  #  5.3V corresponds to 8 kV
task.configure_timing_sample_clock(rate=100000)

task2=AnalogOutputTask()
task2.create_voltage_channel('Dev1/ao1', min_val=0.0, max_val=8.86)  #  5.3V corresponds to 8 kV
task2.configure_timing_sample_clock(rate=100000)


counter = instruments.Sr430()
counter.restoreSettings()
counter.setRecords(20)

counter2=instruments.Sr400()
counter2.setRecords(100)
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

# Laser Delay Function
def setdelay(delay):
    delay = laserfire - ( + delay)/pb.s # Convert to SI from PB units
    for d in ddgs:
        d.setDelay('A', 'T0', delay)


setdelay(2300*pb.us)

# Put a pulse on to test by scope.
# Argon
#pb.add(1,[100*pb.us],[400*pb.us])
#pb.add(4,[502*pb.us],[2420*pb.us])

# Neon
#pb.add(4,[150*pb.us],[130*pb.us])
#pb.add(1,[300*pb.us],[400*pb.us])
#pb.addmore(4,[702*pb.us],[1820*pb.us])
pb.add(5,[0*pb.us],[22.6*pb.us]) # valve



# 
def settiming(period):
        pb.add(1,[0],[2800*pb.us])
        pb.add(2,[0],[10*pb.us])
        pb.add(3,[0],[2800*pb.us])
        pb.add(4,[0],[10*pb.us])
        for i in xrange(int(float(2500/period))):
            starttiming=252-10
            #period=244
            #pb.addmore(1,[starttiming*pb.us+i*period*pb.us],[period*pb.us/4])
            pb.addmore(2,[starttiming*pb.us+i*period*pb.us],[period*pb.us/10])
            #pb.addmore(3,[starttiming*pb.us+i*period*pb.us],[period*pb.us/4])
            pb.addmore(4,[starttiming*pb.us+i*period*pb.us],[period*pb.us/10])
            pb.build()

def settiming2(period):
        pb.add(1,[0],[2800*pb.us])
        pb.add(2,[0],[2800*pb.us])
        pb.add(3,[0],[2800*pb.us])
        pb.add(4,[0],[2800*pb.us])

        pb.build()




pb.build()

#raw_input('Final Check!')
# Saves a copy of the script to the Data folder
yeutil.saveScript()

#delays = yeutil.frange(2760,3240,40) for Argon
delays333 = yeutil.frange(2200,2450,25)  # for neon
#delays=linspace(2200,2450,6)
delays333=linspace(2200,2400,6)
#delays=[2350]
delays40 = yeutil.frange(472,526,20)
delays40=linspace(472,504,6)



delays=empty((delays333.size+delays40.size),dtype=delays333.dtype)
delays[0::2]=delays40
delays[1::2]=delays333
#voltages = yeutil.frange(2400,4200,600)
voltages=[500,2000,4000,8000]
voltages=[12000]
#task.write(100000*[9000/15000.0*10])
def alarm():
    print '\a'*5

#densitytable=[8.2, 8.86, 8.1, 8.45, 7.8]

#densitytable=[8.25, 8.86, 8.1, 8.45, 8.65] # 5 points measurment 5/18/2018
densitytable=[8.75,7.9,8.1,8.35, 8.45, 8.55,8.25,8.65]
OHfiles40 = {(v,'OH40'):'10% 6&1p5kV 40th stage OH 22p60us 8K skimmer 60us 7 cycles 250psi density ' + str(int(round(v*10))) for v in densitytable}
OHfiles333 = {(v,'OH333'):'10% 6&1p5kV 333th stage OH 22p60us 8K skimmer 60us 7 cycles 250psi density ' + str(int(round(v*10))) for v in densitytable}


Nefiles = {(v,'Ne'):'10% 1p5kV Ne 22p60us 8K skimmer 250psi density ' + str(int(round(v*10))) for v in densitytable}

files = copy.deepcopy(OHfiles40)
files.update(OHfiles333)
files.update(Nefiles)
o = output.output(files)    
def takescatter(counter,v,file):
    setdelay(1000*pb.us)
    o.take(counter,'%d' %(-1),(v,'OH' '%s'%(file)))
def valve_length(time):
    
    ddgs[1].setDelay('B', 'A', delaypb.s)
xtime=scope.xaxis()*1e6

settiming(195.2)
#settiming2(195.2)

for v in densitytable:

    out1 = o.filehandles[(v,'Ne')]


        
    for m in xtime:
        out1.write('%.3f\t' %(m))
    out1.write('\n')
    out1.flush()
        #time.sleep(0.1)

#raw_input('Final Check! Enter when done.')

set=1
while True:
 for density in densitytable:
    task2.write(100000*[density]) 
    #raw_input('Final Check! Enter when done.')

    sleep(1)
  # for v in voltages:
#    alarm()
#    pb.add(1,[20*i*pb.us for i in range(100)],[10*pb.us]*100)
#    pb.build()
    
    #task.write(100000*[v/15000.0*10])
    #sleep(30)
    sleep(0.1)
    #raw_input('Set voltage to %s V. Then ENTER.' %(str(v)))
    #print '%dV' %v
#    pb.add(1,[300*pb.us],[400*pb.us])
#    pb.build()
    print density
    for i in range(set):
        scope.trigger()
        time.sleep(0.1)
        takescatter(counter,density,40)
        for d in delays:
            setdelay(d*pb.us)
            time.sleep(0.1)
            if d <900:
                o.take(counter,'%d' %(d),(density,'OH40'))
            else:
                o.take(counter2,'%d' %(d),(density,'OH333'))
            
            
        takescatter(counter2,density,333)   
               

        vec=scope.readChannel(3)
        out1 = o.filehandles[(density,'Ne')]


        
        for m in vec:
                    out1.write('%.3f\t' %(m))
        out1.write('\n')
        out1.flush()
        time.sleep(2)





        


