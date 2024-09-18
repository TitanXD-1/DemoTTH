/**********************************************************************
Name: EDGE_SalesAreaKPICalculationBatch
=======================================================================
Req: 
User Story : ES20-3334,ES20-3335,ES20-3336,ES20-3337,ES20-3338,ES20-3344,ES20-3339,ES20-3340
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.1       Sagar Barman      02/08/2019
1.2       Dipanjan D        06/08/2019        Calculate the Sales Area level KPI from outlet and territory.
***********************************************************************/
/* Commented as part of User Story ES20-6590*/

public class EDGE_SalesAreaKPICalculationBatch /*implements Database.Batchable<sObject>,Database.Stateful,BatchJobManagementInterfaceClass*/{
    Boolean hasError = false;
    /*   Market_Batch_Setting__mdt batchSetting;
Boolean hasError = false;
String exceptionMsg = '';   

//Interface Class Method
public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
this.batchSetting = batchSetting;
}

// start method 
public Database.QueryLocator start(Database.BatchableContext bc){ 
//Upsert Market Batch Job Data
EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting);       
String queryString='';
String countryCode = batchSetting.Country_Code__c;                     
Id regionRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();

queryString='SELECT Id FROM Territory_Hierarchy__c WHERE Geography__r.Code__c =:countryCode AND recordTypeId =:regionRecTypeId';

return Database.getQueryLocator(queryString);
}

//execute method
public void execute(Database.BatchableContext bc, List<Territory_Hierarchy__c> scope){ 
/*
String queryFieldsString = '';
Id territoryId;
Map<String, Sales_Area_KPI_Fields_Mapping__mdt> kpiFieldsMap = new Map<String, Sales_Area_KPI_Fields_Mapping__mdt>();
Map<Id, Integer> regionWithOutletsNumberMap = new Map<Id, Integer>();
List<Territory_Hierarchy__c> terrHierToUpdate = new List<Territory_Hierarchy__c>();
Map<Id, Map<String, Decimal>> regionWithOutletKPIsMap = new Map<Id, Map<String, Decimal>>();
Set<Id> terrHierIds = (new Map<Id,Territory_Hierarchy__c>(scope)).keySet();


try{
//Getting Sales Area KPI Fields Mappings Metadata records for field mappings
for(Sales_Area_KPI_Fields_Mapping__mdt kpiMap : [SELECT MasterLabel, Account_KPI_Field__c, Operation_Type__c, Calculation_Type__c, Relationship__c  FROM Sales_Area_KPI_Fields_Mapping__mdt WHERE Active__c = True]){
kpiFieldsMap.put(kpiMap.MasterLabel, kpiMap);
queryFieldsString += kpiMap.Account_KPI_Field__c + ' ,';
}

//Quering all the outlets within the Sales Area(Territory Hierarchy)
String queryString = 'SELECT Id, Primary_Sales_Territory__c, Primary_Sales_Territory__r.Region__c, ' + queryFieldsString.removeEnd(',') + ' FROM Account WHERE Primary_Sales_Territory__r.Region__c IN :terrHierIds order by Primary_Sales_Territory__c';

system.debug('queryString+++ ' + queryString);

for(Account outlet : Database.query(queryString)){

Id regionId = outlet.Primary_Sales_Territory__r.Region__c;

//Mapping Sales Area(Territory Hierarchy) with number of Outlets
if(regionWithOutletsNumberMap.containsKey(regionId)){
regionWithOutletsNumberMap.put(regionId, regionWithOutletsNumberMap.get(regionId) + 1);
}else{
regionWithOutletsNumberMap.put(regionId, 1);
}

system.debug('regionWithOutletsNumberMap++ ' + regionWithOutletsNumberMap);

//Iterating over field names from Sales Area(Territory Hierarchy) KPI Fields Mappings Metadata
for(String fieldName : kpiFieldsMap.keySet()){
Decimal fieldVal = 0;   
String calcType = kpiFieldsMap.get(fieldName).Calculation_Type__c;  


//Check if it's a parent relationship field
if(kpiFieldsMap.get(fieldName).Relationship__c != 'Parent'){
fieldVal = (Decimal)outlet.get(kpiFieldsMap.get(fieldName).Account_KPI_Field__c);                                       
}else{
String relationName = kpiFieldsMap.get(fieldName).Account_KPI_Field__c.split('\\.')[0];
fieldVal = (Decimal)outlet.getSobject(relationName).get(kpiFieldsMap.get(fieldName).Account_KPI_Field__c.remove(relationName + '.'));
} 


//Checking if it's a parent relationship field and territory KPI values does not repeat or it's a child relationship
if((kpiFieldsMap.get(fieldName).Relationship__c == 'Parent' && outlet.Primary_Sales_Territory__c != territoryId ) || kpiFieldsMap.get(fieldName).Relationship__c != 'Parent'){

if(regionWithOutletKPIsMap.containsKey(regionId)){
if(regionWithOutletKPIsMap.get(regionId).containsKey(fieldName)){
regionWithOutletKPIsMap.get(regionId).put(fieldName, regionWithOutletKPIsMap.get(regionId).get(fieldName) + checkValue(fieldVal, calcType));
}else{
regionWithOutletKPIsMap.get(regionId).put(fieldName, checkValue(fieldVal, calcType));
}                       
}else{
regionWithOutletKPIsMap.put(regionId, new Map<String, Decimal> {fieldName => checkValue(fieldVal, calcType)});
}                   
}               
}
territoryId = outlet.Primary_Sales_Territory__c;            
}
system.debug('regionWithOutletKPIsMap++ ' + regionWithOutletKPIsMap);


//Assigning values to Sales Area(Territory Hierarchy)
for(Territory_Hierarchy__c terrHier : [SELECT Id FROM Territory_Hierarchy__c WHERE Id IN :regionWithOutletKPIsMap.keySet()]){
for(String fieldName : kpiFieldsMap.keySet()){
if(kpiFieldsMap.get(fieldName).Operation_Type__c == 'Average'){
terrHier.put(fieldName, regionWithOutletKPIsMap.get(terrHier.Id).get(fieldName)/ regionWithOutletsNumberMap.get(terrHier.Id));    
}else if(kpiFieldsMap.get(fieldName).Operation_Type__c == 'Sum'){
terrHier.put(fieldName, regionWithOutletKPIsMap.get(terrHier.Id).get(fieldName));    
}

}
terrHierToUpdate.add(terrHier); 
}

if(terrHierToUpdate != null && terrHierToUpdate.size() > 0){
database.update(terrHierToUpdate);
}
}catch(DmlException de){
hasError = true;
Integer numErrors = de.getNumDml();
for(Integer i=0; i<numErrors; i++) {
exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
}
}
catch(Exception ex){
system.debug('@@Exception' + ex.getMessage());
hasError = true;
exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';            
}

}

public static Decimal checkValue(Decimal kpiValue, String calcType){
if(kpiValue != null){
if(calcType == 'Binary'){
if(kpiValue == 100){
return kpiValue;
}else{
return 0;
}               
}else if(calcType == 'Progressive'){
return kpiValue;
}else{
return 0;
}
}else{
return 0;
}       
}   


public void finish(Database.BatchableContext bc){
//Update Batch Job Status
if(hasError){
EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, 'Failed', bc.getJobId(), 'EDGE_SalesAreaKPICalculationBatch', exceptionMsg);
}else{
EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, 'Successful', bc.getJobId(), '', '');
}
EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
}*/    
}