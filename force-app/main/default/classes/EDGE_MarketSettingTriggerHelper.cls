/**
 * @name EDGE_MarketSettingTriggerHelper
 * @description Trigger Helper for Market Setting Trigger
 * @History
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Aniket Sen              30/06/2020      Initial Development
 * 2.0              Mukesh Kant             17/10/2023      145867
 */
public with sharing class EDGE_MarketSettingTriggerHelper {

    /**
     * @Name trackHistory
     * @description 
     * @param newItems 
     * @param oldItems 
     */
	public static void trackHistory(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Map<String,Schema.SObjectField>> changedMS = new Map<Id, Map<String,Schema.SObjectField>>();
        Schema.DescribeSObjectResult oppDescribe = Market_Setting__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> fieldset = oppDescribe.fields.getMap();
        List <Market_Setting_History__c> newMSHlist = new List<Market_Setting_History__c>();
        
       	for(SObject msrecord:newItems.values()){
            Map<String,Schema.SObjectField> changedfields = new Map <String,Schema.SObjectField>();
        	for(String field: fieldset.keySet()){
                if(msrecord.get(field)!=oldItems.get(msrecord.Id).get(field))
                    changedfields.put(fieldset.get(field).getDescribe().getLabel(),fieldset.get(field));
        	}
            changedMS.put(msrecord.Id, changedfields);
    	}
        
        //Create Market Setting History record to keep track of the changes
        for(Id msid: changedMS.keyset()){
        	Market_Setting_History__c msh = new Market_Setting_History__c();
        	msh.Market_Setting__c = msid;
            msh.Old_Value__c = ''; 
            msh.New_Value__c = '';  
            for(String field: changedMS.get(msid).keySet()){
                if(field!='Last Modified Date' && field!='System Modstamp'){
                    msh.Old_Value__c += field+': - '+oldItems.get(msid).get(changedMS.get(msid).get(field))+'\n';
            		msh.New_Value__c += field+': - '+newItems.get(msid).get(changedMS.get(msid).get(field))+'\n';
                }
            }
            newMSHlist.add(msh);
        }
        Database.insert(newMSHlist);
    }

    /**
     * @name validatePosOrderLimit
     * @description 145867-This method is used for validation on "Enable POS Order Limit per Time Period" Market Setting Field to be set to TRUE for a Geography ONLY 
     * if all valid Stock Allocation Records for the Market (i.e., available quantity >0) has a Start and End Date populated
     * @param newItems 
     * @param oldMap 
     */
    public static void validatePosOrderLimit(List<SObject> newItems, Map<Id, SObject> oldMap){
        List<Market_Setting__c> newMarketSettingRecords = (List<Market_Setting__c>)newItems;
        Map<Id,Market_Setting__c> oldMarketSettingMap = (Map<Id,Market_Setting__c>)oldMap;
        Set<Id> countries = new Set<Id>();
        Map<String, Integer> stockObjMap = new Map<String, Integer>();
        try{
            for(Market_Setting__c marketSettingRecord : newMarketSettingRecords){
                if(marketSettingRecord.POS_Time_Based_Allocation__c && (oldMarketSettingMap == null || (oldMarketSettingMap!= null && marketSettingRecord.POS_Time_Based_Allocation__c!=oldMarketSettingMap.get(marketSettingRecord.Id).POS_Time_Based_Allocation__c))){
                    countries.add(marketSettingRecord.Geography__c);
                }
            }
            
            Map<String, Object> stockBinds = new Map<String, Object>{
                'RecordTypeId' => Schema.SObjectType.Stock__c.getRecordTypeInfosByDeveloperName().get('Allocation').getRecordTypeId(),
                'countries' => countries
            };
            
            if(!countries.isEmpty()){
                AggregateResult[] aggrResult = Database.queryWithBinds('SELECT COUNT(Id) quantity, Country__c FROM Stock__c WHERE Allocated_Available__c > 0 AND RecordTypeId =:RecordTypeId AND (Start_Date__c = NULL OR End_Date__c = NULL) AND Country__c IN :countries GROUP BY Country__c', stockBinds, AccessLevel.USER_MODE);
                if(aggrResult != null && aggrResult.size() > 0){ 
                    for(AggregateResult aggr : aggrResult){ 
                        string uniqueKey = (string) aggr.get('Country__c');
                        integer itemCount = Integer.valueOf(aggr.get('quantity'));
                        stockObjMap.put(uniqueKey, itemCount);
                    }
                }
                for(Market_Setting__c marketSettingNewRec : newMarketSettingRecords){
                    String uniqueKey = String.valueOf(marketSettingNewRec.Geography__c);
                  
                    if(stockObjMap!=null && stockObjMap.containsKey(uniqueKey) && stockObjMap.get(uniqueKey) > 0){
                        marketSettingNewRec.addError(System.Label.D1_POS_Order_Limit_Error_Msg);
                       
                    }
                }
            }  
        }catch(Exception e){
            System.debug(LoggingLevel.Error, e.getMessage());
        }
    }
}