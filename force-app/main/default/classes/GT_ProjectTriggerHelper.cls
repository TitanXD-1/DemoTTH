/**
********************
* @Name: GT_ProjectTriggerHelper
* @Created: 1 September 2023
* @Description: Helper for GT_ProjectTriggerHandler, for Global Travel related functions
* @Test Class: GT_ProjectTriggerHandlerTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Tanishq     01/09/2023     140668 [GT-42] Implementation of Auto generation of Predefined Tasks when a project moves through phases
********************
*/

public with sharing class GT_ProjectTriggerHelper {

    /**
* @name: createAndValidateTasks
* @description: Splits logic into different method calls for Update and Insert Scenarios
* @param: Map<Id,SObject> newItems, Map<Id,SObject> oldItems
* @return: void
*/    
    public static void createAndValidateTasks(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){       
        Map<Id,GT_Project__c> mapOldItems;
        Map<Id,GT_Project__c> mapNewItems;
        List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst = new List<GT_Project_Phase_Task_Setting__mdt>();
       	if(oldItems != null){
            mapOldItems = (Map<Id,GT_Project__c>)oldItems;
        }
        if(newItems != null){
            mapNewItems = (Map<Id,GT_Project__c>)newItems;
        }
        if(!(GT_Project_Phase_Task_Setting__mdt.getAll().values().isEmpty())){
            for(GT_Project_Phase_Task_Setting__mdt mdtSett : GT_Project_Phase_Task_Setting__mdt.getAll().values()){
                if(mdtSett.GT_Active__c){
                    mdtSettLst.add(mdtSett);
                }               
            }
        }
        if(!(mdtSettLst.isEmpty())) {
            if(oldItems!=null){
                updatePhaseBranchCondition(mapNewItems,mapOldItems,mdtSettLst);            
            }else if(oldItems==null){
                insertTaskOnCreate(mapNewItems,mdtSettLst);
            }
        }                              
    }

    /**
* @name: updatePhaseBranchCondition
* @description: checks Update condition of Project on Phase change
* @param: Map<Id,GT_Project__c> mapNewItems,Map<Id,GT_Project__c> mapOldItems, List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst
* @return: void
*/
    public static void updatePhaseBranchCondition(Map<Id,GT_Project__c> mapNewItems, Map<Id,GT_Project__c> mapOldItems, List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst){      
        Map<Id,GT_Project__c> filteredItems = new Map<Id,GT_Project__c>();
        for(GT_Project__c projObj:mapNewItems.values()){
            if(mapOldItems.containsKey(projObj.Id) && mapOldItems.get(projObj.Id).GT_Phase__c != projObj.GT_Phase__c){                
                filteredItems.put(projObj.Id,projObj);
            }
        }
        if(filteredItems != null && !((filteredItems.keySet()).isEmpty())){
            insertTaskOnUpdate(filteredItems,mdtSettLst);
        }
    }

    /**
* @name: insertTaskOnCreate
* @description: Creates Tasks on Insert of Project
* @param: Map<Id,GT_Project__c> newItems, List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst
* @return: void
*/        
    public static void insertTaskOnCreate(Map<Id,GT_Project__c> newItems,List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst){       
        List<Task> taskToInsert = new List<Task>();
        for(Id projId:newItems.keySet()){
            for(GT_Project_Phase_Task_Setting__mdt mdtTask : mdtSettLst){
                if(newItems.get(projId).GT_Phase__c == mdtTask.GT_Phase__c){
                    Task newTask = createTasks(mdtTask,projId,newItems);
                    taskToInsert.add(newTask);
                }
            }
        }
        if(!taskToInsert.isEmpty() && Schema.sObjectType.Task.isCreateable()){
            insert taskToInsert;
        }
    }
    
        /**
* @name: insertTaskOnUpdate
* @description: Creates Tasks when Project navigates through different phases
* @param: Map<Id,GT_Project__c> filteredItems, List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst
* @return: void
*/    
    public static void insertTaskOnUpdate(Map<Id,GT_Project__c> filteredItems,List<GT_Project_Phase_Task_Setting__mdt> mdtSettLst){       
        Set<String> uniqueTaskKeySet;
        List<Task> taskToInsert = new List<Task>();                    
        List<Task> availableTask = [Select Id,Status,GT_Task_Unique_Key__c,GT_Task_Phase__c,OwnerId,WhatId,Subject FROM Task WHERE WhatId IN:filteredItems.keySet()];
        for(Id projId : filteredItems.keySet()){
            uniqueTaskKeySet = buildUniqTaskKeySet(availableTask,projId,filteredItems);                  
            for(GT_Project_Phase_Task_Setting__mdt mdtTask : mdtSettLst){
                if(filteredItems.get(projId).GT_Phase__c == mdtTask.GT_Phase__c && 
                ((!uniqueTaskKeySet.isEmpty() && !uniqueTaskKeySet.contains(mdtTask.DeveloperName)) || 
                uniqueTaskKeySet.isEmpty())){
                    Task newTask = createTasks(mdtTask,projId,filteredItems);
                    newTask.OwnerId = filteredItems.get(projId).GT_Owner__c;
                    taskToInsert.add(newTask);
                }                            
            }
        }
        if(!taskToInsert.isEmpty() && Schema.sObjectType.Task.isCreateable()){
            insert taskToInsert;
        }
    }

            /**
* @name: buildUniqTaskKeySet
* @description: Creates Set of Task Unique keys if few Target-Phase Tasks are existing in Project
* @param: List<Task> availableTask,Id projId,Map<Id,GT_Project__c> filteredItems
* @return: Set<String>
*/ 
    public static Set<String> buildUniqTaskKeySet(List<Task> availableTask,Id projId,Map<Id,GT_Project__c> filteredItems){
        Set<String> uniqueTaskKeySet = new Set<String>();
        if(!availableTask.isEmpty()){
            for(Task taskObj: availableTask){
                if(taskObj.WhatId == projId && filteredItems.get(projId).GT_Phase__c == taskObj.GT_Task_Phase__c){
                    uniqueTaskKeySet.add(taskObj.GT_Task_Unique_Key__c);
                }
            }
        }
        return uniqueTaskKeySet;
    }

            /**
* @name: createTasks
* @description: Creates Tasks for different menthod calls in this class
* @param: GT_Project_Phase_Task_Setting__mdt mdtTask,Id projId,Map<Id,GT_Project__c> filteredItems
* @return: Task
*/ 
    public static Task createTasks(GT_Project_Phase_Task_Setting__mdt mdtTask, Id projId, Map<Id,GT_Project__c> filteredItems){
        Task newTask = new Task();
        newTask.WhatId = projId;
        newTask.GT_Task_Unique_Key__c = mdtTask.DeveloperName;
        newTask.Status = Label.GT_Task_Status;
        newTask.GT_Task_Phase__c = mdtTask.GT_Phase__c;
        newTask.Description = mdtTask.GT_Phase__c;
        newTask.OwnerId = filteredItems.get(projId).CreatedById;
        newTask.Subject = mdtTask.GT_Task_Name__c;
        return newTask;
    }            
}