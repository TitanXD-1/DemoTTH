/**********************************************************************
Name: EDGE_ContactShareServiceWrapper
=======================================================================
Purpose: This wrapper class is needed to send response for Contact
Share Service
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandip Ghosh      05/11/2020        ES20-7921

***********************************************************************/
global class EDGE_ContactShareServiceWrapper {
    
    public Boolean isSuccess{get;set;}
    public String errorMessage{get;set;}
}