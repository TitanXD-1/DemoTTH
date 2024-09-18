/**
* @description EDGE_OpportunityOperations
* @history

Author              Version     Date           Detail
Dipanjan Das        v1.0        16/04/2019		ES20-764 : Contains Opportunity Creation and Deletion Methods
Mayukh Roy			v1.1		11/04/2022		ES20-12487 : April_UAT_Regression_EDGE_UpdateTargetListMemberBatch is failing
Rajarshi Lahiri		v1.2 	    22/07/2022		ES20-13152(Bug fix)
Monalisa Halder     v2.0        22/12/2022		ES20-13673
Rajarshi Lahiri     v3.0		01/02/2023		ES20-13771
Saurav Prasad		v3.1		05/08/2024		155306 : GB Opportunity Scoring: Generate Cycle Brief Opportunity in EDGE when template source is set to 'EDGE'
Doman Murmu			v3.2		16/08/2024		155896 : GB Opportunity Scoring: Enhance Deletion Logic for "EDGE' based Cycle Brief Opportunities on removing Outlets from Target list
Sakshi Shah         v4.0        13/09/2024      156186 : 'Not Achieved' Staged Cycle Briefs should NOT be deleted for removed Outlets via Target Lists
**/

public without sharing class EDGE_OpportunityOperations {
    
    //Create Oppty Method
    public static void createOpportunities(set<string> outletOppTemplateSet, set<Id> outletIdSet, set<Id> oppTemplateIdSet){
        Map<Id, Opportunity_Template__c> oppTemplateMap;
        Set<String> existingOutletOppTemplateSet = new Set<String>();
        List<Opportunity> oppListtoInsert = new List<Opportunity>();
        List<String> oppStagesTofilter = Label.EDGE_OppStagesToDelete.split(',');
        //Get Existing Opportunities for outlets
        for(Opportunity oppRec : [SELECT AccountId, Opportunity_Template__c FROM Opportunity WHERE AccountId IN :outletIdSet AND Opportunity_Template__c IN :oppTemplateIdSet AND StageName IN:oppStagesTofilter WITH SECURITY_ENFORCED]){
            String key = oppRec.AccountId + '-' + oppRec.Opportunity_Template__c;
            existingOutletOppTemplateSet.add(key);
        }
        
        //Create Opportunitiy Template map
        //155306
        oppTemplateMap = new Map<Id,Opportunity_Template__c>([SELECT Id, Opportunity_Type__c, Action__c, Start_Date__c, Product__c, Source__c FROM Opportunity_Template__c WHERE Id IN:oppTemplateIdSet WITH SECURITY_ENFORCED]); 
        
        //Create Opportunity List for Outlets
        for(String key : outletOppTemplateSet){
            if(existingOutletOppTemplateSet != null && !existingOutletOppTemplateSet.contains(key)){
                List<string> tempList = key.split('-');
                string outletId = tempList[0];
                string oppTemplateId = tempList[1];
                
                oppListtoInsert.add(createOpportunity(outletId, oppTemplateMap.get(oppTemplateId)));
            }
        }
        
        //Insert Opportunities
        if(oppListtoInsert != null && oppListtoInsert.size() > 0 && Schema.sObjectType.Opportunity.isCreateable()){
            // ES20-13673
             Database.insert(oppListtoInsert,false);
            //insert oppListtoInsert;
        }       
    }
    /*
    //ES20-13771
    public static List<opportunity> createOpportunityList(set<string> outletOppTemplateSet, set<Id> outletIdSet, set<Id> oppTemplateIdSet){
        Map<Id, Opportunity_Template__c> oppTemplateMap;
        Set<String> existingOutletOppTemplateSet = new Set<String>();
        List<Opportunity> oppListtoInsert = new List<Opportunity>();
        List<String> oppStagesTofilter = Label.EDGE_OppStagesToDelete.split(',');
        //Get Existing Opportunities for outlets
        for(Opportunity oppRec : [SELECT AccountId, Opportunity_Template__c FROM Opportunity WHERE AccountId IN :outletIdSet AND Opportunity_Template__c IN :oppTemplateIdSet AND StageName IN:oppStagesTofilter WITH SECURITY_ENFORCED]){
            String key = oppRec.AccountId + '-' + oppRec.Opportunity_Template__c;
            existingOutletOppTemplateSet.add(key);
        }
        
        //Create Opportunitiy Template map
        oppTemplateMap = new Map<Id,Opportunity_Template__c>([SELECT Id, Opportunity_Type__c, Action__c, Start_Date__c, Product__c FROM Opportunity_Template__c WHERE Id IN:oppTemplateIdSet]); 
        
        //Create Opportunity List for Outlets
        for(String key : outletOppTemplateSet){
            if(existingOutletOppTemplateSet != null && !existingOutletOppTemplateSet.contains(key)){
                List<string> tempList = key.split('-');
                string outletId = tempList[0];
                string oppTemplateId = tempList[1];
                
                oppListtoInsert.add(createOpportunity(outletId, oppTemplateMap.get(oppTemplateId)));
            }
        }
        
        /*
        //Insert Opportunities
        if(oppListtoInsert != null && oppListtoInsert.size() > 0 && Schema.sObjectType.Opportunity.isCreateable()){
            // ES20-13673
             //Database.insert(oppListtoInsert,false);
            //insert oppListtoInsert;
            return 
        }  
        return oppListtoInsert;
    }
    
    //ES20-13771
    public static List<Opportunity> deleteOpportunityList(set<string> outletOppTemplateSet, set<Id> oppTemplateIdset){
        String cycleBriefOppType = 'Cycle Brief';
        Map<Id, Set<Id>> targetListWithActiveOppTemplateMap = new Map<Id, Set<Id>>();
        //set<string> existingOutletOppTemplateSet = new set<string>();
        List<Opportunity> deleteOppList = new List<Opportunity>();
        Set<Id> outletSetId = new Set<Id>(); //ES20-12487 
        //ES20-13152
        List<String> oppStagesToDelete = Label.EDGE_OppStagesToDelete.split(',');
        
        //Get Existing Target List for same opp template having activity target list status = Active
        for(Activity_Target_List__c actTargetLst : [SELECT Id, Target_List__c, Opportunity_Template__c FROM Activity_Target_List__c WHERE Opportunity_Template__c IN :oppTemplateIdset AND Status__c = 'Active' AND Opportunity_Template__r.Opportunity_Type__c = :cycleBriefOppType WITH SECURITY_ENFORCED]){
            if(targetListWithActiveOppTemplateMap.containsKey(actTargetLst.Target_List__c)){
                targetListWithActiveOppTemplateMap.get(actTargetLst.Target_List__c).add(actTargetLst.Opportunity_Template__c);
            }else{
                targetListWithActiveOppTemplateMap.put(actTargetLst.Target_List__c , new Set<Id> {actTargetLst.Opportunity_Template__c});
            }
        }
        
        //ES20-12487 for getting the Outlet Ids associated with the Opportunity 
        for(String key : outletOppTemplateset){
            String outletId = key.substringBefore('-');
            outletSetId.add(outletId);
        }
        //Get Target List Member for Target List which we got above
        for(Target_List_Member__c targetLstMem : [SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE Target_List__c IN :targetListWithActiveOppTemplateMap.keySet() AND Assignment_Status__c ='Active' and Outlet__c IN :outletSetId WITH SECURITY_ENFORCED]){ //ES20-12487 added filter Outlet
            //This gives me combination of outlet & template which are linked with another Target List for which ATL is not marked as Waiting Removal. We dont need bypass this combination from deletion            
            if(targetListWithActiveOppTemplateMap != null && targetListWithActiveOppTemplateMap.containsKey(targetLstMem.Target_List__c)){
                for(Id oppTemplateId : targetListWithActiveOppTemplateMap.get(targetLstMem.Target_List__c)){
                    string key = targetLstMem.Outlet__c + '-' + oppTemplateId;
                    //existingOutletOppTemplateSet.add(key);
                    
                    outletOppTemplateSet.remove(key);
                }
            }
        }
        
        //Get All Opportunities that needs to be deleted from system
        //ES20-13152
         List<Opportunity> finalOppListToDelete = new List<Opportunity>();
        if(Schema.sObjectType.Opportunity.isAccessible()){
           
            //deleteOppList = [SELECT Id FROM Opportunity WHERE OutletWithTemplateId__c IN :outletOppTemplateSet AND StageName IN:OppStagesToDelete];
            //ES20-13152
            deleteOppList = [SELECT Id,OutletWithTemplateId__c FROM Opportunity WHERE AccountId IN :outletSetId AND StageName IN:oppStagesToDelete
                            AND Opportunity_Template__c in :oppTemplateIdSet];
        }

        //ES20-13152
        if(deleteOppList != null && deleteOppList.size()>0 && Schema.sObjectType.Opportunity.isDeletable()){
            for(Opportunity oppRec :deleteOppList){
                if(outletOppTemplateSet.contains(oppRec.OutletWithTemplateId__c)){
                    finalOppListToDelete.add(oppRec);
				}
            }
            /*
            if(finalOppListToDelete!=null && finalOppListToDelete.size()>0){
                // ES20-13673
             	Database.delete(finalOppListToDelete,false);
                //delete finalOppListToDelete;
            }
            
            //delete deleteOppList;
        }

        return finalOppListToDelete;
    }
    */
    //New Delete Oppty Method
    public static void deleteOpportunities(set<string> outletOppTemplateSet, set<Id> oppTemplateIdSet){
        String cycleBriefOppType = 'Cycle Brief';
        Map<Id, Set<Id>> targetListWithActiveOppTemplateMap = new Map<Id, Set<Id>>();
        //set<string> existingOutletOppTemplateSet = new set<string>();
        //List<Opportunity> deleteOppList = new List<Opportunity>();
        Set<Id> outletSetId = new Set<Id>(); //ES20-12487 
        //ES20-13152
        List<String> oppStagesToDelete = Label.EDGE_UpdatedOppStagesToDelete.split(','); //Updated Custom Label without 'Not Acheived' value
     
        
        //Get Existing Target List for same opp template having activity target list status = Active
        for(Activity_Target_List__c actTargetLst : [SELECT Id, Target_List__c, Opportunity_Template__c FROM Activity_Target_List__c WHERE Opportunity_Template__c IN :oppTemplateIdset AND Status__c = 'Active' AND Opportunity_Template__r.Opportunity_Type__c = :cycleBriefOppType WITH SECURITY_ENFORCED]){
            if(targetListWithActiveOppTemplateMap.containsKey(actTargetLst.Target_List__c)){
                targetListWithActiveOppTemplateMap.get(actTargetLst.Target_List__c).add(actTargetLst.Opportunity_Template__c);
            }else{
                targetListWithActiveOppTemplateMap.put(actTargetLst.Target_List__c , new Set<Id> {actTargetLst.Opportunity_Template__c});
            }
        }
        
        //ES20-12487 for getting the Outlet Ids associated with the Opportunity 
        for(String key : outletOppTemplateSet){
            //String outletId = ;
            outletSetId.add(key.substringBefore('-'));
        }
        
        //Get Target List Member for Target List which we got above
        for(Target_List_Member__c targetLstMem : [SELECT Id, Outlet__c, Target_List__c FROM Target_List_Member__c WHERE Target_List__c IN :targetListWithActiveOppTemplateMap.keySet() AND Assignment_Status__c ='Active' and Outlet__c IN :outletSetId WITH SECURITY_ENFORCED]){ //ES20-12487 added filter Outlet
            //This gives me combination of outlet & template which are linked with another Target List for which ATL is not marked as Waiting Removal. We dont need bypass this combination from deletion            
            if(targetListWithActiveOppTemplateMap != null && targetListWithActiveOppTemplateMap.containsKey(targetLstMem.Target_List__c)){
                for(Id oppTemplateId : targetListWithActiveOppTemplateMap.get(targetLstMem.Target_List__c)){
                    //string key = ;
                    //existingOutletOppTemplateSet.add(key);
                    
                    outletOppTemplateSet.remove(String.valueOf(targetLstMem.Outlet__c + '-' + oppTemplateId));
                }
            }
        }
        
        //Get All Opportunities that needs to be deleted from system
        //ES20-13152
         List<Opportunity> finalOppListToDelete = new List<Opportunity>();
       /* if(){
           
            //deleteOppList = [SELECT Id FROM Opportunity WHERE OutletWithTemplateId__c IN :outletOppTemplateSet AND StageName IN:OppStagesToDelete];
            //ES20-13152
            deleteOppList = [];
        }*/
        //ES20-13152
        if(Schema.sObjectType.Opportunity.isAccessible() && Schema.sObjectType.Opportunity.isDeletable()){
            for(Opportunity oppRec :
                [SELECT Id,OutletWithTemplateId__c 
                 FROM Opportunity 
                 WHERE AccountId IN :outletSetId 
                 AND StageName IN:oppStagesToDelete
                 AND Opportunity_Template__c in :oppTemplateIdSet
                 AND Source__c = 'EDGE' 	//155896
                 WITH SECURITY_ENFORCED] ){
                     if(outletOppTemplateSet.contains(oppRec.OutletWithTemplateId__c)){
                         finalOppListToDelete.add(oppRec);
                     }
                 }
            if(finalOppListToDelete!=null && finalOppListToDelete.size()>0){
                // ES20-13673
                Database.delete(finalOppListToDelete,false);
                //delete finalOppListToDelete;
            }
            
            //delete deleteOppList;
        }
    }
    
    //This method is used to create opportunity instance
    private static Opportunity createOpportunity(string outletId, Opportunity_Template__c oppTemplate){
        Opportunity oppRec = new Opportunity();
        oppRec.Opportunity_Template__c = oppTemplate.Id;
        oppRec.product__c = oppTemplate.product__c;
        oppRec.AccountId = outletId;
        oppRec.Name = oppTemplate.Opportunity_Type__c + '-' + oppTemplate.Action__c;
        oppRec.Start_Date__c = oppTemplate.Start_Date__c;
        oppRec.CloseDate = oppTemplate.Start_Date__c.addMonths(12); 
        oppRec.Type = oppTemplate.Opportunity_Type__c;
        oppRec.StageName = 'Open';
        //155306
        oppRec.Source__c = oppTemplate.Source__c;
        
        return oppRec;
    } 
    
}