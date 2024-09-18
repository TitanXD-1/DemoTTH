/**
* Name: EDGE_LeaderboardOperationsTest
* Req: This is the test class for EDGE_LeaderboardOperations
* History                                                            
* VERSION       AUTHOR            DATE              DETAIL
* 1.0           Dipanjan D        15/11/2019        Initial Development
* 2.0			Rajarshi Lahiri	  11/10/2022		ES20-13337
  2.1			Doman Murmu		  17/07/2023		142822
**/

@isTest
public class EDGE_LeaderboardOperationsTest{
    
    private static Set<Id> territoryIds = new Set<Id>();
    
    @isTest 
    public static void testcalculateKPIRankings(){
        String rankingType = 'Ranking as per KPI Achievement';	//142822
        Test.StartTest();
        createData();
        String buRecTypeID =  Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        
        system.assert(buRecTypeID != null,'Business Unit Record Id is null');
        Test.StopTest();
        
        EDGE_LeaderboardOperations.calculateKPIRankings(territoryIds,rankingType);
    }
    
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');        
        String buRecTypeID =  Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String regRecTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        String salArRecTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrAtRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Ranking_calculation__c = 'Ranking as per KPI Achievement';
        insert marketSetting;
        
        List<Territory_Hierarchy__c> buRecList = new List<Territory_Hierarchy__c>();
        for(integer i = 0; i < 2; i++){
            Territory_Hierarchy__c buRec = new Territory_Hierarchy__c();
            buRec.RecordTypeId = buRecTypeID;
            buRec.Name = 'BU-' + i;
            buRec.Geography__c = countryId;
            buRecList.add(buRec);
        }       
        insert buRecList;
        
        List<Territory_Hierarchy__c> salesAreaList = new List<Territory_Hierarchy__c>();
        for(Integer j = 0 ; j < buRecList.size() ; j++){
            Territory_Hierarchy__c saRec = new Territory_Hierarchy__c();
            saRec.RecordTypeId = salArRecTypeId;
            saRec.Name = 'SA-' + j;
            saRec.Geography__c = countryId;
            saRec.Parent_BU__c = buRecList[j].Id;
            salesAreaList.add(saRec);           
        }
        insert salesAreaList; 
        List<Territory_Hierarchy__c> regionList = new List<Territory_Hierarchy__c>();
        for(integer j = 0 ; j < salesAreaList.size() ; j++){
            for(integer i = 0; i < 3; i++){
                Territory_Hierarchy__c region = new Territory_Hierarchy__c();               
                region.RecordTypeId =regRecTypeId;
                region.Name = 'Region-' + i;
                region.Geography__c = countryId;
                region.Parent_BU__c = salesAreaList[j].Id;
                regionList.add(region);
            }           
        }      
        insert regionList;
        system.assert(regionList != null,'Territory Hierarchy list is empty');
        System.debug(LoggingLevel.DEBUG,'--regionList size--'+regionList.size());        
        List<Territory__c> territoryList = new List<Territory__c>();
        for(Integer k = 0 ; k < buRecList.size() ; k++){
            for(Integer i = 0 ; i < regionList.size() ; i++){
                for(integer j = 0 ; j < 40; j++){
                    Territory__c territoryRec = new Territory__c();
                    territoryRec.Name = 'Territory '+ j;
                    territoryRec.Status__c = 'Active';
                    territoryRec.Territory_Type__c = 'Sales';
                    territoryRec.Region__c = regionList[i].Id;
                    if( math.mod(i, 2) == 0 ){
                        territoryRec.Exclude_from_Leaderboard_ranking__c = true ;   
                    }
                    territoryRec.Business_Unit__c = buRecList[k].Id;
                    territoryRec.Country__c = countryId;
                    territoryList.add(territoryRec);
                }
            }           
        }
        
