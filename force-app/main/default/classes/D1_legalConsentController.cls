/*
* @name: D1_legalConsentController
* @discription: D1_legalConsentController Class for Consent PopUp on the home page
* @history
* VERSION     AUTHOR           DATE          DETAIL
* 1.0         Manikant         18/11/2020    Initial Development(NCP-871): Methods : getSubscriptionStatus , setSubscription 
*/

public without sharing  class D1_legalConsentController {
    
    // To check whether the user is subscribed or not 
    @AuraEnabled(cacheable = true)
    public static boolean getSubscriptionStatus(){
        List<User> usrList = new List<user>();
        Boolean isSubscribed = false ;
            usrList = [Select Id, ContactId, Contact.MD_SubscriptionDate__c FROM User where id =:UserInfo.getUserId()];
        if(usrList[0].ContactId != null){
            isSubscribed = usrList[0].Contact.MD_SubscriptionDate__c == NULL ? True : False; 
        }
        return isSubscribed;
    }
    
    // To update the Contact Subscription values 
    @AuraEnabled
    public  static void  setSubscription(String allSubscriptionString){
        List<User> usrList = new List<user>();
        usrList = [Select Id, ContactId, Contact.MD_SubscriptionDate__c,Contact.MD_ContactSubscriptions__c FROM User where id =:UserInfo.getUserId()];
        if( allSubscriptionString != null){
            Contact conRec = new Contact(ID =usrList[0].ContactId);
            conRec.MD_ContactSubscriptions__c = allSubscriptionString;
            conRec.MD_SubscriptionDate__c = Datetime.now();
            update conRec;
        }
    }
    
}