public class LookupSearchComponentController {
    
    @AuraEnabled
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        string recTypefilter = '';
        string usrfilter = '';
        String countryName = '';
        String filter = '';
        User usrobj=[Select Id,Name,Available_Countries__c from User where id=:Userinfo.getUserId()];
        if(ObjectName == 'User'){
            usrfilter='Profile.Name ='+'\''+'Legal User'+'\'';
            countryName='Available_Countries__c ='+'\''+usrobj.Available_Countries__c+'\'';                  
        }
        if(ObjectName == 'Pick_Up_Options__c'){
            recTypefilter='RecordTypeId ='+'\''+Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId()+'\'';
        }
        if(ObjectName == 'ECM_Internal_Order__c')
        {
            filter = 'ECM_Auto_Assignment__c = false';
        }
        for(sObject so : Database.Query('Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+(recTypefilter!=''?recTypefilter+' AND ':'')+(usrfilter!=''?usrfilter+' AND ':'')+(countryName!=''?countryName+' AND ':'')+(filter!=''?filter+' AND ':'')+fieldName+' LIKE \'%' + value + '%\'')) {
            String fieldvalue = (String)so.get(fieldName);
            sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
        }
        
        return sObjectResultList;
    }
    
    //method to get list of accounts
    @AuraEnabled
    public static List<Account> getAccountsResult(String value, String terrtoryId){
        String outletRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        User loggedUser = [Select Id,Name,Profile.Name,Available_Countries__c from User Where Id =:userinfo.getUserId() Limit 1];
        String query='';
        system.debug(loggingLevel.ERROR,'----terrtoryId'+terrtoryId);
        if(outletRecordTypeID !=null && terrtoryId!=null && loggedUser.Profile.Name == System.Label.ECM_Profile_ActivationSpecialist){//146039
            query = 'Select id,Name,BillingStreet, BillingCity, BillingState,Global_Channel__c,Hybrid__c,Parent_Outlet__c From Account '+
                        'Where  Activation_Territory_LT__c=\''+terrtoryId+'\' AND RecordTypeID=\''+outletRecordTypeID+'\' AND '+
                        '((Name like \'%'+value+'%\') OR (BillingStreet like \'%'+value+'%\') OR (BillingCity like \'%'+value+'%\') OR (BillingState like \'%'+value+'%\'))';
        } else if(outletRecordTypeID !=null && terrtoryId!=null){
            query = 'Select id,Name,BillingStreet, BillingCity, BillingState,Global_Channel__c,Hybrid__c,Parent_Outlet__c From Account '+
                        'Where  Primary_Sales_Territory__c=\''+terrtoryId+'\' AND RecordTypeID=\''+outletRecordTypeID+'\' AND '+
                        '((Name like \'%'+value+'%\') OR (BillingStreet like \'%'+value+'%\') OR (BillingCity like \'%'+value+'%\') OR (BillingState like \'%'+value+'%\'))';
        }
        system.debug(loggingLevel.ERROR,'-----query---'+query);
        List<Account>lstAccount = Database.query(query);
        List<Account> tobereturnedList=New List<Account>();
        for(Account acc:lstAccount){
            if(acc.Hybrid__c !=false){
                tobereturnedList.add(acc);               
            } 
            else if(acc.Global_Channel__c!='Off Trade'){
              tobereturnedList.add(acc);  
            }
        }
        system.debug(logginglevel.ERROR,'---lstAccount----'+lstAccount);
        return tobereturnedList;
    }
    public class SObJectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
    }
}