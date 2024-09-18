/**********************************************************************
  Name: EDGE_CSVFileProcessBatchHelper
=======================================================================
  Purpose: Helper Class for EDGE_CSVFileProcessBatch
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/

public with sharing class EDGE_CSVFileProcessBatchHelper {
    
    public static EDGE_CSVFileProcessBatchWrapper createOutltTerritory(Set<Id> outletIdSet, Set<Id> territoryIdSet, List<List<String>> csvLines, Boolean firstRun){
        //Variable
        Map<Id, Account> inactiveOutletMap = new Map<Id, Account>();
        Map<String, Outlet_Territory__c> exstnTerriOutletMap = new Map<String, Outlet_Territory__c>();
        Map<String, Outlet_Territory__c> terOutltInsrtMap = new Map<String, Outlet_Territory__c>();
        EDGE_CSVFileProcessBatchWrapper csvFileProcessBatchWrapper = new EDGE_CSVFileProcessBatchWrapper();
        
        Integer j = 0;
        //Variable
        if(firstRun){
        	j = 1;
        }
        
        //Creating inactive Outlet map
        if(!outletIdSet.isEmpty()){
            if(Schema.sObjectType.Account.isAccessible()){
                inactiveOutletMap = new Map<Id,Account>([SELECT Id, Status__c, RecordType.DeveloperName, RecordType.Name FROM Account WHERE Id IN :outletIdSet                                                         
                                                         AND (Status__c NOT IN ('Active') OR RecordType.DeveloperName != 'Outlet')]);
            }
        }
        
        //Creating Existing Territory Outlet Map
        if(!outletIdSet.isEmpty() && !territoryIdSet.isEmpty()){
            if(Schema.sObjectType.Outlet_Territory__c.isAccessible()){
                for(Outlet_Territory__c terOutObj : [SELECT Id,Outlet__c,Outlet__r.Status__c,Territory__c 
                                                     FROM Outlet_Territory__c WHERE Territory__c IN :territoryIdSet
                                                     AND Outlet__c IN :outletIdSet ]){
					String cmpKey = String.valueOf(terOutObj.Outlet__c) + String.valueOf(terOutObj.Territory__c);
					exstnTerriOutletMap.put(cmpKey, terOutObj);
				}
            }
        }
        
        //Iterating over CSV file
        for(Integer i = j; i<csvLines.size(); i++){
        	List<String> currentRow = csvLines[i];
            String outltIdStrng = string.valueOf(currentRow[0]).trim();
            String terIdStrng = string.valueOf(currentRow[1]).trim();
            csvFileProcessBatchWrapper.rowCount++;
            
            if((outltIdStrng.length() == 15 || outltIdStrng.length() == 18)
               &&(terIdStrng.length() == 15 || terIdStrng.length() == 18) ){
                   	
           		Id outletId = outltIdStrng;
            	Id territoryId = terIdStrng;
            	String cmpKey = String.valueOf(outletId) + String.valueOf(territoryId);
            	//Checking if Outlet is Inactive or already present
                if(!inactiveOutletMap.isEmpty() && inactiveOutletMap.containsKey(outletId)){
                	csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = '';
                    if(inactiveOutletMap.get(outletId).RecordType.DeveloperName != 'Outlet'){
                       errorMsg = Label.You_cannot_add + ' ' +inactiveOutletMap.get(outletId).RecordType.Name + ' '+ Label.Outlet;
                    }else if(inactiveOutletMap.get(outletId).Status__c != 'Active'){
                    	errorMsg = Label.Inactive_Status + ' '+ inactiveOutletMap.get(outletId).Status__c;
                   	}
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(territoryId) + ',' + errorMsg + ',' + 'Error,\n';
               }else if(!exstnTerriOutletMap.isEmpty() && exstnTerriOutletMap.containsKey(cmpKey)){
                   	csvFileProcessBatchWrapper.failureRowCount++;
                   	string errorMsg = Label.Duplicate_Territory;
                   	csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(territoryId) + ',' + errorMsg + ',' + 'Error,\n';
               }else{
                   	Outlet_Territory__c terriOutletObj = new Outlet_Territory__c(Outlet__c = currentRow[0].trim(),
                                                                                Territory__c = currentRow[1].trim(),
                                                                                Active__c = 'Waiting Activation');
					terOutltInsrtMap.put(cmpKey, terriOutletObj);
				}   
			}else{
            	csvFileProcessBatchWrapper.failureRowCount++;
                string errorMsg = Label.Invalid_Id_Territory;
                csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + outltIdStrng + ',' + terIdStrng + ',' + errorMsg + ',' + 'Error,\n'; 
            }              
        }
        //DML Operations
        if(!terOutltInsrtMap.isEmpty()){
            List<Outlet_Territory__c> terOutltInsrtList = terOutltInsrtMap.values();
            Database.SaveResult[] saveResultList =  Database.insert(terOutltInsrtList, false);
            Integer count = 0;
            for (Database.SaveResult saveResult : saveResultList) {
                if (saveResult.isSuccess()) {
                    csvFileProcessBatchWrapper.csvSuccessFileString = csvFileProcessBatchWrapper.csvSuccessFileString + string.valueOf(terOutltInsrtList[Count].Outlet__c) + ',' + string.valueOf(terOutltInsrtList[Count].Territory__c) + ',' + 'Success,\n';
                    csvFileProcessBatchWrapper.successRowCount++;
                }else {
                    csvFileProcessBatchWrapper.failureRowCount++;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(terOutltInsrtList[Count].Outlet__c) + ',' + string.valueOf(terOutltInsrtList[Count].Territory__c) + ',' + saveResult.getErrors()[0].getMessage() + ',' + 'Error,\n';
                }
                count++;
            }
        }
        return csvFileProcessBatchWrapper;
    }
    
    //Method Name : deleteOutltTerritory
	//Description : is used to Update Outlet_Territory Records
    public static EDGE_CSVFileProcessBatchWrapper deleteOutltTerritory(Set<Id> outletIdSet, Set<Id> territoryIdSet, List<List<String>> csvLines, Boolean firstRun){
        
        //Variable
        Map<String,Outlet_Territory__c> exstnTerriOutletMap = new Map<String,Outlet_Territory__c>();
        Map<String,Outlet_Territory__c> terOutltUpdtMap = new Map<String,Outlet_Territory__c>();
        EDGE_CSVFileProcessBatchWrapper csvFileProcessBatchWrapper = new EDGE_CSVFileProcessBatchWrapper();
        
        Integer j = 0;
        
        if(firstRun){
            j = 1;
        }
        
        if(!outletIdSet.isEmpty() && !territoryIdSet.isEmpty()){
            if(Schema.sObjectType.Outlet_Territory__c.isAccessible()){
                //Creating Existing Territory Outlet Map
                for(Outlet_Territory__c terOutObj : [SELECT Id,Outlet__c,Outlet__r.Status__c,Territory__c,Active__c 
                                                     FROM Outlet_Territory__c 
                                                     WHERE Territory__c IN :territoryIdSet
                                                     AND Outlet__c IN :outletIdSet ]){
                    String cmpKey = String.valueOf(terOutObj.Outlet__c) + String.valueOf(terOutObj.Territory__c);
                    exstnTerriOutletMap.put(cmpKey, terOutObj);
                }
            }
        }
        
        //Iterating over CSV file
        for(Integer i = j; i<csvLines.size(); i++){
            List<String> currentRow = csvLines[i];
            String outltIdStrng = string.valueOf(currentRow[0]).trim();
            String terIdStrng = string.valueOf(currentRow[1]).trim();
            csvFileProcessBatchWrapper.rowCount++;
            if((outltIdStrng.length() == 15 || outltIdStrng.length() == 18)
                &&(terIdStrng.length() == 15 || terIdStrng.length() == 18) ){
                Id outletId = outltIdStrng;
                Id territoryId = terIdStrng;
                String cmpKey = String.valueOf(outletId) + String.valueOf(territoryId);
                //Checking if already present or not
            	if(!exstnTerriOutletMap.isEmpty() && exstnTerriOutletMap.containsKey(cmpKey)){
                    Outlet_Territory__c terriOutletObj = exstnTerriOutletMap.get(cmpKey);
                    terriOutletObj.Active__c = 'Waiting Removal';
                    terOutltUpdtMap.put(cmpKey, terriOutletObj);
                }else{
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = Label.Invalid_outlet_territory_combination;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString +string.valueOf(outletId) + ',' + string.valueOf(territoryId) + ',' + errorMsg + ',' + 'Error,\n';
                }
            }else{
            	csvFileProcessBatchWrapper.failureRowCount++;
                string errorMsg = Label.Invalid_Id_Territory;
                csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + outltIdStrng + ',' + terIdStrng + ',' + errorMsg + ',' + 'Error,\n';         
          	}
         }
        if(!terOutltUpdtMap.isEmpty()){
            List<Outlet_Territory__c> terOutltUpdtList = terOutltUpdtMap.values();
            Database.SaveResult[] saveResultList =  Database.update(terOutltUpdtList, false);
            Integer count = 0;
            for (Database.SaveResult saveResult : saveResultList) {
                if (saveResult.isSuccess()) {
                    csvFileProcessBatchWrapper.csvSuccessFileString = csvFileProcessBatchWrapper.csvSuccessFileString + string.valueOf(terOutltUpdtList[Count].Outlet__c) + ',' + string.valueOf(terOutltUpdtList[Count].Territory__c)+ ',' + 'Success,\n';
                    csvFileProcessBatchWrapper.successRowCount++;
                }else {
                    csvFileProcessBatchWrapper.failureRowCount++;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(terOutltUpdtList[Count].Outlet__c) + ',' + string.valueOf(terOutltUpdtList[Count].Territory__c) + ',' + saveResult.getErrors()[0].getMessage() + ',' + 'Error,\n';
                }
                count++;
            }
        }
        return csvFileProcessBatchWrapper;
    }
    
    //Method Name : createTargtListMembr
	//Description : is used to Create Target_List_Member Records
    public static EDGE_CSVFileProcessBatchWrapper createTargtListMembr(Set<Id> outletIdSet, Set<Id> targetListIdSet, List<List<String>> csvLines, Boolean firstRun){
        //Variable
        Map<Id, Account> inactiveOutletMap = new Map<Id, Account>();
        Map<String, Target_List_Member__c> existngTrgtMembrMap = new Map<String, Target_List_Member__c>();
        Map<String, Target_List_Member__c> targetMbrInsrtMap = new Map<String, Target_List_Member__c>();
        Map<Id,Target_List__c> staticTrgtLstMap = new Map<Id,Target_List__c>();
        EDGE_CSVFileProcessBatchWrapper csvFileProcessBatchWrapper = new EDGE_CSVFileProcessBatchWrapper();
        
        Integer j = 0;
        //Variable
        if(firstRun){
            j = 1;
        }
        if(!outletIdSet.isEmpty()){
            if(Schema.sObjectType.Account.isAccessible()){
                //Creating inactive Outlet map
            	inactiveOutletMap = new Map<Id,Account>([SELECT Id, Status__c, RecordType.DeveloperName, RecordType.Name FROM Account WHERE Id IN :outletIdSet                                                         
                                                         AND (Status__c NOT IN ('Active') OR RecordType.DeveloperName != 'Outlet')]);
            }
        }
        //Creating Static Target List Map
        if(!targetListIdSet.isEmpty()){
            if(Schema.sObjectType.Target_List__c.isAccessible()){
                staticTrgtLstMap = new Map<Id,Target_List__c>([SELECT Id, RecordType.Name 
                                                               FROM Target_List__c 
                                                               WHERE RecordType.DeveloperName = 'Static_Target_List'
                                                               AND Id IN :targetListIdSet]);
            }
        }
        if(!outletIdSet.isEmpty() && !targetListIdSet.isEmpty()){
            if(Schema.sObjectType.Target_List_Member__c.isAccessible()){
                //Creating Existing Target List Member Map
                for(Target_List_Member__c targtMembrObj : [SELECT Id,Outlet__c,Outlet__r.Status__c,Target_List__c 
                                                           FROM Target_List_Member__c 
                                                           WHERE Target_List__c IN :targetListIdSet
                                                           AND Outlet__c IN :outletIdSet ]){
                    String cmpKey = String.valueOf(targtMembrObj.Outlet__c) + String.valueOf(targtMembrObj.Target_List__c);
                    existngTrgtMembrMap.put(cmpKey,targtMembrObj);
                }
            }                       
        }
        //Iterating over CSV file
        for(Integer i = j; i<csvLines.size();i++){
            List<String> currentRow = csvLines[i];
            Boolean isNewRecord = true;
            String outltIdStrng = string.valueOf(currentRow[0]).trim();
            String targtIdStrng = string.valueOf(currentRow[1]).trim();
            csvFileProcessBatchWrapper.rowCount++;
            if((outltIdStrng.length() == 15 || outltIdStrng.length() == 18)
                &&(targtIdStrng.length() == 15 || targtIdStrng.length() == 18) ){
            	Id outletId = outltIdStrng;  
                Id targetListId = targtIdStrng;
                String cmpKey = String.valueOf(outletId) + String.valueOf(targetListId);
                //Checking if Outlet is Inactive or already present
                if(!inactiveOutletMap.isEmpty() && inactiveOutletMap.containsKey(outletId)){
                    isNewRecord = false;
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = '';
                    if(inactiveOutletMap.get(outletId).RecordType.DeveloperName != 'Outlet'){
                        errorMsg = Label.You_cannot_add + ' ' + inactiveOutletMap.get(outletId).RecordType.Name + ' ' + Label.Outlet;
                    }else if(inactiveOutletMap.get(outletId).Status__c != 'Active'){
                        errorMsg = Label.Inactive_Status + ' ' + inactiveOutletMap.get(outletId).Status__c;
                    }
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(targetListId) + ',' + errorMsg + ',' + 'Error,\n';
                    
                }else if(staticTrgtLstMap.isEmpty()||(!staticTrgtLstMap.isEmpty() && !staticTrgtLstMap.containsKey(targetListId))){
                    isNewRecord = false;
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = Label.Invalid_Target_list;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(targetListId) + ',' + errorMsg + ',' + 'Error,\n';
                }else if(!existngTrgtMembrMap.isEmpty() && existngTrgtMembrMap.containsKey(cmpKey)){
                    isNewRecord = false;
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = Label.Duplicate_Target_Iist;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(targetListId) + ',' + errorMsg + ',' + 'Error,\n';
                }else if(!staticTrgtLstMap.isEmpty() && staticTrgtLstMap.containsKey(targetListId)){
                    Target_List_Member__c targetMembrObj = new Target_List_Member__c(Outlet__c = currentRow[0].trim(),
                                                                                     Target_List__c = currentRow[1].trim(),
                                                                                     Assignment_Status__c = 'Waiting Activation');
                    targetMbrInsrtMap.put(cmpKey,targetMembrObj);
                }
            }else{
                csvFileProcessBatchWrapper.failureRowCount++;
                string errorMsg = Label.Invalid_Id_TargetList;
                csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + outltIdStrng + ',' + targtIdStrng + ',' + errorMsg + ',' + 'Error,\n';   
            }
        }
        
        //DML Operation
        if(!targetMbrInsrtMap.isEmpty()){
            List<Target_List_Member__c> targetMbrInsrtList = targetMbrInsrtMap.values();
            Database.SaveResult[] saveResultList = Database.insert(targetMbrInsrtList, false);
            Integer count = 0;
            for (Database.SaveResult saveResult : saveResultList) {
                if (saveResult.isSuccess()) {
                    csvFileProcessBatchWrapper.csvSuccessFileString = csvFileProcessBatchWrapper.csvSuccessFileString + string.valueOf(targetMbrInsrtList[count].Outlet__c) + ',' + string.valueOf(targetMbrInsrtList[count].Target_List__c) + ',' + 'Success,\n';
                    csvFileProcessBatchWrapper.successRowCount++;
                }else {
                    csvFileProcessBatchWrapper.failureRowCount++;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(targetMbrInsrtList[count].Outlet__c)+','+string.valueOf(targetMbrInsrtList[count].Target_List__c) + ',' + saveResult.getErrors()[0].getMessage() + ',' + 'Error,\n';
                }
                count++;
            }
        }
        return csvFileProcessBatchWrapper;
    }
    
    //Method Name : deleteTargtListMembr
	//Description : is used to Update Target_List_Member Records
    public static EDGE_CSVFileProcessBatchWrapper deleteTargtListMembr(Set<Id> outletIdSet, Set<Id> targetListIdSet, List<List<String>> csvLines, Boolean firstRun){
        //Variable  
        Map<String, Target_List_Member__c> existngTrgtMembrMap = new Map<String, Target_List_Member__c>();
        Map<String, Target_List_Member__c> targetMbrUpdtMap = new Map<String, Target_List_Member__c>();
        Map<Id,Target_List__c> staticTrgtLstMap = new Map<Id,Target_List__c>();
        EDGE_CSVFileProcessBatchWrapper csvFileProcessBatchWrapper = new EDGE_CSVFileProcessBatchWrapper();
        Integer j = 0;
        
        //Variable
        if(firstRun){
            j = 1;
        }
        
        //Creating Static Target List Map
        if(!targetListIdSet.isEmpty()){
            if(Schema.sObjectType.Target_List__c.isAccessible()){
                staticTrgtLstMap = new Map<Id,Target_List__c>([SELECT Id, RecordType.Name 
                                                               FROM Target_List__c 
                                                               WHERE RecordType.DeveloperName = 'Static_Target_List'
                                                               AND Id IN :targetListIdSet]);
            }
        }

		//Creating Existing Target member Map  
        if(!outletIdSet.isEmpty() && !targetListIdSet.isEmpty()){
            if(Schema.sObjectType.Target_List_Member__c.isAccessible()){
                for(Target_List_Member__c targtMemObj : [SELECT Id,Outlet__c,Outlet__r.Status__c,Target_List__c,Assignment_Status__c 
                                                         FROM Target_List_Member__c 
                                                         WHERE Target_List__c IN :targetListIdSet
                                                         AND Outlet__c IN :outletIdSet 
                                                         AND Target_List__r.RecordType.DeveloperName = 'Static_Target_List']){
                    String cmpKey = String.valueOf(targtMemObj.Outlet__c) + String.valueOf(targtMemObj.Target_List__c);
                    existngTrgtMembrMap.put(cmpKey,targtMemObj);
                }
            }
        }
        
        //Iterating over CSV file
        for(Integer i = j; i<csvLines.size();i++){
            List<String> currentRow = csvLines[i];
            String outltIdStrng = string.valueOf(currentRow[0]).trim();
            String targtIdStrng = string.valueOf(currentRow[1]).trim();
            csvFileProcessBatchWrapper.rowCount++;
            if((outltIdStrng.length() == 15 || outltIdStrng.length() == 18)
                &&(targtIdStrng.length() == 15 || targtIdStrng.length() == 18)){
                Id outletId = outltIdStrng;
                Id targetListId = targtIdStrng;
                String cmpKey = String.valueOf(outletId) + String.valueOf(targetListId);
                if(staticTrgtLstMap.isEmpty()||(!staticTrgtLstMap.isEmpty() && !staticTrgtLstMap.containsKey(targetListId))){
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = Label.Invalidd_Removal_Operation;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(targetListId) + ',' + errorMsg + ',' + 'Error,\n';
                }else if(!existngTrgtMembrMap.isEmpty() && existngTrgtMembrMap.containsKey(cmpKey)){
                    Target_List_Member__c trgtLstMbrObj = existngTrgtMembrMap.get(cmpKey);
                    trgtLstMbrObj.Assignment_Status__c = 'Waiting Removal';
                    targetMbrUpdtMap.put(cmpKey,trgtLstMbrObj);
                }else{
                    csvFileProcessBatchWrapper.failureRowCount++;
                    string errorMsg = Label.Invalid_outlet_selection;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueOf(outletId) + ',' + string.valueOf(targetListId) + ',' + errorMsg + ',' + 'Error,\n';
                }
            }else{
            	csvFileProcessBatchWrapper.failureRowCount++;
                string errorMsg = Label.Invalid_Id_TargetList;
                csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + outltIdStrng + ',' + targtIdStrng + ',' + errorMsg + ',' + 'Error,\n';           
            }
        }
        if(!targetMbrUpdtMap.isEmpty()){
            List<Target_List_Member__c> targetMbrUpdtList = targetMbrUpdtMap.values();
            Database.SaveResult[] saveResultList =  Database.update(targetMbrUpdtList, false);
            Integer count = 0;
            for (Database.SaveResult saveResult : saveResultList) {
                if (saveResult.isSuccess()) {
                    csvFileProcessBatchWrapper.csvSuccessFileString = csvFileProcessBatchWrapper.csvSuccessFileString + string.valueOf(targetMbrUpdtList[Count].Outlet__c) + ',' + string.valueOf(targetMbrUpdtList[Count].Target_List__c)+ ',' + 'Success,\n';
                    csvFileProcessBatchWrapper.successRowCount++;
                }else {
                    csvFileProcessBatchWrapper.failureRowCount++;
                    csvFileProcessBatchWrapper.csvErrorFileString = csvFileProcessBatchWrapper.csvErrorFileString + string.valueof(targetMbrUpdtList[Count].Outlet__c) + ',' + string.valueof(targetMbrUpdtList[Count].Target_List__c) + ',' + saveResult.getErrors()[0].getMessage() + ',' + 'Error,\n';
                }
                count++;
            }
        }
        return csvFileProcessBatchWrapper;
    }
}