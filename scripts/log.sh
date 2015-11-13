#!/bin/bash

cd ~/duality/metis-challenge/scripts/
python make_features.py &&  ~/local/R-3.0.2/bin/Rscript model.R

