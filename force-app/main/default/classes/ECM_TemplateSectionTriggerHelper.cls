public class ECM_TemplateSectionTriggerHelper {
    
          
    public static void replaceText(List<ECM_Template_Section__c > newItems){
     
             for(ECM_Template_Section__c tempSectionRecord: newItems){
        if(tempSectionRecord.ECM_Text__c != null && !tempSectionRecord.ECM_Terms_And_Condition__c && !tempSectionRecord.ECM_Keep_Format__c) {
            tempSectionRecord.ECM_Text__c = tempSectionRecord.ECM_Text__c.trim().replaceAll('style="[a-zA-Z0-9:;\\.\\s()\\-,]*"','');
        }
      }
    }
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Template_Section__c > newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Template_Section__c > newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Template_Section__c > mapOldItems;
        List<ECM_Template_Section__c > lstNewChangeGeography = new List<ECM_Template_Section__c>();
        List<ECM_Template_Section__c > lstOldChangeGeography = new List<ECM_Template_Section__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Template_Section__c>)oldItems;
        }
        
        for(ECM_Template_Section__c  objPaymentFreqOption : newItems){
            if(mapOldItems.containsKey(objPaymentFreqOption.Id) && objPaymentFreqOption.ECM_Geography__c != mapOldItems.get(objPaymentFreqOption.Id).ECM_Geography__c){
                lstNewChangeGeography.add(objPaymentFreqOption);
                lstOldChangeGeography.add(mapOldItems.get(objPaymentFreqOption.Id));
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