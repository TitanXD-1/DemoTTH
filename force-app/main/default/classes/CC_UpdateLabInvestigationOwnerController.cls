public without sharing class CC_UpdateLabInvestigationOwnerController {

    @AuraEnabled
    public static string getUpdateInvestigationOwner(String InvestigationId)
    {
        if(!String.isBlank(InvestigationId))
        {
            CC_Investigation__c labInvest= [select Id,CC_Case__c, CC_Case__r.OwnerId, CC_Case__r.CC_Market__c, CC_Case__r.CC_Market__r.CC_CCC__c, OwnerId
                                            from CC_Investigation__c 
                                            Where Id =:InvestigationId];
            //changes done by support--start
            Database.DmlOptions options = new Database.DmlOptions();
 options.emailHeader.triggerUserEmail = true;
            //stop
            if(labInvest.CC_Case__c != null)
                labInvest.OwnerId = labInvest.CC_Case__r.OwnerId;
         //   update labInvest;  commented by salesforce support
         Database.update(labInvest, options);// written by salesforce support
            return labInvest.OwnerId;
        }
        return null;
    }
}