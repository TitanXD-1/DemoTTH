/**********************************************************************
Name: EDGE_OpportunityCountServiceTest

=======================================================================
Req: This is the test class for EDGE_OpportunityCountService,EDGE_OpportunityCountController

=======================================================================
VERSION   AUTHOR              DATE            DETAIL
1.0       Amar Deep          18/12/2020       ES20-9158 
2.0       Dinesh Sharma      11/01/2021       ES20-9284
***********************************************************************/
@isTest
public class EDGE_OpportunityCountServiceTest {
    public static User salesRep;
    @isTest
    public static void testOpportunityCountService(){
        
        Test.startTest();
        createData();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/OpportunityCountService?userid=';
        requri = requri+ String.valueOf(salesRep.Id);
        req.requestUri =requri;
        req.params.put('userid', salesRep.Id);            
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_OpportunityCountService.doGet();
        List<EDGE_OpportunityCountWrapper> OpportunityCountWrapperList = EDGE_OpportunityCountService.doGet();
        system.assert(OpportunityCountWrapperList != null);
        Test.stopTest();
    }
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Business_Role__c businessRole = EDGE_UtilityTestClass.getBusinessRole();
        businessRole.Country__c = countryId;
        businessRole.Global_Equivalent__c = 'Sales Rep';
        insert businessRole;
        
        salesRep = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.Business_Role_ID__c = businessRole.Id;
        salesRep.Business_Role__c = 'Test Role' ;
        insert salesRep;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null);
        
        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
        marketCycle.Start_Date__c = Date.Today();
        marketCycle.End_Date__c = Date.Today().addDays(30);
        marketCycle.Geography__c = countryId;
        insert marketCycle;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Outlet_Member__c outMem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, salesRep.Id, 'Primary'); 
        insert outMem;
            
        Opportunity closedOppRecd = EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        closedOppRecd.StageName = 'Closed';
        insert closedOppRecd;
        
        Opportunity openOppRecd = EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        openOppRecd.StageName = 'Open';
        insert openOppRecd;
        
        Opportunity pendingOppRecd = EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        pendingOppRecd.StageName = 'Pending';
        insert pendingOppRecd;
        
        Opportunity notAchivedOppRecd = EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        notAchivedOppRecd.StageName = 'Not Achieved';
        insert notAchivedOppRecd;
        
    }
}