/**********************************************************************
Name: PNR_DeleteContactNoLiveCustSchedular
=======================================================================
Req:  
User Story : PION-1408- Contact Deletion for No Live Customer
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       2/3/2020      Initial Development

***********************************************************************/
global class PNR_DeleteContactNoLiveCustSchedular implements Schedulable{
    global void execute(SchedulableContext sc) {     
         Database.executeBatch(new PNR_DeleteContactForNoLiveCustomer());   
      }
}