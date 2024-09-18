/**

* @Description :  EDGE_TerritoryProcessInsertExtHelperTest

* @Purpose : Test Class for EDGE_TerritoryProcessInsertExtHelper and EDGE_TerritoryProcessInsertHelper apex class.

* @History :

* @Version   Developer         		 Date           User Story/Purpose

* 1.1       Saurav Prasad     		20/08/2024      Initial Development : 156131 - August Release Deployment Issue Resolver
*/
@isTest
public class EDGE_TerritoryProcessInsertExtHelperTest {
    
    public final static String SALESRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    public final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
    public static List<Outlet_Member__c> omList;
    
    @isTest
    public static void territoryProcessInsertHelperMethod(){
        
        createData();
        
        List<Territory_Member__c> terrMemList = [Select Id, Start_Date__c,End_Date__c, Territory__c,Territory__r.Last_Primary_Sales_Rep__c, 
                                                 Type__c, User__c,User__r.Trax_User__c,User__r.Default_Country__c,User__r.Available_Countries__c 
                                                 from Territory_Member__c];
        
        System.debug(LoggingLevel.DEBUG,'terrMemList @'+terrMemList);
        
        system.AssertNotEquals(terrMemList.Size(), 0,'Territory Member Present');   
        
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap =  EDGE_TerritoryProcessInsertHelper.getUserRoleMap();
        System.debug(LoggingLevel.DEBUG,'userRoleMap @'+userRoleMap);
        
        EDGE_BatchSObjectCombinedWrapper combinedWraapper = EDGE_TerritoryProcessInsertHelper.getCombinedWrapper(terrMemList);
        System.debug(LoggingLevel.DEBUG,'combinedWraapper @'+combinedWraapper);
        
        Map<String, List<Territory_Member__c>> userTerritoryMemberMap = new Map<String, List<Territory_Member__c>>();
        for(Territory_Member__c terrMem : terrMemList){
            userTerritoryMemberMap.putAll(EDGE_TerritoryProcessInsertHelper.getUserTerritoryMemberMap(terrMem,combinedWraapper.territoryOutletMap));
        }
        
        System.debug(LoggingLevel.DEBUG,'userTerritoryMemberMap @'+userTerritoryMemberMap);
        
        EDGE_TerritoryProcessRepInsertBatch.EDGE_BatchSObjectMapWrapper mapWrapper = EDGE_TerritoryProcessRepInsertBatch.getListForTerritoryAdditionAndRemoval(terrMemList, combinedWraapper);
        
        System.debug(LoggingLevel.DEBUG,'mapWrapper @'+mapWrapper);
        
        EDGE_BatchSObjectOutputWrapper outputWrapper = EDGE_TerritoryProcessInsertExtHelper.getWrapperRecordsAndTraxUsers(combinedWraapper,mapWrapper.userTerritoryMemberMap);
        
        System.debug(LoggingLevel.DEBUG,'outputWrapper @'+outputWrapper);
    }
     /**
 * @description Create Data
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
        
        System.debug(LoggingLevel.INFO,'usrList @'+usrList);
        
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

}