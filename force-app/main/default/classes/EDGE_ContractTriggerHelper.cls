/**
*@Description: EDGE_ContractTriggerHelper
*@Purpose: Helper Class for Contract
*@History:

*@Version      Developer                        Date            Story/Purpose

* 1.1         Preyanka Ghosh              07/06/2019        Initial Development(ES20-715)
* 1.2         Shaunak Bhattacharjee       02/12/2019        CR 1397 - Before Update
* 1.3         Saurav Prasad               12/03/2021        ECM-4116 - After Update
* 1.4         Manikandan.T                03/06/2021        ECM-4467- Modified the ECM_createPaymentSummaries method to include Custom Metadata.
* 1.5         Sayan Mullick               28/07/2021        ECM-4570 - Added sendPushNotificationForStatusChange to send push notification to reps on approval/rejection of contract
* 1.6         Saurav Prasad               26/10/2021        ECM-4884 - Logic for the field- “Contract Approval mail to Customer” 
* 1.7         Anivesh Muppa               29/10/2021        ECM-4883 - Logic for PS Generation 
* 1.8         Saurav Prasad               08/11/2021        ECM-4925 - T&C  Attachment for Approval notification mail to Customer
* 1.9         Manikandan.T                10/11/2021        ECM-4891 - Contract Details  Attachment for Approval notification mail to Customer
* 2.0         Subhrojit Majumdar          24/11/2021        ECM-4945 - Logic for Approval notification mail content to Customer
* 2.1         Saurav Prasad               28/12/2021        ECM-5089 - Sanity Bug_January 20th Release_Email is not getting triggered upon Contract being auto approved
* 2.2	      Keshav					  13/01/2022		ECM-4644: Attach Contract PDF to Approvals mail_GLO	
* 2.3         Pratap Sen                  22/03/2022        ECM-5164: PS generation for new retrospective PF types
* 2.4         Pratap Sen                  21/07/2022        ECM-5904: added logic in sendMail method to capture customer response
* 2.5		  Saurav Prasad				  10/10/2022		ECM-6214: Logic for Promo-Std (with rec PF) PS generation_Addendum_SFDC_EU
* 2.6         Abhishek Shivam             12/10/2022        ECM-6196: PS Generation on selection of new PF type_Payment by Activation
* 2.7         Pratik Somani               18/11/2022        ECM-6380: Fast Track-“Contract Approval mail to Customer” for Amended Contract_SFDC_GLO
* 2.8         Tanishq		              30/01/2023        ECM-6679: Email template change for Customer Approval mail_SFDC_EU
* 2.9         Joshraj Sen                20/12/2023         146153- Prevent Payment Summaries for CRG Contracts
*/

