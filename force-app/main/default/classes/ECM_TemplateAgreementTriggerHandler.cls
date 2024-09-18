/**********************************************************************
Name: ECM_TemplateAgreementTriggerHandler
=======================================================================
Purpose: Class with all handler methods of TemplateAgreementTrigger.
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR            		 DATE              DETAIL
1.0      Saurav Prasad            18/12/2020      Initial Development
***********************************************************************/
public class ECM_TemplateAgreementTriggerHandler {
    
    public void onAfterInsert(List<ECM_Template_Agreement__c> newTemplateAgreement, map<Id,ECM_Template_Agreement__c> newMapTemplateAgreement){ 
        //Helper for sharing records based on Geography
        sharingGeographyOnInsert(newTemplateAgreement, newMapTemplateAgreement);
    }
    public void onAfterUpdate(List<ECM_Template_Agreement__c> oldTemplateAgreement, map<Id,ECM_Template_Agreement__c> oldMapTemplateAgreement,List<ECM_Template_Agreement__c> newTemplateAgreement,map<Id,ECM_Template_Agreement__c> newMapTemplateAgreement){ 
        //Helper for sharing records based on Geography
        sharingGeographyOnUpdate(oldTemplateAgreement, oldMapTemplateAgreement, newTemplateAgreement, newMapTemplateAgreement);
    }
    
    public void sharingGeographyOnInsert(List<ECM_Template_Agreement__c> newTemplateAgreement, map<Id,ECM_Template_Agreement__c> newMapTemplateAgreement){
    //Sharing records
        EDGE_SharingUtil.validateCreatePermission(newTemplateAgreement, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newTemplateAgreement, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newTemplateAgreement, 'ECM_Geography__c', 'Down', 'Edit');
    }
    
    public void sharingGeographyOnUpdate(List<ECM_Template_Agreement__c> oldTemplateAgreement, map<Id,ECM_Template_Agreement__c> oldMapTemplateAgreement,List<ECM_Template_Agreement__c> newTemplateAgreement,map<Id,ECM_Template_Agreement__c> newMapTemplateAgreement){
        //Updating shared records
        List<ECM_Template_Agreement__c> lstNewChangeGeography = new List<ECM_Template_Agreement__c>();
        List<ECM_Template_Agreement__c> lstOldChangeGeography = new List<ECM_Template_Agreement__c>();
        
        for(ECM_Template_Agreement__c objTemplateAgreement : newTemplateAgreement){
            if(oldMapTemplateAgreement.containsKey(objTemplateAgreement.Id) 
               && objTemplateAgreement.ECM_Geography__c != oldMapTemplateAgreement.get(objTemplateAgreement.Id).ECM_Geography__c){
                   lstNewChangeGeography.add(objTemplateAgreement);
                   lstOldChangeGeography.add(oldMapTemplateAgreement.get(objTemplateAgreement.Id));
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