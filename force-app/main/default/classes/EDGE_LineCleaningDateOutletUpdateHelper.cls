/**
* @ Name : EDGE_LineCleaningDateOutletUpdateHelper
* @ Description : Helper class for EDGE_LineCleaningDateOutletUpdateBatch
* @ History  
* @ Author                   Version    			 Date           Detail
* @	Rajarshi Lahiri       Initial Development	   30/01/2023     ES20-13471
**/

public with sharing class EDGE_LineCleaningDateOutletUpdateHelper {
    
    public static void setAccMap(Case_Task__c caseTask,Map<Id,Account> accMap){
         if(caseTask.Line_Cleaning_Due_Date__c!=null){
             Account outlet=new Account(Id=caseTask.Account__c);
             outlet.Next_Line_Cleaning_Date__c=caseTask.Line_Cleaning_Due_Date__c.Date();
             accMap.put(caseTask.Account__c,outlet);
          }
    }
    
    public static void setLCDateBlank(Account accRec,Set<Id> accSet,Map<Id,Account> accMap){
        if(!accSet.contains(accRec.Id) && !accMap.containsKey(accRec.Id)){
            Account outlet=new Account(Id=accRec.Id);
            outlet.Next_Line_Cleaning_Date__c=null;
            accMap.put(accRec.Id,outlet);
          }
    }

}