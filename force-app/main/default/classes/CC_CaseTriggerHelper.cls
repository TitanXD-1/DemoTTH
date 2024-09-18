/**********************************************************************
Name: CC_CaseTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for Cases for Customer Concerns
=======================================================================
History                                                            
-------                                                            
VERSION         AUTHOR          DATE            DETAIL
1.0             Bhargav S       16/03/2021      Initial Development
***********************************************************************/
public class  CC_CaseTriggerHelper {
    
/*******************************************************************
Method  : assignCSEandCCC
Purpose : This method is used to assign the CSE and CCC to the Case based on the Account/Market populated
********************************************************************/
    public static void initialMethod(List<SObject> newItems){
        List<SObject> CC_relevant_records = new List<SObject>();
        Id CC_ConsumerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        Id CC_CustomerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Concern').getRecordTypeId();
        for(SObject o : newItems){
            Case c = (Case)o;
            if(c.RecordTypeId == CC_ConsumerConcernRT || c.RecordTypeId == CC_CustomerConcernRT)
                CC_relevant_records.add(o);
        }
        if(CC_relevant_records.size()>0){
            assignCSEandCCC(CC_relevant_records);
            updateEntitlementName(CC_relevant_records);
        }
    }
    
    
/*******************************************************************
Method  : assignCSEandCCC
Purpose : This method is used to assign the CSE and CCC to the Case based on the Account/Market populated
********************************************************************/
    public static void assignCSEandCCC(List<SObject> items){
        Set<Id> accountIds = new Set<Id>();
        for(SObject o : items){
            Case c = (Case)o;
            accountIds.add(c.CC_Market__c);
        }
        
        if(accountIds.size()>0){
            Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id, CC_CCC__c, CC_CCC__r.Email, CC_CSE__c, CC_CSE__r.Email
                                                           FROM Account WHERE Id IN : accountIds]);
            
