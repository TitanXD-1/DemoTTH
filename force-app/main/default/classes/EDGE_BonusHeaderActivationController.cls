/**********************************************************************
Name: EDGE_BonusHeaderActivationController
=======================================================================
Req: 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0		 Sagar Barman 		10/01/2020		 ES20-4583(Activate Bonus header record)
***********************************************************************/
public with sharing class EDGE_BonusHeaderActivationController {
    @AuraEnabled
    public static EDGE_BonusHeaderActivationWrapper validateBonusHeader(Id bhId){
        Boolean totalPercentageCheck = false;
        Set<Id> territoryIDSet = new Set<Id>();
        List<Bonus_Cycle__c>  bonusCycleList = new List<Bonus_Cycle__c>();
        Map<String,string> mapTerritoryToActiveBonus = new Map<String,string>();
        List<String> territoryPecertageFailedString = new List<String>();
        if(Schema.SObjectType.Bonus_Cycle__c.isAccessible() && Schema.SObjectType.Bonus_Header__c.isAccessible() && Schema.SObjectType.Market_Cycle__c.isAccessible()){
            bonusCycleList = [SELECT Market_Cycle__c,Market_Cycle__r.Active__c FROM Bonus_Cycle__c WHERE Bonus_Header__c = : bhId and Market_Cycle__r.Active__c=true];
        }
        //get the current record status
        Bonus_Header__c currentRecord = new Bonus_Header__c();
        if(Schema.SObjectType.Bonus_Header__c.isAccessible()){        
        	currentRecord = [SELECT ID, Status__c FROM Bonus_Header__c WHERE ID =: bhId];
        }    
        EDGE_BonusHeaderActivationWrapper bhWrapper = new EDGE_BonusHeaderActivationWrapper();  
        if(currentRecord.Status__c == 'Active'){
            bhWrapper.isSuccess = false;
            bhWrapper.resultMessage = Label.EDGE_BonusHeaderNotActivated;
            bhWrapper.reason = Label.EDGE_BonusHeaderAlreadyActive;    
        }else if(bonusCycleList.size() == 0){
            bhWrapper.isSuccess = false;
            bhWrapper.resultMessage = Label.EDGE_BonusHeaderNotActivated;
            bhWrapper.reason = Label.EDGE_BonusHeaderNoBonusCycle;
        }else {
            List<Bonus_Assignment__c> bonusAssignmentList = new List<Bonus_Assignment__c>();
            if(Schema.SObjectType.Bonus_Header__c.isAccessible() && Schema.SObjectType.Bonus_Assignment__c.isAccessible() ){
                bonusAssignmentList = [SELECT Bonus_Detail__c,Bonus_Header__c,Global_Percentage__c,Territory_Percentage__c,Total__c,Territory__c,Territory__r.Name FROM Bonus_Assignment__c 
                                       WHERE Bonus_Header__c =:bhId AND Recordtype.Name = 'Bonus Header'];
            }
            if(bonusAssignmentList.size() == 0){
                bhWrapper.isSuccess = false;
                bhWrapper.resultMessage = Label.EDGE_BonusHeaderNotActivated;
                bhWrapper.reason = Label.EDGE_BonusHeaderNoAssignment;    
            }
            else {
                for(Bonus_Assignment__c ba : bonusAssignmentList)
                {
                    Decimal total = 0.0;
                    String tempString = '';
                    territoryIDSet.add(ba.Territory__c);
                    if(null!=ba.Global_Percentage__c && null != ba.Territory_Percentage__c){
                        total = ba.Global_Percentage__c + ba.Territory_Percentage__c;
                        tempString = 'Territory : '+ba.Territory__r.Name+','+' Global Percentage is : '+ String.valueOf(ba.Global_Percentage__c)+' Territory Percentage is : '+String.valueOf(ba.Territory_Percentage__c);
                    }
                    if(null == ba.Global_Percentage__c && null != ba.Territory_Percentage__c){
                        total =  ba.Territory_Percentage__c; 
                        tempString ='Territory : '+ba.Territory__r.Name+','+' Global Percentage is : '+'Territory Percentage is : '+String.valueOf(ba.Territory_Percentage__c);
                    }
                    if(null != ba.Global_Percentage__c && null == ba.Territory_Percentage__c){
                        total =  ba.Global_Percentage__c; 
                        tempString = 'Territory : '+ba.Territory__r.Name+','+' Global Percentage is : '+String.valueOf(ba.Global_Percentage__c)+' Territory Percentage is : ';
                    }
                    if(total <> Decimal.valueOf(100)){
                        totalPercentageCheck = true;                     
                        territoryPecertageFailedString.add(tempString);
                    }
                }
                List<Bonus_Assignment__c> activeBHList = new List<Bonus_Assignment__c>();
                if(territoryIDSet.size()>0 && Schema.SObjectType.Bonus_Assignment__c.isAccessible() && Schema.SObjectType.Bonus_Header__c.isAccessible() && Schema.SObjectType.Territory__c.isAccessible()){
                    activeBHList = [SELECT ID,Territory__r.Name,Bonus_Header__r.Name,Territory__c FROM Bonus_Assignment__c WHERE Bonus_Header__r.Status__c = 'Active' AND Territory__c IN : territoryIDSet];
                }
                for(Bonus_Assignment__c ba : activeBHList){
                    String key = ba.Territory__c+'_'+ba.Territory__r.Name;
                    mapTerritoryToActiveBonus.put(key,ba.Bonus_Header__r.Name);    
                }
                if(activeBHList.size() > 0){//if one of the territories already associated with active Bonus Header
                    bhWrapper.isSuccess = false;
                    bhWrapper.resultMessage = Label.EDGE_BonusHeaderNotActivated;
                    bhWrapper.reason = Label.EDGE_BonusHeaderTerritoryValidation;
                    if(null != mapTerritoryToActiveBonus){
                        for(String key : mapTerritoryToActiveBonus.keySet()){
                            String terrName = key.split('_')[1];
                            bhWrapper.reason += '<br/> Territory : '+  terrName + ' is associated with Active Bonus ' + mapTerritoryToActiveBonus.get(key);   
                        }    
                    }
                }
                else if(totalPercentageCheck){
                    bhWrapper.isSuccess = false;
                    bhWrapper.resultMessage = Label.EDGE_BonusHeaderNotActivated;
                    bhWrapper.reason = Label.EDGE_BonusHeaderPercentageValidation;
                    if(territoryPecertageFailedString.size()>0){
                        for(String str : territoryPecertageFailedString){
                            bhWrapper.reason += '<br/> Information : '+str;	
                        }    
                    }
                }
                else {
                    bhWrapper.isSuccess = true;
                    bhWrapper.resultMessage = Label.EDGE_BonusHeaderActivated;
                    bhWrapper.reason = '';
                } 
            }
        } 
        
        if(bhWrapper.isSuccess){
            Bonus_Header__c bHeader = new Bonus_Header__c();
            if(Schema.SObjectType.Bonus_Header__c.isAccessible() && Schema.SObjectType.Bonus_Header__c.isUpdateable()){
                bHeader = [SELECT Id,Status__c FROM Bonus_Header__c WHERE Id =: bhId];
                bHeader.Status__c = 'Active';
                update bHeader;
            }
        }
        return bhWrapper;
        
    }
}