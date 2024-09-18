/**
 * US : ES20-7089
 * @name : EDGE_PartnerFunctionTriggerHelper
 * @description : Trigger Helper Class for Partner Function.
 * @history
 * VERSION      AUTHOR          DATE                                DETAIL
 * 1.0       Sagar Barman      18/02/2020          ES20-7089/ES20-7413 method - updateShipToAccounts, ES20-7086
 * 2.0       Sai Kumar         12/11/2020          NCP-348
 * 3.0       Saurav Paul       15/01/2021          NCP-1535,NCP-1551
 * 4.0       Saurav Paul       05/03/2021          NCP-2278
 * 5.0       Praveen           21/04/2021          NCP-3024(updateAccountsDirectCustomerFlag)
 * 6.0       Rubeena           6/05/2021           NCP-3006(update SoldTo Accounts)
 * 7.0       Rithika           26/07/2021          NCP-3827(sending notification when a new shipTo is added)
 * 8.0       Rubeena           13/09/2021          NCP-4051(Handle Proposal Modification scenario for existing customer)
 * 9.0       Kapil Baliyan     16/02/2022          NCP-6230(
 
 )
 * 10.0      Kapil Baliyan     26/05/2022          NCP-6766
 * 11.0      Divya Kolhatkar   22/06/2022          NCP-6942(CreateContactPointAddress)
 * 12.0      Gaurav Singh      20/07/2011          NCP-7032
 * 13.0      Pratap Sen        10/01/2022          NCP-7766
 * 14.0      Kapil Baliyan     16/01/2022          NCP-7878
 * 15.0      Kapil Baliyan     09/03/2023          NCP-7934
 * 16.0      Rajesh kumar      07/04/2023          NCP-8036
 * 17.0      Rajesh Kumar       19/04/2023         NCP-8034
 * 18.0      Swagat Shaw        02/06/2023         CUS- 158
 * 19.0      Kapil Baliyan      08/08/2023         144191 
 */
