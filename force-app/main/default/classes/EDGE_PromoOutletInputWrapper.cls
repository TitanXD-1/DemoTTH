/**
* @description EDGE_PromoOutletInputWrapper
*
* @history
* Version  Developer              Date               Purpose
* 1.0      Swaraj Samanta       23/07/2022      Initial Development
*/
global inherited sharing class EDGE_PromoOutletInputWrapper {
    public Id User_Id{get;set;}
    public Id Outlet_Id{get;set;}
    public List<Id> Promotion_List{get;set;}
}