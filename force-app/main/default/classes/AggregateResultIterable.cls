/**********************************************************************
Name: AggregateResultIterable
=======================================================================
Req: Iterable Class class for EDGE_OrderStatusUpdateBatch
User Story : ES20-2267
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL
1.0       Anuja Chattopadhyay      11/07/2019        Sending email with order details to Delivery Partner when Order gets placed from Ready for Order  
***********************************************************************/

public inherited sharing class AggregateResultIterable implements Iterable<AggregateResult> {
  private String query;

  public AggregateResultIterable(String soql){
    query = soql;
  }

  public Iterator<AggregateResult> Iterator(){
    return new AggregateResultIterator(query);
  }
}