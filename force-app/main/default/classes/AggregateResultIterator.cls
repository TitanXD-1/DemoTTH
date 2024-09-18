/**********************************************************************
Name: AggregateResultIterator
=======================================================================
Req: Iterator Class class for EDGE_OrderStatusUpdateBatch
User Story : ES20-2267
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL
1.0       Anuja Chattopadhyay      11/07/2019        Sending email with order details to Delivery Partner when Order gets placed from Ready for Order  
***********************************************************************/
public inherited sharing class AggregateResultIterator implements Iterator<AggregateResult> {
  AggregateResult [] results {get;set;}
  // tracks which result item is returned
  Integer index {get; set;} 
       
  public AggregateResultIterator(String query) {
    index = 0;
    results = Database.query(query);            
  } 

  public boolean hasNext(){ 
    return results != null && !results.isEmpty() && index < results.size(); 
  }    

  public AggregateResult next(){        
    return results[index++];            
  }       
}