public class EDGE_BatchSObjectWrapper {

    public String operationType{get;set;}
    public SObject recordToProcess{get;set;}
    
    public  Map<Id,Integer> virtualCallsCountMap{get;set;} 
    public  Map<Id,Integer> telephoneCallsCountMap{get;set;}
    public  Map<Id,Integer> physicalCallsCountMap{get;set;}
    
}