/**********************************************************************
  Name: ECM_AccrualTrigger
=======================================================================
  Purpose: This is to handle ECM_AccrualTrigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Manikandan.T    15/02/2021      Initial Development
***********************************************************************/
trigger ECM_AccrualTrigger on ECM_Accrual__c (before insert) {

           ECM_AccrualHandler handler= new ECM_AccrualHandler ();
         /* Before Insert */
         if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new);
        }


}