/*
* Class Name: EDGE_DeliveryPartnerEmailServiceTes
* Author: 
* Description: This Test class is used to cover EDGE_DeliveryPartnerEmailService.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0		Rajarshi Lahiri			07/11/2022		Initial Development(ES20-13031)
2.0     Joshraj Sen             08/04/2024      152305 SCA Fix 

*/
@istest
public class EDGE_DeliveryPartnerEmailServiceTest {
	@isTest 
    public static void emailServiceTest(){
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        System.assert(prof!=null,'Profile is Present');
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='GB';
        usr.Title='Legal';
        insert usr;
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        EDGE_UtilityTestClass.createOrgSettings();    
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        outlet.ShippingCountry = 'Australia';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(geographyId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = true;
        insert deliveryPartner;
        
        List<Order__c> lstOrder = new List<Order__c>();
        
        Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(usr.Id, outlet.Id, objContract.Id);
        posOrderGroup.Total_A_P_Cost__c = 20;
        insert posOrderGroup;
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(usr.Id, outlet.Id, objContract.Id);
        posOrder.Order_Group__c = posOrderGroup.Id;
        posOrder.Total_A_P_Cost__c = 20;
        posOrder.Delivery_Partner__c = deliveryPartner.Id;
        lstOrder.add(posOrder);
        
        Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(usr.Id, outlet.Id, objContract.Id);
        posOrder1.Order_Group__c = posOrderGroup.Id;
        posOrder1.Total_A_P_Cost__c = 15;
        posOrder1.Delivery_Partner__c = deliveryPartner.Id;
        lstOrder.add(posOrder1);
        
        insert lstOrder;
        System.debug(LoggingLevel.Debug,'@@lstOrder'+lstOrder);
        List<Id> orderIds=new List<Id>();
        for(Order__c ord: lstOrder){
            orderIds.add(ord.Id);
            
        }
        List<String> orderString=new List<String>();
        for(Order__c ordRec: [Select Name from Order__c where Id IN:orderIds]){
            orderString.add(ordRec.Name);
        }
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId();
        String orderDocContent = string.join(orderIds,',');
        Blob orderliststring = Blob.valueOf(orderDocContent);
        ContentVersion cVersion = new ContentVersion();
        cVersion.RecordTypeId = recordIdContentVersion;
        cVersion.Content_Type__c = 'Other';
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = 'a123b456.txt';	//File name with extention
        cVersion.Title = 'a123b456.txt';	//Name of the file
        cVersion.VersionData = orderliststring;
        insert cVersion;
        Test.startTest();
		List<ContentDocumentLink> conDocLinkList=new List<ContentDocumentLink>();
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        for(Id ord:orderIds){
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;	//Add ContentDocumentId
            cDocLink.LinkedEntityId = ord;	//Add attachment parentId
            cDocLink.ShareType = 'I';	//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDocLink.Visibility = 'InternalUsers';	//AllUsers, InternalUsers, SharedUsers
            conDocLinkList.add(cDocLink);
        }
        insert conDocLinkList;
        Test.stopTest();
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'Test Subject -a123b456';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = 'email body\n2225256325\nTitle';
        email.htmlBody='<html><head></head><body><p>Test body</p></body></html>';
        email.fromName='Test User';
        
        // call the email service class and test it with the data in the testMethod
        EDGE_DeliveryPartnerEmailService  testInbound=new EDGE_DeliveryPartnerEmailService();
        testInbound.handleInboundEmail(email, env);
    }
}