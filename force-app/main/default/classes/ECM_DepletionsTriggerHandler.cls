/*
@Name: ECM_DepletionsTriggerHandler
@Purpose: Class with all handler methods of DepletionsTrigger.
@History                                                                                                                      
@VERSION  	AUTHOR              DATE              	DETAIL
1.0        	Pravlika           	07/12/2020      	Initial Development
2.0			Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country
*/
public class ECM_DepletionsTriggerHandler {
    
    public void onAfterInsert(List<Depletions__c> newDepList, map<Id,Depletions__c> newMapDepList ){ 
        //Helper for sharing records based on Geography
        GenerateSharingGeographyOnInsert(newDepList, newMapDepList);
    }
    public void onAfterUpdate(List<Depletions__c> oldDepList, map<Id,Depletions__c> oldMapDepList,List<Depletions__c> newDepList,map<Id,Depletions__c> newMapDepList){ 
        //Helper for sharing records based on Geography
        ValidateSharingGeographyOnUpdate(oldDepList, oldMapDepList, newDepList, newMapDepList);
    }
    public void onBeforeAddCountry(List<Depletions__c> newDepList,Map<Id,Depletions__c> oldMapDepList){
        populateCountry(newDepList,oldMapDepList);
    }
    public void GenerateSharingGeographyOnInsert(List<Depletions__c> newDepList, map<Id,Depletions__c> newMapDepList){
        //Sharing records
        EDGE_SharingUtil.validateCreatePermission(newDepList, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newDepList, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newDepList, 'ECM_Geography__c', 'Down', 'Edit');
    }
    
    public void ValidateSharingGeographyOnUpdate(List<Depletions__c> oldDepList, map<Id,Depletions__c> oldMapDepList,List<Depletions__c> newDepList,map<Id,Depletions__c> newMapDepList){
        //Updating shared records
        List<Depletions__c> lstNewChangeGeography = new List<Depletions__c>();
        List<Depletions__c> lstOldChangeGeography = new List<Depletions__c>();
        
        for(Depletions__c objDepList : newDepList){
            if(oldMapDepList.containsKey(objDepList.Id) 
               && objDepList.ECM_Geography__c != oldMapDepList.get(objDepList.Id).ECM_Geography__c){
                   lstNewChangeGeography.add(objDepList);
                   lstOldChangeGeography.add(oldMapDepList.get(objDepList.Id));
               }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Down', 'Edit');
        }       
    }
    public void populateCountry(List<Depletions__c> newDepList,Map<Id,Depletions__c> oldMapDepList){
        Set<Id> accId = new Set<Id>();
        List<Depletions__c> reqDepList = new List<Depletions__c>();
        Map<Id,Account> accMap;
        for(Depletions__c depObj : newDepList){
            if((oldMapDepList == null && String.isNotBlank(depObj.ECM_Outlet__c))||
          		(oldMapDepList != null && oldMapDepList.get(depObj.Id).ECM_Outlet__c != depObj.ECM_Outlet__c && String.isNotBlank(depObj.ECM_Outlet__c))){
            	accId.add(depObj.ECM_Outlet__c);
                reqDepList.add(depObj);
            }else if(String.isBlank(depObj.ECM_Outlet__c)){
                 depObj.ECM_Geography__c = null;  
            }
        }
        if(!accId.isEmpty()){
            accMap = new Map<Id,Account>([SELECT Id,Country__c FROM Account WHERE Id IN : accId]);
        }
        for(Depletions__c depObj : reqDepList){
            if(accMap!= null && accMap.containsKey(depObj.ECM_Outlet__c)){
                depObj.ECM_Geography__c = accMap.get(depObj.ECM_Outlet__c).Country__c;
            }
        }
    }
}