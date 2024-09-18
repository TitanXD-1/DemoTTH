/**********************************************************************
Name: EDGE_UserBusinessRoleTriggerHelperTest
=======================================================================
Req: The requirement is to remove Outlet from territory && Target list member from Target list
ES20-277 - Remove Target list member from Target List- Static
ES20-258 - Remove Outlet Territory from Territory
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo     04/03/2019        Initial Development

***********************************************************************/
@isTest
public class EDGE_RemoveElementControllerTest{
    @isTest
    public static void searchTargetMemberDetailsTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Account testacc=EDGE_UtilityTestClass.getOutletRecord();        
        insert testacc;
        Target_List__c  testtl=EDGE_UtilityTestClass.getTargetList(geographyId);
        insert testtl;
        Target_List_Member__c  testtlm=EDGE_UtilityTestClass.getTargetMemList(testacc.ID,testtl.ID);
        insert testtlm;   
        List<Target_List_Member__c> tlmcheck=new List<Target_List_Member__c>();    
        tlmcheck=EDGE_RemoveElementController.searchTargetMemberDetails(' OR Outlet__r.Name LIKE \'%' + 'Test' + '%\'',String.valueOf(testtl.Id));
        System.assertNotEquals(tlmcheck,null,'success');        
    }
    @isTest
    public static void removeMemberTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Account testacc=EDGE_UtilityTestClass.getOutletRecord();        
        insert testacc;
        Target_List__c  testtl=EDGE_UtilityTestClass.getTargetList(geographyId );
        insert testtl;
        Target_List_Member__c  testtlm=EDGE_UtilityTestClass.getTargetMemList(testacc.ID,testtl.ID);
        insert testtlm;
        List<String> tlmlist=new List<String>();
        tlmlist.add(String.valueOf(testtlm.Id));
        EDGE_RemoveElementController.removeMember(tlmlist);
        Target_List_Member__c  tlmcheck=[Select ID,Assignment_Status__c from Target_List_Member__c where ID=:testtlm.Id];
        System.assertequals(tlmcheck.Assignment_Status__c ,'Waiting Removal','Waiting Removal should match');     
    }
    @isTest
    public static void searchOutletTerritoryDetailsTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Account testacc=EDGE_UtilityTestClass.getOutletRecord();        
        insert testacc;
        Territory__c terr=EDGE_UtilityTestClass.getTerritoryRec();
        terr.Country__c=geographyId;
        insert terr;
        Outlet_Territory__c  testot=EDGE_UtilityTestClass.getOutltTerritory(testacc.Id,terr.Id);
        insert testot;
        List<Outlet_Territory__c> otlist= new List<Outlet_Territory__c>();
        otlist=EDGE_RemoveElementController.searchOutletTerritoryDetails(' OR Outlet__r.Name LIKE \'%' + 'Test' + '%\'',String.valueOf(testot.Id));
        System.assertNotEquals(otlist,null,'success');
    }
    @isTest
    public static void removeOutletTest(){
        ID countryid=EDGE_UtilityTestClass.setupCountry('AU');
        Account testacc=EDGE_UtilityTestClass.getOutletRecord();
        insert testacc;        
        Territory__c terr=EDGE_UtilityTestClass.getTerritoryRec();
        terr.Country__c=countryid;
        insert terr;
        Outlet_Territory__c  testot=EDGE_UtilityTestClass.getOutltTerritory(testacc.Id,terr.Id);
        insert testot;
        List<String> otlist= new List<String>();
        otlist.add(String.valueOf(testot.Id));
        EDGE_RemoveElementController.removeOutlet(otlist);
        Outlet_Territory__c otcheck=[Select ID,Active__c from Outlet_Territory__c  where ID=:testot.Id];
        System.assertequals(otcheck.Active__c ,'Waiting Removal','Waiting Removal should match');
    }
}