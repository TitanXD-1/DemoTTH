/**********************************************************************
Name: ECM_TemplateSubSectionTriggerhelper
=======================================================================
Purpose: Helper Class for ECM_TemplateSubSectionTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Keshav         04/1/2021        Initial Development
***********************************************************************/
public class ECM_TemplateSubSectionTriggerhelper {

    public static void replaceText(List<ECM_Template_Sub_Section__c > newItems){
        
        for(ECM_Template_Sub_Section__c tempSectionSubRecord: newItems){
            if(tempSectionSubRecord.ECM_Text__c != null && !tempSectionSubRecord.ECM_Terms_And_Condition__c) {
                tempSectionSubRecord.ECM_Text__c = tempSectionSubRecord.ECM_Text__c.trim().replaceAll('style="[a-zA-Z0-9:;\\.\\s()\\-,]*"','');
            }
        }
    }
    /*******************************************************************
	Method  : checkAndGenerateSharing
	Purpose : To create sharing record on Insert
	********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Template_Sub_Section__c > newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
	Method  : validateAndReGenerateSharing
	Purpose : Modify, Validate sharing record on update
	********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Template_Sub_Section__c > newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Template_Sub_Section__c > mapOldItems;
        List<ECM_Template_Sub_Section__c > lstNewChangeGeography = new List<ECM_Template_Sub_Section__c>();
        List<ECM_Template_Sub_Section__c > lstOldChangeGeography = new List<ECM_Template_Sub_Section__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Template_Sub_Section__c>)oldItems;
        }
        
        for(ECM_Template_Sub_Section__c  objTempSubSec : newItems){
            if(mapOldItems.containsKey(objTempSubSec.Id) && objTempSubSec.ECM_Geography__c != mapOldItems.get(objTempSubSec.Id).ECM_Geography__c){
                lstNewChangeGeography.add(objTempSubSec);
                lstOldChangeGeography.add(mapOldItems.get(objTempSubSec.Id));
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