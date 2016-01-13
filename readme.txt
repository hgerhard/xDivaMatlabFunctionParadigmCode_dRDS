Notes about the Matlab Function Paradigm pmf_dRDS_correlatedFigure_variableBackgrd.m:

%   Code written by Holly Gerhard (2015/2016)
%
%   This is a dynamic random dot stereogram (dRDS) paradigm, which produces
%   a red-blue anaglyph stereo display. Blue = RIGHT eye
%
%   The stimulus has a correlated figure region which potentially modulates in depth
%   on a background whose correlation level can be any value from 0-1.
%
%   The code relies on psychtoolbox (PTB) to generate the stimulus images, 
%   so a version of PTB should be installed on the machine used to
%   display stimuli. See http://psychtoolbox.org/download/
%
%   NB: The code contains some workarounds for missing functionality in xDiva,
%   in some cases things will be hardcoded and should be edited or at least
%   read carefully before running your own experiment. You can find these
%   chunks of code in the .m file by searching for: "###".
%
%   The code also relies on a few directories being available in xDiva_MatlabFunctions/:
%   
%       HG_Images    		contains *.mat files where the stimulus images are stored 
%       HG_Infofiles 		contains *.txt files detailing the image parameters
%       HG_VideoMeasures 	contains *.txt files detailing video parameters
%          			  used in workarounds for missing xDiva functionality
%   
%
%   This is an xDiva Matlab Function paradigm, formatted following an
%   example function provided by Vladimir Vildavski & Mark Pettet:
%   pmf_ParadigmFunction.m. The following are relevant notes from that file:
%
%   -"pmf_" prefix is not strictly necessary, but helps to identify
%   functions that are intended for this purpose.
%
%   -First argument is string for selecting which subfunction to use
%   Additional arguments as needed for each subfunction
%
%   -Each subfunction must conclude with call to "assignin( 'base', 'output', ... )",
%   where value assigned to "output" is a variable or cell array containing variables
%   that xDiva needs to complete the desired task.