        //Added Activation Territories
         List<Territory__c> actterritoryList = new List<Territory__c>();
         for(Integer i = 0 ; i < 5 ; i++){
            Territory__c actterritory = EDGE_UtilityTestClass.getTerritoryRec();
            actterritory.Country__c = countryId;
			actterritory.Name = 'Activation Territory '+ i;
            actterritory.Territory_Type__c = 'Activation Territory';
            actterritory.Pending_For_Batch__c = True;
            actterritory.Status__c = 'Active';
 			if( math.mod(i, 2) == 0 ){
                   actterritory.Exclude_from_Leaderboard_ranking__c = true ;   
               }
    		actterritory.RecordTypeId = terrAtRecordTypeId;
			actterritoryList.add(actterritory);
			}
			territoryList.addAll(actterritoryList);
		
        insert territoryList;
        
        system.assert(territoryList.size() > 0, 'Territory list is null');
        
        system.debug(LoggingLevel.DEBUG,'territoryList size++ ' + territoryList.size());
        List<KPI_Achivement__c> kpiAchiveList = new List<KPI_Achivement__c>();
        for(Integer i = 0 ; i < territoryList.size() ; i++){
            territoryIds.add(territoryList[i].Id);
            KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
            kpiAchive.Territory__c = territoryList[i].Id;
            kpiAchive.KPI_Type__c = 'MPA';
            kpiAchive.Achievement__c = 10;// * i - .5;
            kpiAchiveList.add(kpiAchive);           
            
            KPI_Achivement__c kpiAchive1 = new KPI_Achivement__c();
            kpiAchive1.Territory__c = territoryList[i].Id;
            kpiAchive1.KPI_Type__c = 'MAS';
            kpiAchive1.Achievement__c = 10 * i + .6;
            kpiAchiveList.add(kpiAchive1);          
            
            KPI_Achivement__c kpiAchive2 = new KPI_Achivement__c();
            kpiAchive2.Territory__c = territoryList[i].Id;
            kpiAchive2.KPI_Type__c = 'OES';
            kpiAchive2.Achievement__c = 10 * i + .7;
            kpiAchiveList.add(kpiAchive2);                      
            
        }
        
        List<KPI_Achivement__c> actTerkpiAchiveList = new List<KPI_Achivement__c>();
        for(Integer i = 0 ; i < actterritoryList.size() ; i++){
            territoryIds.add(territoryList[i].Id);
            KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
            kpiAchive.Territory__c = actterritoryList[i].Id;
            kpiAchive.KPI_Type__c = 'MPA';
            kpiAchive.Achievement__c = 10;// * i - .5;
            actTerkpiAchiveList.add(kpiAchive);           
            
            KPI_Achivement__c kpiAchive1 = new KPI_Achivement__c();
            kpiAchive1.Territory__c = actterritoryList[i].Id;
            kpiAchive1.KPI_Type__c = 'MAS';
            kpiAchive1.Achievement__c = 10 * i + .6;
            actTerkpiAchiveList.add(kpiAchive1);          
            
            KPI_Achivement__c kpiAchive2 = new KPI_Achivement__c();
            kpiAchive2.Territory__c = actterritoryList[i].Id;
            kpiAchive2.KPI_Type__c = 'OES';
            kpiAchive2.Achievement__c = 10 * i + .7;
            actTerkpiAchiveList.add(kpiAchive2);                      
            
        }
        kpiAchiveList.addAll(actTerkpiAchiveList);
        
        insert kpiAchiveList;
        
        for(KPI_Achivement__c kpiAchive : kpiAchiveList){
            system.debug(LoggingLevel.DEBUG,'TestData-- ' + ' Region--' +  kpiAchive.Territory__r.Region__c  + '--' +  kpiAchive.Territory__c + '--' + kpiAchive.KPI_Type__c + ' -- ' + kpiAchive.Achievement__c );
        } 
    } 
    @isTest
    public static void testPrimaryTerritoryKPICalcBatch(){
        Test.startTest();
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PrimaryTerritoryKPICalcBatch'
                                                  and Country_Code__c ='AU' ];
        system.assert(batchSetting.Id != null,'Batch Setting Record is Empty');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        //Database.executeBatch((Database.Batchable<SObject>)job,100);
        Test.stopTest();
    }
    
}