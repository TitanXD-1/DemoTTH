/**********************************************************************
Name: EDGE_BonusDetailResultOperations
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan D          22/01/2020        ES20-4587 : Set the result of MPA, MAS, OES into KPI Result Detail object.
***********************************************************************/
public with sharing class EDGE_BonusDetailResultOperations{
    
    public static void populateBonusDetailResults(List<Bonus_Header__c> bonusHeaders){
        
        Set<Id> territoryIds = new Set<Id>();
        Set<String> kpiTypes = new Set<String>();
        List<String> kpiTypesList = Label.EDGE_Global_KPI_Types.split(';');
        Map<String, KPI_Achivement__c> kpiAchivementMap = new Map<String, KPI_Achivement__c>();
        Map<Id, Bonus_Header__c> bonusHeaderMap = new Map<Id,Bonus_Header__c>(bonusHeaders);
        Map<Id, List<Bonus_Detail__c>> bonusHeaderWithDetailsMap = new Map<Id, List<Bonus_Detail__c>>();
        List<Bonus_Detail_Result__c> upsertBonusDetailResultList = new List<Bonus_Detail_Result__c>();
        Map<Id, List<Achievement_Tier__c>> bonusDtlWithAchTierMap = new Map<Id, List<Achievement_Tier__c>>();
        Map<Id, Set<Id>> bonusHeaderWithTerrMap = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> bonusDetailWithTerrMap = new Map<Id, Set<Id>>();
        
        kpiTypesList.addAll(Label.EDGE_Territory_KPI_Types.split(';'));
        if(kpiTypesList != null && kpiTypesList.size()>0){
            kpiTypes.addAll(kpiTypesList);
        }
        
        //Remove Volume from KPI Types as it is not required
        if(kpiTypes.contains('Volume')){
            kpiTypes.remove('Volume');
        }       	
        
        //Get Bonus Detail of type Bonus Header & Bonus Detail
        for(Bonus_Detail__c bonusDetail : [SELECT Id, Achievement_Tier__c, Achievement_Tier_Count__c, Bonus_Header__c, KPI_Type__c, 
                                           Product__c, Survey_KPI__c, Weight__c FROM Bonus_Detail__c WHERE Bonus_Header__c IN :bonusHeaderMap.keySet()])
        {
            if(bonusHeaderWithDetailsMap.containsKey(bonusDetail.Bonus_Header__c)){
                bonusHeaderWithDetailsMap.get(bonusDetail.Bonus_Header__c).add(bonusDetail);
            }else{
                bonusHeaderWithDetailsMap.put(bonusDetail.Bonus_Header__c, new List<Bonus_Detail__c> { bonusDetail });
            }
        }
        
        //Get Actievement Tier
        for(Achievement_Tier__c achTier : [SELECT Id, Bonus_Detail__c, Range_End__c, Range_Start__c, Value__c FROM Achievement_Tier__c 
                                           WHERE Bonus_Detail__r.Bonus_Header__c IN :bonusHeaderWithDetailsMap.keySet()]){
            if(bonusDtlWithAchTierMap.containsKey(achTier.Bonus_Detail__c)){
                bonusDtlWithAchTierMap.get(achTier.Bonus_Detail__c).add(achTier);
            }else{
                bonusDtlWithAchTierMap.put(achTier.Bonus_Detail__c, new List<Achievement_Tier__c> { achTier } );
            }
        }
		
        //Get Bonus Header - Territory Assignment
		for(Bonus_Assignment__c bonusHeaderAssign : [SELECT Id, Bonus_Header__c, Territory__c FROM Bonus_Assignment__c WHERE recordType.DeveloperName = 'Bonus_Header' AND Bonus_Header__c IN :bonusHeaderWithDetailsMap.keySet()]){
			if(bonusHeaderWithTerrMap.containsKey(bonusHeaderAssign.Bonus_Header__c)){
				bonusHeaderWithTerrMap.get(bonusHeaderAssign.Bonus_Header__c).add(bonusHeaderAssign.Territory__c);
			}else{
				bonusHeaderWithTerrMap.put(bonusHeaderAssign.Bonus_Header__c, new Set<Id> { bonusHeaderAssign.Territory__c });
			}
			territoryIds.add(bonusHeaderAssign.Territory__c);
		}
		
        //Get Bonus Detail - Territory Assignment
		for(Bonus_Assignment__c bonusDetailAssign : [SELECT Id, Bonus_Header__c, Bonus_Detail__c, Bonus_Detail__r.KPI_Type__c, Territory__c FROM Bonus_Assignment__c WHERE recordType.DeveloperName = 'Bonus_Detail' AND Bonus_Header__c IN :bonusHeaderWithDetailsMap.keySet()]){
			if(bonusDetailAssign.Bonus_Detail__r.KPI_Type__c == 'MAS' || bonusDetailAssign.Bonus_Detail__r.KPI_Type__c == 'MPA' || bonusDetailAssign.Bonus_Detail__r.KPI_Type__c == 'OES'){
				bonusDetailWithTerrMap.put(bonusDetailAssign.Bonus_Detail__c, bonusHeaderWithTerrMap.get(bonusDetailAssign.Bonus_Header__c));
			}else{
				if(bonusDetailWithTerrMap.containsKey(bonusDetailAssign.Bonus_Detail__c)){
					bonusDetailWithTerrMap.get(bonusDetailAssign.Bonus_Detail__c).add(bonusDetailAssign.Territory__c);
				}else{
					bonusDetailWithTerrMap.put(bonusDetailAssign.Bonus_Detail__c, new Set<Id> { bonusDetailAssign.Territory__c });
				}				
			}
		}
    
		
        //get only Current Active Bonus Header Result
        if(Schema.SObjectType.Bonus_Header_Result__c.isAccessible() && Schema.SObjectType.Market_Cycle__c.isAccessible() ){
            List<Bonus_Header_Result__c> bonusHeaderResult = [SELECT Id, Bonus_Header__c, Bonus_Assignment__c, Market_Cycle__c, Territory__c, Territory_Cycle__c FROM Bonus_Header_Result__c WHERE Bonus_Header__c IN :bonusHeaderMap.keySet() AND Market_Cycle__r.Active__c = True];
            
            if(bonusHeaderResult != null){            
                //Get Territory KPI from KPI Achievement Object
                if(territoryIds != null && territoryIds.size()>0 && kpiTypes != null && kpiTypes.size()>0){
                    for(KPI_Achivement__c kpiAchive : [SELECT Id, KPI_Type__c, Territory__c, Product__c, Survey_KPI__c, Achievement__c, Actual_Achievement__c, Target__c FROM KPI_Achivement__c WHERE recordType.DeveloperName != 'Territory_Hierarchy_KPI' AND KPI_Type__c IN:kpiTypes AND Territory__c IN :territoryIds]){
                        //Product KPI Key
                        if(kpiAchive.Product__c != null && kpiAchive.Territory__c != null &&  kpiAchive.KPI_Type__c != null){
                            kpiAchivementMap.put(kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_' + kpiAchive.Product__c, kpiAchive);
                        }
                        //Survey KPI Key
                        else if(kpiAchive.Survey_KPI__c != null && kpiAchive.Territory__c != null &&  kpiAchive.KPI_Type__c != null){
                            kpiAchivementMap.put(kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_' + kpiAchive.Survey_KPI__c, kpiAchive);
                        }
                        //Global KPI Key
                        else if (kpiAchive.Territory__c != null &&  kpiAchive.KPI_Type__c != null){
                            kpiAchivementMap.put(kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c, kpiAchive);
                        }
                    }
                }
                
                //Create Bonus Detail Result
                for(Bonus_Header_Result__c bhr : bonusHeaderResult){
                    if(bonusHeaderWithDetailsMap.containsKey(bhr.Bonus_Header__c)){
                        for(Bonus_Detail__c bonusDetail : bonusHeaderWithDetailsMap.get(bhr.Bonus_Header__c)){
                            Set<Id> territoryIdsToUse = bonusDetailWithTerrMap.get(bonusDetail.Id);
                            //need to check if bonus detail is assigned to same territory(From Bonus assignment of type bonus detail) as bonus header 
                            if(territoryIdsToUse.contains(bhr.Territory__c)){
                                Bonus_Detail_Result__c bonusDetailResultObj = new Bonus_Detail_Result__c();
                                bonusDetailResultObj.Bonus_Header_Result__c = bhr.id;
                                bonusDetailResultObj.Bonus_Detail__c = bonusDetail.id;
                                switch on bonusDetail.KPI_Type__c {
                                    when 'MAS', 'MPA', 'OES'{
                                        String kpiKey = bhr.Territory__c+'_'+bonusDetail.KPI_Type__c;
                                        if(kpiAchivementMap.containsKey(kpiKey)){
                                            bonusDetailResultObj.Actual__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(kpiKey).Achievement__c);
                                            bonusDetailResultObj.Achievement__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(kpiKey).Actual_Achievement__c);
                                            bonusDetailResultObj.Cycle_Target__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(kpiKey).Target__c);							
                                        }
                                    }
                                    when 'Survey' {
                                        String surveyKey = bhr.Territory__c+'_'+bonusDetail.KPI_Type__c+'_'+bonusDetail.Survey_KPI__c;
                                        if(kpiAchivementMap.containsKey(surveyKey)){
                                            bonusDetailResultObj.Actual__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(surveyKey).Achievement__c);
                                            bonusDetailResultObj.Achievement__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(surveyKey).Actual_Achievement__c);
                                            bonusDetailResultObj.Cycle_Target__c = 	EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(surveyKey).Target__c);							
                                        }
                                    }
                                    when 'NPD', 'Distribution' {
                                        String prodKey = bhr.Territory__c+'_'+bonusDetail.KPI_Type__c+'_'+bonusDetail.Product__c;
                                        if(kpiAchivementMap.containsKey(prodKey)){
                                            bonusDetailResultObj.Actual__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(prodKey).Achievement__c);
                                            bonusDetailResultObj.Achievement__c = EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(prodKey).Actual_Achievement__c);
                                            bonusDetailResultObj.Cycle_Target__c = 	EDGE_UtilityClass.checkForNull(kpiAchivementMap.get(prodKey).Target__c);							
                                        }
                                    }
                                }
                                bonusDetailResultObj.Unique_Id__c = string.valueOf(bhr.id)+'_'+string.valueOf(bonusDetail.id);
                                //Check if Bonus Detail has Achievement Tier or not and based on that calculate Weight Achieve
                                if(bonusDetail.Achievement_Tier__c && bonusDtlWithAchTierMap.containsKey(bonusDetail.id)){
                                    for(Achievement_Tier__c achvTier :bonusDtlWithAchTierMap.get(bonusDetail.id)){
                                        if(bonusDetailResultObj.Achievement__c >= achvTier.Range_Start__c && bonusDetailResultObj.Achievement__c <= achvTier.Range_End__c){
                                            bonusDetailResultObj.Achievement_Multiplier__c = achvTier.Value__c;
                                            bonusDetailResultObj.Weight_Achieved__c = bonusDetail.Weight__c * achvTier.Value__c;
                                            break;
                                        } else{
                                            bonusDetailResultObj.Achievement_Multiplier__c = 0;
                                            bonusDetailResultObj.Weight_Achieved__c= (bonusDetail.Weight__c * EDGE_UtilityClass.checkForNull(bonusDetailResultObj.Achievement__c)) / 100;
                                        }
                                    }
                                } else {
                                    bonusDetailResultObj.Achievement_Multiplier__c=0;
                                    bonusDetailResultObj.Weight_Achieved__c= (bonusDetail.Weight__c * EDGE_UtilityClass.checkForNull(bonusDetailResultObj.Achievement__c)) / 100;
                                }
                                upsertBonusDetailResultList.add(bonusDetailResultObj);							
                            }
                            
                        }
                    }
                }
            }
        }
        
        //Upsert Bonus Detail Result
        if(upsertBonusDetailResultList != null && upsertBonusDetailResultList.size()>0){
            Schema.SObjectField uniqueId = Bonus_Detail_Result__c.Fields.Unique_Id__c;
            database.upsert(upsertBonusDetailResultList,uniqueId,false);
        }
    }
}