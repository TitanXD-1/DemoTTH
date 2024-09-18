/**********************************************************************
Name: ECM_PriceListTriggerHandler
=======================================================================
Purpose: Class with all handler methods of PriceListTrigger.
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR              DATE              DETAIL
1.0        Pravlika           07/12/2020      Initial Development
***********************************************************************/
public class ECM_PriceListTriggerHandler {
    
    public void onAfterInsert(List<ECM_Price_List__c> newPriceList, map<Id,ECM_Price_List__c> newMapPriceList){ 
        //Helper for sharing records based on Geography
        GenerateSharingGeographyOnInsert(newPriceList, newMapPriceList);
    }
    public void onAfterUpdate(List<ECM_Price_List__c> oldPriceList, map<Id,ECM_Price_List__c> oldMapPriceList,List<ECM_Price_List__c> newPriceList,map<Id,ECM_Price_List__c> newMapPriceList){ 
        //Helper for sharing records based on Geography
        ValidateSharingGeographyOnUpdate(oldPriceList, oldMapPriceList, newPriceList, newMapPriceList);
        
    }
    public void GenerateSharingGeographyOnInsert(List<ECM_Price_List__c> newPriceList, map<Id,ECM_Price_List__c> newMapPriceList){
        //Sharing records
        EDGE_SharingUtil.validateCreatePermission(newPriceList, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newPriceList, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newPriceList, 'ECM_Geography__c', 'Down', 'Edit');
    }
    
    public void ValidateSharingGeographyOnUpdate(List<ECM_Price_List__c> oldPriceList, map<Id,ECM_Price_List__c> oldMapPriceList,List<ECM_Price_List__c> newPriceList,map<Id,ECM_Price_List__c> newMapPriceList){
        //Updating shared records
        List<ECM_Price_List__c> lstNewChangeGeography = new List<ECM_Price_List__c>();
        List<ECM_Price_List__c> lstOldChangeGeography = new List<ECM_Price_List__c>();
        
        for(ECM_Price_List__c objPriceList : newPriceList){
            if(oldMapPriceList.containsKey(objPriceList.Id) 
               && objPriceList.ECM_Geography__c != oldMapPriceList.get(objPriceList.Id).ECM_Geography__c){
                   lstNewChangeGeography.add(objPriceList);
                   lstOldChangeGeography.add(oldMapPriceList.get(objPriceList.Id));
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