/**********************************************************************
Name: EDGE_OutletInventoryCompareDateWrapper
=======================================================================
Purpose: 
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder			19/10/20220		  Intial Development(ES20-8625)
***********************************************************************/
global class EDGE_OutletInventoryCompareDateWrapper implements Comparable {
    public Outlet_Inventory__c outletInventory{get;set;}
    public Date dt{get;set;}
    public String Id{get;set;}
    
    // Constructor
    public EDGE_OutletInventoryCompareDateWrapper(Outlet_Inventory__c oi) {
        outletInventory = oi;
        dt = oi.Date__c;
        Id = oi.Id;
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        EDGE_OutletInventoryCompareDateWrapper compareToSQ = (EDGE_OutletInventoryCompareDateWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (outletInventory.Date__c < compareToSQ.outletInventory.Date__c) {
            returnValue = 1;
        } else if (outletInventory.Date__c >= compareToSQ.outletInventory.Date__c) {
            returnValue = -1;
        }
        return returnValue;       
    }
}