public with sharing class EDGE_PartnerFunctionTriggerHelper {
    public static final String PNR_TYPE_SOLD_TO = 'Sold-To';
    public static final String PNR_TYPE_SHIP_TO = 'Ship-To';
    
    //Method to update Ship To & Geography Details
    public static void updateShipToAccounts(Map < Id, SObject > newItems, Map < Id, SObject > oldItems) {
        Map < Id, PNR_Partner_Function__c > partnerFunctionMap;
        Map < Id, Id > partnerFunctionWithAcc = new Map < Id, Id > ();
        Map < Id, String > partnerFunctionWithType = new Map < Id, String > (); //NCP-3006
        Map < String, String > salesOrgCountryCodeMdtMap = new Map < String, String > ();
        Map < String, Geography__c > geoCodeToGeoMap = new Map < String, Geography__c > ();
        Set < String > countryCodeSet = new Set < String > ();
        Set < Id > accountIdset = new Set < Id > ();
        Map < Id, Account > accountMapToUpdate = new Map < Id, Account > ();
        List < String > salesorgLabelValue = new List < String > ();
        List < String > custAccCountryCodeValue = new List < String > ();
        String salesOrgCustomLabel = System.Label.EDGE_SALES_ORG_ID;
        String custmrAccCountryCode = System.Label.EDGE_Customer_Account_Country_Code;
        if (newItems != Null) {
            //type casting newItems with PNR_Partner_Function__c
            partnerFunctionMap = (Map < Id, PNR_Partner_Function__c > ) newItems;
            //spliting the values of custom label (Sales_Org_Id)
            salesorgLabelValue = salesOrgCustomLabel.split(';');
            //populating the map of Partner Function Id with is associated parent Account Id
            for (PNR_Partner_Function__c partnerFunc: partnerFunctionMap.values()) {
                //getting the values of custom label Sale_Org_Id = 'IN01, IS01'
                for (String salesOrgVal: salesorgLabelValue) { //NCP-3006 - included a sold to check
                    if (((partnerFunc.PNR_Type__c == 'Ship-To' && partnerFunc.PNR_Sold_To__c == partnerFunc.PNR_Customer_No__c) || partnerFunc.PNR_Type__c == 'Sold-To') && partnerFunc.PNR_Sales_Org__c == salesOrgVal.trim()) {
                        partnerFunctionWithAcc.put(partnerFunc.Id, partnerFunc.PNR_Customer_No__c);
                        partnerFunctionWithType.put(partnerFunc.Id, partnerFunc.PNR_Type__c); //NCP-3006
                        accountIdset.add(partnerFunc.PNR_Customer_No__c);
                    }
                }
            }
        }
        //querying the account records 
        if (accountIdset.size() > 0 && Schema.SObjectType.Account.isAccessible()) {
            accountMapToUpdate = new Map < Id, Account > ([SELECT Id, Sales_Org__c, Customer_Type__c, Hub__c, Cluster__c, Country__c,
                SAP_Sold_to__c, AccountNumber, Account_Type__c, KUNNR__c FROM Account WHERE Id IN: accountIdset
            ]);
        }
        //splitting the custom label values EDGE_Customer_Account_Country_Code = (NIR, IE)
        custAccCountryCodeValue = custmrAccCountryCode.split(';');
        //Triming the CustAccCountryCodeValue and adding in the set
        for (String str: custAccCountryCodeValue) {
            countryCodeset.add(str.trim());
        }
        //The accounts which has IN01 as Sales Org their Country should be NIR(Northern Ireland) US ES20-7086
        for (Geography__c geoNIRCountryRec: [SELECT Id, Name, Code__c, RecordType.Name, Parent_Geography__c, Parent_Geography__r.Parent_Geography__c
                FROM Geography__c WHERE Code__c IN: countryCodeset
            ]) {
            geoCodeToGeoMap.put(geoNIRCountryRec.Code__c, geoNIRCountryRec);
        }
        //querying the EDGE_Direct_Customer_Sales_Org_Setting__mdt and putting the value in the salesOrgCountryCodeMdtMap
        for (EDGE_Direct_Customer_Sales_Org_Setting__mdt salesOrgCountryCode: [SELECT id, Sales_Org__c, Country_Code__c
                From EDGE_Direct_Customer_Sales_Org_Setting__mdt
            ]) {
            salesOrgCountryCodeMdtMap.put(salesOrgCountryCode.Sales_Org__c, salesOrgCountryCode.Country_Code__c);
        }
        //assign the partner function PNR_Type__c and PNR_Sales_Org__c to parent account
        if (accountMapToUpdate.size() > 0 && null != geoCodeToGeoMap) {
            for (Id pfId: partnerFunctionWithAcc.keySet()) {
                for (Account acc: accountMapToUpdate.values()) {
                    if (acc.Id == partnerFunctionWithAcc.get(pfId)) {
                        if (partnerFunctionMap.get(pfId) != null) {
                            String key = partnerFunctionMap.get(pfId).PNR_Sales_Org__c;
                            if (partnerFunctionWithType.get(pfId) == 'Ship-To') {
                                acc.Customer_Type__c = partnerFunctionMap.get(pfId).PNR_Type__c;
                                acc.Sales_Org__c = partnerFunctionMap.get(pfId).PNR_Sales_Org__c;
                                acc.SAP_Ship_to__c = acc.AccountNumber;
                            }
                            if (partnerFunctionWithType.get(pfId) == 'Sold-To') { //NCP-3006 updating only sales org for sold to accounts
                                acc.Sales_Org__c = partnerFunctionMap.get(pfId).PNR_Sales_Org__c;
                            }
                            if (!salesOrgCountryCodeMdtMap.IsEmpty() && salesOrgCountryCodeMdtMap.containsKey(key) && salesOrgCountryCodeMdtMap.get(key) != null) {
                                acc.Hub__c = geoCodeToGeoMap.get(salesOrgCountryCodeMdtMap.get(key)).Parent_Geography__r.Parent_Geography__c;
                                acc.Cluster__c = geoCodeToGeoMap.get(salesOrgCountryCodeMdtMap.get(key)).Parent_Geography__c;
                                acc.Country__c = geoCodeToGeoMap.get(salesOrgCountryCodeMdtMap.get(key)).Id;
                            }
                        }
                    }
                }
            }
        }
        //update the list
        if (null != accountMapToUpdate && !accountMapToUpdate.IsEmpty() && Schema.SObjectType.Account.isUpdateable()) {
            Database.update(accountMapToUpdate.values(), false);
        }
    }
    
    /**
     * @description : Manual Conversion of Direct Customer to Outlet by MDM (NCP-348)
     */
    
    //Commented because this is no more relevant (143347)
  /*  public static void d1CheckDirectAccount(Map < Id, SObject > newItems, Map < Id, SObject > oldItems) {
        //Variables
        Map < Id, PNR_Partner_Function__c > partnerFunctionMap;
        Map < Id, Id > partnerFunctionWithAcc = new Map < Id, Id > ();
        Map < Id, Account > directAccountMap = new Map < Id, Account > ();
        Map < id, Market_Setting__c > geographyids = new Map < id, Market_Setting__c > ();
        Map < id, string > map_Geographyid_gropname = new Map < id, string > ();
        Set < Id > accountIdset = new Set < Id > ();
        Set < Account > duplicate_Found_Records = new Set < Account > ();
        List < Account > masterAccList = new List < Account > (); //This variable is used to update Master Account record
        List < Merged_Account__c > mergeAccList = new List < Merged_Account__c > (); //This is used to create Merge Account
        Map < Account, Account > mergeAccMap = new Map < Account, Account > ();
        List < Id > mergAccIdList = new List < Id > ();
        Id directCustomerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        Id outletAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //Variables
        if (newItems != Null) {
            //type casting newItems with PNR_Partner_Function__c
            partnerFunctionMap = (Map < Id, PNR_Partner_Function__c > ) newItems;
        }
        for (Market_Setting__c Market_Setting: [select id, Geography__c, Account_Type_Priority__c, Geography__r.MDM_Queue__c, Enable_Account_Merging__c
                from Market_Setting__c where Account_Type_Priority__c = 'Sold-To'
                or Account_Type_Priority__c = 'Ship-To'
            ]) {
            geographyids.put(Market_Setting.Geography__c, Market_Setting);
            map_Geographyid_gropname.put(Market_Setting.Geography__c, Market_Setting.Geography__r.MDM_Queue__c);
        }
        if (geographyids.size() > 0 && partnerFunctionMap.size() > 0) {
            for (PNR_Partner_Function__c partnerFunc: partnerFunctionMap.values()) {
                if ((partnerFunc.PNR_Type__c == 'Ship-To' || partnerFunc.PNR_Type__c == 'Sold-To') && partnerFunc.PNR_Customer_No__c != null) {
                    partnerFunctionWithAcc.put(partnerFunc.Id, partnerFunc.PNR_Customer_No__c);
                }
            }
            if (partnerFunctionWithAcc.size() > 0) {
                for (PNR_Partner_Function__c PNR_Partner_Function: [select id, PNR_Customer_No__c, PNR_Customer_No__r.Country__c, PNR_Type__c
                        from PNR_Partner_Function__c
                        where Id in : partnerFunctionWithAcc.keyset()
                        AND PNR_Customer_No__r.D1_EDGE_Customer__c = True
                        AND PNR_Customer_No__r.RecordTypeId = : directCustomerAccountRecordTypeId
                    ]) {
                    if (geographyids != null && geographyids.containskey(PNR_Partner_Function.PNR_Customer_No__r.Country__c) && PNR_Partner_Function.PNR_Type__c == geographyids.get(PNR_Partner_Function.PNR_Customer_No__r.Country__c).Account_Type_Priority__c) {
                        accountIdset.add(PNR_Partner_Function.PNR_Customer_No__c);
                    }
                }
            }

            if (accountIdset.size() > 0) {
                directAccountMap = new Map < Id, Account > ([SELECT Id, Name, Sales_Org__c, D1_Email_Send_Outlet_Customer__c, Customer_Type__c,
                    Hub__c, Cluster__c, Country__c, AccountNumber, BillingStreet, BillingCity,
                    BillingPostalCode, BillingCountry, Transportation_Zone__c, Central_Order_Block__c,
                    Central_Delivery_Block__c, Central_Billing_Block__c, Deletion_Flag_from_SAP__c,
                    Sort__c, KUNNR__c, Customer_Account_Group__c, PO_Box__c, new_VAT__c, Delivery_Pattern__c,
                    District__c, D1_EDGE_Customer__c, Salesforce_Delivery_Days_Beer__c,
                    Salesforce_Delivery_Days_Keg__c, Salesforce_Delivery_Days_Keg_Stout__c, Salesforce_Delivery_Days_Packaged_Good__c,
                    Language__c, Phone, General_Information__c, SAP_Payer_Bill_To__c, Notes__c,
                    IsOwner__c, Direct_Customer__c, Customer_Sales_Org_Status__c, Delivery_Plant__c, Market__c,
                    Products_Enabled__c, AccountSource, SAP_Ship_to__c, Account_Number_with_Credit_Limit_Ref__c,
                    Credit_Control_Area__c, BillingState, Country__r.Name, Pioneer_Enabled__c
                    FROM Account WHERE Id IN: accountIdset
                    and RecordTypeId = : directCustomerAccountRecordTypeId
                    and D1_Email_Send_Outlet_Customer__c = false
                ]);
            }
            //Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(directAccountMap.keyset());
            List < Account > LAccount = new List < Account > ();
            if (directAccountMap.size() > 0) {
                LAccount.addAll(directAccountMap.values());
            }
            Map < Id, Account > accountMapToMerge = new Map < Id, Account > ();
            Map < Account, Set < Id >> obj = getDuplicates5(LAccount);
            List < Id > AcIds = new List < Id > ();
            for (Account a: obj.keySet()) {
                AcIds.addAll(obj.get(a));
            }
            accountMapToMerge = new Map < Id, Account > ([SELECT Id, Name, Sales_Org__c, D1_Email_Send_Outlet_Customer__c, Customer_Type__c,
                Hub__c, Cluster__c, Country__c, AccountNumber, BillingStreet, BillingCity, Pioneer_Enabled__c,
                BillingPostalCode, BillingCountry, Transportation_Zone__c, Central_Order_Block__c,
                Central_Delivery_Block__c, Central_Billing_Block__c, Deletion_Flag_from_SAP__c,
                Sort__c, KUNNR__c, Customer_Account_Group__c, PO_Box__c, new_VAT__c, Delivery_Pattern__c,
                District__c, D1_EDGE_Customer__c, Salesforce_Delivery_Days_Beer__c,
                Salesforce_Delivery_Days_Keg__c, Salesforce_Delivery_Days_Keg_Stout__c, Salesforce_Delivery_Days_Packaged_Good__c,
                Language__c, Phone, General_Information__c, SAP_Payer_Bill_To__c, Notes__c,
                IsOwner__c, Direct_Customer__c, Customer_Sales_Org_Status__c, Delivery_Plant__c, Market__c,
                Products_Enabled__c, AccountSource, SAP_Ship_to__c, Account_Number_with_Credit_Limit_Ref__c,
                Credit_Control_Area__c, BillingState, BillingStateCode, BillingCountryCode, RecordTypeId
                FROM Account WHERE RecordTypeId = : OutletAccountRecordTypeId AND Id = : AcIds
            ]);
            for (Account a: obj.keySet()) {
                list < Account > alist = new list < Account > ();
                alist.add(a);
                if (obj.get(a) != null && obj.get(a).size() == 1) {
                    List < Id > tIds = new List < Id > ();
                    tIds.addAll(obj.get(a));
                    for (Id tId: tIds) {
                        //Added by Saurav
                        if (accountMapToMerge != null && accountMapToMerge.containsKey(tId)) {
                            Id marketId = accountMapToMerge.get(tId).Country__c;
                            if (geographyids != null && geographyids.containsKey(marketId) && geographyids.get(marketId).Enable_Account_Merging__c) {
                                Account mastrAccObj = copyMasterAcc(accountMapToMerge.get(tId), alist[0]);
                                masterAccList.add(mastrAccObj);
                                Merged_Account__c mergAccObj = createMergeAcc(accountMapToMerge.get(tId), alist[0]);
                                mergeAccList.add(mergAccObj);
                                mergeAccMap.put(accountMapToMerge.get(tId), alist[0]);
                                mergAccIdList.add(accountMapToMerge.get(tId).Id);
                            }
                        }
                        //Added by Saurav
                        duplicate_Found_Records.addAll(alist);
                    }
                } else if (obj.get(a) != null && obj.get(a).size() > 1) {
                    duplicate_Found_Records.addAll(alist);
                }
            }
            //Added by Saurav
            if (!masterAccList.isEmpty()) {
                Database.update(masterAccList, false);
            }
            if (!mergeAccList.isEmpty()) {
                insert mergeAccList;
            }
            if (mergeAccMap != null && !mergeAccMap.isEmpty()) {
                //update masterAccList;
                for (Account accObj: mergeAccMap.keySet()) {
                    Database.merge(accObj, mergeAccMap.get(accObj), false);
                }
            }
            if (!mergAccIdList.isEmpty()) {
                deleteRecordSet(mergAccIdList);
            }
            //Added by Saurav
            if (directAccountMap.size() > 0 && duplicate_Found_Records.size() > 0) {
                for (Account dup_accountrecord: duplicate_Found_Records) {
                    if (directAccountMap.containsKey(dup_accountrecord.Id)) {
                        directAccountMap.remove(dup_accountrecord.Id);
                    }
                }
            }
            if (directAccountMap.size() > 0) {
                D1_SendEmailtoMDM(map_Geographyid_gropname, directAccountMap.values());
            }
        }
    } */
    
    //new function - 19 nov
    public static Map < Account, Set < Id >> getDuplicates5(list < Account > duplicates) {
        Map < Account, Set < Id >> accountMap2 = new Map < Account, Set < Id >> ();
        for (Account a: duplicates) {
            list < Account > tempAcc = new list < Account > ();
            tempAcc.add(a);
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(tempAcc);
            for (Datacloud.FindDuplicatesResult findDupeResult: results) {
                for (Datacloud.DuplicateResult dupeResult: findDupeResult.getDuplicateResults()) {
                    string rule = dupeResult.getDuplicateRule();
                    if (rule == System.Label.D1_Account_Duplicate_Exclusion) {
                        for (Datacloud.MatchResult matchResult: dupeResult.getMatchResults()) {
                            List < Datacloud.MatchRecord > matchRecords = matchResult.getMatchRecords();
                            for (Datacloud.MatchRecord matchRecord: matchRecords) {
                                If(accountMap2.ContainsKey(a)) {
                                    accountMap2.get(a).add(matchRecord.getRecord().Id);
                                } else {
                                    accountMap2.put(a, new set < Id > {
                                        matchRecord.getRecord().Id
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
        return accountMap2;
    }
    
    //Method
    public static Database.MergeResult[] mergeAccounts(Account masterAcc, Set < Account > duplicates) {
        if (masterAcc == null && duplicates == null) {
            return null;
        }
        List < Account > lAcc = new List < Account > ();
        lAcc.addAll(duplicates);
        Database.MergeResult[] results = Database.merge(masterAcc, lAcc, false);
        for (Database.MergeResult res: results) {
            if (res.isSuccess()) {
                List < Id > mergedIds = res.getMergedRecordIds();
                System.debug(LoggingLevel.INFO, mergedIds);
            } else {
                for (Database.Error err: res.getErrors()) {
                    System.debug(LoggingLevel.ERROR, err.getMessage());
                }
            }
        }
        return results;
    }
    
    //Commented because this is no more relevant (143347)
 /*   public static void D1_SendEmailtoMDM(Map < id, string > map_Geographyid_gropname, List < Account > Non_Dupicate_records) {
        List < Account > Update_Accounts = new List < Account > ();
        String Email_template = 'D1 Manual Conversion of Direct Customer to Outlet by MDM';
        Messaging.SingleEmailMessage[] messages = new List < Messaging.SingleEmailMessage > ();
        Messaging.SingleEmailMessage MDM_Email_Template;
        Map < String, List < Id >> map_GeographyId_UserId = new Map < String, List < Id >> ();
        if (map_Geographyid_gropname.size() > 0) {
            for (GroupMember grpmember: [select userorgroupid, group.name from groupmember
                    where group.name in : map_Geographyid_gropname.values()
                ]) {
                if (map_GeographyId_UserId.containsKey(grpmember.group.name)) {
                    List < Id > usersEmail = map_GeographyId_UserId.get(grpmember.group.name);
                    usersEmail.add(grpmember.userorgroupid);
                    map_GeographyId_UserId.put(grpmember.group.name, usersEmail);
                } else {
                    map_GeographyId_UserId.put(grpmember.group.name, new List < Id > {
                        grpmember.userorgroupid
                    });
                }
            }
        }
        EmailTemplate email_Template_Body = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
            FROM EmailTemplate WHERE NAME = : Email_template
        ];
        if (Non_Dupicate_records.size() > 0 && map_GeographyId_UserId.size() > 0) {
            for (Account acc_record: Non_Dupicate_records) {
                acc_record.D1_Email_Send_Outlet_Customer__c = true;
                //EmailTemplate email_Body = email_Template_Body;
                String subject = Email_Template_body.Subject;
                String htmlBody = Email_Template_body.HtmlValue;
                htmlBody = htmlBody.replace('{!Account.Name}', acc_record.Name);
                if (acc_record.AccountNumber != null) {
                    htmlBody = htmlBody.replace('{!Account.AccountNumber}', acc_record.AccountNumber);
                } else {
                    htmlBody = htmlBody.replace('{!Account.AccountNumber}', '');
                }
                htmlBody = htmlBody.replace('{!Account.Country__c}', acc_record.Country__r.Name);
                htmlBody = htmlBody.replace('{!Account.Link}', URL.getSalesforceBaseUrl().toExternalForm() + '/' + acc_record.Id);
                //MDM_Email_Template.toAddresses = map_GeographyId_UserId.get(map_Geographyid_gropname.get(acc_record.Country__c));
                for (Id userids: map_GeographyId_UserId.get(map_Geographyid_gropname.get(acc_record.Country__c))) {
                    MDM_Email_Template = new Messaging.SingleEmailMessage();
                    MDM_Email_Template.setTargetObjectId(userids);
                    MDM_Email_Template.setReplyTo('no-reply@salesforce.com');
                    MDM_Email_Template.setUseSignature(false);
                    MDM_Email_Template.setBccSender(false);
                    MDM_Email_Template.setSaveAsActivity(false);
                    MDM_Email_Template.setSubject(subject);
                    MDM_Email_Template.setHtmlBody(htmlBody);
                    messages.add(MDM_Email_Template);
                }
                Update_Accounts.add(acc_record);
            }
        }
        if (messages.size() > 0) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
                if (Update_Accounts.size() > 0) {
                    update Update_Accounts;
                }
            } else {
                System.debug(LoggingLevel.ERROR, 'The email failed to send: ' +  results[0].errors[0].message);
        }
    }
    } */

    /**
     * @description Method to send custom notification, create ContactPointAddress, Copy D1 Details to Ship-To, Create ACR for new Ship-To
     * NCP-1355, NCP-3827, NCP-7766, NCP-7878
     */
    public static void createContactPointAddress(Map < Id, sObject > newItems, Map < Id, sObject > oldItems) {
        Map < Id, PNR_Partner_Function__c > partnerFunctionMap;
        Map < Id, PNR_Partner_Function__c > oldItemsMap;
        Map < Id, Id > partnerFunctionWithAcc = new Map < Id, Id > ();
        Map < Id, Account > accountMap = new Map < Id, Account > ();
        Map < Id, Account > accountIsBuyerMap = new Map < Id, Account > ();
        Set < String > contactIds = new Set < String > ();
        String targetPageRef = System.Label.D1_My_Business_page;
        String title = 'D1_ShipToTitle';
        String body = 'D1_ShipToBody';
        String notificationType = 'D1_New_Campaigns';
        List < String > customLabelValue = new List < String > ();
        List < ContactPointAddress > contactPointAddressList = new List < ContactPointAddress > ();
        List < Account > accToUpdate = new List <Account>(); //NCP-7766
        Map<Id, Id> soldToShipToMap = new Map<Id, Id>();
        Set<Id> inValidPartnerFunctionIds = New Set<Id>();
        Set<String> invalidKUNNR = new Set<String>();
        Set<String> invalidCusNum = New Set<String>();
       
        Map<Id, AccountContactRelation> soldToACRMap = new Map<Id, AccountContactRelation>();
        List<ContactPointAddress> cpaToClose = new List<ContactPointAddress>();

        //type casting oldItems with PNR_Partner_Function__c
        if (oldItems != Null) {
            oldItemsMap = (Map < Id, PNR_Partner_Function__c > ) oldItems;
        }

        //type casting newItems with PNR_Partner_Function__c
        partnerFunctionMap = (Map < Id, PNR_Partner_Function__c > ) newItems;
        for (PNR_Partner_Function__c partnerFunc : partnerFunctionMap.values()) {
            if ((oldItemsMap != null && oldItemsMap.get(partnerFunc.Id).PNR_Customer_No__c != partnerFunc.PNR_Customer_No__c && partnerFunc.PNR_Type__c == 'Ship-To' && partnerFunc.PNR_Customer_No__c != null && partnerFunc.IsInvalid__c == false) 
                || (oldItemsMap == null && partnerFunc.PNR_Type__c == 'Ship-To' && partnerFunc.PNR_Customer_No__c != null && partnerFunc.IsInvalid__c == false)) 
            {
                
                partnerFunctionWithAcc.put(partnerFunc.PNR_Customer_No__c, partnerFunc.PNR_Sold_To__c);
                soldToShipToMap.put(partnerFunc.PNR_Sold_To__c, partnerFunc.PNR_Customer_No__c);
            }
            //Remove invalid ship to partner function from contact point address - NCP-8034
            else if(oldItemsMap != null && partnerFunc.PNR_Customer_No__c != null && partnerFunc.PNR_Sold_To__c != null && oldItemsMap.get(partnerFunc.Id).IsInvalid__c != partnerFunc.IsInvalid__c && partnerFunc.IsInvalid__c == true && partnerFunc.PNR_Type__c == 'Ship-To'){
                inValidPartnerFunctionIds.add(partnerFunc.Id);            
            }
        }

        //NCP-8034 starts
        Map<String,String> invalidPFMap = new Map<String,String>();
        for(PNR_Partner_Function__c pF : [SELECT id,PNR_Sold_To__c,PNR_Customer_No__r.KUNNR__c FROM PNR_Partner_Function__c WHERE Id In:inValidPartnerFunctionIds]){
            invalidPFMap.put(pF.PNR_Sold_To__c + '_' + pF.PNR_Customer_No__r.KUNNR__c, pF.Id);
            invalidKUNNR.add(pF.PNR_Customer_No__r.KUNNR__c);
            invalidCusNum.add(pF.PNR_Sold_To__c);
        }
        
        for(ContactPointAddress cpaRec : [SELECT Id, Account_Number__c, Status__c, ParentId FROM ContactPointAddress 
                                          WHERE Account_Number__c IN:invalidKUNNR AND parentId IN:invalidCusNum 
                                          AND AddressType = 'Shipping' AND Status__c != 'Closed'])
        {
            if(invalidPFMap.containsKey(cpaRec.ParentId + '_' + cpaRec.Account_Number__c)){
                cpaRec.Status__c = 'Closed';
                cpaToClose.add(cpaRec);
            }
        }
        
        if(cpaToClose.size()>0){
            update cpaToClose;
        }
		//NCP-8034 Ends	 
        if (partnerFunctionWithAcc.size() > 0) {
            //Get ACR for Sold-To
            for (AccountContactRelation acrRecord : [SELECT Id, ContactId, AccountId, D1_Active__c, D1_User_Role__c, D1_Roles__c, Roles FROM AccountContactRelation WHERE AccountId IN :partnerFunctionWithAcc.values() AND D1_Active__c = true]){
                //Get contactIds if Contact has Ordering Permission on Account
                if(String.isNotBlank(acrRecord.D1_Roles__c) && acrRecord.D1_Roles__c.contains('Ordering')){
                    contactIds.add(acrRecord.ContactId);
                }
                soldToACRMap.put(acrRecord.Id, acrRecord);
            }

            //Get Sold-To Details
            for (Account acc: [SELECT Id, Name, IsBuyer, D1_Account_Last_Login_Date__c, D1_Registration_Status__c, Partner_Plus_Enabled__c, Partner_Plus_Joining_Date__c 
                                FROM Account WHERE Id IN: partnerFunctionWithAcc.values() AND IsBuyer = true])
            {
                accountIsBuyerMap.put(acc.Id, acc);
            }

            //Get New Ship-To Details
            for(Account acc : [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                KUNNR__c, Name2__c, Deletion_Flag_from_SAP__c, Central_Order_Block__c, D1_Account_Last_Login_Date__c, 
                                D1_Registration_Status__c, Partner_Plus_Enabled__c, Partner_Plus_Joining_Date__c
                                FROM Account WHERE Id IN: partnerFunctionWithAcc.keyset()])
            {
                accountMap.put(acc.Id, acc);
                customLabelValue.add(acc.Name);
            }

            //Send Notification to contact about new Ship-To
            if (!Test.isRunningTest() && contactIds.size()>0) {
                D1_CustomNotificationUtility.notifyUsers(contactIds, notificationType, title, body, '', targetPageRef, customLabelValue, null);
            }

            //Iterate over Ship-To Account Data to create ContactPointAddress, Copy D1 Details from Sold-To to Ship-To, Create ACR for New Ship-To
            if(accountIsBuyerMap.size()>0){
                for(Account acc : accountMap.values()){
                    Id soldToId = partnerFunctionWithAcc.get(acc.Id);
                    
                    
                    if(accountIsBuyerMap.containsKey(soldToId)){
                        //Create ContactPoint Address
                        contactPointAddressList.add(createContactPointAddressInstance(acc, soldToId));

                        //Update D1 Details from Sold-To to Ship-To(NCP-7766)
                        accToUpdate.add(createAccountInstance(acc.Id, accountIsBuyerMap.get(soldToId)));
                    }
                }
            }

            //Insert ContactPointAddress
            if (contactPointAddressList.size() > 0) {
                Database.insert(contactPointAddressList, false);
            }

            //Update Account
            if (accToUpdate.size() > 0){
                Database.update(accToUpdate, false);
            }

            //SYNC ACR with new Ship-To (NCP-7878)
            if(soldToACRMap.size()>0){
                D1_AccountContactRelationTriggerHelper.syncACR(soldToACRMap, null);
            }
        }
    }
    
    //This method will merge duplicate account field to Master Account
    public static Account copyMasterAcc(Account masterAcc, Account dupAcc) {
        if (String.isBlank(masterAcc.AccountNumber) && String.isNotBlank(dupAcc.AccountNumber)) {
            masterAcc.AccountNumber = dupAcc.AccountNumber;
        }
        if (String.isBlank(masterAcc.Name) && String.isNotBlank(dupAcc.Name)) {
            masterAcc.Name = dupAcc.Name;
        }
        if (String.isBlank(masterAcc.BillingStreet) && String.isNotBlank(dupAcc.BillingStreet)) {
            masterAcc.BillingStreet = dupAcc.BillingStreet;
        }
        if (String.isBlank(masterAcc.BillingCity) && String.isNotBlank(dupAcc.BillingCity)) {
            masterAcc.BillingCity = dupAcc.BillingCity;
        }
        if (String.isBlank(masterAcc.BillingPostalCode) && String.isNotBlank(dupAcc.BillingPostalCode)) {
            masterAcc.BillingPostalCode = dupAcc.BillingPostalCode;
        }
        if (String.isBlank(masterAcc.BillingCountry) && String.isNotBlank(dupAcc.BillingCountry)) {
            masterAcc.BillingCountry = dupAcc.BillingCountry;
        }
        if (String.isBlank(masterAcc.Transportation_Zone__c) && String.isNotBlank(dupAcc.Transportation_Zone__c)) {
            masterAcc.Transportation_Zone__c = dupAcc.Transportation_Zone__c;
        }
        if (String.isBlank(masterAcc.Central_Order_Block__c) && String.isNotBlank(dupAcc.Central_Order_Block__c)) {
            masterAcc.Central_Order_Block__c = dupAcc.Central_Order_Block__c;
        }
        if (String.isBlank(masterAcc.Central_Delivery_Block__c) && String.isNotBlank(dupAcc.Central_Delivery_Block__c)) {
            masterAcc.Central_Delivery_Block__c = dupAcc.Central_Delivery_Block__c;
        }
        if (String.isBlank(masterAcc.Central_Billing_Block__c) && String.isNotBlank(dupAcc.Central_Billing_Block__c)) {
            masterAcc.Central_Billing_Block__c = dupAcc.Central_Billing_Block__c;
        }
        if (dupAcc.Deletion_Flag_from_SAP__c) {
            masterAcc.Deletion_Flag_from_SAP__c = dupAcc.Deletion_Flag_from_SAP__c;
        }
        if (String.isBlank(masterAcc.Sort__c) && String.isNotBlank(dupAcc.Sort__c)) {
            masterAcc.Sort__c = dupAcc.Sort__c;
        }
        if (String.isBlank(masterAcc.KUNNR__c) && String.isNotBlank(dupAcc.KUNNR__c)) {
            masterAcc.KUNNR__c = dupAcc.KUNNR__c;
        }
        if (String.isBlank(masterAcc.Customer_Account_Group__c) && String.isNotBlank(dupAcc.Customer_Account_Group__c)) {
            masterAcc.Customer_Account_Group__c = dupAcc.Customer_Account_Group__c;
        }
        if (String.isBlank(masterAcc.PO_Box__c) && String.isNotBlank(dupAcc.PO_Box__c)) {
            masterAcc.PO_Box__c = dupAcc.PO_Box__c;
        }
        if (String.isBlank(masterAcc.new_VAT__c) && String.isNotBlank(dupAcc.new_VAT__c)) {
            masterAcc.new_VAT__c = dupAcc.new_VAT__c;
        }
        if (String.isBlank(masterAcc.Delivery_Pattern__c) && String.isNotBlank(dupAcc.Delivery_Pattern__c)) {
            masterAcc.Delivery_Pattern__c = dupAcc.Delivery_Pattern__c;
        }
        if (String.isBlank(masterAcc.District__c) && String.isNotBlank(dupAcc.District__c)) {
            masterAcc.District__c = dupAcc.District__c;
        }
        if (dupAcc.D1_EDGE_Customer__c) {
            masterAcc.D1_EDGE_Customer__c = dupAcc.D1_EDGE_Customer__c;
        }
        if (String.isBlank(masterAcc.Salesforce_Delivery_Days_Beer__c) && String.isNotBlank(dupAcc.Salesforce_Delivery_Days_Beer__c)) {
            masterAcc.Salesforce_Delivery_Days_Beer__c = dupAcc.Salesforce_Delivery_Days_Beer__c;
        }
        if (String.isBlank(masterAcc.Salesforce_Delivery_Days_Keg__c) && String.isNotBlank(dupAcc.Salesforce_Delivery_Days_Keg__c)) {
            masterAcc.Salesforce_Delivery_Days_Keg__c = dupAcc.Salesforce_Delivery_Days_Keg__c;
        }
        if (String.isBlank(masterAcc.Salesforce_Delivery_Days_Keg_Stout__c) && String.isNotBlank(dupAcc.Salesforce_Delivery_Days_Keg_Stout__c)) {
            masterAcc.Salesforce_Delivery_Days_Keg_Stout__c = dupAcc.Salesforce_Delivery_Days_Keg_Stout__c;
        }
        if (String.isBlank(masterAcc.Salesforce_Delivery_Days_Packaged_Good__c) && String.isNotBlank(dupAcc.Salesforce_Delivery_Days_Packaged_Good__c)) {
            masterAcc.Salesforce_Delivery_Days_Packaged_Good__c = dupAcc.Salesforce_Delivery_Days_Packaged_Good__c;
        }
        if (String.isBlank(masterAcc.Language__c) && String.isNotBlank(dupAcc.Language__c)) {
            masterAcc.Language__c = dupAcc.Language__c;
        }
        if (String.isBlank(masterAcc.Phone) && String.isNotBlank(dupAcc.Phone)) {
            masterAcc.Phone = dupAcc.Phone;
        }
        if (String.isBlank(masterAcc.General_Information__c) && String.isNotBlank(dupAcc.General_Information__c)) {
            masterAcc.General_Information__c = dupAcc.General_Information__c;
        }
        if (String.isBlank(masterAcc.SAP_Payer_Bill_To__c) && String.isNotBlank(dupAcc.SAP_Payer_Bill_To__c)) {
            masterAcc.SAP_Payer_Bill_To__c = dupAcc.SAP_Payer_Bill_To__c;
        }
        if (String.isBlank(masterAcc.Notes__c) && String.isNotBlank(dupAcc.Notes__c)) {
            masterAcc.Notes__c = dupAcc.Notes__c;
        }
        if (dupAcc.IsOwner__c) {
            masterAcc.IsOwner__c = dupAcc.IsOwner__c;
        }
        if (String.isBlank(masterAcc.Sales_Org__c) && String.isNotBlank(dupAcc.Sales_Org__c)) {
            masterAcc.Sales_Org__c = dupAcc.Sales_Org__c;
        }
        if (dupAcc.Direct_Customer__c) {
            masterAcc.Direct_Customer__c = dupAcc.Direct_Customer__c;
        }
        if (String.isBlank(masterAcc.Customer_Sales_Org_Status__c) && String.isNotBlank(dupAcc.Customer_Sales_Org_Status__c)) {
            masterAcc.Customer_Sales_Org_Status__c = dupAcc.Customer_Sales_Org_Status__c;
        }
        if (String.isBlank(masterAcc.Customer_Type__c) && String.isNotBlank(dupAcc.Customer_Type__c)) {
            masterAcc.Customer_Type__c = dupAcc.Customer_Type__c;
        }
        if (String.isBlank(masterAcc.Delivery_Plant__c) && String.isNotBlank(dupAcc.Delivery_Plant__c)) {
            masterAcc.Delivery_Plant__c = dupAcc.Delivery_Plant__c;
        }
        if (String.isBlank(masterAcc.Market__c) && String.isNotBlank(dupAcc.Market__c)) {
            masterAcc.Market__c = dupAcc.Market__c;
        }
        if (String.isBlank(masterAcc.Hub__c) && String.isNotBlank(dupAcc.Hub__c)) {
            masterAcc.Hub__c = dupAcc.Hub__c;
        }
        if (String.isBlank(masterAcc.Cluster__c) && String.isNotBlank(dupAcc.Cluster__c)) {
            masterAcc.Cluster__c = dupAcc.Cluster__c;
        }
        if (String.isBlank(masterAcc.Country__c) && String.isNotBlank(dupAcc.Country__c)) {
            masterAcc.Country__c = dupAcc.Country__c;
        }
        if (String.isBlank(masterAcc.Products_Enabled__c) && String.isNotBlank(dupAcc.Products_Enabled__c)) {
            masterAcc.Products_Enabled__c = dupAcc.Products_Enabled__c;
        }
        if (String.isBlank(masterAcc.AccountSource) && String.isNotBlank(dupAcc.AccountSource)) {
            masterAcc.AccountSource = dupAcc.AccountSource;
        }
        if (String.isBlank(masterAcc.SAP_Ship_to__c) && String.isNotBlank(dupAcc.SAP_Ship_to__c)) {
            masterAcc.SAP_Ship_to__c = dupAcc.SAP_Ship_to__c;
        }
        if (String.isBlank(masterAcc.Account_Number_with_Credit_Limit_Ref__c) && String.isNotBlank(dupAcc.Account_Number_with_Credit_Limit_Ref__c)) {
            masterAcc.Account_Number_with_Credit_Limit_Ref__c = dupAcc.Account_Number_with_Credit_Limit_Ref__c;
        }
        if (String.isBlank(masterAcc.Credit_Control_Area__c) && String.isNotBlank(dupAcc.Credit_Control_Area__c)) {
            masterAcc.Credit_Control_Area__c = dupAcc.Credit_Control_Area__c;
        }
        masterAcc.Pioneer_Enabled__c = dupAcc.Pioneer_Enabled__c;
        return masterAcc;
    }
    
    //This method will create Merge Account Record
    public static Merged_Account__c createMergeAcc(Account masterAcc, Account childAcc) {
        Merged_Account__c merAccObj = new Merged_Account__c();
        merAccObj.Account_Number__c = childAcc.AccountNumber;
        merAccObj.City__c = childAcc.BillingCity;
        merAccObj.Country__c = childAcc.BillingCountry;
        merAccObj.Outlet__c = masterAcc.Id;
        merAccObj.State_Province__c = childAcc.BillingState;
        merAccObj.Street__c = childAcc.BillingStreet;
        merAccObj.Zip_Postal_Code__c = childAcc.BillingPostalCode;
        return merAccObj;
    }
    
    // Delete duplicate record set for reporting
    @future
    public static void deleteRecordSet(List < Id > accIdList) {
        List < DuplicateRecordSet > dupRecSetList = new List < DuplicateRecordSet > ();
        Set < Id > delDupRecSet = new Set < Id > ();
        List < DuplicateRule > dupRuleList = [SELECT Id
            FROM DuplicateRule WHERE
            DeveloperName = : Label.D1_Account_Duplicate_Exclusion
            AND IsActive = true
        ];
        if (dupRuleList != null && !dupRuleList.isEmpty()) {
            String dupRuleId = dupRuleList[0].Id;
            for (DuplicateRecordItem dupRecItemObj: [SELECT Id, Name, DuplicateRecordSetId
                    FROM DuplicateRecordItem
                    WHERE RecordId IN: accIdList
                    AND DuplicateRecordSet.DuplicateRuleId = : dupRuleId
                ]) {
                if (!delDupRecSet.contains(dupRecItemObj.DuplicateRecordSetId)) {
                    dupRecSetList.add(new DuplicateRecordSet(Id = dupRecItemObj.DuplicateRecordSetId));
                    delDupRecSet.add(dupRecItemObj.DuplicateRecordSetId);
                }
            }
        }
        if (!dupRecSetList.isEmpty()) {
            delete dupRecSetList;
        }
    }
    
    /**
     * Populate Sales Area Look up
     * NCP-2278
     */
    public static void updateSalesArea(List < SObject > newItems, Map < Id, SObject > oldMap) {
        //Variables
        List < PNR_Partner_Function__c > partFuncList = new List < PNR_Partner_Function__c > ();
        Map < String, Id > salesAreaMap = new Map < String, Id > ();
        Set < String > saesAreaNameset = new Set < String > ();
        //Variables
        for (SObject sObj: newItems) {
            PNR_Partner_Function__c partFuncObj = (PNR_Partner_Function__c) sObj;
            if (oldMap != null && oldMap.containsKey(partFuncObj.Id)) { //this is for Update logic
                PNR_Partner_Function__c oldPrtFuncObj = (PNR_Partner_Function__c) oldMap.get(partFuncObj.Id);
                if ((oldPrtFuncObj.PNR_Sales_Org__c != partFuncObj.PNR_Sales_Org__c) || (oldPrtFuncObj.PNR_Distribution_Channel__c != partFuncObj.PNR_Distribution_Channel__c) || (oldPrtFuncObj.PNR_Division__c != partFuncObj.PNR_Division__c)) {
                    if (String.isNotBlank(partFuncObj.PNR_Sales_Org__c) && String.isNotBlank(partFuncObj.PNR_Distribution_Channel__c) && String.isNotBlank(partFuncObj.PNR_Division__c)) {
                        String salesArea = String.valueOf(partFuncObj.PNR_Sales_Org__c + partFuncObj.PNR_Distribution_Channel__c + partFuncObj.PNR_Division__c);
                        partFuncList.add(partFuncObj);
                        saesAreaNameset.add(salesArea);
                    }
                }
            } else if (oldMap == null) { //this is for New Insert logic
                if (String.isNotBlank(partFuncObj.PNR_Sales_Org__c) && String.isNotBlank(partFuncObj.PNR_Distribution_Channel__c) && String.isNotBlank(partFuncObj.PNR_Division__c)) {
                    String salesArea = String.valueOf(partFuncObj.PNR_Sales_Org__c + partFuncObj.PNR_Distribution_Channel__c + partFuncObj.PNR_Division__c);
                    partFuncList.add(partFuncObj);
                    saesAreaNameset.add(salesArea);
                }
            }
        }
        if (!saesAreaNameset.isEmpty()) {
            for (Sales_Area__c areObj: [SELECT Id, Name FROM Sales_Area__c WHERE Name IN: saesAreaNameset]) {
                salesAreaMap.put(String.valueOf(areObj.Name), areObj.Id);
            }
        }
        saesAreaNameset.clear();
        if (!partFuncList.isEmpty()) {
            for (PNR_Partner_Function__c funcObj: partFuncList) {
                String salesArea = String.valueOf(funcObj.PNR_Sales_Org__c + funcObj.PNR_Distribution_Channel__c + funcObj.PNR_Division__c);
                if (salesAreaMap != null && salesAreaMap.containsKey(salesArea)) {
                    funcObj.Sales_Area__c = salesAreaMap.get(salesArea);
                }
            }
        }
    }
    
    /**
     * @description : Method to update Account Type, SAP Sold To
     * @Story : NCP-6230, NCP-6766
     * @param newItems 
     * @param oldMap 
     */
    public static void updateAccountsType(Map<Id, SObject> newItems, Map< Id, SObject> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account> (); //NCP-6230 : Changed List<Account> to Map<Id, Account>
        Map<Id, PNR_Partner_Function__c> partnerFunctionMap;
        if (newItems != NULL) {
            //type casting newItems with PNR_Partner_Function__c
            partnerFunctionMap = (Map<Id, PNR_Partner_Function__c>) newItems;
        }
        for (PNR_Partner_Function__c partFuncObj: partnerFunctionMap.values()) {
            if (partFuncObj.PNR_Sold_To__c != null) {
                accountIds.add(partFuncObj.PNR_Sold_To__c);
            }
            if (partFuncObj.PNR_Customer_No__c != null) {
                accountIds.add(partFuncObj.PNR_Customer_No__c);
            }
        }
        //Get Account Details
        Map<Id, Account> accountPfMap = new Map<Id, Account>([SELECT Id, Direct_Customer__c, Customer_Account_Group__c, Delivery_Plant__c, Sales_Org__c, Account_Type__c, KUNNR__c, Terms_of_Payment__c, Description_of_the_Payment_Term__c FROM Account WHERE Id = :accountIds]);
        
        //Iterate over partner function to update Account Type
        for (PNR_Partner_Function__c pf : partnerFunctionMap.values()) {
            Boolean updateAccount = false;
            Boolean directCustomer = true;
            Id soldToId = pf.PNR_Sold_To__c;
            Id customerId = pf.PNR_Customer_No__c;

            if(accountPfMap.containsKey(soldToId)){
                //Update SAP Sold To on Ship-To Accounts where Sold To Customer Account Group is Y001 (handle Trident Ship-To Issue)
                if (pf.PNR_Type__c == PNR_TYPE_SHIP_TO && accountPfMap.get(soldToId).Customer_Account_Group__c == 'Y001') { //NCP-6766
                    accountPfMap.get(customerId).SAP_Sold_to__c = accountPfMap.get(soldToId).KUNNR__c;
                    updateAccount = true;
                }

                //Update Account Type on Sold-To/Ship-To
                //Removing the invalid Partner function data onto Account type field   NCP-8036
                if (accountPfMap.get(customerId).Account_Type__c == null && pf.IsInvalid__c == false) {
                    accountPfMap.get(customerId).Account_Type__c = pf.PNR_Type__c;
                    updateAccount = true;
                    
                } else if(accountPfMap.get(customerId).Account_Type__c != null){
                    
                    if(!accountPfMap.get(customerId).Account_Type__c.contains(pf.PNR_Type__c) && pf.IsInvalid__c == false) {
                        accountPfMap.get(customerId).Account_Type__c = accountPfMap.get(customerId).Account_Type__c + ';' + pf.PNR_Type__c;
                        updateAccount = true;
                    }else if(accountPfMap.get(customerId).Account_Type__c.contains(pf.PNR_Type__c) && pf.IsInvalid__c == true){
                        String updatedAccountType = accountPfMap.get(customerID).Account_Type__c.replace(pf.PNR_Type__c,'');
                        accountPfMap.get(customerId).Account_Type__c = updatedAccountType;
                        updateAccount = true;
                    }
                }
                    

                //Update Sales Org
                if (accountPfMap.get(customerId).Sales_Org__c != pf.PNR_Sales_Org__c) { 
                    accountPfMap.get(customerId).Sales_Org__c = pf.PNR_Sales_Org__c;
                    updateAccount = true;
                }

                //Update Delivery Plant
                if (soldToId == customerId && pf.PNR_Type__c == PNR_TYPE_SHIP_TO && accountPfMap.get(customerId).Delivery_Plant__c != pf.Delivering_Plant__c) { //NCP-7934 //&& String.isNotBlank(pf.Delivering_Plant__c - commenting due to 144191
                    accountPfMap.get(customerId).Delivery_Plant__c = pf.Delivering_Plant__c;
                    updateAccount = true;
                }

                //Update Direct Flag
                if (String.isBlank(accountPfMap.get(customerId).Customer_Account_Group__c) || accountPfMap.get(customerId).Customer_Account_Group__c == 'YIND' || (pf.PNR_Type__c != PNR_TYPE_SHIP_TO && accountPfMap.get(customerId).Customer_Account_Group__c == 'Y008')) { //NCP-6766
                    directCustomer = false;
                }
                if (accountPfMap.get(customerId).Direct_Customer__c != directCustomer) {
                    accountPfMap.get(customerId).Direct_Customer__c = directCustomer;
                    updateAccount = true;
                }
                
                //Update Terms of Payment(CUS- 158)
                if(accountPfMap.get(customerId).Terms_of_Payment__c != pf.Terms_of_Payment__c){
                    accountPfMap.get(customerId).Terms_of_Payment__c = pf.Terms_of_Payment__c;
                    updateAccount = true;
                }
                
                //Update Description of the Payment Term
                if(accountPfMap.get(customerId).Description_of_the_Payment_Term__c != pf.Description_of_the_Payment_Term__c){
                    accountPfMap.get(customerId).Description_of_the_Payment_Term__c = pf.Description_of_the_Payment_Term__c;
                    updateAccount = true;
                }

                //Add Account for which update happens
                if(updateAccount){
                    accountsToUpdate.put(customerId, accountPfMap.get(customerId));
                }
            }
        }

        //Update Accounts
        if (accountsToUpdate.size() > 0) {
            update accountsToUpdate.values();
        }
    }
    
    /**
     * User Story : NCP-3488
     * @name : updateCustomerInfoAccountsPFDelete
     * @description : This methods used to update Delivery Plant, Sales Org for Customer Account on PF - NCP-3488
     * @param oldMap 
     */
    public static void updateCustomerInfoAccountsPFDelete(Map < Id, SObject > oldMap) {
        Set < Id > accountIds = new Set < Id > ();
        List < Account > accountsToUpdate = new List < Account > ();
        Map < Id, PNR_Partner_Function__c > customerNoPfMap = new Map < Id, PNR_Partner_Function__c > ();
        for (SObject sObj: oldMap.values()) {
            PNR_Partner_Function__c partFuncObj = (PNR_Partner_Function__c) sObj;
            if (partFuncObj.PNR_Customer_No__c != null) {
                accountIds.add(partFuncObj.PNR_Customer_No__c);
                customerNoPfMap.put(partFuncObj.PNR_Customer_No__c, partFuncObj);
            }
        }
        for (Account acc: [SELECT Id, Direct_Customer__c, Customer_Account_Group__c, Delivery_Plant__c, Sales_Org__c FROM Account WHERE Id = : accountIds]) {
            Boolean updateAccount = false;
            if (customerNoPfMap.containsKey(acc.Id)) {
                PNR_Partner_Function__c pf = customerNoPfMap.get(acc.Id);
                if (pf.PNR_Type__c == PNR_TYPE_SOLD_TO || pf.PNR_Type__c == PNR_TYPE_SHIP_TO) {
                    acc.Delivery_Plant__c = null;
                    acc.Sales_Org__c = null;
                    updateAccount = True;
                }
            }
            if (updateAccount) {
                accountsToUpdate.add(acc);
            }
        }
        if (!accountsToUpdate.IsEmpty()) {
            update accountsToUpdate;
        }
    }
    
    /**
     * @description : To update all customers within its Buyer group with the new item proposal number
     * @param newMap 
     * @param oldMap 
     * User Story : NCP -4051
     */
    public static void handleItemProposalUpdate(Map < Id, SObject > newMap, Map < Id, SObject > oldMap) {
        Map < Id, PNR_Partner_Function__c > oldItems;
        Map < Id, PNR_Partner_Function__c > newItems = (Map < Id, PNR_Partner_Function__c > ) newMap;
        Map < Id, Account > accountMap = new Map < Id, Account > ();
        Map < String, Set < Id >> newItemProposalMap = new Map < String, Set < Id >> ();
        List < BuyerGroupMember > createBuyerGroupMember = new List < BuyerGroupMember > ();
        List < BuyerGroupMember > removeBuyerGroupMember = new List < BuyerGroupMember > ();
        Map < Id, String > oldItemProposalAccountMap = new Map < Id, String > ();
        Set < Id > blankItemProposalAccSet = new Set < Id > ();
        if (oldMap != null) {
            oldItems = (Map < Id, PNR_Partner_Function__c > ) oldMap;
        }
        for (PNR_Partner_Function__c newPartnerFunction: newItems.values()) {
            PNR_Partner_Function__c oldPartnerFunction;
            if (oldItems != null) {
                oldPartnerFunction = oldItems.get(newPartnerFunction.Id);
            }
            if (newPartnerFunction.PNR_Type__c == 'Sold-To' && (oldPartnerFunction != null && (oldPartnerFunction.Item_Proposal__c != newPartnerFunction.Item_Proposal__c))) {
                oldItemProposalAccountMap.put(oldPartnerFunction.PNR_Customer_No__c, oldPartnerFunction.Item_Proposal__c);
                if (newPartnerFunction.Item_Proposal__c != null) {
                    if (newItemProposalMap.containsKey(newPartnerFunction.Item_Proposal__c)) {
                        newItemProposalMap.get(newPartnerFunction.Item_Proposal__c).add(newPartnerFunction.PNR_Customer_No__c);
                    } else {
                        newItemProposalMap.put(newPartnerFunction.Item_Proposal__c, new Set < Id > {
                            newPartnerFunction.PNR_Customer_No__c
                        });
                    }
                } else {
                    blankItemProposalAccSet.add(newPartnerFunction.PNR_Customer_No__c);
                }
            }
        }
        if (!oldItemProposalAccountMap.isEmpty()) {
            for (Account acc: [Select Id, IsBuyer from Account where Id IN: oldItemProposalAccountMap.keyset()]) {
                accountMap.put(acc.Id, acc);
            }
            for (BuyerGroupMember bgm: [SELECT Id, BuyerGroupId, BuyerGroup.PortfolioID__c, BuyerId from BuyerGroupMember WHERE BuyerId IN: oldItemProposalAccountMap.keyset()]) {
                if (bgm.BuyerGroup.PortfolioID__c == oldItemProposalAccountMap.get(bgm.BuyerId)) {
                    removeBuyerGroupMember.add(bgm);
                }
            }
        }
        if (!newItemProposalMap.isEmpty()) {
            for (BuyerGroup bg: [select id, Name, PortfolioID__c from BuyerGroup where PortfolioID__c IN: newItemProposalMap.keyset()]) {
                Set < Id > accoundIdList = newItemProposalMap.get(bg.PortfolioID__c);
                for (Id accId: accoundIdList) {
                    //if(!blankItemProposalAccSet.contains(accId) && accountMap.get(accId).IsBuyer == true ){
                    if (accId != null && !blankItemProposalAccSet.contains(accId) && accountMap.get(accId) != null && accountMap.get(accId).IsBuyer == true) {
                        BuyerGroupMember bgm1 = new BuyerGroupMember();
                        bgm1.BuyerId = accId;
                        bgm1.BuyerGroupId = bg.Id;
                        createBuyerGroupMember.add(bgm1);
                    }
                }
            }
        }
        if (!createBuyerGroupMember.isEmpty()) {
            insert createBuyerGroupMember;
        }
        if (!removeBuyerGroupMember.isEmpty()) {
            delete removeBuyerGroupMember;
        }
    }

    /**
     * @description Method to create instance of ContactPointAddress (NCP-7878)
     * @param acc 
     * @param soldToId 
     * @return  `ContactPointAddress`
     */
    public static ContactPointAddress createContactPointAddressInstance(Account acc, Id soldToId){
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name = acc.Name;
        cpa.Account_Number__c = acc.KUNNR__c;
        cpa.AddressType = 'Shipping';
        cpa.City = acc.BillingCity;
        cpa.Country = acc.BillingCountry;
        cpa.PostalCode = acc.BillingPostalCode;
        cpa.State = acc.BillingState;
        cpa.Street = acc.BillingStreet;
        cpa.ParentId = soldToId;
        cpa.Name2__c = acc.Name2__c;
        cpa.source__c ='Diageo one';
        if (acc.Deletion_Flag_from_SAP__c) {
            cpa.Status__c = D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_CLOSED;
        } else if (acc.Central_Order_Block__c == D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_BLOCKED) {
            cpa.Status__c = D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_BLOCKED;
        } else {
            cpa.Status__c = D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE;
        }

        return cpa;
    }

    /**
     * @description Method to create instance of account(NCP-7878)
     * @param shipToId 
     * @param soldToAcc 
     * @return  `Account`
     */
    public static Account createAccountInstance(Id shipToId, Account soldToAcc){
        Account shipToAcc = new Account();
        shipToAcc.Id = shipToId;
        shipToAcc.D1_Account_Last_Login_Date__c = soldToAcc.D1_Account_Last_Login_Date__c;
        shipToAcc.D1_Registration_Status__c = soldToAcc.D1_Registration_Status__c;
        shipToAcc.Partner_Plus_Enabled__c = soldToAcc.Partner_Plus_Enabled__c;
        shipToAcc.Partner_Plus_Joining_Date__c = soldToAcc.Partner_Plus_Joining_Date__c;

        return shipToAcc;
    }
}