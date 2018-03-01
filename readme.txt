@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Author: Elyh Lapetina               @
@ Date: 2/8/2018                      @
@ Rev: 1.0                            @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Description:
The scripts contained in the CBCTCalibrationCode folder is used to calibrate sets of DiCOM files taken from dental CBCT machines. 
_____
StandardCalc.m:
This is the main entry point for the script. In order to run the script, open this file in Matlab and click run. Once the script is open, it will as the user to select the directory of DiCOM files the user's local disk. 

The user can scan through the DiCOM slides by dragging the slider at the bottom of the UI. The user may change views as desired by clicking any of the view buttons. 

The user may take a measurement by clicking the take measurement button. Before this is done, the user must select the first and last slide to average over. This is done by clicking "Mark 1" and "Mark 2". Once this is one, the UI will flip to the first "Mark" and allow the user to  select the center of the first circle to be average. The UI will then put the second "marked" slide into the view, the user will then select the center of the second circle. Once marked, the script will prompt the user to enter the radius of the circle.

The user may also generate a set of calibrated images. This description will be added once the UI elements have been fully worked out.

_____
DICOM2Volumn.m:
This script iterates through each  DiCOM file and constructs an array that contains directory of each format in an ordered fashion.

_____

Generate3dMatrixCBCT.m:
This script takes input from the DICOM2Volume script and constructs a three-dimensional array where each index represents a voxel and contains the grayscale value of the represented voxel.
_____
CircularAVG.m:
This script returns the average value pixel for the area of pixels defined by an X,Y and R location. This function averages values based on a given radius, all values within the radius will be averaged. 

_____
ModelView.m:
The purpose of this function is to allow the user to visual a region of interest in three-dimensions. This script takes a three-dimensional array which is used to generate Matlab Isocaps. The user may adjust what values of Grayscale values are in view by adjusting the slider at the bottom of the UI.

_____
StandardCalc.m:
This is a standalone script that enables the user to easily calculate the predicted HU of HaPe standards based on percent-mass and the effective energy of the scanner. 



