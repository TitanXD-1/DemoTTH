/*
*@Name: ECM_TerritorySelectionController
*@Purpose: This class is used in ECM_Territory_Selection (Aura definition) to fetch records
*
*@History                                                                                                                     
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Saurav Prasad		10/07/2023			142555	:	CM static code violation for the classes_SFDC_Technical Debt
*2.0            Suvendu Roy         10/11/2023          146197  :   Enable Addendum functionality for AS (Change Contract)
*3.0            Joshraj Sen         20/11/2023          148533  :   Enable Addendum functionality for AS via Account Object and Not Wrapper
*4.0            Joshraj Sen         19/12/2023          149477  :   Optimize the getOutletTerritory Query
*/
public with sharing class ECM_TerritorySelectionController {
	@AuraEnabled
    public static Account getoutletTerritory(string outletrecId){
        try {
            Account acc=[Select Id,Activation_Territory_LT__r.Name,Activation_Territory_LT__c,Primary_Sales_Territory__r.Name,Primary_Sales_Territory__c  from Account where id=:outletrecId WITH SECURITY_ENFORCED LIMIT 1]; //Optimized Query       
            return acc;
        }
        catch(exception e){
            System.debug(LoggingLevel.DEBUG,'Exception Caught at Line: '+e.getLineNumber()+'\n Error: '+e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static List<Territory_Member__c> getUserTerritories(){        
        try{
            List<Territory_Member__c> tmList=New List<Territory_Member__c>();
        	List<Territory_Member__c> terrList= [Select Id,User__c,Type__c,End_Date__c,Territory__c,Territory__r.Name from Territory_Member__c where User__c =:userinfo.getUserId() WITH SECURITY_ENFORCED];   
            system.debug(LoggingLevel.DEBUG,'terrList'+terrList);
            for(Territory_Member__c tm:terrList){
                if(tm.End_Date__c >=date.today() || tm.End_Date__c ==null){
                    tmList.add(tm);
                }
            }
            return tmList;
        } 
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,'error'+e.getMessage());
        }
        return null;
    }
    /*public class TerritoryWrapper{
        @AuraEnabled public String terrName {get;set;}
        @AuraEnabled public String terrId {get;set;}
    }*/
}