###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 25.05.2022
#
# Script: cfgOrganizationSettings.sh 
#
#
# Version 1.0
#
# Purpose: Script for configure settings for certificate subject name
################################################################################

clear;
sourceFileDir=$(dirname "$0"); 
scriptRoot="${sourceFileDir}";                                  # root directory for scripts
helperScriptDir="${scriptRoot}/helperScripts";

source "${helperScriptDir}/colorCodes.sh";                              # load color codes for echo
#source "${helperScriptDir}/prepCustomVars.sh";                          # load script file with function writeCustomCfgInfo
source "${helperScriptDir}/commonFunctions.sh";                         # load common functions
varConfFileName="${helperScriptDir}/customVars.sh";

if test -f "${varConfFileName}";                                           # test if custom configuration exist
then    
    source "${varConfFileName}";                                            # load custom configuration
    if [ -n $rootCADaysValid ]
    then
        rootCADaysValid=$(($rootCADaysValid/365));
    fi;
    if [ -n $signingCADaysValid ]
    then
        signingCADaysValid=$(($signingCADaysValid/365))
    fi;
fi;
configOrganizationData;                                                     # call function to edit organizational settings
saverVars=0;
giveYesNoConfirmation 'Do you want to save the data? [y/n]:' 'saverVars' 0;

if [ $saverVars -eq 0 ]
then
    saveConfigData;
else
    echo -e "${Y_Blk}Data not saved!${COLOR_Off}";
    #outerLoop=0;
fi; # end save information