/**********************************************************************
Name: ECM_UtilityClass
=======================================================================
Purpose: This class is used to update any records in System Mode.
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Manikandan.T    		 19/04/2021       Initial Developmemt
***********************************************************************/
public without sharing class ECM_UtilityClass {
    
    public static void updateContractInSystemMode(String conid){
        try{
            Contract conrec=[Select Id,Status from Contract where Id=:conid];
            conrec.Status='Approved';
        	update conrec;
        }catch(exception e){
            system.debug('error--->'+e.getMessage());
        }
        
    }
    
        
    public static void updateAddendumInSystemMode(ECM_Addendum__c legalRec){
        try{
        	update legalRec;
        }catch(exception e){
            system.debug('error--->'+e.getMessage());
        }
        
    }

}