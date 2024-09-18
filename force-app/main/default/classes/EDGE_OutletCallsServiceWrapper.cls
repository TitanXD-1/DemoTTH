public class EDGE_OutletCallsServiceWrapper {
	
    public List<EDGE_OutletWrapper> Outletlist;

    public class EDGE_OutletWrapper{
      	public String Outletid{get;set;}
        public String OutletName{get;set;}
        public String PrimarySalesRepName{get;set;}
        public Decimal PhysicalCalls{get;set;}
        public Decimal VirtualCalls{get;set;}
        public Decimal TelephoneCalls{get;set;}
        public Decimal TotalCall{get;set;}
    }
}