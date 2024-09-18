/**********************************************************************
Name: PNR_deleteContactBatchSchedular
=======================================================================
Req:  
User Story : PION-806- Old Contact Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Tanmoy Bardhan       06/11/2019      Initial Development
***********************************************************************/
global class PNR_deleteContactBatchSchedular implements Schedulable{
    global void execute(SchedulableContext sc) {     
         Database.executeBatch(new PNR_deleteContactBatch());   
      }
}