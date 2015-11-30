#!/bin/bash

cd ~/duality/metis-challenge/scripts/
python transform.py
python make_features.py
~/local/R-3.0.2/bin/Rscript model.R

