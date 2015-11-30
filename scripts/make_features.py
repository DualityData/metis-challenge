#setup a standard image size; this will distort some images but will get everything into the same shape
STANDARD_SIZE = (200, 200)
def img_to_matrix(filename):
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

    return img

def flatten_image(img):
    """
    takes in an (m, n) numpy array and flattens it 
    into an array of shape (1, m * n)
    """
    s = img.shape[0] * img.shape[1]
    img_wide = img.reshape(1, s)
    return img_wide[0]


import os
import numpy as np
from PIL import Image
from sklearn.decomposition import RandomizedPCA
import random
import pdb

#PCA on training set
#3968 total images (dropping image id 1974). Using 2500 as training, remainder test. 
#img_dir = '/home/hgera000/duality/metis-challenge/beetrain/'
img_dir = '/home/hgera000/duality/metis-challenge/beetrain_hsv/'
sort_dir = sorted(os.listdir(img_dir),key=lambda x: int(x.split('.')[0]))
random.seed(1666)
#pdb.set_trace()
random.shuffle(sort_dir)
train_dir = sort_dir[0:2500]
test_dir = sort_dir[2500:]

images = [img_dir+ f for f in train_dir]
names = [int(f.split('/')[-1].split('.')[0]) for f in images]

data = []
for image in images:
    print(image)
    img = img_to_matrix(image)
    img = flatten_image(img)
    data.append(img)

data = np.array(data)


pca = RandomizedPCA(n_components=50,random_state=4289) 
Xtrain = pca.fit_transform(data)
print("Variation explained is %s" % pca.explained_variance_ratio_.sum())
np.savetxt("../data/pca.grey.train.csv", Xtrain, delimiter=",")
np.savetxt("../data/names.grey.train.csv", np.array(names), delimiter=",")

#PCA on test set
images = []
images = [img_dir+ f for f in test_dir]
names = [int(f.split('/')[-1].split('.')[0]) for f in images]

data = []
for image in images:
    #print(image)
    img = img_to_matrix(image)
    img = flatten_image(img)
    data.append(img)

data = np.array(data)

#use the previously fitted PCA model on test set. 
Xtest = pca.transform(data)
np.savetxt("../data/pca.grey.test.csv", Xtest, delimiter=",")
np.savetxt("../data/names.grey.test.csv", np.array(names), delimiter=",")
