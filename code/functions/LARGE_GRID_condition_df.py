#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  5 16:57:07 2018

@author:  kgross
"""

import functions.add_path
import os

import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
from plotnine import *
from plotnine.data import *

import functions.et_preprocess as preprocess
import functions.et_helper as  helper
import functions.make_df as  make_df
from functions.detect_events import make_blinks,make_saccades,make_fixations

import logging


#%% Create large_grid_df for all subjects


def get_complete_large_grid_df(subjectnames, ets):
    # make the df for the large GRID for both eyetrackers and all subjects
    
    # create df
    complete_large_grid_df = pd.DataFrame()
        
    for subject in subjectnames:
        for et in ets:
            logging.critical('Eyetracker: %s    Subject: %s ', et, subject)
            
            # load preprocessed data for one eyetracker and for one subject
            etsamples, etmsgs, etevents = preprocess.preprocess_et(et,subject,load=True)
            
            # adding the messages to the event df
            merged_events = helper.add_msg_to_event(etevents, etmsgs, timefield = 'start_time')
                       
            # make df for grid condition that only contains ONE fixation per element
            # (the last fixation before the new element  (used a groupby.last() to achieve that))
            large_grid_df = make_df.make_large_grid_df(merged_events)          
            
            # add a column for eyetracker and subject
            large_grid_df['et'] = et
            large_grid_df['subject'] = subject
            
            # concatenate to the complete df
            complete_large_grid_df = pd.concat([complete_large_grid_df,large_grid_df])
                   
    return complete_large_grid_df


