/**

* @description : EDGE_OutletStrategicFitTriggerHelper

* @purpose : 

* @history :                                                           

*VERSION    AUTHOR              DATE              DETAIL

*1.0       Shivam Chauhan     11/12/2023      Initial Development(148432)
*2.0       Sakshi Shah        21/06/2024      US-153963
*/
public with sharing class EDGE_OutletStrategicFitTriggerHelper {
    
    public static void outletStrategicFitInsertUpdateCheck(List<Outlet_Strategic_Fit__c> newItems,Map<Id,Sobject> oldItems){
        Map<id,Outlet_Strategic_Fit__c> existingPrimaryRecord = new Map<id,Outlet_Strategic_Fit__c>();
        getGetexistingPrimaryRecord(newItems,existingPrimaryRecord);
        
        /*US-153963 Start -> The intial logic of adding only one primary pickup option to a Outlet-Strategic Fit has been updated 
        to allow adding other primary pickup option only if the existing primary record has been made 'Inactive'.*/
     
        Map<id,Outlet_Strategic_Fit__c> mapoldItems = (Map<id,Outlet_Strategic_Fit__c>)oldItems;
        
        //Map of Pickup options added to fetch the status field
        Map<Id, Pick_Up_Options__c> mapOfParentPickupOptions = new Map<Id, Pick_Up_Options__c>(); 
        mapOfParentPickupOptions = getPickupOption(newItems);
        
        //This is to store the new and existing status of Pickup Option of the Outlet-Strategic fit
        String newRecStatus; 
        String existingStatus; 
        
        // Logic updated to check if the existing primary record is active or not.
        for(Outlet_Strategic_Fit__c newOSF : newItems){
            newRecStatus = getStatusValueFromPickupOption(mapOfParentPickupOptions,newOSF.Strategic_Fit_Option__c);
            existingStatus = !existingPrimaryRecord.isEmpty() ? existingPrimaryRecord.get(newOSF.Outlet__c).Strategic_Fit_Option__r.Status__c: ''; 
            Boolean flag1 = newOSF.is_Primary__c && (existingStatus == 'Active' || newRecStatus == 'Active'); 
            Boolean flag2 = newOSF.is_Primary__c && newRecStatus == 'Active' ;
            Boolean flag3 = (Trigger.isUpdate && mapoldItems.get(newOSF.id).is_Primary__c != newOSF.is_Primary__c);
            if(existingPrimaryRecord.containsKey(newOSF.Outlet__c) && flag1 &&
               ((Trigger.isInsert) || flag3)){
                newOSF.addError(Label.Edge_OSFPrimaryCheckValidationMessage);
            }
            else if(!existingPrimaryRecord.containsKey(newOSF.Outlet__c) && flag2){
                existingPrimaryRecord.put(newOSF.Outlet__c,newOSF);
            }
        }
    }
    
    //This method is added to get the status of a particular pickup option associated with a Outlet- Strategic fit record.
    public static String getStatusValueFromPickupOption(Map<Id, Pick_Up_Options__c> mapOfParentPickupOptions, Id pickupOptionId){ 
        
        String status = '';
            if(!mapOfParentPickupOptions.isEmpty() && mapOfParentPickupOptions.containsKey(pickupOptionId)){
                status = mapOfParentPickupOptions.get(pickupOptionId).Status__c;
            }
            return status;
    }
     //Method added to get the map of pickup options
    public static Map<Id, Pick_Up_Options__c>  getPickupOption(List<Outlet_Strategic_Fit__c> newItems ){
        Set<Id> pickUpOptionsIds = new Set<Id>();

        for(Outlet_Strategic_Fit__c newOSF : newItems){
            pickUpOptionsIds.add(newOSF.Strategic_Fit_Option__c);
        }
        return  new Map<Id, Pick_Up_Options__c>([SELECT Id, Status__c FROM Pick_Up_Options__c WHERE Id IN: pickUpOptionsIds]);
    }
    
    public static void getGetexistingPrimaryRecord(List<Outlet_Strategic_Fit__c> newItems,Map<id,Outlet_Strategic_Fit__c> existingPrimaryRecord){
        Set<id> outletId = new Set<id> ();
        for(Outlet_Strategic_Fit__c newOSF : newItems){
            outletId.add(newOSF.Outlet__c);
        }
        //The query is updated to fetch the status of existing primary record
        for(Outlet_Strategic_Fit__c osf : [Select id,name,is_Primary__c,Strategic_Fit_Option__r.Status__c,Outlet__c from Outlet_Strategic_Fit__c where is_Primary__c = true and Strategic_Fit_Option__r.Status__c = 'Active' and Outlet__c IN:outletId WITH SECURITY_ENFORCED]){ 
            existingPrimaryRecord.put(osf.Outlet__c,osf);
        }
    }    
}