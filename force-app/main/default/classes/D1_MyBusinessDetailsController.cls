/*
* @name: D1_MyBusinessDetailsController
* @discription: D1_MyBusinessDetailsController Class for My Business Detail page 
* @History
* VERSION      AUTHOR           DATE              DETAIL
* 1.0           Ajay            10/6/20      Initial Development(NCP-633)
* 2.0           Rubeena         3/5/21       Changes for making TIN as market and user type configurable(NCP-2409)
* 3.0           Gaurav          17/8/21          NCP-3698   
* 4.0        Sayan Samaddar     20/09/22         NCP-6977
* 5.0        Swagat/Subhrojit   19/10/22         NCP - 7415
*6.0         Supriya            2/11/22          NCP-6854
*7.0         Rajesh             6/12/23			NCP-8272
*/
public without sharing class D1_MyBusinessDetailsController {

    /**
     * @description : This method is used to get Account Details
     * @param userId 
     * @return  `List<AccountWrapper>`
     * @exception 
     */
    @AuraEnabled
    public static List<AccountWrapper> getDirectAndIndirectAccounts(Id userId){
        final String SOLD_TO = 'Sold-To' ;//NOPMD
        final String SHIP_TO = 'Ship-To' ;//NOPMD
        final String PAYER = 'Payer' ;//NOPMD
        string customerBillingAddress;
        Boolean isDirectAccount;
        Boolean isName2ValueCheck;
        List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
        
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }
        
        List<User> users = [SELECT Id,AccountId,Account.Name,Account.KUNNR__c,Effective_Account_Id__c,Available_Countries__c,D1_User_Type__c,LanguageLocaleKey,D1_User_Type_Id__c   FROM User WHERE id =: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }
        User currentUser = users[0];
        Id currUserAccountId = currentUser.Effective_Account_Id__c;//NOPMD
        
        List<String> availableCountry= currentUser.Available_Countries__c!=Null?currentUser.Available_Countries__c.split(';'):new List<String>();
        
        //NCP-6563 - Updated D1 setting query added language filter as well
        List<D1_Setting__c> d1Setting = [SELECT Id,Name_2_value__c FROM D1_Setting__c where Market__r.Code__c IN: availableCountry AND Language__c=:currentUser.LanguageLocaleKey limit 1];
        isName2ValueCheck = d1Setting[0].Name_2_value__c;
        
        //NCP-2409
        String queryString = 'SELECT Id,Name,Phone,Phone__c,PhonePrefix__c,Country__c,Name2__c,Direct_Customer__c,BillingPostalCode,'+  
                                        'BillingStreet,BillingCity,BillingState,'+
                                        'BillingCountry,BillingAddress,KUNNR__c,Central_Order_Block__c';
     
        Set<String> querySet = new Set <String> ();
        for(String qValue : queryString.split(',')){
            querySet.add(qvalue.trim());
        }
       
        //NCP-6563 - Updated D1 User Type query - fetching query as per user's D1 User Type ID
        //NCP-6854 - Updated D1 User Type query - fetching query as per Account_number_Identifier__c
        List<D1_User_Type__c> d1UserType = [SELECT Id, Tax_Identification_Number__c, Account_number_Identifier__c 
                                            FROM D1_User_Type__c 
                                            WHERE ID =:currentUser.D1_User_Type_Id__c];

        //NCP-6854 - if condition to check Account Identification Number is D1UserType                                   
       if(d1UserType[0].Account_number_Identifier__c != null && !querySet.contains(d1UserType[0].Account_number_Identifier__c)){
            String accIdenNum = String.escapeSingleQuotes(d1UserType[0].Account_number_Identifier__c);
            queryString += ',' + accIdenNum ;
       }
       
        if(d1UserType[0].Tax_Identification_Number__c != null && !querySet.contains(d1UserType[0].Tax_Identification_Number__c)){
                String userTaxNum = String.escapeSingleQuotes(d1UserType[0].Tax_Identification_Number__c);
                queryString += ' , ' + userTaxNum + ' FROM Account WHERE Id =:currUserAccountId LIMIT 1';  
        }
        else{
            queryString += ' FROM Account where Id =:currUserAccountId LIMIT 1';
        }
        
        List<Account> accounts = Database.query(String.escapeSingleQuotes(queryString));
        isDirectAccount = accounts[0].Direct_Customer__c;               
        if(!isDirectAccount){
            customerBillingAddress = getBillingAddress(accounts[0].BillingStreet,
                                                        accounts[0].BillingCity,
                                                        accounts[0].BillingState,
                                                        accounts[0].BillingCountry);
        }
        if(isDirectAccount){
            //NCP-2409
            String queryString2 = 'SELECT id,Sales_Area__r.Sales_Area_ID__c,PNR_Distribution_Channel__c,IsInvalid__c,PNR_Division__c,PNR_Sales_Org__c,PNR_Customer_No__c,'+
                                    'PNR_Customer_No__r.Name,PNR_Customer_No__r.Name2__c,PNR_Customer_No__r.Phone,PNR_Customer_No__r.Phone__c,PNR_Customer_No__r.PhonePrefix__c,'+
                                    'PNR_Type__c,PNR_Customer_No__r.billingPostalCode,'+
                                    'PNR_Customer_No__r.BillingAddress,PNR_Customer_No__r.BillingStreet,PNR_Customer_No__r.BillingCity,'+
                                    'PNR_Customer_No__r.BillingState,PNR_Customer_No__r.BillingCountry,PNR_Customer_No__r.KUNNR__c,PNR_Customer_No__r.Central_Order_Block__c';    //NCP-3698
            
            Set<String> querySet2 = new Set <String> ();
            for(String qValue2 : queryString2.split(',')){
                querySet2.add(qvalue2.trim());
            }
            
            if(d1UserType[0].Tax_Identification_Number__c != null && !querySet2.contains('PNR_Customer_No__r.'+d1UserType[0].Tax_Identification_Number__c)){
                String userTaxNum1 = string.escapeSingleQuotes(d1UserType[0].Tax_Identification_Number__c);
                queryString2 += ', PNR_Customer_No__r.'+ userTaxNum1 +' FROM PNR_Partner_Function__c'+ 
                                   ' WHERE PNR_Sold_To__c=:currUserAccountId AND (PNR_Type__c =: SOLD_TO OR PNR_Type__c =: SHIP_TO OR PNR_Type__c =: PAYER) AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c = False AND IsInvalid__c = False';  //NCP-3698 and //NCP-8272-Adding check To exclude closed delivery Address 
            }
            else{
                queryString2 += ' FROM PNR_Partner_Function__c WHERE PNR_Sold_To__c=:currUserAccountId AND (PNR_Type__c =: SOLD_TO OR PNR_Type__c =: SHIP_TO OR PNR_Type__c =: PAYER) AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c = False AND IsInvalid__c = False'; //NCP-3698 and //NCP-8272-Adding check To exclude closed delivery Address
            }
            
            queryString2 += ' Order By PNR_Customer_No__r.Central_Order_Block__c DESC, PNR_Customer_No__r.Name ASC'; //NCP-3698

            List<PNR_Partner_Function__c> partnerFunctions = Database.query(String.escapeSingleQuotes(queryString2));
                                          
            for(PNR_Partner_Function__c partner: partnerFunctions){
                customerBillingAddress = getBillingAddress( partner.PNR_Customer_No__r.BillingStreet,
                                                            partner.PNR_Customer_No__r.BillingCity,
                                                            partner.PNR_Customer_No__r.BillingState,
                                                            partner.PNR_Customer_No__r.BillingCountry );
 
                AccountWrapper accountWrapperObj = populateWrapperClass(partner,partner.PNR_Customer_No__r, 
                                                                        isDirectAccount, customerBillingAddress, isName2ValueCheck,d1UserType[0]);
                accountWrapperList.add(accountWrapperObj);
            }
        }
        else{
            AccountWrapper accountWrapperObj = populateWrapperClass(null, accounts[0],
                                                                    isDirectAccount, customerBillingAddress, isName2ValueCheck,d1UserType[0]);
            accountWrapperList.add(accountWrapperObj);
        }

        return accountWrapperList;            

    }

    /**
     * @description : This is helper method to create AccountWrapper instance
     * @param partner 
     * @param customer 
     * @param isDirectCustomer 
     * @param customerBillingAddress 
     * @param isName2ValueCheck 
     * @param d1UserType 
     * @return  `AccountWrapper`
     */
    public static AccountWrapper populateWrapperClass(PNR_Partner_Function__c partner, Account customer, Boolean isDirectCustomer, string customerBillingAddress,Boolean isName2ValueCheck,D1_User_Type__c d1UserType){
        string accountName2 = '';
        Schema.DescribeFieldResult fieldResult = ContactPointAddress.Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }
       
        if(partner != null && isName2ValueCheck && partner.PNR_Type__c == 'Ship-To'){ 
            accountName2 = customer.Name2__c != null ? ', ' + '<br> ' + customer.Name2__c : '';
        }
        
        AccountWrapper accountWrapperObj= new AccountWrapper();
        accountWrapperObj.accountNumber = d1UserType.Account_number_Identifier__c != null ? ((String)customer.get(d1UserType.Account_number_Identifier__c)!= null ? (String)customer.get(d1UserType.Account_number_Identifier__c) : '-'):''; //NCP-6854
        accountWrapperObj.accNumberVisibility = d1UserType.Account_number_Identifier__c != null ? true : false ; //NCP-6854
        accountWrapperObj.billingAddress = customerBillingAddress;
        accountWrapperObj.billingPostalCode = customer.billingPostalCode;
        accountWrapperObj.accountName = customer.Name + accountName2;
        accountWrapperObj.phone = customer.phone;
        accountWrapperObj.phoneCode = customer.PhonePrefix__c;
        accountWrapperObj.phoneNum = customer.Phone__c;

        accountWrapperObj.status = (customer.Central_Order_Block__c == D1_AccountTriggerHelper.ACCOUNT_CENTRAL_ORDER_BLOCK_BLOCKED? valueLabelMap.get(D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_BLOCKED) : valueLabelMap.get(D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE)); //NCP-3698
        accountWrapperObj.taxIdentification = d1UserType.Tax_Identification_Number__c != null ? (String)customer.get(d1UserType.Tax_Identification_Number__c):''; //NCP-2409
        accountWrapperObj.type = partner != null ?partner.PNR_Type__c:'';
        accountWrapperObj.isDirectCustomer = isDirectCustomer;
        return accountWrapperObj;
    }

    /**
     * @description : This is helper method to create address string
     * @param billingStreet 
     * @param billingCity 
     * @param billingState 
     * @param billingCountry 
     * @return  `string`
     */
    public static string getBillingAddress(string billingStreet, string billingCity, string billingState, string billingCountry){
        billingStreet = billingStreet != null ? billingStreet + ', ' : '';
        billingCity = billingCity != null ? billingCity + ', ' : '';
        billingState = billingState != null ? billingState + ', ' : '';
        
        String billingAddress = billingStreet  + 
                                billingCity + 
                                billingState  +
                                billingCountry ;
        return  billingAddress;                       
    }

    //NCP-6977
    /**
     * @description : This method is used to get wholesalers
     * @param isPreferredWholesaler 
     * @return  `List<WholesalerWrapper>`
     */
    @AuraEnabled
    public static List<WholesalerWrapper> getWholesalerList(Boolean isPreferredWholesaler){
        List<WholesalerWrapper> wholesalersList = new List<WholesalerWrapper>();
        
        User currentUser = [SELECT Id, Effective_Account_Id__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        Id currUserAccountId = currentUser.Effective_Account_Id__c;//NOPMD

        //Get List of Wholesaler
        String queryStr = 'SELECT Id, Wholesaler_Account_Number__c, Outlet__c, Preferred_Wholesaler__c, isPrimary__c, Distributor_Wholesaler__c, ' +
                            'Distributor_Wholesaler__r.Name, Distributor_Wholesaler__r.BillingStreet, Distributor_Wholesaler__r.BillingCity, ' +
                            'Distributor_Wholesaler__r.BillingState, Distributor_Wholesaler__r.BillingCountry FROM Supplier_Outlet__c ' +
                            'WHERE Outlet__c =:currUserAccountId';
        if(isPreferredWholesaler){
            queryStr += ' AND Preferred_Wholesaler__c = TRUE';
        }

        queryStr += ' ORDER BY Preferred_Wholesaler__c DESC, Distributor_Wholesaler__r.Name ASC';
        
        for(Supplier_Outlet__c sc : Database.query(String.escapeSingleQuotes(queryStr))){
            WholesalerWrapper wholesalerData = new WholesalerWrapper();
            wholesalerData.wholesalerName = sc.Distributor_Wholesaler__r.Name;
            wholesalerData.wholesalerAddress = getBillingAddress(sc.Distributor_Wholesaler__r.BillingStreet, sc.Distributor_Wholesaler__r.BillingCity, sc.Distributor_Wholesaler__r.BillingState, sc.Distributor_Wholesaler__r.BillingCountry);
            wholesalerData.wholesalerAccount = sc.Wholesaler_Account_Number__c != null ? sc.Wholesaler_Account_Number__c : '' ;
            wholesalerData.wholesalerPreffered = sc.Preferred_Wholesaler__c;
            wholesalerData.wholesalerIsPrimary = sc.isPrimary__c;
            wholesalerData.outletId = sc.Id;

            wholesalersList.add(wholesalerData);
        }

        return wholesalersList;
    }

    //NCP-6977
    /**
     * @description : This method is used to delete wholesaler
     * @param wholesalerId 
     * @return  `List<WholesalerWrapper>`
     * @exception 
     */
    @AuraEnabled
    public static List<WholesalerWrapper> removeWholesaler(Id wholesalerId){
        Supplier_Outlet__c sup = [SELECT id from Supplier_Outlet__c where Id=:wholesalerId Limit 1];
        try {
            delete sup;

            //Get Updated List
            List<WholesalerWrapper> wholesalersList = getWholesalerList(false);

            return wholesalersList;
        } catch (DmlException ex) {
            throw new AurahandledException('Error Details : ' + ex.getDmlMessage(0));
        }
    }

    //NCP-6977
    /**
     * @description : This method is used to update wholesaler details
     * @param wholesalersList 
     * @return  `Boolean`
     * @exception 
     */
    @AuraEnabled
    public static Boolean updateWholesalerDetails(List<WholesalerWrapper> wholesalersList){
        try {
            List<Supplier_Outlet__c> sOutletList = new List<Supplier_Outlet__c>();
            if(wholesalersList != null && wholesalersList.size()>0){
                for(WholesalerWrapper wholesaler : wholesalersList){
                    Supplier_Outlet__c sOutlet = new Supplier_Outlet__c();
                    sOutlet.Id = wholesaler.outletId;
                    sOutlet.Preferred_Wholesaler__c = wholesaler.wholesalerPreffered;
                    sOutlet.Wholesaler_Account_Number__c = wholesaler.wholesalerAccount;

                    sOutletList.add(sOutlet);
                }

                //Update sOutletList
                if(sOutletList.size()>0){
                    update sOutletList;
                }

                return true;
            }else{
                return false;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description : Account Wrapper Class
     */
    public class AccountWrapper{
        @AuraEnabled public String accountNumber{get;set;}
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public String billingAddress{get;set;}
        @AuraEnabled public String billingPostalCode{get;set;}
        @AuraEnabled public String phoneCode{get;set;}
        @AuraEnabled public String phoneNum{get;set;}
        @AuraEnabled public String phone{get;set;}
        @AuraEnabled public String taxIdentification{get;set;}
        @AuraEnabled public String status{get;set;} //NCP-3698
        @AuraEnabled public String type{get;set;}
        @AuraEnabled public Boolean isDirectCustomer{get;set;}
        @AuraEnabled public Boolean accNumberVisibility{get;set;} //NCP-6854
    }
    
    //NCP-6977
    /**
     * @description WholesalerWrapper Class
     */
    public class WholesalerWrapper{
        @AuraEnabled public Id outletId{get;set;}
        @AuraEnabled public String wholesalerName{get;set;}
        @AuraEnabled public String wholesalerAddress{get;set;}
        @AuraEnabled public String wholesalerAccount{get;set;}
        @AuraEnabled public Boolean wholesalerPreffered{get;set;}
        @AuraEnabled public Boolean wholesalerIsPrimary{get;set;}
    }
}