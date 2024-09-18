/**********************************************************************
Name: PNR_CreateContactFromEmailMessage
=======================================================================
Purpose: Trigger Helper for PNR_EmailMessageTrigger
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      	Pratik Kumar   	  15th Nov, 2021        PION: 1650 - Create Contact records for To, CC and BCC if the Contact doesnt exist
***********************************************************************/
public without sharing class PNR_CreateContactFromEmailMessage {
	public static void createContact(List<EmailMessage> emailToProcess){
        List<Id> emailSenderList = new List<String>();

        for(EmailMessage msg: emailToProcess){
            emailSenderList.add(msg.CreatedById);                
        }
        List<String> profilesToProcess = new List<String>();
        profilesToProcess = System.Label.PNR_ProfilesForEmailSaveFeature.split(';');
        Map<Id, User> pioneerSenders = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :emailSenderList AND Profile.Name IN :profilesToProcess]);
        List<String> emailList = new List<String>();

        //loop to create list of email ids from To, CC and BCC fields
        for(EmailMessage msg: emailToProcess){
            if(pioneerSenders.keyset().contains(msg.CreatedById)) //To process only the emails fired by Pioneer users
            {
                if(msg.ToAddress != null) 
                	emailList.addAll(msg.ToAddress.split('; '));
                if(msg.CcAddress != null) 
                    emailList.addAll(msg.CcAddress.split('; '));
                if(msg.BccAddress != null)
                    emailList.addAll(msg.BccAddress.split('; '));
            }
        }
        
        /*Loop to omit existing Contacts*/
        for(Contact con: [SELECT Id, Email FROM Contact WHERE email IN :emailList])
        {
            if(emailList.contains(con.Email)){
                emailList.remove(emailList.indexOf(con.Email));
            }
        }

        /*Loop to omit emails of existing users*/
        for(User u : [SELECT Id, Email FROM User WHERE Email IN :emailList]){
            if(emailList.contains(u.Email)){
                emailList.remove(emailList.indexOf(u.email));
            }
        }

        /*if statement Omit email of logged in user*/
        if(emailList.contains(UserInfo.getUserEmail())){
            emailList.remove(emailList.indexOf(UserInfo.getUserEmail()));
        }

        try{
            if(!emailList.isEmpty()){
                List<Contact> conToInsertList = new List<Contact>();
                
                    Account acc = [SELECT Id, Name FROM Account WHERE Name = :System.Label.PNR_Email_Contact_Account LIMIT 1];
                
                /*Loop to create one Contact per email Id*/
                for(String em: emailList){
                    Contact con = new Contact();
                    con.AccountId = acc.Id;
                    con.FirstName = 'Contact'; 
                    con.LastName = em.subString(0, em.indexOf('@'));
                    con.Email = em;
                    con.Contact_Type__c = 'Secondary';
                    conToInsertList.add(con); //Creating a list of contact to be inserted
                }
                if(conToInsertList.size() > 0){
                    insert conToInsertList; //Inserting Contacts
                }
            }
        }
        catch(Exception e)
        {
            System.debug('Exception message'+e.getLineNumber() + '---' + e.getMessage()); //Error handling
        }
        
    }
}