/**********************************************************************
Name: ECM_ExtraApprovalTriggerHandler
=======================================================================
Purpose: Class with all handler methods of ExtraApprovalTrigger.
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR            		 DATE              DETAIL
1.0      Saurav Prasad            07/12/2020      Initial Development
***********************************************************************/
public class ECM_ExtraApprovalTriggerHandler {
    
    public void onAfterInsert(List<ECM_Extra_Approval__c> newExtraApproval, map<Id,ECM_Extra_Approval__c> newMapExtraApproval){ 
        //Helper for sharing records based on Geography
        sharingGeographyOnInsert(newExtraApproval, newMapExtraApproval);
    }
    public void onAfterUpdate(List<ECM_Extra_Approval__c> oldExtraApproval, map<Id,ECM_Extra_Approval__c> oldMapExtraApproval,List<ECM_Extra_Approval__c> newExtraApproval,map<Id,ECM_Extra_Approval__c> newMapExtraApproval){ 
        //Helper for sharing records based on Geography
        sharingGeographyOnUpdate(oldExtraApproval, oldMapExtraApproval, newExtraApproval, newMapExtraApproval);
        
    }
    public void sharingGeographyOnInsert(List<ECM_Extra_Approval__c> newExtraApproval, map<Id,ECM_Extra_Approval__c> newMapExtraApproval){
        //Sharing records
        EDGE_SharingUtil.validateCreatePermission(newExtraApproval, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newExtraApproval, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newExtraApproval, 'ECM_Geography__c', 'Down', 'Edit');
    }
    
    public void sharingGeographyOnUpdate(List<ECM_Extra_Approval__c> oldExtraApproval, map<Id,ECM_Extra_Approval__c> oldMapExtraApproval,List<ECM_Extra_Approval__c> newExtraApproval,map<Id,ECM_Extra_Approval__c> newMapExtraApproval){
        //Updating shared records
        List<ECM_Extra_Approval__c> lstNewChangeGeography = new List<ECM_Extra_Approval__c>();
        List<ECM_Extra_Approval__c> lstOldChangeGeography = new List<ECM_Extra_Approval__c>();
        
        for(ECM_Extra_Approval__c objExtraApproval : newExtraApproval){
            if(oldMapExtraApproval.containsKey(objExtraApproval.Id) 
               && objExtraApproval.ECM_Geography__c != oldMapExtraApproval.get(objExtraApproval.Id).ECM_Geography__c){
                   lstNewChangeGeography.add(objExtraApproval);
                   lstOldChangeGeography.add(oldMapExtraApproval.get(objExtraApproval.Id));
               }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Down', 'Edit');
        }       
    }
    
}