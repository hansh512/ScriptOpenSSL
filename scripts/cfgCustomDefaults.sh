###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 27.05.2022
#
# Script: cfgCustumDefaults.sh 
#
#
# Version 1.0
#
# Purpose: Script for changing custom settings
################################################################################

sourceFileDir=$(dirname "$0");                  # directory files and sub directoris for installation of CA
caRootDir="$(dirname $sourceFileDir)";          # get the root ca root directory
helperScriptDir="${caRootDir}/scripts/helperScripts";
source "${helperScriptDir}/initCAinstallVars.sh";                   # read vars from input sh file
source "${helperScriptDir}/colorCodes.sh";                          # loading constants for color codes (echo commad)
if [ -f "${helperScriptDir}/customDef.sh" ]
then
    source "${helperScriptDir}/customVars.sh";                          # loading custom variables
else
    echo -e "${R_Blk}ERROR: Missing file ${helperScriptDir}/customVars.sh.${COLOR_Off}";
    echo 'Run the script request-certificate.sh to create the file customVars.sh.';
    exit;
fi;
source "${helperScriptDir}/commonFunctions.sh";                     # loading common functions

function configCustomDefaults
{    
    if [ -f "${helperScriptDir}/customDef.sh" ]
    then
        local doLoop=1;
        local cfgFName="${helperScriptDir}/customDef.sh";
        source $cfgFName;                                       # loading  value(s) for default behaviour
        while [ $doLoop -eq 1 ]
        do
            clear;
            echo -e "${Y_Blk}Do you want to skip the organization settings when creating a cert? ${COLOR_OFF}" ;           
            readVarInfo 'If yes type true, if no type false or hit ENTER if value is ok' 'skipProcessOrgSettings' 5 0 0 false;
            echo; 
            echo -e "${Y_Blk}Enter the directory where the issued certificates should be stored. ${COLOR_OFF}" ;           
            readVarInfo 'Enter a valid Linux directory path or hit ENTER if path is ok' 'issuedCertsDir' 0 0 0 false;
            echo 
            echo -e "${Y_Blk}Please verify the configuration setting${COLOR_Off}";
            echo "Skip organization settings:           ${skipProcessOrgSettings}";
            echo "Path to issued certificates:          ${issuedCertsDir}";
            giveYesNoConfirmation 'Are the entries correct? [y/n]: ' 'doLoop' 0;             
        done; # end while

        saverVars=0;
        giveYesNoConfirmation 'Do you want to save the data? [y/n]:' 'saverVars' 0;

        if [ $saverVars -eq 0 ]
        then
            echo "skipProcessOrgSettings=${skipProcessOrgSettings};" > $cfgFName;
            local saveError=0;
            if  [ $? -ne 0 ]
            then
                echo -e "${R_Blk}ERROR: Failed to write setting skipProcessOrgSettings to file ${cfgFName}${COLOR_Off}";
                local saveError=1;
            fi;            
            echo "issuedCertsDir='${issuedCertsDir}';" >> $cfgFName;
            if  [ $? -ne 0 ]
            then
                echo -e "${R_Blk}ERROR: Failed to write setting issuedCertsDir to file ${cfgFName}${COLOR_Off}";
                local saveError=1;
            fi;
            if [ $saveError -eq 0 ]
            then
                echo -e "${G_Blk}Successfully saved configuration to file ${cfgFName}${COLOR_Off}";
            fi;            
            else
                echo -e "${Y_Blk}Warning: Some data not saved!${COLOR_Off}";
            fi; # end save information        
    else
        clear;
        echo -e "${R_Blk}ERROR: Missing file ${helperScriptDir}/customDef.sh.${COLOR_Off}";
        echo 'Run the script request-certificate.sh to create the file customDef.sh.';
    fi;
}; # end function configCustomDefaults
configCustomDefaults;
