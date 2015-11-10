from __future__ import division
import os
import numpy as np
from PIL import Image
import colorsys

#convert to grey_scale keeping yellow. 
STANDARD_SIZE = (200, 200)
def img_to_greyscale(filename):
    """
    takes a filename and turns it into a numpy array of RGB pixels
    """
    img = Image.open(filename)
    
    if img.size[0] != 200 or img.size[1] != 200:
        img = img.resize(STANDARD_SIZE)
        print "changing size from %s to %s" % (str(img.size), str(STANDARD_SIZE))
    
    img = list(img.getdata())
    img = map(list, img)
    img = np.array(img) #dimensions 40,000 by 3
    #here convert to HSV scale
    img_hsv = [colorsys.rgb_to_hsv(*x/255) for x in img]
    #set pixels not in yellow range to black.
    img_hsv = [(0, 0, 0) if (x[0]*360 < 40 or x[0]*360 > 79) else (x[0], x[1], x[2]) for x in img_hsv]
    img_rgb = [colorsys.hsv_to_rgb(*x) for x in img_hsv] #re-convert to rgb
    img_rgb = [(int(x[0]*255),int(x[1]*255),int(x[2]*255)) for x in img_rgb]
    
    im = Image.new("RGB", (200,200))
    im.putdata(img_rgb)
    im.save("/home/hgera000/duality/metis-challenge/modified2/%s.jpeg" % filename.split('/')[-1].split('.')[0] )

    return 1


img_dir = '/home/hgera000/duality/metis-challenge/beetrain/'
sort_dir = sorted(os.listdir(img_dir),key=lambda x: int(x.split('.')[0]))[0:2000]
images = [img_dir+ f for f in sort_dir]
for image in images:
    img = img_to_greyscale(image)


