#!/bin/bash

cd ~/duality/metis-challenge/scripts/
python transform.py #make greyscale versions of train and test images and save yellow/orange colour pixel features.
python make_features.py #pca on the training set, extrapolate to test set. run twice. 
~/local/R-3.0.2/bin/Rscript model.R

