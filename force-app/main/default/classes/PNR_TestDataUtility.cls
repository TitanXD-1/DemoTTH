/**********************************************************************
Name: PNR_TestDataUtility
=======================================================================
Req: This is generic class to create sample records. This class will 
be used in all test classes for Pioneer.
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned kHan            13/06/2019      Initial Development
2.0   Saurav Paul           12/08/2019      getInvLineItm,getDirectCorrDoc,getDirectDisputesCase
2.1   Saurav Paul           12/08/2019      getDirOrder,getDirInvoice
************************************************************************/
@IsTest
public without sharing class PNR_TestDataUtility {
    
    // Get Account Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        public static Map <String,Schema.RecordTypeInfo> mapOrderRecordTypes = order__c.sObjectType.getDescribe().getRecordTypeInfosByName();

    // Get the record type id of from the Map based on the Name
    public static Id outletRecTypeId = mapAccountRecordTypes.get('Outlet').getRecordTypeId();
    public static Id prospectRecTypeId = mapAccountRecordTypes.get('Prospect').getRecordTypeId();
    public static Id ownerRecTypeId = mapAccountRecordTypes.get('Owner/Operator').getRecordTypeId();    
    public static Id custRecTypeId = mapAccountRecordTypes.get('Direct Customer').getRecordTypeId();
    public static Id directorderRecTypeId = mapOrderRecordTypes.get('Direct Order').getRecordTypeId(); 

    public static Map<String,Id> geoMap = new Map<String,Id>();
    
    //creates a new user by passing the profile name
    public static User runAsUser(String uniqueKey, String sProfileName) {
        User newUser = new User();      
        if(uniqueKey.length() > 8){
            newUser.Alias = uniqueKey.substring(0,4);
        }
        else {
            newUser.Alias = uniqueKey;
        }
        newUser.Email = uniqueKey + '@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test' + uniqueKey;
        newUser.FirstName = uniqueKey;
        newUser.LanguageLocaleKey  = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = [select Id from Profile where Name =: sProfileName limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = uniqueKey + '@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'AU';
        return newUser; 
    }
    
    public static void createOrgSettings(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        insert orgSetting;
    }    
    //create Geography Object
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography; 
    }
    
    //Setup Global Geography Hierarchy
    public static Geography__c setupGlobalHierarchy(){
        Geography__c globalRec = createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GBL';
        insert globalRec;
        return globalRec;
    } 
    
    //Setup Geography Hierarchy
    public static Id setupCountry(string countryCode){
        
        Geography__c globalRec = createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GBL';
        insert globalRec;
        geoMap.put('Global',globalRec.Id);
        
        Geography__c market = createGeography('Market');
        market.Name = 'APAC';
        market.Code__c = 'APC';
        market.Parent_Geography__c = globalRec.Id;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = createGeography('Hub');
        hub.Name = 'South Australia';
        hub.Code__c = 'SAU';
        hub.Parent_Geography__c = market.Id;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        Geography__c cluster = createGeography('Cluster');
        cluster.Name = 'Australia';
        cluster.Code__c = 'AU';
        cluster.Parent_Geography__c = hub.Id;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = createGeography('Country');
        country.Name = 'Australia';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.Extended_Country_Code__c = 'AU-AUS';
        insert country;
        geoMap.put('Country',country.Id);
        
        
        return country.Id;
    }
    
    //create account with record type Direct Customer    
    public static Account getDirectCustomerRec(){
        Account distAccount = new Account();
        //distAccount.Name = '10483';
        //distAccount.PNR_Customer_Name__c='Test Customer Account';
        distAccount.Name = 'Test Customer Account';
        distAccount.AccountNumber = '10483';
        distAccount.Country__c = geoMap.get('Country');
        distAccount.Hub__c = geoMap.get('Hub');
        distAccount.Market__c = geoMap.get('Market');
        distAccount.Cluster__c= geoMap.get('Cluster');
        distAccount.RecordTypeId =  custRecTypeId;
        distAccount.Outlet_Email_Address__c = 'test@test.com';
        distAccount.BillingCountry = 'Australia';
        return distAccount; 
    }
    
    //Create ContentDocumentLink Record
    public static ContentDocumentLink  getConDocLink (Id entityId, Id docId){
        ContentDocumentLink  conDocLnkObj = new ContentDocumentLink ();
        conDocLnkObj.LinkedEntityId = entityId;
        conDocLnkObj.ContentDocumentId = docId;
        conDocLnkObj.shareType = 'V';
        return conDocLnkObj; 
    }
    
    //Diageo Contact creation
    public static PNR_Diageo_Contact__c getPNRDiageoContactData(){
        PNR_Diageo_Contact__c con = new PNR_Diageo_Contact__c();
        con.PNR_Customer__c =getDirectCustomerRec().Id;  
        return con;
    } 
    //Customer Contact creation
    public static Contact getCustomerContactData(){
        Contact con = new Contact();
        con.FirstName = 'Customer';
        con.LastName='Customer';
        con.PNR_Contact_Type__c='Order Contact';
        con.AccountId =getDirectCustomerRec().Id;
        con.Email='test@diageo.com';
        con.MobilePhone='1234567890';
        return con;
    }
    
    // Diageo PF payer creation
    public static  PNR_Partner_Function__c getPNRPartnerFunctionData(){ 
        List<PNR_Partner_Function__c> pflist=new List<PNR_Partner_Function__c>();
        PNR_Partner_Function__c pfrec=new PNR_Partner_Function__c();
        pfrec.PNR_Customer_No__c=getDirectCustomerRec().Id;
        pfrec.PNR_Sales_Org__c= 'SE01';
        pfrec.PNR_Sold_To__c=getDirectCustomerRec().Id;
        pfrec.PNR_Type__c='Payer';
        pfrec.PNR_Deletion_Flag_for_Sales_Level__c = FALSE;
        return pfrec;
        
    }
    //Daigeo contract creation
    public static Contract getContractData(){
        Contract contrc =new Contract();
        contrc.Accountid=getDirectCustomerRec().Id;
        contrc.Status='Draft';
        contrc.ContractTerm=2;
        contrc.StartDate=system.today();
        return contrc;
        
    }
    // Diageo Order__c creation.
    public static Order__c getNewOrderData(){
        Order__c ord = new Order__c();
        ord.Account__c=getDirectCustomerRec().Id;
        //ord.EffectiveDate=System.today();
        //ord.Status='Open';
        ord.PO_Number__c='EWCCDP1513';
        ord.Sales_Org__c='SE01';
        ord.SAP_Order_Number__c='1100002';
        ord.Delivery_Document__c = '123412';
        ord.RecordTypeId=directorderRecTypeId;
        return ord;
    }
    
    // Diageo Invoice creation
    public static Invoice__c getPNRInvoiceData(){
        Invoice__c inv = new Invoice__c();
        inv.Order__c = getNewOrderData().Id;
        inv.Payer_Number__c = getDirectCustomerRec().Id;
        inv.Document_Type__c='YCR';
        inv.Sales_Org__c='GB01';
        inv.Account__c = getDirectCustomerRec().Id;
        inv.SAP_Invoice_Number__c = '98765432';
        inv.Due_Type__c = 'Open';
        inv.Batch_Import__c = true;
        return inv; 
    }
    // Diageo Case creation
    public static Case getCaseData(){
        Case caserec=new Case();
        caserec.Status='New';
        caserec.Priority='Low';
        caserec.Type='Dispute – Pricing';
        // caserec.CurrencyIsoCode='GBP - British Pound';
        caserec.Origin='Email';
        return caserec; 
        
    }
    
    // Correction Document creation
    public static Correction_Document__c getCorrectionDocData(){
        Correction_Document__c crdoc=new Correction_Document__c();
        crdoc.Bill_To__c='10114';
        crdoc.Billing_notes_for_printing__c='Billing notes';
        crdoc.Case__c = getCaseData().Id;
        crdoc.Reference_invoice__c=getPNRInvoiceData().Id;
        crdoc.Sold_To__c=getDirectCustomerRec().Id;
        crdoc.Payer__c=getDirectCustomerRec().Id;
        return crdoc;
    }
    //Create Invoice Line Item
    public static Invoice_Line_Item__c getInvLineItm(Id invceId){
        Invoice_Line_Item__c invItemObj = new Invoice_Line_Item__c();
        invItemObj.Invoice__c = invceId;
        invItemObj.Product_Number__c = 'Test01';
        invItemObj.SAP_Line_Item_Number__c = 'Test01';
        return invItemObj;
    } 
    //Create Direct Disputes Case
    public static case getDirectDisputesCase(Id accId){
        Case caseObj = new Case();
        Id recTypId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        caseObj.AccountId = accId;
        caseObj.Type = 'Dispute – Delivery';
        caseObj.RecordTypeId = recTypId;
        caseObj.Status = 'New';
        caseObj.Origin = 'Email';
        caseObj.Subject = 'Test Case Subject';
        caseObj.Priority = '1-Low';
        caseObj.Description = 'Test Case Description';
        caseObj.Claimed_Amount__c = 250;
        caseObj.Dispute_Breakdown__c = 'Damaged Goods';
        caseObj.Dispute_Sub_type__c = 'Damages Haulier/Carrier';
        return caseObj;
    }
    //Create Direct Correction Document 
    public static Correction_Document__c getDirectCorrDoc(Id caseId, Id refInvId, Id soldToId, Id payerId){
        Id recTypId  = Schema.SObjectType.Correction_Document__c.getRecordTypeInfosByName().get('Direct Correction Document').getRecordTypeId();
        Correction_Document__c corrDocObj = new Correction_Document__c();
        corrDocObj.RecordTypeId = recTypId;
        corrDocObj.Bill_To__c = '0987654';
        corrDocObj.Billing_notes_for_printing__c = 'Billing notes';
        corrDocObj.Case__c = caseId;
        corrDocObj.Reference_invoice__c = refInvId;
        corrDocObj.Sold_To__c = soldToId;
        corrDocObj.Payer__c = payerId;
        corrDocObj.Document_Type__c = 'YVCR';
        corrDocObj.Reason_Code__c = 'YTR-Test Saurav';
        return corrDocObj;
    }
    
    //Create Approval MAtrix data
    public static Approver_Matrix__c getApproverMatrix(){
        Approver_Matrix__c appMat = new Approver_Matrix__c();
        appMat.Approver_Email__c = 'tanmoy.bardhan@diageo.com';
        appMat.Sales_Org__c = 'GB01';
        appMat.Min_Limit_Amount__c = 101.00;
        appMat.Max_Limit__c = 200.00;
        appMat.Matrix_Status__c = 'Enabled';
        appMat.Approval_Category__c = 'Credit/Debit approval';
        appMat.CurrencyIsoCode = 'GBP';
        return appMat;
    }
    //Create Direct Order
    public static Order__c getDirOrder(Id accId){
        Id dirOrdRecId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Direct Order').getRecordTypeId();
        Order__c odrObj = new Order__c();
        odrObj.RecordTypeId = dirOrdRecId;
        odrObj.Account__c = accId;
        odrObj.PO_Number__c = 'SAURAV1209';
        odrObj.Sales_Org__c = 'SE01';
        odrObj.SAP_Order_Number__c = '8348946084';
        odrObj.Delivery_Document__c = '123412';
        return odrObj;
    } 
    //Create Direct Invoice 
    public static Invoice__c getDirInvoice(){
        Id dirInvRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Direct Invoice').getRecordTypeId();
        Invoice__c invObj = new Invoice__c();
        invObj.RecordTypeId = dirInvRecId;
        invObj.Document_Type__c='YCR';
        invObj.Sales_Org__c='GB01';
        invObj.SAP_Invoice_Number__c = '98765432';
        invObj.Due_Type__c = 'Open';
        return invObj; 
    }
    //Create Product
    public static Product__c getProduct(){
        Product__c prod = new Product__c();
        prod.Name = '10086';
        prod.Description__c = 'KILKENNY DRAUGH 50L   KEG';
        return prod;
    }
    //Create CorrectionDocumentMapping
    public static PNR_CorrectionDocumentMapping__c getCorrDocMap(Id invceId,Id invItemId,Id corrDocId){
        PNR_CorrectionDocumentMapping__c corrDocMap = new PNR_CorrectionDocumentMapping__c();
        corrDocMap.Claimed_Net_Amount__c = 400;
        corrDocMap.Invoice_Net_Price_Item__c  = 9874;
        corrDocMap.Invoice_Net_Price_Unit__c  = 965;
        corrDocMap.Invoice_Quantity__c = 256;
        corrDocMap.Invoice_Unit_of_Measure__c = 'CAS';
        corrDocMap.Plant__c = 'Test';
        corrDocMap.Product_Description__c = 'Test Description';
        corrDocMap.Correction_Document__c = corrDocId;
        corrDocMap.Invoice__c = invceId;
        corrDocMap.Invoice_Line_Item__c = invItemId;
        return corrDocMap;
    }
}