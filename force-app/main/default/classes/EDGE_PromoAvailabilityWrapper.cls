/**
* @description EDGE_PromoAvailabilityWrapper
*
* @history
* Version  Developer              Date               Purpose
* 1.0      Swaraj Samanta       23/07/2022      Initial Development
*/
global inherited sharing class EDGE_PromoAvailabilityWrapper {
    public Id Promotion_Id;
    public Boolean Available_for_Ordering;
    public Integer Unused_Outlet_Promotion;
    public Integer Unused_Territory_Promotion;
    
    /* Record not present ->null
* Limit exceed -> 0
* Limit not exceeeded -> unused value */
}