public class MD_FormRegistrationController {


    public class ClusterWrapper{
        @AuraEnabled public Id ClusterId;
        @AuraEnabled public String ClusterName;
        @AuraEnabled public String CountryCode;
    }

    @AuraEnabled
    public static DiageoCMS.GeneralForm getFormData(String countryCode, Id cId){
     
        List<MD_RegistrationFormsMapping__mdt> Reg = [SELECT Id, FormExternalId__c FROM MD_RegistrationFormsMapping__mdt WHERE CountryCode__c =: countryCode ORDER BY Order__c ASC];
        DiageoCMS.GeneralForm generalForm = new DiageoCMS.GeneralForm(Reg[0].FormExternalId__c, new Set<Id>{cId});
        return generalForm;
    }

    @AuraEnabled
    public static DiageoCMS.GeneralForm getAdditionalFormData(String countryCode, Id cId){
        List<MD_RegistrationFormsMapping__mdt> Reg = [SELECT Id, FormExternalId__c FROM MD_RegistrationFormsMapping__mdt WHERE CountryCode__c =: countryCode ORDER BY Order__c ASC];
        DiageoCMS.GeneralForm generalForm = new DiageoCMS.GeneralForm(Reg[1].FormExternalId__c, new Set<Id>{cId});
        return generalForm;
    }
    
     @AuraEnabled
    public static List<ClusterWrapper> getClusterData(){
        List<DiageoCMS__Cluster__c> Clusters = [SELECT Id, Name, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c where RecordType.DeveloperName = 'ClusterLeaf' and DiageoCMS__ExternalId__c = 'ES'];
        List<ClusterWrapper> ClusterList = new List<ClusterWrapper>();

        for(DiageoCMS__Cluster__c c: Clusters){
            ClusterWrapper Wrapper = new ClusterWrapper();
            Wrapper.ClusterId = c.Id;
            Wrapper.ClusterName=c.Name;
            Wrapper.CountryCode=c.DiageoCMS__ExternalId__c;
            ClusterList.add(Wrapper);
        }
        return ClusterList;
        
    }
    @AuraEnabled
    public static DiageoCMS.FormResponseWrapper saveContact(String formSettings, String contactData, String accountData, String countryCode){
            Map<String, SObject> formData = new Map<String, SObject>();
            Geography__c geo = new Geography__c();
            
            geo.Code__c = countryCode;
            Account acc = (Account)JSON.deserialize(accountData, Account.class);
            Contact con = (Contact)JSON.deserialize(contactData, Contact.class);


            con.Mobile__c = con.Mobile__c.replace(con.MobilePrefix__c, '');

            formData.put('Contact', con);
            formData.put('Account',acc);
            formData.put('Geography__c', geo);

			return DiageoCMS.GeneralForm.saveForm(formSettings, formData);
    }

      @AuraEnabled
    public static DiageoCMS.FormResponseWrapper saveContactExtended(String formSettings, String contactData, String accountData, string vatNumber, string countryCode){
            Map<String, SObject> formData = new Map<String, SObject>();

            Geography__c geo = new Geography__c();
            geo.Code__c = countryCode;

            Account acc = (Account)JSON.deserialize(accountData, Account.class);
            acc.Vat_Number__c = vatNumber;

            Contact con = (Contact)JSON.deserialize(contactData, Contact.class);

            con.Mobile__c = con.Mobile__c.replace(con.MobilePrefix__c, '');

            formData.put('Contact', con);
            formData.put('Account',acc);
            formData.put('Geography__c', geo);

			return DiageoCMS.GeneralForm.saveForm(formSettings, formData);
    }
}