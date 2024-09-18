/**********************************************************************
Name: DelegatedAccountTrigger
=======================================================================
Req: 
User Story : NCP-2781
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Rubeena Naaz      25/03/2021		  Initial Development

***********************************************************************/
trigger DelegatedAccountTrigger on DelegatedAccount (before insert,before Update,before Delete,after Insert,after Update,after Delete,after Undelete) {
	TriggerDispatcher.run(new DelegatedAccountTriggerHandler());
}