/**********************************************************************
Name: PNR_DeleteStaffCustomerSchedular
=======================================================================
Req:  
User Story : PION-964- Staff Customer Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       28/10/2019      Initial Development
***********************************************************************/
global class PNR_DeleteStaffCustomerSchedular implements Schedulable{
    global void execute(SchedulableContext sc) {     
         Database.executeBatch(new PNR_DeleteStaffCustomerBatch(),200);   
      }
}