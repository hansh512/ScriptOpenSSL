###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 30.05.2022
#
# Script: prepCustomVars.sh 
#
#
# Version 1.0
#
# Purpose: Provides function for createCAconf.sh
################################################################################

function writeCustomCfgInfo
{
    
    echo 'Collecting some data for CA setup.'
    outerLoop=1;
    basicLoopVal=0;
    confLoopVal=0;
    custLoopVal=0;
    
    if test -f "${varConfFileName}";                                           # test if custom configuration exist
    then
        echo -e "${Y_Blk}Edit Configurations${COLOR_Off}"
        echo -e "Press ${G_Blk}1${COLOR_Off} for Basic Configuration";
        echo -e "Press ${G_Blk}2${COLOR_Off} for CA Installation Configuration";
        echo -e "Press ${G_Blk}3${COLOR_Off} for Organizational Configuration";
        echo -e "Press ${G_Blk}4${COLOR_Off} for All Configuration";
        echo -e "Press ${Y_Blk}c${COLOR_Off} Cancel";
        echo 'Type the number of the configuration you want to edit, 4 for all configurations or 0 to cancel.'
       
        choiceLoop=1;
        while [ $choiceLoop -eq 1 ]
        do
             read  -n 1 -p "Your selection: " cfgNum;
            case $cfgNum in
            '1')
                basicLoopVal=1;
                choiceLoop=0;
                clear;
                break;
            ;;
            '2')
                confLoopVal=1;
                choiceLoop=0;
                clear;
                break;
            ;;            
            '3')
                custLoopVal=1;
                choiceLoop=0;
                clear;
                break;
            ;;
            '4')
                basicLoopVal=1;
                confLoopVal=1;
                custLoopVal=1;
                choiceLoop=0;
                clear;
                break;
            ;;'c')
                outerLoop=0;
                choiceLoop=0;
                echo;
                exit;
            ;;
            *)
            echo -e "\n${R_Blk}Invalid choice${COLOR_Off}";            
            ;;
            esac;
        done; # choiceLoop;
    else            
        basicLoopVal=1;
        confLoopVal=1;
        custLoopVal=1;                
    fi;

    while [ $outerLoop -eq 1 ]
    do              
        echo -e "${G_Blk}Collecting basic configuration information${COLOR_Off}" 
        getInfoLoopBasic=$basicLoopVal;
        while [ $getInfoLoopBasic -eq 1 ]
        do                                    
    	    #################### collect basic information ###########################
            # readVarInfo promptText variableName numOfChar isInteger removeTrailingSlash
            echo -e "\n${Y_Blk}Collecting directory and URL information${COLOR_Off}" 
            readVarInfo 'Please enter the root directory for the CA installation (e.g. /volume1/ca)' 'caRootDir' 0 0 1 false;  
            readVarInfo 'Please enter URL for the certificate revocation list (e.g. http://crl.your-company.com)' 'crlBaseDir' 0 0 1 false;  
            readVarInfo 'Please enter URL for the AIA (e.g. http://aia.your-company.com)' 'aiaBaseDir' 0 0 1 false;     

            echo -e "\n${Y_Blk}Directory and URL confgiuration${COLOR_Off}"
            echo -e "Root directory for CA installation:    ${caRootDir}";
            echo -e "Base URL for CRL:                      ${crlBaseDir}";
            echo -e "Base URL for AIA:                      ${aiaBaseDir}";
            confirmLoop=1;
            giveYesNoConfirmation 'Is the list with the directory entries correct? [y/n]: ' 'getInfoLoopBasic' 0;
            if [ $x -eq 2 ]; then
            echo 'should not be'
            while [ $confirmLoop -eq 1 ]
            do
                read  -n 1 -p "Is the list with the directory entries correct? [y/n]: " tmpAnswer;
                echo
                case $tmpAnswer in
                    'y')
                        confirmLoop=0;
                        getInfoLoopBasic=0;
                        break;
                    ;;
                    'n')                            
                        confirmLoop=0;
                        getInfoLoopBasic=1;
                    ;;
                esac; # case y/n
            done; # confirmLoop (confirm data is ok) 
            fi; # end dummy           
        done; # info loop get base data (directory, URL)

        #ca validity periods
        #################### collect CA information ###########################
        clear;
        echo -e "${Y_Blk}Collecting validity period information for root and signing ca${COLOR_Off}" ;
        getInfoLoopCaConf=$confLoopVal; 
        while [ $getInfoLoopCaConf -eq 1 ]
        do                                                            
            echo -e "${G_Blk}Collecting configuration for root CA.${COLOR_Off}";
            # readVarInfo promptText variableName numOfChar isInteger removeTrailingSlash
            readVarInfo 'Please enter the validity period in YEARS for the root CA' 'rootCADaysValid' 0 1 0 false; 
            readVarInfo 'Please enter the CRL validity period in DAYS for the root CA' 'rootCACRLDaysValid' 0 1 0 false;  
            readVarInfo 'Please enter the common name (cn) for the root CA' 'customDefault_RootCAName' 0 0 0 false; 
            readVarInfo 'Please enter the name for the root CA CRL file (e.g. root-ca.crl)' 'rootCACrlName' 0 0 0 false; 
            readVarInfo 'Please enter the name for the root CA AIA file (e.g. root-ca-aia.cer)' 'rootCAaiaName' 0 0 0 false; 
            echo -e "\n${G_Blk}Collectin configuration for signing CA.${COLOR_Off}";
            readVarInfo 'Please enter the validity period in YEARS for the signing CA' 'signingCADaysValid' 0 1 0 false;   
            readVarInfo 'Please enter the CRL validity period in DAYS for the signing CA' 'signingCACRLDaysValid' 0 1 0 false; 
            readVarInfo 'Please enter the common name (cn) for the signing CA' 'customDefault_SigningCAName' 0 0 0 false;
            readVarInfo 'Please enter the name for the signing CA CRL file (e.g. signing-ca.crl)' 'signingCACrlName' 0 0 0 false; 
            readVarInfo 'Please enter the name for the signing CA AIA file (e.g. signing-ca-aia.cer)' 'signingCAaiaName' 0 0 0 false;   

            echo -e "\n${G_Blk}Root CA${COLOR_Off}"
            echo -e "Root CA valid in years:            ${rootCADaysValid}";
            echo -e "Root CA CRL valid in days:         ${rootCACRLDaysValid}";
            echo -e "Root ca common name:               ${customDefault_RootCAName}";
            echo -e "Root ca CRL file name:             ${rootCACrlName}";
            echo -e "Root ca AIA file name:             ${rootCAaiaName}";
            echo -e "\n${G_Blk}Signing CA${COLOR_Off}"
            echo -e "Signing CA valid in years:         ${signingCADaysValid}";
            echo -e "Signing CA CRL valid in days:      ${signingCACRLDaysValid}";
            echo -e "Signing ca common name:            ${customDefault_SigningCAName}";
            echo -e "Signing ca CRL file name:          ${signingCACrlName}";
            echo -e "Signing ca AIA file name:          ${signingCAaiaName}";
            confirmLoop=1;
            giveYesNoConfirmation 'Are the root and signing CA configuration correct? [y/n]: ' 'getInfoLoopCaConf' 0;
            clear;
        done; # info loop get base data (directory, URL)

        #################### collect organizational information ###########################
        if [ $custLoopVal -eq 1 ]
        then
            configOrganizationData;
            clear;
        fi;
        #################### verify that data should be saved ###########################            
        echo -e "${G_Blk}Summarizing  collectede data for OpenSSL CA installation${COLOR_Off}";
        echo -e "${Y_Blk}Basic data:${COLOR_Off}";
        echo "Root directory for CA installation:   ${caRootDir}";
        echo "Base URL for CRL:                     ${crlBaseDir}";
        echo "Base URL for AIA:                     ${aiaBaseDir}";
        echo;
        echo -e "${Y_Blk}Root CA installation${COLOR_Off}";
        echo "Root CA valid in years:               ${rootCADaysValid}";
        echo "Root CA CRL valid in days:            ${rootCACRLDaysValid}";
        echo "Root ca common name:                  ${customDefault_RootCAName}";
        echo "Root ca CRL file name:                ${rootCACrlName}";
        echo "Root ca AIA file name:                ${rootCAaiaName}";
         echo -e "${Y_Blk}Signing CA installation${COLOR_Off}";
        echo "Signing CA valid in years:            ${signingCADaysValid}";
        echo "Signing CA CRL valid in days:         ${signingCACRLDaysValid}";
        echo "Signing ca common name:               ${customDefault_SigningCAName}";
        echo "Signing ca CRL file name:             ${signingCACrlName}";
        echo "Signing ca AIA file name:             ${signingCAaiaName}";
        echo
        echo -e "${Y_Blk}Organizational information -  a dot means not present in certificate subject${COLOR_Off}";
        echo "Country code:                         ${customDefault_defCountryCode}";
        echo "Provice:                              ${customDefault_defProvince}";
        echo "Location:                             ${customDefault_defLocation}";
        echo "Organizational unit:                  ${customDefault_defOU}";
        echo "Organization:                         ${customDefault_defOrganization}"
        askForSaveDataLoop=1;

        giveYesNoConfirmation 'Do you want to save the data? [y/n]:' 'outerLoop' 0;

        if [ $outerLoop -eq 0 ]
        then
            saveConfigData;            
        else
            echo -e "${Y_Blk}Data not saved!${COLOR_Off}";
            outerLoop=0;
        fi; # end save information

    done; # outer loop
}; # end funciton writeCustomCfgInfo