public without sharing class EDGE_ContractTriggerHelper {
    private static Map < Id, List < Contract >> mapAccountContract = new Map < Id, List < Contract >> ();
    //private static Set<Id> setNewContract = new Set<Id>();
    private static List < Id > lstReviewContract = new List < Id > ();
    private static List < Id > lstFutureContract = new List < Id > ();
    @TestVisible
    private static List < Id > lstInActiveContract = new List < Id > ();
    private static List < Id > lstActiveContract = new List < Id > ();
    private static List < Outlet_Contract__c > lstAddOutletContract = new List < Outlet_Contract__c > ();
    // Global Variable for ECM-4116
    public static Boolean firstcall = false;
    //Apex properties for ECM-4945
    public static Boolean hasTnC { get; set; }
    public static String salesRepEmail {get; set;}
    public static String salesRepEmailName {get; set;}
    public static String countryCode {get; set;} //added for ECM-6679
    //public static String approvalEmailContent {get; Set;}
    //Global variable for ECM-5089
    public static Boolean isTriggered = true;
    
    /**

* @description : assignContractToOutlet - Used to assign Outlet to Contract

* @return : void

* @param : List < Contract >, Map < Id, SObject > 

*/
    public static void assignContractToOutlet(List < Contract > newItems, Map < Id, SObject > oldItems) {
        Set < Id > setAccountId = new Set < Id > ();
        Map < Id, Contract > mapOldItems = new Map < Id, Contract > ();
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        
        try {
            system.debug('oldItems : '+ oldItems);
            system.debug('oldItems : '+ (newItems!=null));
            if (oldItems != null) {
                mapOldItems = (Map < Id, Contract > ) oldItems;
            }
            
            mapAccountContract = new Map < Id, List < Contract >> ();
            
            
            system.debug('mapOldItems : '+ mapOldItems);
            system.debug('newItems : '+ newItems);
            
            if (newItems != null && newItems.size() > 0) {
                for (Contract newContract: newItems) {
                    
                    system.debug('newContract : '+ newContract);
                    
                    //This code block will execute for Insert and will put all the Account data in mapAccountContract map
                    if (oldItems == null && newContract.AccountId != null && newContract.RecordTypeId == contractRecordTypeId) {
                        setAccountId.add(newContract.AccountId);
                        //setNewContract.add(newContract.Id);
                        if (mapAccountContract.containskey(newContract.AccountId)) {
                            mapAccountContract.get(newContract.AccountId).add(newContract);
                        } else {
                            mapAccountContract.put(newContract.AccountId, new List < Contract > {
                                newContract
                                    });
                        }
                    }
                                        
                    //This code block will execute for Update and will put all the Account data in mapAccountContract map if Start or End date changes
                    else if (oldItems != null && newContract.AccountId != null && newContract.RecordTypeId == contractRecordTypeId &&
                             mapOldItems.containsKey(newContract.Id) &&
                             (mapOldItems.get(newContract.Id).StartDate != newContract.StartDate ||
                              newContract.Contract_End_Date__c != mapOldItems.get(newContract.Id).Contract_End_Date__c)
                            ) {
                                setAccountId.add(newContract.AccountId);
                                //setNewContract.add(newContract.Id);
                                if (mapAccountContract.containskey(newContract.AccountId)) {
                                    mapAccountContract.get(newContract.AccountId).add(newContract);
                                } else {
                                    mapAccountContract.put(newContract.AccountId, new List < Contract > {
                                        newContract
                                            });
                                }
                            }
                }
                System.debug('mapAccountContract:::' + mapAccountContract);
                System.debug('setAccountId:::' + setAccountId);
                
                //setAccountId contains all Account irrespective of any Account Record Type
                if (setAccountId != null && setAccountId.size() > 0 && Schema.sObjectType.Account.isAccessible()) {
                    Map < Id, Account > mapOutletDetails = new Map < Id, Account > ();
                    Map < Id, Account > mapOperatorDetails = new Map < Id, Account > ();
                    String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                    String ownerRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
                    
                    //Depending on Record type(Outlet or Owner/Operator) of Account add the data in mapOutletDetails(Outlet record) or mapOperatorDetails(Operator Record)
                    for (Account objAccount: [SELECT Id, Operator__c, RecordTypeId FROM Account WHERE Id IN: setAccountId AND(RecordTypeId =: outletRecordTypeId OR RecordTypeId =: ownerRecordTypeId)]) {
                        System.debug('objAccount.RecordTypeId::' + objAccount.RecordTypeId);
                        if (objAccount.RecordTypeId == outletRecordTypeId) {
                            mapOutletDetails.put(objAccount.Id, objAccount);
                        } else if (objAccount.RecordTypeId == ownerRecordTypeId) {
                            mapOperatorDetails.put(objAccount.Id, objAccount);
                        }
                    }
                    
                    System.debug('mapOutletDetails:::' + mapOutletDetails);
                    System.debug('mapOperatorDetails:::' + mapOperatorDetails);
                    
                    //Call below method to check which Contract will created with what status
                    checkValidOutlet(mapOutletDetails);
                    checkValidOperatorOutlet(mapOperatorDetails, outletRecordTypeId);
                    
                    System.debug('lstActiveContract:::' + lstActiveContract);
                    System.debug('lstFutureContract:::' + lstFutureContract);
                    System.debug('lstReviewContract:::' + lstReviewContract);
                    //List is used to update the Status to active/Future/Review Needed. 
                    //As we have done it in After insert/update hence below query required 
                    List < Contract > lstContract = new List < Contract > ();
                    if (lstActiveContract != null && lstActiveContract.size() > 0 && Schema.sObjectType.Contract.isUpdateable()) {
                        for (Contract objContract: [SELECT Id, Status FROM Contract WHERE Id IN: lstActiveContract]) {
                            objContract.Status = 'Active';
                            lstContract.add(objContract);
                        }
                    }
                    
                    System.debug('lstInActiveContract : '+ lstInActiveContract);
                    if (lstInActiveContract != null && lstInActiveContract.size() > 0 && Schema.sObjectType.Contract.isUpdateable()) {
                        for (Contract objContract: [SELECT Id, Status FROM Contract WHERE Id IN: lstInActiveContract]) {
                            objContract.Status = 'InActive';
                            lstContract.add(objContract);
                        }
                    }
                    if (lstFutureContract != null & lstFutureContract.size() > 0) {
                        for (Contract objContract: [SELECT Id, Status FROM Contract WHERE Id IN: lstFutureContract]) {
                            objContract.Status = 'Future';
                            lstContract.add(objContract);
                        }
                    }
                    
                    if (lstReviewContract != null && lstReviewContract.size() > 0) {
                        for (Contract objContract: [SELECT Id, Status FROM Contract WHERE Id IN: lstReviewContract]) {
                            objContract.Status = 'Review Needed';
                            lstContract.add(objContract);
                        }
                    }
                    
                    System.debug('lstContract:::' + lstContract);
                    if (lstContract != null && lstContract.size() > 0) {
                        Database.update(lstContract, false);
                        System.debug('After update lstContract:::' + lstContract);
                    }
                    
                    if (lstAddOutletContract != null && lstAddOutletContract.size() > 0) {
                        Database.insert(lstAddOutletContract, false);
                        lstAddOutletContract = new List < Outlet_Contract__c > ();
                    }
                }
            }
            
        } catch (Exception contractException) {
            System.debug('Exception:::' + contractException.getLineNumber() + contractException.getMessage() + contractException.getCause());
            new EDGE_GenericException(contractException, newItems[0]);
        }
    }
    
    /**

* @description : checkValidOutlet - Used to assign Contract to Outlet and check whether we can assign or not

* @return : void

* @param : Map < Id, Account >

*/
    public static void checkValidOutlet(Map < Id, Account > mapOutletDetails) {
        Map < Id, List < Outlet_Contract__c >> mapExistOutletContract = new Map < Id, List < Outlet_Contract__c >> ();
        List < Contract > lstContract;
        try {
            if (mapOutletDetails != null && mapOutletDetails.size() > 0 && Schema.sObjectType.Outlet_Contract__c.isAccessible()) {
                System.debug('mapOutletDetails:::' + mapOutletDetails);
                //Get the existing Outlet Contract Record and put the data into mapExistOutletContract which can be used to check data with mapAccountContract
                for (Outlet_Contract__c existOutletContract: [SELECT Id, Outlet__c, Outlet__r.Operator__c, Contract__c, Contract__r.StartDate, Contract__r.Contract_End_Date__c FROM Outlet_Contract__c WHERE Outlet__c IN: mapOutletDetails.keySet() and Contract__r.Status IN('Future', 'Active') ]) {
                    
                    System.debug('within existOutletContract');
                    //If the key set in mapAccountContract is Owner/Operator than this block will execute
                    if (mapExistOutletContract.containsKey(existOutletContract.Outlet__c)) {
                        mapExistOutletContract.get(existOutletContract.Outlet__c).add(existOutletContract);
                    } else {
                        mapExistOutletContract.put(existOutletContract.Outlet__c, new List < Outlet_Contract__c > {
                            existOutletContract
                                });
                    }
                }
                
                //Iterate over all the outlet record and create corresponding Outlet-Contract list to insert
                for (Account outletRecord: mapOutletDetails.values()) {
                    lstContract = new List < Contract > ();
                    //Get the list of Contract(lstContract) of 'Outlet'
                    if (mapAccountContract.containskey(outletRecord.Id)) {
                        lstContract = mapAccountContract.get(outletRecord.Id);
                    }
                    System.debug('within lstContract:::' + lstContract);
                    System.debug('within mapExistOutletContract:::' + mapExistOutletContract);
                    
                    //If list Contract contains value then we need to check further otherwise nothing needs to be done.
                    if (lstContract != null && lstContract.size() > 0) {
                        for (Contract newContract: lstContract) {
                            //If we found any existing Outlet-Contract record then only execute the if block else create Outlet-Contract record
                            if (mapExistOutletContract != null && mapExistOutletContract.size() > 0 && mapExistOutletContract.containsKey(outletRecord.Id)) {
                                List < Outlet_Contract__c > lstExistOutletContract = mapExistOutletContract.get(outletRecord.Id);
                                Boolean createdRecord;
                                createdRecord = false;
                                
                                //1. If any Active Contract is exist and when we trying to upload new contract with future start & end date
                                //in this Both Contract & Outlet-Contract status will be InActive
                                //2. If any Active Contract exist and when we trying to upload new contract with overlapping of start & end date 
                                //we need to throw an error (implemented in if block)
                                //3. If no Active Contract exist and when we trying to upload new contract with future start & end date
                                //in this case both Contract & outlet-contract will have status as InActive 
                                //4. If no Active Contract exist and when we trying to upload new contract which are having 
                                //start date <= today AND End Date > Today AND Start Date < End Date, create new outlet-contract with status as Active and Contract status is changed to Active
                                for (Outlet_Contract__c existOutletContract: lstExistOutletContract) {
                                    createdRecord = false;
                                    //If the Start date or End Date is within the range of existing contract then we donot need to create Outlet-Contract data
                                    if (newContract.Id != existOutletContract.Contract__c && ((newContract.StartDate >= existOutletContract.Contract__r.StartDate && newContract.StartDate <= existOutletContract.Contract__r.Contract_End_Date__c) ||
                                                                                              (newContract.Contract_End_Date__c >= existOutletContract.Contract__r.StartDate && newContract.Contract_End_Date__c <= existOutletContract.Contract__r.Contract_End_Date__c))) {
                                                                                                  System.debug('before throw error');
                                                                                                  newContract.addError(Label.Contract_Error_Message);
                                                                                              } else if (newContract.Id != existOutletContract.Contract__c) {
                                                                                                  System.debug('within else of throw error');
                                                                                                  createdRecord = true;
                                                                                              }
                                }
                                
                                //Create a record if no Duplicate found
                                if (createdRecord) {
                                    System.debug('within if::199');
                                    //If the startdate is in future then Create Contract with Status 'Future' and Outlet-Contract as 'Inactive'
                                    populateDataInList(newContract, outletRecord);
                                }
                            } else {
                                System.debug('within else::202');
                                //If the startdate is in future then Create Contract with Status 'Future' and Outlet-Contract as 'Inactive'
                                populateDataInList(newContract, outletRecord);
                            }
                        }
                    }
                }
                
                System.debug('lstAddOutletContract:::' + lstAddOutletContract);
                //Insert one Outlet-Contract record for that particular Outlet
                /*if(lstAddOutletContract != null && lstAddOutletContract.size()>0){
Database.insert(lstAddOutletContract,false);
lstAddOutletContract = new List<Outlet_Contract__c>();
}*/
            }
        } catch (Exception contractException) {
            System.debug('Exception:::' + contractException.getLineNumber() + contractException.getMessage() + contractException.getCause());
            new EDGE_GenericException(contractException, lstContract[0]);
            
        }
    }
    
    /**

* @description : checkValidOperatorOutlet - Used to assign Contract to Operator child Outlet and check whether we can assign or not

* @return : void

* @param : Map < Id, Account >, String

*/
    public static void checkValidOperatorOutlet(Map < Id, Account > mapOperatorDetails, String outletRecordTypeId) {
        Map < Id, List < Outlet_Contract__c >> mapExistOutletContract = new Map < Id, List < Outlet_Contract__c >> ();
        Map < Id, Account > mapOutlet;
        List < Contract > lstContract;
        List < Contract > lstContract1;
        List < Contract > lstContract2;
        List < Contract > lstContract3;
        try {
            if (mapOperatorDetails != null && mapOperatorDetails.size() > 0) {
                mapOutlet = new Map < Id, Account > ([SELECT Id, Operator__c, RecordTypeId FROM Account WHERE Operator__c IN: mapOperatorDetails.keySet() AND RecordTypeId =: outletRecordTypeId]);
                
                //mapOulet contains data of Operator outlet as well as direct outlet provided in Account field of Contract
                if (mapOutlet != null && mapOutlet.size() > 0 && Schema.sObjectType.Outlet_Contract__c.isAccessible()) {
                    //Get the existing Outlet Contract Record and put the data into mapExistOutletContract which can be used to check data with mapAccountContract
                    for (Outlet_Contract__c existOutletContract: [SELECT Id, Outlet__c, Outlet__r.Operator__c, Contract__c, Contract__r.StartDate, Contract__r.Contract_End_Date__c FROM Outlet_Contract__c WHERE Outlet__c IN: mapOutlet.keySet() AND Contract__r.Status IN('Future', 'Active')]) {
                        //If the key set in mapAccountContract is Operator than this block will execute
                        if (mapExistOutletContract.containsKey(existOutletContract.Outlet__r.Operator__c)) {
                            mapExistOutletContract.get(existOutletContract.Outlet__r.Operator__c).add(existOutletContract);
                        } else {
                            mapExistOutletContract.put(existOutletContract.Outlet__r.Operator__c, new List < Outlet_Contract__c > {
                                existOutletContract
                                    });
                        }
                    }
                    
                    //Iterate over all the outlet record and create corresponding Outlet-Contract list
                    for (Account outletRecord: mapOutlet.values()) {
                        lstContract = new List < Contract > ();
                        
                        //Get the list of Contract(lstContract) depends on the AccountId of Contract
                        if (mapAccountContract.containskey(outletRecord.Operator__c)) {
                            lstContract = mapAccountContract.get(outletRecord.Operator__c);
                        }
                        
                        //If list Contract contains value then we need to check further otherwise nothing needs to be done.
                        if (lstContract != null && lstContract.size() > 0) {
                            Boolean duplicateFound = false;
                            Boolean createdRecord = false;
                            for (Contract newContract: lstContract) {
                                //If we found any existing Outlet-Contract record then only execute the if block else create Outlet-Contract record
                                if (mapExistOutletContract != null && mapExistOutletContract.size() > 0 && mapExistOutletContract.containsKey(outletRecord.Operator__c)) {
                                    duplicateFound = false;
                                    createdRecord = false;
                                    List < Outlet_Contract__c > lstExistOutletContract = mapExistOutletContract.get(outletRecord.Operator__c);
                                    for (Outlet_Contract__c existOutletContract: lstExistOutletContract) {
                                        duplicateFound = false;
                                        createdRecord = false;
                                        
                                        //If the Start date or End Date is within the range of existing contract then we donot need to create Outlet-Contract data
                                        if (newContract.Id != existOutletContract.Contract__c && ((newContract.StartDate >= existOutletContract.Contract__r.StartDate && newContract.StartDate <= existOutletContract.Contract__r.Contract_End_Date__c) ||
                                                                                                  (newContract.Contract_End_Date__c >= existOutletContract.Contract__r.StartDate && newContract.Contract_End_Date__c <= existOutletContract.Contract__r.Contract_End_Date__c))) {
                                                                                                      duplicateFound = true;
                                                                                                      lstReviewContract.add(newContract.Id);
                                                                                                      break;
                                                                                                  } else if (newContract.Id != existOutletContract.Contract__c) {
                                                                                                      createdRecord = true;
                                                                                                  } else if (newContract.Id == existOutletContract.Contract__c && newContract.StartDate > System.today() && newContract.Contract_End_Date__c > System.today()) {
                                                                                                      lstFutureContract.add(newContract.Id);
                                                                                                  } else if (newContract.Id == existOutletContract.Contract__c && newContract.StartDate < System.today() && newContract.Contract_End_Date__c < System.today()) {
                                                                                                      lstInActiveContract.add(newContract.Id);
                                                                                                  }
                                        System.debug('duplicateFound:::' + duplicateFound);
                                        System.debug('createdRecord:::' + createdRecord);
                                    }
                                    
                                    //Need to use Break otherwise it will create a new record
                                    if (duplicateFound) {
                                        break;
                                    }
                                    
                                    //Create a record if no Duplicate found
                                    if (createdRecord) {
                                        //If the startdate is in future then Create Contract with Status 'Future' and Outlet-Contract as 'Inactive'
                                        populateDataInList(newContract, outletRecord);
                                    }
                                    
                                } else {
                                    //If the startdate is in future then Create Contract with Status 'Future' and Outlet-Contract as 'Inactive'
                                    populateDataInList(newContract, outletRecord);
                                }
                            }
                        }
                    }
                } else {
                    //If we donot found any Outlet record for any Operator than we need to allow Contract creation with Active/Future status
                    for (Id accountId: mapAccountContract.keySet()) {
                        for (Contract newContract: mapAccountContract.get(accountId)) {
                            //This is used to create the Contract as Future status
                            if (newContract.StartDate > System.today() && newContract.Contract_End_Date__c > System.today()) {
                                lstFutureContract.add(newContract.Id);
                            } else if (newContract.StartDate < System.today() && newContract.Contract_End_Date__c < System.today()) {
                                lstInActiveContract.add(newContract.Id);
                            } else {
                                lstActiveContract.add(newContract.Id);
                            }
                        }
                    }
                }
            }
            
            System.debug('lstAddOutletContract:::' + lstAddOutletContract);
            System.debug('lstActiveContract:::' + lstActiveContract);
            //Insert Oulet-Contract for all child Outlet of Operator Account
            /*if(lstAddOutletContract != null && lstAddOutletContract.size()>0){
Database.insert(lstAddOutletContract,false);
lstAddOutletContract = new List<Outlet_Contract__c>();
}*/
            
        } catch (Exception contractException) {
            System.debug('Exception:::' + contractException.getLineNumber() + contractException.getMessage() + contractException.getCause());
            new EDGE_GenericException(contractException, lstContract[0]);
        }
        
    }
    
    /**

* @description : populateDataInList - Used to assign Contract to Outlet and check whether we can assign or not

* @return : void

* @param : Contract, Account

*/
    private static void populateDataInList(Contract newContract, Account outletRecord) {
        if (newContract.StartDate > System.today() && newContract.Contract_End_Date__c > System.today()) {
            lstAddOutletContract.add(createOutletContract(outletRecord.Id, newContract.Id, 'InActive'));
            lstFutureContract.add(newContract.Id);
            
        } else if (newContract.StartDate < System.today() && newContract.Contract_End_Date__c < System.today()) {
            lstAddOutletContract.add(createOutletContract(outletRecord.Id, newContract.Id, 'InActive'));
            lstInActiveContract.add(newContract.Id);
        } else {
            lstAddOutletContract.add(createOutletContract(outletRecord.Id, newContract.Id, 'Active'));
            lstActiveContract.add(newContract.Id);
        }
    }
    
    /**

* @description : createOutletContract - Used to create outlet contract

* @return : Outlet_Contract__c

* @param : Id, Id, String

*/
    private static Outlet_Contract__c createOutletContract(Id outletRecord, Id contractId, String status) {
        Outlet_Contract__c objOutletContract;
        objOutletContract = new Outlet_Contract__c();
        objOutletContract.Outlet__c = outletRecord;
        objOutletContract.Contract__c = contractId;
        objOutletContract.Status__c = status;
        return objOutletContract;
    }
    /**

* @description : updateUOSEarnt - Used to populate UOS Earnt field with same value as Initial UOS Earnt

* @return : void

* @param : List < Contract >

*/
    public static void updateUOSEarnt(List < Contract > newItems) {
        if (newItems != null) {
            for (Contract newContarctObj: newItems) {
                if (newContarctObj.Initial_UOS_Earnt__c != null) {
                    newContarctObj.UOS_Earnt__c = newContarctObj.Initial_UOS_Earnt__c;
                }
            }
        }
    }
    
    //CR 1397 -- Shaunak Bhattacharjee
    /**

* @description : updateUOSEarntOnInitialUpdate - Used to populate UOS Earnt field when Initial UOS Earnt is updated

* @return : void

* @param : List < Contract >, Map < Id, sObject >

*/
    public static void updateUOSEarntOnInitialUpdate(List < Contract > newItems, Map < Id, sObject > oldItems) {
        List < Contract > updateUos1;
        List < Contract > updateUos2;
        List < Contract > updateUos3;
        List < Contract > updateUos4;
        List < Contract > updateUos5;
        List < Contract > updateUos6;
        List < Contract > updateUos;
        updateUos = new List < Contract > ();
        Map < Id, Contract > mapOldItems;
        mapOldItems = new Map < Id, Contract > ();
        if (oldItems != null) {
            mapOldItems = (Map < Id, Contract > ) oldItems;
        }
        if (newItems != null && mapOldItems != null) {
            for (Contract newContarctObj: newItems) {
                if (newContarctObj.UOS_Earnt__c == null && newContarctObj.status == 'Active') {
                    newContarctObj.UOS_Earnt__c = 0;
                }
                if (newContarctObj.Initial_UOS_Earnt__c != null) {
                    
                    if ((mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c != newContarctObj.Initial_UOS_Earnt__c) && mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c != null) {
                        Decimal diff = newContarctObj.Initial_UOS_Earnt__c - mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c;
                        newContarctObj.UOS_Earnt__c = diff + newContarctObj.UOS_Earnt__c;
                        updateUos.add(newContarctObj);
                    } else if (mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c == null && newContarctObj.Initial_UOS_Earnt__c != null) {
                        if (newContarctObj.UOS_Earnt__c == null) {
                            newContarctObj.UOS_Earnt__c = 0;
                        }
                        
                        newContarctObj.UOS_Earnt__c += newContarctObj.Initial_UOS_Earnt__c;
                    }
                    
                } else if ((newContarctObj.Initial_UOS_Earnt__c == null) && (mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c != newContarctObj.Initial_UOS_Earnt__c)) {
                    newContarctObj.Initial_UOS_Earnt__c = 0;
                    Decimal diff = newContarctObj.Initial_UOS_Earnt__c - mapOldItems.get(newContarctObj.Id).Initial_UOS_Earnt__c;
                    newContarctObj.UOS_Earnt__c = diff + newContarctObj.UOS_Earnt__c;
                    updateUos.add(newContarctObj);
                }
            }
        }
    }
    
    /**

* @description : OnContractAfterUpdate - create payment summary's when contract status changes to active 

* @return : void

* @param : Map < Id, sObject >, Map < Id, sObject >

*/
    
    public static void onContractStatusUpdate(Map < Id, sObject > newItems, Map < Id, sObject > oldItems) {
        system.debug('OnContractAfterUpdate');
        String COUNTRYNAME = 'Australia';
        List < ECM_Payment_Summary__c > paymentUpdateLst = new List < ECM_Payment_Summary__c > ();
        //will get the A&P record type ID
        Id AandP_RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Id budgetType_RecordId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id crgRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//146153
        set < id > activeIds = new set < id > ();
        Map < Id, Contract > mapnewItems = (Map < Id, Contract > ) newItems;
        Map < Id, Contract > mapOldItems;
        
        if (oldItems != null) {
            mapOldItems = (Map < Id, Contract > ) oldItems;
        }
        
        try {
            for (contract con: mapnewItems.values()) {
                if ((con.status == 'Active' && mapOldItems.get(con.Id).status != 'Active') /* && con.RecordTypeId != AandP_RecordTypeId  && con.ECM_Upfront_Pre_payment_amount__c > 0*/ ) {
                    activeIds.add(con.id);
                }
            }
            Map < String, Pick_Up_Options__c > budgetTypeValues = new Map < String, Pick_Up_Options__c > ();
            List < String > BUDGET_TYPE = new List < String > {
                'SKU Specific Rebates [AU]',
                    'Upfront Payment [AU]',
                    'Portfolio Rebates [AU]'
                    };
                        if (activeIds.size() > 0) {
                            Map < String, Decimal > depletionCountForOutlets = new Map < String, Decimal > ();
                            List < Contract > contractLst = [Select id, ECM_Upfront_Pre_payment_amount__c, status, ECM_Agreement_Type__r.Geography__r.Name, AccountId, RecordTypeId
                                                             from Contract Where Id IN: activeIds AND ECM_Agreement_Type__r.Geography__r.Name =: COUNTRYNAME and status = 'Active'
                                                            ];
                            
                            for (Pick_Up_Options__c pickOptionRecord: [select id, Name, Geography__r.Name, Status__c, RecordTypeId from Pick_Up_Options__c
                                                                       Where Geography__r.Name =: COUNTRYNAME AND Name IN: BUDGET_TYPE AND Status__c = 'Active'
                                                                       AND RecordTypeId =: budgetType_RecordId
                                                                      ]) {
                                                                          system.debug('option=' + pickOptionRecord);
                                                                          budgetTypeValues.put(pickOptionRecord.Name, pickOptionRecord);
                                                                      }
                            List < ECM_Rebates_Calendar__mdt > rebateCalendarMap = [SELECT ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_Start__c, ECM_Rebate_Period_End__c,
                                                                                    ECM_Region__c, ECM_Financial_Year__c, ECM_Quarter__c, Id FROM ECM_Rebates_Calendar__mdt
                                                                                    Where ECM_Rebate_Calculation_Date__c =: System.today() AND ECM_Region__c =: COUNTRYNAME
                                                                                   ];
                            /*if (rebateCalendarMap.Size() > 0) {
for (Depletions__c depletionRecord: [SELECT Id, ECM_Outlet__c, ECM_Start_Period__c, ECM_End_Period__c, ECM_Product__c,
ECM_Volume__c, ECM_UoM__c FROM Depletions__c Where ECM_Start_Period__c >=: rebateCalendarMap[0].ECM_Rebate_Period_Start__c
AND ECM_End_Period__c <=: rebateCalendarMap[0].ECM_Rebate_Period_End__c
]) {
if (depletionCountForOutlets.containsKey(depletionRecord.ECM_Outlet__c + '-' + depletionRecord.ECM_Product__c)) {
Decimal volumeRate = depletionCountForOutlets.get(depletionRecord.ECM_Outlet__c + '-' + depletionRecord.ECM_Product__c) + depletionRecord.ECM_Volume__c;
depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c + '-' + depletionRecord.ECM_Product__c, volumeRate);
} else {
depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c + '-' + depletionRecord.ECM_Product__c, depletionRecord.ECM_Volume__c);
}
}
}
*/
                            
                            If(contractLst.Size() > 0) {
                                for (Contract conRec: contractLst) {
                                    system.debug('conRec'+conRec.ECM_Upfront_Pre_payment_amount__c);
                                    if (rebateCalendarMap.Size() > 0 && conRec.RecordTypeId != crgRecordTypeId ) {//146153
                                        ECM_Payment_Summary__c paymntRecord = new ECM_Payment_Summary__c();
                                        paymntRecord.ECM_Contract__c = conRec.Id;
                                        paymntRecord.ECM_Type__c = 'Volume-Based';
                                        paymntRecord.ECM_Budget_types__c = budgetTypeValues.size() > 0 && budgetTypeValues.containskey('SKU Specific Rebates [AU]') ? budgetTypeValues.get('SKU Specific Rebates [AU]').Id : Null;
                                        paymntRecord.ECM_Payment_Summary_Status__c = 'Open';
                                        paymentUpdateLst.add(paymntRecord);
                                    }
                                    if (conRec.RecordTypeId != AandP_RecordTypeId  && conRec.RecordTypeId != crgRecordTypeId && conRec.ECM_Upfront_Pre_payment_amount__c > 0) {//146153
                                        ECM_Payment_Summary__c paymntRecord = new ECM_Payment_Summary__c();
                                        paymntRecord.ECM_Contract__c = conRec.Id;
                                        paymntRecord.ECM_Type__c = 'Non-Volume';
                                        paymntRecord.ECM_Payment_Summary_Status__c = 'Open';
                                        paymntRecord.ECM_Total_Amount_Confirmed__c = conRec.ECM_Upfront_Pre_payment_amount__c;
                                        paymntRecord.ECM_Budget_types__c = budgetTypeValues.size() > 0 && budgetTypeValues.containskey('Upfront Payment [AU]') ? budgetTypeValues.get('Upfront Payment [AU]').Id : Null;
                                        paymentUpdateLst.add(paymntRecord);
                                    }
                                }
                            }
                            
                            if (paymentUpdateLst.size() > 0) {
                                insert paymentUpdateLst;
                            }
                            
                        }
        }
        Catch(Exception Ex) {
            System.debug('Exception OnContractAfterUpdate =' + Ex);
        }
        
        
        ContractTriggerHandler.isFirstTime = false;
    }
    /**

* @description : ECM_PaymentSummary_Creation - Used to Create Payment Summary Record of Budget Type Upfront Payment [AU] 
* @return : void
* @param : Map < Id, sObject >, Map < Id, sObject >

*/
    public static void ECM_PaymentSummary_Creation(Map < Id, sObject > newItems, Map < Id, sObject > oldItems) {
       
        Id budgetType_RecordId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        List < ECM_Payment_Summary__c > PaymentSummary_to_Insert = new List < ECM_Payment_Summary__c > ();
         Id crgRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//146153
        Set < Contract > Ids_to_create_Payment_Summary_Upfront_Payment = new Set < Contract > ();
        Map < Id, Contract > mapnewItems = (Map < Id, Contract > ) newItems;
        system.debug(mapnewItems);
        Map < Id, Contract > mapOldItems;
        
        if (oldItems != null) {
            mapOldItems = (Map < Id, Contract > ) oldItems;
        }
        system.debug(mapOldItems);
        List < Pick_Up_Options__c > pickOptionRecord = [select id, Name, Geography__r.Name, Status__c, RecordTypeId from Pick_Up_Options__c
                                                        Where Geography__r.Name =: 'Australia'
                                                        AND Name =: 'Upfront Payment [AU]'
                                                        AND Status__c = 'Active'
                                                        AND RecordTypeId =: budgetType_RecordId limit 1
                                                       ];
        system.debug('pickOptionRecord =>' + pickOptionRecord);
        for (Contract conts: mapnewItems.values()) {
            system.debug('conts=>' + conts);
            system.debug(conts.status);
            
            if (conts.status == 'Active' && conts.RecordTypeId!=crgRecordTypeId   && conts.UOS_Earnt__c!= null && conts.ECM_UOS_Annual_Target__c != null && conts.ECM_Upfront_Payment_Spent__c != null && conts.UOS_Earnt__c >= conts.ECM_UOS_Annual_Target__c &&
                conts.ECM_UOS_Annual_Target__c - conts.ECM_Upfront_Payment_Spent__c > 0 && conts.ECM_Customer_Upfront_Payment_Inv_Now_Due__c && mapOldItems.get(conts.id).ECM_Customer_Upfront_Payment_Inv_Now_Due__c != conts.ECM_Customer_Upfront_Payment_Inv_Now_Due__c) {//146153
                    system.debug(conts.status);
                    Ids_to_create_Payment_Summary_Upfront_Payment.add(conts);
                    if (pickOptionRecord.size() > 0) {
                        system.debug('pickOptionRecord =>' + pickOptionRecord);
                        ECM_Payment_Summary__c paymntRecord_New = new ECM_Payment_Summary__c();
                        paymntRecord_New.ECM_Contract__c = conts.Id;
                        paymntRecord_New.ECM_Type__c = 'Non-Volume';
                        paymntRecord_New.ECM_Payment_Summary_Status__c = 'Open';
                        paymntRecord_New.ECM_Total_Amount_Confirmed__c = conts.ECM_Upfront_Pre_payment_amount__c;
                        paymntRecord_New.ECM_Budget_types__c = pickOptionRecord[0].id;
                        PaymentSummary_to_Insert.add(paymntRecord_New);
                    }
                }
        }
        system.debug('PaymentSummary_to_Insert =>' + PaymentSummary_to_Insert);
        if (PaymentSummary_to_Insert.size() > 0) {
            
            insert PaymentSummary_to_Insert;
        }
        ContractTriggerHandler.isFirstTime = false;
    }
    

    /**

* @description : updateTotalUOSPoints - Used to populate Total UOS Points Earned to Date field with same value as UOS Earnt
* @return : void
* @param : List < Contract > 

*/
    public static void updateTotalUOSPoints(List < Contract > newItems) {
        if (newItems != null) {
            for (Contract newContarctObj: newItems) {
                if (newContarctObj.UOS_Earnt__c != null) {
                    String str = String.valueOf(newContarctObj.UOS_Earnt__c);
                    newContarctObj.ECM_Total_UoS_Points_Earned_to_Date__c=str;
                }
            }
        }
    }
    /**

* @description : updateTotalUOSPointsOnUOSUpdate - Used to populate Total UOS Points field when UOS Earnt is updated
* @return : void
* @param : List < Contract >, Map < Id, sObject >

*/
    public static void updateTotalUOSPointsOnUOSUpdate(List < Contract > newItems, Map < Id, sObject > oldItems) {
        List < Contract > updateUos;
        updateUos = new List < Contract > ();
        Map < Id, Contract > mapOldItems;
        mapOldItems = new Map < Id, Contract > ();
        if (oldItems != null) {
            mapOldItems = (Map < Id, Contract > ) oldItems;
        }
        if (newItems != null && mapOldItems != null) {
            for (Contract newContarctObj: newItems) {
                if (newContarctObj.UOS_Earnt__c != null && (mapOldItems.get(newContarctObj.Id).UOS_Earnt__c != newContarctObj.UOS_Earnt__c)) {
                    String str = String.valueOf(newContarctObj.UOS_Earnt__c);
                    newContarctObj.ECM_Total_UoS_Points_Earned_to_Date__c = str;
                } else if ((newContarctObj.UOS_Earnt__c == null) && (mapOldItems.get(newContarctObj.Id).UOS_Earnt__c != newContarctObj.UOS_Earnt__c)) {
                    newContarctObj.ECM_Total_UoS_Points_Earned_to_Date__c = null;
                }
            }
        }
    }
    /**

* @description : ECM_isUpfrontPaymentDue - Used to check if last payment Date is updated then fire the process builder to create a payment summary.
* @return : void
* @param : Map < Id, sObject >, Map < Id, sObject >

*/
    public static void ECM_isUpfrontPaymentDue(Map < Id, sObject > newItems, Map < Id, sObject > oldItems) {
        
        Map < Id, Contract > mapnewItems = (Map < Id, Contract > ) newItems;
        Map < Id, Contract > mapoldItems = (Map < Id, Contract > ) oldItems;
        String COUNTRYNAME = 'Australia';
        String RETROSPECTIVE = 'Retrospective';
        String EQUALINSTALLMENTS= 'Equal Instalments';
        
        Map <id, Contract > contractMap = new Map<id,contract>([Select id, ECM_Upfront_Last_Payment_date__c, status, AccountId 
                                                                from Contract Where Id IN: mapnewItems.keySet() AND ECM_Selected_Payment_Schedule_AU__c!=null AND (ECM_Selected_Payment_Schedule_AU__r.ECM_type__c =: RETROSPECTIVE OR ECM_Selected_Payment_Schedule_AU__r.ECM_type__c=:EQUALINSTALLMENTS) AND Account.Country__r.Name =: COUNTRYNAME and status = 'Active']);
        
        
        for(contract c:mapnewItems.Values()){
            
            if(contractMap.get(c.id)!=null && c.ECM_Upfront_Last_Payment_date__c!=null && (mapoldItems.get(c.id).ECM_Upfront_Last_Payment_date__c!=c.ECM_Upfront_Last_Payment_date__c)){
                
                c.ECM_Is_Payment_Due__c=true;
            }
        }
        
    }
    
    /**
*@Method Description: ECM_createPaymentSummaries
*@Purpose: when Spain contract status changes from Approved to Active/Inactive - Create  PS-Record
*@History:

*@Version       Developer                   Date            Story/Purpose

* 1.0           Manikandan                 13/03/2021         ECM-4117
* 1.1           Saurav Prasad              15/03/2021         ECM-4116
* 1.2           Veerendra                  15/03/2021         ECM-3600
* 1.3           Keshav                     23/03/2021         ECM-3597
* 1.4           Saurav Prasad              11/05/2021         ECM-4405 (Bug Fix) - Made future methods due to Too many query Exception
* 1.5			Saurav Prasad			   10/10/2022		  ECM-6214 Logic for Promo-Std (with rec PF) PS generation_Addendum_SFDC_EU
* 1.6           Abhishek Shivam            12/10/2022         ECM-6196: PS Generation on selection of new PF type_Payment by Activation
* 1.7           Joshraj Sen                24/12/2023         146153- Prevent Payment Summaries for CRG Contracts
*/
    
    public static void ECM_createPaymentSummaries(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map <Id,Contract> mapnewItems = (Map<Id,Contract>) newItems;
        Map <Id,Contract> mapoldItems = (Map<Id,Contract>) oldItems;
        
        Map <Id,Contract> contractMap = new Map <Id,Contract> ();
        Map <String,ECM_Payment_Summary__c> mapOfPaySum = new Map <String,ECM_Payment_Summary__c> ();
        set <Id> paymentAtTheEndIdSet = new set <Id>();
        set <Id> partialPrePymtSdiIdSet = new set <Id>();
        set <Id> partialPrePymtSdiIdsSet = new set <Id>();
        set <Id> PromoPrepaymentIdSet = new set <Id>();
        set <Id> PromoStandardIdSet = new set <Id>();////added for ECM-4883
        set <Id> paymentAfterActivationSdiIdSet = new set <Id>();
        set <Id> recurringRetrospectiveIdSet = new set <Id>();//added for ECM-5164
        
        
        //End of ECM-4405
        Map <String,List<ECM_Sales_Driver_Item_Detail__c>> uniqueIdentifier = new Map <String,List<ECM_Sales_Driver_Item_Detail__c>> ();
        List <ECM_Sales_Driver_Item_Detail__c> sdidList = new List<ECM_Sales_Driver_Item_Detail__c> ();
        List <ECM_Payment_Summary_Item__c> psiList = new List<ECM_Payment_Summary_Item__c> ();
        Set <Id> contVolSet = new Set <Id>();
        List<String> promoPaymentList= new List<String>();
        List<String> volumePaymentList= new List<String>();
        Id AandP_RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Id crgRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//146153
        //ECM-4467 : Deployment_Enabling Ireland to the Payment summary code change_SFDC_Tech debt
        for(ECM_Technical_Market_Setting__mdt mdt: [select masterlabel,ECM_Country__c,ECM_Payment_Summary_Promo__c,ECM_Payment_Summary_Volume__c from ECM_Technical_Market_Setting__mdt]){
            if(mdt.ECM_Payment_Summary_Promo__c){
                promoPaymentList.add(mdt.ECM_Country__c);
            }
            
            if(mdt.ECM_Payment_Summary_Volume__c){
                volumePaymentList.add(mdt.ECM_Country__c);
            }
        }
        system.debug('volumePaymentList--->'+promoPaymentList);
        try{
            for(Contract con : [SELECT Id,ECM_Agreement_Type__r.CurrencyIsoCode,ECM_Agreement_Type__r.ECM_Screen_3_field_configuration__c,Account.Country__r.Code__c,ECM_Amended__c  
                                FROM Contract where Id IN:mapnewItems.keySet() and RecordTypeId != :crgRecordTypeId  and (Account.Country__r.Code__c IN:promoPaymentList OR Account.Country__r.Code__c IN:volumePaymentList)]){//146153
                                    if( (mapnewItems.get(con.Id).RecordTypeId != AandP_RecordTypeId)
                                       && promoPaymentList.contains(con.Account.Country__r.Code__c)
                                       && mapoldItems.get(con.Id).Status == 'Approved'
                                       && (mapnewItems.get(con.Id).Status == 'Active' || 
                                           mapnewItems.get(con.Id).Status == 'InActive')){
                                               contractMap.put(con.Id,con);
                                               system.debug('contVolSet--->'+contVolSet);
                                           }
                                    if( volumePaymentList.contains(con.Account.Country__r.Code__c) 
                                       && mapoldItems.get(con.Id).Status == 'Approved'
                                       && (mapnewItems.get(con.Id).Status == 'Active' || 
                                           mapnewItems.get(con.Id).Status == 'InActive'))
                                    {
                                        if(con.ECM_Agreement_Type__r.ECM_Screen_3_field_configuration__c.contains('Investment')){
                                            contVolSet.add(con.Id);  
                                        }  
                                    }
                                    
                                }
            
            for(ECM_Sales_Driver_Item__c sdi :   [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,RecordType.Name,ECM_Payment_Via_SAP__c,
                                                  ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,
                                                  ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,
                                                  (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,
                                                   ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                                                   ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                                                   ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                                                   FROM Sales_Driver_Item_Details__r) 
                                                  FROM ECM_Sales_Driver_Item__c where 
                                                  Contract__c IN :contractMap.keySet()
                                                  AND ECM_Payment_Frequency__r.ECM_Other_Investment__c = true]){
                                                      //chnages regarding ECM-4883
                                                      if(sdi.RecordType.Name == 'Sales Driver' || (sdi.RecordType.Name == 'Activation Spend' && sdi.ECM_Payment_Via_SAP__c)){
                                                          
                                                          if(sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Single yearly payments'){
                                                              PromoStandardIdSet.add(sdi.Id);
                                                          }
                                                          if((sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Partial Prepayment' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Prepago parcial')&&(sdi.ECM_Payment_Frequency__r.ECM_Prepayment__c==true)){
                                                              //partialPrePymtSdiList.add(sdi);
                                                              partialPrePymtSdiIdSet.add(sdi.Id);
                                                          }
                                                          if(sdi.ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c != null && (sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Monthly' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Quarterly' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Half-yearly' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Yearly')){
                                                              //partialPrePymtSdilst.add(sdi);
                                                              partialPrePymtSdiIdsSet.add(sdi.Id);
                                                          }
                                                          if(sdi.ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c != null && System.Label.ECM_RetrospectivePFTypes.replace('\r\n','').split(',').contains(sdi.ECM_Payment_Frequency__r.ECM_Type__c)){
                                                              recurringRetrospectiveIdSet.add(sdi.Id); //ECM_RetrospectivePFTypes - Monthly Retrospective,Quarterly Retrospective,Half-yearly Retrospective,Yearly Retrospective
                                                          }
                                                          if(((sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'At the End of the Contract' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Al finalizar el contrato'  ) && (sdi.ECM_Payment_Frequency__r.ECM_End_Date__c==true))||(sdi.ECM_Payment_Frequency__r.ECM_Type__c.equals(System.label.ECM_PsPaymentByActivation))){  // added for ECM-6196
                                                              //paymentAtTheEndlist.add(sdi);
                                                              paymentAtTheEndIdSet.add(sdi.Id);
                                                          }
                                                          if(sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Payment after activation' || sdi.ECM_Payment_Frequency__r.ECM_Type__c == 'Pago después de la activación'){
                                                              //paymentAfterActivationSdilst.add(sdi); 
                                                              paymentAfterActivationSdiIdSet.add(sdi.Id);
                                                          }
                                                          if(sdi.ECM_Payment_Frequency__r.ECM_Prepayment__c==true && (sdi.ECM_1st_Prepayment_Date__c!=null || sdi.ECM_Payment_Date__c!=null)){
                                                              //PromoPrepaymentlist.add(sdi);
                                                              PromoPrepaymentIdSet.add(sdi.Id);
                                                          }
                                                      }                                                                                                           
                                                  }
            set<Id> conSet= new set<Id>();
            for(Contract conRec:[SELECT Id,ECM_Payment_Frequency_type__c,StartDate,Contract_End_Date__c,ECM_Payment_Frequency_type__r.ECM_Volume_target__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,ECM_Payment_Frequency_type__r.ECM_From_When_Starts__c,(Select Id,Name,ECM_Product__c from Contract_Items__r) FROM Contract where Id IN:contVolSet AND ECM_Payment_Frequency_type__c!=null AND ECM_Payment_Frequency_type__r.ECM_Volume_target__c =true]){
                conSet.add(conRec.Id);
            }
            if(conSet.size()>0){
                ECM_CreatePaymtSummaryUtility.ECM_createVolBasedRecurringPS(conSet,null); 
            }
            
            if(!partialPrePymtSdiIdSet.isEmpty()){
                
                ECM_CreatePaymtSummaryUtility.ECM_createPromoStandardPrePaymentPS(partialPrePymtSdiIdSet,null);
            }
            
            if(!partialPrePymtSdiIdsSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(partialPrePymtSdiIdsSet,null); 
            }
            
            if(!paymentAfterActivationSdiIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardAfteractivationPS(paymentAfterActivationSdiIdSet,null); 
            }
            
            if(!paymentAtTheEndIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardEndofContract(paymentAtTheEndIdSet,null); 
            }
            if(!PromoPrepaymentIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromoPrepaymentSummaries(PromoPrepaymentIdSet,null); 
            }
            //changes regarding ECM-4883
            if(!PromoStandardIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPSSingleYearPF(PromoStandardIdSet);
            }
            if(!recurringRetrospectiveIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(recurringRetrospectiveIdSet,null);
            }
          
            
            
            ContractTriggerHandler.isFirstTime = false;
        } 
        catch (Exception contractException) {
            System.debug('Class:EDGE_ContractTriggerHelper\nmethod:ECM_createPromoStandardPS\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
    }
    
    /**

* @description : sendPushNotificationForStatusChange - Rejection Notification for Sales rep for the Promo standard and Volume PS
* @return : void
* @param : List<Contract>, Map < Id, sObject >

*/
    public static void sendPushNotificationForStatusChange(List<Contract> newItems, Map<Id, sObject> oldItems){
        Map<Id, Contract> mapOldItems = new Map <Id, Contract>();
        Map<String, Object> custom = new Map<String, Object>();  
        String notificationTxt ='';
        String comments='';
        String email ='';
        Map<Id,Contract> contractMap = new Map<Id,Contract>();
        Map<Id, ECM_Approval_Log__c> mapConIdApprovalRejectedLog = new Map<Id, ECM_Approval_Log__c>();
        Map<Id, ECM_Approval_Log__c> mapConIdApprovalApprovedLog = new Map<Id, ECM_Approval_Log__c>();
        
        if (oldItems != null) {
            mapOldItems = (Map<Id, Contract>) oldItems;
        }
        if(newItems!=null)
        {
            for(Contract conObj : newItems){
                if(((conObj.Status.equals('Approved')|| conObj.Status.equals('Draft'))&& mapOldItems!=null && mapOldItems.containsKey(conObj.Id) 
                   && mapOldItems.get(conObj.Id).Status != conObj.Status ) || Test.isRunningTest()){
                       contractMap.put(conObj.Id,conObj);
                   }                    
            }  
        }
        if(!contractMap.isEmpty()){
            for(ECM_Approval_Log__c approvalLogRecd :  [SELECT Id, ECM_Comment__c,ECM_Contract__c,ECM_Contract__r.Account.Name, ECM_Time_Date_Log__c,Name,ECM_Status__c,ECM_Contract__r.Owner.LanguageLocaleKey
                                                        FROM ECM_Approval_Log__c 
                                                        WHERE ECM_Contract__c IN :contractMap.KeySet() AND ECM_Status__c IN ('Rejected','Approved')
                                                        ORDER BY LastModifiedDate ASC]){
                                                            if(approvalLogRecd.ECM_Status__c.equals('Rejected')){
                                                                mapConIdApprovalRejectedLog.put(approvalLogRecd.ECM_Contract__c,approvalLogRecd);                                               
                                                            }else if(approvalLogRecd.ECM_Status__c.equals('Approved')){                  
                                                                mapConIdApprovalApprovedLog.put(approvalLogRecd.ECM_Contract__c,approvalLogRecd);  
                                                            }           
                                                        }
            System.debug('mapConIdApprovalRejectedLog'+ mapConIdApprovalRejectedLog.size());
            System.debug('mapConIdApprovalApprovedLog'+ mapConIdApprovalApprovedLog.size());
            for(Contract newContarctObj: contractMap.values()){
                //this is used for Approved records
                System.debug(newContarctObj.Status+ 'newContarctObj.Status');
                System.debug('mapConIdApprovalRejectedLog.containsKey(newContarctObj.Id)' + mapConIdApprovalRejectedLog.containsKey(newContarctObj.Id));
                if (newContarctObj.Status.equals('Approved') && 
                    (!mapConIdApprovalApprovedLog.isEmpty() && mapConIdApprovalApprovedLog.containsKey(newContarctObj.Id))) {
                        if(mapConIdApprovalApprovedLog.get(newContarctObj.Id).ECM_Contract__r.Owner.LanguageLocaleKey == 'de'){
                            notificationTxt = Label.ECM_Contract_Push_Notification_Generic_Message_DE.replace('@@@@',newContarctObj.ContractNumber).replace('*****',mapConIdApprovalApprovedLog.get(newContarctObj.Id).ECM_Contract__r.Account.Name);
                        	notificationTxt = notificationTxt +' '+Label.ECM_Contract_Push_Notification_Approved_Message_DE;
                        }else{
                            notificationTxt = Label.ECM_Contract_Push_Notification_Generic_Message.replace('@@@@',newContarctObj.ContractNumber).replace('*****',mapConIdApprovalApprovedLog.get(newContarctObj.Id).ECM_Contract__r.Account.Name);
                        	notificationTxt = notificationTxt +' '+Label.ECM_Contract_Push_Notification_Approved_Message;
                        }                        
                    }
                //this is used for Rejected records
                
                else if(newContarctObj.Status.equals('Draft') &&
                        (!mapConIdApprovalRejectedLog.isEmpty() && mapConIdApprovalRejectedLog.containsKey(newContarctObj.Id)) ){
                            email = String.isNotBlank(mapConIdApprovalRejectedLog.get(newContarctObj.Id).Name)?mapConIdApprovalRejectedLog.get(newContarctObj.Id).Name:' ';
                            comments = String.isNotBlank(mapConIdApprovalRejectedLog.get(newContarctObj.Id).ECM_Comment__c)?mapConIdApprovalRejectedLog.get(newContarctObj.Id).ECM_Comment__c:' ';
                            if(mapConIdApprovalRejectedLog.get(newContarctObj.Id).ECM_Contract__r.Owner.LanguageLocaleKey == 'de'){
                                notificationTxt = Label.ECM_Contract_Push_Notification_Generic_Message_DE.replace('@@@@',newContarctObj.ContractNumber).replace('*****',mapConIdApprovalRejectedLog.get(newContarctObj.Id).ECM_Contract__r.Account.Name);                            	
                            	notificationTxt = notificationTxt + ' ' +Label.ECM_Contract_Push_Notification_Rejected_Message_DE.replace('&&&&',email).replace('####',comments);               
                            }else{
                                notificationTxt = Label.ECM_Contract_Push_Notification_Generic_Message.replace('@@@@',newContarctObj.ContractNumber).replace('*****',mapConIdApprovalRejectedLog.get(newContarctObj.Id).ECM_Contract__r.Account.Name);                            	
                            	notificationTxt = notificationTxt + ' ' +Label.ECM_Contract_Push_Notification_Rejected_Message.replace('&&&&',email).replace('####',comments);
                            }								                            
                        }
                custom.put('ContractId',newContarctObj.Id);
                custom.put('OutletId',newContarctObj.AccountId);
                custom.put('OwnerId',newContarctObj.OwnerId);
                System.debug('@@notificationTxt' +notificationTxt);
                EDGE_PushNotificationHelper.pushNotificationMethod(null, notificationTxt, custom);           
            }
            ContractTriggerHandler.isFirstTime = false;
        }        
    }

/**
* @description : sendEmailNotificationToCustomer - Send Email Notification to Customer (ECM-4884)
* @return : void
* @param : Map <Id, sObject>, Map < Id, sObject >
*/

    public static void sendEmailNotificationToCustomer(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map <Id,Contract> mapnewItems = (Map<Id,Contract>) newItems;
        Map <Id,Contract> mapoldItems = (Map<Id,Contract>) oldItems;
        set <Id> contractIds =new set <Id> ();
        
        try{
            
            for(Contract con: 
                [SELECT Id,ECM_Agreement_Type__c,ECM_Amended__c,
                 Account.Country__r.Code__c,
                 ECM_Agreement_Type__r.ECM_Contract_Approval_mail_to_Customer__c,
                 AccountId,Account.Email_for_contracts_payments__c,
                 OwnerId,Owner.Email 
                 FROM Contract
                 WHERE Id IN:mapnewItems.values()]){
                     //ECM-6380
                     if(mapoldItems.get(con.Id).Status != mapnewItems.get(con.Id).Status &&
                        mapnewItems.get(con.Id).Status == 'Approved' && !(con.ECM_Amended__c) &&
                        con.ECM_Agreement_Type__r.ECM_Contract_Approval_mail_to_Customer__c && 
                        con.Account.Email_for_contracts_payments__c != null){
                            contractIds.add(con.Id);                        
                        }
                 }
            
            if(contractIds.size() > 0){
                sendEmail(contractIds); 
                //ECM-5089
                isTriggered = false;
            }

        }catch(Exception contractException){
            System.debug('Class:EDGE_ContractTriggerHelper\nmethod:sendEmailNotificationToCustomer\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
        }
    }
/**
* @description : sendEmail - Send Email Notification to Customer  future method(ECM-4925 & ECM-4891)
* @return : void
* @param : set<Id>
*/
    
@future(callout=true)
    public static void sendEmail(set<Id> contractIds){
        
        try{
            List <Contract> contractList = new List <Contract> ();
            set <String> countryCodes = new Set <String> ();
            Map <String,Messaging.EmailFileAttachment> mapOfTnCAttach = new Map <String,Messaging.EmailFileAttachment> ();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Map <Id,Market_Setting__c> mapOfMarketSetting;
            
            Id contractApproverId = [select Id,Address from OrgWideEmailAddress where Address =:Label.ECM_ContractApproverOrgWideEmail].Id;
            Id emailTemplateId = [Select Id,Name,DeveloperName from EmailTemplate where DeveloperName =:Label.ECM_Approval_Email_to_Customer_Template_Name].Id;
            
            //changes related to ECM-4925
            for(Contract con: 
                [SELECT Id,ECM_Agreement_Type__c,
                 Account.Country__r.Code__c,
                 ECM_Agreement_Type__r.ECM_Contract_Approval_mail_to_Customer__c,
                 ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c,
                 AccountId,Account.Email_for_contracts_payments__c,
                 OwnerId,Owner.Email,Owner.Name 
                 FROM Contract
                 WHERE Id IN:contractIds]){
                     countryCodes.add(con.Account.Country__r.Code__c);
                     contractList.add(con);
                 }
            
            mapOfMarketSetting = new Map <Id,Market_Setting__c> ([SELECT Id, Name, Geography__r.Code__c 
                                                                  FROM Market_Setting__c 
                                                                  WHERE Geography__r.Code__c IN:countryCodes]); 
            
            for(ContentDocumentLink  existConDoc : 
                [SELECT Id, LinkedEntityId, ContentDocumentId, 
                 ContentDocument.FileExtension, ContentDocument.Title,
                 ContentDocument.LatestPublishedVersion.Content_Type__c,
                 ContentDocument.LatestPublishedVersion.VersionData
                 FROM ContentDocumentLink 
                 WHERE LinkedEntityId IN :mapOfMarketSetting.keySet()]){
                     if(Label.ECM_MarketSettingContentTypesForRestriction.contains(existConDoc.ContentDocument.LatestPublishedVersion.Content_Type__c)){
                         Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                         attach.setFileName(existConDoc.ContentDocument.Title+'.'+existConDoc.ContentDocument.FileExtension);
                         attach.setBody(existConDoc.ContentDocument.LatestPublishedVersion.VersionData);
                         mapOfTnCAttach.put(mapOfMarketSetting.get(existConDoc.LinkedEntityId).Geography__r.Code__c ,attach);
                     }
                     
                 }
            //end of changes ECM-4925
            
            
            for(Contract con: contractList){                
                // ECM-4644
                String Status = 'Approved';
            	Messaging.EmailFileAttachment attach = ECM_ApprovalLogUtility.contractPdf(con,Status,null);  
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(con.OwnerId);
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(con.Id);
                email.setOrgWideEmailAddressId(contractApproverId);
                email.setTemplateID(emailTemplateId);
                email.setSaveAsActivity(false);                      
                if(mapOfTnCAttach.containsKey(con.Account.Country__r.Code__c)){
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{attach,mapOfTnCAttach.get(con.Account.Country__r.Code__c)});
                    hasTnC = true;//check added for ECM-4945
                }else{
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
                    hasTnC = false;//check added for ECM-4945
                }

                email.setReplyTo(Label.ECM_CustomerResponseEmailServiceAddress);//ECM-5904
                email.setToAddresses(new list<String>{con.Account.Email_for_contracts_payments__c});
                email.setCcAddresses(new list<String>{con.Owner.Email}); 
                salesRepEmail=con.Owner.Email;//ECM-4945 
                System.debug('1103'+salesRepEmail);
                //salesRepEmailName = salesRepEmail.substringBefore('@');//ECM-4945
                salesRepEmailName=con.Owner.Name;//ECM-4945 
                countryCode =con.Account.Country__r.Code__c;//added for ECM-6679
                Map<String,String> PaysumVolumeMapmdt= new Map<String,String> ();
                mails.add(email);
            }
            if(mails.size() > 0){
                Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);                
            }
        }catch(Exception contractException){
            System.debug('Class:EDGE_ContractTriggerHelper\nmethod:sendEmail\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
        }
        
    }
    
}