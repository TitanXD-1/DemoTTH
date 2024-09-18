public class EDGE_OperatorCycleBriefOppWrapper {
    
    public List<EDGE_CycleBriefOppWrapper> ListOpp {get;set;}
    public Integer CycleBriefOpenOpp {get;set;}
    public Integer CycleBriefCloseOpp {get;set;}
    
    public class EDGE_CycleBriefOppWrapper{
        public String OutletID {get;set;}
        public String OutletName {get;set;}
        public String OpportunityID {get;set;}
        public String OppName {get;set;}
        public String Status {get;set;}
        public Date PendingDate {get;set;}
        public Date CloseDate {get;set;}
        
    }
}