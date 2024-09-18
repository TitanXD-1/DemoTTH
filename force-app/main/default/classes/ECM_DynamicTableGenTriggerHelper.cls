/**********************************************************************
Name: ECM_DynamicTableGenTriggerHelper
=======================================================================
Purpose: Class with all handler methods of ECM_DynamicTableTrigger.
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR              DATE              DETAIL
1.0        Pravlika           07/12/2020      Initial Development
***********************************************************************/
public class ECM_DynamicTableGenTriggerHelper {
    
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Dynamic_Table_Generator__c > newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Dynamic_Table_Generator__c > newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Dynamic_Table_Generator__c > mapOldItems;
        List<ECM_Dynamic_Table_Generator__c > lstNewChangeGeography = new List<ECM_Dynamic_Table_Generator__c>();
        List<ECM_Dynamic_Table_Generator__c > lstOldChangeGeography = new List<ECM_Dynamic_Table_Generator__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Dynamic_Table_Generator__c>)oldItems;
        }
        
        for(ECM_Dynamic_Table_Generator__c  objDynamicTabOption : newItems){
            if(mapOldItems.containsKey(objDynamicTabOption.Id) && objDynamicTabOption.ECM_Geography__c != mapOldItems.get(objDynamicTabOption.Id).ECM_Geography__c){
                lstNewChangeGeography.add(objDynamicTabOption);
                lstOldChangeGeography.add(mapOldItems.get(objDynamicTabOption.Id));
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