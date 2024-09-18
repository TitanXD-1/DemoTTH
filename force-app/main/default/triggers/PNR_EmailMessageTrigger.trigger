/**********************************************************************
Name: PNR_EmailMessageTrigger
=======================================================================
Purpose: Trigger on EmailMessage object to create contacts based on recipients of email
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE                      DETAIL
1.0      	Pratik Kumar   	  15th Nov, 2021        PION: 1650 - Create Contact records for To, CC and BCC if the Contact doesnt exist
***********************************************************************/
trigger PNR_EmailMessageTrigger on EmailMessage (after insert) {
	if(Trigger.isInsert && Trigger.isAfter){
        List<EmailMessage> msgToProcess = new List<EmailMessage>();
        
        for(EmailMessage msg : Trigger.new)
        {
            //Checking if the email message is associated with any Case
            if(msg.ParentId != null){
                msgToProcess.add(msg);
            }
        }
        if(msgToProcess.size() > 0){
            PNR_CreateContactFromEmailMessage.createContact(msgToProcess);
        }
    }
}