            String unassignedConcernsQueueName = Label.Customer_Concerns;
            List<Group> unassignedConcerns = [SELECT Id FROM Group
                                              WHERE Type='Queue'
                                              AND DeveloperName=:unassignedConcernsQueueName];
            for(SObject o : items){
                Case c = (Case)o;
                if(accMap.containsKey(c.CC_Market__c)
                   && accMap.get(c.CC_Market__c).CC_CCC__c!=null
                   && accMap.get(c.CC_Market__c).CC_CSE__c!=null){
                    c.OwnerId = accMap.get(c.CC_Market__c).CC_CCC__c;
                    c.CC_CSE__c = accMap.get(c.CC_Market__c).CC_CSE__c;
                }else{
                    c.OwnerId = unassignedConcerns[0].Id;
                }
            }
        }
    }
    
    public static void updateEntitlementName(List<SObject> items){
        try{
            //Get Entitlement process SLA Process 
            String entitlementName = Label.CC_Entitlement_Name;
            List<SlaProcess> cc_Sla = new List<SlaProcess>([SELECT Id From SlaProcess where Name = :entitlementName  AND IsActive = True Limit 1]);
            
            //Get Entitlement Record
            List<Entitlement> cc_Entitlement = new List<Entitlement>();
            if(cc_Sla.size()>0){
                cc_Entitlement=[SELECT id from Entitlement where SlaProcessId IN:cc_Sla Limit 1];
            }
            
            for(SObject obj : items){ 
                Case caseObj = (Case)obj;
                if(cc_Entitlement.size()>0){
                    caseObj.EntitlementId=cc_Entitlement[0].Id;
                }
            }
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
        }
    }
    
    public static void closeMileStone(List<SObject> items){
        List<Id> caseIds = new List<Id>();
        for(SObject obj : items){
            Case caseObj = (Case)obj;
            caseIds.add(caseObj.Id);
        }
        List<CaseMilestone> caseMileStones = [SELECT Id, completionDate 
                                              FROM CaseMilestone 
                                              WHERE CaseId = :caseIds AND IsCompleted =False
                                              AND completionDate = null];
        for(CaseMilestone cm : caseMileStones){
            cm.completionDate = System.now();
        }
        update caseMileStones;
     
        
        
    }
    /* This method used to update concern status from case*/
    public static void updateconcernsstatus(List<SObject> items){
        Map<string,Case> casemap=New Map<String,Case>();
        List<CC_Customer_Concern__c> tobeupdatedList =New List<CC_Customer_Concern__c>();
        for(SObject obj : items){
            Case caseObj = (Case)obj;
            casemap.put(caseObj.Id,caseObj);
        }
        
        List<CC_Customer_Concern__c> concernList=[Select Id,CC_Status__c,CC_Case__c from CC_Customer_Concern__c where CC_Case__c In:casemap.keyset()];
        if(concernList.size()>0){
            for(CC_Customer_Concern__c cc:concernList){
                cc.CC_Status__c =casemap.get(cc.CC_Case__c).Status;
                tobeupdatedList.add(cc);
            }
        }
        try{
        	update tobeupdatedList;  
        }catch(exception e){
            system.debug('error is'+e.getMessage());
        }
        
    }
    
    public static void sendemailtoContacts(Map<string,List<String>> caseemailmap){
        
        for(case cs:[Select Id, CaseNumber,Owner.name,CC_Security_Manager__r.Email,
                             CC_Insurance_manager__r.Email,CC_Customer_Care_Co_ordinator__r.Email,CC_Security_Manager__c,CC_Insurance_manager__c,
                             CC_Customer_Care_Co_ordinator__c,other__r.Email
                             from Case where Id In:caseemailmap.keyset()]){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            EmailTemplate emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where DeveloperName = 'Email_to_Case_Contacts'];
           	String plainText = emailTemplate.Body;
            String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ cs.Id;
			String stringURL  = '<a href='+fullFileURL+' >click here</a>';
            plainText = plainText.replace('user,', 'user,<br/><br/>');
            plainText = plainText.replace('Thanks,', 'Thanks,<br/>');
            plainText = plainText.replace('open case', 'open case<br/><br/>');
            plainText = plainText.replace('{!Case.CaseNumber}', cs.CaseNumber+'<br/>');
            plainText = plainText.replace('{!Case.OwnerFullName}', cs.Owner.Name);
            plainText = plainText.replace('{!Case.Id}', stringURL);
            email.setSubject('Case assignment notification-'+cs.CaseNumber);
            email.setHtmlBody(plainText);
            email.setSaveAsActivity(false);
            List<string> toaddress=New List<String>();
            for(string str :caseemailmap.get(cs.Id)){
                if(cs.CC_Security_Manager__c ==str){
                    toaddress.add(cs.CC_Security_Manager__r.Email);
                }
                if(cs.CC_Insurance_manager__c ==str){
                    toaddress.add(cs.CC_Insurance_manager__r.Email);
                }
                if(cs.CC_Customer_Care_Co_ordinator__c ==str){
                    toaddress.add(cs.CC_Customer_Care_Co_ordinator__r.Email);
                }
                if(cs.Other__c ==str){
                    toaddress.add(cs.other__r.Email);
                }
            }
            email.setToAddresses(toaddress);
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                email
                    });
        }
        
    }
    
    public static void ccAfterupdatehandler(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
         List<SObject> CC_relevant_records = new List<SObject>();
        List<SObject> cc_statusrelevantrecs =New List<SObject>();
        Map<String,List<String>> cc_emailReleventrecords =New Map<String,List<String>>();
        Id CC_ConsumerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        Id CC_CustomerConcernRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Concern').getRecordTypeId();
        
        for(SObject o : newItems.values()){
            Case c = (Case)o;
            Case oldCase = (Case)oldItems.get(c.Id);
            Date oldReceivedFromInv = oldCase.CC_Received_from_Investigation__c; 
            if((c.RecordTypeId == CC_ConsumerConcernRT || c.RecordTypeId == CC_CustomerConcernRT) 
               && c.CC_Received_from_Investigation__c != oldReceivedFromInv && c.SlaExitDate == null){
                CC_relevant_records.add(o);
            }
            if(c.RecordTypeId == CC_ConsumerConcernRT || c.RecordTypeId == CC_CustomerConcernRT){
                if(c.Status !=oldCase.Status){
                cc_statusrelevantrecs.add(o);
                }
                
                if(c.CC_Security_Manager__c !=oldCase.CC_Security_Manager__c && c.CC_Security_Manager__c !=null){
                    if(!cc_emailReleventrecords.containskey(c.Id)){
                        cc_emailReleventrecords.put(c.Id,new List<string>());
                        cc_emailReleventrecords.get(c.Id).add(c.CC_Security_Manager__c);
                    }
                    else{
                        cc_emailReleventrecords.get(c.Id).add(c.CC_Security_Manager__c);
                    }
                    
                }
                if(c.CC_Insurance_manager__c !=oldCase.CC_Insurance_manager__c && c.CC_Insurance_manager__c!=null){
                    if(!cc_emailReleventrecords.containskey(c.Id)){
                        cc_emailReleventrecords.put(c.Id,new List<string>());
                        cc_emailReleventrecords.get(c.Id).add(c.CC_Insurance_manager__c);
                    }else{
                        cc_emailReleventrecords.get(c.Id).add(c.CC_Insurance_manager__c);
                    }
                }
                if(c.CC_Customer_Care_Co_ordinator__c !=oldCase.CC_Customer_Care_Co_ordinator__c && c.CC_Customer_Care_Co_ordinator__c!=null){
                   if(!cc_emailReleventrecords.containskey(c.Id)){
                       cc_emailReleventrecords.put(c.Id,new List<string>());
                       cc_emailReleventrecords.get(c.Id).add(c.CC_Customer_Care_Co_ordinator__c);
                   }else{
                       cc_emailReleventrecords.get(c.Id).add(c.CC_Customer_Care_Co_ordinator__c);
                   }
                }
                if(c.Other__c !=oldCase.Other__c && c.Other__c!=null){
                  if(!cc_emailReleventrecords.containskey(c.Id)){
                       cc_emailReleventrecords.put(c.Id,new List<string>());
                       cc_emailReleventrecords.get(c.Id).add(c.Other__c);
                  }else{
                       cc_emailReleventrecords.get(c.Id).add(c.Other__c);
                  }
                }
            }
            
        }
        if(CC_relevant_records.size()>0)
            CC_CaseTriggerHelper.closeMileStone(CC_relevant_records);
        
        if(cc_statusrelevantrecs.size()>0){
            CC_CaseTriggerHelper.updateconcernsstatus(cc_statusrelevantrecs);
        }
        
        if(!cc_emailReleventrecords.isEmpty()){
            CC_CaseTriggerHelper.sendemailtoContacts(cc_emailReleventrecords);
        }
    }
    //PION-2574 - CCC profile users are prevented from changing Case record type
    public static void readOnlyRecordType(Map<Id, SObject> oldItems,Map<Id, SObject> newItems){
        List<SObject> caseNewList= new List<SObject>(newItems.values());
        List<SObject> caseOldList= new List<SObject>(oldItems.values());
        Map<Id,Case> caseOldMap =new Map<Id,Case>();
        for(SObject obj : caseOldList){
             Case caseObj = (Case)obj;
             caseOldMap.put(caseObj.id,caseObj);
        }
        Id userProfileId = UserInfo.getProfileId();
        Id repProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'CC Customer Care Coordinator'].Id;
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        if(userProfileId == repProfileId){
            for(SObject obj : caseNewList){
                Case caseObj = (Case)obj;
                if(caseObj.RecordTypeId != caseRecordTypeId && caseObj.RecordTypeId != caseOldMap.get(caseObj.id).RecordTypeId){
                    caseObj.addError('You cannot change the Case Record type');
                }
            }  
        }        
    }
    
}