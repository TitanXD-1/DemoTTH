/**********************************************************************
Name: ProductPrincingTrigger
=======================================================================
Purpose: This is to handle Product Pricing Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR          DATE           DETAIL
1.0      Manikant Pr.    21/08/2019     ES20-4028 : SFDC_New Object 
***********************************************************************/

trigger ProductPrincingTrigger on Product_Pricing__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ProductPrincingTriggerHandler());
}