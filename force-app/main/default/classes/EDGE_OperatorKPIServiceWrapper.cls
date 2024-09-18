public class EDGE_OperatorKPIServiceWrapper {
    public List<EDGE_OperatorSurveykpisWrapper> surveykpiList{get;set;}
    public List<EDGE_OperatorActivationkpisWrapper> activationkpisList{get;set;}
    
    public Decimal TotalTarget {get;set;}
    public Decimal TotalNumerator {get;set;}
    public Decimal TotalAchievement {get;set;}
    
    public class EDGE_OperatorSurveykpisWrapper{
        public Decimal Target{get;set;}
        public Decimal TargetDerived{get;set;}
        public Decimal TargetNumber{get;set;}
        public String SurveykpiName{get;set;}
        public Decimal Denominator{get;set;}
        public Decimal ActualNumerator{get;set;}
        public Decimal Actual{get;set;}
        public Decimal Achievement{get;set;}
    }
    
    public class EDGE_OperatorActivationkpisWrapper{
        public Decimal Target{get;set;}
        public Decimal TargetDerived{get;set;}
        public Decimal TargetNumber{get;set;}
        public Decimal ActualNumerator{get;set;}
        public Decimal Denominator{get;set;}
        public String ActivationName{get;set;}
        public Decimal Actual{get;set;}
        public Decimal Achievement{get;set;}
    }
}