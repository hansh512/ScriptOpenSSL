###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 25.05.2022
#
# Script: initCAInstallVars.sh 
#
#
# Version 1.0
#
# Purpose: Script with variables used for the initialization of the CA's
################################################################################

# variables used for CA installation (root and signing)
rootCADirName='root-ca';                            # name of the directory for the root CA
signingCADirName='signing-ca';                      # name of the directory for the signing CA

confFileRootCAName='root-ca.conf';                  # name of the conf file for the root CA
confFileSigningCAName='signing-ca.conf';            # name of the conf file for the signing CA

rootCAcertName='root-ca.crt';                       # name of the root CA certificate file
rootCAKeyName='root-ca.key';                        # name of the root CA key file
rootCACSRName='root-ca.csr';                        # name of the root CA csr file

signingCAcertName='signing-ca.crt';                 # name of the signing CA certificate file
signingCAKeyName='signing-ca.key';                  # name of the signing CA key file
signingCACSRName='signing-ca.csr';                  # name of the signing CA csr file

# variables used for certificate deployment
# line numbers for informations in cert conf file (if inappropriate changed, will break script)
baseInfoHeaderLineNum=5;
extInfoHeaderLineNum=6;

# length of the private key for certs to issiue - value is used, if not found in conf file
defCertPrivateKeyLength=2048;
# validity period of cert in days - value is used, if not found in conf file
defCertValidInDays=365;

