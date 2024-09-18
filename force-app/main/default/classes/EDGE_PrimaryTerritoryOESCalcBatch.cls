/**********************************************************************
Name: EDGE_PrimaryTerritoryOESCalcBatch
=======================================================================
Req: Calculate the Terrritory level Current OES Score & Rank
User Story : ES20-1783,ES20-1812
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Dipanjan Das      20/05/2019        Calculate the Terrritory level Current OES Score & Rank   
***********************************************************************/
/* Commented as part of User Story ES20-6590*/

public class EDGE_PrimaryTerritoryOESCalcBatch /*implements Database.Batchable<sObject>,Database.Stateful,BatchJobManagementInterfaceClass*/{    
    Boolean hasError = false;
    /*
Market_Batch_Setting__mdt batchSetting;
Boolean hasError = false;
String exceptionMsg = '';
Set<Id> territoryIdSet = new Set<Id>();

//Interface Class Method
public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
this.batchSetting = batchSetting;
}

// start method 
public Database.QueryLocator start(Database.BatchableContext bc){        
//Upsert Market Batch Job Data
EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting);       
String queryString='';
String territoryType='Sales';
String activeStatus='Active'; 
String countryCode = batchSetting.Country_Code__c;                     
//Get sales territoris

queryString='SELECT Id, Current_OES_Rank__c, Current_OES_Score__c, Country__r.Minimum_Activation_Standards__c, Country__r.Minimum_Product_Assortment__c FROM Territory__c WHERE Territory_Type__c =:territoryType AND Country__r.Code__c =:countryCode';

return Database.getQueryLocator(queryString);
}

//execute method
public void execute(Database.BatchableContext bc, List<Territory__c> scope){

Map<Id, Integer> territoryWithOutletNumMap = new Map<Id, Integer>();
Map<Id, Decimal> territoryWithOesMap = new Map<Id, Decimal>();

Map<Id, Decimal> territoryWithTotalMPAMap = new Map<Id, Decimal>();

Map<Id, Decimal> territoryWithTotalMASMap = new Map<Id, Decimal>();

Map<Id, Decimal> territoryWithMasFactorMap = new Map<Id, Decimal>();
Map<Id, Decimal> territoryWithMpaFactorMap = new Map<Id, Decimal>();
Set<Id> territoryIdSet = new Set<Id>();

for(Territory__c territory : scope){
territoryIdSet.add(territory.Id);
territoryWithMasFactorMap.put(territory.Id, territory.Country__r.Minimum_Activation_Standards__c);  
territoryWithMpaFactorMap.put(territory.Id, territory.Country__r.Minimum_Product_Assortment__c);    
}
system.debug('territoryIdSet++ ' + territoryIdSet);
for(Account outlet : [Select Id, Primary_Sales_Territory__c, Minimum_Product_Assortment__c, Minimum_Activation_Standards__c FROM Account WHERE Primary_Sales_Territory__c IN :territoryIdSet AND Status__c = 'Active']){
if(territoryWithOutletNumMap.containsKey(outlet.Primary_Sales_Territory__c)){
territoryWithOutletNumMap.put(outlet.Primary_Sales_Territory__c, territoryWithOutletNumMap.get(outlet.Primary_Sales_Territory__c) + 1);
}else{
territoryWithOutletNumMap.put(outlet.Primary_Sales_Territory__c, 1);
}    
if(outlet.Minimum_Product_Assortment__c == 100 && outlet.Minimum_Activation_Standards__c == 100){
if(territoryWithTotalMPAMap.containsKey(outlet.Primary_Sales_Territory__c)){
territoryWithTotalMPAMap.put(outlet.Primary_Sales_Territory__c, territoryWithTotalMPAMap.get(outlet.Primary_Sales_Territory__c) + outlet.Minimum_Product_Assortment__c);
}else{
territoryWithTotalMPAMap.put(outlet.Primary_Sales_Territory__c, outlet.Minimum_Product_Assortment__c);
}
if(territoryWithTotalMASMap.containsKey(outlet.Primary_Sales_Territory__c)){
territoryWithTotalMASMap.put(outlet.Primary_Sales_Territory__c, territoryWithTotalMASMap.get(outlet.Primary_Sales_Territory__c) + outlet.Minimum_Activation_Standards__c);
}else{
territoryWithTotalMASMap.put(outlet.Primary_Sales_Territory__c, outlet.Minimum_Activation_Standards__c);
}
}    
}
for(Id territoryId : territoryWithOutletNumMap.keySet()){
territoryWithOesMap.put(territoryId, (((checkForNull(territoryWithTotalMASMap.get(territoryId)) / territoryWithOutletNumMap.get(territoryId)) * checkForNull(territoryWithMasFactorMap.get(territoryId))) + ((checkForNull(territoryWithTotalMPAMap.get(territoryId)) / territoryWithOutletNumMap.get(territoryId)) * checkForNull(territoryWithMpaFactorMap.get(territoryId)))) / 100); 
}       

for(Territory__c territory : scope){
territory.Previous_OES_Score__c = territory.Current_OES_Score__c;
territory.Current_OES_Score__c = checkForNull(territoryWithOesMap.get(territory.Id));
}

system.debug('territoryWithTotalMPAMap++ ' + territoryWithTotalMPAMap);
system.debug('territoryWithTotalMASMap++ ' + territoryWithTotalMASMap);
system.debug('territoryWithOutletNumMap++ ' + territoryWithOutletNumMap);
system.debug('territoryWithMasFactorMap++ ' + territoryWithMasFactorMap);   
system.debug('territoryWithMpaFactorMap++ ' + territoryWithMpaFactorMap);   


try{
Database.update(scope,false);
}catch(DmlException de){            
hasError = true;
Integer numErrors = de.getNumDml();
for(Integer i=0; i<numErrors; i++) {
exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
}
}catch(Exception ex) {            
hasError = true;
exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
}       

}       

//Return 0 if KPI value is null
public static Decimal checkForNull(Decimal kpiValue){
return EDGE_UtilityClass.checkForNull(kpiValue);
}   

public void finish(Database.BatchableContext bc){
String territoryType='Sales';
String countryCode = batchSetting.Country_Code__c;      
List<Territory__c> terrListToUpdate = new List<Territory__c>();
Integer rank = 1;
System.debug('@@countryCode' +countryCode);
try{
for(Territory__c territoryObj : [SELECT Id,Current_OES_Score__c,Current_OES_Rank__c FROM Territory__c WHERE 
Territory_Type__c =:territoryType AND Country__r.Code__c =:countryCode AND 
Current_OES_Score__c != null ORDER BY Current_OES_Score__c DESC]){
territoryObj.Previous_OES_Rank__c = territoryObj.Current_OES_Rank__c;
territoryObj.Current_OES_Rank__c = rank;
terrListToUpdate.add(territoryObj);
rank++;            
}
if(!terrListToUpdate.isEmpty()){
Database.update(terrListToUpdate, false);
}
}catch(exception ex){
hasError = true;
exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';    
}

//Update Batch Job Status
if(hasError){
EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, 'Failed', bc.getJobId(), 'EDGE_PrimaryTerritoryOutletCalcBatch', exceptionMsg);
}else{
EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, 'Successful', bc.getJobId(), '', '');
}    
//Schedule Next Batch from Batch Utility Class
EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); 
}*/
}