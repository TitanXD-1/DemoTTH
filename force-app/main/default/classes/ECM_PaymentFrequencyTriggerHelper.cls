public class ECM_PaymentFrequencyTriggerHelper {
    
    
        
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Payment_Frequency__c > newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Payment_Frequency__c > newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Payment_Frequency__c > mapOldItems;
        List<ECM_Payment_Frequency__c > lstNewChangeGeography = new List<ECM_Payment_Frequency__c>();
        List<ECM_Payment_Frequency__c > lstOldChangeGeography = new List<ECM_Payment_Frequency__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Payment_Frequency__c>)oldItems;
        }
        
        for(ECM_Payment_Frequency__c  objPaymentFreqOption : newItems){
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