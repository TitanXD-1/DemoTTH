/**********************************************************************
Name: EDGE_OrderProductWrapper
=======================================================================
Purpose: This wrapper class is needed to parse Mobile request
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sagar Barman      09/07/2019        ES20-3002

***********************************************************************/
global class EDGE_OrderProductWrapper {
    public String product{get;set;}
    public String accountId{get;set;}
    public Decimal quantity{get;set;}
    public String orderType{get;set;}
    public String salesRep{get;set;}
    public String guid{get;set;}
    public String recordTypeName{get;set;}
    

    
}