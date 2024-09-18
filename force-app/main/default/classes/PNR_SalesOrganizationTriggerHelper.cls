/*
 * Class Name : PNR_SalesOrganizationTriggerHelper
 * @description: This is Sales Organisation Trigger Helper
 * @history
 * VERSION    AUTHOR           DATE              DETAIL
 * 1.0      Jayashree R      12/01/2021        Initial Development
*/
public with sharing class PNR_SalesOrganizationTriggerHelper {
    
    /*
	*@Method  : createPublicGroup
	*@Purpose : Create and Update group name 
	*/       
    public static void createPublicGroup(Map<Id, SObject> newItems){
        
        try{
            if(newItems != null && newItems.size()>0){
                List<Group> groups=new List<Group>();
                List<Sales_Organisation__c> regGroups=new List<Sales_Organisation__c>();
                regGroups=(List<Sales_Organisation__c>)newItems.values();
                Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Sales_Organisation__c.getRecordTypeInfosById();
                for(Sales_Organisation__c rg : regGroups)
                {
                    if(rtMap.get(rg.RecordTypeId).getDeveloperName() == 'Regional_Group'){ 
                        Group gp1 = new Group();
                        gp1.name = 'RG_'+rg.Name+'_Read';
                        Group gp2 = new Group();
                        gp2.name = 'RG_'+rg.Name+'_Write';
                        groups.add(gp2);
                        groups.add(gp1);
                    }
                }
                insert groups;
            }
            
        }catch(Exception excption){
            List<SObject> errorItem= newItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);
        }
    }
    
    public static void shareSalesOrgs(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        try{
            Map<Id, Sales_Organisation__c> newSoMap = (Map<Id, Sales_Organisation__c>)newItems;
            Map<Id, Sales_Organisation__c> oldSoMap = new Map<Id, Sales_Organisation__c>();
            if(oldItems != null){
                oldSoMap = (Map<Id, Sales_Organisation__c>)oldItems;
            }
            Map<String, Id> soCodeRgIdMap = new Map<String, Id>();
            Map<String, Id> soOldCodeRgIdMap = new Map<String, Id>();
            for(Id soId: newSoMap.keyset()){
                if(Schema.SObjectType.Sales_Organisation__c.getRecordTypeInfosById().get(newSoMap.get(soId).RecordTypeId).getDeveloperName() == 'SalesOrg' 
                    && 
                    (oldItems == null 
                    ||
                    (newSoMap.get(soId).PNR_Regional_Group__c != null && oldSoMap.containsKey(soId) &&
                        newSoMap.get(soId).PNR_Regional_Group__c != oldSoMap.get(soId).PNR_Regional_Group__c 
                    ))
                )
                {
                    soCodeRgIdMap.put(newSoMap.get(soId).Code__c, newSoMap.get(soId).PNR_Regional_Group__c);
                    if(oldItems != null){
                        soOldCodeRgIdMap.put(oldSoMap.get(soId).Code__c, oldSoMap.get(soId).PNR_Regional_Group__c);
                    }
                }
            }

            Map<Id, String> rgIdNameMap = new Map<Id, String>();
            for(Sales_Organisation__c so: [SELECT Id, Name FROM Sales_Organisation__c WHERE Id IN :soCodeRgIdMap.values() OR Id IN :soOldCodeRgIdMap.values()]){

                rgIdNameMap.put(so.Id, so.Name);
            }

            
            if(!soCodeRgIdMap.keyset().isEmpty()){
                Map<String, String> soCodeRgNameMap = new Map<String, String>();
                for(String soCode: soCodeRgIdMap.keyset()){

                    soCodeRgNameMap.put('SO_'+soCode+'_Read', 'RG_'+rgIdNameMap.get(soCodeRgIdMap.get(soCode))+'_Read');
                    soCodeRgNameMap.put('SO_'+soCode+'_Write', 'RG_'+rgIdNameMap.get(soCodeRgIdMap.get(soCode))+'_Write');
                }
                if(!soCodeRgNameMap.keyset().isEmpty()){
                    PNR_SharingUtil.addSOGroupToRGGroup(soCodeRgNameMap, 'add');
                }
            }
            if(oldItems != null && !soOldCodeRgIdMap.keyset().isEmpty()){
                Map<String, String> soCodeRgNameMap = new Map<String, String>();
                for(String soCode: soOldCodeRgIdMap.keyset()){
                    soCodeRgNameMap.put('SO_'+soCode+'_Read', 'RG_'+rgIdNameMap.get(soOldCodeRgIdMap.get(soCode))+'_Read');
                    soCodeRgNameMap.put('SO_'+soCode+'_Write', 'RG_'+rgIdNameMap.get(soOldCodeRgIdMap.get(soCode))+'_Write');
                }
                if(!soCodeRgNameMap.keyset().isEmpty()){
                    PNR_SharingUtil.addSOGroupToRGGroup(soCodeRgNameMap, 'remove');
                }
            }
        }catch(Exception exp){
            System.debug('Exception:::'+exp.getLineNumber()+exp.getCause()+exp.getMessage());
            new EDGE_GenericException(exp, null);
        }
    }
}