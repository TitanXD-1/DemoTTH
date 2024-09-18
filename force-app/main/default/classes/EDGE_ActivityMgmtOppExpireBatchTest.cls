/**********************************************************************
Name: EDGE_ActivityMgmtOpprExpireBatchTest
=======================================================================
Req: 
User Story : ES20-880
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sagar Barman        17/04/2019      Initial Development
2.0     Prasanth T          23/09/2022      ES20-13324(Test Class Correction Due to Failure)
***********************************************************************/
@isTest
public class EDGE_ActivityMgmtOppExpireBatchTest {
    @isTest
    public static void testOppExpiration(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_ActivityMgmtOppExpireBatch' AND Country_Code__c ='AU'LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'batchSetting have values');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
    } 
    
    public static void createData(){
        
        // create Geography record  
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();        
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit.Name = 'Gold[AU]';
        insert pickUpVisit;
        
        List<Opportunity> oppList = new List<Opportunity>();
        Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Country__c = country.Id;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit.Id;
        insert outletAccount;
        Test.startTest();  
        //create Product             
        Product__c testProd = EDGE_UtilityTestClass.getProd();
        insert testProd; 
        Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
        orgSetting.Run_Validation_Rules__c = false;
        update orgSetting;
        //Create Territory
        Id clusterId = [Select Id,Code__c from Geography__c where Code__c = 'AUCT'].Id;
        Territory__c terrId =EDGE_UtilityTestClass.getTerritoryRec();
        terrId.Territory_Type__c = 'Service';
        insert terrId;  
        
        //Create Opportunity template
        Opportunity_Template__c oppoTemp = new Opportunity_Template__c(Territory__c=terrId.Id,Product__c=testProd.Id,Cluster__c=clusterId,Opportunity_Type__c='Cycle Brief',Action__c='Test',Closing_Method__c='Order',Start_Date__c=Date.today(),Weight_Type__c='Always on Top',End_Date__c=Date.today().addDays(7));                
        insert oppoTemp;
        
        //Create Opportunity
        Account outlet = [SELECT Id, Country__c, Country__r.Code__c FROM Account WHERE Id =:outletAccount.Id];
        
        for(Integer i=0;i<10;i++){
            Opportunity testOpp = new Opportunity();
            testOpp.CloseDate = Date.today().addDays(-7);
            testOpp.Name = 'Test Opp'+i;
            testopp.AccountId = outlet.Id;
            testopp.StageName ='Open';
            testopp.Opportunity_Template__c =oppoTemp.Id;
            oppList.add(testopp);
        }
        insert oppList;
        
        //List<Opportunity> lstOpp = [SELECT Id, AccountId, Account.Country__c, Account.Country__r.Code__c FROM Opportunity];
        
        //Org Setting        
        
        
        Opportunity_Template__c oppoUpdateTemp =[Select ID,Start_Date__c,End_Date__c from Opportunity_Template__c where ID =: oppoTemp.Id];
        oppoUpdateTemp.End_Date__c=Date.today().addDays(-17);
        oppoUpdateTemp.Start_Date__c=Date.today().addDays(-117);
        update oppoUpdateTemp;  
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryID);
        insert survey;
        
        Target_List__c tlc = EDGE_UtilityTestClass.getTargetList(countryID);
        insert tlc;
        
        Activity_Target_List__c aTL = EDGE_UtilityTestClass.getActivityTargetList(survey.id, tlc.id);
        aTL.Status__c = 'Waiting Removal';
        insert aTL;
        
        aTl.Opportunity_Template__c = oppoUpdateTemp.id;
        update aTL;
    }   
}