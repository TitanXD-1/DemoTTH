/**

* @Description :  EDGE_TerritoryProcessRepBatchTest

* @Purpose : Test Class for EDGE_TerritoryProcessRepInsertBatch apex class.

* @History :

* @Version   Developer         		 Date           User Story/Purpose

* 1.1       Dipanjan Das     		11/03/2019      Initial Development
* 1.2	    Juned Khan	     		11/19/2020      updated testmethods testRepDeleteBatch and testRepInsertBatch to include batch size as 50
* 1.3    	Aparajita/Rajarshi/     11/03/2022		ES20-12216,12231,12213
			Subhodeep
* 1.4       Suvendu Roy             20/06/2024	    154642 - EDGE Classes_Fix Static Code Analysis Error_Story_4
* 1.5       Joshraj Sen             28/06/2024      154642 - Fixed the SCA ApexDoc
*/

@isTest
/**
 * @description Test Class for EDGE_TerritoryProcessRepInsertBatch
 */
public class EDGE_TerritoryProcessRepBatchTest{
    
    final static String SALESRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); //ES20-12216,12231,12213
    
    public static List<Outlet_Member__c> omList;
    /**
 * @description Test Class for EDGE_TerritoryProcessRepInsertBatch Code
 */
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        
        //Insert Sales Territory
        Territory__c territoryRec =  EDGE_UtilityTestClass.getTerritoryRec();
        territoryRec.Country__c = countryId;
        territoryRec.Sales_Area__c = terriHierSA.Id;
        territoryRec.Region__c = terriHierRegion.Id;
        territoryRec.RecordTypeId = SALESRECORDTYPEID;
        territoryRec.Territory_Type__c = 'Sales';
        territoryRec.Status__c = 'Active';
        territoryRec.Pending_For_Batch__c = true;
        
        //Insert AT
        Territory__c territoryAT =  EDGE_UtilityTestClass.getTerritoryRec();
        territoryAT.Country__c = countryId;
        territoryAT.Territory_Type__c = 'Activation Territory';
        territoryAT.RecordTypeId = ACTIVATIONRECORDTYPEID;
        territoryAT.Status__c = 'Active';
        territoryAT.Pending_For_Batch__c = true;
        
        List<Territory__c> terrList = new List<Territory__c>(); 
        terrList.add(territoryRec);
        terrList.add(territoryAT);
        insert terrList;
        
        //Business Role for SR
        Business_Role__c br = new Business_Role__c();
        br.Name ='Business Role 1';
        br.Global_Equivalent__c = 'Sales Rep';
        br.Country__c = countryId;
        br.Call_Type__c = 'Telephone';
        br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED';//removed Distribution__c
        insert br;
        
        //Business Role for AS
        Business_Role__c busroleAT = EDGE_UtilityTestClass.getBusinessRole();
        busroleAT.Country__c = countryId;
        busroleAT.Global_Equivalent__c ='Activation Specialist';
        busroleAT.My_accounts_Fields_Display__c='Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        insert busroleAT;
        
        List<User> usrList = new List<User>();
        List<User_Business_Role__c> uList = new List<User_Business_Role__c>();
        
        //Insert AS
        User usrAS = EDGE_UtilityTestClass.runAsUser('TestAS', 'Activation Specialist');
        usrAS.Business_Role__c = busroleAT.Id;
        usrAS.Available_Countries__c = 'AU';
        insert usrAS;
        
        //User Business Role for AS
        User_Business_Role__c ubrAT = new User_Business_Role__c();
        ubrAT.Business_Role__c= busroleAT.Id ;
        ubrAT.User__c=usrAS.Id;
        insert ubrAT;
        
        //Insert SR
        for(integer i=0; i<2; i++){
            User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
            userRec.trax_user__c=true;
            usrList.add(userRec);
        }
        
        insert usrList;
        
        //User Business Role
        for(integer i =0;i<2;i++){
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.id;
            ubr.User__c = usrList[i].id;
            uList.add(ubr);
        }
        
        insert uList;
        
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
        String activeStatus = 'Waiting Activation-Active-Waiting Removal';
        for(integer i = 0; i<3; i++){
            Outlet_Territory__c outltTerri = new Outlet_Territory__c();
            outltTerri = EDGE_UtilityTestClass.getOutltTerritory(accList[i].Id, territoryRec.Id);
            outltTerri.Active__c = activeStatus.split('-')[i];
            outletTerritoryList.add(outltTerri);
        }
        insert outletTerritoryList;
        
        //Insert OT for AT
        Outlet_Territory__c otAT = EDGE_UtilityTestClass.getOutltTerritory(accList[0].Id, territoryAT.Id);
        otAT.Active__c = 'Waiting Activation';   
        insert otAT;
        
        //Insert SR TerrMembers
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
        
        //Insert AS TerrMember
        Territory_Member__c terrMemberAT = new Territory_Member__c();
        terrMemberAT.User__c = usrAS.Id;
        terrMemberAT.Type__c = 'Primary' ;
        terrMemberAT.Territory__c  = territoryAT.Id;
        terrMemberAT.Start_Date__c = Date.today();
        territoryMemberList.add(terrMemberAT);
        
        insert territoryMemberList;
        
        omList = insertOutletMembers(accList, usrList, usrAS);
        
        EDGE_OutletMemberAccountTeamSync.updateAccountTeamMembers(omList);
        EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMembers(omList);
    }
     /**
 * @description Return Outlet Members
 * @param accList
 * @param usrList
 * @param usrAS
 * @return List<Outlet_Member__c>
 */
    public static List<Outlet_Member__c> insertOutletMembers(List<Account> accList,List<User> usrList, User usrAS){
        //Create OutletMem for Sales Reps
        List<Outlet_Member__c> omList = new List<Outlet_Member__c>();
        for(integer i=0; i<2; i++){
            Outlet_Member__c omTest = new Outlet_Member__c();
            if(i==0){
                omTest = EDGE_UtilityTestClass.getOutletMemberRecord(accList[1].Id, usrList[0].Id, 'Primary');
                omTest.Flag_For_Deletion__c = true;
            }else{
                omTest = EDGE_UtilityTestClass.getOutletMemberRecord(accList[1].Id, usrList[1].Id, 'Secondary');
                omTest.Flag_For_Deletion__c = false;
            }
            omList.add(omTest);
        }
        
        //Insert OutletMem for AS
        Outlet_Member__c omAS = EDGE_UtilityTestClass.getOutletMemberRecord(accList[0].Id, usrAS.Id, 'Activation Specialist');
        omList.add(omAS);
        
        insert omList;  
        return omList;
    }
    
    @isTest
    public static void testRepDeleteBatch(){     
        Test.startTest(); 
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessRepDeleteBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,50); 
        List<Outlet_Member__c> outletMemList = [SELECT Id FROM Outlet_Member__c LIMIT 1];
        system.AssertEquals(outletMemList.Size(), 1,'Outlet Member Present');               
        Test.stopTest();        
    }
    
    @isTest
    public static void testRepInsertBatch(){
        Test.startTest();
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessRepInsertBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,50);
        List<Outlet_Member__c> outletMemList = [SELECT Id FROM Outlet_Member__c LIMIT 1];
        system.AssertEquals(outletMemList.Size(), 1,'Outlet Member Present');   
        Test.stopTest();
    }
    
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
        
        System.assert(userRec != null,'User Record Null');
        
        Outlet_Member__c omTest = new Outlet_Member__c ();
        omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userRec.id, 'Primary');
        insert omTest;
        omTest.Flag_For_Deletion__c = true;
        update omTest;
        Test.stopTest();       
    }
    
    @isTest
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
        system.Assert(userRec != null,'User Not Null');
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
     @isTest
    public static void test3(){
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test Outlet11 ';
        insert outlet;
        User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
        insert userRec;
        
        List<Outlet_Member__c> outMem = new List<Outlet_Member__c>();
        Outlet_Member__c omTest = new Outlet_Member__c ();
        omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userRec.id, 'Primary');
        outMem.add(omTest);
        insert outMem;
        System.assert(omTest.Outlet__c!=Null,'Outet in OM');
        EDGE_OutletMemberExtnUtility.deleteOutletMember(outMem);
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = outlet.Id;
        newAccTeamMember.UserId = userRec.Id;
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        //insert newAccTeamMember;
        List<AccountTeamMember> listAccTeamMem = new List<AccountTeamMember>();
        listAccTeamMem.add(newAccTeamMember);
        EDGE_OutletMemberExtnUtility.createAccTeam(listAccTeamMem);
        EDGE_OutletMemberExtnUtility.deleteAccTeam(listAccTeamMem);
        
    }
   
}