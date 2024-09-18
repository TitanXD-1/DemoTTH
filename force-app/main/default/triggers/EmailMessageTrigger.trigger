/**********************************************************************
Name: PNR_EmailMessageTrigger
************************************************************************
Purpose: Trigger on EmailMessage object to create contacts based on recipients of email
************************************************************************
History                                                            
********                                                          
VERSION     AUTHOR              DATE                      DETAIL
1.0      	Pratik Kumar   	  15th Nov, 2021        PION: 1650 - Create Contact records for To, CC and BCC if the Contact doesnt exist
2.0			Sai Kiran         8th Feb, 2022         PION: 1715 - Prevent user to delete emailMessage record when subject is approved.
***********************************************************************/
trigger EmailMessageTrigger on EmailMessage (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new EmailMessageTriggerHandler()); 
}