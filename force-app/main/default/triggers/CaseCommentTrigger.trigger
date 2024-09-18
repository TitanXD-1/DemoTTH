/**
 
* @description : CaseCommentTrigger

* @purpose : This is to handle CaseComments trigger events 

* @history :                                                            
                                                          
*VERSION  			AUTHOR            DATE              DETAIL
*1.0 				Juned khan		 19/03/2021      Initial Development

*/
trigger CaseCommentTrigger on CaseComment (before Update,after Update,before insert,after insert,before Delete,after Delete,after Undelete) {
    TriggerDispatcher.run(new CaseCommentTriggerHandler()); 
}