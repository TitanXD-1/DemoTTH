/**
* @Name: D1_AddWholesalerController
* 
* Purpose: Controller class for Add Wholesaler functionality
* 
* History                                                            
* -                                                           
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		Subhrojit Majumdar		21/09/2022		NCP-7289
**/

public without sharing class D1_AddWholesalerController {
    
    //get Record Type Id for Distributor/Wholesaler Accounts
    static String wholesalerRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
    
	/**
     * Get current user
     * @userStory NCP-7289 
     * @param {Id} userId
     * @return {User}
     */
    public static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;
        
        List<User> users = [SELECT id, Effective_Account_Id__c, Available_Countries__c, ContactId
                            FROM User
                            WHERE id=: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users[0];
    }
    
    /**
     * Get list of distributor/wholesaler accounts
     * @userStory NCP-7289 
     * @param {Id} userId
     * @return {List<Account>}
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getWholesalerMasterList(Id userId){
        //Fetch Current User
        User currentUser = getCurrentUser(userId);
        List<String> availableCountry = currentUser.Available_Countries__c != NULL ? currentUser.Available_Countries__c.split(';') : new List<String>();
        
        List<Account> wholesalers = [SELECT Id, Name, Status__c, BillingAddress, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                                     FROM Account 
                                     WHERE RecordTypeId =: wholesalerRecordTypeId
                                     AND Status__c = 'Active' 
                                     AND Country__r.Code__c IN :availableCountry 
                                     AND Id NOT IN (SELECT Distributor_Wholesaler__c FROM Supplier_Outlet__c WHERE Outlet__c =:currentUser.Effective_Account_Id__c)];
        
        return wholesalers;
    }
    
    /**
     * Check maximum preferred limit of wholesalers and/or save new supplier outlet record
     * @userStory NCP-7289 
     * @param {Id, String, Boolean, Id} wholesSalerId, wholeSalerNumber, preferred, userID
     * @return {Boolean}
     */
    @AuraEnabled
    public static Boolean saveSupplierOutletRecord(ID wholesSalerId, String wholeSalerNumber, Boolean preferred, ID userID){
        try{
            Integer maxLimit = Integer.valueOf(System.label.D1_Max_Preferred_Wholesaler_Limit);
            User currentUser = getCurrentUser(userId);

            if(preferred){
                List<AggregateResult> countOfPreferred = [SELECT COUNT(Id)numberOfWholesalers FROM Supplier_Outlet__c WHERE Outlet__c =: CurrentUser.Effective_Account_Id__c AND Distributor_Wholesaler__c != null AND Preferred_Wholesaler__c = true];
                if(Integer.valueOf(countOfPreferred[0].get('numberOfWholesalers')) + 1 > maxLimit){
                    return false; //Return false if maximum preferred limit is reached
                }
            }

            if(wholesSalerId != null){
                Supplier_Outlet__c newSupplierOutlet = new Supplier_Outlet__c();
                newSupplierOutlet.Distributor_Wholesaler__c = wholesSalerId;
                newSupplierOutlet.Wholesaler_Account_Number__c = wholeSalerNumber;
                newSupplierOutlet.Preferred_Wholesaler__c = preferred;
                newSupplierOutlet.Outlet__c = CurrentUser.Effective_Account_Id__c;
                upsert newSupplierOutlet;
                return true; //Return true on saving new record successfully
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return false;
    }
}