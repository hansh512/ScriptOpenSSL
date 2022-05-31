###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 27.05.2022
#
# Script: createCAconf.sh 
#
#
# Version 1.0
#
# Purpose: Collects information for CA configuration
################################################################################

clear;
sourceFileDir=$(dirname "$0"); 
scriptRoot="${sourceFileDir}/scripts";                                  # root directory for scripts
helperScriptDir="${scriptRoot}/helperScripts";
source "${helperScriptDir}/colorCodes.sh";                              # load color codes for echo
source "${sourceFileDir}/prepCustomVars.sh";                            # load script file with function writeCustomCfgInfo
source "${helperScriptDir}/commonFunctions.sh";                         # load common functions
varConfFileName="${helperScriptDir}/customVars.sh";

if test -f "${varConfFileName}";                                        # test if custom configuration exist
then    
    source "${varConfFileName}";                                        # load custom configuration
    if [ -n $rootCADaysValid ]
    then
        rootCADaysValid=$(($rootCADaysValid/365));
    fi;
    if [ -n $signingCADaysValid ]
    then
        signingCADaysValid=$(($signingCADaysValid/365));
    fi;
fi;
writeCustomCfgInfo;                                                     # call function to create/edit custom configuration