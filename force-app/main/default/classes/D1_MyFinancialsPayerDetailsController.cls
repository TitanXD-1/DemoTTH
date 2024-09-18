/*
* @name: D1_MyFinancialsPayerDetailsController
* @discription: Controller for MyFinancialsPlayerDetails lwc
* History
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Gaurav          12/03/21    NCP-1475
* 2.0         Gaurav          24/03/21    NCP-2050, NCP-2388
*/
public without sharing class D1_MyFinancialsPayerDetailsController {
    public static final String PAYER = 'Payer';

    /**
     * Get Player Financial Info
     * @param {Id} userId
     */
    @AuraEnabled(cacheable=true)
    public static MyFinancialPayerInit_Wrapper getPayerFinancialInfo( Id userId ) {
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }

        List<User> users = [SELECT Id,AccountId,ContactId,Account.Name,Account.KUNNR__c,Available_Countries__c,LanguageLocaleKey,D1_User_Type_Id__c,Effective_Account_Id__c FROM User WHERE id =: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied. User Not found.');
        }
        
        User currentUser = users[0];
        
        List<PNR_Partner_Function__c> partnerFunctions = [SELECT id, PNR_Customer_No__c, PNR_Customer_No__r.Name, PNR_Customer_No__r.KUNNR__c,
                                                          PNR_Distribution_Channel__c, PNR_Division__c, PNR_Sales_Org__c 
                                                          FROM PNR_Partner_Function__c
                                                          WHERE PNR_Sold_To__c  =: currentUser.Effective_Account_Id__c
                                                          AND PNR_Type__c =: PAYER
                                                          LIMIT 1];
        
        if(partnerFunctions.isEmpty()){
            throw new AuraHandledException('Access Denied. Partner Function Not found.');
        }

        Map<Id,PNR_Partner_Function__c> customerPfMap = new Map<Id,PNR_Partner_Function__c>();
        for( PNR_Partner_Function__c pf : partnerFunctions ){
            customerPfMap.put( pf.PNR_Customer_No__c, pf);
        }

        List<AccountContactRelation> partnerFunctionsACR = [SELECT id, AccountId, D1_Active__c
                                                          FROM AccountContactRelation
                                                          WHERE AccountId  IN: customerPfMap.keyset()
                                                          AND ContactId =: currentUser.ContactId
                                                          AND D1_Active__c = True
                                                          AND D1_Roles__c INCLUDES ('Account Balances')
                                                          LIMIT 1];
        
        if(partnerFunctionsACR.isEmpty()){
            throw new AuraHandledException('Access Denied. ACR for Partner Function Not found.');
        }

        //List<String> availableCountry= currentUser.Available_Countries__c!=Null?currentUser.Available_Countries__c.split(','):new List<String>();
        
        List<D1_User_Type__c> d1UserTypes = [Select id, D1_Setting__c,
                                           D1_Setting__r.Display_Account_Balance__c, D1_Setting__r.Display_Credit_limit__c, 
                                           D1_Setting__r.Display_Credit_limit_Exposure__c, D1_Setting__r.Display_Amount_Due__c, 
                                           D1_Setting__r.Display_Last_Payment_Received__c
                                           from D1_User_Type__c 
                                           where id =:currentUser.D1_User_Type_Id__c];
        if(d1UserTypes.isEmpty()){
            throw new AuraHandledException('Access Denied. D1 User Type Not found.');
        }
        
        D1_PayerFinancialDetails.CustomerFinance_Response_Wrapper payerFinancialInfo;
        PNR_Partner_Function__c partnerFunction = customerPfMap.get(partnerFunctionsACR[0].AccountId);
        if( d1UserTypes[0].D1_Setting__r.Display_Account_Balance__c || d1UserTypes[0].D1_Setting__r.Display_Credit_limit__c || 
           d1UserTypes[0].D1_Setting__r.Display_Credit_limit_Exposure__c || d1UserTypes[0].D1_Setting__r.Display_Amount_Due__c || 
           d1UserTypes[0].D1_Setting__r.Display_Last_Payment_Received__c ){
            payerFinancialInfo = D1_PayerFinancialDetails.getPayerFinancialInfo( partnerFunction.PNR_Customer_No__r.KUNNR__c, partnerFunction.PNR_Sales_Org__c, partnerFunction.PNR_Distribution_Channel__c, partnerFunction.PNR_Division__c );
        }

        MyFinancialPayerInit_Wrapper initWrap = new MyFinancialPayerInit_Wrapper();
        initWrap.customerNumber = partnerFunction.PNR_Customer_No__r.KUNNR__c;
        initWrap.customerName = partnerFunction.PNR_Customer_No__r.Name;
        initWrap.payerFinancialInfo = payerFinancialInfo;
        initWrap.d1Setting = (D1_Setting__c)d1UserTypes[0].getsObject('D1_Setting__r');
        return initWrap;
    }

    /**
     * Wrapper class to Store User's Financial Info
     */
    Public class MyFinancialPayerInit_Wrapper{
        @AuraEnabled public String customerNumber;
        @AuraEnabled public String customerName;
        @AuraEnabled public D1_PayerFinancialDetails.CustomerFinance_Response_Wrapper payerFinancialInfo;
        @AuraEnabled public D1_Setting__c d1Setting;
    }

}