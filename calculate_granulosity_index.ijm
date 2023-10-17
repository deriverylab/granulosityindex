macro "Fourrier_spotology" {
	
//This code needs one stack as input and eventually one or more regions of interest (ROIs)
//stack: raw data (cells or in vitro). Single channel, and can be a movie.
//Rois: put as many ROIs in the ROI manager as you want. If you don't put any the whole image will be processed
//

// the output will be in a text file (and the log) giving you per time point SD fourrier (Granulosity Index) for all ROI

//------input parameters----------
backsub=100; //do camera offset substraction
//--------------------------------

raw=getImageID();
getDimensions(width, height, channels, slices, frames);
dir=getInfo("image.directory");
image=getInfo("image.filename");

// get appropriate radius
Dialog.create("What kind of data are you processing?");
Dialog.addChoice("Select an option:", newArray("Cell images", "In vitro images"));
Dialog.show();

option = Dialog.getChoice();
if (option=="Cell images"){
	radius=70;
	};
else if (option=="In vitro images"){
	radius=40;
};

run("Clear Results");
run("Set Measurements...", "mean standard display redirect=None decimal=3");
print("\\Clear");
print("ROI","\t","timepoint","\t","Mean","\t","STD fourrier","\t","mean fourrier filter","\t","STD fourrier/mean real space (Granulosity Index)","\t","Radius fourrier");

//background subtraction

run("Select All");
run("Subtract...", "value="+backsub+" stack");


nroi=roiManager("count");
if (nroi==0) {
	//print("no ROI in ROI manager, process with full image instead");
	run("Select All");
	roiManager("Add");
	wholeROI=1;
	nroi=1;
}else {
	wholeROI=0;
}

if (frames>1 || slices>1 ) {
	Dialog.create("Stack detected");
Dialog.addCheckbox("Process entire stack?", 1);
Dialog.show();
stackmode=Dialog.getCheckbox();
if (frames==1 && slices>1 ) {   //if the stack is in Z and not in T for some reason
Stack.setDimensions(channels, frames,slices);
getDimensions(width, height, channels, slices, frames);
}
}else {
stackmode=0;
}

setBatchMode(true);

if (stackmode==1) {

for (iroi = 0; iroi < nroi; iroi++) {
for (i = 1; i < frames+1; i++) {
	run("Clear Results");
selectImage(raw);
run("Select None");
run("Duplicate...", "duplicate range="+i+"-"+i);
temp=getImageID();
selectImage(temp);
roiManager("select", iroi);
run("Measure");
run("Select All");
run("32-bit");
run("FFT");
rename("FFT");
run("Make Circular Selection...", "radius="+radius);
run("Cut");
run("Inverse FFT");
rename("iFFT");
roiManager("select", iroi);
run("Measure");
if (wholeROI==0) {
	print("Roi "+iroi,"\t",i,"\t",getResult("Mean", 0),"\t",getResult("StdDev", 1),"\t",getResult("Mean", 1),"\t",getResult("StdDev", 1)/getResult("Mean", 0),"\t",radius);
}else {
	print("Entire frame","\t",i,"\t",getResult("Mean", 0),"\t",getResult("StdDev", 1),"\t",getResult("Mean", 1),"\t",getResult("StdDev", 1)/getResult("Mean", 0),"\t",radius);
}


selectWindow("FFT");
close();
selectWindow("iFFT");
close();
selectImage(temp);
close();
}
}
}else {
	Stack.getPosition(channel, slice, currentframe);
	for (iroi = 0; iroi < nroi; iroi++) {
	run("Clear Results");
selectImage(raw);
run("Select None");
run("Duplicate...", "duplicate range="+currentframe+"-"+currentframe);
temp=getImageID();
selectImage(temp);
roiManager("select", iroi);
run("Measure");
run("Select All");
run("32-bit");
run("FFT");
rename("FFT");
run("Make Circular Selection...", "radius="+radius);
run("Cut");
run("Inverse FFT");
rename("iFFT");
roiManager("select", iroi);
run("Measure");
if (wholeROI==0) {
	print("Roi "+iroi,"\t",currentframe,"\t",getResult("Mean", 0),"\t",getResult("StdDev", 1),"\t",getResult("Mean", 1),"\t",getResult("StdDev", 1)/getResult("Mean", 0),"\t",radius);
}else {
	print("Entire frame","\t",currentframe,"\t",getResult("Mean", 0),"\t",getResult("StdDev", 1),"\t",getResult("Mean", 1),"\t",getResult("StdDev", 1)/getResult("Mean", 0),"\t",radius);
}


selectWindow("FFT");
close();
selectWindow("iFFT");
close();
selectImage(temp);
close();
}
	
}

selectWindow("Log");
saveAs("Text", dir+image+"_fourrier"+radius+".txt");
}
