/**********************************************************************
Name: EDGE_BespokeHistoryServiceTest

=======================================================================
Req: This is the test class for EDGE_BespokeHistoryService,EDGE_BespokeHistoryController

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
2.0     Prasanth T          23/09/2022      ES20-13324(Test Class Correction Due to Failure)
***********************************************************************/
@isTest
public class EDGE_BespokeHistoryServiceTest {
    @isTest
    public static void testBespokeHistoryService(){
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'Sales Manager should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep;        
        System.assert(salesRep.Id!=null,'Sales Rep should not be null');
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/BespokeHistoryService?userid=';
        requri = requri+ String.valueOf(salesRep.Id);
        req.requestUri =requri;
        req.params.put('userid', salesRep.Id);            
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        createData(salesRep);
        EDGE_BespokeHistoryService.doGet();
        List<EDGE_BespokeWrapper> bespokeDetailsList = EDGE_BespokeHistoryService.doGet();
        system.assert(bespokeDetailsList != null,'Bespoke Details List Should not be null');
        Test.stopTest();
    }
    public static void createData(User salesRep){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id defRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment2');
        pickupOption.RecordTypeId = defRecTypeId;
        pickupOption.Name = 'Segment[AU]';
        insert pickupOption;
        

        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');        
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption1;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id; 
        insert outlet;
        
        Outlet_Member__c outMem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, salesRep.Id, 'Primary'); 
        insert outMem;
        
        Market_Setting__c marSet = EDGE_UtilityTestClass.getMarketSetting(countryId); 
        marSet.Bespoke_History_Number__c = 2;
        insert marSet;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        String deliveryPartnerRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = deliveryPartnerRecordTypeId;
        insert deliveryPartner;
        
        String activationRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Activation').getRecordTypeId();
        
        Bespoke__c objBespoke1 = new Bespoke__c();
        objBespoke1.Account__c = outlet.id;
        objBespoke1.RecordTypeId = activationRecordTypeId;
        objBespoke1.Activity_Objectives__c = pickupOption.id;
        objBespoke1.Contract__c = objContract.Id;
        objBespoke1.Country__c = countryId;
        objBespoke1.Sales_Rep__c = salesRep.id;
        objBespoke1.Start_Date__c = System.today();
        objBespoke1.Project_Name__c = 'Test';
        objBespoke1.Delivery_Partner__c = deliveryPartner.id;
        objBespoke1.End_Date__c = System.today().addDays(10);
        objBespoke1.Status__c = 'Draft';
        insert objBespoke1;
        
        
        
        
        EDGE_BespokeWrapper bespokeWrapper = new EDGE_BespokeWrapper();
        bespokeWrapper.bespokeId = objBespoke1.Id;
        bespokeWrapper.bespokeName = objBespoke1.Name;
        bespokeWrapper.outletId = objBespoke1.Account__c;
        bespokeWrapper.deliveryPartnerId = objBespoke1.Delivery_Partner__c;
        bespokeWrapper.bespokeStatus = objBespoke1.Status__c;
        bespokeWrapper.lastModifiedDate = objBespoke1.LastModifiedDate;
        bespokeWrapper.recordTypeId = objBespoke1.RecordTypeId;
        bespokeWrapper.bespokeBudget = objBespoke1.Budget__c;
        bespokeWrapper.bespokeContractId = objBespoke1.Contract__c;
        bespokeWrapper.customerContactEmail = objBespoke1.Customer_Contact_Email__c;
        bespokeWrapper.customerContactPhone = objBespoke1.Customer_Contact_Phone__c;
        bespokeWrapper.customerPreferredContact = objBespoke1.Customer_Preferred_Contact__c;
        bespokeWrapper.diageoContact = objBespoke1.Diageo_Contact__c;
        bespokeWrapper.diageoContactEmail = objBespoke1.Diageo_Contact_Email__c;
        bespokeWrapper.diageoContactPhoneNumber = objBespoke1.Diageo_Contact_Phone_Number__c;
        bespokeWrapper.bespokeEndDate = objBespoke1.End_Date__c;
        bespokeWrapper.bespokeStartDate = objBespoke1.Start_Date__c;
        bespokeWrapper.incrementalNSV = objBespoke1.Incremental_NSV__c;
        bespokeWrapper.incrementalVolume = objBespoke1.Incremental_Volume__c;
        bespokeWrapper.bespokeROI = objBespoke1.ROI__c;
        bespokeWrapper.bespokeProjectName = objBespoke1.Project_Name__c;
        bespokeWrapper.createdDate = objBespoke1.CreatedDate;
        bespokeWrapper.segmentActivation = objBespoke1.Segment_Activation__c;
        bespokeWrapper.activityObjectives = objBespoke1.Activity_Objectives__c;
        bespokeWrapper.productFocus = objBespoke1.Product_Focus__c;
        bespokeWrapper.siteVisitDate = objBespoke1.Site_Visit_Date__c;
        bespokeWrapper.siteVisitTime = objBespoke1.Site_Visit_Time__c;
        bespokeWrapper.venueNotes = objBespoke1.Venue_Notes__c;
        bespokeWrapper.bumpIn = objBespoke1.Bump_In__c;
        bespokeWrapper.bumpOut = objBespoke1.Bump_Out__c;
        bespokeWrapper.userId = NULL;
        try{
            objBespoke1.Status__c = 'Order Placed';
            update objBespoke1;
        } catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        
        
        
    }
}