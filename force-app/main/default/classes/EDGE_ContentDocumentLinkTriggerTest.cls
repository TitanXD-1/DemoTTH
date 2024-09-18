/**
* @Name: EDGE_ContentDocumentLinkTriggerTest

* @Req: This is the test class for ContentDocumentLink Trigger
* @EDGE_ContentDocumentLinkTriggerHelper
* @ContentDocumentLinkTriggerHandler


* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Saurav Paul     13/02/2019      Initial Development
*  2.0	     Aparajita       10/05/2021      Create case feeds after file upload(ES20-9665)
*  3.0		 Saurav Prasad   12/11/2021		 ECM-4924 - Placeholder to upload the T&C pdf in Market Setting_Customer Approval Mail
*  4.0		 Shivam Chauhan		  19/03/2024		151377	- CRG Enhancements_No validation for number of attachments in "Approval mail attachments"_ SFDC
**/
@isTest
public with sharing class EDGE_ContentDocumentLinkTriggerTest {
    
    /**
	Method  : multipleImageTest
Purpose : This is used to cover multiple image scenario
**/
    @isTest
    public static void multipleImageTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
        objPickUp.Name = 'Gold[AUT]';
        insert objPickUp;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');
        
        Survey__c objSurvey = EDGE_UtilityTestClass.getSurvey(geographyId);
        //objSurvey.Grouping__c='Group_1';
        insert objSurvey;
        
        Outlet_Survey__c objOutletSurvey = EDGE_UtilityTestClass.getOutletSurvey(objSurvey.Id,outletAccount.Id);
        insert objOutletSurvey;
        
        Survey_Question__c objSurveyQus = EDGE_UtilityTestClass.getSurveyQuestion(objSurvey.Id);
        insert objSurveyQus;
        
        Outlet_Survey_Response__c objSurveyRes = EDGE_UtilityTestClass.getOutletSurveyRes(objOutletSurvey.Id,objSurveyQus.Id);
        insert objSurveyRes;
        
        Test.startTest();        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle1234.jpeg');
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Outlet-Survey Response').getRecordTypeId();
        conVerRec.Content_Type__c = 'Outlet-Survey Response';
        conVerRec.Title = 'OutletRes.jpeg';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'outletAccount should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objSurveyRes.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        ContentVersion conVerRecSec = EDGE_UtilityTestClass.gerConVerRec('OutleSe1234.jpeg');
        conVerRecSec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Outlet-Survey Response').getRecordTypeId();
        conVerRecSec.Content_Type__c = 'Outlet-Survey Response';
        conVerRecSec.Title = 'OutletSeRes.jpeg';
        insert conVerRecSec;
        System.assert(conVerRecSec.Id != null,'conVerRecSec should not be null');           
        
        List<ContentDocument> documentSec = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRecSec.Id];
        System.assertEquals(documentSec.size(), 1,'documentSec should match');
        
        ContentDocumentLink conDocLnkRecSec = EDGE_UtilityTestClass.getConDocLink (objSurveyRes.Id,documentSec[0].Id);
        insert conDocLnkRecSec;
        System.assert(conDocLnkRecSec.Id != null,'conDocLnkRecSec should not be null');
        
        delete documentSec;
        
        Test.stopTest();
    }
    
    /**
Method  : oppTemplateTest
Purpose : This is used to cover Opportunity_Template__c method
**/
    @isTest
    public static void oppTemplateTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Territory_Hierarchy__c businessUnit = new Territory_Hierarchy__c();
        businessUnit.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        businessUnit.Name = 'AUS';
        businessUnit.Geography__c = geographyId;
        insert businessUnit;
        
        Territory_Hierarchy__c salesArea = new Territory_Hierarchy__c();
        salesArea.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        salesArea.Name = 'SOU';
        salesArea.Parent_BU__c = businessUnit.Id;
        salesArea.Geography__c = geographyId;
        insert salesArea;
        
        Territory_Hierarchy__c region = new Territory_Hierarchy__c();
        region.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        region.Name = 'FSM VIC NORTH';
        region.Parent_BU__c = salesArea.Id;
        region.Geography__c = geographyId;
        insert region;
        
        Territory__c objTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        objTerritory.Region__c = region.Id;
        insert objTerritory;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        insert objProduct;
        
        Opportunity_Template__c objOppTemplate = EDGE_UtilityTestClass.getOpportunityTemplate(objProduct.Id, objTerritory.Id, geographyId);
        objOppTemplate.D1_Content_Reference__c = 'Test';
        insert objOppTemplate;
        
        //This for Opportunity Thumbnail
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle1234.jpeg');
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Opportunity Template').getRecordTypeId();
        conVerRec.Content_Type__c = 'Opportunity Template Image';
        conVerRec.Title = 'OutletRes.jpeg';
        insert conVerRec;
        
        System.assert(conVerRec.Id != null,'conVerRec should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        /*ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name ='Opportunity Template'];
        
        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();        
        newWorkspaceDoc.ContentWorkspaceId = testWorkspace.Id;
        newWorkspaceDoc.ContentDocumentId = documents[0].Id;
        
        insert newWorkspaceDoc;*/
        List<ContentDocumentLink> contentDocList = new List<ContentDocumentLink>();
        ContentDocumentLink conDocLnkRec;
        conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objOppTemplate.Id,documents[0].Id);
        //contentDocList.add(conDocLnkRec);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec id should not be null');
        
        delete documents;
        Test.startTest();
        //This is for Opportunity Presenter
        ContentVersion conVerRecSec = EDGE_UtilityTestClass.gerConVerRec('Outle1234.pdf');
        conVerRecSec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Opportunity Template').getRecordTypeId();
        conVerRecSec.Content_Type__c = 'Opportunity Template Image';
        conVerRecSec.Title = 'OutletRes.pdf';
        insert conVerRecSec;
        System.assert(conVerRecSec.Id != null,'conVerRecSec should not be null');           
        
        //Test.startTest();
        
        List<ContentDocument> documentSec = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRecSec.Id];
        System.assertEquals(documentSec.size(), 1,'documentSec should match');
        
        ContentDocumentLink conDocLnkRecSec;
        conDocLnkRecSec = EDGE_UtilityTestClass.getConDocLink (objOppTemplate.Id,documentSec[0].Id);
        contentDocList.add(conDocLnkRecSec);
      //  insert conDocLnkRecSec;
        //System.assert(conDocLnkRecSec.Id != null,'conDocLnkRecSec id should not be null');
        
        //This is for Opportunity Presenter
        ContentVersion conVerRecThd = EDGE_UtilityTestClass.gerConVerRec('Outle1235.png');
        conVerRecThd.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Opportunity Template').getRecordTypeId();
        conVerRecThd.Content_Type__c = 'Opportunity Template Image';
        conVerRecThd.Title = 'OutletRes.pdf';
        insert conVerRecThd;
        System.assert(conVerRecThd.Id != null,'conVerRecThd should not be null');           
        
        List<ContentDocument> documentThd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRecThd.Id];
        System.assertEquals(documentThd.size(), 1,'documentThd should match');
        try{
            ContentDocumentLink conDocLnkRecThd = EDGE_UtilityTestClass.getConDocLink (objOppTemplate.Id,documentThd[0].Id);
            contentDocList.add(conDocLnkRecThd);
            Insert contentDocList;
            //insert conDocLnkRecThd;
            //System.assert(conDocLnkRecThd.Id != null,'conDocLnkRecThd should not be null');
            
        } catch (Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause()); 
        }        
        
        Test.stopTest();
    }

        /**
Method  : testContractContentversion
Purpose : This is used to cover ContractContentversion method
**/
      @isTest
      public static void testContractContentversion(){
       
          //change made by Aparajita ES20-9665
          User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
          insert newUser;
          System.runAs(newUser){
              List<ContentDocument> adminDocuments;
              adminDocuments  = new List<ContentDocument>();
              List<ContentDocument> adminDocuments1;
              adminDocuments1 = new List<ContentDocument>();
        Profile prof = [select id,Name from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
              
        CM_Attachment_Permission__mdt cmAttach = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName,
                                                  Country_Code__c, File_Type__c, Content_Type__c, Permission__c, Profile_Name__c FROM CM_Attachment_Permission__mdt 
                                                  where Profile_Name__c=:prof.Name AND Country_Code__c=:usr.Available_Countries__c LIMIT 1];
        cmAttach.Content_Type__c = 'Signed Contract';
        cmAttach.File_Type__c='Contracts';
        cmAttach.Object__c='Contract';
        cmAttach.Profile_Name__c = 'Sales Representative';
              
              
              System.runAs(usr){
                  
                  Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
                  EDGE_UtilityTestClass.createOrgSettings();
                  
                  Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
                  objPickUp.Name = 'Gold[AUT]';
                  insert objPickUp;
                  
                  Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
                  outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
                  outletAccount.VAT_Number__c='6789';
                  outletAccount.New_VAT__c='56789';
                  outletAccount.SAP_Ship_to__c='AGS';
                  outletAccount.SAP_Sold_to__c='THH';
                  outletAccount.Sales_Org__c='0923';
                  outletAccount.Email_for_contracts_payments__c='test@test.com';
                  outletAccount.ECM_Legal_Name__c='Test';
                  insert outletAccount;
                  
                  Market_Setting__c marksettings = EDGE_UtilityTestClass.getMarketSetting(geographyId);
                  marksettings.ECM_Contract_Management_Market__c=true;
                  marksettings.ECM_SAP_Order_Type__c='IPAS';
                  marksettings.ECM_Payment_Management_Email__c='Test@yupmail.com';
                  marksettings.ECM_Email_to_Send_Payment_CSV__c='Tes1t@yupmail.com';
                  marksettings.ECM_Contract_Creation_Page__c='Australia';
                  marksettings.Threshold_Format__c ='Percent';
                  marksettings.ECM_Max_Days_to_upload_Signed_PDF__c = 1;
                  marksettings.ECM_Mandatory_field_for_Contract__c='SAP Sold to;VAT number;Legal Name;SAP Ship to;Customer email for Contract;Sales org;Tax Identification number';
                  insert marksettings;
                  
                  //Added part of ECM-4924
                  Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
                  ContentVersion cVersion = new ContentVersion();
                  if(String.isNotEmpty(recordIdContentVersion)){
                      cVersion.RecordTypeId = recordIdContentVersion;
                  }
                  cVersion.Content_Type__c = 'Terms and Conditions';
                  cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                  cVersion.PathOnClient = 'Test.pdf';//File name with extention
                  cVersion.Title = 'Test';//Name of the file
                  cVersion.VersionData = Blob.valueOf('Unit Test');//File content
                  Insert cVersion;
                  
                  //System.assert(cVersion.Id !=null,'cVersion should not be null');
                  
                  //After saved the Content Verison, get the ContentDocumentId
                  Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                  ContentDocumentLink cDocLink = new ContentDocumentLink();
                  cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                  cDocLink.LinkedEntityId = marksettings.Id;//Add attachment parentId
                  cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                  cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                  Insert cDocLink;
                  
                  //System.assert(cDocLink.Id !=null,'cDocLink should not be null');
                  //End of ECM-4924
                  
                  ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
                  contractType.Name='Promotional';
                  contractType.Geography__c=geographyId;
                  contractType.ECM_Abbreviation__c='POM';
                  contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
                  contractType.Volume_UoM_for_Spirits__c='CAS';
                  contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
                  contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment;Rate Per UoM;UoM;';
                  contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
				  //contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
				  insert contractType;
                  
                  String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
                  
                  Pick_Up_Options__c banner= new Pick_Up_Options__c();
                  banner.Name='Range[ES]';
                  banner.Geography__c=geographyId;
                  banner.RecordTypeId=bannerRecordTypeId;
                  // insert banner;            
                  Test.startTest();
                  String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                  Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
                  objContract.Status = 'Draft';
                  objContract.Contract_End_Date__c = System.today()+29;
                  objContract.AccountId=outletAccount.Id;
                  // objContract.ECM_Territory__c=testterritory.Id;
                  objContract.ECM_Overall_Investment_Amount__c=100020.55;
                  objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
                  objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
                  objContract.ECM_Overall_Investment_Figure__c=122.43;
                  objContract.ECM_Agreement_Type__c=contractType.Id;
                  //  objContract.ECM_Agreement_Type__c=contractType.Id;
                  objContract.recordTypeId=contractRecordTypeId;
                  objContract.ECM_Channel__c='On-Premise';
                  // objContract.ECM_Banner__c=banner.Id;
                  objContract.StartDate = system.today();
                  objContract.Contract_End_Date__c = system.today()+360;           
                  insert objContract;
                  
                  objContract.status='Approved';
                  update objContract;        
                  
                  //This for Opportunity Thumbnail
                  ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
                  conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
                  conVerRec.Content_Type__c = 'Signed Contract';
                  conVerRec.Title = 'Signed_Contract.jpeg';
                  conVerRec.ECM_Customer_Signed_Date__c = Date.today();
                  insert conVerRec;
                  //System.assert(conVerRec.Id != null,'conVerRec should not be null');           
                  
                  List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where ContentDocument.LatestPublishedVersion.RecordTypeId!=:recordIdContentVersion];
                  //System.assertEquals(documents.size(), 1,'documents should match');
                  //Added by Aparajita
                  adminDocuments = documents.clone();
                  //
                  
                  ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objContract.Id,adminDocuments[0].Id);
                  insert conDocLnkRec; 
                  
                  System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
                  
              }

                  delete adminDocuments;
              
              
              //Added part of ECM-4924
              Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
              ContentVersion cVersion1 = new ContentVersion();
              if(String.isNotEmpty(recordIdContentVersion)){
                  cVersion1.RecordTypeId = recordIdContentVersion;
              }
              cVersion1.Content_Type__c = 'Terms and Conditions';
              cVersion1.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
              cVersion1.PathOnClient = 'Test.pdf';//File name with extention
              cVersion1.Title = 'Test';//Name of the file
              cVersion1.VersionData = Blob.valueOf('Unit Test');//File content
              Insert cVersion1;
              
              System.assert(cVersion1.Id != null,'cVersion1 should not be null');
              
              Market_Setting__c marketRecord = [Select Id from Market_Setting__c LIMIT 1];
              
              System.assert(marketRecord.Id != null,'marketRecord should not be null');
              
              //After saved the Content Verison, get the ContentDocumentId
              Id conDocument1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion1.Id].ContentDocumentId;
              ContentDocumentLink cDocLink1 = new ContentDocumentLink();
              cDocLink1.ContentDocumentId = conDocument1;//Add ContentDocumentId
              cDocLink1.LinkedEntityId = marketRecord.Id;//Add attachment parentId
              cDocLink1.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
              cDocLink1.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
              
              try{
                  Insert cDocLink1;
              }catch(Exception ex){
                  System.debug(LoggingLevel.Debug,'Handled Exception for insertion of more than one pdf on market setting record');
              }
              //End of ECM-4924
              
              Test.stopTest();
          }
        }
    /**
Method  : updatePaymentFields
Purpose : This is used to cover updateProductDetails method
**/
    
   @isTest
    public static void updatePaymentFieldsTest(){
        //change made by Aparajita ES20-9665
          User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
          insert newUser;
          System.runAs(newUser){
              List<ContentDocument> adminDocuments = new List<ContentDocument>();
        Profile prof = [select id,Name from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
              
        CM_Attachment_Permission__mdt cmAttach = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName,
                                                  Country_Code__c, File_Type__c, Content_Type__c, Permission__c, Profile_Name__c FROM CM_Attachment_Permission__mdt 
                                                  where Profile_Name__c=:prof.Name AND Country_Code__c=:usr.Available_Countries__c LIMIT 1];
        cmAttach.Content_Type__c = 'Signed Contract';
        cmAttach.File_Type__c='Contracts';
        cmAttach.Object__c='Contract';
        cmAttach.Profile_Name__c = 'Sales Representative';
		
       	
              System.runAs(usr){
                  
                  Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
                  EDGE_UtilityTestClass.createOrgSettings();
                  
                  Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
                  objPickUp.Name = 'Gold[AUT]';
                  insert objPickUp;
                  
                  Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
                  outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;                  
                  insert outletAccount;
                  
                  ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
                  contractType.Name='Promotional';
                  contractType.Geography__c=geographyId;
                  contractType.ECM_Abbreviation__c='POM';
                  contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
                  contractType.Volume_UoM_for_Spirits__c='CAS';
                  contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
                  contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Volume Target';
                  contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
				  insert contractType;
                  
                  String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
                  
                  Pick_Up_Options__c banner= new Pick_Up_Options__c();
                  banner.Name='Range[ES]';
                  banner.Geography__c=geographyId;
                  banner.RecordTypeId=bannerRecordTypeId;
                  
                  Test.startTest();
                  String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                  Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
                  objContract.Status = 'Draft';
                  objContract.Contract_End_Date__c = System.today()+29;
                  objContract.AccountId=outletAccount.Id;
                  objContract.ECM_Overall_Investment_Amount__c=100020.55;
                  objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
                  objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
                  objContract.ECM_Overall_Investment_Figure__c=122.43;
                  objContract.ECM_Agreement_Type__c=contractType.Id;
                  objContract.recordTypeId=contractRecordTypeId;
                  objContract.ECM_Channel__c='On-Premise';
                  objContract.StartDate = system.today();
                  objContract.Contract_End_Date__c = system.today()+360;           
                  insert objContract;                  
                  objContract.status='Approved';
                  update objContract;                  
                  
                  ECM_Payment_Summary__c paySummary =ECM_UtilityTestClass.getPaymentSummary(objContract.Id);
                  insert paySummary;
                  ContentVersion payConVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
                  payConVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
                  payConVerRec.Content_Type__c = 'Evidence';
                  payConVerRec.Title = 'Signed_Contract.jpeg';                  
                  insert payConVerRec;
                  List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
                  System.assertEquals(documents1.size(), 1,'documents1 should match');
                  ContentDocumentLink conDocLnkRecPay = EDGE_UtilityTestClass.getConDocLink (paySummary.Id,documents1[0].Id);
                  insert conDocLnkRecPay;
                  System.assert(conDocLnkRecPay.Id != null,'conDocLnkRecPay should not be null');
                    Test.stopTest();
              }
              
            delete adminDocuments;
              
            
          }
    }
    
    /**
Method  : updateProductDetailsTest
Purpose : This is used to cover updateProductDetails method
**/
    
    @isTest
    public static void updateProductDetailsTest(){
        Id geographyId;
        geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        try{            
            Product__c product= EDGE_UtilityTestClass.getProd();
            insert product;
            System.assert(product.Id != null,'product should not be null');
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('ProductImage_1234.jpeg');
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            conVerRec.Content_Type__c = 'Product Image';
            conVerRec.Title = 'ProductImage_1234.jpeg';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');           
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (product.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            
            
            ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('ProductImage_12345.jpeg');
            conVerRec1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            conVerRec1.Content_Type__c = 'Product Image';
            conVerRec1.Title = 'ProductImage_12345.jpeg';
            insert conVerRec1;
            System.assert(conVerRec1.Id != null,'conVerRec1 should not be null');           
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRec1.id];
            System.assertEquals(documents1.size(), 1,'documents1 should match');
            
            ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (product.Id,documents1[0].Id);
            insert conDocLnkRec1;
            System.assert(conDocLnkRec1.Id != null,'conDocLnkRec1 should not be null');            
            
        }catch(Exception ex){
            //Checking file type update validation
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        Test.stopTest();
    }
    
    /**
Method  : recordNameNotMatchedTest
Purpose : This is used to cover checkRecordTypePerObject method
**/
    @isTest
    public static void recordNameNotMatchedTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        try{
            Id geographyId;
            geographyId= EDGE_UtilityTestClass.setupCountry('AUT'); 
            Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
            insert disAccrec;
            System.assert(disAccrec.Id != null,'disAccrec should not be null');
            System.debug(LoggingLevel.Debug,'disAccrec::'+disAccrec);
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('OutleImage_1234.jpeg');
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Opportunity Template').getRecordTypeId();
            conVerRec.Content_Type__c = 'Opportunity Template Image';
            conVerRec.Title = 'OutleImage_1234.jpeg';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null'); 
            System.debug(LoggingLevel.Debug,'conVerRec::'+conVerRec);
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            System.debug(LoggingLevel.Debug,'documents::'+documents);
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (disAccrec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            System.debug(LoggingLevel.Debug,'conDocLnkRec::'+conDocLnkRec);
            
        }catch(Exception ex){
            //Checking file type update validation
            System.debug(LoggingLevel.Debug,'ex'+ex.getMessage()+ex.getLineNumber());
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        Test.stopTest();
        
    }
    
    /**
Method  : NotificationlateTest
Purpose : This is used to cover Opportunity_Template__c method
**/
    @isTest
    public static void notificationTemplateTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Territory_Hierarchy__c businessUnit = new Territory_Hierarchy__c();
        businessUnit.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        businessUnit.Name = 'AUS';
        businessUnit.Geography__c = geographyId;
        insert businessUnit;
        
        Territory_Hierarchy__c salesArea = new Territory_Hierarchy__c();
        salesArea.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        salesArea.Name = 'SOU';
        salesArea.Parent_BU__c = businessUnit.Id;
        salesArea.Geography__c = geographyId;
        insert salesArea;
        
        Territory_Hierarchy__c region = new Territory_Hierarchy__c();
        region.RecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        region.Name = 'FSM VIC NORTH';
        region.Parent_BU__c = salesArea.Id;
        region.Geography__c = geographyId;
        insert region;
        
        Territory__c objTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        objTerritory.Region__c = region.Id;
        insert objTerritory;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        insert objProduct;
        
        Opportunity_Template__c objOppTemplate = EDGE_UtilityTestClass.getOpportunityTemplate(objProduct.Id, objTerritory.Id, geographyId);
        insert objOppTemplate;
        
        String newsFeedRecordTypeId = Notification__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Edge365 Newsfeed').getRecordTypeId();
        String notiContentTypeRecTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Notification').getRecordTypeId();
        
        Notification__c notificationObj = new Notification__c(Status__c = 'Draft',Start_Date__c= System.today(), End_Date__c= System.today() + 5, Country__c = geographyId, RecordTypeId = newsFeedRecordTypeId);
        insert notificationObj;
        
        Test.startTest();
        //This is for Notification Image
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Notification1234.jpeg');
        conVerRec.RecordTypeId = notiContentTypeRecTypeId;
        conVerRec.Content_Type__c = 'Notification Image';
        conVerRec.Title = 'Notification001.jpeg';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');           
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1,'documents should match');
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (notificationObj.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        
        
        Test.stopTest();
    }
    
    /**
Method  : upsertDirectCustomerData
Purpose : This is used to cover upsertDirectCustomerData method
**/
    @isTest
    public static void upsertDirectCustomerData(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        try{
            Id geographyId;
            set<Id> contentDocLinkIds = new set<Id>();
            geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
            Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
            insert disAccrec;
            System.assert(disAccrec.Id != null,'disAccrec should not be null');
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            conVerRec.Content_Type__c = 'Direct Customer';
            conVerRec.Title = 'Test.jpeg';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');           
            Test.startTest();
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (disAccrec.Id,documents[0].Id);
            insert conDocLnkRec;
            contentDocLinkIds.add(conDocLnkRec.Id);
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            
           
            ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            conVerRec1.Content_Type__c = 'Direct Customer';
            conVerRec1.Title = 'Test.jpeg';
            insert conVerRec1;
            System.assert(conVerRec1.Id != null,'conVerRec1 should not be null');           
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRec1.id];
            System.assertEquals(documents1.size(), 1,'documents1 should match');
           // Test.startTest();
            ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (disAccrec.Id,documents1[0].Id);
            insert conDocLnkRec1;
            contentDocLinkIds.add(conDocLnkRec1.Id);
            System.assert(conDocLnkRec1.Id != null,'conDocLnkRec1 should not be null');            
            
            //Added to increase code coverage 
            Map<Id,ContentDocumentLink> mapContentDoc = new Map<Id,ContentDocumentLink>();
            String contentWorkSpaceName = 'Direct Customer';
            Id linkedEntityId = disAccrec.Id;
            for(ContentDocumentLink objConDocLink :
                [Select Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                 ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                 ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.CreatedDate,ContentDocument.LatestPublishedVersion.Content_Type__c
                 FROM ContentDocumentLink 
                 WHERE Id IN :contentDocLinkIds WITH SECURITY_ENFORCED]){
                     mapContentDoc.put(objConDocLink.ContentDocumentId,objConDocLink);
                 }
            EDGE_ContentDocumentLinkTriggerHelper.upsertDirectCustomerData(mapContentDoc, contentWorkSpaceName, linkedEntityId, true,false);  
            Test.stopTest(); 
        }catch(Exception ex){
            //Checking file type update validation
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        
    }
    
    
    /**
Method  : upsertShareTest
Purpose : This is used to cover changeVisiblityPublic and createShare method
**/
    @isTest
    public static void upsertShareTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        try{
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
              EDGE_UtilityTestClass.createOrgSettings();
              
              Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
              objPickUp.Name = 'Gold[AUT]';
              insert objPickUp;
              
              Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
              outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
              insert outletAccount;
            
            
             String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
              Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
              objContract.Status = 'Draft';
              objContract.Contract_End_Date__c = System.today()+29;
              objContract.AccountId=outletAccount.Id;
              // objContract.ECM_Territory__c=testterritory.Id;
              objContract.ECM_Overall_Investment_Amount__c=100020.55;
              objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
              objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
              objContract.ECM_Overall_Investment_Figure__c=122.43;
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            conVerRec.Content_Type__c = 'Direct Customer';
            conVerRec.Title = 'Test.jpeg';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');           
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (outletAccount.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            
            
            ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            conVerRec1.Content_Type__c = 'Direct Customer';
            conVerRec1.Title = 'Test.jpeg';
            insert conVerRec1;
            System.assert(conVerRec1.Id != null,'conVerRec1 should not be null');           
            
            List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =:conVerRec1.id];
            System.assertEquals(documents1.size(), 1,'documents1 should match');
            Test.startTest();
            ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (outletAccount.Id,documents1[0].Id);
            insert conDocLnkRec1;
            System.assert(conDocLnkRec1.Id != null,'conDocLnkRec1 should not be null');            
            Test.stopTest(); 
        }catch(Exception ex){
            //Checking file type update validation
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        
    }
    
 /**
Method  : insertCaseAttachmentToFeedTest
Purpose : This is used to cover insertCaseAttachmentToFeed method
**/
    @isTest
    public static void insertCaseAttachmentToFeedTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId;
        geographyId  = EDGE_UtilityTestClass.setupCountry('AUT'); 
        User intUser= EDGE_UtilityTestClass.runAsUser('integrationUser','Integration User Profile');
        intUser.Default_Country__c = 'AU';
        intUser.Available_Countries__c = 'AU';
        insert intUser;
        Test.startTest();
        try{
            System.runAs(intUser){
            Case caseRec = new Case();
            caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
            caseRec.Origin = 'EDGE365';
            caseRec.Status = 'In Progress';
            insert caseRec;
            System.assert(caseRec.Id != null,'caseRec should not be null');
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test';
            conVerRec.PathOnClient = 'Test.jpeg';
            conVerRec.VersionData = Blob.valueOf('Test Content');
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');           
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (caseRec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            
            FeedItem feedRec = new FeedItem();
            feedRec.Body = Label.EDGE_DefaultCaseFeedBody;
            feedRec.ParentId = caseRec.Id;
            insert feedRec;
            System.assert(feedRec.Id != null,'feedRec should not be null');
            
            FeedAttachment attachmentRec = new FeedAttachment();
            attachmentRec.FeedEntityId = feedRec.Id;//Chatter Post Id
            attachmentRec.RecordId = conVerRec.Id;//Document Id
            attachmentRec.Type = 'CONTENT'; 
            insert attachmentRec;
            System.assert(attachmentRec.Id != null,'attachmentRec should not be null');
            
            FeedAttachment feedAttachmentObj = [SELECT Id,FeedEntityId, RecordId FROM FeedAttachment];
            System.assertEquals(conVerRec.Id,feedAttachmentObj.RecordId,'conVerRec should match');
        }
        }catch(Exception ex){
            //Checking file type update validation
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        Test.stopTest();
    }
     /**
Method  : insertCaseAttachmentToSNOWTest
Purpose : This is used to cover insertCaseAttachmentToSNowTicket method
**/
    @isTest
    public static void insertCaseAttachmentToSNOWTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId; 
        geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        
        Test.startTest();
        try{
            Case caseRec = new Case();
            caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
            caseRec.Origin = 'EDGE365';
            caseRec.Status = 'In Progress';
            insert caseRec;
            System.assert(caseRec.Id != null,'caseRec should not be null');
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test';
            conVerRec.PathOnClient = 'Test.jpeg';
            conVerRec.VersionData = Blob.valueOf('Test Content');
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');           
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'documents should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (caseRec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
            
          
        }catch(Exception ex){
            //Checking file type update validation
            System.assert(ex.getMessage() != null,'ex should not be null');
        }
        Test.stopTest();
    }
    /**
	* @description : test method updateRecordType
	* @param : void Id
	* @return : void	
	*/
    @isTest
    public static void updateRecordType(){
        Test.startTest();
        Profile prof = [SELECT Id FROM profile WHERE name=: 'Legal User'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        
        System.runAs(usr){   
            
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
            
            //Territory Hierarchy records creation for all different recordtypes
            Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Business Unit');
            insert terrHierBsUnitobj; 
            Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Sales Area');
            terrHierSalAreaobj.Parent_BU__c = terrHierBsUnitobj.Id;
            insert terrHierSalAreaobj;
            Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Region');
            terrHierRegionobj.Parent_BU__c = terrHierSalAreaobj.Id;
            insert terrHierRegionobj;
            
            //Create Territory
            Territory__c testterritory = EDGE_UtilityTestClass.getTerritoryRec();
            testterritory.Name ='Testterriotory';
            testterritory.Territory_Type__c ='Sales';
            testterritory.Region__c = terrHierRegionobj.Id;
            testterritory.Country__c= geographyId;
            testterritory.Status__c = 'Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            //CReate OutletAccount
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c = usr.Id;
            outletAccount.OwnerId = usr.Id;
            insert outletAccount;
            System.assert(outletAccount.Id != null,'outletAccount should not be null');
            
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.getAgreementType(geographyId);
            contractType.Name ='Promotional';
            contractType.Geography__c = geographyId;
            contractType.ECM_Abbreviation__c ='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
            insert contractType;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today();
            objContract.AccountId = outletAccount.Id;
            objContract.ECM_Territory__c = testterritory.Id;
            objContract.ECM_Agreement_Type__c = contractType.Id;
            objContract.recordTypeId = contractRecordTypeId;
            objContract.ECM_Channel__c = 'On-Premise';
            objContract.StartDate = system.today();
            objContract.ECM_Duration__c = 12;
            objContract.ECM_Hybrid_UOS_PerTerm__c = 3;
            objContract.ECM_Total_Upfront_Payment_Loan_Over_Term__c = 2;
            objContract.Contract_End_Date__c = system.today()+360;
            objContract.ECM_Overall_Investment_Amount__c = 30.00;
            insert objContract;
            objContract.Status = 'In Signing Customer';
            update objContract;
            
            ECM_Addendum__c addendumRec = ECM_UtilityTestClass.getAddendum(objContract.Id);
            insert addendumRec;
            addendumRec.ECM_Status__c = 'Approved';
            addendumRec.ECM_New_T_C__c = 'Checking';
            update addendumRec;
            
            EDGE_UtilityTestClass.createOrgSettings();
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test.jpeg';
            conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
      		conVerRec.Content_Type__c = 'Amended T&C';
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec should not be null');
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument ];
            System.assertEquals(documents.size(), 1,'documents should match');
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (addendumRec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec should not be null');
        }
        Test.stopTest();
    }
    /**
	* @description : Test CST Claim testCSTClaim
	* @param : void
	* @return : void	
	*/
	@isTest
    public static void testCSTClaim(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        
		Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[SEU]';
        pickupOption.Sales_Organisation__c= salesorg.Id;
		pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        outletAccount.CST_Default_Approver__c=UserInfo.getUserId();
        outletAccount.Direct_Customer__c=true;
        outletAccount.Sales_Organisation__c = salesorg.Id;
        insert outletAccount;
        outletAccount.Direct_Customer__c=true;
        update outletAccount;
        
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);
        claim.CST_Total_Amount__c=10.00;
        claim.CST_Approver__c=UserInfo.getUserId();
        claim.CST_Sales_Organisation__c = salesorg.Id;
		insert claim;
        Test.startTest();
        EDGE_UtilityTestClass.createOrgSettings();
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test CST Claim.jpeg');
        conVerRec.Title = 'Test.jpeg';
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        conVerRec.Content_Type__c = 'Amended T&C';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not null');
       
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument ];
        System.assertEquals(documents.size(), 1,'documents should match');
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (claim.Id,documents[0].Id);
        insert conDocLnkRec;
        Test.stopTest();
        
    }



	/**
	* @description : Test method testContentTypeApprovalMailAttachment
	* @param : void
	* @return : void	
	*/
    @isTest
    public static void testContentTypeApprovalMailAttachment(){
        User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
          insert newUser;
          System.runAs(newUser){
        List<ContentDocument> adminDocuments = new List<ContentDocument>();
        Profile prof = [select id,Name from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        CM_Attachment_Permission__mdt cmAttach = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName,
                                                  Country_Code__c, File_Type__c, Content_Type__c, Permission__c, Profile_Name__c FROM CM_Attachment_Permission__mdt 
                                                  where Profile_Name__c=:prof.Name AND Country_Code__c=:usr.Available_Countries__c LIMIT 1];
        cmAttach.Content_Type__c = 'Approval Mail Attachment';
        cmAttach.File_Type__c='Contracts';
        cmAttach.Object__c='Contract';
        cmAttach.Profile_Name__c = 'Sales Representative';
   
              System.runAs(usr){
                  
                  Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
                  EDGE_UtilityTestClass.createOrgSettings();
                  
                  Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
                  objPickUp.Name = 'Gold[AUT]';
                  insert objPickUp;
                  
                  Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
                  outletAccount.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
                  outletAccount.VAT_Number__c='6789';
                  outletAccount.New_VAT__c='56789';
                  outletAccount.SAP_Ship_to__c='AGS';
                  outletAccount.SAP_Sold_to__c='THH';
                  outletAccount.Sales_Org__c='0923';
                  outletAccount.Email_for_contracts_payments__c='test@test.com';
                  outletAccount.ECM_Legal_Name__c='Test';
                  insert outletAccount;
                  
                  ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
                  contractType.Name='Promotional';
                  contractType.Geography__c=geographyId;
                  contractType.ECM_Abbreviation__c='POM';
                  contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
                  contractType.Volume_UoM_for_Spirits__c='CAS';
                  contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
                  contractType.ECM_Screen_3_field_configuration__c='Product Name;UoM;Volume Target';
                  contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
				  //contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
				  insert contractType;
                  
                  String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
                  
                  Pick_Up_Options__c banner= new Pick_Up_Options__c();
                  banner.Name='Range[ES]';
                  banner.Geography__c=geographyId;
                  banner.RecordTypeId=bannerRecordTypeId;
                  // insert banner;            
                  Test.startTest();
                  String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                  Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
                  objContract.Status = 'Draft';
                  objContract.Contract_End_Date__c = System.today()+29;
                  objContract.AccountId=outletAccount.Id;
                  // objContract.ECM_Territory__c=testterritory.Id;
                  objContract.ECM_Overall_Investment_Amount__c=100020.55;
                  objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
                  objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
                  objContract.ECM_Overall_Investment_Figure__c=122.43;
                  objContract.ECM_Agreement_Type__c=contractType.Id;
                  objContract.recordTypeId=contractRecordTypeId;
                  objContract.ECM_Channel__c='On-Premise';
                  // objContract.ECM_Banner__c=banner.Id;
                  objContract.StartDate = system.today();
                  objContract.Contract_End_Date__c = system.today()+360;           
                  insert objContract;
                  
                  objContract.status='Approved';
                  update objContract;      
                  
                 Id recordIdOfContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
                  ContentVersion contVersion = new ContentVersion();
                  if(String.isNotEmpty(recordIdOfContentVersion)){
                      contVersion.RecordTypeId = recordIdOfContentVersion;
                  }
                  contVersion.Content_Type__c = 'Approval Mail Attachment';
                  contVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                  contVersion.PathOnClient = 'Test.pdf';//File name with extention
                  contVersion.Title = 'Test';//Name of the file
                  contVersion.VersionData = Blob.valueOf('Unit Test');//File content
                  Insert contVersion;
                  
                  System.assert(contVersion.Id !=null,'contVersion should not be null');
                  
                  //After saved the Content Verison, get the ContentDocumentId
                  Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contVersion.Id].ContentDocumentId;
                  ContentDocumentLink cDocLink = new ContentDocumentLink();
                  cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                  cDocLink.LinkedEntityId = objContract.Id;//Add attachment parentId
                  cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                  cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                  Insert cDocLink;
                  
                  System.assert(cDocLink.Id !=null,'v should not be null'); 
                  }
              
            delete adminDocuments;
              
              Id recordIdOfContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
                  ContentVersion contVersion1 = new ContentVersion();
                  if(String.isNotEmpty(recordIdOfContentVersion)){
                      contVersion1.RecordTypeId = recordIdOfContentVersion;
                  }
                  contVersion1.Content_Type__c = 'Approval Mail Attachment';
                  contVersion1.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                  contVersion1.PathOnClient = 'Test.pdf';//File name with extention
                  contVersion1.Title = 'Test';//Name of the file
                  contVersion1.VersionData = Blob.valueOf('Unit Test');//File content
                  Insert contVersion1;
                  
                  System.assert(contVersion1.Id !=null,'v should not be null');
              
              Contract contractRecord = [Select Id from Contract LIMIT 1];
              
              System.assert(contractRecord.Id != null,'contractRecord should not be null');
              
              //After saved the Content Verison, get the ContentDocumentId
              Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contVersion1.Id].ContentDocumentId;
                  ContentDocumentLink cDocLink1 = new ContentDocumentLink();
                  cDocLink1.ContentDocumentId = conDocument;//Add ContentDocumentId
                  cDocLink1.LinkedEntityId = contractRecord.Id;//Add attachment parentId
                  cDocLink1.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                  cDocLink1.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
              
              try{
                  Insert cDocLink1;
              }catch(Exception ex){
                  System.debug(LoggingLevel.Debug,'Handled Exception for insertion of more than one Approval Mail Attachment for Contract record');
              }
              //End of ECM-4959
              
              Test.stopTest();
    }
    }

       /**
Method  : onAddingSignedPDFTest
Purpose : This is used to cover onAddingContractAttachment method
**/
    
    @isTest
    public static void onAddingSignedPDFTest(){
        //change made by Swagata ECM-5901
        User adminUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
        insert adminUser;
        System.runAs(adminUser){
            List<ContentDocument> adminDocuments = new List<ContentDocument>();
            Profile prof = [select id,Name from profile where name=: 'Sales Representative'];
            User user1 = new User();
            user1.firstName = 'test1';
            user1.lastName = 'test2';
            user1.profileId = prof.id;        
            user1.email = 'test@test.com';
            user1.Username ='testcm123@test.com';
            user1.Alias='test';
            user1.Timezonesidkey='America/Los_Angeles';
            user1.LocaleSidKey='en_US';
            user1.LanguageLocaleKey='en_US';
            user1.EmailEncodingKey='UTF-8';
            user1.Available_Countries__c='ES';
            user1.Title='Legal';
            insert user1;
            CM_Attachment_Permission__mdt cmPermss = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName,
                                                      Country_Code__c, File_Type__c, Content_Type__c, Permission__c, Profile_Name__c FROM CM_Attachment_Permission__mdt 
                                                      where Profile_Name__c=:prof.Name AND Country_Code__c=:user1.Available_Countries__c LIMIT 1];
            cmPermss.Content_Type__c = 'Signed Contract';
            cmPermss.File_Type__c='Contracts';
            cmPermss.Object__c='Contract';
            cmPermss.Profile_Name__c = 'Sales Representative';
            
            
            System.runAs(user1){
                
                Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
                EDGE_UtilityTestClass.createOrgSettings();
                
                Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
                objPickUp.Name = 'Gold[AUT]';
                insert objPickUp;
                
                Account outltAccnt = EDGE_UtilityTestClass.getOutletRecord();
                outltAccnt.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
                outltAccnt.VAT_Number__c='6789';
                outltAccnt.New_VAT__c='56789';
                outltAccnt.SAP_Ship_to__c='AGS';
                outltAccnt.SAP_Sold_to__c='THH';
                outltAccnt.Sales_Org__c='0923';
                outltAccnt.Email_for_contracts_payments__c='test@test.com';
                outltAccnt.ECM_Legal_Name__c='Test';
                insert outltAccnt;
                
                Market_Setting__c mrktStng = EDGE_UtilityTestClass.getMarketSetting(geographyId);
                mrktStng.ECM_Contract_Management_Market__c=true;
                mrktStng.ECM_SAP_Order_Type__c='IPAS';
                mrktStng.ECM_Payment_Management_Email__c='Test@yupmail.com';
                mrktStng.ECM_Email_to_Send_Payment_CSV__c='Tes1t@yupmail.com';
                mrktStng.ECM_Contract_Creation_Page__c='Australia';
                mrktStng.Threshold_Format__c ='Percent';
                mrktStng.ECM_Mandatory_field_for_Contract__c='SAP Sold to;VAT number;Legal Name;SAP Ship to;Customer email for Contract;Sales org;Tax Identification number';
                insert mrktStng;
                
                //Added part of ECM-4924
                Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
                ContentVersion cVersion = new ContentVersion();
                if(String.isNotEmpty(recordIdContentVersion)){
                    cVersion.RecordTypeId = recordIdContentVersion;
                }
                cVersion.Content_Type__c = 'Terms and Conditions';
                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersion.PathOnClient = 'Test.pdf';//File name with extention
                cVersion.Title = 'Test';//Name of the file
                cVersion.VersionData = Blob.valueOf('Unit Test');//File content
                Insert cVersion;
                
                System.assert(cVersion.Id !=null,'ContentVerion should match');
                
                //After saved the Content Verison, get the ContentDocumentId
                Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                cDocLink.LinkedEntityId = mrktStng.Id;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                Insert cDocLink;
                
                System.assert(cDocLink.Id !=null,'ContentDocLink should match');
                
                
                ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
                contractType.Name='Promotional';
                contractType.Geography__c=geographyId;
                contractType.ECM_Abbreviation__c='POM';
                contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
                contractType.Volume_UoM_for_Spirits__c='CAS';
                contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
                contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment;Rate Per UoM;UoM;';
                contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
                //contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
                insert contractType;
                
                String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
                
                Pick_Up_Options__c banner= new Pick_Up_Options__c();
                banner.Name='Range[ES]';
                banner.Geography__c=geographyId;
                banner.RecordTypeId=bannerRecordTypeId;
                // insert banner;            
                Test.startTest();
                String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                Contract objContract = EDGE_UtilityTestClass.getContract(outltAccnt.Id, contractRecordTypeId);
                objContract.Status = 'Draft';
                objContract.Contract_End_Date__c = System.today()+29;
                objContract.AccountId=outltAccnt.Id;
                // objContract.ECM_Territory__c=testterritory.Id;
                objContract.ECM_Overall_Investment_Amount__c=100020.55;
                objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
                objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
                objContract.ECM_Overall_Investment_Figure__c=122.43;
                objContract.ECM_Agreement_Type__c=contractType.Id;
                //  objContract.ECM_Agreement_Type__c=contractType.Id;
                objContract.recordTypeId=contractRecordTypeId;
                objContract.ECM_Channel__c='On-Premise';
                // objContract.ECM_Banner__c=banner.Id;
                objContract.StartDate = system.today();
                objContract.Contract_End_Date__c = system.today()+360;           
                objContract.ECM_Digitally_Signed__c = 'OTP Used';
                insert objContract;
                
                objContract.status='Approved';
                update objContract;        
                
                //This for Opportunity Thumbnail
                ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
                conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
                conVerRec.Content_Type__c = 'Signed Contract';
                conVerRec.Title = 'Signed_Contract.jpeg';
                conVerRec.ECM_Customer_Signed_Date__c = Date.today();
                insert conVerRec;
                System.assert(conVerRec.Id != null, 'Contentversion should match');
                
                List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where ContentDocument.LatestPublishedVersion.RecordTypeId!=:recordIdContentVersion];
                System.assertEquals(documents.size(), 1,'ContentDocument should match');
                
                adminDocuments = documents.clone();
                
                ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objContract.Id,adminDocuments[0].Id);
                insert conDocLnkRec;
                //System.assert(conDocLnkRec.Id != null,'ContentLink should match');
                
            }              
            
            delete adminDocuments;
            
            Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
            ContentVersion cVersion1 = new ContentVersion();
            if(String.isNotEmpty(recordIdContentVersion)){
                cVersion1.RecordTypeId = recordIdContentVersion;
            }
            cVersion1.Content_Type__c = 'Terms and Conditions';
            cVersion1.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion1.PathOnClient = 'Test.pdf';//File name with extention
            cVersion1.Title = 'Test';//Name of the file
            cVersion1.VersionData = Blob.valueOf('Unit Test');//File content
            Insert cVersion1;
            
            System.assert(cVersion1.Id != null,'ContentVerion should match');
            
            Market_Setting__c marketRecord = [Select Id from Market_Setting__c LIMIT 1];
            
            //System.assert(marketRecord.Id != null);
            
            //After saved the Content Verison, get the ContentDocumentId
            Id conDocument1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion1.Id].ContentDocumentId;
            ContentDocumentLink cDocLink1 = new ContentDocumentLink();
            cDocLink1.ContentDocumentId = conDocument1;//Add ContentDocumentId
            cDocLink1.LinkedEntityId = marketRecord.Id;//Add attachment parentId
            cDocLink1.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDocLink1.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
            
            try{
                Insert cDocLink1;
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Handled Exception for insertion of more than one pdf on market setting record');
            }
            
            
            Test.stopTest();
        }
    }

    /**
Method  : onAddingAssetPDFTest
Purpose : This is used to cover onAddingContractAttachment method
**/
    
    @isTest
    public static void onAddingAssetPDFTest() {
        //change made by Wribhu ECM-6107
        User adminUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
        insert adminUser;
        System.runAs(adminUser){
            List<ContentDocument> adminDocuments = new List<ContentDocument>();
            Profile prof = [SELECT Id, Name FROM Profile WHERE Name =: 'Sales Representative'];
            User user1 = new User();
            user1.firstName = 'test1';
            user1.lastName = 'test2';
            user1.profileId = prof.id;        
            user1.email = 'test@test.com';
            user1.Username ='testcm123@test.com';
            user1.Alias='test';
            user1.Timezonesidkey='America/Los_Angeles';
            user1.LocaleSidKey='en_US';
            user1.LanguageLocaleKey='en_US';
            user1.EmailEncodingKey='UTF-8';
            user1.Available_Countries__c='ES';
            user1.Title='Legal';
            insert user1;
            CM_Attachment_Permission__mdt cmPermss = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName,
                                                      Country_Code__c, File_Type__c, Content_Type__c, Permission__c, Profile_Name__c FROM CM_Attachment_Permission__mdt 
                                                      where Profile_Name__c=:prof.Name AND Country_Code__c=:user1.Available_Countries__c LIMIT 1];
            cmPermss.Content_Type__c = 'Asset PDF';
            cmPermss.File_Type__c='Contracts';
            cmPermss.Object__c='Contract';
            cmPermss.Profile_Name__c = 'Sales Representative';
            
            
            System.runAs(user1){
                
                Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
                EDGE_UtilityTestClass.createOrgSettings();
                
                Pick_Up_Options__c objPickUp = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
                objPickUp.Name = 'Gold[AUT]';
                insert objPickUp;
                
                Account outltAccnt = EDGE_UtilityTestClass.getOutletRecord();
                outltAccnt.Outlet_Visit_Prioritisation_Grade__c = objPickUp.Id;
                outltAccnt.VAT_Number__c='6789';
                outltAccnt.New_VAT__c='56789';
                outltAccnt.SAP_Ship_to__c='AGS';
                outltAccnt.SAP_Sold_to__c='THH';
                outltAccnt.Sales_Org__c='0923';
                outltAccnt.Email_for_contracts_payments__c='test@test.com';
                outltAccnt.ECM_Legal_Name__c='Test';
                outltAccnt.Person_Responsible__c=user1.Id;
                insert outltAccnt;
                
                Market_Setting__c mrktStng = EDGE_UtilityTestClass.getMarketSetting(geographyId);
                mrktStng.ECM_Contract_Management_Market__c=true;
                mrktStng.ECM_SAP_Order_Type__c='IPAS';
                mrktStng.ECM_Payment_Management_Email__c='Test@yupmail.com';
                mrktStng.ECM_Email_to_Send_Payment_CSV__c='Tes1t@yupmail.com';
                mrktStng.ECM_Contract_Creation_Page__c='Australia';
                mrktStng.Threshold_Format__c ='Percent';
                mrktStng.ECM_Mandatory_field_for_Contract__c='SAP Sold to;VAT number;Legal Name;SAP Ship to;Customer email for Contract;Sales org;Tax Identification number';
                insert mrktStng;
                
                //Added part of ECM-4924
                Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
                ContentVersion cVersion = new ContentVersion();
                if(String.isNotEmpty(recordIdContentVersion)){
                    cVersion.RecordTypeId = recordIdContentVersion;
                }
                cVersion.Content_Type__c = 'Terms and Conditions';
                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersion.PathOnClient = 'Test.pdf';//File name with extention
                cVersion.Title = 'Test';//Name of the file
                cVersion.VersionData = Blob.valueOf('Unit Test');//File content
                Insert cVersion;
                
                System.assert(cVersion.Id !=null,'ContentVerion should match');
                
                //After saved the Content Verison, get the ContentDocumentId
                Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                cDocLink.LinkedEntityId = mrktStng.Id;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                Insert cDocLink;
                
                System.assert(cDocLink.Id !=null,'ContentDocumentLink should match');
                
                
                ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
                contractType.Name='Promotional';
                contractType.Geography__c=geographyId;
                contractType.ECM_Abbreviation__c='POM';
                contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
                contractType.Volume_UoM_for_Spirits__c='CAS';
                contractType.ECM_Mandatory_Fields_Check__c='After Customer Signed';
                contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment;Rate Per UoM;UoM;';
                contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
                contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
                //contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
                insert contractType;
                
                String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
                
                Pick_Up_Options__c banner= new Pick_Up_Options__c();
                banner.Name='Range[ES]';
                banner.Geography__c=geographyId;
                banner.RecordTypeId=bannerRecordTypeId;
                // insert banner;            
                Test.startTest();
                String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Asset Contract').getRecordTypeId();
                Contract objContract = EDGE_UtilityTestClass.getContract(outltAccnt.Id, contractRecordTypeId);
                objContract.Status = 'Draft';
                objContract.Contract_End_Date__c = System.today()+29;
                objContract.AccountId=outltAccnt.Id;
                // objContract.ECM_Territory__c=testterritory.Id;
                objContract.ECM_Overall_Investment_Amount__c=100020.55;
                objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
                objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
                objContract.ECM_Overall_Investment_Figure__c=122.43;
                objContract.ECM_Agreement_Type__c=contractType.Id;
                //  objContract.ECM_Agreement_Type__c=contractType.Id;
                objContract.recordTypeId=contractRecordTypeId;
                objContract.ECM_Channel__c='On-Premise';
                // objContract.ECM_Banner__c=banner.Id;
                objContract.StartDate = system.today();
                objContract.Contract_End_Date__c = system.today()+360;
                objContract.ECM_Type_of_Contract__c = 'Group';
                objContract.ECM_Digitally_Signed__c = 'OTP Used';
                insert objContract;
                
                objContract.status='Approved';
                update objContract;        
                                
                //This for Opportunity Thumbnail
                ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Outle12345.jpeg');
                conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
                conVerRec.Content_Type__c = 'Asset PDF';
                conVerRec.Title = 'Asset_PDF.jpeg';
                
                insert conVerRec;
                System.assert(conVerRec.Id != null,'Contentversion should match');           
                
                List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where ContentDocument.LatestPublishedVersion.RecordTypeId!=:recordIdContentVersion];
                System.assertEquals(documents.size(), 1,'ContentDocument should match');
                
                adminDocuments = documents.clone();
                
                ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (objContract.Id,adminDocuments[0].Id);
                insert conDocLnkRec;
                System.assert(conDocLnkRec.Id != null,'ContentDocumentLink should match');
            }
            
            delete adminDocuments; 
            
            Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
            ContentVersion cVersion1 = new ContentVersion();
            if(String.isNotEmpty(recordIdContentVersion)){
                cVersion1.RecordTypeId = recordIdContentVersion;
            }
            cVersion1.Content_Type__c = 'Terms and Conditions';
            cVersion1.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion1.PathOnClient = 'Test.pdf';//File name with extention
            cVersion1.Title = 'Test';//Name of the file
            cVersion1.VersionData = Blob.valueOf('Unit Test');//File content
            Insert cVersion1;
            
            System.assert(cVersion1.Id != null,'Version should not be null');
            
            Market_Setting__c marketRecord = [Select Id from Market_Setting__c LIMIT 1];
            
            //System.assert(marketRecord.Id != null);
            
            //After saved the Content Verison, get the ContentDocumentId
            Id conDocument1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion1.Id].ContentDocumentId;
            ContentDocumentLink cDocLink1 = new ContentDocumentLink();
            cDocLink1.ContentDocumentId = conDocument1;//Add ContentDocumentId
            cDocLink1.LinkedEntityId = marketRecord.Id;//Add attachment parentId
            cDocLink1.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDocLink1.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
            
            try{
                Insert cDocLink1;
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Handled Exception for insertion of more than one pdf on market setting record');   
            }
            Test.stopTest();
        }
    }

    @isTest
    public static void testFileSetting(){
        
        Profile prof = [SELECT Id, Name FROM Profile WHERE Name =: 'Sales Representative'];
            User user1 = new User();
            user1.firstName = 'test1';
            user1.lastName = 'test2';
            user1.profileId = prof.id;        
            user1.email = 'test@test.com';
            user1.Username ='testcm123@test.com';
            user1.Alias='test';
            user1.Timezonesidkey='America/Los_Angeles';
            user1.LocaleSidKey='en_US';
            user1.LanguageLocaleKey='en_US';
            user1.EmailEncodingKey='UTF-8';
            user1.Available_Countries__c='AU';
            user1.Title='Legal';
            insert user1;
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment2');
        pickupOption.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        pickupOption.Name = 'Segment[AU]';
        insert pickupOption;
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Gold[AU]';
        insert pickupOption1;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption1.Id;
        outlet.Independent_of_Operator__c = true ;
        outlet.Independent_of_Owner__c = true;
        insert outlet;

        System.assert(outlet.id != null,'outlet should not be null');
        
        String deliveryPartnerRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = deliveryPartnerRecordTypeId;
        insert deliveryPartner;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        String activationRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Activation').getRecordTypeId();
        Bespoke__c objBespoke1 = new Bespoke__c();
        objBespoke1.Account__c = outlet.id;
        objBespoke1.RecordTypeId = activationRecordTypeId;
        objBespoke1.Activity_Objectives__c = pickupOption.id;
        objBespoke1.Contract__c = objContract.Id;
        objBespoke1.Country__c = countryId;
        objBespoke1.Sales_Rep__c = user1.id;
        objBespoke1.Start_Date__c = System.today();
        objBespoke1.Project_Name__c = 'Test';
        objBespoke1.Delivery_Partner__c = deliveryPartner.id;
        objBespoke1.End_Date__c = System.today().addDays(10);
        Test.startTest();
        Insert objBespoke1;

        
        ContentVersion conVerRecPDF1 = EDGE_UtilityTestClass.gerConVerRec('Product12345.JPEG');
        conVerRecPDF1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Bespoke').getRecordTypeId();
        conVerRecPDF1.Content_Type__c = 'Bespoke';
        conVerRecPDF1.Title = 'OutletRes.pdf';
        insert conVerRecPDF1;
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :conVerRecPDF1.Id];
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = objBespoke1.id;
        contentlink.ShareType = 'V';
        contentlink.ContentDocumentId = testcontent.ContentDocumentId;
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        Test.stopTest();
    }
    
}