/**********************************************************************
Name: EDGE_TerritoryProcessAccShareBatchTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     11/03/2019      Test Class for EDGE_TerritoryProcessRepInsertBatch apex class.
2.0         Joshraj Sen      08/04/2024      152305
***********************************************************************/
@isTest
public class EDGE_TerritoryProcessAccShareBatchTest{
    
    public static List<Outlet_Member__c> omList;
    
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU'); 
        //Insert Territory
        Territory__c  territoryRec = EDGE_UtilityTestClass.getTerritoryRec();
        territoryRec.Country__c = countryId;
        insert territoryRec;
        
        //Insert User
        List<User> usrList = new List<User>();
        for(integer i=0; i<2; i++){
            User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' + i, 'Sales Representative');
            usrList.add(userRec);
        }
        insert usrList;
        
        //Insert Account
        List<Account> accList = new List<Account>();
        for(integer i = 0; i<3; i++){
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Name = 'Test Outlet ' + i;
            accList.add(outlet);
        }
        insert accList;
        
        //Insert Outlet Territory
        List<Outlet_Territory__c> outletTerritoryList = new List<Outlet_Territory__c>();
        for(integer i=0; i<3; i++){
            Outlet_Territory__c outltTerri = new Outlet_Territory__c();
            if(i==0){
                outltTerri = EDGE_UtilityTestClass.getOutltTerritory(accList[0].Id, territoryRec.Id);
                outltTerri.Active__c = 'Waiting Activation';
            }else if(i==1){
                outltTerri = EDGE_UtilityTestClass.getOutltTerritory(accList[1].Id, territoryRec.Id);
                outltTerri.Active__c = 'Active';
            }else{
                outltTerri = EDGE_UtilityTestClass.getOutltTerritory(accList[2].Id, territoryRec.Id);
                outltTerri.Active__c = 'Waiting Removal';
            }
            outletTerritoryList.add(outltTerri);
        }
        system.debug(LoggingLevel.Debug,'outletTerritoryList++ ' + outletTerritoryList);
        insert outletTerritoryList;
        
        List<Territory_Member__c> territoryMemberList = new List<Territory_Member__c>();
        for(integer i=0; i<2; i++){
            Territory_Member__c terrMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(usrList[0].Id, territoryRec.Id); 
            terrMember.Start_Date__c = Date.today();
            if(i==0){
                terrMember.End_Date__c = Date.today().addDays(-1);
            }else{
                
                terrMember.End_Date__c = Date.today().addDays(10);
                terrMember.Type__c = 'Secondary';
            }
            territoryMemberList.add(terrMember);
        }
        insert territoryMemberList;
        
        //create outletMember
        omList = new list<Outlet_Member__c>();
        for(integer i=0; i<2; i++){
            Outlet_Member__c omTest = new Outlet_Member__c();
            if(i==0){
                omTest = EDGE_UtilityTestClass.getOutletMemberRecord(accList[1].Id, usrList[0].Id, 'Primary');
            }else{
                omTest = EDGE_UtilityTestClass.getOutletMemberRecord(accList[1].Id, usrList[1].Id, 'Secondary');
            }
            omList.add(omTest);
        }
        insert omList;  
        List<AccountTeamMember> accountTeamMembers=new List<AccountTeamMember>();
        for(integer i=0; i<2; i++){
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            if(i==0){                
                newAccTeamMember.AccountId=accList[0].Id;
                newAccTeamMember.UserId = usrList[0].Id;
                
            }else{
                newAccTeamMember.AccountId=accList[1].Id;
                newAccTeamMember.UserId = usrList[1].Id;
            }
            accountTeamMembers.add(newAccTeamMember);
        }
        insert accountTeamMembers;  
        EDGE_OutletMemberAccountTeamSync.updateAccountTeamMembers(omList);
        EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMembers(omList);
        
    }
    
    @isTest
    public static void testRepDeleteBatch(){
        
        Test.startTest(); 
        createData();
        //Database.executeBatch(new EDGE_TerritoryProcessRepDeleteBatch(), 10);
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessRepDeleteBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c)); 
        List<Outlet_Member__c> outletMemList = [SELECT Id FROM Outlet_Member__c LIMIT 1];
        system.AssertEquals(outletMemList.Size(), 1,'Match');               
        Test.stopTest();
        
        
        
    }
    
    /*@isTest
public static void testRepInsertBatch(){
Test.startTest();
createData();
//Database.executeBatch(new EDGE_TerritoryProcessRepInsertBatch(), 10);
Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessRepInsertBatch'
and Country_Code__c ='AU' ];
String className = batchSetting.Batch_Class__c;
Type t = Type.forName(className);
BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
job.getBatchDetails(batchSetting);
Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));   
//List<Outlet_Member__c> outletMemList = [SELECT Id FROM Outlet_Member__c LIMIT 1];
//system.AssertEquals(outletMemList.Size(), 1);   
Test.stopTest();
}*/
    @isTest
    public static void testTerritoryPorcessAccountbatch(){
        Test.startTest();
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessAccountShareBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test Outlet11 ';
        insert outlet;
        User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
        insert userRec;
        
        system.Assert(userRec != null,'User is Addded');
        
        Outlet_Member__c omTest = new Outlet_Member__c ();
        omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userRec.id, 'Primary');
        insert omTest;
        omTest.Flag_For_Deletion__c = true;
        update omTest;
        Test.stopTest();
        
    }
    @IsTest
    public static void test2(){
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessAccountShareBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        CreateData();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test Outlet11 ';
        insert outlet;
        User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
        insert userRec;
        system.Assert(userRec != null,'User is Added');
        Outlet_Member__c omTest = new Outlet_Member__c ();
        omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userRec.id, 'Primary');
        omTest.Flag_For_Deletion__c = false;
        insert omTest;
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(omTest.Id,yesterday); 
        Test.startTest();
        update omTest;
        Test.stopTest();
    }
}